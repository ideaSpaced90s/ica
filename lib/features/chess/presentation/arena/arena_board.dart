import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/chess_provider.dart';
import '../../application/arena_provider.dart';
import '../shared/widgets/chess_piece_widget.dart';
import 'widgets/arena_system_indicators.dart';
import '../../domain/chess_game.dart';
import '../shared/widgets/promotion_overlay.dart';
import 'effects/forest_effects.dart';
import 'effects/toy_effects.dart';
import 'effects/steampunk_effects.dart';
import 'effects/electric_effects.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'effects/high_contrast_piece.dart';
import 'effects/ink_theme.dart';
import 'effects/slate_theme.dart';
import 'effects/liquid_theme.dart';
import 'effects/platinum_theme.dart';
import 'effects/grease_effects.dart';
import '../shared/animations/signature_move_overlay.dart';
import '../shared/animations/landing_feedback.dart';
import '../shared/animations/tap_ripple.dart';
import '../shared/animations/piece_motion_profile.dart';
import 'animations/knight_dust.dart';
import 'animations/bishop_wind.dart';
import 'animations/impact_shake.dart';
import '../shared/animations/shake_animation.dart';
import 'animations/landing_shockwave.dart';
import 'animations/arcade_capture_burst.dart';
import 'themes/theme_registry.dart';
import '../shared/themes/chess_theme.dart';
import 'themes/shadow_theme.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';

class ArenaChessBoard extends ConsumerStatefulWidget {
  final AlignmentGeometry alignment;

  const ArenaChessBoard({super.key, this.alignment = Alignment.center});

  @override
  ConsumerState<ArenaChessBoard> createState() => _ArenaChessBoardState();
}

class _ArenaChessBoardState extends ConsumerState<ArenaChessBoard>
    with TickerProviderStateMixin {
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  int _lastMovesCount = 0;
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
  /// Arcade landing shockwave rings: {square, row, col}
  final List<Map<String, dynamic>> _landingShockwaves = [];

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
    final arenaState = ref.watch(arenaProvider);
    final themeId = ThemeRegistry.resolveThemeId(chessState);
    final chessTheme = ThemeRegistry.getTheme(themeId);

    // If the game has been reset (no moves made), clear any lingering selection highlights/legal dots
    final recentMovesLength = arenaState.recentMoves.length;
    if (recentMovesLength == 0 && _lastMovesCount > 0) {
      _selectedSquare = null;
      _legalTargets = const [];
    }
    _lastMovesCount = recentMovesLength;

    // Use currentBoardFen for display during analysis/history viewing
    final displayGame = ChessGame(fen: arenaState.currentBoardFen);

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
                      RepaintBoundary(
                        child: chessTheme.buildBackground(
                          context,
                          ref
                              .read(chessProvider.notifier)
                              .isAnimationTypeEnabled('themeAmbience'),
                        ),
                      ),

                      if (arenaState.game.inCheck)
                        chessTheme.buildCheckEffect(context),
                      RepaintBoundary(
                        child: GridView.builder(
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
                            arenaState.isBoardFlipped,
                          );

                          final isSelected = _selectedSquare == squareName;
                          final isHint = _legalTargets.contains(squareName);
                          final isLastMoveStartOrEnd =
                               _isStartOrEndSquare(squareName, arenaState.lastMove);
                           final isLastMoveInBetween =
                                _isInBetweenSquare(squareName, arenaState.lastMove);
                          final isSuggestedFrom =
                              arenaState.isHintVisible &&
                              arenaState.hintFrom == squareName;
                          final isSuggestedTo =
                              arenaState.isHintVisible &&
                              arenaState.hintTo == squareName;
                          final isThreatened = arenaState.threatenedSquares
                              .contains(squareName);
                          final isGlow = false;
                          final isSuggestionTarget = false;
                          final piece = displayGame.getPiece(squareName);

                          return DragTarget<String>(
                            onWillAcceptWithDetails: (details) =>
                                _legalTargets.contains(squareName),
                            onAcceptWithDetails: (details) {
                              ref
                                  .read(arenaProvider.notifier)
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
                                      color: chessTheme.boardImagePath != null
                                          ? Colors.transparent
                                          : (isLight
                                              ? chessTheme.lightSquare
                                              : chessTheme.darkSquare),
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
                                            if (isSelected &&
                                                chessTheme.hasSystemIndicators &&
                                                ref
                                                    .read(
                                                      chessProvider.notifier,
                                                    )
                                                    .isAnimationTypeEnabled(
                                                      'indicators',
                                                    ))
                                              chessTheme
                                                          .buildSelectionEffect(
                                                            context,
                                                            _gearController
                                                                .value,
                                                          )
                                                          .runtimeType ==
                                                      SizedBox
                                                  ? const ArenaOrbitingStarAnimation(
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
                                            if (isThreatened &&
                                                !isSuggestionTarget &&
                                                !isGlow &&
                                                chessTheme.hasSystemIndicators &&
                                                ref
                                                    .read(
                                                      chessProvider.notifier,
                                                    )
                                                    .isAnimationTypeEnabled(
                                                      'indicators',
                                                    ))
                                              const ArenaOrbitingStarAnimation(
                                                color: Colors.redAccent,
                                                isActive: true,
                                                isCircle: true,
                                              ),
                                            // 6. Last Move Highlight (Premium Trajectory Path)
                                            if (isLastMoveStartOrEnd ||
                                                isLastMoveInBetween)
                                              TweenAnimationBuilder<double>(
                                                key: ValueKey(
                                                  'lm_${arenaState.lastMove}',
                                                ),
                                                tween: Tween(
                                                  begin: isLastMoveStartOrEnd
                                                      ? (chessTheme.id == 'theme8'
                                                          ? 0.20
                                                          : 0.35)
                                                      : (chessTheme.id == 'theme8'
                                                          ? 0.08
                                                          : 0.15),
                                                  end: isLastMoveStartOrEnd
                                                      ? (chessTheme.id == 'theme8'
                                                          ? 0.14
                                                          : 0.24)
                                                      : (chessTheme.id == 'theme8'
                                                          ? 0.05
                                                          : 0.09),
                                                ),
                                                duration: ref
                                                    .read(
                                                      chessProvider.notifier,
                                                    )
                                                    .isAnimationTypeEnabled(
                                                      'indicators',
                                                    )
                                                    ? const Duration(
                                                        milliseconds: 400,
                                                      )
                                                    : Duration.zero,
                                                curve: Curves.easeOutCubic,
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
                                                  color: (isSuggestedTo
                                                          ? ScholarlyTheme
                                                              .accentBlueSoft
                                                          : ScholarlyTheme
                                                              .accentGold)
                                                      .withValues(
                                                        alpha: 0.16,
                                                      ),
                                                  border: Border.all(
                                                    color: (isSuggestedTo
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
                                            if (arenaState.isHintBlinking &&
                                                (isSuggestedFrom ||
                                                    isSuggestedTo) &&
                                                chessTheme.hasSystemIndicators &&
                                                ref
                                                    .read(
                                                      chessProvider.notifier,
                                                    )
                                                    .isAnimationTypeEnabled(
                                                      'indicators',
                                                    ))
                                              const ArenaOrbitingStarAnimation(
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
                                                    ((arenaState.game.inCheck &&
                                                            piece?.color ==
                                                                arenaState
                                                                    .game
                                                                    .turn) ||
                                                        isThreatened),
                                                child: Center(
                                                  child: AnimatedBuilder(
                                                    animation: _gearController,
                                                    builder: (context, child) {
                                                      return ChessPieceWidget(
                                                        squareName: squareName,
                                                        game: displayGame,
                                                        highlighted: isSelected,
                                                        rotation:
                                                            _gearController
                                                                .value,
                                                        theme: chessTheme,
                                                        isMoving:
                                                            arenaState
                                                                    .moveAnimation
                                                                    ?.from ==
                                                                squareName ||
                                                            arenaState
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
                                                arenaState.isBoardFlipped,
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
                    ),
                      if (arenaState.moveAnimation != null)
                        SignatureMoveOverlay(
                          data: arenaState.moveAnimation!,
                          boardSize: boardSize,
                          isFlipped: arenaState.isBoardFlipped,
                          isCheckmate: arenaState.game.inCheckmate,
                          theme: chessTheme,
                          onComplete: () {
                            ref
                                .read(arenaProvider.notifier)
                                .clearMoveAnimation();
                          },
                          onLand: (from, to, pieceCode, profile) =>
                              _handleMoveLanding(
                                from,
                                  to,
                                  pieceCode,
                                  profile,
                                  boardSize,
                                  isCritical: arenaState.game.inCheckmate,
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
                            isFlipped: arenaState.isBoardFlipped,
                            isCritical: fb['critical'] as bool? ?? false,
                            onComplete: () =>
                                setState(() => _landingFeedbacks.remove(fb)),
                          ),
  
                        // Tap ripple effects
                        for (final pos in _tapRipples)
                          TapRipple(
                            position: pos,
                            squareSize: boardSize / 8,
                            arcadeMode: ref
                                .read(chessProvider.notifier)
                                .isAnimationTypeEnabled('arcadeMode'),
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
                        for (final shockwave in _landingShockwaves)
                          LandingShockwave(
                            squareSize: boardSize / 8,
                            squareRow: shockwave['row'] as int,
                            squareCol: shockwave['col'] as int,
                            isFlipped: arenaState.isBoardFlipped,
                            onComplete: () => setState(
                              () => _landingShockwaves.remove(shockwave),
                            ),
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
  
                        PromotionOverlay(theme: chessTheme),
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
    final displayGame = ChessGame(fen: ref.read(arenaProvider).currentBoardFen);
    final themeId = chessState.boardThemeId;
    final chessTheme = ThemeRegistry.getTheme(themeId);

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
          _triggerMetalShatter(squareName, targetPiece.color == chess_lib.Color.WHITE);
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
      // Arcade Mode: blue particle burst on any capture
      if (isCapture &&
          ref
              .read(chessProvider.notifier)
              .isAnimationTypeEnabled('arcadeMode')) {
        final themeId = chessState.boardThemeId;
        final hasThemeEffect = ref
                .read(chessProvider.notifier)
                .isAnimationTypeEnabled('themeEffects') &&
            ['theme2', 'theme3', 'theme4', 'theme5', 'theme7', 'theme8', 'theme9', 'theme10'].contains(themeId);
        if (chessTheme.hasInteractionFeedback) {
          _triggerArcadeCaptureBurst(squareName, reduced: hasThemeEffect);
        }
      }
      ref.read(arenaProvider.notifier).makeMove(_selectedSquare!, squareName);
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
    final arenaState = ref.read(arenaProvider);
    final piece = displayGame.getPiece(squareName);
    if (piece == null) {
      _clearSelection();
      return;
    }

    // Helper to determine color
    final isWhitePiece = piece.color == chess_lib.Color.WHITE;

    // Check if it's the player's piece in the Arena context
    final isPlayerPiece = isWhitePiece
        ? arenaState.isPlayerWhite
        : !arenaState.isPlayerWhite;

    if (!isPlayerPiece) {
      _clearSelection();
      if (chessState.isHapticsEnabled) {
        ref.read(chessHapticsServiceProvider).errorFeedback();
      }
      return;
    }

    // Check if it's the correct turn for this piece
    final isWhiteTurn = displayGame.turn == chess_lib.Color.WHITE;
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
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceSelect);
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
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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
        _leafScatters.add(Offset(x, y));
      });
    });
  }

  void _triggerInkSplash(String squareName) {
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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

  void _triggerMetalShatter(String squareName, bool isWhite) {
    final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(squareName[1]);
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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
        _metalShatters.add({
          'pos': Offset(x, y),
          'isWhite': isWhite,
        });
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
      final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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
      final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;

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

  void _triggerTapRipple(String squareName) {
    final themeId = ref.read(chessProvider).boardThemeId;
    final chessTheme = ThemeRegistry.getTheme(themeId);
    if (!chessTheme.hasInteractionFeedback) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;
      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final isFlipped = ref.read(arenaProvider).isBoardFlipped;
      final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final row = 8 - int.parse(squareName[1]);
      final effectiveCol = isFlipped ? 7 - col : col;
      final effectiveRow = isFlipped ? 7 - row : row;
      final x = effectiveCol * squareSize;
      final y = effectiveRow * squareSize;
      setState(() => _tapRipples.add(Offset(x, y)));
    });
  }

  void _handleMoveLanding(
    String from,
    String to,
    String pieceCode,
    PieceMotionProfile profile,
    double boardSize, {
    bool isCritical = false,
  }) {
    if (!mounted) return;
    final themeId = ref.read(chessProvider).boardThemeId;
    final chessTheme = ThemeRegistry.getTheme(themeId);

    if (chessTheme.hasInteractionFeedback &&
        ref.read(chessProvider.notifier).isAnimationTypeEnabled('feedback')) {
      _triggerLandingFeedback(to, profile, boardSize, isCritical: isCritical);
    }

    if (ref
        .read(chessProvider.notifier)
        .isAnimationTypeEnabled('arcadeMode')) {
      if (chessTheme.hasInteractionFeedback) {
        _triggerLandingShockwave(to, boardSize);
      }
    }

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

    if (ref.read(chessProvider.notifier).isAnimationTypeEnabled('themeEffects')) {
      final themeId = ref.read(chessProvider).boardThemeId;
      final type = pieceCode.length > 1
          ? pieceCode[1].toUpperCase()
          : pieceCode.toUpperCase();

      if (themeId == 'theme10' && type != 'P') {
        _triggerThunderTrail(from, to);
      } else if (themeId == 'theme5') {
        _triggerGreaseTrail(from, to);
      }
    }
  }

  bool _isStartOrEndSquare(String square, String? lastMove) {
    if (lastMove == null || lastMove.length < 4) return false;
    final from = lastMove.substring(0, 2);
    final to = lastMove.substring(2, 4);
    return square == from || square == to;
  }

  bool _isInBetweenSquare(String square, String? lastMove) {
    if (lastMove == null || lastMove.length < 4) return false;
    final from = lastMove.substring(0, 2);
    final to = lastMove.substring(2, 4);
    final inBetween = _getInBetweenSquares(from, to);
    return inBetween.contains(square);
  }

  List<String> _getInBetweenSquares(String from, String to) {
    if (from.length < 2 || to.length < 2) return const [];
    final fromCol = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRow = int.tryParse(from[1]) == null ? 0 : int.parse(from[1]) - 1;
    final toCol = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toRow = int.tryParse(to[1]) == null ? 0 : int.parse(to[1]) - 1;

    final dCol = toCol - fromCol;
    final dRow = toRow - fromRow;

    if (dCol == 0 && dRow == 0) return const [];

    final stepCol = dCol.sign;
    final stepRow = dRow.sign;

    final squares = <String>[];

    if (dCol == 0 || dRow == 0 || dCol.abs() == dRow.abs()) {
      var curCol = fromCol + stepCol;
      var curRow = fromRow + stepRow;
      while (curCol != toCol || curRow != toRow) {
        if (curCol < 0 || curCol > 7 || curRow < 0 || curRow > 7) break;
        final colChar = String.fromCharCode('a'.codeUnitAt(0) + curCol);
        final rowChar = (curRow + 1).toString();
        squares.add('$colChar$rowChar');
        curCol += stepCol;
        curRow += stepRow;
      }
    }
    return squares;
  }

  void _triggerKnightDust(String square, double boardSize) {
    final pos = _getSquareCenter(square, boardSize);
    setState(() => _knightDusts.add({'pos': pos}));
  }

  void _triggerLandingShockwave(String square, double boardSize) {
    final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(square[1]);
    setState(() => _landingShockwaves.add({'square': square, 'row': row, 'col': col}));
  }

  void _triggerArcadeCaptureBurst(String squareName, {bool reduced = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final overlay = Overlay.of(context);
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;
      final boardSize = box.size.width;
      final squareSize = boardSize / 8;
      final isFlipped = ref.read(arenaProvider).isBoardFlipped;
      final col = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final row = 8 - int.parse(squareName[1]);
      final effectiveCol = isFlipped ? 7 - col : col;
      final effectiveRow = isFlipped ? 7 - row : row;
      final localCenter = Offset(
        effectiveCol * squareSize + squareSize / 2,
        effectiveRow * squareSize + squareSize / 2,
      );
      final globalCenter = box.localToGlobal(localCenter);
      ArcadeCaptureBurst.show(
        overlay: overlay,
        globalCenter: globalCenter,
        squareSize: squareSize,
        reduced: reduced,
      );
    });
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

    final nextCol = toCol + dx;
    final nextRow = toRow + dy;

    if (nextCol >= 0 && nextCol < 8 && nextRow >= 0 && nextRow < 8) {
      final nextSquare = _getSquareName(
        nextRow,
        nextCol,
        ref.read(arenaProvider).isBoardFlipped,
      );
      setState(() {
        _impactShakes.add({
          'square': nextSquare,
          'dir': Offset(dx.toDouble(), dy.toDouble()),
        });
      });
    } else {
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
    final isFlipped = ref.read(arenaProvider).isBoardFlipped;
    final effectiveCol = isFlipped ? 7 - col : col;
    final effectiveRow = isFlipped ? 7 - row : row;
    return Offset(
      effectiveCol * squareSize + squareSize / 2,
      effectiveRow * squareSize + squareSize / 2,
    );
  }

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
