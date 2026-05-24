import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/chess_provider.dart';
import '../../scholarly_theme.dart';
import '../animations/piece_motion_profile.dart';

import '../../utils/contrast_utility.dart';
import '../themes/chess_theme.dart';
import '../themes/classic_theme.dart';

import 'package:chess/chess.dart' as chess_lib;

class ChessPieceWidget extends ConsumerStatefulWidget {
  final String squareName;
  final String? pieceCode;
  final bool highlighted;
  final bool isMoving;
  final bool forceVisible;
  final double rotation;
  final VoidCallback? onTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;
  final ChessTheme? theme;

  const ChessPieceWidget({
    super.key,
    required this.squareName,
    this.pieceCode,
    this.highlighted = false,
    this.isMoving = false,
    this.forceVisible = false,
    this.rotation = 0.0,
    this.onTap,
    this.onDragStarted,
    this.onDragEnd,
    this.theme,
  });

  @override
  ConsumerState<ChessPieceWidget> createState() => _ChessPieceWidgetState();
}

class _ChessPieceWidgetState extends ConsumerState<ChessPieceWidget>
    with TickerProviderStateMixin {
  late AnimationController _levitationController;
  late AnimationController _matrixDataController;

  /// Breathing scale effect for selected pieces — very subtle 1–2% variation.
  late AnimationController _breathingController;

  /// Low-frequency pulse for King when in check state.
  late AnimationController _checkPulseController;

  @override
  void initState() {
    super.initState();
    _levitationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _matrixDataController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    // Breathing: runs always, applied only when highlighted
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    // Check pulse: 1.2s slow oscillation, runs always, gated in build()
    _checkPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _levitationController.dispose();
    _matrixDataController.dispose();
    _breathingController.dispose();
    _checkPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);
    final theme = widget.theme ?? const ClassicTheme();

    var code = widget.pieceCode;

    if (code == null) {
      final piece = chessState.game.getPiece(widget.squareName);
      if (piece == null) return const SizedBox.shrink();

      final colorStr = piece.color.toString().toLowerCase();
      final colorPrefix = colorStr.contains('white') ? 'w' : 'b';

      code = '$colorPrefix${piece.type.toUpperCase()}';
    }

    final isWhite = code.startsWith('w');
    final type = code.substring(1).toUpperCase();

    // Render piece based on theme
    Widget pieceWidget = theme.buildPiece(
      context,
      type,
      isWhite,
      widget.highlighted,
      _matrixDataController.value,
    );

    // ── Resolve piece motion profile ─────────────────────────────────────
    // code is guaranteed non-null here (resolved above)
    final profile = PieceMotionProfile.forCode(code);

    // Note: Global piece selection enlargement and movement stretch animations have been disabled/removed.

    // ── Breathing selection scale (Option B: always running, applied when highlighted) ──
    if (ref.read(chessProvider.notifier).isAnimationTypeEnabled('feedback') &&
        widget.highlighted &&
        profile.hasBreathingSelection) {
      pieceWidget = AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          final breathScale =
              1.0 +
              profile.selectionBreathScale *
                  Curves.easeInOutSine.transform(_breathingController.value);
          return Transform.scale(scale: breathScale, child: child);
        },
        child: pieceWidget,
      );
    }

    if (widget.highlighted &&
        ref.read(chessProvider.notifier).isAnimationTypeEnabled('feedback')) {
      final glowColor = theme.id == 'theme10'
          ? ContrastUtility.selectionGlow
          : ScholarlyTheme.selectedGlow;

      pieceWidget = AnimatedBuilder(
        animation: _levitationController,
        builder: (context, child) {
          // Profile-driven levitation height — heavier pieces float less
          final dy =
              -profile.levitationHeight *
              Curves.easeInOutSine.transform(_levitationController.value);
          final glowOpacity = 0.3 + 0.3 * _levitationController.value;
          final blurRadius = 12.0 + 8.0 * _levitationController.value;

          return Transform.translate(
            offset: Offset(0, dy),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: glowOpacity),
                    blurRadius: blurRadius,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: pieceWidget,
      );
    }

    // ── King check pulse: subtle scale oscillation when King is in check ──
    if (widget.pieceCode == null &&
        widget.squareName != 'none' &&
        ref.read(chessProvider.notifier).isAnimationTypeEnabled('feedback') &&
        !widget.highlighted) {
      final chessStateForCheck = ref.read(chessProvider);
      final pieceOnSquare = chessStateForCheck.game.getPiece(widget.squareName);
      final isKingPiece = pieceOnSquare?.type == chess_lib.PieceType.KING;
      final isKingTurn = pieceOnSquare?.color == chessStateForCheck.game.turn;
      if (isKingPiece && isKingTurn && chessStateForCheck.game.inCheck) {
        pieceWidget = AnimatedBuilder(
          animation: _checkPulseController,
          builder: (context, child) {
            // Very gentle 0.97–1.0 scale — feels cautious, not aggressive
            final pulseScale =
                0.97 +
                0.03 *
                    Curves.easeInOutSine.transform(_checkPulseController.value);
            return Transform.scale(scale: pulseScale, child: child);
          },
          child: pieceWidget,
        );
      }
    }

    // ── Interaction and Visibility ───────────────────────────────────────
    final interactivePiece = widget.isMoving && !widget.forceVisible
        ? Opacity(opacity: 0.0, child: pieceWidget)
        : pieceWidget;

    return interactivePiece;
  }
}
