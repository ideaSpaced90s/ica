import 'dart:math';
import 'package:flutter/material.dart';
import '../../../shared/themes/animation_group.dart';
import '../../../shared/animations/signature_move_style.dart';
import '../../../shared/animations/piece_motion_profile.dart';
import '../global/sprite_chess_theme.dart';

class PlasmaChessTheme extends SpriteChessTheme {
  const PlasmaChessTheme()
      : super(
          id: 'sprite_plasma',
          name: 'Plasma',
          individualPiecesFolder: 'assets/pieces/energy-webP',
          pieceExtension: 'webp',
          lightSquare: const Color(0xDC0D1117),
          darkSquare: const Color(0xDC0F2C59),
          frameColor: const Color(0xFF00BFFF),
        );

  @override
  AnimationGroup get animationGroup => AnimationGroup.c;

  @override
  SignatureMoveStyle? get signatureMoveStyle => const PlasmaModernSignature();

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    if (animationsEnabled) {
      return const PlasmaFlowBackground();
    }
    return Container(
      color: const Color(0xFF070B11),
      child: CustomPaint(
        painter: PlasmaBackgroundPainter(),
        size: Size.infinite,
      ),
    );
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return const PlasmaRingSelection();
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return PlasmaDissolveCapture(position: position, onComplete: onComplete);
  }

  @override
  PieceMotionProfile getPieceMotionProfile(String pieceCode) {
    final type = pieceCode.length > 1
        ? pieceCode.substring(1).toUpperCase()
        : pieceCode.toUpperCase();
    switch (type) {
      case 'Q':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 480),
          moveCurve: Curves.easeInOutCubic,
        );
      case 'N':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 440),
          moveCurve: Curves.easeInOutQuad,
        );
      case 'R':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 380),
          moveCurve: Curves.easeOutCubic,
        );
      case 'B':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 380),
          moveCurve: Curves.easeOutCubic,
        );
      case 'K':
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 420),
          moveCurve: Curves.easeInOutQuad,
        );
      case 'P':
      default:
        return const PieceMotionProfile(
          moveDuration: Duration(milliseconds: 300),
          moveCurve: Curves.easeOutCubic,
        );
    }
  }
}

// ────────────────────────────────────────────────────────────────────────
// 1. Plasma Flow Background (with hue rotation)
// ────────────────────────────────────────────────────────────────────────
class PlasmaFlowBackground extends StatefulWidget {
  const PlasmaFlowBackground({super.key});

  @override
  State<PlasmaFlowBackground> createState() => _PlasmaFlowBackgroundState();
}

class _PlasmaFlowBackgroundState extends State<PlasmaFlowBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
      builder: (context, child) {
        final double value = _controller.value;
        final color1 = Color.lerp(
          const Color(0xFF070B11),
          const Color(0xFF140727),
          (sin(value * 2 * pi) + 1) / 2,
        )!;
        final color2 = Color.lerp(
          const Color(0xFF0A1E3F),
          const Color(0xFF05242C),
          (cos(value * 2 * pi) + 1) / 2,
        )!;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CustomPaint(
            painter: PlasmaBackgroundPainter(),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class PlasmaBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw cybernetic grid
    final gridPaint = Paint()
      ..color = const Color(0xFF00BFFF).withValues(alpha: 0.035)
      ..strokeWidth = 1.0;
    
    final int gridCount = 10;
    for (int i = 0; i <= gridCount; i++) {
      final x = size.width * (i / gridCount);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      final y = size.height * (i / gridCount);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF00BFFF).withValues(alpha: 0.05);

    final random = Random(8888);

    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 30.0 + random.nextDouble() * 60.0;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    paint.color = const Color(0xFF00E5FF).withValues(alpha: 0.08);
    for (int i = 0; i < 20; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1.5 + random.nextDouble() * 2.5;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PlasmaBackgroundPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// 2. Pulsing Neon Selection Ring
// ────────────────────────────────────────────────────────────────────────
class PlasmaRingSelection extends StatefulWidget {
  const PlasmaRingSelection({super.key});

  @override
  State<PlasmaRingSelection> createState() => _PlasmaRingSelectionState();
}

class _PlasmaRingSelectionState extends State<PlasmaRingSelection>
    with SingleTickerProviderStateMixin {
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
      builder: (context, child) {
        return IgnorePointer(
          child: CustomPaint(
            painter: _PlasmaRingPainter(progress: _controller.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _PlasmaRingPainter extends CustomPainter {
  final double progress;

  _PlasmaRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final strokeWidth = 2.5 + progress * 1.5;
    final opacity = 0.5 + progress * 0.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF9C3FE4).withValues(alpha: opacity),
          const Color(0xFF00BFFF).withValues(alpha: opacity),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRect(rect.deflate(strokeWidth / 2), paint);
  }

  @override
  bool shouldRepaint(covariant _PlasmaRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ────────────────────────────────────────────────────────────────────────
// 3. Plasma Dissolve Capture Effect
// ────────────────────────────────────────────────────────────────────────
class PlasmaDissolveCapture extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  const PlasmaDissolveCapture({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<PlasmaDissolveCapture> createState() => _PlasmaDissolveCaptureState();
}

class _PlasmaDissolveCaptureState extends State<PlasmaDissolveCapture>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_PlasmaPixel> _pixels = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    final random = Random();
    for (int i = 0; i < 20; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = 30.0 + random.nextDouble() * 60.0;
      final size = 3.0 + random.nextDouble() * 4.0;
      final verticalDrift = -30.0 - random.nextDouble() * 40.0;
      _pixels.add(_PlasmaPixel(
        angle: angle,
        speed: speed,
        size: size,
        verticalDrift: verticalDrift,
        color: random.nextBool()
            ? const Color(0xFF9C3FE4)
            : const Color(0xFF00BFFF),
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
          painter: _PlasmaDissolvePainter(
            center: widget.position,
            progress: _controller.value,
            pixels: _pixels,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _PlasmaPixel {
  final double angle;
  final double speed;
  final double size;
  final double verticalDrift;
  final Color color;

  _PlasmaPixel({
    required this.angle,
    required this.speed,
    required this.size,
    required this.verticalDrift,
    required this.color,
  });
}

class _PlasmaDissolvePainter extends CustomPainter {
  final Offset center;
  final double progress;
  final List<_PlasmaPixel> pixels;

  _PlasmaDissolvePainter({
    required this.center,
    required this.progress,
    required this.pixels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final opacity = 1.0 - progress;

    for (final p in pixels) {
      final dist = p.speed * progress;
      final x = center.dx + cos(p.angle) * dist;
      final y = center.dy + sin(p.angle) * dist + p.verticalDrift * progress;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: p.size, height: p.size),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlasmaDissolvePainter oldDelegate) {
    return true;
  }
}
