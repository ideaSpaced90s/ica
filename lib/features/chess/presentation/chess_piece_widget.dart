import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'widgets/toy_effects.dart';
import 'animation/piece_motion_profile.dart';

import 'utils/contrast_utility.dart';
import 'themes/theme_registry.dart';


import 'package:chess/chess.dart' as chess_lib;

class ChessPieceWidget extends ConsumerStatefulWidget {
  final String squareName;
  final String? pieceCode;
  final bool highlighted;
  final bool isMoving;
  final double rotation;
  final VoidCallback? onTap;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragEnd;

  const ChessPieceWidget({
    super.key,
    required this.squareName,
    this.pieceCode,
    this.highlighted = false,
    this.isMoving = false,
    this.rotation = 0.0,
    this.onTap,
    this.onDragStarted,
    this.onDragEnd,
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
    final boardThemeId = chessState.boardThemeId;
    final animationsEnabled = chessState.isAnimationsEnabled;

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
    
    final theme = ThemeRegistry.getTheme(boardThemeId);

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

    // Apply selection enlargement (108% with elastic spring) — unchanged
    pieceWidget = AnimatedScale(
      scale: widget.isMoving ? (boardThemeId == 'theme8' || boardThemeId == 'theme4' ? 1.05 : 1.08) : (widget.highlighted ? (boardThemeId == 'theme8' || boardThemeId == 'theme4' ? 1.03 : 1.15) : 1.0),
      duration: (!animationsEnabled) ? Duration.zero : (boardThemeId == 'theme8' || boardThemeId == 'theme4' ? const Duration(milliseconds: 400) : const Duration(milliseconds: 200)),
      curve: boardThemeId == 'theme8' || boardThemeId == 'theme4' ? Curves.easeInOut : Curves.easeOutBack,
      child: AnimatedContainer(
        duration: (!animationsEnabled) ? Duration.zero : (boardThemeId == 'theme8' || boardThemeId == 'theme4' ? const Duration(milliseconds: 500) : const Duration(milliseconds: 300)),
        curve: boardThemeId == 'theme9' ? Curves.bounceOut : (boardThemeId == 'theme8' || boardThemeId == 'theme4' ? Curves.linear : Curves.elasticOut),
        transform: Matrix4.diagonal3Values(
          widget.isMoving ? (boardThemeId == 'theme8' || boardThemeId == 'theme4' ? 1.0 : 0.85) : 1.0,
          widget.isMoving ? (boardThemeId == 'theme9' ? 1.4 : (boardThemeId == 'theme8' || boardThemeId == 'theme4' ? 1.0 : 1.25)) : 1.0,
          1.0
        ),
        transformAlignment: Alignment.bottomCenter,
        child: pieceWidget,
      ),
    );

    // ── Breathing selection scale (Option B: always running, applied when highlighted) ──
    if (animationsEnabled && widget.highlighted && profile.hasBreathingSelection) {
      pieceWidget = AnimatedBuilder(
        animation: _breathingController,
        builder: (context, child) {
          final breathScale = 1.0 +
              profile.selectionBreathScale *
                  Curves.easeInOutSine.transform(_breathingController.value);
          return Transform.scale(
            scale: breathScale,
            child: child,
          );
        },
        child: pieceWidget,
      );
    }

    if (widget.highlighted && animationsEnabled) {
      final glowColor = boardThemeId == 'theme10'
          ? ContrastUtility.selectionGlow
          : ScholarlyTheme.selectedGlow;

      pieceWidget = AnimatedBuilder(
        animation: _levitationController,
        builder: (context, child) {
          // Profile-driven levitation height — heavier pieces float less
          final dy = -profile.levitationHeight *
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
    if (animationsEnabled && !widget.highlighted) {
      final chessStateForCheck = ref.read(chessProvider);
      final pieceOnSquare = chessStateForCheck.game.getPiece(widget.squareName);
      final isKingPiece = pieceOnSquare?.type == chess_lib.PieceType.KING;
      final isKingTurn = pieceOnSquare?.color == chessStateForCheck.game.turn;
      if (isKingPiece && isKingTurn && chessStateForCheck.game.inCheck) {
        pieceWidget = AnimatedBuilder(
          animation: _checkPulseController,
          builder: (context, child) {
            // Very gentle 0.97–1.0 scale — feels cautious, not aggressive
            final pulseScale = 0.97 +
                0.03 *
                    Curves.easeInOutSine.transform(_checkPulseController.value);
            return Transform.scale(
              scale: pulseScale,
              child: child,
            );
          },
          child: pieceWidget,
        );
      }
    }

    if (widget.pieceCode != null) return pieceWidget;

    // Apply 30% fade during movement animation
    // Apply wiggle if selected (for Toy themes)
    if (animationsEnabled && (boardThemeId == 'theme4' || boardThemeId == 'theme9') && widget.highlighted) {
      pieceWidget = WiggleAnimation(
        isActive: true,
        child: pieceWidget,
      );
    }

    final interactivePiece = widget.isMoving 
        ? Opacity(opacity: 0.30, child: pieceWidget)
        : pieceWidget;

    return Draggable<String>(
      data: widget.squareName,
      onDragStarted: widget.onDragStarted,
      onDragEnd: (_) => widget.onDragEnd?.call(),
      feedback: Transform.translate(
        // Subtle 2px positional lag illusion — makes dragging feel tactile
        offset: const Offset(2.0, 2.0),
        child: Transform.scale(
          scale: 1.15,
          child: SizedBox(
            width: 70,
            height: 70,
            child: pieceWidget,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: interactivePiece),
      child: interactivePiece,
    );
  }
}
