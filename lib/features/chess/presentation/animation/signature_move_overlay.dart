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

  /// Called with move details when movement completes.
  /// Used to trigger [LandingFeedback] and kinetic effects in chess_board.dart.
  final void Function(
    String from,
    String to,
    String pieceCode,
    PieceMotionProfile profile,
  )?
  onLand;

  /// Trigger for special visual effects (e.g. 'dust_puff')
  final void Function(String action, Offset position)? onActionTrigger;

  const SignatureMoveOverlay({
    super.key,
    required this.data,
    required this.boardSize,
    required this.isFlipped,
    this.isCheckmate = false,
    required this.onComplete,
    this.onLand,
    this.onActionTrigger,
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

  // Castling support
  late List<Offset>? _rookPath;
  late PieceMotionProfile? _rookProfile;
  bool _hasTriggeredDust = false;

  @override
  void initState() {
    super.initState();
    _squareSize = widget.boardSize / 8;
    _path = _calculatePath(widget.data.from, widget.data.to);
    _profile = PieceMotionProfile.forCode(widget.data.pieceCode);

    if (widget.data.isCastle) {
      _rookPath = _calculatePath(widget.data.rookFrom!, widget.data.rookTo!);
      _rookProfile = PieceMotionProfile.forCode(widget.data.rookPieceCode!);
    } else {
      _rookPath = null;
      _rookProfile = null;
    }

    _controller =
        AnimationController(vsync: this, duration: _effectiveMoveDuration)
          ..addListener(_handleAnimationTick)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              // Fire landing callback before completing
              widget.onLand?.call(
                widget.data.from,
                widget.data.to,
                widget.data.pieceCode,
                _profile,
              );
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

    final pieceMotionEnabled = ref
        .read(chessProvider.notifier)
        .isAnimationTypeEnabled('pieceMotion');
    if (!pieceMotionEnabled) {
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
      _path = _calculatePath(widget.data.from, widget.data.to);
      _profile = PieceMotionProfile.forCode(widget.data.pieceCode);

      if (widget.data.isCastle) {
        _rookPath = _calculatePath(widget.data.rookFrom!, widget.data.rookTo!);
        _rookProfile = PieceMotionProfile.forCode(widget.data.rookPieceCode!);
      } else {
        _rookPath = null;
        _rookProfile = null;
      }

      _hasTriggeredDust = false;
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

  void _handleAnimationTick() {
    if ((widget.data.isCastle || _profile.isInfantry) &&
        !_hasTriggeredDust &&
        _controller.value >= 0.5) {
      _hasTriggeredDust = true;

      // Calculate mid-point position for dust puff
      final fromOffset = _coordsToOffset(
        widget.data.from.codeUnitAt(0) - 'a'.codeUnitAt(0),
        8 - int.parse(widget.data.from[1]),
      );
      final toOffset = _coordsToOffset(
        widget.data.to.codeUnitAt(0) - 'a'.codeUnitAt(0),
        8 - int.parse(widget.data.to[1]),
      );

      final midPos = Offset.lerp(fromOffset, toOffset, 0.5)!;
      widget.onActionTrigger?.call('dust_puff', midPos);
    }
  }

  // ── Path Calculation (identical to TrailMovementOverlay) ─────────────────

  List<Offset> _calculatePath(String from, String to) {
    final fromCol = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRow = 8 - int.parse(from[1]);
    final toCol = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toRow = 8 - int.parse(to[1]);

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
            forceVisible: true,
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
        } else if (isToyTheme &&
            ref
                .read(chessProvider.notifier)
                .isAnimationTypeEnabled('themeEffects')) {
          // Toy: high arc + squash/stretch (unchanged)
          verticalLift = -arc * 60.0;
          pieceScale = 1.0 + (arc * 0.4);
          if (rawProgress < 0.2 || rawProgress > 0.8) pieceScale = 0.8;
        } else if (_profile.isInfantry) {
          // ── Infantry March Signature (Pawn) ────────────────────────────
          // Keeps the pawn firmly grounded and solid.
          verticalLift = 0.0;
          pieceScale = 1.0;

          // Persistent forward lean/tilt during transit (~5 degrees = 0.087 radians)
          final tiltAngle = 0.087;
          final tiltEnvelope = math.sin(rawProgress * math.pi);

          final int fromRow = 8 - int.parse(widget.data.from[1]);
          final int toRow = 8 - int.parse(widget.data.to[1]);
          final isMovingUp = toRow < fromRow;
          final visualDirection = (isMovingUp ^ widget.isFlipped) ? 1.0 : -1.0;
          midRotation = tiltAngle * visualDirection * tiltEnvelope;
        } else if (isSteampunkTheme &&
            ref
                .read(chessProvider.notifier)
                .isAnimationTypeEnabled('themeEffects')) {
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
            forceVisible: true,
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
            // Hidden for teleport moves to maintain clean jump feel
            if (!_profile.isTeleport &&
                !isMatrixTheme &&
                !isElectricTheme &&
                ref
                    .read(chessProvider.notifier)
                    .isAnimationTypeEnabled('themeEffects'))
              CustomPaint(
                size: Size(widget.boardSize, widget.boardSize),
                painter: TrailPainter(
                  path: _path,
                  progress: progress,
                  squareSize: _squareSize,
                ),
              ),

            // ── Electric arc (theme9, unchanged) ──
            if (isElectricTheme &&
                ref
                    .read(chessProvider.notifier)
                    .isAnimationTypeEnabled('themeEffects'))
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

            // ── Moving pieces ────────────────────────────────────────

            // Rook (if castling)
            if (widget.data.isCastle && _rookPath != null)
              _buildSecondaryPiece(
                rawProgress,
                _getPositionOnPath(_rookPath!, progress),
                widget.data.rookPieceCode!,
                _rookProfile!,
                arc,
                isMatrixTheme,
                isToyTheme,
                isSteampunkTheme,
              ),

            // King (primary piece)
            _buildMovingPiece(
              rawProgress,
              piecePos,
              pieceScale,
              verticalLift,
              vibration,
              midRotation,
              movingPiece,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSecondaryPiece(
    double rawProgress,
    Offset pos,
    String pieceCode,
    PieceMotionProfile profile,
    double arc,
    bool isMatrixTheme,
    bool isToyTheme,
    bool isSteampunkTheme,
  ) {
    double scale = 1.0;
    double lift = 0.0;
    Offset vib = Offset.zero;

    if (isMatrixTheme) {
      final noise = math.sin(rawProgress * 80);
      scale = 0.8 + (0.4 * noise.abs());
      vib = Offset(noise * 3, 0);
      if ((rawProgress * 20).floor() % 2 == 0) scale = 0.0;
    } else if (isToyTheme &&
        ref
            .read(chessProvider.notifier)
            .isAnimationTypeEnabled('themeEffects')) {
      lift = -arc * 60.0;
      scale = 1.0 + (arc * 0.4);
      if (rawProgress < 0.2 || rawProgress > 0.8) scale = 0.8;
    } else if (isSteampunkTheme &&
        ref
            .read(chessProvider.notifier)
            .isAnimationTypeEnabled('themeEffects')) {
      lift = -arc * 10.0;
      vib = Offset(math.sin(rawProgress * 40) * 2.0, 0);
    } else {
      lift = -arc * _squareSize * profile.verticalArcFactor;
      if (profile.verticalArcFactor > 0.05) {
        scale = 1.0 + (arc * 0.15);
      }
    }

    return Positioned(
      left: pos.dx - _squareSize / 2 + vib.dx,
      top: pos.dy - _squareSize / 2 + lift + vib.dy,
      child: Transform.scale(
        scale: scale,
        child: SizedBox(
          width: _squareSize,
          height: _squareSize,
          child: ChessPieceWidget(
            squareName: widget.data.from, // Not strictly used for display
            pieceCode: pieceCode,
            isMoving: true,
            forceVisible: true,
          ),
        ),
      ),
    );
  }

  Widget _buildMovingPiece(
    double rawProgress,
    Offset piecePos,
    double pieceScale,
    double verticalLift,
    Offset vibration,
    double midRotation,
    Widget movingPiece,
  ) {
    if (!_profile.isTeleport) {
      return Positioned(
        left: piecePos.dx - _squareSize / 2 + vibration.dx,
        top: piecePos.dy - _squareSize / 2 + verticalLift + vibration.dy,
        child: Transform.scale(scale: pieceScale, child: movingPiece),
      );
    }

    // ── Queen Teleport (Blink) Logic ─────────────────────────────────────

    // 1. Handle Capture Delay (wait for dust/vanish)
    double adjustedProgress = rawProgress;
    const captureDelay = 0.25; // 25% of duration spent waiting

    if (widget.data.isCapture) {
      if (rawProgress < captureDelay) {
        return const SizedBox.shrink(); // Hidden while waiting for capture effect
      }
      adjustedProgress = (rawProgress - captureDelay) / (1.0 - captureDelay);
    }

    // 2. Teleport Phases (To-and-Fro Airy Flickering)
    // We alternate between A and B to create a "phase-shifting" look.
    // 4 hops of 400ms each = 1.6s total (adjustedProgress).

    Offset teleportPos;
    double blinkOpacity = 1.0;

    // Use a fast sine wave to drive the "airy" flickering across the whole duration
    // 4 cycles total (A -> B -> A -> B)
    final double cycleProgress = (adjustedProgress * 4) % 1.0;
    final int cycleIndex = (adjustedProgress * 4).floor().clamp(0, 3);

    // Cycle 0: Point A
    // Cycle 1: Point B
    // Cycle 2: Point A
    // Cycle 3: Point B
    if (cycleIndex % 2 == 0) {
      teleportPos = _path.first;
    } else {
      teleportPos = _path.last;
    }

    // "Airy" fade: pulses 1.0 -> 0.3 -> 1.0 during each 400ms hop
    blinkOpacity =
        0.65 + 0.35 * math.sin(cycleProgress * math.pi * 2 + math.pi / 2);

    // Final stabilization: in the last 10% of the final hop, stay at B and solid
    if (adjustedProgress > 0.95) {
      teleportPos = _path.last;
      blinkOpacity = 1.0;
    }

    return Positioned(
      key: ValueKey('queen_teleport_${teleportPos}_$cycleIndex'),
      left: teleportPos.dx - _squareSize / 2,
      top: teleportPos.dy - _squareSize / 2,
      child: Opacity(
        opacity: blinkOpacity.clamp(0.0, 1.0),
        child: Transform.scale(scale: 1.0, child: movingPiece),
      ),
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
