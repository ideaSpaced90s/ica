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
