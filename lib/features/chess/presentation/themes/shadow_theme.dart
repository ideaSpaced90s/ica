import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'chess_theme.dart';
import '../widgets/high_contrast_piece.dart';

class ShadowTheme extends ChessTheme {
  const ShadowTheme() : super(id: 'theme10', name: 'Shadow');

  @override
  Color get lightSquare => const Color(0xFF3C3C3C);

  @override
  Color get darkSquare => const Color(0xFF000000);

  @override
  Color get lightCoordinateColor => Colors.white.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white.withValues(alpha: 0.7);

  @override
  Color get frameColor => const Color(0xFF000000);

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
    return null;
  }

  @override
  Border? getSquareBorder(bool isSelected, bool isDragHover) {
    return null;
  }

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    return HighContrastPiece(
      type: type.toUpperCase(),
      isWhite: isWhite,
      isHighlighted: isHighlighted,
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return Center(
      child: Container(
        width: isEnemy ? 40 : 14,
        height: isEnemy ? 40 : 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnemy
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.45),
          border: isEnemy
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 2.5,
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return const ShadowSelectionPulse();
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

class ShadowSelectionPulse extends StatefulWidget {
  const ShadowSelectionPulse({super.key});

  @override
  State<ShadowSelectionPulse> createState() => _ShadowSelectionPulseState();
}

class _ShadowSelectionPulseState extends State<ShadowSelectionPulse>
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
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(
                alpha: 0.2 + 0.3 * _controller.value,
              ),
              width: 2.0 + 2.0 * _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class ThunderTrailOverlay extends StatefulWidget {
  final Offset from;
  final Offset to;
  final VoidCallback onComplete;

  const ThunderTrailOverlay({
    super.key,
    required this.from,
    required this.to,
    required this.onComplete,
  });

  @override
  State<ThunderTrailOverlay> createState() => _ThunderTrailOverlayState();
}

class _ThunderTrailOverlayState extends State<ThunderTrailOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late final List<double> _jitters;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _jitters = List.generate(8, (_) => (random.nextDouble() - 0.5) * 24.0);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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
          painter: _ThunderTrailPainter(
            from: widget.from,
            to: widget.to,
            progress: _controller.value,
            jitters: _jitters,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ThunderTrailPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final double progress;
  final List<double> jitters;

  _ThunderTrailPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.jitters,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double opacity = (1.0 - progress).clamp(0.0, 1.0);
    if (opacity <= 0) return;

    final baseVec = to - from;
    final length = baseVec.distance;
    if (length <= 0) return;

    final normal = Offset(-baseVec.dy, baseVec.dx) / length;

    final path = Path();
    path.moveTo(from.dx, from.dy);

    final int segments = jitters.length + 1;
    final List<Offset> points = [from];

    for (int i = 0; i < jitters.length; i++) {
      final t = (i + 1) / segments;
      final basePoint = Offset.lerp(from, to, t)!;
      final envelope = math.sin(t * math.pi);
      final point = basePoint + normal * jitters[i] * envelope;
      path.lineTo(point.dx, point.dy);
      points.add(point);
    }
    path.lineTo(to.dx, to.dy);
    points.add(to);

    final forkPath = Path();
    final random = math.Random(from.dx.toInt() ^ to.dy.toInt());
    for (int i = 1; i < points.length - 1; i += 2) {
      if (random.nextBool()) {
        forkPath.moveTo(points[i].dx, points[i].dy);
        final forkDir = normal * (random.nextBool() ? 1.0 : -1.0) + baseVec / length * 0.5;
        final forkEnd = points[i] + forkDir * (15.0 + random.nextDouble() * 15.0);
        forkPath.lineTo(forkEnd.dx, forkEnd.dy);
      }
    }

    final outerPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final innerPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final forkOuterPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final forkInnerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(forkPath, forkOuterPaint);
    canvas.drawPath(forkPath, forkInnerPaint);

    canvas.drawPath(path, outerPaint);
    canvas.drawPath(path, innerPaint);
  }

  @override
  bool shouldRepaint(_ThunderTrailPainter oldDelegate) => true;
}
