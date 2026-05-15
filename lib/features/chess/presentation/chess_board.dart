import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/chess_provider.dart';
import 'chess_piece_widget.dart';
import 'orbiting_star_animation.dart';
import 'scholarly_theme.dart';
import '../domain/chess_game.dart';
import 'widgets/promotion_overlay.dart';
import 'widgets/forest_effects.dart';
import 'widgets/toy_effects.dart';
import 'widgets/steampunk_effects.dart';
import 'widgets/electric_effects.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'widgets/high_contrast_piece.dart';
import 'widgets/ink_theme.dart';
import 'widgets/slate_theme.dart';
import 'widgets/liquid_theme.dart';
import 'widgets/platinum_theme.dart';
import 'widgets/grease_effects.dart';
import 'animation/signature_move_overlay.dart';
import 'animation/landing_feedback.dart';
import 'animation/tap_ripple.dart';
import 'animation/piece_motion_profile.dart';
import 'animation/knight_dust.dart';
import 'animation/bishop_wind.dart';
import 'animation/impact_shake.dart';
import 'animation/shake_animation.dart';
import 'themes/theme_registry.dart';
import 'themes/chess_theme.dart';
import 'themes/shadow_theme.dart';

class ChessBoard extends ConsumerStatefulWidget {
  final AlignmentGeometry alignment;

  const ChessBoard({super.key, this.alignment = Alignment.center});

  @override
  ConsumerState<ChessBoard> createState() => _ChessBoardState();
}

class _ChessBoardState extends ConsumerState<ChessBoard>
    with TickerProviderStateMixin {
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  final List<Offset> _leafScatters = [];
  final List<Offset> _toyConfetti = [];
  final List<Map<String, dynamic>> _metalShatters = [];
  final List<Map<String, dynamic>> _shadowCaptures = [];
  final List<Offset> _slateCaptures = [];

  final List<Offset> _electricBursts = [];
  final List<Offset> _liquidSplashes = [];
  final List<Offset> _inkSplashes = [];
  final List<Offset> _platinumCaptures = [];
  final List<Offset> _oilSplashes = [];
  final List<Map<String, dynamic>> _greaseTrails = [];
  final List<Map<String, dynamic>> _thunderTrails = [];

  // ── Signature Animation System ───────────────────────────────────────────
  /// Landing micro-settle entries: {square, profile, row, col}
  final List<Map<String, dynamic>> _landingFeedbacks = [];

  /// Tap ripple entries: board-local top-left Offset of the tapped square
  final List<Offset> _tapRipples = [];

  final List<Map<String, dynamic>> _knightDusts = [];
  final List<Map<String, dynamic>> _bishopWinds = [];
  final List<Map<String, dynamic>> _impactShakes = [];

  late final AnimationController _gearController;

  late final AnimationController _electricEffectController;
  late final AnimationController _liquidEffectController;
  late final AnimationController _hologramEffectController;

  @override
  void initState() {
    super.initState();
    _gearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _electricEffectController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _liquidEffectController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _hologramEffectController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _gearController.dispose();
    _electricEffectController.dispose();
    _liquidEffectController.dispose();
    _hologramEffectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);
    final chessTheme = ThemeRegistry.getTheme(chessState.boardThemeId);

    // Use currentBoardFen for display during analysis/history viewing
    final displayGame = ChessGame(fen: chessState.currentBoardFen);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = min(constraints.maxWidth, constraints.maxHeight);

        return Align(
          alignment: widget.alignment,
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: ImpactShake(
              trigger: _impactShakes.any((s) => s['square'] == 'BOARD'),
              direction:
                  _impactShakes.firstWhere(
                        (s) => s['square'] == 'BOARD',
                        orElse: () => {'dir': Offset.zero},
                      )['dir']
                      as Offset,
              intensity: 8.0,
              onComplete: () => setState(
                () => _impactShakes.removeWhere((s) => s['square'] == 'BOARD'),
              ),
              child: Container(
                clipBehavior: Clip.none,
                decoration: BoxDecoration(
                  borderRadius:
                      chessTheme.id == 'theme2' || chessTheme.id == 'theme7'
                      ? BorderRadius.circular(12)
                      : null,
                  boxShadow:
                      chessTheme.id == 'theme2' || chessTheme.id == 'theme7'
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ]
                      : [],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                      // 1. Background Effects
                      chessTheme.buildBackground(
                        context,
                        ref
                            .read(chessProvider.notifier)
                            .isAnimationTypeEnabled('themeAmbience'),
                      ),

                      if (chessState.game.inCheck)
                        chessTheme.buildCheckEffect(context),
                      if (chessState.academyHouseAnimations)
                        const AcademyPaperOverlay(),
                      GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 8,
                            ),
                        padding: EdgeInsets.zero,
                        itemCount: 64,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final row = index ~/ 8;
                          final col = index % 8;
                          final isLight = (row + col) % 2 == 0;
                          final squareName = _getSquareName(
                            row,
                            col,
                            chessState.isBoardFlipped,
                          );

                          final isSelected = _selectedSquare == squareName;
                          final isHint = _legalTargets.contains(squareName);
                          final isLastMove =
                              chessState.lastMove?.contains(squareName) ??
                              false;
                          final isSuggestedFrom =
                              chessState.isHintVisible &&
                              chessState.hintFrom == squareName;
                          final isSuggestedTo =
                              chessState.isHintVisible &&
                              chessState.hintTo == squareName;
                          final isThreatened = chessState.threatenedSquares
                              .contains(squareName);
                          final isGlow = chessState.glowingSquare == squareName;
                          final isSuggestionTarget = chessState.bardSuggestion?.to == squareName;
                          final piece = displayGame.getPiece(squareName);

                          return DragTarget<String>(
                            onWillAcceptWithDetails: (details) =>
                                _legalTargets.contains(squareName),
                            onAcceptWithDetails: (details) {
                              ref
                                  .read(chessProvider.notifier)
                                  .makeMove(details.data, squareName);
                              _clearSelection();
                            },
                            builder: (context, candidateData, rejectedData) {
                              final isDragHover = candidateData.isNotEmpty;
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 120),
                                opacity: 1.0,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _handleSquareTap(
                                    squareName: squareName,
                                    pieceExists: piece != null,
                                  ),
                                  child: AnimatedContainer(
                                    duration:
                                        ref
                                            .read(chessProvider.notifier)
                                            .isAnimationTypeEnabled('feedback')
                                        ? const Duration(milliseconds: 160)
                                        : Duration.zero,
                                    curve: Curves.easeOutCubic,
                                    decoration: BoxDecoration(
                                      color: isLight
                                          ? chessTheme.lightSquare
                                          : chessTheme.darkSquare,
                                      borderRadius:
                                          chessTheme.id == 'theme2' ||
                                              chessTheme.id == 'theme4' ||
                                              chessTheme.id == 'theme8' ||
                                              chessTheme.id == 'theme9'
                                          ? BorderRadius.circular(10)
                                          : null,
                                      border: chessTheme.getSquareBorder(
                                            isSelected,
                                            isDragHover,
                                          ) ??
                                          Border.all(
                                            color: isSelected
                                                ? (chessTheme.id == 'theme2'
                                                      ? Colors.transparent
                                                      : ScholarlyTheme
                                                            .accentGold)
                                                : isDragHover
                                                ? ScholarlyTheme
                                                      .accentBlueSoft
                                                : Colors.transparent,
                                            width: isSelected || isDragHover
                                                ? 3.0
                                                : 0.0,
                                          ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _handleSquareTap(
                                          squareName: squareName,
                                          pieceExists: piece != null,
                                        ),
                                        child: Stack(
                                          children: [
                                            // 3. Square Texture/Painter
                                            if (chessTheme.getSquarePainter(
                                                  isLight,
                                                  0,
                                                ) !=
                                                null)
                                              CustomPaint(
                                                painter: chessTheme
                                                    .getSquarePainter(
                                                      isLight,
                                                      0.0,
                                                    ),
                                                size: Size.infinite,
                                              ),
                                            // 4. Selection Effects
                                            if (isSelected)
                                              chessTheme
                                                          .buildSelectionEffect(
                                                            context,
                                                            _gearController
                                                                .value,
                                                          )
                                                          .runtimeType ==
                                                      SizedBox
                                                  ? const OrbitingStarAnimation(
                                                      color: ScholarlyTheme
                                                          .accentBlueSoft,
                                                      isActive: true,
                                                    )
                                                  : chessTheme.buildSelectionEffect(
                                                      context,
                                                      chessTheme.id == 'theme4'
                                                          ? _hologramEffectController
                                                                .value
                                                          : chessTheme.id ==
                                                                'theme5'
                                                          ? _gearController
                                                                .value
                                                          : chessTheme.id ==
                                                                'theme9'
                                                          ? _electricEffectController
                                                                .value
                                                          : _gearController
                                                                .value,
                                                    ),
                                            // 5. Move Hints
                                            if (isHint)
                                              chessTheme.buildMoveHint(
                                                context,
                                                piece != null,
                                              ),
                                            if (chessState
                                                        .engineSelectionSquare ==
                                                    squareName &&
                                                ref
                                                    .read(
                                                      chessProvider.notifier,
                                                    )
                                                    .isAnimationTypeEnabled(
                                                      'indicators',
                                                    ))
                                              const OrbitingStarAnimation(
                                                color:
                                                    ScholarlyTheme.accentGold,
                                                isActive: true,
                                              ),
                                                                                                                                      if (isThreatened && !isSuggestionTarget && !isGlow &&
                                                ref
                                                    .read(
                                                      chessProvider.notifier,
                                                    )
                                                    .isAnimationTypeEnabled(
                                                      'indicators',
                                                    ))
                                              const OrbitingStarAnimation(
                                                color: Colors.redAccent,
                                                isActive: true,
                                              ),
                                                                                         if (isGlow)
                                               const AcademySquareGlow(
                                                 color: ScholarlyTheme.accentBlue,
                                               ),
                                             // 6. Last Move Highlight
                                            if (isLastMove)
                                              TweenAnimationBuilder<double>(
                                                key: ValueKey(
                                                  'lm_${chessState.lastMove}',
                                                ),
                                                tween: Tween(
                                                  begin:
                                                      chessTheme.id == 'theme8'
                                                      ? 0.10
                                                      : 0.18,
                                                  end: 0.0,
                                                ),
                                                duration:
                                                    ref
                                                        .read(
                                                          chessProvider
                                                              .notifier,
                                                        )
                                                        .isAnimationTypeEnabled(
                                                          'indicators',
                                                        )
                                                    ? const Duration(
                                                        milliseconds: 1800,
                                                      )
                                                    : Duration.zero,
                                                curve: Curves.easeIn,
                                                builder: (context, opacity, _) {
                                                  return chessTheme
                                                      .buildLastMoveHighlight(
                                                        context,
                                                        opacity,
                                                      );
                                                },
                                              ),
                                            if (isSuggestedFrom ||
                                                isSuggestedTo)
                                              Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      (isSuggestedTo
                                                              ? ScholarlyTheme
                                                                    .accentBlueSoft
                                                              : ScholarlyTheme
                                                                    .accentGold)
                                                          .withValues(
                                                            alpha: 0.16,
                                                          ),
                                                  border: Border.all(
                                                    color:
                                                        (isSuggestedTo
                                                                ? ScholarlyTheme
                                                                      .accentBlueSoft
                                                                : ScholarlyTheme
                                                                      .accentGold)
                                                            .withValues(
                                                              alpha: 0.72,
                                                            ),
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            if (chessState.isHintBlinking &&
                                                (isSuggestedFrom ||
                                                    isSuggestedTo))
                                              const OrbitingStarAnimation(
                                                color:
                                                    ScholarlyTheme.accentYellow,
                                                isActive: true,
                                              ),
                                            ImpactShake(
                                              trigger: _impactShakes.any(
                                                (s) =>
                                                    s['square'] == squareName,
                                              ),
                                              direction:
                                                  _impactShakes.firstWhere(
                                                        (s) =>
                                                            s['square'] ==
                                                            squareName,
                                                        orElse: () => {
                                                          'dir': Offset.zero,
                                                        },
                                                      )['dir']
                                                      as Offset,
                                              onComplete: () => setState(
                                                () => _impactShakes.removeWhere(
                                                  (s) =>
                                                      s['square'] == squareName,
                                                ),
                                              ),
                                              child: ShakeAnimation(
                                                isActive:
                                                    ref
                                                        .read(
                                                          chessProvider
                                                              .notifier,
                                                        )
                                                        .isAnimationTypeEnabled(
                                                          'feedback',
                                                        ) &&
                                                    piece?.type ==
                                                        chess_lib
                                                            .PieceType
                                                            .KING &&
                                                    ((chessState.game.inCheck &&
                                                            piece?.color ==
                                                                chessState
                                                                    .game
                                                                    .turn) ||
                                                        isThreatened),
                                                child: Center(
                                                  child: AnimatedBuilder(
                                                    animation: _gearController,
                                                    builder: (context, child) {
                                                      return ChessPieceWidget(
                                                        squareName: squareName,
                                                        highlighted: isSelected,
                                                        rotation:
                                                            _gearController
                                                                .value,
                                                        isMoving:
                                                            chessState
                                                                    .moveAnimation
                                                                    ?.from ==
                                                                squareName ||
                                                            chessState
                                                                    .moveAnimation
                                                                    ?.to ==
                                                                squareName,
                                                        onTap: () =>
                                                            _handleSquareTap(
                                                              squareName:
                                                                  squareName,
                                                              pieceExists:
                                                                  piece != null,
                                                            ),
                                                        onDragStarted: () =>
                                                            _handlePieceSelection(
                                                              squareName,
                                                              displayGame,
                                                            ),
                                                        onDragEnd:
                                                            _clearSelection,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (chessState.showCoordinates)
                                              _buildCoordinates(
                                                row,
                                                col,
                                                (row + col) % 2 == 0,
                                                chessState.isBoardFlipped,
                                                chessTheme,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      if (chessState.moveAnimation != null)
                        SignatureMoveOverlay(
                          data: chessState.moveAnimation!,
                          boardSize: boardSize,
                          isFlipped: chessState.isBoardFlipped,
                          isCheckmate: chessState.game.inCheckmate,
                          onComplete: () {
                            ref
                                .read(chessProvider.notifier)
                                .clearMoveAnimation();
                          },
                          onLand: (from, to, pieceCode, profile) =>
                              _handleMoveLanding(
                                from,
                                to,
                                pieceCode,
                                profile,
                                boardSize,
                                isCritical: chessState.game.inCheckmate,
                              ),
                          onActionTrigger: (action, position) {
                            if (action == 'dust_puff' &&
                                ref
                                    .read(chessProvider.notifier)
                                    .isAnimationTypeEnabled('themeEffects')) {
                              setState(() {
                                _knightDusts.add({'pos': position});
                              });
                            }
                          },
                        ),

                      // Landing micro-settle effects
                      for (final fb in _landingFeedbacks)
                        LandingFeedback(
                          squareName: fb['square'] as String,
                          profile: fb['profile'] as PieceMotionProfile,
                          squareSize: boardSize / 8,
                          squareRow: fb['row'] as int,
                          squareCol: fb['col'] as int,
                          isFlipped: chessState.isBoardFlipped,
                          isCritical: fb['critical'] as bool? ?? false,
                          onComplete: () =>
                              setState(() => _landingFeedbacks.remove(fb)),
                        ),

                      // Tap ripple effects
                      for (final pos in _tapRipples)
                        TapRipple(
                          position: pos,
                          squareSize: boardSize / 8,
                          onComplete: () =>
                              setState(() => _tapRipples.remove(pos)),
                        ),

                      for (final dust in _knightDusts)
                        KnightDustEffect(
                          position: dust['pos'],
                          squareSize: boardSize / 8,
                          onComplete: () =>
                              setState(() => _knightDusts.remove(dust)),
                        ),

                      for (final wind in _bishopWinds)
                        BishopWindEffect(
                          from: wind['from'],
                          to: wind['to'],
                          squareSize: boardSize / 8,
                          onComplete: () =>
                              setState(() => _bishopWinds.remove(wind)),
                        ),

                      for (final pos in _leafScatters)
                        LeafScatterEffect(
                          position: pos,
                          onComplete: () =>
                              setState(() => _leafScatters.remove(pos)),
                        ),
                      for (final pos in _toyConfetti)
                        ToyConfettiSystem(
                          position: pos,
                          onComplete: () =>
                              setState(() => _toyConfetti.remove(pos)),
                        ),
                      for (final shatter in _metalShatters)
                        MetalShatterEffect(
                          position: shatter['pos'],
                          isWhite: shatter['isWhite'],
                          onComplete: () =>
                              setState(() => _metalShatters.remove(shatter)),
                        ),
                      for (final capture in _shadowCaptures)
                        ShadowCaptureEffect(
                          position: capture['pos'],
                          piece: capture['piece'],
                          onComplete: () =>
                              setState(() => _shadowCaptures.remove(capture)),
                        ),
                      for (final pos in _slateCaptures)
                        SlateCaptureEffect(
                          position: pos,
                          onComplete: () =>
                              setState(() => _slateCaptures.remove(pos)),
                        ),

                      for (final pos in _liquidSplashes)
                        LiquidSplashEffect(
                          position: pos,
                          onComplete: () =>
                              setState(() => _liquidSplashes.remove(pos)),
                        ),
                      for (final pos in _electricBursts)
                        ElectricBurstEffect(
                          position: pos,
                          onComplete: () =>
                              setState(() => _electricBursts.remove(pos)),
                        ),
                      for (final pos in _inkSplashes)
                        InkSplashEffect(
                          position: pos,
                          onComplete: () =>
                              setState(() => _inkSplashes.remove(pos)),
                        ),
                      for (final pos in _platinumCaptures)
                        PlatinumCaptureEffect(
                          position: pos,
                          onComplete: () =>
                              setState(() => _platinumCaptures.remove(pos)),
                        ),
                      for (final pos in _oilSplashes)
                        OilSplashEffect(
                          position: pos,
                          onComplete: () =>
                              setState(() => _oilSplashes.remove(pos)),
                        ),
                      for (final trail in _greaseTrails)
                        GreaseTrailOverlay(
                          from: trail['from'],
                          to: trail['to'],
                          onComplete: () =>
                              setState(() => _greaseTrails.remove(trail)),
                        ),
                      for (final trail in _thunderTrails)
                        ThunderTrailOverlay(
                          from: trail['from'],
                          to: trail['to'],
                          onComplete: () =>
                              setState(() => _thunderTrails.remove(trail)),
                        ),

                      if (chessState.bardSuggestion != null &&
                          chessState.academyHouseAnimations)
                        AcademySuggestionOverlay(
                          data: chessState.bardSuggestion!,
                          boardSize: boardSize,
                          isFlipped: chessState.isBoardFlipped,
                          trigger: chessState.academyAnimationTrigger,
                        ),

                      const PromotionOverlay(),
                    ],
                  ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleSquareTap({
    required String squareName,
    required bool pieceExists,
  }) {
    final haptics = ref.read(chessHapticsServiceProvider);
    haptics.selection();
    final chessState = ref.read(chessProvider);
    final displayGame = ChessGame(fen: chessState.currentBoardFen);

    // Tap ripple on every tap (gated by animations setting)
    if (ref.read(chessProvider.notifier).isAnimationTypeEnabled('feedback')) {
      _triggerTapRipple(squareName);
    }

    if (_selectedSquare != null && _legalTargets.contains(squareName)) {
      final targetPiece = displayGame.getPiece(squareName);
      final sourcePiece = displayGame.getPiece(_selectedSquare!);
      final isCapture =
          targetPiece != null && targetPiece.color != sourcePiece?.color;
      if (isCapture &&
          ref
              .read(chessProvider.notifier)
              .isAnimationTypeEnabled('themeEffects')) {
        final themeId = chessState.boardThemeId;
        if (themeId == 'theme2') {
          _triggerLeafScatter(squareName);
        } else if (themeId == 'theme3') {
          _triggerInkSplash(squareName);
        } else if (themeId == 'theme4') {
          _triggerPlatinumCapture(squareName);
        } else if (themeId == 'theme5') {
          _triggerOilSplash(squareName);
        } else if (themeId == 'theme8') {
          _triggerLiquidSplash(squareName);
        } else if (themeId == 'theme10') {
          final capturedPiece = displayGame.getPiece(squareName);
          if (capturedPiece != null) {
            _triggerShadowCapture(squareName, capturedPiece);
          }
        } else if (themeId == 'theme7') {
          _triggerSlateCapture(squareName);
        } else if (themeId == 'theme9') {
          _triggerToyConfetti(squareName);
        }
      }
      if (chessState.boardThemeId == 'theme5' &&
          ref
              .read(chessProvider.notifier)
              .isAnimationTypeEnabled('themeEffects')) {
        _triggerGreaseTrail(_selectedSquare!, squareName);
      }
      if (chessState.boardThemeId == 'theme10' &&
          sourcePiece?.type != chess_lib.PieceType.PAWN &&
          ref
              .read(chessProvider.notifier)
              .isAnimationTypeEnabled('themeEffects')) {
        _triggerThunderTrail(_selectedSquare!, squareName);
      }
      ref.read(chessProvider.notifier).makeMove(_selectedSquare!, squareName);
      _clearSelection();
      return;
    }

    if (pieceExists) {
      _handlePieceSelection(squareName, displayGame);
    } else {
      _clearSelection();
    }
  }

  void _handlePieceSelection(String squareName, ChessGame displayGame) {
    final chessState = ref.read(chessProvider);
    final piece = displayGame.getPiece(squareName);
    if (piece == null) {
      _clearSelection();
      return;
    }

    final notifier = ref.read(chessProvider.notifier);
    final isWhitePiece = notifier.isWhite(piece.color);

    // Check if it's the player's piece
    final isPlayerPiece = isWhitePiece
        ? chessState.isPlayerWhite
        : !chessState.isPlayerWhite;

    if (!isPlayerPiece) {
      _clearSelection();
      if (chessState.isHapticsEnabled) {
        ref.read(chessHapticsServiceProvider).errorFeedback();
      }
      return;
    }

    // Check if it's the correct turn for this piece
    final isWhiteTurn = notifier.isWhite(displayGame.turn);
    final isCurrentTurnPiece = (isWhitePiece == isWhiteTurn);

    if (!isCurrentTurnPiece) {
      _clearSelection();
      if (chessState.isHapticsEnabled) {
        ref.read(chessHapticsServiceProvider).errorFeedback();
      }
      return;
    }

    setState(() {
      _selectedSquare = squareName;
      _legalTargets = displayGame.legalDestinations(squareName);
    });
    ref.read(chessProvider.notifier).playNotify();
  }

  void _clearSelection() {
    if (!mounted) return;
    setState(() {
      _selectedSquare = null;
      _legalTargets = const [];
    });
  }

  String _getSquareName(int row, int col, bool isFlipped) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    final fileIndex = isFlipped ? 7 - col : col;
    final rankIndex = isFlipped ? 7 - row : row;
    return '${files[fileIndex]}${ranks[rankIndex]}';
  }

  Widget _buildCoordinates(
    int row,
    int col,
    bool isLight,
    bool isFlipped,
    ChessTheme chessTheme,
  ) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    final showRank = col == 0;
    final showFile = row == 7;

    if (!showRank && !showFile) return const SizedBox.shrink();

    final fileIndex = isFlipped ? 7 - col : col;
    final rankIndex = isFlipped ? 7 - row : row;

    return Stack(
      children: [
        if (showRank)
          Positioned(
            top: 2,
            left: 2,
            child: Text(
              ranks[rankIndex],
              style: TextStyle(
                color: isLight
                    ? chessTheme.lightCoordinateColor
                    : chessTheme.darkCoordinateColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (showFile)
          Positioned(
            bottom: 2,
            right: 2,
            child: Text(
              files[fileIndex],
              style: TextStyle(
                color: isLight
                    ? chessTheme.lightCoordinateColor
                    : chessTheme.darkCoordinateColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  void _triggerLeafScatter(String squareName) {
    // We can infer the size from context or wait for the next frame.
    // However, the best way is to calculate it based on the square name.
    // Since we know it's an 8x8 grid, we can use the col/row.
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(chessProvider).isBoardFlipped;

    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;

    // We'll use a hack to get the board size from the context if possible,
    // or just use a proportional offset and scale later.
    // Actually, let's just use the RenderBox.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width; // Board is square
      final squareSize = boardSize / 8;
      final x = effectiveCol * squareSize + squareSize / 2;
      final y = effectiveRow * squareSize + squareSize / 2;

      setState(() {
        _leafScatters.add(Offset(x, y));
      });
    });
  }

  void _triggerInkSplash(String squareName) {
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(chessProvider).isBoardFlipped;

    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final x = effectiveCol * squareSize + squareSize / 2;
      final y = effectiveRow * squareSize + squareSize / 2;

      setState(() {
        _inkSplashes.add(Offset(x, y));
      });
    });
  }

  void _triggerOilSplash(String squareName) {
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(chessProvider).isBoardFlipped;

    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final x = effectiveCol * squareSize + squareSize / 2;
      final y = effectiveRow * squareSize + squareSize / 2;

      setState(() {
        _oilSplashes.add(Offset(x, y));
      });
    });
  }

  void _triggerGreaseTrail(String from, String to) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final isFlipped = ref.read(chessProvider).isBoardFlipped;

      Offset getOffset(String square) {
        final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
        final row = 8 - int.parse(square[1]);
        final effectiveCol = isFlipped ? 7 - col : col;
        final effectiveRow = isFlipped ? 7 - row : row;
        return Offset(
          effectiveCol * squareSize + squareSize / 2,
          effectiveRow * squareSize + squareSize / 2,
        );
      }

      setState(() {
        _greaseTrails.add({'from': getOffset(from), 'to': getOffset(to)});
      });
    });
  }

  void _triggerThunderTrail(String from, String to) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final isFlipped = ref.read(chessProvider).isBoardFlipped;

      Offset getOffset(String square) {
        final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
        final row = 8 - int.parse(square[1]);
        final effectiveCol = isFlipped ? 7 - col : col;
        final effectiveRow = isFlipped ? 7 - row : row;
        return Offset(
          effectiveCol * squareSize + squareSize / 2,
          effectiveRow * squareSize + squareSize / 2,
        );
      }

      setState(() {
        _thunderTrails.add({'from': getOffset(from), 'to': getOffset(to)});
      });
    });
  }

  void _triggerToyConfetti(String squareName) {
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(chessProvider).isBoardFlipped;

    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final x = effectiveCol * squareSize + squareSize / 2;
      final y = effectiveRow * squareSize + squareSize / 2;

      setState(() {
        _toyConfetti.add(Offset(x, y));
      });
    });
  }

  void _triggerPlatinumCapture(String squareName) {
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(chessProvider).isBoardFlipped;

    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final x = effectiveCol * squareSize + squareSize / 2;
      final y = effectiveRow * squareSize + squareSize / 2;

      setState(() {
        _platinumCaptures.add(Offset(x, y));
      });
    });
  }

  void _triggerSlateCapture(String squareName) {
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(chessProvider).isBoardFlipped;

    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final x = effectiveCol * squareSize + squareSize / 2;
      final y = effectiveRow * squareSize + squareSize / 2;

      setState(() {
        _slateCaptures.add(Offset(x, y));
      });
    });
  }

  void _triggerShadowCapture(String squareName, chess_lib.Piece piece) {
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(chessProvider).isBoardFlipped;

    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final x = effectiveCol * squareSize + squareSize / 2;
      final y = effectiveRow * squareSize + squareSize / 2;

      setState(() {
        _shadowCaptures.add({'pos': Offset(x, y), 'piece': piece});
      });
    });
  }

  void _triggerLiquidSplash(String squareName) {
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(chessProvider).isBoardFlipped;

    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final x = effectiveCol * squareSize + squareSize / 2;
      final y = effectiveRow * squareSize + squareSize / 2;

      setState(() {
        _liquidSplashes.add(Offset(x, y));
      });
    });
  }

  // ── Signature Animation Triggers ─────────────────────────────────────────

  /// Triggers a tap ripple on the square the user tapped.
  void _triggerTapRipple(String squareName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;
      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final isFlipped = ref.read(chessProvider).isBoardFlipped;
      final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final row = 8 - int.parse(squareName[1]);
      final effectiveCol = isFlipped ? 7 - col : col;
      final effectiveRow = isFlipped ? 7 - row : row;
      final x = effectiveCol * squareSize;
      final y = effectiveRow * squareSize;
      setState(() => _tapRipples.add(Offset(x, y)));
    });
  }

  /// Orchestrates all landing and kinetic impact effects.
  void _handleMoveLanding(
    String from,
    String to,
    String pieceCode,
    PieceMotionProfile profile,
    double boardSize, {
    bool isCritical = false,
  }) {
    if (!mounted) return;

    // 1. Basic Landing Feedback (Square Pressure)
    if (ref.read(chessProvider.notifier).isAnimationTypeEnabled('feedback')) {
      _triggerLandingFeedback(to, profile, boardSize, isCritical: isCritical);
    }

    // 2. Kinetic Impact Effects
    if (ref
        .read(chessProvider.notifier)
        .isAnimationTypeEnabled('kineticImpact')) {
      final type = pieceCode.length > 1
          ? pieceCode[1].toUpperCase()
          : pieceCode.toUpperCase();

      switch (type) {
        case 'N':
          _triggerKnightDust(to, boardSize);
          break;
        case 'B':
          _triggerBishopWind(from, to, boardSize);
          break;
        case 'R':
          _triggerRookImpact(from, to, boardSize);
          break;
      }
    }
  }

  void _triggerKnightDust(String square, double boardSize) {
    final pos = _getSquareCenter(square, boardSize);
    setState(() => _knightDusts.add({'pos': pos}));
  }

  void _triggerBishopWind(String from, String to, double boardSize) {
    final fromPos = _getSquareCenter(from, boardSize);
    final toPos = _getSquareCenter(to, boardSize);
    setState(() => _bishopWinds.add({'from': fromPos, 'to': toPos}));
  }

  void _triggerRookImpact(String from, String to, double boardSize) {
    final fromCol = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRow = 8 - int.parse(from[1]);
    final toCol = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toRow = 8 - int.parse(to[1]);

    final dx = (toCol - fromCol).sign;
    final dy = (toRow - fromRow).sign;

    // Calculate "next" square
    final nextCol = toCol + dx;
    final nextRow = toRow + dy;

    if (nextCol >= 0 && nextCol < 8 && nextRow >= 0 && nextRow < 8) {
      final nextSquare = _getSquareName(
        nextRow,
        nextCol,
        ref.read(chessProvider).isBoardFlipped,
      );
      setState(() {
        _impactShakes.add({
          'square': nextSquare,
          'dir': Offset(dx.toDouble(), dy.toDouble()),
        });
      });
    } else {
      // Board Thud (shake the whole board)
      // We can use a special "board" square name or just a separate list
      setState(() {
        _impactShakes.add({
          'square': 'BOARD',
          'dir': Offset(dx.toDouble(), dy.toDouble()),
        });
      });
    }
  }

  Offset _getSquareCenter(String square, double boardSize) {
    final squareSize = boardSize / 8;
    final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(square[1]);
    final isFlipped = ref.read(chessProvider).isBoardFlipped;
    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;
    return Offset(
      effectiveCol * squareSize + squareSize / 2,
      effectiveRow * squareSize + squareSize / 2,
    );
  }

  /// Triggers a landing micro-settle on the destination square.
  void _triggerLandingFeedback(
    String square,
    PieceMotionProfile profile,
    double boardSize, {
    bool isCritical = false,
  }) {
    if (!mounted) return;
    final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(square[1]);
    setState(() {
      _landingFeedbacks.add({
        'square': square,
        'profile': profile,
        'row': row,
        'col': col,
        'critical': isCritical,
      });
    });
  }
}

class _IcePulseGlow extends StatefulWidget {
  const _IcePulseGlow();

  @override
  State<_IcePulseGlow> createState() => _IcePulseGlowState();
}

class _IcePulseGlowState extends State<_IcePulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(
                0xFFE0F2FE,
              ).withValues(alpha: 0.5 * (1.0 - _controller.value)),
              width: 8 * _controller.value,
            ),
          ),
        );
      },
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
      duration: const Duration(milliseconds: 800),
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
      builder: (context, _) => Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.white.withValues(
              alpha: 0.5 + 0.5 * _controller.value,
            ),
            width: 2.0 + 2.0 * _controller.value,
          ),
        ),
      ),
    );
  }
}

class ShadowCaptureEffect extends StatefulWidget {
  final Offset position;
  final chess_lib.Piece piece;
  final VoidCallback onComplete;

  const ShadowCaptureEffect({
    super.key,
    required this.position,
    required this.piece,
    required this.onComplete,
  });

  @override
  State<ShadowCaptureEffect> createState() => _ShadowCaptureEffectState();
}

class _ShadowCaptureEffectState extends State<ShadowCaptureEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
    final pieceType = widget.piece.type.toUpperCase();
    final isWhite = widget.piece.color == chess_lib.Color.WHITE;

    return Positioned(
      left: widget.position.dx - 30,
      top: widget.position.dy - 30,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: 1.0 - _controller.value,
            child: Transform.scale(
              scale: 1.0 - 0.5 * _controller.value,
              child: SizedBox(
                width: 60,
                height: 60,
                child: HighContrastPiece(type: pieceType, isWhite: isWhite),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AcademyPaperOverlay extends StatelessWidget {
  const AcademyPaperOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFFFDF6E3).withValues(alpha: 0.0),
              const Color(0xFFFDF6E3).withValues(alpha: 0.08),
            ],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
      ),
    );
  }
}

class AcademySuggestionOverlay extends StatefulWidget {
  final MoveAnimationData data;
  final double boardSize;
  final bool isFlipped;
  final int trigger;

  const AcademySuggestionOverlay({
    super.key,
    required this.data,
    required this.boardSize,
    required this.isFlipped,
    required this.trigger,
  });

  @override
  State<AcademySuggestionOverlay> createState() =>
      _AcademySuggestionOverlayState();
}

class _AcademySuggestionOverlayState extends State<AcademySuggestionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AcademySuggestionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger || oldWidget.data != widget.data) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final squareSize = widget.boardSize / 8;

    Offset getPos(String square) {
      final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final row = 8 - int.parse(square[1]);
      final efCol = widget.isFlipped ? 7 - col : col;
      final efRow = widget.isFlipped ? 7 - row : row;
      return Offset(efCol * squareSize, efRow * squareSize);
    }

    final fromPos = getPos(widget.data.from);
    final toPos = getPos(widget.data.to);

    return IgnorePointer(
      child: Stack(
        children: [
          // 1. Animated Scholarly Arrow
          CustomPaint(
            size: Size(widget.boardSize, widget.boardSize),
            painter: AcademyArrowPainter(
              from: fromPos + Offset(squareSize / 2, squareSize / 2),
              to: toPos + Offset(squareSize / 2, squareSize / 2),
              progress: _animation.value,
            ),
          ),

          // 2. Gliding Ghost Piece
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Quadratic Bezier path for ghost piece (matching the arrow)
              final p0 = fromPos;
              final p2 = toPos;
              final p1 = Offset(
                (p0.dx + p2.dx) / 2,
                (p0.dy + p2.dy) / 2 - 30, // Arc matching AcademyArrowPainter
              );

              final t = _animation.value;
              final currentPos = Offset(
                (1 - t) * (1 - t) * p0.dx +
                    2 * (1 - t) * t * p1.dx +
                    t * t * p2.dx,
                (1 - t) * (1 - t) * p0.dy +
                    2 * (1 - t) * t * p1.dy +
                    t * t * p2.dy,
              );

              // Fade in at start, fade out at end (to reveal stationary ghost)
              double opacity = 0.4;
              if (t < 0.2) opacity = (t / 0.2) * 0.4;
              if (t > 0.8) opacity = 0.4 - ((t - 0.8) / 0.2) * 0.4;

              return Positioned(
                left: currentPos.dx,
                top: currentPos.dy,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: squareSize,
                    height: squareSize,
                    padding: const EdgeInsets.all(4),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/pieces/${widget.data.pieceCode}.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. Final Destination Marker (Stationary Ghost)
          if (_animation.value > 0.8)
            Positioned(
              left: toPos.dx,
              top: toPos.dy,
              child: Opacity(
                opacity: (_animation.value - 0.8) / 0.2 * 0.4,
                child: Container(
                  width: squareSize,
                  height: squareSize,
                  padding: const EdgeInsets.all(4),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/pieces/${widget.data.pieceCode}.svg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AcademyArrowPainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final double progress;

  AcademyArrowPainter({
    required this.from,
    required this.to,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = ScholarlyTheme.accentBlue.withValues(alpha: 0.4)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final controlPoint = Offset(
      (from.dx + to.dx) / 2,
      (from.dy + to.dy) / 2 - 30,
    );

    final path = Path()..moveTo(from.dx, from.dy);

    // Draw the path up to the current progress
    if (progress < 1.0) {
      // Approximate quadratic bezier for animation
      for (double t = 0; t <= progress; t += 0.01) {
        final x = (1 - t) * (1 - t) * from.dx +
            2 * (1 - t) * t * controlPoint.dx +
            t * t * to.dx;
        final y = (1 - t) * (1 - t) * from.dy +
            2 * (1 - t) * t * controlPoint.dy +
            t * t * to.dy;
        path.lineTo(x, y);
      }
    } else {
      path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, to.dx, to.dy);
    }

    canvas.drawPath(path, paint);

    // Arrowhead (only show if progress > 0.8)
    if (progress > 0.8) {
      final t = progress;
      final headOpacity = (t - 0.8) / 0.2;

      final paintHead = Paint()
        ..color = ScholarlyTheme.accentBlue.withValues(alpha: 0.4 * headOpacity)
        ..style = PaintingStyle.fill;

      // Current direction at the tip of the path
      final dx = 2 * (1 - t) * (controlPoint.dx - from.dx) +
          2 * t * (to.dx - controlPoint.dx);
      final dy = 2 * (1 - t) * (controlPoint.dy - from.dy) +
          2 * t * (to.dy - controlPoint.dy);
      final angle = Offset(dx, dy).direction;

      const arrowSize = 12.0;
      final currentTo = Offset(
        (1 - t) * (1 - t) * from.dx +
            2 * (1 - t) * t * controlPoint.dx +
            t * t * to.dx,
        (1 - t) * (1 - t) * from.dy +
            2 * (1 - t) * t * controlPoint.dy +
            t * t * to.dy,
      );

      final p1 = currentTo + Offset.fromDirection(angle + 2.4, arrowSize);
      final p2 = currentTo + Offset.fromDirection(angle - 2.4, arrowSize);

      final headPath = Path()
        ..moveTo(currentTo.dx, currentTo.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..close();

      canvas.drawPath(headPath, paintHead);
    }
  }

  @override
  bool shouldRepaint(covariant AcademyArrowPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.from != from ||
      oldDelegate.to != to;
}

class AcademySquareGlow extends StatefulWidget {
  final Color color;

  const AcademySquareGlow({super.key, required this.color});

  @override
  State<AcademySquareGlow> createState() => _AcademySquareGlowState();
}

class _AcademySquareGlowState extends State<AcademySquareGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
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
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * (1.0 - _controller.value)),
                blurRadius: 20 * _controller.value,
                spreadRadius: 10 * _controller.value,
              ),
            ],
            border: Border.all(
              color: widget.color.withValues(alpha: 0.8 * (1.0 - _controller.value)),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}
