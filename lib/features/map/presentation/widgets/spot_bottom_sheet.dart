import 'dart:async';
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/parking_spot_model.dart';
import '../../../../providers/map_provider.dart';
import '../../../../core/theme/app_theme.dart';

class SpotBottomSheet extends ConsumerStatefulWidget {
  final ParkingSpot spot;
  const SpotBottomSheet({super.key, required this.spot});

  @override
  ConsumerState<SpotBottomSheet> createState() => _SpotBottomSheetState();
}

class _SpotBottomSheetState extends ConsumerState<SpotBottomSheet> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Rebuild every second so countdown stays live
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Duration get _remaining => widget.spot.expiresAt.difference(DateTime.now());
  bool get _isExpired => _remaining.isNegative;

  String get _countdownText {
    if (_isExpired) return 'Expired';
    if (_remaining.inSeconds < 60) return '${_remaining.inSeconds}s left';
    if (_remaining.inMinutes < 60) return '${_remaining.inMinutes}m left';
    return '${_remaining.inHours}h ${_remaining.inMinutes % 60}m left';
  }

  Color get _countdownColor {
    if (_isExpired) return Colors.grey;
    if (_remaining.inMinutes < 5) return AppTheme.neonRed;
    if (_remaining.inMinutes < 15) return AppTheme.neonYellow;
    return AppTheme.neonGreen;
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    return '${d.inHours}h ago';
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.7) return AppTheme.neonGreen;
    if (confidence >= 0.4) return AppTheme.neonYellow;
    return AppTheme.neonRed;
  }

  Future<void> _navigateToSpot() async {
    final lat = widget.spot.lat;
    final lng = widget.spot.lng;
    if (kIsWeb) {
      final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      if (await canLaunchUrl(url)) await launchUrl(url);
      return;
    }
    final wazeUrl = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');
    if (await canLaunchUrl(wazeUrl)) { await launchUrl(wazeUrl); return; }
    final gmapsUrl = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(gmapsUrl)) { await launchUrl(gmapsUrl); return; }
    final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }

  Future<void> _markTaken() async {
    Navigator.pop(context);
    await ref.read(firestoreServiceProvider).markSpotTaken(widget.spot.id);
    ref.read(parkingSpotsProvider.notifier).removeExpiredSpots();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Spot marked as taken — thanks!'),
          backgroundColor: AppTheme.card,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _confirmSpot() async {
    ref.read(firestoreServiceProvider).confirmSpot(widget.spot.id, 'local_user');
    ref.read(parkingSpotsProvider.notifier).updateSpot(
      widget.spot.copyWith(confidence: (widget.spot.confidence + 0.05).clamp(0.0, 1.0)),
    );
    Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Spot confirmed! +5 points'),
          backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    final confidence = spot.confidence;
    final confColor = _confidenceColor(confidence);
    final confPct = (confidence * 100).toInt();

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.card.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status row
                  Row(
                    children: [
                      _StatusBadge(status: spot.status),
                      const Spacer(),
                      // Countdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _countdownColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _countdownColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 13, color: _countdownColor),
                            const SizedBox(width: 5),
                            Text(
                              _countdownText,
                              style: TextStyle(
                                color: _countdownColor,
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

                  // Photo
                  if (spot.photoUrl != null && spot.photoUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: spot.photoUrl!,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 160,
                          color: AppTheme.cardBorder,
                          child: const Center(
                            child: CircularProgressIndicator(color: AppTheme.orange, strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 160,
                          color: AppTheme.cardBorder,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Confidence bar
                  Row(
                    children: [
                      Text(
                        'AI Confidence',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                      ),
                      const Spacer(),
                      Text(
                        '$confPct%',
                        style: TextStyle(color: confColor, fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidence.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(confColor),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Meta row
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.white38),
                      const SizedBox(width: 5),
                      Text(
                        'Reported ${_timeAgo(spot.reportedAt)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      if (spot.confirmedCount > 0) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.thumb_up_outlined, size: 14, color: AppTheme.neonGreen.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Text(
                          '${spot.confirmedCount} confirmed',
                          style: TextStyle(color: AppTheme.neonGreen.withValues(alpha: 0.7), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  if (spot.note != null && spot.note!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.notes, size: 14, color: Colors.white38),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            spot.note!,
                            style: const TextStyle(color: Colors.white60, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Navigate button
                  _ActionButton(
                    onTap: _navigateToSpot,
                    gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                    icon: Icons.navigation_rounded,
                    label: 'Navigate Here',
                  ),
                  const SizedBox(height: 10),

                  // Mark taken + confirm row
                  Row(
                    children: [
                      Expanded(
                        child: _OutlineActionButton(
                          onTap: _markTaken,
                          icon: Icons.no_meeting_room_outlined,
                          label: 'Taken',
                          color: AppTheme.neonRed,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _OutlineActionButton(
                          onTap: _confirmSpot,
                          icon: Icons.thumb_up_outlined,
                          label: 'Still Free',
                          color: AppTheme.neonGreen,
                        ),
                      ),
                    ],
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

// ── Status badge ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final SpotStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SpotStatus.available     => ('🟢  Available',    AppTheme.neonGreen),
      SpotStatus.soonAvailable => ('🟡  Soon Free',    AppTheme.neonYellow),
      SpotStatus.lowConfidence => ('🔴  Low Confidence', AppTheme.neonRed),
      SpotStatus.taken         => ('⛔  Taken',        Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

// ── Gradient action button ────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final LinearGradient gradient;
  final IconData icon;
  final String label;

  const _ActionButton({required this.onTap, required this.gradient, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}

// ── Outlined action button ────────────────────────────────────────────────────
class _OutlineActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;

  const _OutlineActionButton({required this.onTap, required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
