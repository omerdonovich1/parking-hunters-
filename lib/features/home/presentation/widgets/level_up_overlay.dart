import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../services/gamification_service.dart';

class LevelUpOverlay extends ConsumerWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpOverlay({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appStringsProvider);
    final title = GamificationService().getLevelTitle(newLevel);

    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⬆️', style: TextStyle(fontSize: 64))
                  .animate()
                  .scaleXY(begin: 0.3, end: 1.0, duration: 500.ms, curve: Curves.elasticOut)
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              Text(
                s.levelUp,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  s.levelBadge(newLevel, title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 400.ms)
                  .scaleXY(begin: 0.8, end: 1.0),
              const SizedBox(height: 32),
              Text(
                s.tapToContinue,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
            ],
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 2000.ms,
                color: Colors.white.withValues(alpha: 0.05),
              ),
        ),
      ),
    );
  }
}
