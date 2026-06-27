import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../scholarly_theme.dart';

class ArenaHintOverlay extends ConsumerStatefulWidget {
  final String from;
  final String to;
  final double boardSize;
  final bool isFlipped;

  const ArenaHintOverlay({
    super.key,
    required this.from,
    required this.to,
    required this.boardSize,
    required this.isFlipped,
  });

  @override
  ConsumerState<ArenaHintOverlay> createState() => _ArenaHintOverlayState();
}

class _ArenaHintOverlayState extends ConsumerState<ArenaHintOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _curvedAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Offset _squareCenter(String square, double squareSize) {
    final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(square[1]);
    final efCol = widget.isFlipped ? 7 - col : col;
    final efRow = widget.isFlipped ? 7 - row : row;
    return Offset((efCol + 0.5) * squareSize, (efRow + 0.5) * squareSize);
  }

  List<Offset> _calculatePath(Offset start, Offset end, double squareSize) {
    final fromCol = widget.from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRow = 8 - int.parse(widget.from[1]);
    final toCol = widget.to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toRow = 8 - int.parse(widget.to[1]);
    final dx = (toCol - fromCol).abs();
    final dy = (toRow - fromRow).abs();

    final List<Offset> path = [start];
    if ((dx == 1 && dy == 2) || (dx == 2 && dy == 1)) {
      // Knight path: go horizontally then vertically, or vice versa
      if (dx == 1) {
        path.add(_squareCenter(widget.from[0] + widget.to[1], squareSize));
      } else {
        path.add(_squareCenter(widget.to[0] + widget.from[1], squareSize));
      }
    }
    path.add(end);
    return path;
  }

  Offset _getPositionOnPath(List<Offset> path, double t) {
    if (path.isEmpty) return Offset.zero;
    if (t <= 0) return path.first;
    if (t >= 1) return path.last;

    final totalSegments = path.length - 1;
    final segment = (t * totalSegments).floor();
    final segmentT = (t * totalSegments) - segment;

    return Offset.lerp(path[segment], path[segment + 1], segmentT)!;
  }

  @override
  Widget build(BuildContext context) {
    final squareSize = widget.boardSize / 8;
    final start = _squareCenter(widget.from, squareSize);
    final end = _squareCenter(widget.to, squareSize);
    final path = _calculatePath(start, end, squareSize);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _curvedAnimation,
        builder: (context, child) {
          final progress = _curvedAnimation.value;
          final currentPos = _getPositionOnPath(path, progress);
          final double opacity = math.sin(progress * math.pi);

          // Calculate expanding landing ripple parameters when finishing the slide
          double rippleScale = 0.0;
          double rippleOpacity = 0.0;
          if (progress > 0.7) {
            final t = (progress - 0.7) / 0.3; // 0.0 to 1.0
            rippleScale = 0.4 + t * 0.9;
            rippleOpacity = (1.0 - t).clamp(0.0, 1.0);
          }

          final tileSize = squareSize * 0.82;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Trail path drawing
              CustomPaint(
                size: Size(widget.boardSize, widget.boardSize),
                painter: HintTrailPainter(
                  path: path,
                  progress: progress,
                  squareSize: squareSize,
                ),
              ),

              // 2. Landing ripple on target square
              if (progress > 0.7)
                Positioned(
                  left: end.dx - (squareSize * 1.3) / 2,
                  top: end.dy - (squareSize * 1.3) / 2,
                  child: Opacity(
                    opacity: rippleOpacity,
                    child: Transform.scale(
                      scale: rippleScale,
                      child: Container(
                        width: squareSize * 1.3,
                        height: squareSize * 1.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ScholarlyTheme.accentYellow.withValues(alpha: 0.85),
                            width: 3.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. Sliding glowing tile
              Positioned(
                left: currentPos.dx - tileSize / 2,
                top: currentPos.dy - tileSize / 2,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: tileSize,
                    height: tileSize,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ScholarlyTheme.accentYellow.withValues(alpha: 0.55),
                          blurRadius: 16,
                          spreadRadius: 4,
                        ),
                      ],
                      gradient: RadialGradient(
                        colors: [
                          ScholarlyTheme.accentYellow.withValues(alpha: 0.45),
                          ScholarlyTheme.accentYellow.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                        stops: const [0.25, 0.75, 1.0],
                      ),
                      border: Border.all(
                        color: ScholarlyTheme.accentYellow.withValues(alpha: 0.85),
                        width: 2.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class HintTrailPainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final double squareSize;

  HintTrailPainter({
    required this.path,
    required this.progress,
    required this.squareSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final trailOpacity = math.sin(progress * math.pi);

    // 1. Wide outer faint glow line
    final outerGlowPaint = Paint()
      ..color = ScholarlyTheme.accentYellow.withValues(alpha: 0.15 * trailOpacity)
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 2. Medium inner glow line
    final innerGlowPaint = Paint()
      ..color = ScholarlyTheme.accentYellow.withValues(alpha: 0.35 * trailOpacity)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // 3. Sharp bright core line
    final corePaint = Paint()
      ..color = ScholarlyTheme.accentYellow.withValues(alpha: 0.85 * trailOpacity)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final totalSegments = path.length - 1;
    final currentSegment = (progress * totalSegments).floor();
    final segmentProgress = (progress * totalSegments) - currentSegment;

    final Path drawingPath = Path();
    drawingPath.moveTo(path[0].dx, path[0].dy);

    for (int i = 0; i < currentSegment; i++) {
      drawingPath.lineTo(path[i + 1].dx, path[i + 1].dy);
    }

    if (currentSegment < totalSegments) {
      final start = path[currentSegment];
      final end = path[currentSegment + 1];
      final currentPos = Offset.lerp(start, end, segmentProgress)!;
      drawingPath.lineTo(currentPos.dx, currentPos.dy);
    }

    canvas.drawPath(drawingPath, outerGlowPaint);
    canvas.drawPath(drawingPath, innerGlowPaint);
    canvas.drawPath(drawingPath, corePaint);
  }

  @override
  bool shouldRepaint(covariant HintTrailPainter oldDelegate) => true;
}
