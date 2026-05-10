import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/chess_provider.dart';
import 'chess_piece_widget.dart';
import 'orbiting_star_animation.dart';
import 'scholarly_theme.dart';
import '../domain/chess_game.dart';
import '../domain/board_theme.dart' as domain;
import 'widgets/promotion_overlay.dart';
import 'widgets/forest_effects.dart';
import 'widgets/toy_effects.dart';
import 'widgets/steampunk_effects.dart';
import 'widgets/matrix_effects.dart';
import 'widgets/matrix_theme_painter.dart';
import 'widgets/electric_effects.dart';
import 'widgets/electric_theme_painter.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'widgets/high_contrast_piece.dart';
import 'widgets/ink_theme.dart';
import 'widgets/slate_theme.dart';
import 'widgets/liquid_theme.dart';
import 'widgets/walnut_theme_painter.dart';
import 'widgets/platinum_theme.dart';
import 'widgets/grease_theme.dart';
import 'widgets/grease_effects.dart';
import 'animation/signature_move_overlay.dart';
import 'animation/landing_feedback.dart';
import 'animation/tap_ripple.dart';
import 'animation/piece_motion_profile.dart';


class ChessBoard extends ConsumerStatefulWidget {
  const ChessBoard({super.key});

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
  final List<Offset> _matrixGlitches = [];
  final List<Map<String, dynamic>> _shadowCaptures = [];
  final List<Offset> _slateCaptures = [];

  final List<Offset> _electricBursts = [];
  final List<Offset> _liquidSplashes = [];
  final List<Offset> _inkSplashes = [];
  final List<Offset> _platinumCaptures = [];
  final List<Offset> _oilSplashes = [];
  final List<Map<String, dynamic>> _greaseTrails = [];

  // ── Signature Animation System ───────────────────────────────────────────
  /// Landing micro-settle entries: {square, profile, row, col}
  final List<Map<String, dynamic>> _landingFeedbacks = [];

  /// Tap ripple entries: board-local top-left Offset of the tapped square
  final List<Offset> _tapRipples = [];

  late final AnimationController _gearController;

  late final AnimationController _matrixEffectController;
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
    _matrixEffectController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
    _matrixEffectController.dispose();
    _electricEffectController.dispose();
    _liquidEffectController.dispose();
    _hologramEffectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);

    final boardTheme = domain.BoardTheme.allThemes.firstWhere(
      (t) => t.id == chessState.boardThemeId,
      orElse: () => domain.BoardTheme.allThemes.first,
    );

    // Use currentBoardFen for display during analysis/history viewing
    final displayGame = ChessGame(fen: chessState.currentBoardFen);

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = min(constraints.maxWidth, constraints.maxHeight);

        return Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Container(
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                borderRadius:
                    boardTheme.id == 'theme2' || boardTheme.id == 'theme7'
                    ? BorderRadius.circular(12)
                    : null,
                boxShadow:
                    boardTheme.id == 'theme2' || boardTheme.id == 'theme7'
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
                  if (boardTheme.id == 'theme2' &&
                      chessState.isAnimationsEnabled)
                    const ForestDustOverlay(),
                  if (boardTheme.id == 'theme3' &&
                      chessState.isAnimationsEnabled)
                    const Positioned.fill(child: InkCheckSlash()),
                  if (boardTheme.id == 'theme3' && chessState.game.inCheck)
                    const Positioned.fill(child: InkCheckSlash()),
                  if (boardTheme.id == 'theme4' &&
                      chessState.isAnimationsEnabled)
                    const FloatingBubblesOverlay(),
                  if (boardTheme.id == 'theme5' &&
                      chessState.isAnimationsEnabled)
                    const IndustrialAtmosphereOverlay(),
                  if (boardTheme.id == 'theme6' &&
                      chessState.isAnimationsEnabled)
                    const MatrixFallingCodeOverlay(),

                  if (boardTheme.id == 'theme6' &&
                      chessState.isAnimationsEnabled)
                    const ScanlineOverlay(),
                  if (boardTheme.id == 'theme4' &&
                      chessState.isAnimationsEnabled)
                    IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _hologramEffectController,
                        builder: (context, _) => CustomPaint(
                          painter: PlatinumBoardPainter(
                            isLight: true,
                            animationValue: _hologramEffectController.value,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  if (boardTheme.id == 'theme8' &&
                      chessState.isAnimationsEnabled)
                    const InsetShadowOverlay(),
                  if (boardTheme.id == 'theme9' &&
                      chessState.isAnimationsEnabled)
                    const FloatingBubblesOverlay(),
                  if (boardTheme.id == 'theme9' &&
                      chessState.isAnimationsEnabled)
                    const StaticDischargeOverlay(),
                  if (boardTheme.id == 'theme2' && chessState.game.inCheck)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.5),
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (boardTheme.id == 'theme3' && chessState.game.inCheck)
                    const Positioned.fill(child: InkCheckSlash()),
                  if (boardTheme.id == 'theme5' && chessState.game.inCheck)
                    const Positioned.fill(child: GreaseCheckPulse()),
                  if (boardTheme.id == 'theme7' && chessState.game.inCheck)
                    const Positioned.fill(child: SlateCheckBorder()),

                  if (boardTheme.id == 'theme6' && chessState.game.inCheck)
                    const Positioned.fill(child: MatrixCheckRedPulse()),
                  if (boardTheme.id == 'theme9' && chessState.game.inCheck)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(
                              0xFF00BFFF,
                            ).withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00BFFF,
                              ).withValues(alpha: 0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (boardTheme.id == 'theme3')
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: InkBoardPainter(
                            isLight: true,
                          ), // Placeholder for general grain
                          size: Size.infinite,
                        ),
                      ),
                    ),
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
                          chessState.lastMove?.contains(squareName) ?? false;
                      final isSuggestedFrom =
                          chessState.isHintVisible &&
                          chessState.hintFrom == squareName;
                      final isSuggestedTo =
                          chessState.isHintVisible &&
                          chessState.hintTo == squareName;
                      final isThreatened = chessState.threatenedSquares
                          .contains(squareName);
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
                                duration: chessState.isAnimationsEnabled
                                    ? const Duration(milliseconds: 160)
                                    : Duration.zero,
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  color: isLight
                                      ? boardTheme.lightSquare
                                      : boardTheme.darkSquare,
                                  borderRadius:
                                      boardTheme.id == 'theme2' ||
                                          boardTheme.id == 'theme4' ||
                                          boardTheme.id == 'theme8' ||
                                          boardTheme.id == 'theme9'
                                      ? BorderRadius.circular(10)
                                      : null,
                                  border: boardTheme.id == 'theme10'
                                      ? Border.all(
                                          color: const Color(0xFF2A2A2A),
                                          width: 1.0,
                                        )
                                      : Border.all(
                                          color: isSelected
                                              ? (boardTheme.id == 'theme2'
                                                    ? Colors.transparent
                                                    : ScholarlyTheme.accentGold)
                                              : isDragHover
                                              ? ScholarlyTheme.accentBlueSoft
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
                                        if (boardTheme.id == 'theme2')
                                          CustomPaint(
                                            painter: LeafTexturePainter(),
                                            size: Size.infinite,
                                          ),
                                        if (boardTheme.id == 'theme3')
                                          CustomPaint(
                                            painter: InkBoardPainter(
                                              isLight: isLight,
                                            ),
                                            size: Size.infinite,
                                          ),
                                        if (boardTheme.id == 'theme5')
                                          CustomPaint(
                                            painter: GreaseBoardPainter(
                                              isLight: isLight,
                                            ),
                                            size: Size.infinite,
                                          ),

                                        if (boardTheme.id == 'theme6' &&
                                            chessState.isAnimationsEnabled)
                                          AnimatedBuilder(
                                            animation: _matrixEffectController,
                                            builder: (context, _) =>
                                                CustomPaint(
                                                  painter: MatrixSquarePainter(
                                                    isLight: isLight,
                                                    animationValue:
                                                        _matrixEffectController
                                                            .value,
                                                  ),
                                                  size: Size.infinite,
                                                ),
                                          ),
                                        if (boardTheme.id == 'theme9' &&
                                            chessState.isAnimationsEnabled)
                                          AnimatedBuilder(
                                            animation:
                                                _electricEffectController,
                                            builder: (context, _) => CustomPaint(
                                              painter: ElectricGridPainter(
                                                isLight: isLight,
                                                animationValue:
                                                    _electricEffectController
                                                        .value,
                                              ),
                                              size: Size.infinite,
                                            ),
                                          ),
                                        if (boardTheme.id == 'theme9')
                                          const SizedBox.shrink(),

                                        if (boardTheme.id == 'theme8')
                                          CustomPaint(
                                            painter: WalnutBoardPainter(
                                              isLight: isLight,
                                              baseColor: isLight
                                                  ? boardTheme.lightSquare
                                                  : boardTheme.darkSquare,
                                            ),
                                            size: Size.infinite,
                                          ),
                                        if (isSelected)
                                          boardTheme.id == 'theme2'
                                              ? const SelectionGlowRing(
                                                  isActive: true,
                                                )
                                              : boardTheme.id == 'theme3'
                                              ? const InkRippleIndicator(
                                                  isActive: true,
                                                )
                                              : boardTheme.id == 'theme4'
                                              ? AnimatedBuilder(
                                                  animation:
                                                      _hologramEffectController,
                                                  builder: (context, _) => CustomPaint(
                                                    painter:
                                                        PlatinumSelectionPainter(
                                                          animationValue:
                                                              _hologramEffectController
                                                                  .value,
                                                          color: Colors.white,
                                                        ),
                                                    size: Size.infinite,
                                                  ),
                                                )
                                              : boardTheme.id == 'theme7'
                                              ? CustomPaint(
                                                  painter:
                                                      const SlateSelectionPainter(),
                                                  size: Size.infinite,
                                                )
                                              : boardTheme.id == 'theme5'
                                              ? AnimatedBuilder(
                                                  animation: _gearController,
                                                  builder: (context, _) =>
                                                      CustomPaint(
                                                        painter:
                                                            GreaseSelectionPainter(
                                                              animationValue:
                                                                  _gearController
                                                                      .value,
                                                            ),
                                                        size: Size.infinite,
                                                      ),
                                                )
                                              : boardTheme.id == 'theme6'
                                              ? AnimatedBuilder(
                                                  animation:
                                                      _matrixEffectController,
                                                  builder: (context, _) => CustomPaint(
                                                    painter: DigitalPulsePainter(
                                                      animationValue:
                                                          _matrixEffectController
                                                              .value,
                                                      color: const Color(
                                                        0xFF00FF88,
                                                      ),
                                                    ),
                                                    size: Size.infinite,
                                                  ),
                                                )
                                              : boardTheme.id == 'theme9'
                                              ? AnimatedBuilder(
                                                  animation:
                                                      _electricEffectController,
                                                  builder: (context, _) => CustomPaint(
                                                    painter: EnergySurgePainter(
                                                      animationValue:
                                                          _electricEffectController
                                                              .value,
                                                      color: const Color(
                                                        0xFF00BFFF,
                                                      ),
                                                    ),
                                                    size: Size.infinite,
                                                  ),
                                                )
                                              : boardTheme.id == 'theme10'
                                              ? const ShadowSelectionPulse()
                                              : const OrbitingStarAnimation(
                                                  color: ScholarlyTheme
                                                      .accentBlueSoft,
                                                  isActive: true,
                                                ),
                                        if (boardTheme.id == 'theme4')
                                          AnimatedBuilder(
                                            animation:
                                                _hologramEffectController,
                                            builder: (context, _) => CustomPaint(
                                              painter: PlatinumBoardPainter(
                                                isLight: isLight,
                                                animationValue:
                                                    _hologramEffectController
                                                        .value,
                                              ),
                                              size: Size.infinite,
                                            ),
                                          ),
                                        if (isHint)
                                          boardTheme.id == 'theme3'
                                              ? InkMoveHint(
                                                  isEnemy: piece != null,
                                                )
                                              : boardTheme.id == 'theme4'
                                              ? CustomPaint(
                                                  painter:
                                                      PlatinumMoveHintPainter(
                                                        isEnemy: piece != null,
                                                      ),
                                                  size: Size.infinite,
                                                )
                                              : boardTheme.id == 'theme5'
                                              ? OilPuddleIndicator(
                                                  isEnemy: piece != null,
                                                )
                                              : boardTheme.id == 'theme6'
                                              ? AnimatedBuilder(
                                                  animation:
                                                      _matrixEffectController,
                                                  builder: (context, _) => CustomPaint(
                                                    painter: MatrixMoveHintPainter(
                                                      animationValue:
                                                          _matrixEffectController
                                                              .value,
                                                    ),
                                                    size: Size.square(
                                                      piece == null ? 20 : 45,
                                                    ),
                                                  ),
                                                )
                                              : boardTheme.id == 'theme7'
                                              ? CustomPaint(
                                                  painter: SlateMoveHintPainter(
                                                    isEnemy: piece != null,
                                                  ),
                                                  size: Size.infinite,
                                                )
                                              : boardTheme.id == 'theme10'
                                              ? Center(
                                                  child: Container(
                                                    width: piece == null
                                                        ? 14
                                                        : 40,
                                                    height: piece == null
                                                        ? 14
                                                        : 40,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: piece == null
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.45,
                                                                )
                                                          : Colors.transparent,
                                                      border: piece != null
                                                          ? Border.all(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                    alpha: 0.8,
                                                                  ),
                                                              width: 2.5,
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                )
                                              : boardTheme.id == 'theme8'
                                              ? Center(
                                                  child: Container(
                                                    width: piece == null
                                                        ? 10
                                                        : 35,
                                                    height: piece == null
                                                        ? 10
                                                        : 35,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: piece == null
                                                          ? Colors.black
                                                                .withValues(
                                                                  alpha: 0.3,
                                                                )
                                                          : Colors.transparent,
                                                      border: piece != null
                                                          ? Border.all(
                                                              color: Colors
                                                                  .black
                                                                  .withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                              width: 2.0,
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                )
                                              : Center(
                                                  child: Container(
                                                    width: piece == null
                                                        ? 12
                                                        : 38,
                                                    height: piece == null
                                                        ? 12
                                                        : 38,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: piece == null
                                                          ? ScholarlyTheme
                                                                .accentBlueSoft
                                                                .withValues(
                                                                  alpha: 0.75,
                                                                )
                                                          : Colors.transparent,
                                                      border: piece != null
                                                          ? Border.all(
                                                              color: ScholarlyTheme
                                                                  .accentBlueSoft,
                                                              width: 2.8,
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                        if (chessState.engineSelectionSquare ==
                                                squareName &&
                                            chessState.isAnimationsEnabled)
                                          const OrbitingStarAnimation(
                                            color: ScholarlyTheme.accentGold,
                                            isActive: true,
                                          ),
                                        if (isThreatened &&
                                            chessState.isAnimationsEnabled)
                                          const OrbitingStarAnimation(
                                            color: Colors.redAccent,
                                            isActive: true,
                                          ),
                                        if (isLastMove)
                                          // Fade-out last-move highlight.
                                          // TweenAnimationBuilder goes FROM full
                                          // opacity TO 0.0 over 1.8s.
                                          // ValueKey resets tween on each new move.
                                          TweenAnimationBuilder<double>(
                                            key: ValueKey(
                                              'lm_${chessState.lastMove}',
                                            ),
                                            tween: Tween(
                                              begin: boardTheme.id == 'theme8'
                                                  ? 0.10
                                                  : 0.18,
                                              end: 0.0,
                                            ),
                                            duration:
                                                chessState.isAnimationsEnabled
                                                ? const Duration(
                                                    milliseconds: 1800,
                                                  )
                                                : Duration.zero,
                                            curve: Curves.easeIn,
                                            builder: (context, opacity, _) {
                                              return Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      boardTheme.id == 'theme8'
                                                      ? Colors.white.withValues(
                                                          alpha: opacity,
                                                        )
                                                      : ScholarlyTheme
                                                            .accentGold
                                                            .withValues(
                                                              alpha: opacity,
                                                            ),
                                                ),
                                              );
                                            },
                                          ),
                                        if (isSuggestedFrom || isSuggestedTo)
                                          Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  (isSuggestedTo
                                                          ? ScholarlyTheme
                                                                .accentBlueSoft
                                                          : ScholarlyTheme
                                                                .accentGold)
                                                      .withValues(alpha: 0.16),
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
                                        ShakeAnimation(
                                          isActive:
                                              chessState.isAnimationsEnabled &&
                                              (boardTheme.id == 'theme4' ||
                                                  boardTheme.id == 'theme9') &&
                                              chessState.game.inCheck &&
                                              piece?.type ==
                                                  chess_lib.PieceType.KING &&
                                              piece?.color ==
                                                  chessState.game.turn,
                                          child: Center(
                                            child: AnimatedBuilder(
                                              animation: _gearController,
                                              builder: (context, child) {
                                                return ChessPieceWidget(
                                                  squareName: squareName,
                                                  highlighted: isSelected,
                                                  rotation:
                                                      _gearController.value,
                                                  isMoving:
                                                      chessState
                                                              .moveAnimation
                                                              ?.from ==
                                                          squareName ||
                                                      chessState
                                                              .moveAnimation
                                                              ?.to ==
                                                          squareName,
                                                  onTap: () => _handleSquareTap(
                                                    squareName: squareName,
                                                    pieceExists: piece != null,
                                                  ),
                                                  onDragStarted: () =>
                                                      _handlePieceSelection(
                                                        squareName,
                                                        displayGame,
                                                      ),
                                                  onDragEnd: _clearSelection,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        if (chessState.showCoordinates)
                                          _buildCoordinates(
                                            row,
                                            col,
                                            (row + col) % 2 == 0,
                                            chessState.isBoardFlipped,
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
                      onComplete: () {
                        ref.read(chessProvider.notifier).clearMoveAnimation();
                      },
                      onLand: chessState.isAnimationsEnabled
                          ? (square, profile) => _triggerLandingFeedback(
                              square,
                              profile,
                              boardSize,
                            )
                          : null,
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
                      onComplete: () =>
                          setState(() => _landingFeedbacks.remove(fb)),
                    ),

                  // Tap ripple effects
                  for (final pos in _tapRipples)
                    TapRipple(
                      position: pos,
                      squareSize: boardSize / 8,
                      onComplete: () => setState(() => _tapRipples.remove(pos)),
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
                  for (final pos in _matrixGlitches)
                    MatrixGlitchCapture(
                      position: pos,
                      onComplete: () =>
                          setState(() => _matrixGlitches.remove(pos)),
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

                  const PromotionOverlay(),
                ],
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
    HapticFeedback.lightImpact();
    final chessState = ref.read(chessProvider);
    final displayGame = ChessGame(fen: chessState.currentBoardFen);

    // Tap ripple on every tap (gated by animations setting)
    if (chessState.isAnimationsEnabled) {
      _triggerTapRipple(squareName);
    }

    if (_selectedSquare != null && _legalTargets.contains(squareName)) {
      final isCapture = displayGame.getPiece(squareName) != null;
      if (isCapture && chessState.isAnimationsEnabled) {
        if (ref.read(chessProvider).boardThemeId == 'theme2') {
          _triggerLeafScatter(squareName);
        } else if (ref.read(chessProvider).boardThemeId == 'theme3') {
          _triggerInkSplash(squareName);
        } else if (ref.read(chessProvider).boardThemeId == 'theme4') {
          _triggerPlatinumCapture(squareName);
        } else if (ref.read(chessProvider).boardThemeId == 'theme5') {
          _triggerOilSplash(squareName);
        } else if (ref.read(chessProvider).boardThemeId == 'theme6') {
          _triggerMatrixGlitch(squareName);
        } else if (ref.read(chessProvider).boardThemeId == 'theme8') {
          _triggerLiquidSplash(squareName);
        } else if (ref.read(chessProvider).boardThemeId == 'theme10') {
          final capturedPiece = displayGame.getPiece(squareName);
          if (capturedPiece != null) {
            _triggerShadowCapture(squareName, capturedPiece);
          }
        } else if (ref.read(chessProvider).boardThemeId == 'theme7') {
          _triggerSlateCapture(squareName);
        } else if (ref.read(chessProvider).boardThemeId == 'theme9') {
          _triggerToyConfetti(squareName);
        }
      }
      if (ref.read(chessProvider).boardThemeId == 'theme5' &&
          ref.read(chessProvider).isAnimationsEnabled) {
        _triggerGreaseTrail(_selectedSquare!, squareName);
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
      return;
    }

    // Check if it's the correct turn for this piece
    final isWhiteTurn = notifier.isWhite(displayGame.turn);
    final isCurrentTurnPiece = (isWhitePiece == isWhiteTurn);

    if (!isCurrentTurnPiece) {
      _clearSelection();
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

  Widget _buildCoordinates(int row, int col, bool isLight, bool isFlipped) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    final showRank = isFlipped ? col == 7 : col == 0;
    final showFile = isFlipped ? row == 0 : row == 7;

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
                color:
                    (isLight
                            ? ScholarlyTheme.darkSquare
                            : ScholarlyTheme.lightSquare)
                        .withValues(alpha: 0.6),
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
                color:
                    (isLight
                            ? ScholarlyTheme.darkSquare
                            : ScholarlyTheme.lightSquare)
                        .withValues(alpha: 0.6),
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

  void _triggerMatrixGlitch(String squareName) {
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
        _matrixGlitches.add(Offset(x, y));
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

  /// Triggers a landing micro-settle on the destination square.
  void _triggerLandingFeedback(
    String square,
    PieceMotionProfile profile,
    double boardSize,
  ) {
    if (!mounted) return;
    final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(square[1]);
    setState(() {
      _landingFeedbacks.add({
        'square': square,
        'profile': profile,
        'row': row,
        'col': col,
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
