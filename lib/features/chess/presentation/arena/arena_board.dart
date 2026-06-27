import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/chess_provider.dart';
import '../../application/arena_provider.dart';
import '../shared/widgets/chess_piece_widget.dart';
import 'widgets/arena_system_indicators.dart';
import 'widgets/arena_hint_overlay.dart';
import '../../domain/chess_game.dart';
import '../shared/widgets/promotion_overlay.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../shared/animations/signature_move_overlay.dart';
import '../shared/animations/landing_feedback.dart';
import '../shared/animations/tap_ripple.dart';
import '../shared/animations/piece_motion_profile.dart';
import '../shared/animations/shake_animation.dart';
import 'themes/theme_registry.dart';
import '../shared/themes/chess_theme.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import '../analysis/widgets/move_annotation_badge.dart';
import '../../application/study_lab_provider.dart' show MoveAnnotation;
import '../../application/analysis_engine_controller.dart' show MoveClassification;

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
  String? _dropSquare;
  late AnimationController _dropController;

  // Tier 2 theme-specific capture effects
  final List<Map<String, dynamic>> _captureEffects = [];

  // Tier 1 global landing feedback
  final List<Map<String, dynamic>> _landingFeedbacks = [];

  // Tier 1 global tap ripples
  final List<Offset> _tapRipples = [];

  double? _moveProgress;
  Offset? _movingPiecePos;

  late AnimationController _cameraShakeController;
  late AnimationController _focalZoomController;
  String _shakeType = 'capture';
  Offset _zoomCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    _dropController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _dropController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _dropSquare = null;
        });
      }
    });
    _cameraShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _focalZoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _dropController.dispose();
    _cameraShakeController.dispose();
    _focalZoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);
    final arenaState = ref.watch(arenaProvider);
    final themeId = ThemeRegistry.resolveThemeId(chessState);
    final chessTheme = ThemeRegistry.getTheme(themeId);

    // If the game has been reset, clear selections
    final recentMovesLength = arenaState.recentMoves.length;
    if (recentMovesLength == 0 && _lastMovesCount > 0) {
      _selectedSquare = null;
      _legalTargets = const [];
    }
    _lastMovesCount = recentMovesLength;

    final displayGame = ChessGame(fen: arenaState.currentBoardFen);
    final masterAnimationsEnabled = ref.watch(chessProvider.notifier).masterAnimationsEnabled;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = min(constraints.maxWidth, constraints.maxHeight);

        return Align(
          alignment: widget.alignment,
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: Listenable.merge([_cameraShakeController, _focalZoomController]),
                  builder: (context, child) {
                    final shakeVal = _cameraShakeController.value;
                    final zoomVal = _focalZoomController.value;

                    double dx = 0.0;
                    double dy = 0.0;
                    final t = 1.0 - shakeVal;

                    if (shakeVal > 0.0) {
                      if (_shakeType == 'capture') {
                        dx = sin(shakeVal * 12 * pi) * 6.0 * t;
                        dy = cos(shakeVal * 10 * pi) * 6.0 * t;
                      } else if (_shakeType == 'rook') {
                        dx = sin(shakeVal * 8 * pi) * 8.0 * t;
                        dy = cos(shakeVal * 6 * pi) * 8.0 * t;
                      } else if (_shakeType == 'king') {
                        dx = sin(shakeVal * 6 * pi) * 4.0 * t;
                        dy = cos(shakeVal * 4 * pi) * 8.0 * t;
                      }
                    }

                    final scale = 1.0 + 0.04 * sin(zoomVal * pi);
                    final focusCenter = _zoomCenter == Offset.zero 
                        ? Offset(boardSize / 2, boardSize / 2) 
                        : _zoomCenter;

                    final matrix = Matrix4.translationValues(dx, dy, 0.0) *
                        Matrix4.translationValues(focusCenter.dx, focusCenter.dy, 0.0) *
                        Matrix4.diagonal3Values(scale, scale, 1.0) *
                        Matrix4.translationValues(-focusCenter.dx, -focusCenter.dy, 0.0);

                    return Transform(
                      transform: matrix,
                      alignment: Alignment.center,
                      child: child,
                    );
                  },
                  child: Container(
                    clipBehavior: Clip.none,
                    decoration: chessTheme.id == 'theme2'
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          )
                        : null,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                  // 1. Board Background
                  RepaintBoundary(
                    child: chessTheme.buildBackground(
                      context,
                      masterAnimationsEnabled,
                    ),
                  ),

                  // 2. Ambient Overlay (Tier 2/3, gated by toggle)
                  if (masterAnimationsEnabled)
                    RepaintBoundary(
                      child: chessTheme.buildAmbientOverlay(context) ??
                          const SizedBox.shrink(),
                    ),

                  // 3. Check Effect (Always active when in check)
                  if (arenaState.game.inCheck)
                    chessTheme.buildCheckEffect(context),

                  // 4. Board Grid squares
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
                        final isSuggestedFrom = arenaState.isHintVisible &&
                            arenaState.hintFrom == squareName;
                        final isSuggestedTo = arenaState.isHintVisible &&
                            arenaState.hintTo == squareName;
                        final isThreatened =
                            arenaState.threatenedSquares.contains(squareName);
                        final isDominating =
                            arenaState.dominatingSquares.contains(squareName);
                        final isPremoveStartOrEnd =
                            arenaState.premoveFrom == squareName ||
                            arenaState.premoveTo == squareName;

                        final activeMoveIndex = arenaState.viewingMoveIndex ?? (arenaState.recentMoves.length - 1);
                        final hasReview = arenaState.reviewClassifications != null;
                        final isDestSquare = hasReview &&
                            activeMoveIndex >= 0 &&
                            activeMoveIndex < arenaState.recentMovesUci.length &&
                            arenaState.recentMovesUci[activeMoveIndex].substring(2, 4) == squareName;
                        final classification = isDestSquare
                            ? arenaState.reviewClassifications![activeMoveIndex]
                            : null;

                        chess_lib.Piece? piece;
                        bool isGhostPiece = false;
                        if (arenaState.premoveFrom != null && arenaState.premoveTo != null) {
                          if (squareName == arenaState.premoveFrom) {
                            piece = null;
                          } else if (squareName == arenaState.premoveTo) {
                            piece = displayGame.getPiece(arenaState.premoveFrom!);
                            isGhostPiece = true;
                          } else {
                            piece = displayGame.getPiece(squareName);
                          }
                        } else {
                          piece = displayGame.getPiece(squareName);
                        }

                        return DragTarget<String>(
                          onWillAcceptWithDetails: (details) {
                            return _legalTargets.contains(squareName);
                          },
                          onAcceptWithDetails: (details) {
                            ref
                                .read(arenaProvider.notifier)
                                .makeMove(details.data, squareName);
                            setState(() {
                              _dropSquare = squareName;
                            });
                            _dropController.forward(from: 0);
                            _clearSelection();
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isDragHover = candidateData.isNotEmpty;
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _handleSquareTap(
                                squareName: squareName,
                                pieceExists: piece != null,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                curve: Curves.easeOutCubic,
                                decoration: BoxDecoration(
                                  color: chessTheme.boardImagePath != null
                                      ? Colors.transparent
                                      : (isLight
                                          ? chessTheme.lightSquare
                                          : chessTheme.darkSquare),
                                  borderRadius: chessTheme.id == 'theme2' ||
                                          chessTheme.id == 'theme4'
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
                                                : ScholarlyTheme.accentGold)
                                            : isDragHover
                                                ? ScholarlyTheme.accentBlueSoft
                                                : Colors.transparent,
                                        width: isSelected || isDragHover ? 3.0 : 0.0,
                                      ),
                                ),
                                child: Stack(
                                  children: [
                                    // Square Custom Painter
                                    if (chessTheme.getSquarePainter(isLight, 0) !=
                                        null)
                                      CustomPaint(
                                        painter: chessTheme.getSquarePainter(
                                          isLight,
                                          0.0,
                                        ),
                                        size: Size.infinite,
                                      ),

                                    // Selection Ring
                                    if (isSelected)
                                      chessTheme.buildSelectionRing(context),

                                    // Move Hints (dots)
                                    if (isHint)
                                      chessTheme.buildMoveHint(
                                        context,
                                        piece != null,
                                      ),

                                    // Last Move Highlight
                                    if (isLastMoveStartOrEnd || isLastMoveInBetween)
                                      TweenAnimationBuilder<double>(
                                        key: ValueKey('lm_${arenaState.lastMove}'),
                                        tween: Tween(
                                          begin: isLastMoveStartOrEnd ? 0.35 : 0.15,
                                          end: isLastMoveStartOrEnd ? 0.24 : 0.09,
                                        ),
                                        duration: const Duration(milliseconds: 400),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, opacity, _) {
                                          return chessTheme.buildLastMoveHighlight(
                                            context,
                                            opacity,
                                          );
                                        },
                                      ),

                                    // GM Counselor Suggestion Highlights
                                    if (isSuggestedFrom || isSuggestedTo)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: (isSuggestedTo
                                                  ? ScholarlyTheme.accentBlueSoft
                                                  : ScholarlyTheme.accentGold)
                                              .withValues(alpha: 0.16),
                                          border: Border.all(
                                            color: (isSuggestedTo
                                                    ? ScholarlyTheme.accentBlueSoft
                                                    : ScholarlyTheme.accentGold)
                                                .withValues(alpha: 0.72),
                                            width: 2,
                                          ),
                                        ),
                                      ),

                                    if (arenaState.isHintBlinking &&
                                        (isSuggestedFrom || isSuggestedTo))
                                      const ArenaOrbitingStarAnimation(
                                        color: ScholarlyTheme.accentYellow,
                                        isActive: true,
                                      ),

                                    if (isPremoveStartOrEnd)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withValues(alpha: 0.25),
                                          border: Border.all(
                                            color: Colors.redAccent,
                                            width: 2.0,
                                          ),
                                        ),
                                      ),

                                    // King Check Shake / Threatened Jitter
                                    // Wrapped in ArenaPieceEffectsWrapper for 3D orbit animations
                                    ArenaPieceEffectsWrapper(
                                      isThreatened: isThreatened && piece != null,
                                      isDominating: isDominating && piece != null,
                                      child: ShakeAnimation(
                                        isActive: piece?.type ==
                                                chess_lib.PieceType.KING &&
                                            ((arenaState.game.inCheck &&
                                                    piece?.color ==
                                                        arenaState.game.turn) ||
                                                isThreatened),
                                        child: Center(
                                          child: Builder(
                                            builder: (context) {
                                              final localPiece = piece;
                                              final pieceExists = localPiece != null;
                                              final isPlayerPiece = localPiece != null && !isGhostPiece &&
                                                  ((localPiece.color == chess_lib.Color.WHITE) == arenaState.isPlayerWhite);

                                              Widget pieceWidget = ChessPieceWidget(
                                                squareName: isGhostPiece ? arenaState.premoveFrom! : squareName,
                                                pieceCode: isGhostPiece && localPiece != null
                                                    ? '${localPiece.color == chess_lib.Color.WHITE ? 'w' : 'b'}${localPiece.type.toUpperCase()}'
                                                    : null,
                                                game: displayGame,
                                                highlighted: isSelected,
                                                theme: chessTheme,
                                                isMoving: arenaState.moveAnimation?.from == squareName ||
                                                    arenaState.moveAnimation?.to == squareName,
                                                onTap: () => _handleSquareTap(
                                                  squareName: squareName,
                                                  pieceExists: pieceExists,
                                                ),
                                              );

                                              if (isGhostPiece) {
                                                pieceWidget = Opacity(
                                                  opacity: 0.5,
                                                  child: pieceWidget,
                                                );
                                              }

                                              if (squareName == _dropSquare) {
                                                pieceWidget = AnimatedBuilder(
                                                  animation: _dropController,
                                                  builder: (context, child) {
                                                    double scale = 0.85 + 0.15 * Curves.elasticOut.transform(_dropController.value);
                                                    return Transform.scale(scale: scale, child: child);
                                                  },
                                                  child: pieceWidget,
                                                );
                                              }

                                              final offset = _calculatePieceInteractiveOffset(
                                                squareName: squareName,
                                                boardSize: boardSize,
                                                themeId: themeId,
                                                masterAnimationsEnabled: masterAnimationsEnabled,
                                                arenaState: arenaState,
                                              );

                                              Widget finalPieceWidget;
                                              if (isPlayerPiece) {
                                                final squareSize = boardSize / 8;
                                                finalPieceWidget = Draggable<String>(
                                                  data: squareName,
                                                  onDragStarted: () {
                                                    _handlePieceSelection(squareName, displayGame);
                                                  },
                                                  onDraggableCanceled: (velocity, offset) {
                                                    _clearSelection();
                                                  },
                                                  onDragEnd: (details) {
                                                    _clearSelection();
                                                  },
                                                  feedback: Material(
                                                    color: Colors.transparent,
                                                    child: SizedBox(
                                                      width: squareSize * 1.2,
                                                      height: squareSize * 1.2,
                                                      child: themeId == 'sprite_arc'
                                                          ? DragTiltWidget(
                                                              child: ChessPieceWidget(
                                                                squareName: squareName,
                                                                game: displayGame,
                                                                highlighted: false,
                                                                theme: chessTheme,
                                                                isMoving: false,
                                                              ),
                                                            )
                                                          : ChessPieceWidget(
                                                              squareName: squareName,
                                                              game: displayGame,
                                                              highlighted: false,
                                                              theme: chessTheme,
                                                              isMoving: false,
                                                            ),
                                                    ),
                                                  ),
                                                  childWhenDragging: Opacity(
                                                    opacity: 0.35,
                                                    child: ChessPieceWidget(
                                                      squareName: squareName,
                                                      game: displayGame,
                                                      highlighted: false,
                                                      theme: chessTheme,
                                                      isMoving: false,
                                                    ),
                                                  ),
                                                  child: pieceWidget,
                                                );
                                              } else {
                                                finalPieceWidget = pieceWidget;
                                              }

                                              if (offset != Offset.zero) {
                                                return Transform.translate(
                                                  offset: offset,
                                                  child: finalPieceWidget,
                                                );
                                              }
                                              return finalPieceWidget;
                                            },
                                          ),
                                        ),
                                      ),
                                    ),

                                    if (chessState.showCoordinates)
                                      _buildCoordinates(
                                        row,
                                        col,
                                        isLight,
                                        arenaState.isBoardFlipped,
                                        chessTheme,
                                      ),

                                    if (isDestSquare && classification != null && classification != MoveClassification.none)
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: MoveAnnotationBadge(
                                          annotation: _mapClassificationToAnnotation(classification),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 5. Signature Move Overlays
                  if (arenaState.moveAnimation != null)
                    SignatureMoveOverlay(
                      data: arenaState.moveAnimation!,
                      boardSize: boardSize,
                      isFlipped: arenaState.isBoardFlipped,
                      isCheckmate: arenaState.game.inCheckmate,
                      theme: chessTheme,
                      onProgressUpdate: (progress, piecePos) {
                        setState(() {
                          _moveProgress = progress;
                          _movingPiecePos = piecePos;
                        });
                      },
                      onComplete: () {
                        setState(() {
                          _moveProgress = null;
                          _movingPiecePos = null;
                        });
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
                        isCritical: arenaState.game.inCheckmate ||
                            (pieceCode.substring(1).toUpperCase() == 'K' &&
                                themeId == 'sprite_arc'),
                      ),
                    ),

                  // 5.1 Hint Overlay (glowing path and tile animation)
                  if (arenaState.isHintVisible &&
                      arenaState.hintFrom != null &&
                      arenaState.hintTo != null)
                    Positioned.fill(
                      child: ArenaHintOverlay(
                        from: arenaState.hintFrom!,
                        to: arenaState.hintTo!,
                        boardSize: boardSize,
                        isFlipped: arenaState.isBoardFlipped,
                      ),
                    ),

                  // 6. Landing Feedback Micro-settles (Tier 1)
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

                  // 7. Tap Ripples (Tier 1)
                  for (final pos in _tapRipples)
                    TapRipple(
                      position: pos,
                      squareSize: boardSize / 8,
                      arcadeMode: false,
                      onComplete: () =>
                          setState(() => _tapRipples.remove(pos)),
                    ),

                  // 8. Capture Particles (Tier 2/3, gated by toggle)
                  for (final effect in _captureEffects)
                    effect['widget'] as Widget,

                  // 9. Pawn Promotion Overlay
                  PromotionOverlay(
                    theme: chessTheme,
                    isPromotingOverride: arenaState.isPromoting,
                    isWhiteOverride: arenaState.game.turn == chess_lib.Color.WHITE,
                    onCompleteOverride: (piece) => ref.read(arenaProvider.notifier).completePromotion(piece),
                    onCancelOverride: () => ref.read(arenaProvider.notifier).cancelPromotion(),
                  ),
                      ],
                    ),
                  ),
                ),
                if (themeId == 'sprite_arc')
                  IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _focalZoomController,
                      builder: (context, child) {
                        final zoomVal = _focalZoomController.value;
                        final vignetteOpacity = (sin(zoomVal * pi) * 0.45).clamp(0.0, 1.0);
                        final focusCenter = _zoomCenter == Offset.zero 
                            ? Offset(boardSize / 2, boardSize / 2) 
                            : _zoomCenter;

                        return Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment(
                                ((focusCenter.dx / boardSize) * 2.0) - 1.0,
                                ((focusCenter.dy / boardSize) * 2.0) - 1.0,
                              ),
                              radius: 0.7,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: vignetteOpacity),
                              ],
                              stops: const [0.35, 1.0],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<String> _getLegalTargetsForSquare(String squareName, ChessGame game, ArenaState arenaState) {
    final isWhiteTurn = game.turn == chess_lib.Color.WHITE;
    final isPlayerTurn = arenaState.isPlayerWhite == isWhiteTurn;
    if (isPlayerTurn) {
      return game.legalDestinations(squareName);
    } else {
      try {
        final fenParts = game.fen.split(' ');
        if (fenParts.length > 1) {
          fenParts[1] = arenaState.isPlayerWhite ? 'w' : 'b';
          final tempGame = ChessGame(fen: fenParts.join(' '));
          return tempGame.legalDestinations(squareName);
        }
      } catch (_) {}
      return const [];
    }
  }

  bool _isPlayerTurn(ArenaState arenaState) {
    final fenParts = arenaState.currentBoardFen.split(' ');
    if (fenParts.length > 1) {
      final turnWhite = fenParts[1] == 'w';
      return arenaState.isPlayerWhite == turnWhite;
    }
    return true;
  }

  void _handleSquareTap({
    required String squareName,
    required bool pieceExists,
  }) {
    final haptics = ref.read(chessHapticsServiceProvider);
    haptics.selection();

    // Tap ripple on every tap
    if (ref.read(chessProvider).isAnimationsEnabled) {
      _triggerTapRipple(squareName);
    }

    if (_selectedSquare != null && _legalTargets.contains(squareName)) {
      ref.read(arenaProvider.notifier).makeMove(_selectedSquare!, squareName);
      _clearSelection();
      return;
    }

    if (pieceExists) {
      _handlePieceSelection(squareName, ChessGame(fen: ref.read(arenaProvider).currentBoardFen));
    } else {
      _clearSelection();
      ref.read(arenaProvider.notifier).clearPremove();
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

    final isGameOver = arenaState.game.gameOver;
    if (isGameOver) {
      _clearSelection();
      return;
    }

    if (_selectedSquare == squareName) {
      _clearSelection();
      if (!_isPlayerTurn(arenaState)) {
        ref.read(arenaProvider.notifier).clearPremove();
      }
      return;
    }

    final isWhitePiece = piece.color == chess_lib.Color.WHITE;
    final isWhiteTurn = displayGame.turn == chess_lib.Color.WHITE;
    final isPlayerTurn = arenaState.isPlayerWhite == isWhiteTurn;

    if (isPlayerTurn) {
      final isCurrentTurnPiece = (isWhitePiece == isWhiteTurn);
      if (!isCurrentTurnPiece) {
        _clearSelection();
        if (chessState.isHapticsEnabled) {
          ref.read(chessHapticsServiceProvider).errorFeedback();
        }
        return;
      }
    } else {
      final isPlayerPiece = (piece.color == chess_lib.Color.WHITE) == arenaState.isPlayerWhite;
      if (!isPlayerPiece) {
        _clearSelection();
        ref.read(arenaProvider.notifier).clearPremove();
        if (chessState.isHapticsEnabled) {
          ref.read(chessHapticsServiceProvider).errorFeedback();
        }
        return;
      }
      // Clear current pre-move when starting a new selection during opponent's turn
      ref.read(arenaProvider.notifier).clearPremove();
    }

    setState(() {
      _selectedSquare = squareName;
      _legalTargets = _getLegalTargetsForSquare(squareName, displayGame, arenaState);
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

  Offset _calculatePieceInteractiveOffset({
    required String squareName,
    required double boardSize,
    required String themeId,
    required bool masterAnimationsEnabled,
    required ArenaState arenaState,
  }) {
    if (!masterAnimationsEnabled || themeId != 'sprite_arc') return Offset.zero;
    final moveAnim = arenaState.moveAnimation;
    if (moveAnim == null || _movingPiecePos == null || _moveProgress == null) return Offset.zero;

    final pieceType = moveAnim.pieceCode.substring(1).toUpperCase();
    final squareSize = boardSize / 8;
    final sCenter = _getSquareCenter(squareName, boardSize);

    // 1. Knight piece-bump effect (adjacent pushing)
    if (pieceType == 'N') {
      final vec = sCenter - _movingPiecePos!;
      final dist = vec.distance;
      final threshold = squareSize * 1.5;
      if (dist > 0.1 && dist < threshold) {
        final dir = vec / dist;
        final factor = 1.0 - (dist / threshold);
        // Sinusoidal bump factor based on progress
        final strength = sin(_moveProgress! * pi);
        final bump = factor * factor * 14.0 * strength;
        return dir * bump;
      }
    }

    // 2. Rook downstream momentum shake
    // If the Rook lands, the tile behind point B shakes
    if (pieceType == 'R' && _moveProgress! > 0.85) {
      final fromCol = moveAnim.from.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final fromRow = 8 - int.parse(moveAnim.from[1]);
      final toCol = moveAnim.to.codeUnitAt(0) - 'a'.codeUnitAt(0);
      final toRow = 8 - int.parse(moveAnim.to[1]);
      
      final dc = toCol - fromCol;
      final dr = toRow - fromRow;
      if (dc != 0 || dr != 0) {
        final stepCol = dc.sign;
        final stepRow = dr.sign;
        
        final pastCol = toCol + stepCol;
        final pastRow = toRow + stepRow;
        
        if (pastCol >= 0 && pastCol < 8 && pastRow >= 0 && pastRow < 8) {
          final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
          final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];
          final pastSquareName = '${files[pastCol]}${ranks[pastRow]}';
          
          if (squareName == pastSquareName) {
            final progressFactor = (_moveProgress! - 0.85) / 0.15;
            final shakeMagnitude = sin(progressFactor * 6 * pi) * 3.0 * (1.0 - progressFactor);
            final colOffset = stepCol * shakeMagnitude;
            final rowOffset = stepRow * shakeMagnitude;
            final flipMult = arenaState.isBoardFlipped ? -1.0 : 1.0;
            return Offset(colOffset, rowOffset * flipMult);
          }
        }
      }
    }

    return Offset.zero;
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

  void _triggerTapRipple(String squareName) {
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

  void _triggerCaptureEffect(String squareName, ChessTheme chessTheme, double boardSize) {
    final center = _getSquareCenter(squareName, boardSize);
    final effect = chessTheme.buildCaptureEffect(context, center, () {
      setState(() => _captureEffects.removeWhere((e) => e['pos'] == center));
    });
    if (effect != null) {
      setState(() {
        _captureEffects.add({
          'pos': center,
          'widget': effect,
        });
      });
    }
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

    final moveAnim = ref.read(arenaProvider).moveAnimation;
    final isCapture = moveAnim?.isCapture ?? false;
    final themeId = ref.read(chessProvider).boardThemeId;
    final chessTheme = ThemeRegistry.getTheme(themeId);

    // Trigger board camera shake & focal zoom for Arc theme
    if (themeId == 'sprite_arc' && ref.read(chessProvider.notifier).masterAnimationsEnabled) {
      _zoomCenter = _getSquareCenter(to, boardSize);
      final isRook = pieceCode.substring(1).toUpperCase() == 'R';
      final isKing = pieceCode.substring(1).toUpperCase() == 'K';
      final isBorder = to.startsWith('a') || to.startsWith('h') || to.endsWith('1') || to.endsWith('8');

      if (isCapture) {
        _shakeType = 'capture';
        _cameraShakeController.forward(from: 0.0);
        _focalZoomController.forward(from: 0.0).then((_) {
          if (mounted) {
            _focalZoomController.reverse();
          }
        });
      } else if (isRook && isBorder) {
        _shakeType = 'rook';
        _cameraShakeController.forward(from: 0.0);
      } else if (isKing) {
        _shakeType = 'king';
        _cameraShakeController.forward(from: 0.0);
      }
    }

    // 1. Trigger global Landing Feedback (Tier 1)
    _triggerLandingFeedback(to, profile, boardSize, isCritical: isCritical);

    // 2. Trigger theme-specific Capture Effect (Tier 2/3, gated by masterAnimationsEnabled)
    if (isCapture && ref.read(chessProvider.notifier).masterAnimationsEnabled) {
      final capturingPieceType = moveAnim?.pieceCode.substring(1).toUpperCase();
      if (themeId == 'sprite_arc' && capturingPieceType == 'P') {
        // Skip the radiating orbital capture effect to ensure the signature pawn capturing slash is fully visible
      } else {
        _triggerCaptureEffect(to, chessTheme, boardSize);
      }
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

    final steps = max(dCol.abs(), dRow.abs());
    if (steps <= 1) return const [];

    final list = <String>[];
    final stepCol = dCol ~/ steps;
    final stepRow = dRow ~/ steps;

    for (int i = 1; i < steps; i++) {
      final c = fromCol + stepCol * i;
      final r = fromRow + stepRow * i;
      const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
      list.add('${files[c]}${r + 1}');
    }
    return list;
  }

  MoveAnnotation _mapClassificationToAnnotation(MoveClassification? classification) {
    if (classification == null) return MoveAnnotation.none;
    switch (classification) {
      case MoveClassification.brilliant:
        return MoveAnnotation.brilliant;
      case MoveClassification.best:
        return MoveAnnotation.good;
      case MoveClassification.good:
        return MoveAnnotation.good;
      case MoveClassification.inaccuracy:
        return MoveAnnotation.dubious;
      case MoveClassification.mistake:
        return MoveAnnotation.mistake;
      case MoveClassification.blunder:
        return MoveAnnotation.blunder;
      default:
        return MoveAnnotation.none;
    }
  }
}

class DragTiltWidget extends StatefulWidget {
  final Widget child;
  const DragTiltWidget({super.key, required this.child});

  @override
  State<DragTiltWidget> createState() => _DragTiltWidgetState();
}

class _DragTiltWidgetState extends State<DragTiltWidget> with SingleTickerProviderStateMixin {
  Offset _lastPos = Offset.zero;
  Offset _velocity = Offset.zero;
  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.attached) {
        final currentPos = renderBox.localToGlobal(Offset.zero);
        if (_lastPos != Offset.zero) {
          final diff = currentPos - _lastPos;
          setState(() {
            _velocity = _velocity * 0.75 + diff * 0.25;
          });
        }
        _lastPos = currentPos;
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tiltX = (_velocity.dx * -0.012).clamp(-0.25, 0.25);
    final speed = _velocity.distance;
    final stretchY = 1.0 + (speed * 0.005).clamp(0.0, 0.08);

    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..rotateZ(tiltX);
    final scaledMatrix = matrix * Matrix4.diagonal3Values(1.0, stretchY, 1.0);

    return Transform(
      transform: scaledMatrix,
      alignment: Alignment.bottomCenter,
      child: widget.child,
    );
  }
}
