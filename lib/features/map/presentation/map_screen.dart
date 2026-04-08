import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/parking_spot_model.dart';
import '../../../providers/map_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/location_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/spot_bottom_sheet.dart';
import 'widgets/map_filter_bar.dart';

// ── Cluster model ────────────────────────────────────────────────────────────
class _Cluster {
  final List<ParkingSpot> spots;
  _Cluster(this.spots);

  LatLng get center {
    final lat = spots.map((s) => s.lat).reduce((a, b) => a + b) / spots.length;
    final lng = spots.map((s) => s.lng).reduce((a, b) => a + b) / spots.length;
    return LatLng(lat, lng);
  }

  // Dominant color = most common status
  SpotStatus get dominantStatus {
    final counts = <SpotStatus, int>{};
    for (final s in spots) {
      counts[s.computedStatus] = (counts[s.computedStatus] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

/// Haversine distance in metres between two [LatLng] points.
double _haversineMeters(LatLng a, LatLng b) {
  const r = 6371000.0;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLng = (b.longitude - a.longitude) * math.pi / 180;
  final sinDLat = math.sin(dLat / 2);
  final sinDLng = math.sin(dLng / 2);
  final x = sinDLat * sinDLat +
      math.cos(a.latitude * math.pi / 180) *
          math.cos(b.latitude * math.pi / 180) *
          sinDLng * sinDLng;
  return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
}

/// Zoom level that makes the 200 m radius circle fill [fillRatio] of screen width.
double _zoomForRadius200m(double latDeg, double screenWidthPx,
    {double fillRatio = 0.75}) {
  const earthMppZoom0 = 156543.03392;
  final metersPerPixel = 400.0 / (screenWidthPx * fillRatio);
  final zoom =
      math.log(earthMppZoom0 * math.cos(latDeg * math.pi / 180) / metersPerPixel) /
          math.ln2;
  return zoom.clamp(13.0, 18.5);
}

/// Groups spots into clusters. Radius shrinks as zoom increases.
List<_Cluster> _buildClusters(List<ParkingSpot> spots, double zoom) {
  // At zoom 15+ show individual markers (cluster radius effectively 0)
  final radiusDeg = zoom >= 15 ? 0.0 : 0.003 * math.pow(2, 14 - zoom);
  final clusters = <_Cluster>[];

  for (final spot in spots) {
    bool merged = false;
    for (final cluster in clusters) {
      final c = cluster.center;
      final dlat = (spot.lat - c.latitude).abs();
      final dlng = (spot.lng - c.longitude).abs();
      if (dlat < radiusDeg && dlng < radiusDeg) {
        cluster.spots.add(spot);
        merged = true;
        break;
      }
    }
    if (!merged) clusters.add(_Cluster([spot]));
  }
  return clusters;
}

/// Maps confidence (0.0–1.0) → HSL heat color: red (0°) → yellow → green (120°).
Color _confidenceColor(double pct) {
  final hue = (pct * 120.0).clamp(0.0, 120.0);
  return HSLColor.fromAHSL(1.0, hue, 1.0, 0.45).toColor();
}

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentPosition = const LatLng(Constants.defaultLat, Constants.defaultLng);
  bool _isLoadingLocation = true;
  final LocationService _locationService = LocationService();

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _hunterModeOpen = false;
  double _currentZoom = 15;

  // 200 m search zone centre — defaults to user's GPS, updates on geocode search
  LatLng _zoneCenter = const LatLng(Constants.defaultLat, Constants.defaultLng);

  late AnimationController _pulseController;
  // Radar sweep — one full 360° rotation every 3 seconds
  late AnimationController _radarController;
  AnimationController? _flyController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _radarController.dispose();
    _flyController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Restart the radar sweep from 0 — called after zone changes.
  void _restartRadar() {
    _radarController.forward(from: 0);
  }

  /// Cinematic camera pan + zoom toward [target].
  /// Offsets north so the spot sits above the bottom sheet.
  void _flyToSpot(LatLng target) {
    _flyController?.dispose();
    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    final camera = _mapController.camera;
    final startLat = camera.center.latitude;
    final startLng = camera.center.longitude;
    final startZoom = camera.zoom;
    // Nudge north ~90m so spot is visible above the 55% bottom sheet
    final endLat = target.latitude + 0.0007;
    final endLng = target.longitude;
    final endZoom = startZoom < 15.5 ? 15.5 : startZoom;

    final curve = CurvedAnimation(parent: _flyController!, curve: Curves.easeOutCubic);
    final latAnim  = Tween<double>(begin: startLat,  end: endLat).animate(curve);
    final lngAnim  = Tween<double>(begin: startLng,  end: endLng).animate(curve);
    final zoomAnim = Tween<double>(begin: startZoom, end: endZoom).animate(curve);

    _flyController!.addListener(() {
      _mapController.move(LatLng(latAnim.value, lngAnim.value), zoomAnim.value);
    });
    _flyController!.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        HapticFeedback.lightImpact(); // landing click
        _flyController?.dispose();
        _flyController = null;
      } else if (s == AnimationStatus.dismissed) {
        _flyController?.dispose();
        _flyController = null;
      }
    });

    _flyController!.forward();
  }

  Future<void> _initLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      final latlng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      final screenW = MediaQuery.of(context).size.width;
      final zoom = _zoomForRadius200m(position.latitude, screenW);
      setState(() {
        _currentPosition = latlng;
        _zoneCenter = latlng;
        _isLoadingLocation = false;
      });
      _mapController.move(latlng, zoom);
      _restartRadar();
      // Firestore stream auto-loads all active spots — no manual fetch needed.
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  /// Geocodes [query] → moves zone centre + auto-zooms to 200 m fill.
  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final locations = await locationFromAddress(query);
      if (!mounted || locations.isEmpty) return;
      final loc = locations.first;
      final latlng = LatLng(loc.latitude, loc.longitude);
      final screenW = MediaQuery.of(context).size.width;
      final zoom = _zoomForRadius200m(loc.latitude, screenW);
      setState(() {
        _zoneCenter = latlng;
        _isSearching = false;
        _searchController.clear();
      });
      _mapController.move(latlng, zoom);
      _restartRadar();
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
  }

  Color _spotColor(SpotStatus s) {
    switch (s) {
      case SpotStatus.available:     return AppTheme.neonGreen;
      case SpotStatus.soonAvailable: return AppTheme.neonYellow;
      case SpotStatus.lowConfidence: return AppTheme.neonRed;
      case SpotStatus.taken:         return Colors.grey;
    }
  }

  String _spotEmoji(SpotStatus s) {
    switch (s) {
      case SpotStatus.available:     return '🟢';
      case SpotStatus.soonAvailable: return '🟡';
      case SpotStatus.lowConfidence: return '🔴';
      case SpotStatus.taken:         return '⛔';
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    return '${d.inHours}h';
  }

  @override
  Widget build(BuildContext context) {
    // Tick when a new spot appears live on the map
    ref.listen<List<ParkingSpot>>(parkingSpotsProvider, (prev, next) {
      if (prev != null && next.length > prev.length) {
        HapticFeedback.selectionClick();
      }
    });

    final s = ref.watch(appStringsProvider);
    final spots = ref.watch(parkingSpotsProvider);
    final activeFilters = ref.watch(activeFiltersProvider);

    // Filter by status + 200 m zone, then sort closest → farthest
    final filtered =
        spots.where((sp) => !sp.isExpired && activeFilters.contains(sp.status)).toList();
    final nearby = filtered
        .where((sp) =>
            _haversineMeters(_zoneCenter, LatLng(sp.lat, sp.lng)) <= 200)
        .toList()
      ..sort((a, b) =>
          _haversineMeters(_zoneCenter, LatLng(a.lat, a.lng))
              .compareTo(_haversineMeters(_zoneCenter, LatLng(b.lat, b.lng))));
    final visible = nearby;
    final noSpotsInZone = filtered.isNotEmpty && nearby.isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // ── Full-screen map ────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15,
              maxZoom: 19,
              minZoom: 10,
              onPositionChanged: (pos, _) {
                if (pos.zoom != null && pos.zoom != _currentZoom) {
                  setState(() => _currentZoom = pos.zoom!);
                }
              },
            ),
            children: [
              // ── Light map tiles (Carto Voyager) ───────────────────────────
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.parking_hunter',
                retinaMode: true,
              ),
              // ── Military radar: steady boundary ring ─────────────────────
              if (!_isLoadingLocation)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _zoneCenter,
                      radius: 200,
                      useRadiusInMeter: true,
                      color: AppTheme.neonGreen.withValues(alpha: 0.03),
                      borderStrokeWidth: 1.2,
                      borderColor: AppTheme.neonGreen.withValues(alpha: 0.40),
                    ),
                    // GPS dot halo
                    CircleMarker(
                      point: _currentPosition,
                      radius: 55,
                      useRadiusInMeter: true,
                      color: AppTheme.orange.withValues(alpha: 0.04),
                      borderStrokeWidth: 0.8,
                      borderColor: AppTheme.orange.withValues(alpha: 0.15),
                    ),
                  ],
                ),
              // ── Military radar: sweep line CustomPaint marker ─────────────
              if (!_isLoadingLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _zoneCenter,
                      width: 400,
                      height: 400,
                      child: AnimatedBuilder(
                        animation: _radarController,
                        builder: (_, __) => CustomPaint(
                          painter: _RadarSweepPainter(
                            angle: _radarController.value * 2 * math.pi,
                            color: AppTheme.neonGreen,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              // ── Parking spot markers — clustered by zoom level ────────────
              MarkerLayer(
                markers: _buildClusters(visible, _currentZoom).map((cluster) {
                  if (cluster.spots.length == 1) {
                    final spot = cluster.spots.first;
                    final color = _confidenceColor(spot.confidence);
                    return Marker(
                      point: LatLng(spot.lat, spot.lng),
                      width: 68,
                      height: 76,
                      child: GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); _flyToSpot(LatLng(spot.lat, spot.lng)); _showSpotSheet(spot); },
                        child: _SpotMarker(
                          spot: spot,
                          color: color,
                          timeAgo: _timeAgo(spot.reportedAt),
                        ),
                      ),
                    );
                  } else {
                    final color = _spotColor(cluster.dominantStatus);
                    return Marker(
                      point: cluster.center,
                      width: 56,
                      height: 56,
                      child: GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); _mapController.move(cluster.center, _currentZoom + 2); },
                        child: _ClusterMarker(count: cluster.spots.length, color: color),
                      ),
                    );
                  }
                }).toList(),
              ),
              // Current location dot
              if (!_isLoadingLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 24,
                      height: 24,
                      child: _LocationDot(pulseController: _pulseController),
                    ),
                  ],
                ),
            ],
          ),

          // ── Edge vignette — pulls focus to center, darkens corners ──────────
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    AppTheme.bg.withValues(alpha: 0.55),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),

          // ── Top: blurred search bar ────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 72, 0),
              child: _GlassSearchBar(
                controller: _searchController,
                isSearching: _isSearching,
                onTap: () => setState(() => _isSearching = true),
                onClose: () => setState(() {
                  _isSearching = false;
                  _searchController.clear();
                }),
                onSubmitted: (q) => _searchLocation(q),
                spotCount: visible.length,
                hintText: s.searchHint,
              ),
            ),
          ),

          // ── Filter chips (below search) ────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 72),
              child: const _GlassFilterBar(),
            ),
          ),

          // ── Right side: Hunter button ──────────────────────────────────────
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HunterSideButton(
                    onTap: () => context.go('/report'),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(begin: 1.0, end: 1.1, duration: 1000.ms, curve: Curves.easeInOut),
                  const SizedBox(height: 16),
                  _SideIconButton(
                    icon: Icons.my_location_rounded,
                    onTap: () {
                      final screenW = MediaQuery.of(context).size.width;
                      final zoom = _zoomForRadius200m(_currentPosition.latitude, screenW);
                      setState(() => _zoneCenter = _currentPosition);
                      _mapController.move(_currentPosition, zoom);
                      _restartRadar();
                    },
                  ),
                  const SizedBox(height: 12),
                  _SideIconButton(
                    icon: Icons.add,
                    onTap: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1),
                  ),
                  const SizedBox(height: 12),
                  _SideIconButton(
                    icon: Icons.remove,
                    onTap: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1),
                  ),
                ],
              ),
            ),
          ),

          // ── No parking in zone hint ───────────────────────────────────────
          if (noSpotsInZone)
            Positioned(
              bottom: 120,
              left: 24,
              right: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.card.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off_rounded,
                          color: Colors.white54, size: 18),
                      const SizedBox(width: 8),
                      Text(s.noParkingNearby,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.2, end: 0, duration: 300.ms),
              ),
            ),

          // ── Loading shimmer HUD ───────────────────────────────────────────
          if (_isLoadingLocation)
            Positioned(
              top: 130,
              left: 20,
              right: 80,
              child: _MapLoadingShimmer(),
            ),
        ],
      ),
    );
  }

  void _showSpotSheet(ParkingSpot spot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NavigateSheet(spot: spot),
    );
  }
}

// ── Map loading shimmer HUD ──────────────────────────────────────────────────
class _MapLoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.card,
      highlightColor: const Color(0xFF1C3558),
      period: const Duration(milliseconds: 1000),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fake pill — scanning indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Container(width: 130, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Three ghost spot markers in a row
          Row(
            children: List.generate(3, (i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

// ── Cluster marker — minimal count badge ─────────────────────────────────────
class _ClusterMarker extends StatelessWidget {
  final int count;
  final Color color;
  const _ClusterMarker({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft ambient glow
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.07),
          ),
        ),
        // Main pill
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.card.withValues(alpha: 0.95),
            border: Border.all(color: color, width: 1.8),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 14, spreadRadius: 1),
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 28, spreadRadius: 4),
            ],
          ),
          child: Center(
            child: Text(
              '$count',
              style: TextStyle(
                color: color, fontSize: 16,
                fontWeight: FontWeight.w900, height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Spot marker — clean minimal blip ─────────────────────────────────────────
class _SpotMarker extends StatelessWidget {
  final ParkingSpot spot;
  final Color color;
  final String timeAgo;

  const _SpotMarker({required this.spot, required this.color, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Ambient glow halo
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.10),
              ),
            ),
            // Core circle — dark fill so text is always legible
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.card.withValues(alpha: 0.96),
                border: Border.all(color: color, width: 2),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.65), blurRadius: 12, spreadRadius: 1),
                  BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 28, spreadRadius: 4),
                ],
              ),
              child: Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: color,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        // Tiny time label below
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.bg.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              timeAgo,
              style: TextStyle(
                color: color.withValues(alpha: 0.85),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        // Pointer tip
        CustomPaint(
          size: const Size(8, 5),
          painter: _TipPainter(color: color),
        ),
      ],
    );
  }
}

class _TipPainter extends CustomPainter {
  final Color color;
  const _TipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Pulsing location dot ─────────────────────────────────────────────────────
class _LocationDot extends StatelessWidget {
  final AnimationController pulseController;
  const _LocationDot({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24 + 8 * pulseController.value,
            height: 24 + 8 * pulseController.value,
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: 0.15 * (1 - pulseController.value)),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [BoxShadow(color: AppTheme.orange.withValues(alpha: 0.5), blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass search bar ─────────────────────────────────────────────────────────
class _GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final ValueChanged<String> onSubmitted;
  final int spotCount;
  final String hintText;

  const _GlassSearchBar({
    required this.controller, required this.isSearching,
    required this.onTap, required this.onClose,
    required this.onSubmitted, required this.spotCount,
    this.hintText = 'Search address…',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          decoration: BoxDecoration(
            color: isSearching
                ? Colors.white.withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSearching
                  ? AppTheme.orange.withValues(alpha: 0.45)
                  : Colors.black.withValues(alpha: 0.10),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
              if (isSearching)
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: 0.08),
                  blurRadius: 16,
                ),
            ],
          ),
          child: isSearching
              ? Row(children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search_rounded,
                      color: AppTheme.orange.withValues(alpha: 0.8), size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(
                            color: Colors.black45,
                            fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: onSubmitted,
                    ),
                  ),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 28, height: 28,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.07),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.black54, size: 14),
                    ),
                  ),
                ])
              : GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(children: [
                      const Icon(Icons.search_rounded,
                          color: Colors.black45, size: 19),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(hintText,
                            style: const TextStyle(
                                color: Colors.black45, fontSize: 14)),
                      ),
                      // Spot count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.orange.withValues(alpha: 0.35)),
                        ),
                        child: Text('$spotCount P',
                            style: const TextStyle(
                                color: AppTheme.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3)),
                      ),
                    ]),
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Glow status chip filter bar ───────────────────────────────────────────────
class _GlassFilterBar extends ConsumerWidget {
  const _GlassFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeFiltersProvider);
    final s = ref.watch(appStringsProvider);
    final filters = [
      (SpotStatus.available,     s.filterHigh, AppTheme.neonGreen),
      (SpotStatus.soonAvailable, s.filterMid,  AppTheme.neonYellow),
      (SpotStatus.lowConfidence, s.filterLow,  AppTheme.neonRed),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((f) {
          final (status, label, color) = f;
          final selected = active.contains(status);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _StatusChip(
              label: label,
              color: color,
              selected: selected,
              onTap: () {
                final current = Set<SpotStatus>.from(active);
                if (selected) {
                  if (current.length > 1) current.remove(status);
                } else {
                  current.add(status);
                }
                ref.read(activeFiltersProvider.notifier).state = current;
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusChip extends StatefulWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _StatusChip({
    required this.label, required this.color,
    required this.selected, required this.onTap,
  });

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final selected = widget.selected;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); widget.onTap(); },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: AppTheme.statusChip(color, selected: selected),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? color : color.withValues(alpha: 0.35),
                      boxShadow: selected
                          ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6, spreadRadius: 1)]
                          : [],
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    widget.label,
                    style: TextStyle(
                      // Dark text so chips are legible on both light map
                      // tiles and dark overlays
                      color: selected
                          ? const Color(0xFF0A0A0A)
                          : const Color(0xFF1A1A1A),
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Side Hunter button — mission-critical CTA ────────────────────────────────
class _HunterSideButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HunterSideButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.heavyImpact(); onTap(); },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.energy, Color(0xFFBB0055)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppTheme.energy.withValues(alpha: 0.75), blurRadius: 28, spreadRadius: 4),
            BoxShadow(color: AppTheme.energy.withValues(alpha: 0.4), blurRadius: 52, spreadRadius: 8),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.5),
        ),
        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

// ── Side utility icon button — solid black circle, pure white icon ───────────
class _SideIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SideIconButton({required this.icon, required this.onTap});

  @override
  State<_SideIconButton> createState() => _SideIconButtonState();
}

class _SideIconButtonState extends State<_SideIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); widget.onTap(); },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ── Radar sweep CustomPainter ─────────────────────────────────────────────────
class _RadarSweepPainter extends CustomPainter {
  final double angle; // 0..2π, current sweep head angle
  final Color color;

  const _RadarSweepPainter({required this.angle, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;

    // ── Strictly clip to circle boundary — no bleed outside 200 m ring ───────
    canvas.save();
    canvas.clipPath(
        Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius)));

    // ── Trail: filled wedge sweeping 270° behind the head, fading out ────────
    const trailSweep = 5 * math.pi / 6; // 150° trail
    const trailSteps = 40;
    for (int i = 0; i < trailSteps; i++) {
      final frac = i / trailSteps;
      final stepAngle = angle - trailSweep * (1 - frac);
      final opacity = frac * 0.18; // 0 at tail, 0.18 at head
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final path = Path()
        ..moveTo(cx, cy)
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: radius),
          stepAngle,
          trailSweep / trailSteps,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }

    // ── Sweep head line ───────────────────────────────────────────────────────
    final headPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle)),
      headPaint,
    );

    // ── Bright tip dot at sweep head ─────────────────────────────────────────
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle)),
      3,
      dotPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_RadarSweepPainter old) => old.angle != angle;
}

// ── Navigate action sheet — Waze / Google Maps deep links ────────────────────
class _NavigateSheet extends ConsumerWidget {
  final ParkingSpot spot;
  const _NavigateSheet({required this.spot});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _confidenceColor(spot.confidence);
    final confPct = '${(spot.confidence * 100).toInt()}%';
    final minsAgo = DateTime.now().difference(spot.reportedAt).inMinutes;
    final timeLabel = minsAgo < 1 ? 'just now' : '${minsAgo}m ago';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Spot info row
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8)
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Parking spot — $confPct confidence',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Waze
              _NavButton(
                icon: Icons.navigation_rounded,
                label: 'Navigate with Waze',
                color: const Color(0xFF09C0F0),
                onTap: () {
                  Navigator.pop(context);
                  _launch('waze://?ll=${spot.lat},${spot.lng}&navigate=yes');
                },
              ),
              const SizedBox(height: 10),
              // Google Maps
              _NavButton(
                icon: Icons.map_rounded,
                label: 'Navigate with Google Maps',
                color: const Color(0xFF4285F4),
                onTap: () {
                  Navigator.pop(context);
                  _launch(
                    'https://www.google.com/maps/dir/?api=1&destination=${spot.lat},${spot.lng}',
                  );
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavButton({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
