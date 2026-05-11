import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/chess_provider.dart';
import '../chess_piece_widget.dart';
import '../trail_movement_overlay.dart' show TrailPainter;
import 'piece_motion_profile.dart';

/// Enhanced movement overlay that applies per-piece motion identity on top of
/// the existing smooth animation pipeline.
///
/// Replaces [TrailMovementOverlay] as the mount point in chess_board.dart
/// while preserving all existing theme-differentiated behavior.
class SignatureMoveOverlay extends ConsumerStatefulWidget {
  final MoveAnimationData data;
  final double boardSize;
  final bool isFlipped;
  final bool isCheckmate;
  final VoidCallback onComplete;

  /// Called with the landing square when movement completes.
  /// Used to trigger [LandingFeedback] in chess_board.dart.
  final void Function(String square, PieceMotionProfile profile)? onLand;

  const SignatureMoveOverlay({
    super.key,
    required this.data,
    required this.boardSize,
    required this.isFlipped,
    this.isCheckmate = false,
    required this.onComplete,
    this.onLand,
  });

  @override
  ConsumerState<SignatureMoveOverlay> createState() =>
      _SignatureMoveOverlayState();
}

class _SignatureMoveOverlayState extends ConsumerState<SignatureMoveOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Offset> _path;
  late double _squareSize;
  late Animation<double> _curvedProgress;
  late PieceMotionProfile _profile;

  @override
  void initState() {
    super.initState();
    _squareSize = widget.boardSize / 8;
    _path = _calculatePath();
    _profile = PieceMotionProfile.forCode(widget.data.pieceCode);

    _controller =
        AnimationController(vsync: this, duration: _effectiveMoveDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              // Fire landing callback before completing
              widget.onLand?.call(widget.data.to, _profile);
              widget.onComplete();
            }
          });

    // ── Curve Selection ──────────────────────────────────────────────────
    // Profile curve refines the feel per-piece identity.
    // Theme-specific overrides (toy-bounce, matrix-flicker) are preserved
    // in the build() block via explicit Guards.
    final boardThemeId = ref.read(chessProvider).boardThemeId;

    _curvedProgress = CurvedAnimation(
      parent: _controller,
      curve: _profileAwareCurve(boardThemeId, _profile),
    );

    final animationsEnabled = ref.read(chessProvider).isAnimationsEnabled;
    if (!animationsEnabled) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  Duration get _effectiveMoveDuration {
    final baseDuration = widget.isCheckmate
        ? Duration(
            milliseconds: (_profile.moveDuration.inMilliseconds * 1.7).round(),
          )
        : _profile.moveDuration;

    if (widget.boardSize >= 520) {
      return baseDuration;
    }

    const mobileMinimum = Duration(milliseconds: 500);
    if (baseDuration >= mobileMinimum) {
      return baseDuration;
    }
    return mobileMinimum;
  }

  /// Returns the profile-aware curve, falling back to theme curve for
  /// theme-specific special modes (matrix, toy).
  Curve _profileAwareCurve(String themeId, PieceMotionProfile profile) {
    // Special themes keep their own curve logic (handled in build())
    if (themeId == 'theme6' || themeId == 'theme9') {
      return _themeBaseCurve(themeId);
    }
    return profile.moveCurve;
  }

  Curve _themeBaseCurve(String themeId) {
    switch (themeId) {
      case 'theme2':
        return Curves.easeOutBack;
      case 'theme3':
        return Curves.easeInOutCubic;
      default:
        return Curves.easeInOutSine;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SignatureMoveOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle new move data if it changes while the overlay is still mounted
    if (widget.data != oldWidget.data) {
      _path = _calculatePath();
      _profile = PieceMotionProfile.forCode(widget.data.pieceCode);
      _controller.duration = _effectiveMoveDuration;
      
      final boardThemeId = ref.read(chessProvider).boardThemeId;
      _curvedProgress = CurvedAnimation(
        parent: _controller,
        curve: _profileAwareCurve(boardThemeId, _profile),
      );
      
      _controller.reset();
      _controller.forward();
    } else if (widget.isCheckmate &&
        !oldWidget.isCheckmate &&
        _controller.value < 1.0) {
      _controller.duration = _effectiveMoveDuration;
      _controller.forward(from: _controller.value);
    }
  }

  // ── Path Calculation (identical to TrailMovementOverlay) ─────────────────

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
      if (dx == 1) {
        path.add(_coordsToOffset(fromCol, toRow));
      } else {
        path.add(_coordsToOffset(toCol, fromRow));
      }
    } else {
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
    if (path.last != toOffset) path.add(toOffset);
    return path;
  }

  Offset _coordsToOffset(int col, int row) {
    final x =
        (widget.isFlipped ? 7 - col : col) * _squareSize + _squareSize / 2;
    final y =
        (widget.isFlipped ? 7 - row : row) * _squareSize + _squareSize / 2;
    return Offset(x, y);
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

  Widget _buildGhostPiece(double t, double opacity) {
    if (t <= 0 || t >= 1.0) return const SizedBox.shrink();
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

  @override
  Widget build(BuildContext context) {
    final boardThemeId = ref.watch(chessProvider.select((s) => s.boardThemeId));

    // ── Theme-specific special modes (preserved from original overlay) ──
    final isMatrixTheme = boardThemeId == 'theme6';
    final isElectricTheme = boardThemeId == 'theme9';
    final isToyTheme = boardThemeId == 'theme4';
    final isSteampunkTheme = boardThemeId == 'theme5';

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _curvedProgress.value;
        final rawProgress = _controller.value;

        final piecePos = _getPositionOnPath(_path, progress);
        final arc = math.sin(rawProgress * math.pi);

        // ── Motion Variables ─────────────────────────────────────────────

        double pieceScale = 1.0;
        double verticalLift = 0.0;
        Offset vibration = Offset.zero;
        double midRotation = 0.0; // radians

        if (isMatrixTheme) {
          // Matrix: teleport dissolve (unchanged)
          final noise = math.sin(rawProgress * 80);
          pieceScale = 0.8 + (0.4 * noise.abs());
          vibration = Offset(noise * 3, 0);
          if ((rawProgress * 20).floor() % 2 == 0) pieceScale = 0.0;
        } else if (isToyTheme) {
          // Toy: high arc + squash/stretch (unchanged)
          verticalLift = -arc * 60.0;
          pieceScale = 1.0 + (arc * 0.4);
          if (rawProgress < 0.2 || rawProgress > 0.8) pieceScale = 0.8;
        } else if (isSteampunkTheme) {
          // Steampunk: mechanical rattle (unchanged)
          verticalLift = -arc * 10.0;
          vibration = Offset(math.sin(rawProgress * 40) * 2.0, 0);
        } else {
          // ── Profile-driven motion (all other themes) ─────────────────
          // Vertical arc from profile
          verticalLift = -arc * _squareSize * _profile.verticalArcFactor;

          // Mid-move rotation (Knight signature)
          if (_profile.midRotationDeg != 0.0) {
            midRotation =
                _profile.midRotationDeg *
                (math.pi / 180.0) *
                math.sin(rawProgress * math.pi);
          }

          // Subtle scale swell (small rise mid-arc for non-flat pieces)
          if (_profile.verticalArcFactor > 0.05) {
            pieceScale = 1.0 + (arc * 0.15);
          }
        }

        // ── Piece Widget ─────────────────────────────────────────────────
        Widget movingPiece = SizedBox(
          width: _squareSize,
          height: _squareSize,
          child: ChessPieceWidget(
            squareName: widget.data.from,
            pieceCode: widget.data.pieceCode,
            isMoving: true,
          ),
        );

        // Apply mid-move rotation (Knight only in practice)
        if (midRotation != 0.0) {
          movingPiece = Transform.rotate(
            angle: midRotation,
            child: movingPiece,
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Trail painter (all non-matrix, non-electric themes) ──
            if (!isMatrixTheme && !isElectricTheme)
              CustomPaint(
                size: Size(widget.boardSize, widget.boardSize),
                painter: TrailPainter(
                  path: _path,
                  progress: progress,
                  squareSize: _squareSize,
                ),
              ),

            // ── Electric arc (theme9, unchanged) ──
            if (isElectricTheme)
              CustomPaint(
                size: Size(widget.boardSize, widget.boardSize),
                painter: _LightningArcPainter(
                  from: _path.first,
                  to: piecePos,
                  progress: progress,
                ),
              ),

            // ── Bishop ghost trail ──────────────────────────────────
            if (_profile.hasGhostTrail && !isMatrixTheme)
              for (int i = 1; i <= 4; i++)
                _buildGhostPiece(progress - (i * 0.05), 0.35 / (i * 1.6)),

            // ── Moving piece ────────────────────────────────────────
            Positioned(
              left: piecePos.dx - _squareSize / 2 + vibration.dx,
              top: piecePos.dy - _squareSize / 2 + verticalLift + vibration.dy,
              child: Transform.scale(scale: pieceScale, child: movingPiece),
            ),
          ],
        );
      },
    );
  }
}

// ── Lightning Arc (preserved from original TrailMovementOverlay) ─────────────

class _LightningArcPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final double progress;

  _LightningArcPainter({
    required this.from,
    required this.to,
    required this.progress,
  });

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
      final jitter = Offset(
        (random.nextDouble() - 0.5) * 20,
        (random.nextDouble() - 0.5) * 20,
      );
      path.lineTo(lerped.dx + jitter.dx, lerped.dy + jitter.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LightningArcPainter oldDelegate) => true;
}
