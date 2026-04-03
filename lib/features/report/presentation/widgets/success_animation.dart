import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SuccessAnimation extends StatefulWidget {
  final VoidCallback? onDismiss;

  const SuccessAnimation({super.key, this.onDismiss});

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  int _displayedPoints = 0;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _animatePoints();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onDismiss?.call();
    });
  }

  void _animatePoints() async {
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) setState(() => _displayedPoints = i);
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.85),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, _) {
              return CustomPaint(
                painter: _ParticlePainter(_particleController.value),
                size: MediaQuery.of(context).size,
              );
            },
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 60,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 200.ms),
                const SizedBox(height: 24),
                const Text(
                  'Successful Hunt! 🎯',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 400.ms),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '+$_displayedPoints points',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 300.ms)
                    .scale(
                      delay: 500.ms,
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: 300.ms,
                      curve: Curves.easeOut,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  static final List<_Particle> _particles = List.generate(
    30,
    (i) => _Particle(math.Random(i)),
  );

  _ParticlePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      final animProgress = (progress + particle.offset) % 1.0;
      final opacity = (1.0 - animProgress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final x = particle.startX * size.width +
          math.sin(animProgress * math.pi * 2 + particle.phase) * 60;
      final y = size.height * 0.5 - animProgress * size.height * 0.6;
      final radius = particle.radius * (1 - animProgress * 0.5);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double startX;
  final double offset;
  final double phase;
  final double radius;
  final Color color;

  _Particle(math.Random random)
      : startX = random.nextDouble(),
        offset = random.nextDouble(),
        phase = random.nextDouble() * math.pi * 2,
        radius = 4 + random.nextDouble() * 8,
        color = _colors[random.nextInt(_colors.length)];

  static const List<Color> _colors = [
    Color(0xFFFF6B35),
    Color(0xFF4CAF50),
    Color(0xFFFFEB3B),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
  ];
}
