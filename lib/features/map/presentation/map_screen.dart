import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:go_router/go_router.dart';
import 'package:geocoding/geocoding.dart';
import '../../../models/parking_spot_model.dart';
import '../../../models/road_status_model.dart';
import '../../../providers/map_provider.dart';
import '../../../services/location_service.dart';
import '../../../services/firestore_service.dart';
import '../../../core/utils/constants.dart';
import '../../../core/theme/app_theme.dart';
import 'widgets/spot_bottom_sheet.dart';
import 'widgets/map_filter_bar.dart';
import 'widgets/street_view_sheet.dart';

// Run geocoding in background isolate
Future<List<Location>> _geocodeInBackground(String address) async {
  return locationFromAddress(address);
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
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _hunterModeOpen = false;
  List<RoadStatus> _roadStatus = [];
  bool _showReportForm = false;
  bool _showStreetView = false;

  late AnimationController _pulseController;
  Timer? _panDebounceTimer;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initLocation();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _panDebounceTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();

      // Validate location coordinates
      if (position.latitude < -90 || position.latitude > 90 ||
          position.longitude < -180 || position.longitude > 180) {
        throw Exception('Invalid coordinates received');
      }

      final latlng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;

      debugPrint('✅ Location acquired: ${position.latitude}, ${position.longitude}');

      setState(() {
        _currentPosition = latlng;
        _isLoadingLocation = false;
      });
      _mapController.move(latlng, 15);
      ref.read(parkingSpotsProvider.notifier)
          .loadNearbySpots(position.latitude, position.longitude,
              radiusKm: ref.read(nearbyRadiusProvider));
    } catch (e) {
      debugPrint('❌ Location error: $e');
      if (mounted) {
        // Show error snackbar with context-aware message
        String message = 'Couldn\'t get your location';
        if (e.toString().contains('permission')) {
          message = 'Location permission denied. Using default area.';
        } else if (e.toString().contains('timeout')) {
          message = 'Location request timed out. Using default area.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 4),
            backgroundColor: AppTheme.orange.withValues(alpha: 0.9),
          ),
        );

        setState(() => _isLoadingLocation = false);
        // Still load default location spots
        ref.read(parkingSpotsProvider.notifier)
            .loadNearbySpots(Constants.defaultLat, Constants.defaultLng,
                radiusKm: ref.read(nearbyRadiusProvider));
      }
    }
  }

  void _startLocationTracking() {
    _locationSubscription = _locationService.getPositionStream().listen(
      (position) {
        final newLatLng = LatLng(position.latitude, position.longitude);

        if (mounted) {
          setState(() {
            _currentPosition = newLatLng;
          });

          // Move map to follow user (smooth pan)
          _mapController.move(newLatLng, _mapController.camera.zoom);

          // Reload nearby spots (uses debounce from _onMapPanned)
          _onMapPanned(position.latitude, position.longitude);

          // Also load road status for this area
          _loadRoadStatus(position.latitude, position.longitude);

          debugPrint('📍 Location updated: ${position.latitude}, ${position.longitude}');
        }
      },
      onError: (e) {
        debugPrint('❌ Location tracking error: $e');
      },
    );
  }

  Future<void> _loadRoadStatus(double lat, double lng) async {
    try {
      final roadStatusStream = _firestoreService.getNearbyRoadStatus(
        lat,
        lng,
        ref.read(nearbyRadiusProvider),
      );

      roadStatusStream.listen((roadStatuses) {
        if (mounted) {
          setState(() => _roadStatus = roadStatuses);
          debugPrint('📍 Road status loaded: ${roadStatuses.length} items');
        }
      });
    } catch (e) {
      debugPrint('❌ Road status error: $e');
    }
  }

  Future<void> _searchAddress(String address) async {
    if (address.isEmpty) return;
    try {
      // Run geocoding in background isolate (non-blocking)
      final locations = await compute(_geocodeInBackground, address);
      if (locations.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Address not found')),
          );
        }
        return;
      }
      final loc = locations.first;
      final latlng = LatLng(loc.latitude, loc.longitude);
      _mapController.move(latlng, 15);
      if (mounted) {
        setState(() => _isSearching = false);
        _searchController.clear();
      }
      ref.read(parkingSpotsProvider.notifier)
          .loadNearbySpots(loc.latitude, loc.longitude,
              radiusKm: ref.read(nearbyRadiusProvider));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  void _onMapPanned(double lat, double lng) {
    // Only reload if map center moved significantly (>0.5 km)
    final distance = _currentPosition.distanceTo(LatLng(lat, lng));
    const threshold = 0.005; // ~0.5 km in degrees
    if (distance > threshold) {
      // Debounce: cancel previous timer, wait 500ms before querying
      _panDebounceTimer?.cancel();
      _panDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        setState(() => _currentPosition = LatLng(lat, lng));
        ref.read(parkingSpotsProvider.notifier)
            .loadNearbySpots(lat, lng,
                radiusKm: ref.read(nearbyRadiusProvider));
      });
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
    final spots = ref.watch(parkingSpotsProvider);
    final activeFilters = ref.watch(activeFiltersProvider);
    final visible = spots.where((s) => !s.isExpired && activeFilters.contains(s.status)).toList();

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
              onPositionChanged: (MapPosition pos, bool hasGesture) {
                if (hasGesture && pos.center != null) {
                  _onMapPanned(pos.center!.latitude, pos.center!.longitude);
                }
              },
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              // Dark-styled OSM tiles
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.parking_hunter',
                retinaMode: true,
              ),
              // 200m radius around user
              if (!_isLoadingLocation)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentPosition,
                      radius: 200,
                      useRadiusInMeter: true,
                      color: AppTheme.orange.withValues(alpha: 0.07),
                      borderColor: AppTheme.orange.withValues(alpha: 0.35),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              // Parking spot markers
              MarkerLayer(
                markers: visible.map((spot) {
                  final color = _spotColor(spot.status);
                  return Marker(
                    point: LatLng(spot.lat, spot.lng),
                    width: 80,
                    height: 56,
                    child: GestureDetector(
                      onTap: () => _showSpotSheet(spot),
                      child: _SpotMarker(
                        spot: spot,
                        color: color,
                        timeAgo: _timeAgo(spot.reportedAt),
                      ),
                    ),
                  );
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
                onSubmitted: (address) => _searchAddress(address),
                spotCount: visible.length,
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

          // ── Road Status Panel ──────────────────────────────────────────────
          if (_roadStatus.isNotEmpty)
            Positioned(
              top: 130,
              left: 16,
              right: 88,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _roadStatus.map((status) {
                    final color = status.trafficLevel == TrafficLevel.light
                        ? AppTheme.neonGreen
                        : status.trafficLevel == TrafficLevel.moderate
                            ? AppTheme.neonYellow
                            : AppTheme.neonRed;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _mapController.move(
                            LatLng(status.lat, status.lng), 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BackdropFilter(
                            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: color.withValues(alpha: 0.6),
                                    width: 1),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    status.trafficLevel.name.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (status.incidents.isNotEmpty)
                                    Text(
                                      '⚠️ ${status.incidents.length}',
                                      style: TextStyle(
                                          color: color, fontSize: 9),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
                      .scaleXY(begin: 1.0, end: 1.06, duration: 1200.ms, curve: Curves.easeInOut),
                  const SizedBox(height: 16),
                  _SideIconButton(
                    icon: Icons.warning_rounded,
                    onTap: () => setState(() => _showReportForm = !_showReportForm),
                  ),
                  const SizedBox(height: 12),
                  _SideIconButton(
                    icon: Icons.streetview_rounded,
                    isActive: _showStreetView,
                    onTap: () => setState(() {
                      _showStreetView = !_showStreetView;
                      if (_showStreetView) _showReportForm = false;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _SideIconButton(
                    icon: Icons.my_location_rounded,
                    onTap: () => _mapController.move(_currentPosition, 15),
                  ),
                  const SizedBox(height: 12),
                  _SideIconButton(
                    icon: Icons.add,
                    onTap: () => _mapController.move(
                        _mapController.camera.center ?? _currentPosition,
                        _mapController.camera.zoom + 1),
                  ),
                  const SizedBox(height: 12),
                  _SideIconButton(
                    icon: Icons.remove,
                    onTap: () => _mapController.move(
                        _mapController.camera.center ?? _currentPosition,
                        _mapController.camera.zoom - 1),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading indicator ──────────────────────────────────────────────
          if (_isLoadingLocation)
            Positioned(
              top: 130,
              left: 0,
              right: 80,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: AppTheme.glassCard(radius: 20),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.orange)),
                          SizedBox(width: 10),
                          Text('Finding your location…',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Report Incident Form ───────────────────────────────────────────
          if (_showReportForm)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _ReportIncidentForm(
                currentLat: _currentPosition.latitude,
                currentLng: _currentPosition.longitude,
                onSubmit: (type, description) {
                  _firestoreService.reportRoadIncident(
                    lat: _currentPosition.latitude,
                    lng: _currentPosition.longitude,
                    type: type,
                    description: description,
                    userId: 'user123', // TODO: Get from auth
                  );
                  setState(() => _showReportForm = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted! Thank you.')),
                  );
                },
                onClose: () => setState(() => _showReportForm = false),
              ),
            ),

          // ── Street View Sheet ──────────────────────────────────────────────
          if (_showStreetView)
            StreetViewSheet(
              lat: _currentPosition.latitude,
              lng: _currentPosition.longitude,
              onClose: () => setState(() => _showStreetView = false),
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
      builder: (_) => SpotBottomSheet(spot: spot),
    );
  }
}

// ── Premium spot marker ──────────────────────────────────────────────────────
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(conf, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
              Text(timeAgo, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        // Pointer tip
        CustomPaint(
          size: const Size(10, 6),
          painter: _TipPainter(color: color.withValues(alpha: 0.6)),
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

// ── Car location indicator ──────────────────────────────────────────────────
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
          // Pulsing outer glow
          Container(
            width: 40 + 8 * pulseController.value,
            height: 40 + 8 * pulseController.value,
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: 0.12 * (1 - pulseController.value)),
              shape: BoxShape.circle,
            ),
          ),
          // Car icon container
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.orange.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 18,
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

  const _GlassSearchBar({
    required this.controller, required this.isSearching,
    required this.onTap, required this.onClose,
    required this.onSubmitted, required this.spotCount,
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
                      decoration: const InputDecoration(
                        hintText: 'Search address…',
                        hintStyle: TextStyle(color: Colors.white38),
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
                      const Expanded(
                        child: Text('Search location…',
                            style: TextStyle(color: Colors.white38, fontSize: 14)),
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
    final filters = [
      (SpotStatus.available,     '🟢', 'Free',  AppTheme.neonGreen),
      (SpotStatus.soonAvailable, '🟡', 'Soon',  AppTheme.neonYellow),
      (SpotStatus.lowConfidence, '🔴', 'Low',   AppTheme.neonRed),
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

// ── Side Hunter button ───────────────────────────────────────────────────────
class _HunterSideButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HunterSideButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.orange, Color(0xFFFF3D00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: AppTheme.orange.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

// ── Side utility icon button ─────────────────────────────────────────────────
class _SideIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  const _SideIconButton({required this.icon, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.orange.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isActive ? AppTheme.orange.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: isActive ? AppTheme.orange : Colors.white70, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Report Incident Form Widget ────────────────────────────────────────
class _ReportIncidentForm extends StatefulWidget {
  final double currentLat;
  final double currentLng;
  final Function(IncidentType, String) onSubmit;
  final VoidCallback onClose;

  const _ReportIncidentForm({
    required this.currentLat,
    required this.currentLng,
    required this.onSubmit,
    required this.onClose,
  });

  @override
  State<_ReportIncidentForm> createState() => _ReportIncidentFormState();
}

class _ReportIncidentFormState extends State<_ReportIncidentForm> {
  late TextEditingController _descriptionController;
  IncidentType _selectedType = IncidentType.accident;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: EdgeInsets.fromLTRB(
              16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Report Issue',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white60),
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Type selector
                Wrap(
                  spacing: 8,
                  children: [
                    for (final type in IncidentType.values)
                      FilterChip(
                        label: Text(type.name.toUpperCase(),
                            style: const TextStyle(fontSize: 11)),
                        selected: _selectedType == type,
                        selectedColor: AppTheme.orange,
                        onSelected: (_) =>
                            setState(() => _selectedType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Description input
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Describe the issue...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (_descriptionController.text.isNotEmpty) {
                        widget.onSubmit(_selectedType,
                            _descriptionController.text);
                      }
                    },
                    child: const Text('Submit Report',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
