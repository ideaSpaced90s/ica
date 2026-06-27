import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/chess_provider.dart';
import '../../../application/puzzles_provider.dart';
import '../widgets/chess_piece_widget.dart';
import 'piece_motion_profile.dart';
import '../themes/chess_theme.dart';
import '../themes/animation_group.dart';
import 'signature_move_style.dart';

class SignatureMoveOverlay extends ConsumerStatefulWidget {
  final MoveAnimationData data;
  final double boardSize;
  final bool isFlipped;
  final bool isCheckmate;
  final VoidCallback onComplete;
  final ChessTheme? theme;

  /// Called with move details when movement completes.
  /// Used to trigger LandingFeedback and kinetic effects in chess_board.dart.
  final void Function(
    String from,
    String to,
    String pieceCode,
    PieceMotionProfile profile,
  )? onLand;

  /// Trigger for special visual effects (e.g. 'dust_puff')
  final void Function(String action, Offset position)? onActionTrigger;

  /// Exposes real-time progress of the moving piece for interactive board effects.
  final void Function(double progress, Offset piecePos)? onProgressUpdate;

  const SignatureMoveOverlay({
    super.key,
    required this.data,
    required this.boardSize,
    required this.isFlipped,
    this.isCheckmate = false,
    required this.onComplete,
    this.onLand,
    this.onActionTrigger,
    this.onProgressUpdate,
    this.theme,
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

  bool _isBlinkingRed = false;

  static const PieceMotionProfile _puzzleStandardProfile = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 200),
    moveCurve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    _squareSize = widget.boardSize / 8;
    _path = _calculatePath(widget.data.from, widget.data.to);
    
    final isPuzzle = ref.read(puzzlesProvider).isPuzzleMode;
    _profile = isPuzzle
        ? _puzzleStandardProfile
        : (widget.theme?.getPieceMotionProfile(widget.data.pieceCode) ??
            PieceMotionProfile.forCode(widget.data.pieceCode));

    if (widget.data.isCastle) {
      _rookPath = _calculatePath(widget.data.rookFrom!, widget.data.rookTo!);
    } else {
      _rookPath = null;
    }

    _controller =
        AnimationController(vsync: this, duration: _effectiveMoveDuration);

    _curvedProgress = CurvedAnimation(
      parent: _controller,
      curve: _profile.moveCurve,
    );

    _controller.addListener(() {
      if (!mounted) return;
      final progressValue = _curvedProgress.value;
      final rawValue = _controller.value;
      final pos = _calculateCurrentPiecePos(rawValue, progressValue);
      widget.onProgressUpdate?.call(rawValue, pos);
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.data.isWrongMove) {
          setState(() {
            _isBlinkingRed = true;
          });
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            setState(() {
              _isBlinkingRed = false;
            });
            _controller.reverse();
          });
        } else {
          // Fire landing callback before completing
          widget.onLand?.call(
            widget.data.from,
            widget.data.to,
            widget.data.pieceCode,
            _profile,
          );
          widget.onComplete();
        }
      } else if (status == AnimationStatus.dismissed) {
        if (widget.data.isWrongMove) {
          widget.onComplete();
        }
      }
    });

    // Check if provider disabled animations altogether.
    final animationsEnabled = ref.read(chessProvider).isAnimationsEnabled;
    if (!animationsEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onLand?.call(
            widget.data.from,
            widget.data.to,
            widget.data.pieceCode,
            _profile,
          );
          widget.onComplete();
        }
      });
    } else {
      _controller.forward();
    }
  }

  Duration get _effectiveMoveDuration {
    return widget.isCheckmate
        ? Duration(milliseconds: (_profile.moveDuration.inMilliseconds * 1.5).toInt())
        : _profile.moveDuration;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SignatureMoveOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.data != oldWidget.data) {
      _path = _calculatePath(widget.data.from, widget.data.to);
      
      final isPuzzle = ref.read(puzzlesProvider).isPuzzleMode;
      _profile = isPuzzle
          ? _puzzleStandardProfile
          : (widget.theme?.getPieceMotionProfile(widget.data.pieceCode) ??
              PieceMotionProfile.forCode(widget.data.pieceCode));

      if (widget.data.isCastle) {
        _rookPath = _calculatePath(widget.data.rookFrom!, widget.data.rookTo!);
      } else {
        _rookPath = null;
      }

      _controller.duration = _effectiveMoveDuration;
      _curvedProgress = CurvedAnimation(
        parent: _controller,
        curve: _profile.moveCurve,
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



  Offset _calculateCurrentPiecePos(double rawProgress, double progress) {
    final pieceType = widget.data.pieceCode.substring(1).toUpperCase();
    Offset piecePos = _getPositionOnPath(_path, progress);
    
    final isArcTheme = widget.theme?.id == 'sprite_arc';
    final isFairytaleTheme = widget.theme?.id == 'sprite_fairytale';
    final isPlasmaTheme = widget.theme?.id == 'sprite_plasma';
    final isLightningTheme = widget.theme?.id == 'sprite_lightning';
    final isDiamondsTheme = widget.theme?.id == 'sprite_diamonds';

    if (isArcTheme || isFairytaleTheme || isPlasmaTheme || isLightningTheme || isDiamondsTheme) {
      if (pieceType == 'N' && _path.length >= 3) {
        final p0 = _path[0];
        final p1 = _path[1];
        final p2 = _path[2];
        final t = progress;
        piecePos = Offset(
          (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx,
          (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy,
        );

        final jumpY = -math.sin(rawProgress * math.pi) * _squareSize * 0.9;
        piecePos = piecePos.translate(0, jumpY);
        
        if (isArcTheme) {
          final dir = p2 - p0;
          if (dir.distance > 0.1) {
            final norm = dir / dir.distance;
            final ortho = Offset(-norm.dy, norm.dx);
            final sway = math.sin(rawProgress * 3 * math.pi) * 20.0 * (1.0 - rawProgress);
            piecePos += ortho * sway;
          }
        }
      }
    }
    return piecePos;
  }

  @override
  Widget build(BuildContext context) {
    final masterAnimationsEnabled = ref.watch(chessProvider.notifier).masterAnimationsEnabled;
    final style = widget.theme?.signatureMoveStyle;
    
    // Check if piece is a Queen of a Group C theme with master animations enabled
    final isQueen = widget.data.pieceCode.substring(1).toUpperCase() == 'Q';
    final isGroupCQueenTeleport = isQueen && widget.theme?.animationGroup == AnimationGroup.c && masterAnimationsEnabled;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _curvedProgress.value;
        final rawProgress = _controller.value;

        Offset piecePos = _getPositionOnPath(_path, progress);

        // ── Primary Piece ─────────────────────────────────────────────────
        Widget movingPiece = SizedBox(
          width: _squareSize,
          height: _squareSize,
          child: ChessPieceWidget(
            squareName: widget.data.from,
            pieceCode: widget.data.pieceCode,
            isMoving: true,
            forceVisible: true,
            theme: widget.theme,
          ),
        );

        final isArcTheme = widget.theme?.id == 'sprite_arc';
        if (isArcTheme && widget.data.pieceCode.substring(1).toUpperCase() == 'P') {
          movingPiece = Transform.scale(
            scale: 0.80,
            child: movingPiece,
          );
        }
        final isFairytaleTheme = widget.theme?.id == 'sprite_fairytale';
        final isPlasmaTheme = widget.theme?.id == 'sprite_plasma';
        final isLightningTheme = widget.theme?.id == 'sprite_lightning';
        final isDiamondsTheme = widget.theme?.id == 'sprite_diamonds';

        if (isArcTheme || isFairytaleTheme || isPlasmaTheme || isLightningTheme || isDiamondsTheme) {
          final pieceType = widget.data.pieceCode.substring(1).toUpperCase();
          if (pieceType == 'N' && _path.length >= 3) {
            // Knight: Quadratic Bezier curves for smooth trajectories
            final p0 = _path[0];
            final p1 = _path[1];
            final p2 = _path[2];
            final t = progress;
            piecePos = Offset(
              (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx,
              (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy,
            );

            // Add dynamic vertical height representing jumping over pieces
            final jumpY = -math.sin(rawProgress * math.pi) * _squareSize * 0.9;
            piecePos = piecePos.translate(0, jumpY);

            if (isArcTheme) {
              final dir = p2 - p0;
              if (dir.distance > 0.1) {
                final norm = dir / dir.distance;
                final ortho = Offset(-norm.dy, norm.dx);
                final sway = math.sin(rawProgress * 3 * math.pi) * 20.0 * (1.0 - rawProgress);
                piecePos += ortho * sway;
              }
            }

            if (isPlasmaTheme) {
              // Quantum phase jump: fade out slightly in transit
              final opacity = (1.0 - math.sin(rawProgress * math.pi) * 0.75).clamp(0.15, 1.0);
              movingPiece = Opacity(
                opacity: opacity,
                child: movingPiece,
              );
            } else if (isLightningTheme) {
              // Electrical jitter
              final jitterX = (math.Random().nextDouble() - 0.5) * 4.0;
              final jitterY = (math.Random().nextDouble() - 0.5) * 4.0;
              movingPiece = Transform.translate(
                offset: Offset(jitterX, jitterY),
                child: movingPiece,
              );
            }

            // Rotation tilt and scale compression
            final tilt = math.cos(rawProgress * math.pi) * 0.25;
            final scale = 1.0 + math.sin(rawProgress * math.pi) * 0.2;
            movingPiece = Transform(
              transform: Matrix4.diagonal3Values(scale, scale, 1.0)
                ..rotateZ(tilt),
              alignment: Alignment.center,
              child: movingPiece,
            );
          } else if (pieceType == 'R') {
            // Rook: Directional squash and stretch along movement axis
            final dx = (_path.last.dx - _path.first.dx).abs();
            final dy = (_path.last.dy - _path.first.dy).abs();
            final stretch = 1.0 + math.sin(rawProgress * math.pi) * 0.12;
            final scaleX = dx > dy ? stretch : (2.0 - stretch);
            final scaleY = dx > dy ? (2.0 - stretch) : stretch;
            
            // Only squash/stretch if not Diamonds (which is crystalline and rigid)
            if (!isDiamondsTheme) {
              movingPiece = Transform(
                transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                alignment: Alignment.center,
                child: movingPiece,
              );
            }

            if (isArcTheme) {
              final to = widget.data.to;
              final isBorder = to.startsWith('a') || to.startsWith('h') || to.endsWith('1') || to.endsWith('8');
              if (isBorder && rawProgress > 0.85) {
                final direction = _path.last - _path.first;
                if (direction.distance > 0.1) {
                  final norm = direction / direction.distance;
                  final progressFactor = (rawProgress - 0.85) / 0.15;
                  final shake = math.sin(progressFactor * 8 * math.pi) * 4.0 * (1.0 - progressFactor);
                  piecePos += norm * shake;
                }
              }
            }

            // Fairytale Rook: Add heavy ground rumble shake perpendicular to movement direction
            if (isFairytaleTheme) {
              final direction = _path.last - _path.first;
              if (direction.distance > 0.1) {
                final norm = direction / direction.distance;
                final ortho = Offset(-norm.dy, norm.dx);
                final rumble = math.sin(rawProgress * math.pi * 14.0) * 1.8 * (1.0 - rawProgress);
                piecePos += ortho * rumble;
              }
            } else if (isLightningTheme) {
              // Lightning Rook: High voltage jitter perpendicular to direction
              final direction = _path.last - _path.first;
              if (direction.distance > 0.1) {
                final norm = direction / direction.distance;
                final ortho = Offset(-norm.dy, norm.dx);
                final jitter = math.sin(rawProgress * math.pi * 32.0) * 2.0;
                piecePos += ortho * jitter;
              }
            }
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Signature move effect layer (Group C only, gated by toggle) ──
            if (style != null && masterAnimationsEnabled)
              _buildSignatureLayer(style, progress, rawProgress, isGroupCQueenTeleport),

            // ── Wrong Move Red Blink Overlay ────────────────────────
            if (_isBlinkingRed)
              Positioned(
                left: _path.last.dx - _squareSize / 2,
                top: _path.last.dy - _squareSize / 2,
                child: Container(
                  width: _squareSize,
                  height: _squareSize,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent,
                      width: 3.0,
                    ),
                  ),
                ),
              ),

            // ── Moving pieces ────────────────────────────────────────

            // Rook (if castling)
            if (widget.data.isCastle && _rookPath != null)
              _buildSecondaryPiece(
                rawProgress,
                _getPositionOnPath(_rookPath!, progress),
                widget.data.rookPieceCode!,
              ),

            // King or Queen or other primary piece
            _buildPrimaryPiece(
              rawProgress,
              piecePos,
              movingPiece,
              isGroupCQueenTeleport,
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
  ) {
    return Positioned(
      left: pos.dx - _squareSize / 2,
      top: pos.dy - _squareSize / 2,
      child: SizedBox(
        width: _squareSize,
        height: _squareSize,
        child: ChessPieceWidget(
          squareName: widget.data.from,
          pieceCode: pieceCode,
          isMoving: true,
          forceVisible: true,
          theme: widget.theme,
        ),
      ),
    );
  }

  Widget _buildPrimaryPiece(
    double rawProgress,
    Offset piecePos,
    Widget movingPiece,
    bool isGroupCQueenTeleport,
  ) {
    if (isGroupCQueenTeleport) {
      final origin = _path.first;
      final dest = _path.last;
      
      if (widget.theme?.id == 'sprite_arc') {
        final Offset teleportPos;
        if (rawProgress < 0.15) {
          teleportPos = origin;
        } else if (rawProgress < 0.30) {
          teleportPos = dest;
        } else if (rawProgress < 0.45) {
          teleportPos = origin;
        } else if (rawProgress < 0.60) {
          teleportPos = dest;
        } else if (rawProgress < 0.75) {
          teleportPos = origin;
        } else {
          teleportPos = dest;
        }

        return Positioned(
          left: teleportPos.dx - _squareSize / 2,
          top: teleportPos.dy - _squareSize / 2,
          child: movingPiece,
        );
      }
      
      final Offset teleportPos;
      final double teleportOpacity;
      if (rawProgress < 0.4) {
        teleportPos = origin;
        teleportOpacity = (1.0 - (rawProgress / 0.4)).clamp(0.0, 1.0);
      } else if (rawProgress < 0.6) {
        teleportPos = dest;
        teleportOpacity = 0.0;
      } else {
        teleportPos = dest;
        teleportOpacity = ((rawProgress - 0.6) / 0.4).clamp(0.0, 1.0);
      }

      return Positioned(
        left: teleportPos.dx - _squareSize / 2,
        top: teleportPos.dy - _squareSize / 2,
        child: Opacity(
          opacity: teleportOpacity,
          child: movingPiece,
        ),
      );
    }

    return Positioned(
      left: piecePos.dx - _squareSize / 2,
      top: piecePos.dy - _squareSize / 2,
      child: movingPiece,
    );
  }

  Widget _buildSignatureLayer(
    SignatureMoveStyle style,
    double progress,
    double raw,
    bool isTeleport,
  ) {
    return switch (style) {
      QuantumDissolveTrail() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _QuantumDissolvePainter(path: _path, progress: progress, isTeleport: isTeleport),
        ),
      PlasmaArcFlash() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _PlasmaArcFlashPainter(from: _path.first, to: isTeleport ? _path.last : _getPositionOnPath(_path, progress), progress: raw),
        ),
      CrystalTrail() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _CrystalTrailPainter(path: _path, progress: progress, isTeleport: isTeleport),
        ),
      PlasmaModernSignature() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _PlasmaModernSignaturePainter(
            path: _path,
            progress: progress,
            rawProgress: raw,
            pieceCode: widget.data.pieceCode,
            squareSize: _squareSize,
            isTeleport: isTeleport,
          ),
        ),
      LightningModernSignature() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _LightningModernSignaturePainter(
            path: _path,
            progress: progress,
            rawProgress: raw,
            pieceCode: widget.data.pieceCode,
            squareSize: _squareSize,
            isTeleport: isTeleport,
          ),
        ),
      DiamondsModernSignature() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _DiamondsModernSignaturePainter(
            path: _path,
            progress: progress,
            rawProgress: raw,
            pieceCode: widget.data.pieceCode,
            squareSize: _squareSize,
            isTeleport: isTeleport,
          ),
        ),
      OrbitalPulseTrail() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _OrbitalPulseTrailPainter(path: _path, progress: progress, squareSize: _squareSize, isTeleport: isTeleport),
        ),
      FairyDustTrail() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _FairyDustTrailPainter(path: _path, progress: progress, isTeleport: isTeleport),
        ),
      ArcModernSignature() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _ArcModernSignaturePainter(
            path: _path,
            progress: progress,
            rawProgress: raw,
            pieceCode: widget.data.pieceCode,
            squareSize: _squareSize,
            isTeleport: isTeleport,
          ),
        ),
      FairytaleModernSignature() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _FairytaleModernSignaturePainter(
            path: _path,
            progress: progress,
            rawProgress: raw,
            pieceCode: widget.data.pieceCode,
            squareSize: _squareSize,
            isTeleport: isTeleport,
          ),
        ),
    };
  }
}

// ── Plasma: "Quantum Dissolve" Painter ──────────────────────────────────────

class _QuantumDissolvePainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final bool isTeleport;

  _QuantumDissolvePainter({
    required this.path,
    required this.progress,
    required this.isTeleport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final squareSize = size.width / 8;
    final origin = path.first;
    final dest = path.last;

    for (int i = 0; i < 12; i++) {
      final color = i % 2 == 0 ? const Color(0xFF9C3FE4) : const Color(0xFF00BFFF);
      final paint = Paint()
        ..color = color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;

      final fSize = 4.0 + random.nextDouble() * 4.0;
      final dx = (random.nextDouble() - 0.5) * squareSize;
      final dy = (random.nextDouble() - 0.5) * squareSize;

      final Offset pos;
      if (isTeleport) {
        if (progress < 0.5) {
          final p = progress / 0.5;
          pos = Offset(
            origin.dx + dx * p * 1.5,
            origin.dy + dy * p * 1.5 - p * 20.0,
          );
        } else {
          final p = (progress - 0.5) / 0.5;
          pos = Offset(
            dest.dx + dx * (1.0 - p) * 1.5,
            dest.dy + dy * (1.0 - p) * 1.5 - (1.0 - p) * 20.0,
          );
        }
      } else {
        if (progress >= 0.3 && progress <= 0.7) {
          final t = (progress - 0.3) / 0.4;
          final currentPos = Offset.lerp(origin, dest, progress)!;
          final spread = math.sin(t * math.pi);
          pos = Offset(
            currentPos.dx + dx * spread,
            currentPos.dy + dy * spread,
          );
        } else {
          continue;
        }
      }

      canvas.drawRect(Rect.fromCenter(center: pos, width: fSize, height: fSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _QuantumDissolvePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Lightning: "Plasma Arc Flash" Painter ───────────────────────────────────

class _PlasmaArcFlashPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final double progress;

  _PlasmaArcFlashPainter({
    required this.from,
    required this.to,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress >= 0.75) return;

    final opacity = (progress < 0.15)
        ? (progress / 0.15)
        : (1.0 - (progress - 0.15) / 0.60).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = const Color(0xFF00BFFF).withValues(alpha: opacity)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF00BFFF).withValues(alpha: opacity * 0.3)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final random = math.Random(42);
    final path = Path()..moveTo(from.dx, from.dy);

    final dist = (to - from).distance;
    if (dist < 1.0) return;
    final segments = (dist / 12).clamp(5, 20).toInt();

    for (int i = 1; i <= segments; i++) {
      final t = i / segments;
      final lerped = Offset.lerp(from, to, t)!;
      final jitter = Offset(
        (random.nextDouble() - 0.5) * 25 * math.sin(t * math.pi),
        (random.nextDouble() - 0.5) * 25 * math.sin(t * math.pi),
      );
      path.lineTo(lerped.dx + jitter.dx, lerped.dy + jitter.dy);
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PlasmaArcFlashPainter oldDelegate) => true;
}

// ── Diamonds: "Crystal Trail" Painter ───────────────────────────────────────

class _CrystalTrailPainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final bool isTeleport;

  _CrystalTrailPainter({
    required this.path,
    required this.progress,
    required this.isTeleport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(1337);
    final origin = path.first;
    final dest = path.last;

    final spawnTimes = [0.15, 0.35, 0.55, 0.75];
    for (int i = 0; i < spawnTimes.length; i++) {
      final tSpawn = spawnTimes[i];
      if (progress < tSpawn) continue;

      final age = progress - tSpawn;
      final duration = 0.35;
      if (age > duration) continue;

      final pAge = age / duration;
      final opacity = (1.0 - pAge).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = const Color(0xFFB2EBF2).withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final Offset pos;
      if (isTeleport) {
        pos = tSpawn < 0.5
            ? Offset(origin.dx + (random.nextDouble() - 0.5) * 30, origin.dy + (random.nextDouble() - 0.5) * 30)
            : Offset(dest.dx + (random.nextDouble() - 0.5) * 30, dest.dy + (random.nextDouble() - 0.5) * 30);
      } else {
        pos = Offset.lerp(origin, dest, tSpawn)!;
      }

      final dSize = 6.0 + random.nextDouble() * 4.0;
      final rotation = pAge * 45 * (math.pi / 180);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotation);
      
      final rect = Rect.fromCenter(center: Offset.zero, width: dSize, height: dSize);
      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, glowPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _CrystalTrailPainter oldDelegate) => true;
}

// ── Arc: "Orbital Pulse Trail" Painter ──────────────────────────────────────

class _OrbitalPulseTrailPainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final double squareSize;
  final bool isTeleport;

  _OrbitalPulseTrailPainter({
    required this.path,
    required this.progress,
    required this.squareSize,
    required this.isTeleport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final origin = path.first;
    final dest = path.last;
    final spawnTimes = [0.0, 0.25, 0.5, 0.75];
    final duration = 0.45;

    for (int i = 0; i < spawnTimes.length; i++) {
      final tSpawn = spawnTimes[i];
      if (progress < tSpawn) continue;

      final age = progress - tSpawn;
      if (age > duration) continue;

      final pAge = age / duration;
      final opacity = (0.28 * (1.0 - pAge)).clamp(0.0, 1.0);
      final scale = 0.8 + 0.6 * pAge;

      final paint = Paint()
        ..color = const Color(0xFFC3A555).withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final Offset pos;
      if (isTeleport) {
        pos = tSpawn < 0.5 ? origin : dest;
      } else {
        pos = Offset.lerp(origin, dest, tSpawn)!;
      }

      canvas.drawCircle(pos, (squareSize * 0.4) * scale, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitalPulseTrailPainter oldDelegate) => true;
}

// ── Fairytale: "Fairy Dust Trail" Painter ───────────────────────────────────

class _FairyDustTrailPainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final bool isTeleport;

  _FairyDustTrailPainter({
    required this.path,
    required this.progress,
    required this.isTeleport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(2026);
    final origin = path.first;
    final dest = path.last;
    final spawnTimes = [0.1, 0.25, 0.4, 0.55, 0.7];
    final colors = [
      const Color(0xFFFFD700), // Gold
      const Color(0xFFFF69B4), // Pink
      const Color(0xFFFFFFFF), // White
    ];

    final duration = 0.60;

    for (int i = 0; i < spawnTimes.length; i++) {
      final tSpawn = spawnTimes[i];
      if (progress < tSpawn) continue;

      final age = progress - tSpawn;
      if (age > duration) continue;

      final pAge = age / duration;
      final opacity = (1.0 - pAge).clamp(0.0, 1.0);

      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final Offset spawnPos;
      if (isTeleport) {
        spawnPos = tSpawn < 0.5 ? origin : dest;
      } else {
        spawnPos = Offset.lerp(origin, dest, tSpawn)!;
      }

      final driftY = pAge * (10.0 + random.nextDouble() * 8.0);
      final driftX = (random.nextDouble() - 0.5) * 8.0;
      final pos = Offset(spawnPos.dx + driftX, spawnPos.dy + driftY);

      final starSize = 5.0 + random.nextDouble() * 3.0;
      final rotation = pAge * (90 + random.nextDouble() * 90) * (math.pi / 180);

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotation);

      final starPath = Path()
        ..moveTo(0, -starSize)
        ..lineTo(starSize * 0.3, -starSize * 0.3)
        ..lineTo(starSize, 0)
        ..lineTo(starSize * 0.3, starSize * 0.3)
        ..lineTo(0, starSize)
        ..lineTo(-starSize * 0.3, starSize * 0.3)
        ..lineTo(-starSize, 0)
        ..lineTo(-starSize * 0.3, -starSize * 0.3)
        ..close();

      canvas.drawPath(starPath, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FairyDustTrailPainter oldDelegate) => true;
}

// ── Arc: "Arc Modern Signature" Painter ──────────────────────────────────────

class _ArcModernSignaturePainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final double rawProgress;
  final String pieceCode;
  final double squareSize;
  final bool isTeleport;

  _ArcModernSignaturePainter({
    required this.path,
    required this.progress,
    required this.rawProgress,
    required this.pieceCode,
    required this.squareSize,
    required this.isTeleport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final pieceType = pieceCode.length > 1
        ? pieceCode.substring(1).toUpperCase()
        : pieceCode.toUpperCase();
    final origin = path.first;
    final dest = path.last;

    const goldColor = Color(0xFFC3A555);

    if (isTeleport || pieceType == 'Q') {
      final random = math.Random(999);
      final transitions = [0.15, 0.30, 0.45, 0.60, 0.75];
      for (final tTrigger in transitions) {
        final age = rawProgress - tTrigger;
        if (age >= 0 && age < 0.15) {
          final pAge = age / 0.15;
          final opacity = (1.0 - pAge).clamp(0.0, 1.0);
          final center = (tTrigger == 0.15 || tTrigger == 0.45 || tTrigger == 0.75) ? dest : origin;
          
          // Draw expand ring
          final ringPaint = Paint()
            ..color = goldColor.withValues(alpha: opacity * 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          canvas.drawCircle(center, squareSize * 0.65 * pAge, ringPaint);
          
          // Draw electric sparks
          final sparkPaint = Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.95)
            ..strokeWidth = 1.8;
          for (int j = 0; j < 8; j++) {
            final angle = random.nextDouble() * 2 * math.pi;
            final length = squareSize * (0.3 + random.nextDouble() * 0.4);
            final start = center + Offset(math.cos(angle) * squareSize * 0.1, math.sin(angle) * squareSize * 0.1);
            final end = start + Offset(math.cos(angle) * length * pAge, math.sin(angle) * length * pAge);
            canvas.drawLine(start, end, sparkPaint);
          }
        }
      }
      return;
    }

    if (pieceType == 'N') {
      // ♞ Knight: Parabolic Arc Leap
      if (path.length >= 3) {
        final p0 = path[0];
        final p1 = path[1];
        final p2 = path[2];

        // 1. Draw glowing path
        final strokePaint = Paint()
          ..color = goldColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;

        final glowPaint = Paint()
          ..color = goldColor.withValues(alpha: 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        final trajectoryPath = Path()..moveTo(p0.dx, p0.dy);
        trajectoryPath.quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);
        canvas.drawPath(trajectoryPath, glowPaint);
        canvas.drawPath(trajectoryPath, strokePaint);

        // 2. Draw trailing stardust sparks
        final random = math.Random(5678);
        for (int i = 0; i < 15; i++) {
          final sparkAge = (rawProgress * 1.4 - i * 0.07).clamp(0.0, 1.0);
          if (sparkAge <= 0 || sparkAge >= 1.0) continue;

          final st = sparkAge;
          final sPos = Offset(
            (1 - st) * (1 - st) * p0.dx + 2 * (1 - st) * st * p1.dx + st * st * p2.dx,
            (1 - st) * (1 - st) * p0.dy + 2 * (1 - st) * st * p1.dy + st * st * p2.dy,
          );

          // Add parabolic height
          final jumpY = -math.sin(sparkAge * math.pi) * squareSize * 0.9;
          final finalPos = sPos.translate(
            (random.nextDouble() - 0.5) * 8.0,
            jumpY + (random.nextDouble() - 0.5) * 8.0,
          );

          final opacity = (1.0 - (rawProgress - sparkAge) * 4.5).clamp(0.0, 0.75);
          if (opacity <= 0) continue;

          final sparkPaint = Paint()
            ..color = goldColor.withValues(alpha: opacity)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(finalPos, 1.5 + random.nextDouble() * 2.5, sparkPaint);
        }

        // 3. Draw landing shockwave
        if (progress > 0.8) {
          final lt = (progress - 0.8) / 0.2;
          final ringPaint = Paint()
            ..color = goldColor.withValues(alpha: 0.45 * (1.0 - lt))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * (1.0 - lt);
          
          canvas.drawCircle(p2, squareSize * 0.45 * lt, ringPaint);
          canvas.drawCircle(p2, squareSize * 0.7 * lt, ringPaint);
        }
      }
      return;
    }

    if (pieceType == 'B') {
      // ♝ Bishop: Refraction Laser Vector (last 2 tiles trail)
      final isWhitePiece = pieceCode.startsWith('w');
      final trailColor = isWhitePiece ? const Color(0xFFFFD96A) : const Color(0xFFFF5733);

      final totalSegments = path.length - 1;
      final tTrailStart = (progress - 2.0 / totalSegments).clamp(0.0, 1.0);
      
      final trailPath = Path();
      final startPos = _getPositionOnPath(path, tTrailStart);
      trailPath.moveTo(startPos.dx, startPos.dy);
      
      final startIndex = (tTrailStart * totalSegments).ceil();
      final endIndex = (progress * totalSegments).floor();
      
      for (int i = startIndex; i <= endIndex; i++) {
        if (i > 0 && i < path.length) {
          trailPath.lineTo(path[i].dx, path[i].dy);
        }
      }
      
      final currentPos = _getPositionOnPath(path, progress);
      trailPath.lineTo(currentPos.dx, currentPos.dy);
      
      final glowPaint = Paint()
        ..color = trailColor.withValues(alpha: 0.5 * (1.0 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * (1.0 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(trailPath, glowPaint);
      canvas.drawPath(trailPath, corePaint);

      for (int i = 0; i < 5; i++) {
        final tSpawn = 0.15 + i * 0.18;
        if (progress < tSpawn) continue;
        final age = progress - tSpawn;
        if (age > 0.3) continue;

        final opacity = (1.0 - age / 0.3).clamp(0.0, 0.8);
        final size = 5.0 * (1.0 - age / 0.3);
        final pos = Offset.lerp(origin, dest, tSpawn)!;

        final shardPaint = Paint()
          ..color = trailColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.rotate(age * math.pi * 3);
        
        final diamondPath = Path()
          ..moveTo(0, -size)
          ..lineTo(size * 0.6, 0)
          ..lineTo(0, size)
          ..lineTo(-size * 0.6, 0)
          ..close();
        canvas.drawPath(diamondPath, shardPaint);
        canvas.restore();
      }
      return;
    }

    if (pieceType == 'R') {
      // ♜ Rook: Linear Railgun + momentum trail
      final isWhitePiece = pieceCode.startsWith('w');
      final trailColor = isWhitePiece ? const Color(0xFFE0F7FA) : const Color(0xFFFF5722);
      
      final currentPos = Offset.lerp(origin, dest, progress)!;

      // Draw thick energy trail behind rook
      final trailPaint = Paint()
        ..color = trailColor.withValues(alpha: 0.3 * (1.0 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8 * (1.0 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(origin, currentPos, trailPaint);
      canvas.drawLine(origin, currentPos, corePaint);

      // Keep rail lines but color-coded and themed
      final railPaint = Paint()
        ..color = trailColor.withValues(alpha: 0.3 * (1.0 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final dx = (dest.dx - origin.dx).abs();
      final dy = (dest.dy - origin.dy).abs();
      final Offset offset;
      if (dx > dy) {
        offset = const Offset(0, 9.0);
      } else {
        offset = const Offset(9.0, 0);
      }

      canvas.drawLine(origin - offset, dest - offset, railPaint);
      canvas.drawLine(origin + offset, dest + offset, railPaint);

      final Offset direction = (dest - origin);
      if (direction.distance > 0.1) {
        final dirNorm = direction / direction.distance;
        final arcCenter = currentPos + dirNorm * (squareSize * 0.4);
        
        final arcPaint = Paint()
          ..color = trailColor.withValues(alpha: 0.7 * (1.0 - progress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        final angle = math.atan2(dirNorm.dy, dirNorm.dx);
        
        canvas.drawArc(
          Rect.fromCircle(center: arcCenter, radius: squareSize * 0.32),
          angle - math.pi * 0.45,
          math.pi * 0.9,
          false,
          arcPaint,
        );
      }
      return;
    }

    if (pieceType == 'P') {
      // ♟ Pawn: Micro-Thruster Glide + Capture slice
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final direction = (dest - origin);
      if (direction.distance > 0.1) {
        final dirNorm = direction / direction.distance;
        final backPos = currentPos - dirNorm * (squareSize * 0.3);
        final ortho = Offset(-dirNorm.dy, dirNorm.dx) * 6.5;

        final thrusterPaint = Paint()
          ..color = goldColor.withValues(alpha: 0.5 * (1.0 - progress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawLine(backPos - ortho, backPos - ortho - dirNorm * 12.0, thrusterPaint);
        canvas.drawLine(backPos + ortho, backPos + ortho - dirNorm * 12.0, thrusterPaint);
      }

      // Capture slicing effect
      final isCapture = (origin.dx - dest.dx).abs() > 1.0 && (origin.dy - dest.dy).abs() > 1.0;
      if (isCapture && progress > 0.4) {
        final isWhitePiece = pieceCode.startsWith('w');
        final slashColor = isWhitePiece ? const Color(0xFFFFD96A) : const Color(0xFFFF5733);
        final sliceProgress = (progress - 0.4) / 0.6;
        final opacity = (1.0 - sliceProgress).clamp(0.0, 1.0);
        
        final slashPaint = Paint()
          ..color = slashColor.withValues(alpha: opacity * 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round;
          
        final glowPaint = Paint()
          ..color = slashColor.withValues(alpha: opacity * 0.45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        final halfSize = squareSize * 0.4;
        
        final pStart1 = dest + Offset(-halfSize, -halfSize * 0.5);
        final pEnd1 = dest + Offset(halfSize, halfSize * 0.5);
        
        final pStart2 = dest + Offset(-halfSize * 0.8, halfSize * 0.6);
        final pEnd2 = dest + Offset(halfSize * 0.8, -halfSize * 0.6);

        final sEnd1 = Offset.lerp(pStart1, pEnd1, sliceProgress.clamp(0.0, 1.0))!;
        final sEnd2 = Offset.lerp(pStart2, pEnd2, sliceProgress.clamp(0.0, 1.0))!;

        canvas.drawPath(Path()..moveTo(pStart1.dx, pStart1.dy)..lineTo(sEnd1.dx, sEnd1.dy), glowPaint);
        canvas.drawPath(Path()..moveTo(pStart1.dx, pStart1.dy)..lineTo(sEnd1.dx, sEnd1.dy), slashPaint);
        
        canvas.drawPath(Path()..moveTo(pStart2.dx, pStart2.dy)..lineTo(sEnd2.dx, sEnd2.dy), glowPaint);
        canvas.drawPath(Path()..moveTo(pStart2.dx, pStart2.dy)..lineTo(sEnd2.dx, sEnd2.dy), slashPaint);
      }
      return;
    }

    if (pieceType == 'K') {
      // ♚ King: Aegis Defensive Shield
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final shieldPaint = Paint()
        ..color = goldColor.withValues(alpha: 0.3 * math.sin(progress * math.pi))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;

      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(progress * math.pi * 2);
      
      final hexPath = Path();
      final radius = squareSize * 0.48;
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;
        if (i == 0) {
          hexPath.moveTo(x, y);
        } else {
          hexPath.lineTo(x, y);
        }
      }
      hexPath.close();
      canvas.drawPath(hexPath, shieldPaint);
      canvas.restore();

      // Golden landing shimmer ring expansion
      if (progress > 0.8) {
        final lt = (progress - 0.8) / 0.2;
        final shimmerPaint = Paint()
          ..color = goldColor.withValues(alpha: 0.7 * (1.0 - lt))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 * (1.0 - lt);
        canvas.drawCircle(dest, squareSize * 0.55 * lt, shimmerPaint);
      }
      return;
    }
  }

  @override
  bool shouldRepaint(covariant _ArcModernSignaturePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rawProgress != rawProgress ||
        oldDelegate.pieceCode != pieceCode ||
        oldDelegate.isTeleport != isTeleport;
  }
}

// ── Fairytale: "Fairytale Modern Signature" Painter ──────────────────────────

class _FairytaleModernSignaturePainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final double rawProgress;
  final String pieceCode;
  final double squareSize;
  final bool isTeleport;

  _FairytaleModernSignaturePainter({
    required this.path,
    required this.progress,
    required this.rawProgress,
    required this.pieceCode,
    required this.squareSize,
    required this.isTeleport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final pieceType = pieceCode.length > 1
        ? pieceCode.substring(1).toUpperCase()
        : pieceCode.toUpperCase();
    final origin = path.first;
    final dest = path.last;

    const goldColor = Color(0xFFFFD700);
    const pinkColor = Color(0xFFFFB6C1);
    const lavenderColor = Color(0xFFE6E6FA);
    const sproutColor = Color(0xFF90EE90);
    const stoneColor = Color(0xFFE7DEC9);

    if (isTeleport || pieceType == 'Q') {
      // ♛ Queen: Hand-Mirror Teleport Gate
      if (rawProgress < 0.4) {
        final t = rawProgress / 0.4;
        final paint = Paint()
          ..color = goldColor.withValues(alpha: 0.85 * (1.0 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.save();
        canvas.translate(origin.dx, origin.dy);
        canvas.rotate(t * math.pi * 0.4);
        
        // Draw vintage hand-mirror outline
        final mirrorRect = Rect.fromCenter(center: Offset.zero, width: squareSize * 0.5, height: squareSize * 0.65);
        canvas.drawOval(mirrorRect, paint);
        canvas.drawLine(Offset(0, squareSize * 0.325), Offset(0, squareSize * 0.5), paint);
        canvas.restore();
        
        // Butterfly/Sparkle cloud at start
        final random = math.Random(777);
        final sparkPaint = Paint()..color = pinkColor.withValues(alpha: 0.7 * (1.0 - t));
        for (int i = 0; i < 6; i++) {
          final offset = Offset(
            (random.nextDouble() - 0.5) * squareSize * 0.5,
            (random.nextDouble() - 0.5) * squareSize * 0.5 - t * 15,
          );
          canvas.drawCircle(origin + offset, 2.0 + random.nextDouble() * 2.0, sparkPaint);
        }
      }

      if (rawProgress > 0.6) {
        final t = (rawProgress - 0.6) / 0.4;
        final paint = Paint()
          ..color = goldColor.withValues(alpha: 0.85 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.save();
        canvas.translate(dest.dx, dest.dy);
        canvas.rotate((1.0 - t) * math.pi * 0.4);
        
        final mirrorRect = Rect.fromCenter(center: Offset.zero, width: squareSize * 0.5, height: squareSize * 0.65);
        canvas.drawOval(mirrorRect, paint);
        canvas.drawLine(Offset(0, squareSize * 0.325), Offset(0, squareSize * 0.5), paint);
        canvas.restore();
        
        // Butterfly/Sparkle cloud at dest
        final random = math.Random(888);
        final sparkPaint = Paint()..color = lavenderColor.withValues(alpha: 0.7 * t);
        for (int i = 0; i < 6; i++) {
          final offset = Offset(
            (random.nextDouble() - 0.5) * squareSize * 0.5,
            (random.nextDouble() - 0.5) * squareSize * 0.5 - (1.0 - t) * 15,
          );
          canvas.drawCircle(dest + offset, 2.0 + random.nextDouble() * 2.0, sparkPaint);
        }
      }

      // Warp speed sparkles
      if (rawProgress >= 0.2 && rawProgress <= 0.8) {
        final random = math.Random(999);
        final opacity = math.sin((rawProgress - 0.2) / 0.6 * math.pi);
        final colors = [pinkColor, goldColor, lavenderColor];

        for (int i = 0; i < 8; i++) {
          final tOffset = (random.nextDouble() - 0.5) * squareSize * 0.4;
          final currentPos = Offset.lerp(origin, dest, rawProgress)! + Offset(tOffset, (random.nextDouble() - 0.5) * squareSize * 0.4);
          
          final paint = Paint()
            ..color = colors[random.nextInt(colors.length)].withValues(alpha: opacity * 0.6)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(currentPos, 1.5 + random.nextDouble() * 2.0, paint);
        }
      }
      return;
    }

    if (pieceType == 'N') {
      // ♞ Knight: Pegasus Leap (Rainbow Ribbon)
      if (path.length >= 3) {
        final p0 = path[0];
        final p1 = path[1];
        final p2 = path[2];

        // 1. Draw smooth pastel gradient ribbon path
        final steps = 40;
        final ribbonPath = Path()..moveTo(p0.dx, p0.dy);
        for (int i = 1; i <= steps; i++) {
          final t = i / steps;
          final x = (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
          final y = (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
          ribbonPath.lineTo(x, y);
        }

        final ribbonPaint = Paint()
          ..shader = const LinearGradient(
            colors: [goldColor, pinkColor, lavenderColor],
          ).createShader(Rect.fromPoints(p0, p2))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5;

        final glowPaint = Paint()
          ..color = pinkColor.withValues(alpha: 0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

        canvas.drawPath(ribbonPath, glowPaint);
        canvas.drawPath(ribbonPath, ribbonPaint);

        // 2. Falling gravity-bound stardust sparks
        final random = math.Random(1314);
        for (int i = 0; i < 18; i++) {
          final sparkAge = (rawProgress * 1.4 - i * 0.065).clamp(0.0, 1.0);
          if (sparkAge <= 0 || sparkAge >= 1.0) continue;

          final st = sparkAge;
          final sPos = Offset(
            (1 - st) * (1 - st) * p0.dx + 2 * (1 - st) * st * p1.dx + st * st * p2.dx,
            (1 - st) * (1 - st) * p0.dy + 2 * (1 - st) * st * p1.dy + st * st * p2.dy,
          );

          // Translate vertically for jump, and drift downwards under gravity
          final jumpY = -math.sin(sparkAge * math.pi) * squareSize * 0.9;
          final gravityDrift = (rawProgress - sparkAge) * 22.0; // falls down
          final finalPos = sPos.translate(
            (random.nextDouble() - 0.5) * 8.0,
            jumpY + gravityDrift + (random.nextDouble() - 0.5) * 6.0,
          );

          final opacity = (1.0 - (rawProgress - sparkAge) * 3.5).clamp(0.0, 0.8);
          if (opacity <= 0) continue;

          final colors = [goldColor, pinkColor, lavenderColor];
          final sparkPaint = Paint()
            ..color = colors[random.nextInt(colors.length)].withValues(alpha: opacity)
            ..style = PaintingStyle.fill;
          
          canvas.drawCircle(finalPos, 1.5 + random.nextDouble() * 2.0, sparkPaint);
        }

        // 3. Landing shockwave (expanding bubbles)
        if (progress > 0.8) {
          final lt = (progress - 0.8) / 0.2;
          final ringPaint = Paint()
            ..color = pinkColor.withValues(alpha: 0.5 * (1.0 - lt))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2 * (1.0 - lt);
          
          canvas.drawCircle(p2, squareSize * 0.45 * lt, ringPaint);
          
          final bubblePaint = Paint()
            ..color = lavenderColor.withValues(alpha: 0.3 * (1.0 - lt))
            ..style = PaintingStyle.fill;
          final randomBubble = math.Random(1212);
          for (int b = 0; b < 6; b++) {
            final angle = randomBubble.nextDouble() * 2 * math.pi;
            final dist = squareSize * 0.5 * lt;
            final bubblePos = p2 + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
            canvas.drawCircle(bubblePos, 3.0 + randomBubble.nextDouble() * 3.0, bubblePaint);
          }
        }
      }
      return;
    }

    if (pieceType == 'B') {
      // ♝ Bishop: Stardust Double-Helix
      final currentPos = Offset.lerp(origin, dest, progress)!;

      // Draw subtle core trajectory line
      final corePaint = Paint()
        ..color = lavenderColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(origin, currentPos, corePaint);

      final direction = dest - origin;
      if (direction.distance > 0.1) {
        final dirNorm = direction / direction.distance;
        final ortho = Offset(-dirNorm.dy, dirNorm.dx);
        
        final points1 = <Offset>[];
        final points2 = <Offset>[];
        final steps = (progress * 40).clamp(2, 80).toInt();
        for (int i = 0; i <= steps; i++) {
          final t = (i / steps) * progress;
          final pos = Offset.lerp(origin, dest, t)!;
          // Sine wave oscillation for the helix wrap
          final wave = math.sin(t * math.pi * 5.5) * 7.5;
          
          points1.add(pos + ortho * wave);
          points2.add(pos - ortho * wave);
        }
        
        final paint1 = Paint()
          ..color = pinkColor.withValues(alpha: 0.65)
          ..strokeWidth = 1.8;

        final paint2 = Paint()
          ..color = goldColor.withValues(alpha: 0.65)
          ..strokeWidth = 1.8;

        // Draw overlapping dots or segments to look sparkling
        for (int i = 0; i < points1.length; i++) {
          final op = (1.0 - (progress - (i / points1.length) * progress) * 2.0).clamp(0.0, 1.0);
          if (op <= 0) continue;
          
          canvas.drawCircle(points1[i], 1.2, paint1..color = pinkColor.withValues(alpha: op * 0.65));
          canvas.drawCircle(points2[i], 1.2, paint2..color = goldColor.withValues(alpha: op * 0.65));
        }

        for (int i = 0; i < 4; i++) {
          final tSpawn = 0.2 + i * 0.22;
          if (progress < tSpawn) continue;
          final age = progress - tSpawn;
          if (age > 0.35) continue;

          final opacity = (1.0 - age / 0.35).clamp(0.0, 0.7);
          final size = 4.5 * (1.0 - age / 0.35);
          final pos = Offset.lerp(origin, dest, tSpawn)!;

          final shardPaint = Paint()
            ..color = lavenderColor.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

          canvas.save();
          canvas.translate(pos.dx, pos.dy);
          canvas.rotate(age * math.pi * 2.5);
          
          final diamondPath = Path()
            ..moveTo(0, -size)
            ..lineTo(size * 0.6, 0)
            ..lineTo(0, size)
            ..lineTo(-size * 0.6, 0)
            ..close();
          canvas.drawPath(diamondPath, shardPaint);
          canvas.restore();
        }
      }
      return;
    }

    if (pieceType == 'R') {
      // ♜ Rook: Castle Rampart Silhouettes
      final steps = 3;
      final paint = Paint()
        ..color = stoneColor.withValues(alpha: 0.16 * (1.0 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (int i = 0; i < steps; i++) {
        final t = i / (steps - 1);
        final pos = Offset.lerp(origin, dest, t * progress)!;
        _drawTurretSilhouette(canvas, pos, squareSize, paint);
      }

      // Landing dust puff (glitter explosion)
      if (progress > 0.8) {
        final lt = (progress - 0.8) / 0.2;
        final random = math.Random(202);
        final puffPaint = Paint()
          ..color = goldColor.withValues(alpha: 0.5 * (1.0 - lt))
          ..style = PaintingStyle.fill;

        for (int p = 0; p < 8; p++) {
          final angle = p * math.pi / 4;
          final dist = squareSize * 0.55 * lt;
          final puffPos = dest + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
          canvas.drawCircle(puffPos, 2.0 + random.nextDouble() * 2.5, puffPaint);
        }
      }
      return;
    }

    if (pieceType == 'P') {
      // ♟ Pawn: Sprout Glide (Green leaves / Gold stars)
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final direction = dest - origin;
      if (direction.distance > 0.1) {
        final dirNorm = direction / direction.distance;
        final backPos = currentPos - dirNorm * (squareSize * 0.35);

        final sproutPaint = Paint()
          ..color = sproutColor.withValues(alpha: 0.7 * (1.0 - progress))
          ..style = PaintingStyle.fill;

        final goldPaint = Paint()
          ..color = goldColor.withValues(alpha: 0.6 * (1.0 - progress))
          ..style = PaintingStyle.fill;

        // Draw small leaf sprout at the back
        _drawLeaf(canvas, backPos, 5.0, sproutPaint);
        
        // Draw tiny spark
        canvas.drawCircle(backPos - dirNorm * 8.0, 1.5, goldPaint);
      }
      return;
    }

    if (pieceType == 'K') {
      // ♚ King: Royal Crown Halo
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final haloPaint = Paint()
        ..color = goldColor.withValues(alpha: 0.32 * math.sin(progress * math.pi))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.save();
      // Offset Y coordinate to float above King's head
      canvas.translate(currentPos.dx, currentPos.dy - squareSize * 0.32);
      canvas.rotate(progress * math.pi * 1.5);
      
      // Draw 3D-perspective tilted ellipse halo ring
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: squareSize * 0.68, height: squareSize * 0.22), haloPaint);
      
      // Draw mini crown stars orbiting the halo
      final starPaint = Paint()..color = goldColor.withValues(alpha: 0.65 * math.sin(progress * math.pi));
      for (int i = 0; i < 3; i++) {
        final angle = i * 2 * math.pi / 3 + progress * math.pi;
        final x = math.cos(angle) * (squareSize * 0.34);
        final y = math.sin(angle) * (squareSize * 0.11);
        canvas.drawCircle(Offset(x, y), 2.0, starPaint);
      }
      
      canvas.restore();
      return;
    }
  }

  void _drawTurretSilhouette(Canvas canvas, Offset center, double size, Paint paint) {
    final w = size * 0.36;
    final h = size * 0.45;
    final left = center.dx - w / 2;
    final top = center.dy - h / 2;
    
    final path = Path()
      ..moveTo(left, top + h)
      ..lineTo(left + w, top + h)
      ..lineTo(left + w, top + h * 0.2)
      // Crenellations
      ..lineTo(left + w * 0.8, top + h * 0.2)
      ..lineTo(left + w * 0.8, top)
      ..lineTo(left + w * 0.6, top)
      ..lineTo(left + w * 0.6, top + h * 0.2)
      ..lineTo(left + w * 0.4, top + h * 0.2)
      ..lineTo(left + w * 0.4, top)
      ..lineTo(left + w * 0.2, top + h * 0.2)
      ..lineTo(left, top + h * 0.2)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawLeaf(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(center.dx + size * 0.6, center.dy - size * 0.4, center.dx, center.dy)
      ..quadraticBezierTo(center.dx - size * 0.6, center.dy - size * 0.4, center.dx, center.dy - size)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FairytaleModernSignaturePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rawProgress != rawProgress ||
        oldDelegate.pieceCode != pieceCode ||
        oldDelegate.isTeleport != isTeleport;
  }
}

// ── Plasma: "Plasma Modern Signature" Painter ────────────────────────────────

class _PlasmaModernSignaturePainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final double rawProgress;
  final String pieceCode;
  final double squareSize;
  final bool isTeleport;

  _PlasmaModernSignaturePainter({
    required this.path,
    required this.progress,
    required this.rawProgress,
    required this.pieceCode,
    required this.squareSize,
    required this.isTeleport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final pieceType = pieceCode.length > 1
        ? pieceCode.substring(1).toUpperCase()
        : pieceCode.toUpperCase();
    final origin = path.first;
    final dest = path.last;

    final cyanColor = const Color(0xFF00BFFF);
    final purpleColor = const Color(0xFF9C3FE4);
    final pinkColor = const Color(0xFFFF007F);

    if (isTeleport || pieceType == 'Q') {
      // Queen: Singularity Teleport
      if (rawProgress < 0.45) {
        final t = rawProgress / 0.45;
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        final paint = Paint()
          ..color = purpleColor.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(origin, (squareSize * 0.6) * (1.0 - t), paint);
        final random = math.Random(101);
        for (int i = 0; i < 12; i++) {
          final angle = random.nextDouble() * 2 * math.pi;
          final dist = squareSize * 0.8 * (1.0 - t * 0.9);
          final pPos = origin + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
          canvas.drawRect(Rect.fromCenter(center: pPos, width: 3, height: 3), Paint()..color = cyanColor.withValues(alpha: opacity));
        }
      }
      if (rawProgress > 0.55) {
        final t = (rawProgress - 0.55) / 0.45;
        final opacity = t.clamp(0.0, 1.0);
        final paint = Paint()
          ..color = cyanColor.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

        canvas.drawCircle(dest, (squareSize * 0.6) * t, paint);
        final random = math.Random(202);
        for (int i = 0; i < 15; i++) {
          final angle = random.nextDouble() * 2 * math.pi;
          final dist = squareSize * 0.8 * t * random.nextDouble();
          final pPos = dest + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
          canvas.drawRect(Rect.fromCenter(center: pPos, width: 4 * (1.0 - t), height: 4 * (1.0 - t)), Paint()..color = purpleColor.withValues(alpha: opacity));
        }
      }
      return;
    }

    if (pieceType == 'N') {
      // Knight: Parabolic leap code nodes
      if (path.length >= 3) {
        final p0 = path[0];
        final p1 = path[1];
        final p2 = path[2];

        final random = math.Random(303);
        for (int i = 0; i < 16; i++) {
          final sparkAge = (rawProgress * 1.3 - i * 0.06).clamp(0.0, 1.0);
          if (sparkAge <= 0 || sparkAge >= 1.0) continue;

          final st = sparkAge;
          final sPos = Offset(
            (1 - st) * (1 - st) * p0.dx + 2 * (1 - st) * st * p1.dx + st * st * p2.dx,
            (1 - st) * (1 - st) * p0.dy + 2 * (1 - st) * st * p1.dy + st * st * p2.dy,
          );

          final jumpY = -math.sin(sparkAge * math.pi) * squareSize * 0.9;
          final finalPos = sPos.translate(
            (random.nextDouble() - 0.5) * 6.0,
            jumpY + (random.nextDouble() - 0.5) * 6.0,
          );

          final opacity = (1.0 - (rawProgress - sparkAge) * 3.5).clamp(0.0, 0.85);
          if (opacity <= 0) continue;

          final paint = Paint()
            ..color = (i % 2 == 0 ? cyanColor : purpleColor).withValues(alpha: opacity)
            ..style = PaintingStyle.fill;
          canvas.drawRect(Rect.fromCenter(center: finalPos, width: 3.5, height: 3.5), paint);
        }

        if (progress > 0.8) {
          final lt = (progress - 0.8) / 0.2;
          final ringPaint = Paint()
            ..color = cyanColor.withValues(alpha: 0.6 * (1.0 - lt))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0 * (1.0 - lt);
          canvas.drawCircle(p2, squareSize * 0.5 * lt, ringPaint);
        }
      }
      return;
    }

    if (pieceType == 'B') {
      // Bishop: Plasma diagonal beam sweep with rotating helix
      final currentPos = Offset.lerp(origin, dest, progress)!;

      final glowPaint = Paint()
        ..color = cyanColor.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawLine(origin, currentPos, glowPaint);
      canvas.drawLine(origin, currentPos, corePaint);

      final direction = dest - origin;
      if (direction.distance > 0.1) {
        final dirNorm = direction / direction.distance;
        final ortho = Offset(-dirNorm.dy, dirNorm.dx);
        final steps = (progress * 25).toInt().clamp(2, 50);
        final helixPaint = Paint()
          ..color = pinkColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill;

        for (int i = 0; i <= steps; i++) {
          final t = (i / steps) * progress;
          final pos = Offset.lerp(origin, dest, t)!;
          final wave = math.sin(t * math.pi * 6.0 + rawProgress * math.pi * 2.0) * 8.0;
          canvas.drawCircle(pos + ortho * wave, 2.0, helixPaint);
        }
      }
      return;
    }

    if (pieceType == 'R') {
      // Rook: Cyber-rail and terminal landing wall
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final railPaint = Paint()
        ..color = cyanColor.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final dx = (dest.dx - origin.dx).abs();
      final dy = (dest.dy - origin.dy).abs();
      final offset = dx > dy ? const Offset(0, 10.0) : const Offset(10.0, 0);

      canvas.drawLine(origin - offset, dest - offset, railPaint);
      canvas.drawLine(origin + offset, dest + offset, railPaint);

      final fillPaint = Paint()
        ..color = cyanColor.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromPoints(origin - offset, currentPos + offset), fillPaint);

      if (progress > 0.75) {
        final lt = (progress - 0.75) / 0.25;
        final wallPaint = Paint()
          ..color = purpleColor.withValues(alpha: 0.6 * (1.0 - lt))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        final rect = Rect.fromCenter(center: dest, width: squareSize * 0.8, height: squareSize * 0.8);
        canvas.drawRect(rect, wallPaint);
        canvas.drawRect(rect.deflate(4.0), wallPaint);
      }
      return;
    }

    if (pieceType == 'P') {
      // Pawn: Ion Stream Thruster
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final direction = dest - origin;
      if (direction.distance > 0.1) {
        final dirNorm = direction / direction.distance;
        final backPos = currentPos - dirNorm * (squareSize * 0.3);
        final ortho = Offset(-dirNorm.dy, dirNorm.dx) * 5.0;

        final thrusterPaint = Paint()
          ..color = cyanColor.withValues(alpha: 0.7 * (1.0 - progress))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawLine(backPos - ortho, backPos - ortho - dirNorm * 10.0, thrusterPaint);
        canvas.drawLine(backPos + ortho, backPos + ortho - dirNorm * 10.0, thrusterPaint);

        final random = math.Random();
        for (int i = 0; i < 3; i++) {
          final pPos = backPos - dirNorm * 8.0 + (math.Random().nextBool() ? ortho : -ortho) * random.nextDouble();
          canvas.drawCircle(pPos, 1.0, Paint()..color = purpleColor.withValues(alpha: 0.6 * (1.0 - progress)));
        }
      }
      return;
    }

    if (pieceType == 'K') {
      // King: Plasma Hexagonal Forcefield
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final shieldPaint = Paint()
        ..color = purpleColor.withValues(alpha: 0.4 * math.sin(progress * math.pi))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(progress * math.pi * 2.0);
      
      final hexPath = Path();
      final radius = squareSize * 0.5;
      for (int i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;
        if (i == 0) {
          hexPath.moveTo(x, y);
        } else {
          hexPath.lineTo(x, y);
        }
      }
      hexPath.close();
      canvas.drawPath(hexPath, shieldPaint);

      final innerPaint = Paint()
        ..color = cyanColor.withValues(alpha: 0.2 * math.sin(progress * math.pi))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, radius * 0.6, innerPaint);
      canvas.restore();
      return;
    }
  }

  @override
  bool shouldRepaint(covariant _PlasmaModernSignaturePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rawProgress != rawProgress ||
        oldDelegate.pieceCode != pieceCode ||
        oldDelegate.isTeleport != isTeleport;
  }
}

// ── Lightning: "Lightning Modern Signature" Painter ──────────────────────────

class _LightningModernSignaturePainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final double rawProgress;
  final String pieceCode;
  final double squareSize;
  final bool isTeleport;

  _LightningModernSignaturePainter({
    required this.path,
    required this.progress,
    required this.rawProgress,
    required this.pieceCode,
    required this.squareSize,
    required this.isTeleport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final pieceType = pieceCode.length > 1
        ? pieceCode.substring(1).toUpperCase()
        : pieceCode.toUpperCase();
    final origin = path.first;
    final dest = path.last;

    final electricBlue = const Color(0xFF00E5FF);
    final skyCyan = const Color(0xFFE0FFFF);

    if (isTeleport || pieceType == 'Q') {
      // Queen: Thunderous Smite
      if (rawProgress < 0.3) {
        final t = rawProgress / 0.3;
        final paint = Paint()
          ..color = Colors.grey.withValues(alpha: 0.5 * (1.0 - t))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(origin, squareSize * 0.4 * t, paint);
      }
      if (rawProgress >= 0.5 && rawProgress <= 0.95) {
        final t = (rawProgress - 0.5) / 0.45;
        final opacity = math.sin(t * math.pi);
        final paint = Paint()
          ..color = electricBlue.withValues(alpha: opacity)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;
        final glow = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.8)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        final boltPath = Path();
        boltPath.moveTo(dest.dx, dest.dy - squareSize * 4.0);
        
        final segments = 8;
        final random = math.Random(505);
        for (int i = 1; i <= segments; i++) {
          final st = i / segments;
          final y = dest.dy - squareSize * 4.0 * (1.0 - st);
          final jitterX = (random.nextDouble() - 0.5) * 15 * math.sin(st * math.pi);
          boltPath.lineTo(dest.dx + jitterX, y);
        }
        canvas.drawPath(boltPath, paint);
        canvas.drawPath(boltPath, glow);
      }
      return;
    }

    if (pieceType == 'N') {
      // Knight: Storm Tempest Leap
      if (path.length >= 3) {
        final p0 = path[0];
        final p1 = path[1];
        final p2 = path[2];

        final t = progress;
        final piecePos = Offset(
          (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx,
          (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy,
        );
        final jumpY = -math.sin(rawProgress * math.pi) * squareSize * 0.9;
        final cloudPos = piecePos.translate(0, jumpY);

        final cloudPaint = Paint()
          ..color = const Color(0xFF1E293B).withValues(alpha: 0.35 * math.sin(rawProgress * math.pi))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(cloudPos, squareSize * 0.45, cloudPaint);

        final random = math.Random(606);
        if (rawProgress > 0.1 && rawProgress < 0.9) {
          final sparkPaint = Paint()
            ..color = skyCyan.withValues(alpha: 0.8)
            ..strokeWidth = 1.0;
          for (int i = 0; i < 3; i++) {
            final start = cloudPos + Offset((random.nextDouble() - 0.5) * 15, (random.nextDouble() - 0.5) * 15);
            final end = start + Offset((random.nextDouble() - 0.5) * 10, (random.nextDouble() - 0.5) * 10);
            canvas.drawLine(start, end, sparkPaint);
          }
        }

        if (progress > 0.8) {
          final lt = (progress - 0.8) / 0.2;
          final strokePaint = Paint()
            ..color = electricBlue.withValues(alpha: 0.8 * (1.0 - lt))
            ..strokeWidth = 2.0 * (1.0 - lt)
            ..style = PaintingStyle.stroke;

          for (int d = 0; d < 4; d++) {
            final angle = d * math.pi / 2;
            final dist = squareSize * 0.75 * lt;
            final bolt = Path()..moveTo(p2.dx, p2.dy);
            
            final next = p2 + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
            final jitter = Offset((random.nextDouble() - 0.5) * 6, (random.nextDouble() - 0.5) * 6);
            bolt.lineTo(next.dx + jitter.dx, next.dy + jitter.dy);
            canvas.drawPath(bolt, strokePaint);
          }
        }
      }
      return;
    }

    if (pieceType == 'B') {
      // Bishop: Chain Lightning Bolt
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final dist = (currentPos - origin).distance;
      if (dist > 1.0) {
        final segments = (dist / 12).clamp(4, 25).toInt();
        final random = math.Random(707);
        final boltPath = Path()..moveTo(origin.dx, origin.dy);

        for (int i = 1; i <= segments; i++) {
          final st = i / segments;
          final p = Offset.lerp(origin, currentPos, st)!;
          final jitter = Offset(
            (random.nextDouble() - 0.5) * 14 * math.sin(st * math.pi),
            (random.nextDouble() - 0.5) * 14 * math.sin(st * math.pi),
          );
          boltPath.lineTo(p.dx + jitter.dx, p.dy + jitter.dy);
        }

        final boltPaint = Paint()
          ..color = electricBlue.withValues(alpha: 0.8)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        final glowPaint = Paint()
          ..color = skyCyan.withValues(alpha: 0.3)
          ..strokeWidth = 5.0
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawPath(boltPath, glowPaint);
        canvas.drawPath(boltPath, boltPaint);
      }
      return;
    }

    if (pieceType == 'R') {
      // Rook: High-Voltage Railgun
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final rayPaint = Paint()
        ..color = electricBlue.withValues(alpha: 0.4 * (1.0 - progress))
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke;
      final corePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * (1.0 - progress))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(origin, currentPos, rayPaint);
      canvas.drawLine(origin, currentPos, corePaint);

      final random = math.Random(808);
      if (progress > 0.1 && progress < 0.9) {
        final sparkPaint = Paint()..color = skyCyan..strokeWidth = 1.0;
        final samplePos = Offset.lerp(origin, currentPos, 0.5)!;
        canvas.drawLine(
          samplePos,
          samplePos + Offset((random.nextDouble() - 0.5) * 18, (random.nextDouble() - 0.5) * 18),
          sparkPaint,
        );
      }
      return;
    }

    if (pieceType == 'P') {
      // Pawn: Static Spark Trail
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final random = math.Random(909);
      if (progress > 0.2 && progress < 0.9) {
        final paint = Paint()
          ..color = electricBlue.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

        final start = currentPos - (dest - origin) * 0.2;
        final end = start + Offset((random.nextDouble() - 0.5) * 10, (random.nextDouble() - 0.5) * 10);
        canvas.drawLine(start, end, paint);
        canvas.drawCircle(end, 1.5, Paint()..color = skyCyan);
      }
      return;
    }

    if (pieceType == 'K') {
      // King: Tesla Cage Shield
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final opacity = math.sin(progress * math.pi);
      
      final shieldPaint = Paint()
        ..color = electricBlue.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(currentPos, squareSize * 0.48, shieldPaint);

      final random = math.Random(1010);
      final radius = squareSize * 0.48;
      final arcPath = Path();
      
      for (int i = 0; i < 5; i++) {
        final angle = (i * 2 * math.pi / 5) + (random.nextDouble() * 0.2);
        final start = currentPos + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        final nextAngle = ((i + 1) * 2 * math.pi / 5);
        final end = currentPos + Offset(math.cos(nextAngle) * radius, math.sin(nextAngle) * radius);
        
        final middle = Offset.lerp(start, end, 0.5)! + Offset((random.nextDouble() - 0.5) * 6, (random.nextDouble() - 0.5) * 6);
        
        arcPath.moveTo(start.dx, start.dy);
        arcPath.lineTo(middle.dx, middle.dy);
        arcPath.lineTo(end.dx, end.dy);
      }
      
      canvas.drawPath(arcPath, Paint()..color = skyCyan.withValues(alpha: opacity * 0.7)..strokeWidth = 1.0..style = PaintingStyle.stroke);
      return;
    }
  }

  @override
  bool shouldRepaint(covariant _LightningModernSignaturePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rawProgress != rawProgress ||
        oldDelegate.pieceCode != pieceCode ||
        oldDelegate.isTeleport != isTeleport;
  }
}

// ── Diamonds: "Diamonds Modern Signature" Painter ────────────────────────────

class _DiamondsModernSignaturePainter extends CustomPainter {
  final List<Offset> path;
  final double progress;
  final double rawProgress;
  final String pieceCode;
  final double squareSize;
  final bool isTeleport;

  _DiamondsModernSignaturePainter({
    required this.path,
    required this.progress,
    required this.rawProgress,
    required this.pieceCode,
    required this.squareSize,
    required this.isTeleport,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final pieceType = pieceCode.length > 1
        ? pieceCode.substring(1).toUpperCase()
        : pieceCode.toUpperCase();
    final origin = path.first;
    final dest = path.last;

    final crystalCyan = const Color(0xFF80DEEA);

    if (isTeleport || pieceType == 'Q') {
      // Queen: Chromatic Aberration RGB splits
      if (rawProgress > 0.1 && rawProgress < 0.9) {
        final opacity = math.sin((rawProgress - 0.1) / 0.8 * math.pi) * 0.45;
        final currentPos = Offset.lerp(origin, dest, progress)!;
        final drift = Offset(8.0 * math.sin(rawProgress * math.pi), 0);

        final redPaint = Paint()..color = const Color(0xFFFF0000).withValues(alpha: opacity)..style = PaintingStyle.fill;
        final greenPaint = Paint()..color = const Color(0xFF00FF00).withValues(alpha: opacity)..style = PaintingStyle.fill;
        final bluePaint = Paint()..color = const Color(0xFF0000FF).withValues(alpha: opacity)..style = PaintingStyle.fill;

        canvas.drawCircle(currentPos - drift, squareSize * 0.25, redPaint);
        canvas.drawCircle(currentPos, squareSize * 0.25, greenPaint);
        canvas.drawCircle(currentPos + drift, squareSize * 0.25, bluePaint);
      }

      if (progress > 0.8) {
        final lt = (progress - 0.8) / 0.2;
        final random = math.Random(111);
        final shardPaint = Paint()..color = Colors.white.withValues(alpha: 0.7 * (1.0 - lt))..style = PaintingStyle.fill;
        for (int i = 0; i < 6; i++) {
          final angle = random.nextDouble() * 2 * math.pi;
          final dist = squareSize * 0.6 * lt;
          final shardPos = dest + Offset(math.cos(angle) * dist, math.sin(angle) * dist);
          canvas.drawRect(Rect.fromCenter(center: shardPos, width: 3.0, height: 3.0), shardPaint);
        }
      }
      return;
    }

    if (pieceType == 'N') {
      // Knight: Crystal Bridge Leap
      if (path.length >= 3) {
        final p0 = path[0];
        final p2 = path[2];

        final steps = [0.25, 0.5, 0.75];
        for (int i = 0; i < steps.length; i++) {
          final tStep = steps[i];
          if (progress < tStep) continue;

          final age = progress - tStep;
          if (age > 0.3) continue;

          final opacity = (1.0 - age / 0.3).clamp(0.0, 0.7);
          final stepPos = Offset.lerp(p0, p2, tStep)!;
          final jumpY = -math.sin(tStep * math.pi) * squareSize * 0.9;
          final finalPos = stepPos.translate(0, jumpY);

          final stepPaint = Paint()
            ..color = crystalCyan.withValues(alpha: opacity)
            ..style = PaintingStyle.fill;
          final glowPaint = Paint()
            ..color = Colors.white.withValues(alpha: opacity * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

          canvas.save();
          canvas.translate(finalPos.dx, finalPos.dy);
          canvas.rotate(age * math.pi);
          final rect = Rect.fromCenter(center: Offset.zero, width: 12.0, height: 6.0);
          canvas.drawRect(rect, stepPaint);
          canvas.drawRect(rect, glowPaint);
          canvas.restore();
        }
      }
      return;
    }

    if (pieceType == 'B') {
      // Bishop: Prismatic Laser down diagonal
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final whitePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(origin, currentPos, whitePaint);

      if (progress > 0.75) {
        final lt = (progress - 0.75) / 0.25;
        final colors = [
          const Color(0xFFFF8A80),
          const Color(0xFFFFD180),
          const Color(0xFFCCFF90),
          const Color(0xFFA7FFEB),
          const Color(0xFF82B1FF),
          const Color(0xFFEA80FC),
        ];

        for (int i = 0; i < colors.length; i++) {
          final angle = (i * 2 * math.pi / colors.length) + lt * 0.5;
          final dist = squareSize * 0.7 * lt;
          final colorPaint = Paint()
            ..color = colors[i].withValues(alpha: 0.6 * (1.0 - lt))
            ..strokeWidth = 1.5;
          canvas.drawLine(dest, dest + Offset(math.cos(angle) * dist, math.sin(angle) * dist), colorPaint);
        }
      }
      return;
    }

    if (pieceType == 'R') {
      // Rook: Crystal Wall Slide
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final wallPaint = Paint()
        ..color = crystalCyan.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final dx = (dest.dx - origin.dx).abs();
      final dy = (dest.dy - origin.dy).abs();
      final offset = dx > dy ? const Offset(0, 8.0) : const Offset(8.0, 0);

      canvas.drawPath(
        Path()
          ..moveTo(origin.dx - offset.dx, origin.dy - offset.dy)
          ..lineTo(currentPos.dx - offset.dx, currentPos.dy - offset.dy)
          ..lineTo(currentPos.dx + offset.dx, currentPos.dy + offset.dy)
          ..lineTo(origin.dx + offset.dx, origin.dy + offset.dy)
          ..close(),
        wallPaint,
      );

      final steps = 4;
      for (int i = 0; i <= steps; i++) {
        final t = (i / steps) * progress;
        final p = Offset.lerp(origin, dest, t)!;
        canvas.drawRect(Rect.fromCenter(center: p, width: 4, height: 4), borderPaint);
      }
      return;
    }

    if (pieceType == 'P') {
      // Pawn: Prism Trail
      final rainbowColors = [
        const Color(0xFFFF8A80),
        const Color(0xFFCCFF90),
        const Color(0xFF82B1FF),
        const Color(0xFFEA80FC),
      ];

      for (int i = 0; i < rainbowColors.length; i++) {
        final tOffset = 0.1 + i * 0.15;
        if (progress < tOffset) continue;
        final age = progress - tOffset;
        if (age > 0.3) continue;

        final opacity = (1.0 - age / 0.3).clamp(0.0, 0.85);
        final trailPos = Offset.lerp(origin, dest, tOffset)!;
        
        canvas.drawCircle(
          trailPos,
          2.0,
          Paint()..color = rainbowColors[i % rainbowColors.length].withValues(alpha: opacity),
        );
      }
      return;
    }

    if (pieceType == 'K') {
      // King: Crystalline Aegis
      final currentPos = Offset.lerp(origin, dest, progress)!;
      final opacity = math.sin(progress * math.pi);
      
      final paint = Paint()
        ..color = crystalCyan.withValues(alpha: opacity * 0.4)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(progress * math.pi);
      
      final octagon = Path();
      final radius = squareSize * 0.48;
      for (int i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        final x = math.cos(angle) * radius;
        final y = math.sin(angle) * radius;
        if (i == 0) {
          octagon.moveTo(x, y);
        } else {
          octagon.lineTo(x, y);
        }
      }
      octagon.close();
      canvas.drawPath(octagon, paint);
      canvas.drawPath(octagon, border);
      canvas.restore();
      return;
    }
  }

  @override
  bool shouldRepaint(covariant _DiamondsModernSignaturePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rawProgress != rawProgress ||
        oldDelegate.pieceCode != pieceCode ||
        oldDelegate.isTeleport != isTeleport;
  }
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

