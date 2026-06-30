import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../../domain/chess_game.dart';
import '../scholarly_theme.dart';

import '../shared/themes/chess_theme.dart';
import '../shared/widgets/chess_piece_widget.dart';
import 'widgets/academy_system_indicators.dart';
import '../shared/widgets/promotion_overlay.dart';
import '../shared/animations/signature_move_overlay.dart';
import '../shared/animations/landing_feedback.dart';
import '../shared/animations/tap_ripple.dart';
import '../shared/animations/piece_motion_profile.dart';
import '../shared/animations/shake_animation.dart';

import 'themes/academy_scholar_theme.dart';
import 'themes/academy_champion_theme.dart';

class AcademyBoard extends ConsumerStatefulWidget {
  final AlignmentGeometry alignment;

  const AcademyBoard({super.key, this.alignment = Alignment.center});

  @override
  ConsumerState<AcademyBoard> createState() => _AcademyBoardState();
}

class _AcademyBoardState extends ConsumerState<AcademyBoard>
    with TickerProviderStateMixin {
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  String? _dropSquare;
  late AnimationController _dropController;

  // Tap ripple entries: board-local top-left Offset of the tapped square
  final List<Offset> _tapRipples = [];

  // Landing micro-settle entries: {square, profile, row, col}
  final List<Map<String, dynamic>> _landingFeedbacks = [];

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

  String _getCandidatePlaybackDisplayFen(ChessState chessState) {
    final base = chessState.candidatePlaybackBaseFen ?? chessState.currentBoardFen;
    final board = chess_lib.Chess.fromFEN(base);
    final moves = chessState.activeCandidateMoves ?? [];
    final limit = min(chessState.candidatePlaybackPosition, moves.length);
    for (int i = 0; i < limit; i++) {
      final uci = moves[i];
      if (uci.length >= 4) {
        final from = uci.substring(0, 2);
        final to = uci.substring(2, 4);
        final promo = uci.length > 4 ? uci.substring(4) : null;
        final piece = board.get(from);
        if (piece != null) {
          final isWhitePiece = piece.color == chess_lib.Color.WHITE;
          final currentFen = board.fen;
          final parts = currentFen.split(' ');
          if (parts.length > 1) {
            parts[1] = isWhitePiece ? 'w' : 'b';
            board.load(parts.join(' '));
          }
        }
        board.move({'from': from, 'to': to, 'promotion': promo});
      }
    }
    return board.fen;
  }

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);
    final targetThemeValue = chessState.isBoardInChampionsTheme ? 1.0 : 0.0;

    String getTacticsDisplayFen() {
      final base = chessState.tacticsBaseFen ?? chessState.currentBoardFen;
      final board = chess_lib.Chess.fromFEN(base);
      for (final step in chessState.tacticsSequence) {
        final piece = board.get(step.from);
        if (piece != null) {
          final isWhitePiece = piece.color == chess_lib.Color.WHITE;
          final currentFen = board.fen;
          final parts = currentFen.split(' ');
          if (parts.length > 1) {
            parts[1] = isWhitePiece ? 'w' : 'b';
            board.load(parts.join(' '));
          }
        }
        board.move({'from': step.from, 'to': step.to});
      }
      return board.fen;
    }

    String getPlaybackDisplayFen() {
      final base = chessState.tacticsBaseFen ?? chessState.currentBoardFen;
      final board = chess_lib.Chess.fromFEN(base);
      final moves = chessState.activeTacticMoves ?? [];
      final limit = min(chessState.tacticPlaybackPosition, moves.length);
      for (int i = 0; i < limit; i++) {
        final uci = moves[i];
        if (uci.length >= 4) {
          final from = uci.substring(0, 2);
          final to = uci.substring(2, 4);
          final promo = uci.length > 4 ? uci.substring(4) : null;
          final piece = board.get(from);
          if (piece != null) {
            final isWhitePiece = piece.color == chess_lib.Color.WHITE;
            final currentFen = board.fen;
            final parts = currentFen.split(' ');
            if (parts.length > 1) {
              parts[1] = isWhitePiece ? 'w' : 'b';
              board.load(parts.join(' '));
            }
          }
          board.move({'from': from, 'to': to, 'promotion': ?promo});
        }
      }
      return board.fen;
    }

    final String displayFen;
    if (chessState.activeTacticIndex != null) {
      displayFen = getPlaybackDisplayFen();
    } else if (chessState.isTacticsModeActive) {
      displayFen = getTacticsDisplayFen();
    } else if (chessState.isCandidatePlaybackActive && chessState.activeCandidateMoves != null) {
      displayFen = _getCandidatePlaybackDisplayFen(chessState);
    } else {
      displayFen = chessState.currentBoardFen;
    }
    final displayGame = ChessGame(fen: displayFen);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetThemeValue),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, t, child) {
        final chessTheme = InterpolatedChessTheme(t);

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

                      if (chessState.game.inCheck && !chessState.isTacticsModeActive && chessState.activeTacticIndex == null)
                        chessTheme.buildCheckEffect(context),

                      if (chessState.academyHouseAnimations)
                        const AcademyPaperOverlay(),

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
                          chessState.isBoardFlipped,
                        );

                        final isSelected = _selectedSquare == squareName;
                        final isHint = _legalTargets.contains(squareName);
                        final isLastMoveStartOrEnd =
                            _isStartOrEndSquare(squareName, chessState.lastMove);
                        final isLastMoveInBetween =
                            _isInBetweenSquare(squareName, chessState.lastMove);
                        final isSuggestedFrom =
                            chessState.isHintVisible &&
                            chessState.hintFrom == squareName;
                        final isSuggestedTo =
                            chessState.isHintVisible &&
                            chessState.hintTo == squareName;
                        final isThreatened = chessState.threatenedSquares
                            .contains(squareName);
                        final isGlow = chessState.glowingSquare == squareName;
                        final isSuggestionTarget = chessState.chanakyaSuggestion?.to == squareName;

                        final isPremoveStartOrEnd =
                            chessState.premoveFrom == squareName ||
                            chessState.premoveTo == squareName;

                        TacticsStep? lastStepForSquare;
                        if (chessState.isTacticsModeActive) {
                          for (final step in chessState.tacticsSequence) {
                            if (step.from == squareName || step.to == squareName) {
                              lastStepForSquare = step;
                            }
                          }
                        }
                        final isPlaybackHighlight = chessState.activeTacticIndex != null &&
                            chessState.activeTacticMoves != null &&
                            chessState.tacticPlaybackPosition > 0 &&
                            (chessState.activeTacticMoves![chessState.tacticPlaybackPosition - 1].substring(0, 2) == squareName ||
                                chessState.activeTacticMoves![chessState.tacticPlaybackPosition - 1].substring(2, 4) == squareName);

                        chess_lib.Piece? piece;
                        bool isGhostPiece = false;
                        if (chessState.premoveFrom != null && chessState.premoveTo != null) {
                          if (squareName == chessState.premoveFrom) {
                            piece = null;
                          } else if (squareName == chessState.premoveTo) {
                            piece = displayGame.getPiece(chessState.premoveFrom!);
                            isGhostPiece = true;
                          } else {
                            piece = displayGame.getPiece(squareName);
                          }
                        } else {
                          piece = displayGame.getPiece(squareName);
                        }

                        return DragTarget<String>(
                          onWillAcceptWithDetails: (details) {
                            if (chessState.activeTacticIndex != null) return false;
                            return _legalTargets.contains(squareName);
                          },
                          onAcceptWithDetails: (details) {
                            if (chessState.isTacticsModeActive) {
                              ref.read(chessProvider.notifier).addTacticsMove(details.data, squareName);
                            } else {
                              ref
                                  .read(chessProvider.notifier)
                                  .makeMove(details.data, squareName);
                            }
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
                                    border: chessTheme.getSquareBorder(
                                          isSelected,
                                          isDragHover,
                                        ) ??
                                        Border.all(
                                          color: isSelected
                                              ? ScholarlyTheme.accentGold
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
                                          if (isSelected &&
                                              chessTheme.hasSystemIndicators &&
                                              ref
                                                  .read(
                                                    chessProvider.notifier,
                                                  )
                                                  .isAnimationTypeEnabled(
                                                    'indicators',
                                                  ))
                                            const AcademyOrbitingStarAnimation(
                                              color: ScholarlyTheme
                                                  .accentBlueSoft,
                                              isActive: true,
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
                                              chessTheme.hasSystemIndicators &&
                                              ref
                                                  .read(
                                                    chessProvider.notifier,
                                                  )
                                                  .isAnimationTypeEnabled(
                                                    'indicators',
                                                  ))
                                            const AcademyOrbitingStarAnimation(
                                              color:
                                                  ScholarlyTheme.accentGold,
                                              isActive: true,
                                            ),
                                          if (isThreatened && !isSuggestionTarget && !isGlow &&
                                              chessTheme.hasSystemIndicators &&
                                              ref
                                                  .read(
                                                    chessProvider.notifier,
                                                  )
                                                  .isAnimationTypeEnabled(
                                                    'indicators',
                                                  ))
                                            const AcademyOrbitingStarAnimation(
                                              color: Colors.redAccent,
                                              isActive: true,
                                              isCircle: true,
                                            ),
                                          if (isGlow && chessTheme.hasSystemIndicators)
                                            const AcademySquareGlow(
                                              color: ScholarlyTheme.accentBlue,
                                            ),
                                          // 6. Last Move Highlight (Classic uses opacity)
                                          if (isLastMoveStartOrEnd || isLastMoveInBetween)
                                            TweenAnimationBuilder<double>(
                                              key: ValueKey(
                                                'lm_${chessState.lastMove}',
                                              ),
                                              tween: Tween(
                                                begin: isLastMoveStartOrEnd ? 0.35 : 0.15,
                                                end: isLastMoveStartOrEnd ? 0.24 : 0.09,
                                              ),
                                              duration: ref
                                                      .read(
                                                        chessProvider
                                                            .notifier,
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
                                          if (lastStepForSquare != null)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: (lastStepForSquare.isUserMove
                                                        ? ScholarlyTheme.accentGold
                                                        : ScholarlyTheme.accentBlueSoft)
                                                    .withValues(alpha: 0.22),
                                                border: Border.all(
                                                  color: lastStepForSquare.isUserMove
                                                      ? ScholarlyTheme.accentGold
                                                      : ScholarlyTheme.accentBlueSoft,
                                                  width: 2.0,
                                                ),
                                              ),
                                            ),
                                          if (isPlaybackHighlight)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: ScholarlyTheme.accentGold.withValues(alpha: 0.24),
                                                border: Border.all(
                                                  color: ScholarlyTheme.accentGold,
                                                  width: 2.5,
                                                ),
                                              ),
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
                                                  isSuggestedTo) &&
                                              chessTheme.hasSystemIndicators &&
                                              ref
                                                  .read(
                                                    chessProvider.notifier,
                                                  )
                                                  .isAnimationTypeEnabled(
                                                    'indicators',
                                                  ))
                                            const AcademyOrbitingStarAnimation(
                                              color:
                                                  ScholarlyTheme.accentYellow,
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
                                          ShakeAnimation(
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
                                              child: Builder(
                                                builder: (context) {
                                                   final localPiece = piece;
                                                   final pieceExists = localPiece != null;
                                                   final bool isPlayerPiece;
                                                   if (localPiece == null || isGhostPiece || chessState.activeTacticIndex != null) {
                                                     isPlayerPiece = false;
                                                   } else if (chessState.isTacticsModeActive) {
                                                     final nextIsUser = chessState.tacticsSequence.length % 2 == 0;
                                                     final isWhiteTurn = nextIsUser ? chessState.isPlayerWhite : !chessState.isPlayerWhite;
                                                     isPlayerPiece = (localPiece.color == chess_lib.Color.WHITE) == isWhiteTurn;
                                                   } else {
                                                     isPlayerPiece = (localPiece.color == chess_lib.Color.WHITE) == chessState.isPlayerWhite;
                                                   }

                                                  Widget pieceWidget = ChessPieceWidget(
                                                    squareName: isGhostPiece ? chessState.premoveFrom! : squareName,
                                                    pieceCode: isGhostPiece && localPiece != null
                                                        ? '${localPiece.color == chess_lib.Color.WHITE ? 'w' : 'b'}${localPiece.type.toUpperCase()}'
                                                        : null,
                                                    game: displayGame,
                                                    highlighted: isSelected,
                                                    rotation: 0.0,
                                                    theme: chessTheme,
                                                    isMoving: chessState.moveAnimation?.from == squareName ||
                                                        chessState.moveAnimation?.to == squareName,
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
                                                            rotation: 0.0,
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
                                                          rotation: 0.0,
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
                  ),
                  if (chessState.moveAnimation != null)
                    SignatureMoveOverlay(
                      data: chessState.moveAnimation!,
                      boardSize: boardSize,
                      isFlipped: chessState.isBoardFlipped,
                      isCheckmate: chessState.game.inCheckmate,
                      theme: chessTheme,
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
                      onActionTrigger: (action, position) {},
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
                      arcadeMode: ref
                          .read(chessProvider.notifier)
                          .isAnimationTypeEnabled('arcadeMode'),
                      onComplete: () =>
                          setState(() => _tapRipples.remove(pos)),
                    ),

                  if (chessState.chanakyaSuggestion != null &&
                      chessState.academyHouseAnimations)
                    AcademySuggestionOverlay(
                      data: chessState.chanakyaSuggestion!,
                      boardSize: boardSize,
                      isFlipped: chessState.isBoardFlipped,
                      trigger: chessState.academyAnimationTrigger,
                      theme: chessTheme,
                    ),

                  PromotionOverlay(theme: chessTheme),
                ],
              ),
            ),
          ),
        );
      },
    );
  },
);
}

  List<String> _getLegalTargetsForSquare(String squareName, ChessGame game, ChessState chessState) {
    if (chessState.isTacticsModeActive) {
      final piece = game.getPiece(squareName);
      if (piece == null) return const [];
      final pieceIsWhite = piece.color == chess_lib.Color.WHITE;
      final nextIsUser = chessState.tacticsSequence.length % 2 == 0;
      final isWhiteTurn = nextIsUser ? chessState.isPlayerWhite : !chessState.isPlayerWhite;
      if (pieceIsWhite != isWhiteTurn) return const [];
      return game.legalDestinations(squareName);
    }

    final isWhiteTurn = game.turn == chess_lib.Color.WHITE;
    final isPlayerTurn = chessState.isPlayerWhite == isWhiteTurn;
    if (isPlayerTurn) {
      return game.legalDestinations(squareName);
    } else {
      try {
        final fenParts = game.fen.split(' ');
        if (fenParts.length > 1) {
          fenParts[1] = chessState.isPlayerWhite ? 'w' : 'b';
          final tempGame = ChessGame(fen: fenParts.join(' '));
          return tempGame.legalDestinations(squareName);
        }
      } catch (_) {}
      return const [];
    }
  }

  bool _isPlayerTurn(ChessState chessState) {
    final fenParts = chessState.currentBoardFen.split(' ');
    if (fenParts.length > 1) {
      final turnWhite = fenParts[1] == 'w';
      return chessState.isPlayerWhite == turnWhite;
    }
    return true;
  }

  void _handleSquareTap({
    required String squareName,
    required bool pieceExists,
  }) {
    final haptics = ref.read(chessHapticsServiceProvider);
    haptics.selection();
    final chessState = ref.read(chessProvider);

    if (chessState.activeTacticIndex != null || chessState.isCandidatePlaybackActive) return;

    String getTacticsDisplayFen() {
      final base = chessState.tacticsBaseFen ?? chessState.currentBoardFen;
      final board = chess_lib.Chess.fromFEN(base);
      for (final step in chessState.tacticsSequence) {
        final piece = board.get(step.from);
        if (piece != null) {
          final isWhitePiece = piece.color == chess_lib.Color.WHITE;
          final currentFen = board.fen;
          final parts = currentFen.split(' ');
          if (parts.length > 1) {
            parts[1] = isWhitePiece ? 'w' : 'b';
            board.load(parts.join(' '));
          }
        }
        board.move({'from': step.from, 'to': step.to});
      }
      return board.fen;
    }

    final String displayFen = chessState.isTacticsModeActive
        ? getTacticsDisplayFen()
        : chessState.currentBoardFen;
    final displayGame = ChessGame(fen: displayFen);

    // Tap ripple on every tap (gated by animations setting)
    if (ref.read(chessProvider.notifier).isAnimationTypeEnabled('feedback')) {
      _triggerTapRipple(squareName);
    }

    if (_selectedSquare != null && _legalTargets.contains(squareName)) {
      if (chessState.isWaitingForSideChoice) return;
      if (chessState.isTacticsModeActive) {
        ref.read(chessProvider.notifier).addTacticsMove(_selectedSquare!, squareName);
      } else {
        ref.read(chessProvider.notifier).makeMove(_selectedSquare!, squareName);
      }
      _clearSelection();
      return;
    }

    if (pieceExists) {
      _handlePieceSelection(squareName, displayGame);
    } else {
      _clearSelection();
      ref.read(chessProvider.notifier).clearPremove();
    }
  }

  void _handlePieceSelection(String squareName, ChessGame displayGame) {
    final chessState = ref.read(chessProvider);
    if (chessState.isTacticsModeActive) {
      final piece = displayGame.getPiece(squareName);
      if (piece == null) {
        _clearSelection();
        return;
      }
      final isPieceWhite = piece.color == chess_lib.Color.WHITE;
      final nextIsUser = chessState.tacticsSequence.length % 2 == 0;
      final isWhiteTurn = nextIsUser ? chessState.isPlayerWhite : !chessState.isPlayerWhite;
      if (isPieceWhite != isWhiteTurn) {
        _clearSelection();
        return;
      }
      setState(() {
        _selectedSquare = squareName;
        _legalTargets = _getLegalTargetsForSquare(squareName, displayGame, chessState);
      });
      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceSelect);
      return;
    }

    final piece = displayGame.getPiece(squareName);
    if (piece == null) {
      _clearSelection();
      return;
    }

    final isGameOver = chessState.game.gameOver;
    if (isGameOver) {
      _clearSelection();
      return;
    }

    if (_selectedSquare == squareName) {
      _clearSelection();
      if (!_isPlayerTurn(chessState)) {
        ref.read(chessProvider.notifier).clearPremove();
      }
      return;
    }

    final isWhitePiece = piece.color == chess_lib.Color.WHITE;
    final isWhiteTurn = displayGame.turn == chess_lib.Color.WHITE;
    final isPlayerTurn = chessState.isPlayerWhite == isWhiteTurn;

    if (isPlayerTurn) {
      final isCurrentTurnPiece = (isWhitePiece == isWhiteTurn);
      if (!isCurrentTurnPiece) {
        _clearSelection();
        return;
      }
    } else {
      final isPlayerPiece = (piece.color == chess_lib.Color.WHITE) == chessState.isPlayerWhite;
      if (!isPlayerPiece) {
        _clearSelection();
        ref.read(chessProvider.notifier).clearPremove();
        return;
      }
      // Clear current pre-move when starting a new selection during opponent's turn
      ref.read(chessProvider.notifier).clearPremove();
    }

    // Lock board controls if game is over, engine vs engine, or waiting for side choice
    final isEvE = chessState.isEngineVsEngine;
    if (isEvE || chessState.isWaitingForSideChoice) {
      _clearSelection();
      return;
    }

    setState(() {
      _selectedSquare = squareName;
      _legalTargets = _getLegalTargetsForSquare(squareName, displayGame, chessState);
    });
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceSelect);
  }

  void _clearSelection() {
    setState(() {
      _selectedSquare = null;
      _legalTargets = const [];
    });
  }


  void _triggerTapRipple(String squareName) {
    final rowCol = _getSquareRowCol(squareName, ref.read(chessProvider).isBoardFlipped);
    if (rowCol != null) {
      final size = context.size?.width ?? 0;
      final squareSize = size / 8;
      final offset = Offset(
        rowCol.y * squareSize,
        rowCol.x * squareSize,
      );
      setState(() {
        _tapRipples.add(offset);
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
    final isFlipped = ref.read(chessProvider).isBoardFlipped;
    final toRowCol = _getSquareRowCol(to, isFlipped);
    if (toRowCol != null) {
      setState(() {
        _landingFeedbacks.add({
          'square': to,
          'profile': profile,
          'row': toRowCol.x,
          'col': toRowCol.y,
          'critical': isCritical,
        });
      });
    }
  }

  Point<int>? _getSquareRowCol(String square, bool isFlipped) {
    if (square.length != 2) return null;
    final files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    final fileIndex = files.indexOf(square[0]);
    final rankIndex = ranks.indexOf(square[1]);

    if (fileIndex == -1 || rankIndex == -1) return null;

    if (isFlipped) {
      return Point(7 - rankIndex, 7 - fileIndex);
    }
    return Point(rankIndex, fileIndex);
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
  final ChessTheme theme;

  const AcademySuggestionOverlay({
    super.key,
    required this.data,
    required this.boardSize,
    required this.isFlipped,
    required this.trigger,
    required this.theme,
  });

  @override
  State<AcademySuggestionOverlay> createState() =>
      _AcademySuggestionOverlayState();
}

class _AcademySuggestionOverlayState extends State<AcademySuggestionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _startAnimation();
  }

  void _startAnimation() {
    setState(() => _isVisible = true);
    _controller.reset();
    _controller.forward().then((_) {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  @override
  void didUpdateWidget(AcademySuggestionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger || oldWidget.data != widget.data) {
      _startAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

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

    final String pieceCode = widget.data.pieceCode;
    final bool isWhite = pieceCode.startsWith('w');
    final String pieceType = pieceCode.substring(1);

    return IgnorePointer(
      child: Stack(
        children: [
          // 1. Animated Scholarly Arrow
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final t = _animation.value;

              // Arrow progress draws from 0.0 to 0.4
              final arrowProgress = (t / 0.4).clamp(0.0, 1.0);

              // Arrow opacity is solid, and fades out from 0.8 to 1.0
              double arrowOpacity = 1.0;
              if (t > 0.8) {
                arrowOpacity = ((1.0 - t) / 0.2).clamp(0.0, 1.0);
              }

              return CustomPaint(
                size: Size(widget.boardSize, widget.boardSize),
                painter: AcademyArrowPainter(
                  from: fromPos + Offset(squareSize / 2, squareSize / 2),
                  to: toPos + Offset(squareSize / 2, squareSize / 2),
                  progress: arrowProgress,
                  opacity: arrowOpacity,
                ),
              );
            },
          ),

          // 2. Gliding & Settling Piece
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final t = _animation.value;

              double glideProgress = (t / 0.4).clamp(0.0, 1.0);
              double curveValue = Curves.easeInOut.transform(glideProgress);

              // Quadratic Bezier path matching the arrow arc
              final p0 = fromPos;
              final p2 = toPos;
              final p1 = Offset(
                (p0.dx + p2.dx) / 2,
                (p0.dy + p2.dy) / 2 - 35, // arc height
              );

              final currentPos = Offset(
                (1 - curveValue) * (1 - curveValue) * p0.dx +
                    2 * (1 - curveValue) * curveValue * p1.dx +
                    curveValue * curveValue * p2.dx,
                (1 - curveValue) * (1 - curveValue) * p0.dy +
                    2 * (1 - curveValue) * curveValue * p1.dy +
                    curveValue * curveValue * p2.dy,
              );

              double opacity = 0.95;
              double scale = 1.0;

              if (t <= 0.4) {
                // Glide: lift and descend
                scale = 1.0 + 0.15 * sin(glideProgress * pi);
              } else if (t <= 0.8) {
                // Settle: small bounce when landing
                final settleProgress = (t - 0.4) / 0.4;
                if (settleProgress <= 0.35) {
                  final tSettle = settleProgress / 0.35;
                  scale = 1.0 + 0.08 * sin(tSettle * pi);
                }
              } else {
                // Fade out: shrink and fade
                final fadeProgress = (t - 0.8) / 0.2;
                opacity = 0.95 * (1.0 - fadeProgress);
                scale = 1.0 - 0.08 * fadeProgress;
              }

              return Positioned(
                left: currentPos.dx,
                top: currentPos.dy,
                child: Opacity(
                  opacity: opacity.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: scale,
                    child: SizedBox(
                      width: squareSize,
                      height: squareSize,
                      child: Center(
                        child: widget.theme.buildPiece(
                          context,
                          pieceType,
                          isWhite,
                          false,
                          0.0,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
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
  final double opacity;

  AcademyArrowPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || opacity <= 0) return;

    final controlPoint = Offset(
      (from.dx + to.dx) / 2,
      (from.dy + to.dy) / 2 - 30,
    );

    final path = Path()..moveTo(from.dx, from.dy);
    if (progress < 1.0) {
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

    // 1. Shadow glow (dark green)
    final shadowPaint = Paint()
      ..color = const Color(0xFF15803D).withValues(alpha: 0.25 * opacity)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, shadowPaint);

    // 2. Vibrant green main path
    final paint = Paint()
      ..color = const Color(0xFF22C55E).withValues(alpha: 0.85 * opacity)
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paint);

    // 3. Arrowhead
    if (progress > 0.8) {
      final t = progress;
      final headOpacity = (t - 0.8) / 0.2;

      final paintHead = Paint()
        ..color = const Color(0xFF22C55E).withValues(alpha: 0.85 * opacity * headOpacity)
        ..style = PaintingStyle.fill;

      final dx = 2 * (1 - t) * (controlPoint.dx - from.dx) +
          2 * t * (to.dx - controlPoint.dx);
      final dy = 2 * (1 - t) * (controlPoint.dy - from.dy) +
          2 * t * (to.dy - controlPoint.dy);
      final angle = Offset(dx, dy).direction;

      const arrowSize = 14.0;
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
      oldDelegate.opacity != opacity ||
      oldDelegate.from != from ||
      oldDelegate.to != to;
}

class InterpolatedChessTheme extends ChessTheme {
  final double t;
  final AcademyScholarTheme scholar;
  final AcademyChampionTheme champion;

  InterpolatedChessTheme(this.t)
      : scholar = const AcademyScholarTheme(),
        champion = const AcademyChampionTheme(),
        super(id: 'interpolated', name: 'Interpolated');

  @override
  Color get lightSquare => Color.lerp(scholar.lightSquare, champion.lightSquare, t)!;

  @override
  Color get darkSquare => Color.lerp(scholar.darkSquare, champion.darkSquare, t)!;

  @override
  Color get lightCoordinateColor => Color.lerp(scholar.lightCoordinateColor, champion.lightCoordinateColor, t)!;

  @override
  Color get darkCoordinateColor => Color.lerp(scholar.darkCoordinateColor, champion.darkCoordinateColor, t)!;

  @override
  Color get frameColor => Color.lerp(scholar.frameColor, champion.frameColor, t)!;

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return scholar.buildBackground(context, animationsEnabled);
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return champion.buildCheckEffect(context);
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) => null;

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    if (t == 0.0) {
      return scholar.buildPiece(context, type, isWhite, isHighlighted, animationValue);
    }
    if (t == 1.0) {
      return champion.buildPiece(context, type, isWhite, isHighlighted, animationValue);
    }
    return Stack(
      children: [
        Opacity(
          opacity: (1.0 - t).clamp(0.0, 1.0),
          child: scholar.buildPiece(context, type, isWhite, isHighlighted, animationValue),
        ),
        Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: champion.buildPiece(context, type, isWhite, isHighlighted, animationValue),
        ),
      ],
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return scholar.buildMoveHint(context, isEnemy);
  }

  @override
  Widget buildSelectionRing(BuildContext context) {
    return scholar.buildSelectionRing(context);
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(
          const Color(0xFF0056B3),
          const Color(0xFFFFD700),
          t,
        )!.withValues(alpha: opacity),
      ),
    );
  }
}
