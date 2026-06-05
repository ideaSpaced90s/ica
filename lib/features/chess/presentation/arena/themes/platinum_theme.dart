import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../shared/themes/chess_theme.dart';
import '../../shared/themes/animation_group.dart';

class PlatinumTheme extends ChessTheme {
  const PlatinumTheme() : super(id: 'theme4', name: 'Platinum');

  @override
  Color get lightSquare => const Color(0xFFD1D5DB);

  @override
  Color get darkSquare => const Color(0xFF374151);

  @override
  Color get lightCoordinateColor => Colors.black87.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white70;

  @override
  Color get frameColor => const Color(0xFF1F2933);

  @override
  BorderRadius get squareBorderRadius => BorderRadius.circular(10);

  @override
  AnimationGroup get animationGroup => AnimationGroup.d;

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return PlatinumBoardPainter(
      isLight: isLight,
      animationValue: animationValue,
    );
  }

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    chess_lib.PieceType pType;
    switch (type.toUpperCase()) {
      case 'K':
        pType = chess_lib.PieceType.KING;
        break;
      case 'Q':
        pType = chess_lib.PieceType.QUEEN;
        break;
      case 'R':
        pType = chess_lib.PieceType.ROOK;
        break;
      case 'B':
        pType = chess_lib.PieceType.BISHOP;
        break;
      case 'N':
        pType = chess_lib.PieceType.KNIGHT;
        break;
      case 'P':
        pType = chess_lib.PieceType.PAWN;
        break;
      default:
        pType = chess_lib.PieceType.PAWN;
    }

    return AspectRatio(
      aspectRatio: 1,
      child: CustomPaint(
        painter: PlatinumSpritePiecePainter(
          type: pType,
          isWhite: isWhite,
          isHighlighted: isHighlighted,
        ),
      ),
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return CustomPaint(
      painter: PlatinumMoveHintPainter(isEnemy: isEnemy),
      size: Size.infinite,
    );
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return CustomPaint(
      painter: PlatinumSelectionPainter(
        animationValue: 0.0,
        color: Colors.white,
      ),
      size: Size.infinite,
    );
  }

  @override
  Widget? buildCaptureEffect(
      BuildContext context, Offset position, VoidCallback onComplete) {
    return PlatinumCaptureEffect(position: position, onComplete: onComplete);
  }

  @override
  Widget? buildAmbientOverlay(BuildContext context) {
    return const FloatingBubblesOverlay();
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
// 1. Brushed Texture Utility & Board Painter
// ────────────────────────────────────────────────────────────────────────
class BrushedTextureUtility {
  static void drawBrushedMetal(Canvas canvas, Rect rect, {double grainDensity = 0.5}) {
    final Paint grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final Random random = Random(42);
    final double step = 1.5;

    for (double y = rect.top; y < rect.bottom; y += step) {
      if (random.nextDouble() > grainDensity) continue;

      final double opacity = 0.03 + (random.nextDouble() * 0.05);
      grainPaint.color = Colors.white.withValues(alpha: opacity);
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
    final Paint basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isLight
            ? [const Color(0xFFD1D5DB), const Color(0xFF9CA3AF)]
            : [const Color(0xFF4B5563), const Color(0xFF374151)],
      ).createShader(rect);

    canvas.drawRect(rect, basePaint);
    BrushedTextureUtility.drawBrushedMetal(canvas, rect);

    final Paint borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(PlatinumBoardPainter oldDelegate) =>
      oldDelegate.isLight != isLight ||
      oldDelegate.animationValue != animationValue;
}

// ────────────────────────────────────────────────────────────────────────
// 2. Platinum Selection Painter (Thin silver border rim)
// ────────────────────────────────────────────────────────────────────────
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// 3. Platinum Move Hint Painter
// ────────────────────────────────────────────────────────────────────────
class PlatinumMoveHintPainter extends CustomPainter {
  final bool isEnemy;

  PlatinumMoveHintPainter({required this.isEnemy});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = isEnemy ? size.width * 0.45 : size.width * 0.15;
    final center = Offset(size.width / 2, size.height / 2);

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

// ────────────────────────────────────────────────────────────────────────
// 4. Platinum Capture Effect (Sink & Glow)
// ────────────────────────────────────────────────────────────────────────
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
      duration: const Duration(milliseconds: 500), // Reduced to 500ms
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    _sink = Tween<double>(begin: 0.0, end: 12.0).animate( // Reduced to 12px sink
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

// ────────────────────────────────────────────────────────────────────────
// 5. Platinum Piece Painter
// ────────────────────────────────────────────────────────────────────────
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
      final Paint glowFill = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
      canvas.drawPath(path, glowFill);

      final Paint solidFill = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white;
      canvas.drawPath(path, solidFill);

      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF1F2937)
        ..strokeWidth = size.width * 0.05
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
    } else {
      final Paint auraPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
      canvas.save();
      canvas.translate(0, 2);
      canvas.drawPath(path, auraPaint);
      canvas.restore();

      final Paint fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFF0F172A);
      canvas.drawPath(path, fillPaint);

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
        path.moveTo(midX - w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.85);
        path.lineTo(midX + w * 0.2, h * 0.75);
        path.lineTo(midX - w * 0.2, h * 0.75);
        path.close();
        path.moveTo(midX - w * 0.15, h * 0.75);
        path.lineTo(midX + w * 0.15, h * 0.75);
        path.lineTo(midX + w * 0.08, h * 0.45);
        path.lineTo(midX - w * 0.08, h * 0.45);
        path.close();
        path.addOval(Rect.fromCircle(center: Offset(midX, h * 0.32), radius: w * 0.16));
        break;

      case chess_lib.PieceType.ROOK:
        path.moveTo(midX - w * 0.3, h * 0.85);
        path.lineTo(midX + w * 0.3, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.75);
        path.lineTo(midX - w * 0.25, h * 0.75);
        path.close();
        path.moveTo(midX - w * 0.2, h * 0.75);
        path.lineTo(midX + w * 0.2, h * 0.75);
        path.lineTo(midX + w * 0.2, h * 0.4);
        path.lineTo(midX - w * 0.2, h * 0.4);
        path.close();
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
        path.moveTo(midX - w * 0.3, h * 0.85);
        path.lineTo(midX + w * 0.3, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.75);
        path.lineTo(midX - w * 0.25, h * 0.75);
        path.close();
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
        path.addOval(Rect.fromCircle(center: Offset(midX + w * 0.08, h * 0.3), radius: w * 0.025));
        break;

      case chess_lib.PieceType.BISHOP:
        path.moveTo(midX - w * 0.28, h * 0.85);
        path.lineTo(midX + w * 0.28, h * 0.85);
        path.lineTo(midX + w * 0.22, h * 0.75);
        path.lineTo(midX - w * 0.22, h * 0.75);
        path.close();
        path.moveTo(midX - w * 0.2, h * 0.75);
        path.quadraticBezierTo(midX - w * 0.28, h * 0.45, midX, h * 0.25);
        path.quadraticBezierTo(midX + w * 0.28, h * 0.45, midX + w * 0.2, h * 0.75);
        path.close();
        path.addOval(Rect.fromCircle(center: Offset(midX, h * 0.2), radius: w * 0.04));
        break;

      case chess_lib.PieceType.QUEEN:
        path.moveTo(midX - w * 0.32, h * 0.85);
        path.lineTo(midX + w * 0.32, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.75);
        path.lineTo(midX - w * 0.25, h * 0.75);
        path.close();
        path.moveTo(midX - w * 0.2, h * 0.75);
        path.lineTo(midX - w * 0.35, h * 0.32);
        path.lineTo(midX - w * 0.15, h * 0.5);
        path.lineTo(midX - w * 0.12, h * 0.25);
        path.lineTo(midX, h * 0.45);
        path.lineTo(midX + w * 0.12, h * 0.25);
        path.lineTo(midX + w * 0.15, h * 0.5);
        path.lineTo(midX + w * 0.35, h * 0.32);
        path.lineTo(midX + w * 0.2, h * 0.75);
        path.close();
        path.addOval(Rect.fromCircle(center: Offset(midX, h * 0.18), radius: w * 0.045));
        break;

      case chess_lib.PieceType.KING:
        path.moveTo(midX - w * 0.32, h * 0.85);
        path.lineTo(midX + w * 0.32, h * 0.85);
        path.lineTo(midX + w * 0.25, h * 0.75);
        path.lineTo(midX - w * 0.25, h * 0.75);
        path.close();
        path.moveTo(midX - w * 0.22, h * 0.75);
        path.lineTo(midX - w * 0.28, h * 0.4);
        path.lineTo(midX - w * 0.1, h * 0.52);
        path.lineTo(midX, h * 0.35);
        path.lineTo(midX + w * 0.1, h * 0.52);
        path.lineTo(midX + w * 0.28, h * 0.4);
        path.lineTo(midX + w * 0.22, h * 0.75);
        path.close();
        final double cx = midX;
        final double cy = h * 0.22;
        final double cw = w * 0.04;
        final double ch = h * 0.12;
        path.addRect(Rect.fromCenter(center: Offset(cx, cy), width: cw, height: ch));
        path.addRect(Rect.fromCenter(center: Offset(cx, cy - h * 0.01), width: ch * 0.8, height: cw));
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ────────────────────────────────────────────────────────────────────────
// 6. Floating Bubbles Ambient Overlay (Optimized to 12 bubbles, max opacity 0.25)
// ────────────────────────────────────────────────────────────────────────
class FloatingBubblesOverlay extends StatefulWidget {
  const FloatingBubblesOverlay({super.key});

  @override
  State<FloatingBubblesOverlay> createState() => _FloatingBubblesOverlayState();
}

class _FloatingBubblesOverlayState extends State<FloatingBubblesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Bubble> _bubbles = List.generate(12, (_) => _Bubble()); // Reduced to 12

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

      paint.color = Colors.white.withValues(alpha: 0.25); // Max opacity 0.25
      canvas.drawCircle(Offset(dx, dy), b.size, paint);

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
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
