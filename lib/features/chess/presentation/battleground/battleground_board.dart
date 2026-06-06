import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../../application/chess_provider.dart';
import '../../application/battleground_provider.dart';
import '../../domain/chess_game.dart';
// Removed unused import

import '../shared/themes/chess_theme.dart';
import '../shared/widgets/chess_piece_widget.dart';
import '../shared/widgets/orbiting_star_animation.dart';
import '../shared/widgets/promotion_overlay.dart';
// Removed unused import

import 'themes/rated_bnw_theme.dart';

class BattlegroundBoard extends ConsumerStatefulWidget {
  final AlignmentGeometry alignment;

  const BattlegroundBoard({super.key, this.alignment = Alignment.center});

  @override
  ConsumerState<BattlegroundBoard> createState() => _BattlegroundBoardState();
}

class _BattlegroundBoardState extends ConsumerState<BattlegroundBoard>
    with TickerProviderStateMixin {
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  String? _dropSquare;
  late AnimationController _dropController;

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
    final bgState = ref.watch(battlegroundProvider);
    // Rated mode always uses BNW theme
    const chessTheme = ratedBnwTheme;

    // Use currentBoardFen for display during analysis/history viewing
    final displayGame = ChessGame(fen: bgState.currentBoardFen);

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
              decoration: null,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Background Effects (Classic has none)
                  RepaintBoundary(
                    child: chessTheme.buildBackground(
                      context,
                      ref
                          .read(chessProvider.notifier)
                          .isAnimationTypeEnabled('themeAmbience'),
                    ),
                  ),

                  if (bgState.game.inCheck)
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
                          bgState.isBoardFlipped,
                        );

                        final isSelected = _selectedSquare == squareName;
                        final isHint = _legalTargets.contains(squareName);
                        final isLastMoveStartOrEnd =
                            _isStartOrEndSquare(squareName, bgState.lastMove);
                        final isLastMoveInBetween =
                            _isInBetweenSquare(squareName, bgState.lastMove);
                        final isThreatened = bgState.threatenedSquares
                            .contains(squareName);
                        final isPremoveStartOrEnd =
                            bgState.premoveFrom == squareName ||
                            bgState.premoveTo == squareName;

                        final piece = displayGame.getPiece(squareName);

                        return DragTarget<String>(
                           onWillAcceptWithDetails: (details) {
                             // Accept during player's turn (normal move hints)
                             if (_legalTargets.contains(squareName)) return true;
                             // Accept during opponent's turn for premove (dragged piece belongs to player)
                             if (!_isPlayerTurn(bgState)) {
                               final draggingPiece = displayGame.getPiece(details.data);
                               if (draggingPiece != null) {
                                 final isPlayerPiece =
                                     (draggingPiece.color == chess_lib.Color.WHITE) == bgState.isPlayerWhite;
                                 return isPlayerPiece && squareName != details.data;
                               }
                             }
                             return false;
                           },
                           onAcceptWithDetails: (details) {
                             ref.read(battlegroundProvider.notifier).makeMove(details.data, squareName);
                             setState(() {
                               _dropSquare = squareName;
                             });
                             _dropController.forward(from: 0);
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
                                    border: chessTheme.getSquareBorder(isSelected, isDragHover),
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
                                          // 3. Square Texture/Painter (Classic has none)
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
                                            chessTheme.buildSelectionRing(context),
                                          // 5. Move Hints
                                          if (isHint)
                                            chessTheme.buildMoveHint(
                                              context,
                                              piece != null,
                                            ),
                                          if (isThreatened &&
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
                                              isCircle: true,
                                            ),
                                          // 6. Last Move Highlight (Classic uses opacity)
                                          if (isLastMoveStartOrEnd || isLastMoveInBetween)
                                            TweenAnimationBuilder<double>(
                                              key: ValueKey(
                                                'lm_${bgState.lastMove}',
                                              ),
                                              tween: Tween(
                                                begin: isLastMoveStartOrEnd ? 0.35 : 0.15,
                                                end: isLastMoveStartOrEnd ? 0.24 : 0.09,
                                              ),
                                              duration: Duration.zero,
                                              curve: Curves.easeOutCubic,
                                              builder: (context, opacity, _) {
                                                return chessTheme
                                                    .buildLastMoveHighlight(
                                                      context,
                                                      opacity,
                                                    );
                                              },
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
                                           Builder(
                                             builder: (context) {
                                               Widget piece = ChessPieceWidget(
                                                 squareName: squareName,
                                                 game: displayGame,
                                                 highlighted: isSelected,
                                                 rotation: 0.0,
                                                 theme: chessTheme,
                                                 isMoving: false,
                                                 onTap: () => _handleSquareTap(squareName: squareName, pieceExists: displayGame.getPiece(squareName) != null),
                                                 onDragStarted: () => _handlePieceSelection(squareName, displayGame),
                                                 onDragEnd: _clearSelection,
                                               );
                                               if (squareName == _dropSquare) {
                                                 return AnimatedBuilder(
                                                   animation: _dropController,
                                                   builder: (context, child) {
                                                     double scale = 0.85 + 0.15 * Curves.elasticOut.transform(_dropController.value);
                                                     return Transform.scale(scale: scale, child: child);
                                                   },
                                                   child: piece,
                                                 );
                                               }
                                               return piece;
                                             },
                                           ),
                                          if (chessState.showCoordinates)
                                            _buildCoordinates(
                                              row,
                                              col,
                                              (row + col) % 2 == 0,
                                              bgState.isBoardFlipped,
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
                  if (bgState.moveAnimation != null)
                    Builder(
                      builder: (context) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(battlegroundProvider.notifier)
                              .clearMoveAnimation();
                        });
                        return const SizedBox.shrink();
                      },
                    ),

                  PromotionOverlay(
                    theme: chessTheme,
                    isPromotingOverride: bgState.isPromoting,
                    isWhiteOverride: bgState.game.turn == chess_lib.Color.WHITE,
                    onCompleteOverride: (piece) => ref.read(battlegroundProvider.notifier).completePromotion(piece),
                    onCancelOverride: () => ref.read(battlegroundProvider.notifier).cancelPromotion(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _getLegalTargetsForSquare(String squareName, ChessGame game, BattlegroundState bgState) {
    final isWhiteTurn = game.turn == chess_lib.Color.WHITE;
    final isPlayerTurn = bgState.isPlayerWhite == isWhiteTurn;
    if (isPlayerTurn) {
      return game.legalDestinations(squareName);
    } else {
      try {
        final fenParts = game.fen.split(' ');
        if (fenParts.length > 1) {
          fenParts[1] = bgState.isPlayerWhite ? 'w' : 'b';
          final tempGame = ChessGame(fen: fenParts.join(' '));
          return tempGame.legalDestinations(squareName);
        }
      } catch (_) {}
      return const [];
    }
  }

  void _handleSquareTap({
    required String squareName,
    required bool pieceExists,
  }) {
    final bgState = ref.read(battlegroundProvider);
    final displayGame = ChessGame(fen: bgState.currentBoardFen);

    if (_selectedSquare != null && _legalTargets.contains(squareName)) {
      ref.read(battlegroundProvider.notifier).makeMove(_selectedSquare!, squareName);
      _clearSelection();
      return;
    }

    if (pieceExists) {
      _handlePieceSelection(squareName, displayGame);
    } else {
      _clearSelection();
      ref.read(battlegroundProvider.notifier).clearPremove();
    }
  }

  void _handlePieceSelection(String squareName, ChessGame displayGame) {
    final bgState = ref.read(battlegroundProvider);
    final piece = displayGame.getPiece(squareName);
    if (piece == null) {
      _clearSelection();
      return;
    }

    final isGameOver = bgState.game.gameOver;
    if (isGameOver) {
      _clearSelection();
      return;
    }

    final isWhiteTurn = displayGame.turn == chess_lib.Color.WHITE;
    final isPlayerTurn = bgState.isPlayerWhite == isWhiteTurn;

    if (isPlayerTurn) {
      if (piece.color == chess_lib.Color.WHITE && !isWhiteTurn) {
        _clearSelection();
        return;
      }
      if (piece.color == chess_lib.Color.BLACK && isWhiteTurn) {
        _clearSelection();
        return;
      }
    } else {
      final isPlayerPiece = (piece.color == chess_lib.Color.WHITE) == bgState.isPlayerWhite;
      if (!isPlayerPiece) {
        _clearSelection();
        ref.read(battlegroundProvider.notifier).clearPremove();
        return;
      }
    }

    setState(() {
      _selectedSquare = squareName;
      _legalTargets = _getLegalTargetsForSquare(squareName, displayGame, bgState);
    });
    // Sound effects disabled in Battleground
    // ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceSelect);
  }

  void _clearSelection() {
    setState(() {
      _selectedSquare = null;
      _legalTargets = const [];
    });
  }

  bool _isPlayerTurn(BattlegroundState bgState) {
    final fenParts = bgState.currentBoardFen.split(' ');
    if (fenParts.length > 1) {
      final turnWhite = fenParts[1] == 'w';
      return bgState.isPlayerWhite == turnWhite;
    }
    return true;
  }

  String _getSquareName(int row, int col, bool isFlipped) {
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    if (isFlipped) {
      return '${files[7 - col]}${ranks[7 - row]}';
    }
    return '${files[col]}${ranks[row]}';
  }

  bool _isStartOrEndSquare(String squareName, String? uciMove) {
    if (uciMove == null || uciMove.length < 4) return false;
    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    return squareName == from || squareName == to;
  }

  bool _isInBetweenSquare(String squareName, String? uciMove) {
    if (uciMove == null || uciMove.length < 4) return false;
    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);

    final fromCol = from.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fromRow = from.codeUnitAt(1) - '1'.codeUnitAt(0);
    final toCol = to.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final toRow = to.codeUnitAt(1) - '1'.codeUnitAt(0);

    final targetCol = squareName.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final targetRow = squareName.codeUnitAt(1) - '1'.codeUnitAt(0);

    final minCol = min(fromCol, toCol);
    final maxCol = max(fromCol, toCol);
    final minRow = min(fromRow, toRow);
    final maxRow = max(fromRow, toRow);

    if (targetCol < minCol || targetCol > maxCol || targetRow < minRow || targetRow > maxRow) {
      return false;
    }

    if (squareName == from || squareName == to) return false;

    // Check collinearity
    if ((toCol - fromCol) * (targetRow - fromRow) == (targetCol - fromCol) * (toRow - fromRow)) {
      return true;
    }
    return false;
  }

  Widget _buildCoordinates(
    int row,
    int col,
    bool isLightSquare,
    bool isFlipped,
    ChessTheme theme,
  ) {
    final color = isLightSquare ? theme.lightCoordinateColor : theme.darkCoordinateColor;
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    final fileText = isFlipped ? files[7 - col] : files[col];
    final rankText = isFlipped ? ranks[7 - row] : ranks[row];

    return Stack(
      children: [
        if (col == 0)
          Positioned(
            top: 2,
            left: 4,
            child: Text(
              rankText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        if (row == 7)
          Positioned(
            bottom: 2,
            right: 4,
            child: Text(
              fileText,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
      ],
    );
  }
}
