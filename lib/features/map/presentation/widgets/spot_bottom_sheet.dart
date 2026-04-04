import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/parking_spot_model.dart';
import '../../../../providers/map_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'spot_photo_viewer.dart';

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
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
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
    if (await canLaunchUrl(wazeUrl)) {
      await launchUrl(wazeUrl);
      return;
    }
    final gmapsUrl = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(gmapsUrl)) {
      await launchUrl(gmapsUrl);
      return;
    }
    final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }

  Color _statusColor(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return const Color(0xFF22C55E);
      case SpotStatus.soonAvailable:
        return const Color(0xFFF59E0B);
      case SpotStatus.lowConfidence:
        return const Color(0xFFEF4444);
      case SpotStatus.taken:
        return const Color(0xFF94A3B8);
    }
  }

  String _statusLabel(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return 'Available';
      case SpotStatus.soonAvailable:
        return 'Soon Available';
      case SpotStatus.lowConfidence:
        return 'Low Confidence';
      case SpotStatus.taken:
        return 'Taken';
    }
  }

  IconData _statusIcon(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return Icons.check_circle_rounded;
      case SpotStatus.soonAvailable:
        return Icons.schedule_rounded;
      case SpotStatus.lowConfidence:
        return Icons.warning_rounded;
      case SpotStatus.taken:
        return Icons.block_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  String _timeRemaining(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    if (remaining.inSeconds < 60) return '${remaining.inSeconds}s';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes}min';
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
  }

  Color _timeRemainingColor(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return const Color(0xFF94A3B8);
    if (remaining.inMinutes < 5) return const Color(0xFFEF4444);
    if (remaining.inMinutes < 15) return const Color(0xFFF59E0B);
    return AppTheme.blue;
  }

  double _timeRemainingFraction(DateTime expiresAt, DateTime reportedAt) {
    final total = expiresAt.difference(reportedAt).inSeconds;
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    if (total <= 0) return 0;
    return (remaining / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(spot.status);
    final confidencePercent = (spot.confidence * 100).toInt();
    final timeColor = _timeRemainingColor(spot.expiresAt);
    final timeFraction = _timeRemainingFraction(spot.expiresAt, spot.reportedAt);
    final bg = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final surface = isDark ? const Color(0xFF252B3B) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? const Color(0xFF8B9CB8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status header row
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_statusIcon(spot.status), color: statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusLabel(spot.status),
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Reported ${_timeAgo(spot.reportedAt)}',
                            style: TextStyle(color: textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    // Time remaining pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: timeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer_rounded, size: 13, color: timeColor),
                          const SizedBox(width: 4),
                          Text(
                            _timeRemaining(spot.expiresAt),
                            style: TextStyle(
                              color: timeColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Confidence + time bar card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Confidence
                      Row(
                        children: [
                          Text(
                            'Confidence',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$confidencePercent%',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        percent: spot.confidence.clamp(0.0, 1.0),
                        lineHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                        progressColor: statusColor,
                        barRadius: const Radius.circular(3),
                        padding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 14),

                      // Time remaining bar
                      Row(
                        children: [
                          Text(
                            'Time Remaining',
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _timeRemaining(spot.expiresAt),
                            style: TextStyle(
                              color: timeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearPercentIndicator(
                        percent: timeFraction,
                        lineHeight: 6,
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                        progressColor: timeColor,
                        barRadius: const Radius.circular(3),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),

                // Note
                if (spot.note != null && spot.note!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes_rounded, size: 16, color: textMuted),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            spot.note!,
                            style: TextStyle(color: textPrimary, fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Photo
                if (spot.photoUrl != null && spot.photoUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        SpotPhotoThumbnail(photoUrl: spot.photoUrl!),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 13),
                                SizedBox(width: 4),
                                Text('Tap to expand',
                                    style: TextStyle(color: Colors.white, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Navigate button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _navigateToSpot,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.navigation_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Navigate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Mark as taken
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ref.read(firestoreServiceProvider).markSpotTaken(spot.id);
                      ref.read(parkingSpotsProvider.notifier).removeExpiredSpots();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Spot marked as taken — thanks!'),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textPrimary,
                      side: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Mark as Taken',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Deny / Confirm row
                Row(
                  children: [
                    Expanded(
                      child: _ActionChip(
                        label: 'Not There',
                        icon: Icons.thumb_down_rounded,
                        color: const Color(0xFFEF4444),
                        isDark: isDark,
                        onTap: () {
                          ref.read(firestoreServiceProvider).denySpot(spot.id, 'local_user');
                          ref.read(parkingSpotsProvider.notifier).updateSpot(
                                spot.copyWith(
                                  confidence: (spot.confidence - 0.1).clamp(0.0, 1.0),
                                ),
                              );
                          Navigator.pop(context);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Spot denied'),
                                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ActionChip(
                        label: 'Still Free',
                        icon: Icons.thumb_up_rounded,
                        color: const Color(0xFF22C55E),
                        isDark: isDark,
                        onTap: () {
                          ref.read(firestoreServiceProvider).confirmSpot(spot.id, 'local_user');
                          ref.read(parkingSpotsProvider.notifier).updateSpot(
                                spot.copyWith(
                                  confidence: (spot.confidence + 0.1).clamp(0.0, 1.0),
                                ),
                              );
                          Navigator.pop(context);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Spot confirmed! +5 points'),
                                backgroundColor: const Color(0xFF22C55E),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
