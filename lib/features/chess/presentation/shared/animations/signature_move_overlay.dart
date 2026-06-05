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

  const SignatureMoveOverlay({
    super.key,
    required this.data,
    required this.boardSize,
    required this.isFlipped,
    this.isCheckmate = false,
    required this.onComplete,
    this.onLand,
    this.onActionTrigger,
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
        AnimationController(vsync: this, duration: _effectiveMoveDuration)
          ..addStatusListener((status) {
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

    _curvedProgress = CurvedAnimation(
      parent: _controller,
      curve: _profile.moveCurve,
    );

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
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 200);
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

        final piecePos = _getPositionOnPath(_path, progress);

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
      OrbitalPulseTrail() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _OrbitalPulseTrailPainter(path: _path, progress: progress, squareSize: _squareSize, isTeleport: isTeleport),
        ),
      FairyDustTrail() => CustomPaint(
          size: Size(widget.boardSize, widget.boardSize),
          painter: _FairyDustTrailPainter(path: _path, progress: progress, isTeleport: isTeleport),
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
