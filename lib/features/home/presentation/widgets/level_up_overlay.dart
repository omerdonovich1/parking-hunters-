import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/gamification_service.dart';

class LevelUpOverlay extends StatelessWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final title = GamificationService().getLevelTitle(newLevel);
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.88),
        child: Stack(
          children: [
            // Star particles bursting from center
            ..._buildStars(size),
            // Central content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLevelBadge(newLevel),
                  const SizedBox(height: 28),
                  const Text(
                    'LEVEL UP!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                    ),
                  )
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.3, end: 0)
                      .then()
                      .shimmer(
                        duration: 1800.ms,
                        color: AppTheme.orange.withValues(alpha: 0.7),
                      ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.orange, Color(0xFFFF3D00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.orange.withValues(alpha: 0.55),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      '$title · Level $newLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      .animate(delay: 650.ms)
                      .fadeIn(duration: 400.ms)
                      .scaleXY(
                          begin: 0.7,
                          end: 1.0,
                          curve: Curves.elasticOut,
                          duration: 700.ms),
                  const SizedBox(height: 44),
                  Text(
                    'Tap anywhere to continue',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14,
                    ),
                  ).animate(delay: 1600.ms).fadeIn(duration: 500.ms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int level) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulsing outer glow
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.orange.withValues(alpha: 0.55),
                blurRadius: 50,
                spreadRadius: 12,
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.88, end: 1.12, duration: 900.ms),
        // Ring border
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.orange, width: 3),
            gradient: RadialGradient(
              colors: [
                AppTheme.orange.withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ),
          ),
        ),
        // Level number
        Text(
          '$level',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 66,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    )
        .animate()
        .scaleXY(
            begin: 0.2,
            end: 1.0,
            duration: 650.ms,
            curve: Curves.elasticOut)
        .fadeIn(duration: 300.ms);
  }

  List<Widget> _buildStars(Size size) {
    const emojis = ['⭐', '✨', '🌟', '💫', '⚡', '🏆'];
    final rng = Random(newLevel * 7);

    return List.generate(14, (i) {
      final angle = (i / 14) * 2 * pi;
      final distance = 130.0 + rng.nextDouble() * 90;
      final cx = size.width / 2;
      final cy = size.height / 2;
      final x = cx + cos(angle) * distance;
      final y = cy + sin(angle) * distance;
      final emoji = emojis[i % emojis.length];
      final fontSize = 16.0 + rng.nextDouble() * 18;
      final delay = (i * 55).ms;
      // offset from final position back to center
      final dx = cx - x;
      final dy = cy - y;

      return Positioned(
        left: x - fontSize / 2,
        top: y - fontSize / 2,
        child: Text(emoji, style: TextStyle(fontSize: fontSize))
            .animate(delay: delay)
            .move(
              begin: Offset(dx, dy),
              end: Offset.zero,
              duration: 600.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(duration: 200.ms)
            .scaleXY(begin: 0.3, end: 1.0, duration: 500.ms)
            .then(delay: 700.ms)
            .fadeOut(duration: 500.ms),
      );
    });
  }
}
