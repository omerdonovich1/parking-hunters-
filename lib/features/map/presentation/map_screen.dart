import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:go_router/go_router.dart';
import '../../../models/parking_spot_model.dart';
import '../../../providers/map_provider.dart';
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

  late AnimationController _pulseController;

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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      final latlng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _currentPosition = latlng;
        _isLoadingLocation = false;
      });
      _mapController.move(latlng, 15);
      // Firestore stream auto-loads all active spots — no manual fetch needed.
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
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
              onPositionChanged: (pos, _) {
                if (pos.zoom != null && pos.zoom != _currentZoom) {
                  setState(() => _currentZoom = pos.zoom!);
                }
              },
            ),
            children: [
              // Dark-styled OSM tiles
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.parking_hunter',
                retinaMode: true,
              ),
              // Parking spot markers — clustered by zoom level
              MarkerLayer(
                markers: _buildClusters(visible, _currentZoom).map((cluster) {
                  if (cluster.spots.length == 1) {
                    final spot = cluster.spots.first;
                    final color = _spotColor(spot.computedStatus);
                    return Marker(
                      point: LatLng(spot.lat, spot.lng),
                      width: 80,
                      height: 56,
                      child: GestureDetector(
                        onTap: () { HapticFeedback.selectionClick(); _showSpotSheet(spot); },
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
                onSubmitted: (_) => setState(() => _isSearching = false),
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
                    icon: Icons.my_location_rounded,
                    onTap: () => _mapController.move(_currentPosition, 15),
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

// ── Cluster marker ───────────────────────────────────────────────────────────
class _ClusterMarker extends StatelessWidget {
  final int count;
  final Color color;
  const _ClusterMarker({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.7), width: 2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 14)],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              '🅿️',
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
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
      onTap: () { HapticFeedback.heavyImpact(); onTap(); },
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
