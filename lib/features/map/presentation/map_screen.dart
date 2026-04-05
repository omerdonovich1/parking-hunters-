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
  AnimationController? _flyController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _flyController?.dispose();
    _searchController.dispose();
    super.dispose();
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
              // ── Base tiles: roads only, no POI clutter ────────────────────
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_nolabels/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.parking_hunter',
                retinaMode: true,
              ),
              // ── Labels overlay: street names only ─────────────────────────
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.parking_hunter',
                retinaMode: true,
              ),
              // ── 200 m Search Zone circle (animated pulse) ────────────────
              if (!_isLoadingLocation)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => CircleLayer(
                    circles: [
                      // Solid filled zone — breathing opacity
                      CircleMarker(
                        point: _zoneCenter,
                        radius: 200,
                        useRadiusInMeter: true,
                        color: AppTheme.neonGreen.withValues(
                            alpha: 0.04 + 0.025 * _pulseController.value),
                        borderStrokeWidth: 1.6,
                        borderColor: AppTheme.neonGreen.withValues(
                            alpha: 0.35 + 0.25 * _pulseController.value),
                      ),
                      // Expanding outer ring — fades out as it grows
                      CircleMarker(
                        point: _zoneCenter,
                        radius: 200 + 12 * _pulseController.value,
                        useRadiusInMeter: true,
                        color: Colors.transparent,
                        borderStrokeWidth: 0.8,
                        borderColor: AppTheme.neonGreen.withValues(
                            alpha: 0.18 * (1 - _pulseController.value)),
                      ),
                      // Subtle 100 m inner reference ring
                      CircleMarker(
                        point: _currentPosition,
                        radius: 80,
                        useRadiusInMeter: true,
                        color: Colors.transparent,
                        borderStrokeWidth: 0.8,
                        borderColor: AppTheme.orange.withValues(alpha: 0.12),
                      ),
                    ],
                  ),
                ),
              // ── Parking spot markers — clustered by zoom level ────────────
              MarkerLayer(
                markers: _buildClusters(visible, _currentZoom).map((cluster) {
                  if (cluster.spots.length == 1) {
                    final spot = cluster.spots.first;
                    final color = _spotColor(spot.computedStatus);
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
                    },
                  ),
                  const SizedBox(height: 12),
                  _SideIconButton(
                    icon: Icons.add,
                    onTap: () => _mapController.move(
                        _currentPosition, _mapController.camera.zoom + 1),
                  ),
                  const SizedBox(height: 12),
                  _SideIconButton(
                    icon: Icons.remove,
                    onTap: () => _mapController.move(
                        _currentPosition, _mapController.camera.zoom - 1),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      useSafeArea: false,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.55, 0.92],
        builder: (_, scrollController) =>
            SpotBottomSheet(spot: spot, scrollController: scrollController),
      ),
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

// ── Cluster marker — radar sweep style ──────────────────────────────────────
class _ClusterMarker extends StatelessWidget {
  final int count;
  final Color color;
  const _ClusterMarker({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.06),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
        ),
        // Inner filled circle
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 20, spreadRadius: 3),
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 40, spreadRadius: 6),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, height: 1.1),
              ),
              Text('🅿️', style: const TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Spot marker — radar blip HUD ─────────────────────────────────────────────
class _SpotMarker extends StatelessWidget {
  final ParkingSpot spot;
  final Color color;
  final String timeAgo;

  const _SpotMarker({required this.spot, required this.color, required this.timeAgo});

  @override
  Widget build(BuildContext context) {
    final conf = '${(spot.confidence * 100).toInt()}%';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulse ring
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.05),
                border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
              ),
            ),
            // Main blip circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color, width: 2.5),
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.75), blurRadius: 18, spreadRadius: 3),
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 36, spreadRadius: 6),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    conf,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.75),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Pointer tip
        CustomPaint(
          size: const Size(10, 7),
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
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: isSearching
              ? Row(children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: onSubmitted,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                    onPressed: onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ])
              : GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(hintText,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.orange.withValues(alpha: 0.4)),
                        ),
                        child: Text('$spotCount 🅿️',
                            style: const TextStyle(color: AppTheme.orange, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Glass filter bar ─────────────────────────────────────────────────────────
class _GlassFilterBar extends ConsumerWidget {
  const _GlassFilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeFiltersProvider);
    final s = ref.watch(appStringsProvider);
    final filters = [
      (SpotStatus.available,     '🟢', s.filterHigh, AppTheme.neonGreen),
      (SpotStatus.soonAvailable, '🟡', s.filterMid,  AppTheme.neonYellow),
      (SpotStatus.lowConfidence, '🔴', s.filterLow,  AppTheme.neonRed),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((f) {
          final (status, emoji, label, color) = f;
          final selected = active.contains(status);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                final current = Set<SpotStatus>.from(active);
                if (selected) {
                  if (current.length > 1) current.remove(status);
                } else {
                  current.add(status);
                }
                ref.read(activeFiltersProvider.notifier).state = current;
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? color.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.1),
                        width: 1.2,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 5),
                      Text(label, style: TextStyle(
                        color: selected ? color : Colors.white54,
                        fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      )),
                    ]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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

// ── Side utility icon button ─────────────────────────────────────────────────
class _SideIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SideIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }
}
