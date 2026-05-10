import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/chess_provider.dart';
import 'chess_piece_widget.dart';

class TrailMovementOverlay extends ConsumerStatefulWidget {
  final MoveAnimationData data;
  final double boardSize;
  final bool isFlipped;
  final VoidCallback onComplete;

  const TrailMovementOverlay({
    super.key,
    required this.data,
    required this.boardSize,
    required this.isFlipped,
    required this.onComplete,
  });

  @override
  ConsumerState<TrailMovementOverlay> createState() => _TrailMovementOverlayState();
}

class _TrailMovementOverlayState extends ConsumerState<TrailMovementOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Offset> _path;
  late double _squareSize;

  late Animation<double> _curvedProgress;

  @override
  void initState() {
    super.initState();
    _squareSize = widget.boardSize / 8;
    _path = _calculatePath();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550), // Snappier movement
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    final boardThemeId = ref.read(chessProvider).boardThemeId;
    final curve = boardThemeId == 'theme2' 
        ? Curves.easeOutBack 
        : boardThemeId == 'theme3'
            ? Curves.easeInOutCubic
            : Curves.easeInOutSine;

    _curvedProgress = CurvedAnimation(
      parent: _controller,
      curve: curve,
    );

    final animationsEnabled = ref.read(chessProvider).isAnimationsEnabled;
    if (!animationsEnabled) {
      _controller.value = 1.0;
      // The status listener will trigger onComplete
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Offset> _calculatePath() {
    final fromCol = widget.data.from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRow = 8 - int.parse(widget.data.from[1]);
    final toCol = widget.data.to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toRow = 8 - int.parse(widget.data.to[1]);

    final path = <Offset>[];
    path.add(_coordsToOffset(fromCol, fromRow));

    final dx = (toCol - fromCol).abs();
    final dy = (toRow - fromRow).abs();

    if ((dx == 1 && dy == 2) || (dx == 2 && dy == 1)) {
      // Knight jump path
      if (dx == 1) {
        path.add(_coordsToOffset(fromCol, toRow));
      } else {
        path.add(_coordsToOffset(toCol, fromRow));
      }
    } else {
      // Zigzag through squares
      int currCol = fromCol;
      int currRow = fromRow;
      while (currCol != toCol || currRow != toRow) {
        if (currCol < toCol) {
          currCol++;
        } else if (currCol > toCol) {
          currCol--;
        }
        
        if (currRow < toRow) {
          currRow++;
        } else if (currRow > toRow) {
          currRow--;
        }
        
        path.add(_coordsToOffset(currCol, currRow));
      }
    }
    
    final toOffset = _coordsToOffset(toCol, toRow);
    if (path.last != toOffset) {
      path.add(toOffset);
    }
    
    return path;
  }

  Offset _coordsToOffset(int col, int row) {
    final x = (widget.isFlipped ? 7 - col : col) * _squareSize + _squareSize / 2;
    final y = (widget.isFlipped ? 7 - row : row) * _squareSize + _squareSize / 2;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final boardThemeId = ref.watch(chessProvider.select((s) => s.boardThemeId));
    final isIceTheme = boardThemeId == 'theme3';
    final isToyTheme = boardThemeId == 'theme4';
    final isSteampunkTheme = boardThemeId == 'theme5';
    final isMatrixTheme = boardThemeId == 'theme6';
    final isElectricTheme = boardThemeId == 'theme9';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _curvedProgress.value;
        final rawProgress = _controller.value;
        
        // Piece and trail follow the curved progress
        final piecePos = _getPositionOnPath(_path, progress);

        // Calculate arc and squash/stretch for Toy theme
        final arc = math.sin(rawProgress * math.pi);
        
        double pieceScale = 1.0;
        double verticalLift = 0.0;
        Offset vibration = Offset.zero;
        
        if (isIceTheme) {
          pieceScale = 1.0;
          verticalLift = 0.0;
        } else if (isToyTheme) {
          // Playful hop: higher arc + squash at start/end
          verticalLift = -arc * 60.0; // High hop!
          pieceScale = 1.0 + (arc * 0.4); // Stretch in mid-air
          if (rawProgress < 0.2 || rawProgress > 0.8) {
             pieceScale = 0.8; // Squash on landing/takeoff
          }
        } else if (isSteampunkTheme) {
          // Mechanical slide: subtle vibration
          verticalLift = -arc * 10.0;
          vibration = Offset(math.sin(rawProgress * 40) * 2.0, 0); // Mechanical rattle
        } else if (isMatrixTheme) {
          // Teleport dissolve
          final noise = math.sin(rawProgress * 80);
          pieceScale = 0.8 + (0.4 * noise.abs());
          vibration = Offset(noise * 3, 0);
          // Sudden jump in opacity/visibility
          if ((rawProgress * 20).floor() % 2 == 0) {
            pieceScale = 0.0; // Digital flicker out
          }
        } else {
          pieceScale = 1.0 + (arc * 0.35);
          verticalLift = -arc * 25.0;
        }

        return Stack(
          children: [
            if (!isIceTheme && !isMatrixTheme && !isElectricTheme)
              CustomPaint(
                size: Size(widget.boardSize, widget.boardSize),
                painter: TrailPainter(
                  path: _path,
                  progress: progress,
                  squareSize: _squareSize,
                ),
              ),
            
            if (isElectricTheme)
              CustomPaint(
                size: Size(widget.boardSize, widget.boardSize),
                painter: _LightningArcPainter(
                  from: _path.first,
                  to: piecePos,
                  progress: progress,
                ),
              ),
            
            // Render Ghost Trail for Ice Theme (Motion Blur Pro)
            if (isIceTheme)
              for (int i = 1; i <= 6; i++)
                _buildGhostPiece(progress - (i * 0.04), 0.5 / (i * 1.5)),

            // Render subtle Ghost Trail for Bishop (Signature identity)
            // Gated by PieceCode and intentionally lower opacity (0.4)
            if (!isIceTheme && !isMatrixTheme && widget.data.pieceCode.endsWith('B'))
              for (int i = 1; i <= 4; i++)
                _buildGhostPiece(progress - (i * 0.05), 0.4 / (i * 1.6)),

            Positioned(
              left: piecePos.dx - _squareSize / 2 + vibration.dx,
              top: piecePos.dy - _squareSize / 2 + verticalLift + vibration.dy,
              child: Transform.scale(
                scale: pieceScale,
                child: SizedBox(
                  width: _squareSize,
                  height: _squareSize,
                  child: ChessPieceWidget(
                    squareName: widget.data.from,
                    pieceCode: widget.data.pieceCode,
                    isMoving: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGhostPiece(double t, double opacity) {
    if (t <= 0) return const SizedBox.shrink();
    if (t >= 1.0) return const SizedBox.shrink();
    final pos = _getPositionOnPath(_path, t);
    return Positioned(
      left: pos.dx - _squareSize / 2,
      top: pos.dy - _squareSize / 2,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: SizedBox(
          width: _squareSize,
          height: _squareSize,
          child: ChessPieceWidget(
            squareName: widget.data.from,
            pieceCode: widget.data.pieceCode,
            isMoving: true,
          ),
        ),
      ),
    );
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
}

class TrailPainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final double squareSize;

  TrailPainter({
    required this.path,
    required this.progress,
    required this.squareSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    // Fade out trail towards the end of the animation
    final trailOpacity = (1.0 - progress).clamp(0.0, 1.0);
    
    final paint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.6 * trailOpacity)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.3 * trailOpacity)
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
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

    canvas.drawPath(drawingPath, glowPaint);
    canvas.drawPath(drawingPath, paint);
  }

  @override
  bool shouldRepaint(covariant TrailPainter oldDelegate) => true;
}

class _LightningArcPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final double progress;

  _LightningArcPainter({required this.from, required this.to, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;

    final paint = Paint()
      ..color = const Color(0xFF00BFFF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final glowPaint = Paint()
      ..color = const Color(0xFF00BFFF).withValues(alpha: 0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final random = math.Random();
    final path = Path()..moveTo(from.dx, from.dy);
    
    final dist = (to - from).distance;
    final segments = (dist / 10).clamp(5, 20).toInt();
    
    for (int i = 1; i <= segments; i++) {
        final t = i / segments;
        final lerped = Offset.lerp(from, to, t)!;
        final jitter = Offset((random.nextDouble() - 0.5) * 20, (random.nextDouble() - 0.5) * 20);
        path.lineTo(lerped.dx + jitter.dx, lerped.dy + jitter.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LightningArcPainter oldDelegate) => true;
}
