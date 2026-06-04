import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;

/// UI Utilities for Platinum Metallic Theme
class BrushedTextureUtility {
  static void drawBrushedMetal(
    Canvas canvas,
    Rect rect, {
    double grainDensity = 0.5,
  }) {
    final Paint grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final Random random = Random(42); // Seed for consistent grain
    final double step = 1.5;

    for (double y = rect.top; y < rect.bottom; y += step) {
      if (random.nextDouble() > grainDensity) continue;

      final double opacity = 0.03 + (random.nextDouble() * 0.05);
      grainPaint.color = Colors.white.withValues(alpha: opacity);

      // Horizontal grain across the entire board
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grainPaint);
    }
  }
}

class PlatinumBoardPainter extends CustomPainter {
  final bool isLight;
  final double animationValue;

  PlatinumBoardPainter({required this.isLight, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    // 1. Base Gradient for Depth
    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isLight
            ? [const Color(0xFFD1D5DB), const Color(0xFF9CA3AF)]
            : [const Color(0xFF4B5563), const Color(0xFF374151)],
      ).createShader(rect);

    canvas.drawRect(rect, basePaint);

    // 2. Brushed Metal Effect
    BrushedTextureUtility.drawBrushedMetal(canvas, rect);

    // 3. Subtle Inner Shadow / Edge Depth
    final Paint borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);

    // 4. Removed Animated light sweep (Lustre) for static design
  }

  @override
  bool shouldRepaint(PlatinumBoardPainter oldDelegate) =>
      oldDelegate.isLight != isLight ||
      oldDelegate.animationValue != animationValue;
}

class MetalPiece extends StatelessWidget {
  final chess_lib.PieceType type;
  final bool isWhite;
  final bool isHighlighted;
  final double animationValue;

  const MetalPiece({
    super.key,
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
    this.animationValue = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: MetalPiecePainter(
          type: type,
          isWhite: isWhite,
          isHighlighted: isHighlighted,
          animationValue: animationValue,
        ),
      ),
    );
  }
}

class MetalPiecePainter extends CustomPainter {
  final chess_lib.PieceType type;
  final bool isWhite;
  final bool isHighlighted;
  final double animationValue;

  MetalPiecePainter({
    required this.type,
    required this.isWhite,
    required this.isHighlighted,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _getMachinedPiecePath(type, size);
    final Rect bounds = path.getBounds();

    // 1. Strong Soft Drop Shadow
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);
    canvas.save();
    canvas.translate(2, 4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // 2. Subtle Reflection (Mirror effect)
    final Paint reflectionPaint = Paint()
      ..color = (isWhite ? Colors.white : Colors.black).withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.save();
    canvas.translate(0, size.height * 0.1);
    canvas.scale(1.0, -0.2); // Squashed upside down
    canvas.translate(0, -size.height);
    canvas.drawPath(path, reflectionPaint);
    canvas.restore();

    // 3. Layered Gradient Base (Material Realism)
    final Color topHighlight = isWhite
        ? const Color(0xFFF9FAFB)
        : const Color(0xFF1F2937);
    final Color midBody = isWhite
        ? const Color(0xFFE5E7EB)
        : const Color(0xFF111827);
    final Color bottomFalloff = isWhite
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF020617);

    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [topHighlight, midBody, bottomFalloff],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds);

    canvas.drawPath(path, bodyPaint);

    // 4. Sharp Static Specular Highlight Line
    const double specShift = 0.0;
    final Paint specularPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment(-0.5 + specShift, -1),
        end: Alignment(0.5 + specShift, 1),
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.8),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(bounds);

    canvas.drawPath(path, specularPaint);

    // 5. Removed Selection Highlight Sweep for static aesthetic
  }

  Path _getMachinedPiecePath(chess_lib.PieceType type, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    // Premium machined metal forms (minimal Staunton)
    switch (type) {
      case chess_lib.PieceType.PAWN:
        path.moveTo(midX - w * 0.15, h * 0.85);
        path.lineTo(midX + w * 0.15, h * 0.85);
        path.lineTo(midX + w * 0.1, h * 0.75);
        path.lineTo(midX + w * 0.1, h * 0.45);
        path.arcToPoint(
          Offset(midX - w * 0.1, h * 0.45),
          radius: Radius.circular(w * 0.1),
        );
        path.lineTo(midX - w * 0.1, h * 0.75);
        path.close();
        break;
      case chess_lib.PieceType.KNIGHT:
        path.moveTo(midX - w * 0.2, h * 0.85);
        path.lineTo(midX + w * 0.2, h * 0.85);
        path.lineTo(midX + w * 0.15, h * 0.75);
        path.lineTo(midX + w * 0.15, h * 0.6);
        path.lineTo(midX + w * 0.35, h * 0.4);
        path.lineTo(midX + w * 0.15, h * 0.2);
        path.lineTo(midX - w * 0.15, h * 0.2);
        path.lineTo(midX - w * 0.15, h * 0.75);
        path.close();
        break;
      case chess_lib.PieceType.BISHOP:
        path.moveTo(midX - w * 0.2, h * 0.85);
        path.lineTo(midX + w * 0.2, h * 0.85);
        path.lineTo(midX + w * 0.1, h * 0.75);
        path.lineTo(midX + w * 0.1, h * 0.3);
        path.lineTo(midX, h * 0.15);
        path.lineTo(midX - w * 0.1, h * 0.3);
        path.lineTo(midX - w * 0.1, h * 0.75);
        path.close();
        break;
      case chess_lib.PieceType.ROOK:
        path.moveTo(midX - w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.2, h * 0.75);
        path.lineTo(midX + w * 0.2, h * 0.3);
        path.lineTo(midX + w * 0.25, h * 0.3);
        path.lineTo(midX + w * 0.25, h * 0.2);
        path.lineTo(midX - w * 0.25, h * 0.2);
        path.lineTo(midX - w * 0.25, h * 0.3);
        path.lineTo(midX - w * 0.2, h * 0.3);
        path.lineTo(midX - w * 0.2, h * 0.75);
        path.close();
        break;
      case chess_lib.PieceType.QUEEN:
        path.moveTo(midX - w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.15, h * 0.7);
        path.lineTo(midX + w * 0.3, h * 0.3);
        path.lineTo(midX, h * 0.1);
        path.lineTo(midX - w * 0.3, h * 0.3);
        path.lineTo(midX - w * 0.15, h * 0.7);
        path.close();
        break;
      case chess_lib.PieceType.KING:
        path.moveTo(midX - w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.15, h * 0.7);
        path.lineTo(midX + w * 0.15, h * 0.3);
        path.lineTo(midX + w * 0.3, h * 0.3);
        path.lineTo(midX + w * 0.3, h * 0.1);
        path.lineTo(midX - w * 0.3, h * 0.1);
        path.lineTo(midX - w * 0.3, h * 0.3);
        path.lineTo(midX - w * 0.15, h * 0.3);
        path.lineTo(midX - w * 0.15, h * 0.7);
        path.close();
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(MetalPiecePainter oldDelegate) => true;
}

class PlatinumSelectionPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  PlatinumSelectionPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Rect rect = Offset.zero & size;
    final double inset = 2.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(inset), const Radius.circular(10)),
      paint,
    );

    // Removed animated sweep across the rim for static design
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class PlatinumMoveHintPainter extends CustomPainter {
  final bool isEnemy;

  PlatinumMoveHintPainter({required this.isEnemy});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = isEnemy ? size.width * 0.45 : size.width * 0.15;
    final center = Offset(size.width / 2, size.height / 2);

    // Metallic disc
    final Paint discPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFE5E7EB),
          const Color(0xFF9CA3AF),
          const Color(0xFF4B5563),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    if (isEnemy) {
      discPaint.style = PaintingStyle.stroke;
      discPaint.strokeWidth = 3.0;
      canvas.drawCircle(center, radius, discPaint);
    } else {
      discPaint.style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, discPaint);

      // Depth shadow
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PlatinumCaptureEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const PlatinumCaptureEffect({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<PlatinumCaptureEffect> createState() => _PlatinumCaptureEffectState();
}

class _PlatinumCaptureEffectState extends State<PlatinumCaptureEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _sink;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _sink = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInQuad),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 35,
      top: widget.position.dy - 35,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _sink.value),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFE5E7EB).withValues(alpha: 0.8),
                      const Color(0xFF9CA3AF).withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlatinumSpritePiecePainter extends CustomPainter {
  final chess_lib.PieceType type;
  final bool isWhite;
  final bool isHighlighted;

  PlatinumSpritePiecePainter({
    required this.type,
    required this.isWhite,
    this.isHighlighted = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = _getPiecePath(type, size);

    if (isWhite) {
      // White pieces: line-art with pure glowing white interior
      // 1. Glowing base fill
      final Paint glowFill = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(path, glowFill);

      final Paint solidFill = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white;
      canvas.drawPath(path, solidFill);

      // 2. Premium dark outline stroke
      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF1F2937)
        ..strokeWidth = size.width * 0.05
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
    } else {
      // Black pieces: solid filled silhouette with a subtle cool edge aura
      // 1. Soft distinct cyan-blue or cool-grey aura to keep solid shapes perfectly legible
      final Paint auraPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
      canvas.save();
      canvas.translate(0, 2);
      canvas.drawPath(path, auraPaint);
      canvas.restore();

      // 2. Primary solid black body
      final Paint fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF0F172A);
      canvas.drawPath(path, fillPaint);

      // Subtle inner rim line for exceptional material feel
      final Paint innerRim = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = size.width * 0.015;
      canvas.drawPath(path, innerRim);
    }
  }

  Path _getPiecePath(chess_lib.PieceType type, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    final double midX = w / 2;

    switch (type) {
      case chess_lib.PieceType.PAWN:
        // Base
        path.moveTo(midX - w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.2, h * 0.75);
        path.lineTo(midX - w * 0.2, h * 0.75);
        path.close();
        // Stem
        path.moveTo(midX - w * 0.15, h * 0.75);
        path.lineTo(midX + w * 0.15, h * 0.75);
        path.lineTo(midX + w * 0.08, h * 0.45);
        path.lineTo(midX - w * 0.08, h * 0.45);
        path.close();
        // Head sphere
        path.addOval(Rect.fromCircle(center: Offset(midX, h * 0.32), radius: w * 0.16));
        break;

      case chess_lib.PieceType.ROOK:
        // Base
        path.moveTo(midX - w * 0.3, h * 0.85);
        path.lineTo(midX + w * 0.3, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.75);
        path.lineTo(midX - w * 0.25, h * 0.75);
        path.close();
        // Body column
        path.moveTo(midX - w * 0.2, h * 0.75);
        path.lineTo(midX + w * 0.2, h * 0.75);
        path.lineTo(midX + w * 0.2, h * 0.4);
        path.lineTo(midX - w * 0.2, h * 0.4);
        path.close();
        // Crenellations (Castle Top)
        path.moveTo(midX - w * 0.25, h * 0.4);
        path.lineTo(midX + w * 0.25, h * 0.4);
        path.lineTo(midX + w * 0.25, h * 0.22);
        path.lineTo(midX + w * 0.12, h * 0.22);
        path.lineTo(midX + w * 0.12, h * 0.3);
        path.lineTo(midX + w * 0.05, h * 0.3);
        path.lineTo(midX + w * 0.05, h * 0.22);
        path.lineTo(midX - w * 0.05, h * 0.22);
        path.lineTo(midX - w * 0.05, h * 0.3);
        path.lineTo(midX - w * 0.12, h * 0.3);
        path.lineTo(midX - w * 0.12, h * 0.22);
        path.lineTo(midX - w * 0.25, h * 0.22);
        path.close();
        break;

      case chess_lib.PieceType.KNIGHT:
        // Base
        path.moveTo(midX - w * 0.3, h * 0.85);
        path.lineTo(midX + w * 0.3, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.75);
        path.lineTo(midX - w * 0.25, h * 0.75);
        path.close();
        // Horse profile
        path.moveTo(midX - w * 0.22, h * 0.75);
        path.lineTo(midX + w * 0.22, h * 0.75);
        path.lineTo(midX + w * 0.15, h * 0.55);
        path.lineTo(midX + w * 0.32, h * 0.42);
        path.lineTo(midX + w * 0.25, h * 0.22);
        path.lineTo(midX + w * 0.05, h * 0.18);
        path.lineTo(midX - w * 0.15, h * 0.32);
        path.lineTo(midX - w * 0.25, h * 0.32);
        path.lineTo(midX - w * 0.15, h * 0.52);
        path.lineTo(midX - w * 0.22, h * 0.75);
        path.close();
        // Eye slit
        path.addOval(Rect.fromCircle(center: Offset(midX + w * 0.08, h * 0.3), radius: w * 0.025));
        break;

      case chess_lib.PieceType.BISHOP:
        // Base
        path.moveTo(midX - w * 0.28, h * 0.85);
        path.lineTo(midX + w * 0.28, h * 0.85);
        path.lineTo(midX + w * 0.22, h * 0.75);
        path.lineTo(midX - w * 0.22, h * 0.75);
        path.close();
        // Mitre Oval body
        path.moveTo(midX - w * 0.2, h * 0.75);
        path.quadraticBezierTo(midX - w * 0.28, h * 0.45, midX, h * 0.25);
        path.quadraticBezierTo(midX + w * 0.28, h * 0.45, midX + w * 0.2, h * 0.75);
        path.close();
        // Top pearl
        path.addOval(Rect.fromCircle(center: Offset(midX, h * 0.2), radius: w * 0.04));
        break;

      case chess_lib.PieceType.QUEEN:
        // Base
        path.moveTo(midX - w * 0.32, h * 0.85);
        path.lineTo(midX + w * 0.32, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.75);
        path.lineTo(midX - w * 0.25, h * 0.75);
        path.close();
        // Crown body flaring to 5 points
        path.moveTo(midX - w * 0.2, h * 0.75);
        path.lineTo(midX - w * 0.35, h * 0.32); // Leftmost peak
        path.lineTo(midX - w * 0.15, h * 0.5);  // Inner dip
        path.lineTo(midX - w * 0.12, h * 0.25); // Mid-left peak
        path.lineTo(midX, h * 0.45);            // Center dip
        path.lineTo(midX + w * 0.12, h * 0.25); // Mid-right peak
        path.lineTo(midX + w * 0.15, h * 0.5);  // Inner dip
        path.lineTo(midX + w * 0.35, h * 0.32); // Rightmost peak
        path.lineTo(midX + w * 0.2, h * 0.75);
        path.close();
        // Floating center peak pearl
        path.addOval(Rect.fromCircle(center: Offset(midX, h * 0.18), radius: w * 0.045));
        break;

      case chess_lib.PieceType.KING:
        // Base
        path.moveTo(midX - w * 0.32, h * 0.85);
        path.lineTo(midX + w * 0.32, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.75);
        path.lineTo(midX - w * 0.25, h * 0.75);
        path.close();
        // Crown base body
        path.moveTo(midX - w * 0.22, h * 0.75);
        path.lineTo(midX - w * 0.28, h * 0.4);
        path.lineTo(midX - w * 0.1, h * 0.52);
        path.lineTo(midX, h * 0.35);
        path.lineTo(midX + w * 0.1, h * 0.52);
        path.lineTo(midX + w * 0.28, h * 0.4);
        path.lineTo(midX + w * 0.22, h * 0.75);
        path.close();
        // Center top cross
        final double cx = midX;
        final double cy = h * 0.22;
        final double cw = w * 0.04;
        final double ch = h * 0.12;
        // Vertical cross bar
        path.addRect(Rect.fromCenter(center: Offset(cx, cy), width: cw, height: ch));
        // Horizontal cross bar
        path.addRect(Rect.fromCenter(center: Offset(cx, cy - h * 0.01), width: ch * 0.8, height: cw));
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(PlatinumSpritePiecePainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.isWhite != isWhite ||
      oldDelegate.isHighlighted != isHighlighted;
}

class FloatingBubblesOverlay extends StatefulWidget {
  const FloatingBubblesOverlay({super.key});

  @override
  State<FloatingBubblesOverlay> createState() => _FloatingBubblesOverlayState();
}

class _FloatingBubblesOverlayState extends State<FloatingBubblesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = List.generate(15, (_) => _Bubble());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
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
        return CustomPaint(
          painter: _BubblePainter(_bubbles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Bubble {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double size = Random().nextDouble() * 15 + 5;
  double speed = Random().nextDouble() * 0.05 + 0.02;
  double drift = Random().nextDouble() * 0.1 - 0.05;
}

class _BubblePainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final double animationValue;

  _BubblePainter(this.bubbles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var b in bubbles) {
      final dx = size.width * ((b.x + animationValue * b.drift) % 1.0);
      final dy = size.height * ((b.y - animationValue * b.speed) % 1.0);

      paint.color = Colors.white.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(dx, dy), b.size, paint);

      // Highlight on bubble
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(dx - b.size * 0.3, dy - b.size * 0.3),
        b.size * 0.2,
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => true;
}
