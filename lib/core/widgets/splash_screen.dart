import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05080F),
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.blue.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.blue.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.blue,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.blue.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🅿️', style: TextStyle(fontSize: 48)),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scaleXY(
                      begin: 0.5,
                      end: 1.0,
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 32),

                // App name
                const Text(
                  'Parking Hunter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.4, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 10),

                // Tagline
                Text(
                  'Find parking. Beat the city.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 15,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w400,
                  ),
                )
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 80),

                // Loading bar
                SizedBox(
                  width: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.08),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.blue),
                      minHeight: 3,
                    ),
                  ),
                ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
