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

    // Try Waze first, fall back to Google Maps
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
    // Web fallback
    final webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    await launchUrl(webUrl, mode: LaunchMode.externalApplication);
  }

  Color _statusColor(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return AppTheme.secondaryColor;
      case SpotStatus.soonAvailable:
        return Colors.orange;
      case SpotStatus.lowConfidence:
        return Colors.red;
      case SpotStatus.taken:
        return Colors.grey;
    }
  }

  String _statusLabel(SpotStatus status) {
    switch (status) {
      case SpotStatus.available:
        return '🟢 Available';
      case SpotStatus.soonAvailable:
        return '🟡 Soon Available';
      case SpotStatus.lowConfidence:
        return '🔴 Low Confidence';
      case SpotStatus.taken:
        return '⛔ Taken';
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
    if (remaining.inSeconds < 60) return '${remaining.inSeconds}s left';
    if (remaining.inMinutes < 60) return '${remaining.inMinutes}min left';
    return '${remaining.inHours}h ${remaining.inMinutes % 60}m left';
  }

  Color _timeRemainingColor(DateTime expiresAt) {
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return Colors.grey;
    if (remaining.inMinutes < 5) return Colors.red;
    if (remaining.inMinutes < 15) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final spot = widget.spot;
    final statusColor = _statusColor(spot.computedStatus);
    final confidencePercent = (spot.confidence * 100).toInt();
    final aiPercent = (spot.aiConfidence * 100).toInt();
    final timeColor = _timeRemainingColor(spot.expiresAt);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    _statusLabel(spot.computedStatus),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: timeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: timeColor),
                      const SizedBox(width: 4),
                      Text(
                        _timeRemaining(spot.expiresAt),
                        style: TextStyle(
                          color: timeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Live Probability', style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '$confidencePercent%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearPercentIndicator(
              percent: spot.confidence.clamp(0.0, 1.0),
              lineHeight: 14,
              backgroundColor: Colors.grey.shade200,
              progressColor: statusColor,
              barRadius: const Radius.circular(7),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'AI Scan',
                    value: '$aiPercent%',
                    icon: Icons.auto_awesome,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Time Factor',
                    value: _timeRemaining(spot.expiresAt),
                    icon: Icons.timer_outlined,
                    color: timeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Reported ${_timeAgo(spot.reportedAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            if (spot.note != null && spot.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      spot.note!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            // Photo thumbnail
            if (spot.photoUrl != null && spot.photoUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  SpotPhotoThumbnail(photoUrl: spot.photoUrl!),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Tap to expand',
                            style: TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToSpot,
                icon: const Icon(Icons.navigation_outlined),
                label: const Text(
                  'Navigate',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Mark as Taken — full width prominent button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref
                      .read(firestoreServiceProvider)
                      .markSpotTaken(spot.id);
                  ref
                      .read(parkingSpotsProvider.notifier)
                      .removeExpiredSpots();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🅿️ Spot marked as taken — thanks!'),
                        backgroundColor: Colors.blueGrey,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.no_meeting_room_outlined),
                label: const Text('Mark as Taken'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(firestoreServiceProvider)
                          .denySpot(spot.id, 'local_user');
                      ref.read(parkingSpotsProvider.notifier).updateSpot(
                            spot.copyWith(
                              confidence:
                                  (spot.confidence - 0.1).clamp(0.0, 1.0),
                            ),
                          );
                      Navigator.pop(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Spot denied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.thumb_down_outlined, color: Colors.red),
                    label: const Text('Not There',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(firestoreServiceProvider)
                          .confirmSpot(spot.id, 'local_user');
                      ref.read(parkingSpotsProvider.notifier).updateSpot(
                            spot.copyWith(
                              confidence:
                                  (spot.confidence + 0.1).clamp(0.0, 1.0),
                            ),
                          );
                      Navigator.pop(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Spot confirmed! +5 points'),
                            backgroundColor: AppTheme.secondaryColor,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: const Text('Still Free'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
