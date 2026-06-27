import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../shared/themes/chess_theme.dart';
import '../../../shared/themes/animation_group.dart';

class InkTheme extends ChessTheme {
  const InkTheme() : super(id: 'theme3', name: 'Calligraphy');

  @override
  Color get lightSquare => const Color(0xFFF5F5DC);

  @override
  Color get darkSquare => const Color(0xFFD6D3D1);

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get frameColor => const Color(0xFF2C2C2C);

  @override
  AnimationGroup get animationGroup => AnimationGroup.d;

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const Positioned.fill(child: InkCheckSlash());
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return InkBoardPainter(isLight: isLight);
  }

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: BrushStrokePiecePainter(
          type: type.toUpperCase(),
          isWhite: isWhite,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return InkMoveHint(isEnemy: isEnemy);
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return const InkRippleIndicator(isActive: true);
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return InkSplashEffect(position: position, onComplete: onComplete);
  }

  @override
  Widget? buildAmbientOverlay(BuildContext context) {
    return null;
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: opacity),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// 1. Ink Board Painter
// ────────────────────────────────────────────────────────────────────────
class InkBoardPainter extends CustomPainter {
  final bool isLight;

  InkBoardPainter({required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isLight ? const Color(0xFFF5F5DC) : const Color(0xFFD6D3D1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final random = math.Random(isLight ? 42 : 13);
    final grainPaint = Paint();
    for (int i = 0; i < 150; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 0.8;
      grainPaint.color = Colors.black.withValues(
        alpha: random.nextDouble() * 0.03,
      );
      canvas.drawCircle(Offset(x, y), radius, grainPaint);
    }

    if (!isLight) {
      final washPaint = Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width * 0.5, size.height * 0.5),
          size.width * 0.7,
          [Colors.black.withValues(alpha: 0.05), Colors.transparent],
        );
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), washPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// 2. Brush Stroke Piece Painter
// ────────────────────────────────────────────────────────────────────────
class BrushStrokePiecePainter extends CustomPainter {
  final String type;
  final bool isWhite;
  final bool isHighlighted;

  BrushStrokePiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inkColor = isWhite
        ? Colors.black.withValues(alpha: 0.85)
        : const Color(0xFF1A1A1A);

    final strokeWidth = isWhite ? 2.2 : 3.8;

    final paint = Paint()
      ..color = inkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.4);

    final fillPaint = Paint()
      ..color = isWhite ? Colors.white : const Color(0xFF1A1A1A)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(size.width * 0.1, size.height * 0.1);
    final drawSize = size * 0.8;

    _drawPiecePath(canvas, drawSize, paint, fillPaint);
    canvas.restore();
  }

  void _drawPiecePath(Canvas canvas, Size size, Paint strokePaint, Paint fillPaint) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    final basePath = Path()
      ..moveTo(w * 0.2, h * 0.9)
      ..quadraticBezierTo(w * 0.5, h * 0.85, w * 0.8, h * 0.9);

    switch (type.toUpperCase()) {
      case 'P':
        path.moveTo(w * 0.5, h * 0.3);
        path.addOval(
          Rect.fromCenter(
            center: Offset(w * 0.5, h * 0.4),
            width: w * 0.3,
            height: h * 0.3,
          ),
        );
        path.moveTo(w * 0.35, h * 0.55);
        path.quadraticBezierTo(w * 0.5, h * 0.8, w * 0.65, h * 0.55);
        break;
      case 'R':
        path.moveTo(w * 0.3, h * 0.3);
        path.lineTo(w * 0.7, h * 0.3);
        path.lineTo(w * 0.7, h * 0.8);
        path.lineTo(w * 0.3, h * 0.8);
        path.close();
        path.moveTo(w * 0.3, h * 0.3);
        path.lineTo(w * 0.3, h * 0.2);
        path.lineTo(w * 0.4, h * 0.2);
        path.lineTo(w * 0.4, h * 0.3);
        path.moveTo(w * 0.6, h * 0.3);
        path.lineTo(w * 0.6, h * 0.2);
        path.lineTo(w * 0.7, h * 0.2);
        path.lineTo(w * 0.7, h * 0.3);
        break;
      case 'N':
        path.moveTo(w * 0.3, h * 0.8);
        path.quadraticBezierTo(w * 0.3, h * 0.3, w * 0.6, h * 0.2);
        path.quadraticBezierTo(w * 0.8, h * 0.4, w * 0.5, h * 0.5);
        path.quadraticBezierTo(w * 0.4, h * 0.7, w * 0.7, h * 0.8);
        break;
      case 'B':
        path.moveTo(w * 0.5, h * 0.2);
        path.quadraticBezierTo(w * 0.3, h * 0.5, w * 0.5, h * 0.8);
        path.quadraticBezierTo(w * 0.7, h * 0.5, w * 0.5, h * 0.2);
        path.moveTo(w * 0.45, h * 0.35);
        path.lineTo(w * 0.55, h * 0.45);
        break;
      case 'Q':
        path.moveTo(w * 0.5, h * 0.2);
        path.lineTo(w * 0.3, h * 0.4);
        path.lineTo(w * 0.4, h * 0.5);
        path.lineTo(w * 0.2, h * 0.6);
        path.lineTo(w * 0.5, h * 0.8);
        path.lineTo(w * 0.8, h * 0.6);
        path.lineTo(w * 0.6, h * 0.5);
        path.lineTo(w * 0.7, h * 0.4);
        path.close();
        break;
      case 'K':
        path.moveTo(w * 0.4, h * 0.2);
        path.lineTo(w * 0.6, h * 0.2);
        path.moveTo(w * 0.5, h * 0.1);
        path.lineTo(w * 0.5, h * 0.3);
        path.moveTo(w * 0.3, h * 0.4);
        path.quadraticBezierTo(w * 0.5, h * 0.2, w * 0.7, h * 0.4);
        path.lineTo(w * 0.7, h * 0.8);
        path.lineTo(w * 0.3, h * 0.8);
        path.close();
        break;
    }

    path.addPath(basePath, Offset.zero);
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    final jitterPath = Path();
    final random = math.Random(type.length + (isWhite ? 1 : 0));
    for (ui.PathMetric metric in path.computeMetrics()) {
      for (double i = 0; i < metric.length; i += 2) {
        final pos = metric.getTangentForOffset(i);
        if (pos != null) {
          final offset = Offset(
            pos.position.dx + (random.nextDouble() - 0.5) * 1.5,
            pos.position.dy + (random.nextDouble() - 0.5) * 1.5,
          );
          if (i == 0) {
            jitterPath.moveTo(offset.dx, offset.dy);
          } else {
            jitterPath.lineTo(offset.dx, offset.dy);
          }
        }
      }
    }
    canvas.drawPath(jitterPath, strokePaint..strokeWidth *= 0.8);
  }

  @override
  bool shouldRepaint(covariant BrushStrokePiecePainter oldDelegate) =>
      oldDelegate.isHighlighted != isHighlighted || oldDelegate.type != type;
}

// ────────────────────────────────────────────────────────────────────────
// 3. Selection Ripple Indicator
// ────────────────────────────────────────────────────────────────────────
class InkRippleIndicator extends StatelessWidget {
  final bool isActive;
  const InkRippleIndicator({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();
    return _InkRipple();
  }
}

class _InkRipple extends StatefulWidget {
  @override
  State<_InkRipple> createState() => _InkRippleState();
}

class _InkRippleState extends State<_InkRipple>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
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
      builder: (context, _) {
        return CustomPaint(
          painter: _InkRipplePainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _InkRipplePainter extends CustomPainter {
  final double progress;
  _InkRipplePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: opacity * 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, radius, paint);

    final outerPaint = Paint()
      ..color = Colors.black.withValues(alpha: opacity * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 1.2, outerPaint);
  }

  @override
  bool shouldRepaint(covariant _InkRipplePainter oldDelegate) => true;
}

// ────────────────────────────────────────────────────────────────────────
// 4. Capture Effect: Ink Splash (Optimized to 12 particles, central splash removed)
// ────────────────────────────────────────────────────────────────────────
class InkSplashEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const InkSplashEffect({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<InkSplashEffect> createState() => _InkSplashEffectState();
}

class _InkSplashEffectState extends State<InkSplashEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_SplashParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final random = math.Random();
    for (int i = 0; i < 12; i++) { // Reduced to 12 as per spec
      _particles.add(
        _SplashParticle(
          angle: random.nextDouble() * 2 * math.pi,
          speed: 2.0 + random.nextDouble() * 4.0,
          size: 3.0 + random.nextDouble() * 8.0,
        ),
      );
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
      builder: (context, _) {
        return CustomPaint(
          painter: _InkSplashPainter(
            position: widget.position,
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SplashParticle {
  final double angle;
  final double speed;
  final double size;
  _SplashParticle({
    required this.angle,
    required this.speed,
    required this.size,
  });
}

class _InkSplashPainter extends CustomPainter {
  final Offset position;
  final List<_SplashParticle> particles;
  final double progress;

  _InkSplashPainter({
    required this.position,
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      final distance = p.speed * progress * 50.0;
      final x = position.dx + math.cos(p.angle) * distance;
      final y = position.dy + math.sin(p.angle) * distance;

      canvas.drawCircle(Offset(x, y), p.size * (1.0 - progress * 0.5), paint);
      // Central blotch removed for cleaner visuals
    }
  }

  @override
  bool shouldRepaint(covariant _InkSplashPainter oldDelegate) => true;
}

// ────────────────────────────────────────────────────────────────────────
// 5. Ink Move Hint
// ────────────────────────────────────────────────────────────────────────
class InkMoveHint extends StatelessWidget {
  final bool isEnemy;
  const InkMoveHint({super.key, required this.isEnemy});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: isEnemy ? 45 : 18,
        height: isEnemy ? 45 : 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnemy
              ? Colors.transparent
              : Colors.black.withValues(alpha: 0.15),
          border: isEnemy
              ? Border.all(
                  color: Colors.black.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────
// 6. Ink Check Slash
// ────────────────────────────────────────────────────────────────────────
class InkCheckSlash extends StatefulWidget {
  const InkCheckSlash({super.key});

  @override
  State<InkCheckSlash> createState() => _InkCheckSlashState();
}

class _InkCheckSlashState extends State<InkCheckSlash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
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
      builder: (context, _) {
        return CustomPaint(
          painter: _InkSlashPainter(progress: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _InkSlashPainter extends CustomPainter {
  final double progress;
  _InkSlashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: (1.0 - progress).clamp(0.0, 0.4))
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.8)
      ..moveTo(size.width * 0.8, size.height * 0.2)
      ..lineTo(size.width * 0.2, size.height * 0.8);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InkSlashPainter oldDelegate) => true;
}
