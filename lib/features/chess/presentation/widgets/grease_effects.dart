import 'dart:math' as math;
import 'package:flutter/material.dart';

class GreaseTrailOverlay extends StatefulWidget {
  final Offset from;
  final Offset to;
  final VoidCallback onComplete;

  const GreaseTrailOverlay({
    super.key,
    required this.from,
    required this.to,
    required this.onComplete,
  });

  @override
  State<GreaseTrailOverlay> createState() => _GreaseTrailOverlayState();
}

class _GreaseTrailOverlayState extends State<GreaseTrailOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GreaseTrailPainter(
            from: widget.from,
            to: widget.to,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GreaseTrailPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final double progress;

  _GreaseTrailPainter({required this.from, required this.to, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = 1.0 - progress;
    if (opacity <= 0) return;

    final Paint trailPaint = Paint()
      ..color = const Color(0xFF111111).withValues(alpha: 0.5 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0 * (1.0 + progress * 0.5) // Spreading effect
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * progress + 2);

    final Path path = Path();
    path.moveTo(from.dx, from.dy);
    path.lineTo(to.dx, to.dy);

    canvas.drawPath(path, trailPaint);

    // Oily Reflection
    final Paint shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(path, shinePaint);
  }

  @override
  bool shouldRepaint(_GreaseTrailPainter oldDelegate) => true;
}

class OilSplashEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const OilSplashEffect({super.key, required this.position, required this.onComplete});

  @override
  State<OilSplashEffect> createState() => _OilSplashEffectState();
}

class _OilSplashEffectState extends State<OilSplashEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _OilSplashPainter(
            position: widget.position,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _OilSplashPainter extends CustomPainter {
  final Offset position;
  final double progress;

  _OilSplashPainter({required this.position, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = 1.0 - progress;
    final random = math.Random(123);
    
    final Paint paint = Paint()..color = const Color(0xFF111111).withValues(alpha: opacity);

    for (int i = 0; i < 12; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double dist = 10 + (progress * 50 * random.nextDouble());
      final double r = 5 * (1.0 - progress);
      
      canvas.drawCircle(
        position + Offset(math.cos(angle) * dist, math.sin(angle) * dist),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OilSplashPainter oldDelegate) => true;
}

class IndustrialAtmosphereOverlay extends StatelessWidget {
  const IndustrialAtmosphereOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Smoke Haze
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  center: Alignment.center,
                  radius: 1.5,
                ),
              ),
            ),
          ),
          // Subtle Lighting
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GreaseCheckPulse extends StatefulWidget {
  const GreaseCheckPulse({super.key});

  @override
  State<GreaseCheckPulse> createState() => _GreaseCheckPulseState();
}

class _GreaseCheckPulseState extends State<GreaseCheckPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3 * _controller.value),
            width: 8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.2 * _controller.value),
              blurRadius: 20,
              spreadRadius: 5,
            )
          ],
        ),
      ),
    );
  }
}
