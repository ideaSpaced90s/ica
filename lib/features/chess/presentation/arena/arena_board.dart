import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/chess_provider.dart';
import '../../application/arena_provider.dart';
import '../shared/widgets/chess_piece_widget.dart';
import 'widgets/arena_system_indicators.dart';
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
  }

  @override
  void dispose() {
    _dropController.dispose();
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

                                              if (isPlayerPiece) {
                                                final squareSize = boardSize / 8;
                                                return Draggable<String>(
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
                                                      child: ChessPieceWidget(
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
                                              }

                                              return pieceWidget;
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
    final themeId = ref.read(chessProvider).boardThemeId;
    final chessTheme = ThemeRegistry.getTheme(themeId);

    // 1. Trigger global Landing Feedback (Tier 1)
    _triggerLandingFeedback(to, profile, boardSize, isCritical: isCritical);

    // 2. Trigger theme-specific Capture Effect (Tier 2/3, gated by masterAnimationsEnabled)
    final isCapture = ref.read(arenaProvider).moveAnimation?.isCapture ?? false;
    if (isCapture && ref.read(chessProvider.notifier).masterAnimationsEnabled) {
      _triggerCaptureEffect(to, chessTheme, boardSize);
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
}
