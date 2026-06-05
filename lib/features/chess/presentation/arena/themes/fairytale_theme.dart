import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../shared/themes/animation_group.dart';
import '../../shared/animations/signature_move_style.dart';
import 'sprite_chess_theme.dart';

class FairytaleChessTheme extends SpriteChessTheme {
  const FairytaleChessTheme()
      : super(
          id: 'sprite_fairytale',
          name: 'Fairytale',
          individualPiecesFolder: 'assets/pieces/fairytale_castle',
          lightSquare: const Color(0xDCE7DEC9),
          darkSquare: const Color(0xDC5C5346),
          frameColor: const Color(0xFF3E3930),
        );

  @override
  AnimationGroup get animationGroup => AnimationGroup.c;

  @override
  SignatureMoveStyle? get signatureMoveStyle => const FairyDustTrail();

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return Container(
      color: const Color(0xFF1E1A14),
      child: CustomPaint(
        painter: FairytaleBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return const GlowSelectionRing();
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return FairyDustCapture(position: position, onComplete: onComplete);
  }

  @override
  Widget? buildAmbientOverlay(BuildContext context) {
    return const SparkleAmbient();
  }
}

class FairytaleBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.05);

    final random = Random(1111);

    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final sparkleSize = 2.0 + random.nextDouble() * 3.0;
      _drawSparkle(canvas, x, y, sparkleSize);
    }

    paint.color = const Color(0xFFE7DEC9).withValues(alpha: 0.06);
    
    _drawTower(canvas, paint, 30.0, size.height, 40.0, 65.0);
    _drawTower(canvas, paint, size.width - 70.0, size.height, 40.0, 65.0);
  }

  void _drawSparkle(Canvas canvas, double x, double y, double size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.08);

    final path = Path()
      ..moveTo(x, y - size)
      ..quadraticBezierTo(x, y, x + size, y)
      ..quadraticBezierTo(x, y, x, y + size)
      ..quadraticBezierTo(x, y, x - size, y)
      ..quadraticBezierTo(x, y, x, y - size)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawTower(Canvas canvas, Paint paint, double x, double y, double width, double height) {
    canvas.drawRect(Rect.fromLTWH(x, y - height, width, height), paint);
    
    final teethCount = 3;
    final toothWidth = width / (teethCount * 2 - 1);
    final toothHeight = 6.0;
    
    for (int i = 0; i < teethCount; i++) {
      final tx = x + (i * 2 * toothWidth);
      canvas.drawRect(Rect.fromLTWH(tx, y - height - toothHeight, toothWidth, toothHeight), paint);
    }
  }

  @override
  bool shouldRepaint(covariant FairytaleBackgroundPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// 1. Glow Selection Ring (Breathing Pink Glow)
// ────────────────────────────────────────────────────────────────────────
class GlowSelectionRing extends StatefulWidget {
  const GlowSelectionRing({super.key});

  @override
  State<GlowSelectionRing> createState() => _GlowSelectionRingState();
}

class _GlowSelectionRingState extends State<GlowSelectionRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return IgnorePointer(
          child: Center(
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Opacity(
                opacity: _opacityAnimation.value,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFFFFB6C1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// 2. Fairy Dust Capture Effect
// ────────────────────────────────────────────────────────────────────────
class FairyDustCapture extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  const FairyDustCapture({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<FairyDustCapture> createState() => _FairyDustCaptureState();
}

class _FairyDustCaptureState extends State<FairyDustCapture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_GlitterParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final random = Random();
    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFFF69B4),
      const Color(0xFFFFFFFF),
    ];

    for (int i = 0; i < 10; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 40.0 + random.nextDouble() * 60.0;
      final size = 4.0 + random.nextDouble() * 4.0;
      final rotationSpeed = (random.nextDouble() * 4 - 2) * pi;
      _particles.add(_GlitterParticle(
        angle: angle,
        speed: speed,
        size: size,
        rotationSpeed: rotationSpeed,
        color: colors[random.nextInt(colors.length)],
      ));
    }

    _controller.forward().then((_) => widget.onComplete());
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
          painter: _FairyDustPainter(
            center: widget.position,
            progress: _controller.value,
            particles: _particles,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _GlitterParticle {
  final double angle;
  final double speed;
  final double size;
  final double rotationSpeed;
  final Color color;

  _GlitterParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.color,
  });
}

class _FairyDustPainter extends CustomPainter {
  final Offset center;
  final double progress;
  final List<_GlitterParticle> particles;

  _FairyDustPainter({
    required this.center,
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = 1.0 - progress;

    for (final p in particles) {
      final distance = p.speed * progress;
      final px = center.dx + cos(p.angle) * distance;
      final py = center.dy + sin(p.angle) * distance;
      
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotationSpeed * progress);
      
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      
      final path = Path();
      final halfSize = p.size / 2;
      path.moveTo(0, -halfSize);
      path.lineTo(halfSize * 0.25, -halfSize * 0.25);
      path.lineTo(halfSize, 0);
      path.lineTo(halfSize * 0.25, halfSize * 0.25);
      path.lineTo(0, halfSize);
      path.lineTo(-halfSize * 0.25, halfSize * 0.25);
      path.lineTo(-halfSize, 0);
      path.lineTo(-halfSize * 0.25, -halfSize * 0.25);
      path.close();
      
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FairyDustPainter oldDelegate) {
    return true;
  }
}

// ────────────────────────────────────────────────────────────────────────
// 3. Sparkle Ambient Overlay (Twinkling sparkles)
// ────────────────────────────────────────────────────────────────────────
class SparkleAmbient extends StatefulWidget {
  const SparkleAmbient({super.key});

  @override
  State<SparkleAmbient> createState() => _SparkleAmbientState();
}

class _SparkleAmbientState extends State<SparkleAmbient>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  final List<_TwinkleSparkle> _sparkles = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    final colors = [
      const Color(0xFFFFD700),
      const Color(0xFFFF69B4),
      const Color(0xFFFFFFFF),
    ];

    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) return;
      if (_sparkles.length < 15) {
        final x = _random.nextDouble();
        final y = _random.nextDouble();
        setState(() {
          _sparkles.add(_TwinkleSparkle(
            xPercent: x,
            yPercent: y,
            startTime: DateTime.now(),
            duration: const Duration(milliseconds: 800),
            color: colors[_random.nextInt(colors.length)],
            maxSize: 4.0 + _random.nextDouble() * 4.0,
          ));
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    _sparkles.removeWhere((s) => now.difference(s.startTime) > s.duration);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _SparklePainter(sparkles: List.from(_sparkles)),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _TwinkleSparkle {
  final double xPercent;
  final double yPercent;
  final DateTime startTime;
  final Duration duration;
  final Color color;
  final double maxSize;

  _TwinkleSparkle({
    required this.xPercent,
    required this.yPercent,
    required this.startTime,
    required this.duration,
    required this.color,
    required this.maxSize,
  });

  double getProgress() {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    return (elapsed / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}

class _SparklePainter extends CustomPainter {
  final List<_TwinkleSparkle> sparkles;

  _SparklePainter({required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparkles) {
      final progress = s.getProgress();
      final double opacity = progress < 0.5 ? progress / 0.5 : (1.0 - progress) / 0.5;
      final x = s.xPercent * size.width;
      final y = s.yPercent * size.height;
      final starSize = s.maxSize * progress;

      final paint = Paint()
        ..color = s.color.withValues(alpha: opacity * 0.7)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(x, y - starSize);
      path.lineTo(x + starSize * 0.25, y - starSize * 0.25);
      path.lineTo(x + starSize, y);
      path.lineTo(x + starSize * 0.25, y + starSize * 0.25);
      path.lineTo(x, y + starSize);
      path.lineTo(x - starSize * 0.25, y + starSize * 0.25);
      path.lineTo(x - starSize, y);
      path.lineTo(x - starSize * 0.25, y - starSize * 0.25);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) {
    return true;
  }
}
