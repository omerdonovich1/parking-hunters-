import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng _currentPosition =
      const LatLng(Constants.defaultLat, Constants.defaultLng);
  bool _isLoadingLocation = true;
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
      ref.read(parkingSpotsProvider.notifier).loadNearbySpots(
          position.latitude, position.longitude,
          radiusKm: ref.read(nearbyRadiusProvider));
    } catch (e) {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Color _spotColor(SpotStatus s) {
    switch (s) {
      case SpotStatus.available:
        return AppTheme.neonGreen;
      case SpotStatus.soonAvailable:
        return AppTheme.neonYellow;
      case SpotStatus.lowConfidence:
        return AppTheme.neonRed;
      case SpotStatus.taken:
        return Colors.grey;
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
    final visible = spots
        .where((s) => !s.isExpired && activeFilters.contains(s.status))
        .toList();
    final availableCount =
        visible.where((s) => s.status == SpotStatus.available).length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Full-screen light map ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 15,
              maxZoom: 19,
              minZoom: 10,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.parking_hunter',
                retinaMode: true,
              ),
              MarkerLayer(
                markers: visible.map((spot) {
                  final color = _spotColor(spot.status);
                  return Marker(
                    point: LatLng(spot.lat, spot.lng),
                    width: 72,
                    height: 72,
                    child: GestureDetector(
                      onTap: () => _showSpotSheet(spot),
                      child: _PremiumPin(
                        color: color,
                        confidence: spot.confidence,
                        timeAgo: _timeAgo(spot.reportedAt),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (!_isLoadingLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentPosition,
                      width: 28,
                      height: 28,
                      child: _LocationDot(pulseController: _pulseController),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top search bar ─────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _SearchBar(
                controller: _searchController,
                isSearching: _isSearching,
                onTap: () => setState(() => _isSearching = true),
                onClose: () => setState(() {
                  _isSearching = false;
                  _searchController.clear();
                }),
                onSubmitted: (_) => setState(() => _isSearching = false),
              ),
            ),
          ),

          // ── Filter chips ───────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 76),
              child: const _FilterBar(),
            ),
          ),

          // ── Location button ────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 240,
            child: _FloatingIconButton(
              icon: Icons.my_location_rounded,
              onTap: () => _mapController.move(_currentPosition, 15),
            ),
          ),

          // ── Zoom buttons ───────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: 300,
            child: Column(
              children: [
                _FloatingIconButton(
                  icon: Icons.add,
                  onTap: () => _mapController.move(
                      _currentPosition, _mapController.camera.zoom + 1),
                ),
                const SizedBox(height: 8),
                _FloatingIconButton(
                  icon: Icons.remove,
                  onTap: () => _mapController.move(
                      _currentPosition, _mapController.camera.zoom - 1),
                ),
              ],
            ),
          ),

          // ── Bottom action card ─────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomActionCard(
              spotCount: visible.length,
              availableCount: availableCount,
              isLoading: _isLoadingLocation,
              onReport: () => context.go('/report'),
            ),
          ),

          // ── Loading indicator ──────────────────────────────────────────────
          if (_isLoadingLocation)
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.blue),
                      ),
                      SizedBox(width: 10),
                      Text('Finding your location…',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
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
      builder: (_) => SpotBottomSheet(spot: spot),
    );
  }
}

// ── Premium luxury pin ────────────────────────────────────────────────────────
class _PremiumPin extends StatelessWidget {
  final Color color;
  final double confidence;
  final String timeAgo;

  const _PremiumPin({
    required this.color,
    required this.confidence,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final pct = '${(confidence * 100).toInt()}%';
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pct,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                timeAgo,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        // Pin tip
        Container(
          width: 2,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Location dot ──────────────────────────────────────────────────────────────
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
            width: 28 + 10 * pulseController.value,
            height: 28 + 10 * pulseController.value,
            decoration: BoxDecoration(
              color: AppTheme.blue
                  .withValues(alpha: 0.12 * (1 - pulseController.value)),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                    color: AppTheme.blue.withValues(alpha: 0.4),
                    blurRadius: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final ValueChanged<String> onSubmitted;

  const _SearchBar({
    required this.controller,
    required this.isSearching,
    required this.onTap,
    required this.onClose,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: isSearching
          ? Row(children: [
              const SizedBox(width: 16),
              const Icon(Icons.search_rounded,
                  color: AppTheme.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.textDark),
                  decoration: const InputDecoration(
                    hintText: 'Search address…',
                    hintStyle:
                        TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: onSubmitted,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppTheme.textMuted, size: 20),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ])
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const Icon(Icons.search_rounded,
                      color: AppTheme.textMuted, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Search location…',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 14)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.blueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('🅿️',
                        style: TextStyle(fontSize: 13)),
                  ),
                ]),
              ),
            ),
    );
  }
}

// ── Filter bar ────────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeFiltersProvider);
    final filters = [
      (SpotStatus.available, 'Free', AppTheme.neonGreen),
      (SpotStatus.soonAvailable, 'Soon', AppTheme.neonYellow),
      (SpotStatus.lowConfidence, 'Low', AppTheme.neonRed),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? color
                        : Colors.grey.shade300,
                    width: selected ? 1.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppTheme.textDark : AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ]),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Floating icon button ──────────────────────────────────────────────────────
class _FloatingIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FloatingIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Icon(icon, color: AppTheme.textDark, size: 20),
      ),
    );
  }
}

// ── Bottom action card ────────────────────────────────────────────────────────
class _BottomActionCard extends StatelessWidget {
  final int spotCount;
  final int availableCount;
  final bool isLoading;
  final VoidCallback onReport;

  const _BottomActionCard({
    required this.spotCount,
    required this.availableCount,
    required this.isLoading,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Spot info row
          Row(
            children: [
              // Available count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? 'Scanning...' : '$availableCount spots nearby',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLoading
                          ? 'Finding parking spots'
                          : '$spotCount total · updated now',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Live indicator
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.neonGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppTheme.neonGreen.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Live',
                      style: TextStyle(
                        color: AppTheme.neonGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Report Spot button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onReport,
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.blue,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.blue.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_location_alt_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Report a Spot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                begin: 1.0,
                end: 1.02,
                duration: 1500.ms,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut)
        .fadeIn(duration: 400.ms);
  }
}
