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
                        final isPremoveStartOrEnd =
                            bgState.premoveFrom == squareName ||
                            bgState.premoveTo == squareName;

                        chess_lib.Piece? piece;
                        bool isGhostPiece = false;
                        if (bgState.premoveFrom != null && bgState.premoveTo != null) {
                          if (squareName == bgState.premoveFrom) {
                            piece = null;
                          } else if (squareName == bgState.premoveTo) {
                            piece = displayGame.getPiece(bgState.premoveFrom!);
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
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
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
                                          // Background tile (with press animation)
                                          Positioned.fill(
                                            child: AnimatedScale(
                                              scale: isSelected ? 0.93 : 1.0,
                                              duration: const Duration(milliseconds: 200),
                                              curve: Curves.easeOutCubic,
                                              child: Stack(
                                                children: [
                                                  Positioned.fill(
                                                    child: AnimatedContainer(
                                                      duration: ref.read(chessProvider.notifier).isAnimationTypeEnabled('feedback')
                                                          ? const Duration(milliseconds: 160)
                                                          : Duration.zero,
                                                      curve: Curves.easeOutCubic,
                                                      decoration: BoxDecoration(
                                                        color: isLight
                                                            ? chessTheme.lightSquare
                                                            : chessTheme.darkSquare,
                                                        borderRadius: BorderRadius.circular(isSelected ? 6.0 : 0.0),
                                                        border: chessTheme.getSquareBorder(isSelected, isDragHover),
                                                      ),
                                                    ),
                                                  ),
                                                  if (chessTheme.getSquarePainter(isLight, 0) != null)
                                                    Positioned.fill(
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(isSelected ? 6.0 : 0.0),
                                                        child: CustomPaint(
                                                          painter: chessTheme.getSquarePainter(isLight, 0.0),
                                                          size: Size.infinite,
                                                        ),
                                                      ),
                                                    ),
                                                  if (isLastMoveStartOrEnd || isLastMoveInBetween)
                                                    Positioned.fill(
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(isSelected ? 6.0 : 0.0),
                                                        child: TweenAnimationBuilder<double>(
                                                          key: ValueKey('lm_${bgState.lastMove}'),
                                                          tween: Tween(
                                                            begin: isLastMoveStartOrEnd ? 0.35 : 0.15,
                                                            end: isLastMoveStartOrEnd ? 0.24 : 0.09,
                                                          ),
                                                          duration: Duration.zero,
                                                          builder: (context, opacity, _) {
                                                            return chessTheme.buildLastMoveHighlight(context, opacity);
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
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
                                           if (isPremoveStartOrEnd)
                                             Container(
                                               decoration: BoxDecoration(
                                                 color: Colors.green.withValues(alpha: 0.25),
                                                 border: Border.all(
                                                   color: Colors.green,
                                                   width: 2.0,
                                                 ),
                                               ),
                                             ),
                                           Builder(
                                             builder: (context) {
                                                final localPiece = piece;
                                                final pieceExists = localPiece != null;
                                                final isPlayerPiece = localPiece != null && !isGhostPiece &&
                                                    ((localPiece.color == chess_lib.Color.WHITE) == bgState.isPlayerWhite);

                                                Widget pieceWidget = ChessPieceWidget(
                                                  squareName: isGhostPiece ? bgState.premoveFrom! : squareName,
                                                  pieceCode: isGhostPiece && localPiece != null
                                                      ? '${localPiece.color == chess_lib.Color.WHITE ? 'w' : 'b'}${localPiece.type.toUpperCase()}'
                                                      : null,
                                                 game: displayGame,
                                                 highlighted: isSelected,
                                                 rotation: 0.0,
                                                 theme: chessTheme,
                                                 isMoving: false,
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

                                                pieceWidget = BattlegroundPieceEffectsWrapper(
                                                  isSelected: isSelected && !isGhostPiece,
                                                  child: pieceWidget,
                                                );

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

    if (ref.read(chessProvider).isHapticsEnabled) {
      ref.read(chessHapticsServiceProvider).selection();
    }

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

    if (_selectedSquare == squareName) {
      _clearSelection();
      if (!_isPlayerTurn(bgState)) {
        ref.read(battlegroundProvider.notifier).clearPremove();
      }
      return;
    }

    final isWhiteTurn = displayGame.turn == chess_lib.Color.WHITE;
    final isPlayerTurn = bgState.isPlayerWhite == isWhiteTurn;

    if (isPlayerTurn) {
      if (piece.color == chess_lib.Color.WHITE && !isWhiteTurn) {
        _clearSelection();
        if (ref.read(chessProvider).isHapticsEnabled) {
          ref.read(chessHapticsServiceProvider).errorFeedback();
        }
        return;
      }
      if (piece.color == chess_lib.Color.BLACK && isWhiteTurn) {
        _clearSelection();
        if (ref.read(chessProvider).isHapticsEnabled) {
          ref.read(chessHapticsServiceProvider).errorFeedback();
        }
        return;
      }
    } else {
      final isPlayerPiece = (piece.color == chess_lib.Color.WHITE) == bgState.isPlayerWhite;
      if (!isPlayerPiece) {
        _clearSelection();
        ref.read(battlegroundProvider.notifier).clearPremove();
        if (ref.read(chessProvider).isHapticsEnabled) {
          ref.read(chessHapticsServiceProvider).errorFeedback();
        }
        return;
      }
      // Clear current pre-move when starting a new selection during opponent's turn
      ref.read(battlegroundProvider.notifier).clearPremove();
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

class BattlegroundPieceEffectsWrapper extends StatefulWidget {
  final Widget child;
  final bool isSelected;

  const BattlegroundPieceEffectsWrapper({
    super.key,
    required this.child,
    required this.isSelected,
  });

  @override
  State<BattlegroundPieceEffectsWrapper> createState() =>
      _BattlegroundPieceEffectsWrapperState();
}

class _BattlegroundPieceEffectsWrapperState
    extends State<BattlegroundPieceEffectsWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    if (widget.isSelected) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(BattlegroundPieceEffectsWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        if (!_ctrl.isAnimating) _ctrl.repeat();
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.isSelected ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Back layer: passes behind the piece (z <= 0)
          if (widget.isSelected)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SelectionOrbitPainter(
                      progress: _ctrl.value,
                      frontPass: false,
                    ),
                  );
                },
              ),
            ),
          // Chess piece
          widget.child,
          // Front layer: passes in front of the piece (z > 0)
          if (widget.isSelected)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _SelectionOrbitPainter(
                      progress: _ctrl.value,
                      frontPass: true,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectionOrbitPainter extends CustomPainter {
  final double progress;
  final bool frontPass;

  static const _tilt = 22.0 * pi / 180.0; // 22° tilt
  static const _trailCount = 28;
  static const Color _headColor = Color(0xFFF59E0B);

  const _SelectionOrbitPainter({required this.progress, required this.frontPass});

  static ({double x, double y, double z}) _orbit(
    double theta,
    double cx,
    double headY,
    double R,
  ) {
    final sinT = sin(theta);
    final cosT = cos(theta);
    return (
      x: cx + R * cosT,
      y: headY - R * sinT * sin(_tilt),
      z: R * sinT * cos(_tilt),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final headY = size.height * 0.25; // forehead position
    final R = size.width * 0.22;

    // Current head angle (full circle per loop)
    final theta0 = progress * 2 * pi;

    // Build and draw the comet trail (newest -> oldest)
    for (int i = 0; i < _trailCount; i++) {
      final trailFrac = i / _trailCount;
      final trailSpan = 1.0 * pi; // half-orbit trail length
      final theta = theta0 - trailFrac * trailSpan;

      final p = _orbit(theta, cx, headY, R);

      // Depth filter: only draw on the correct layer
      if (frontPass && p.z <= 0) continue;
      if (!frontPass && p.z > 0) continue;

      final alpha = (1.0 - trailFrac).clamp(0.0, 1.0);
      final radius = (3.5 - trailFrac * 2.8).clamp(0.4, 3.5);

      // Scale brightness by depth for a subtle 3-D cue
      final depthFade = ((p.z / R + 1.0) * 0.5).clamp(0.3, 1.0);

      final paint = Paint()
        ..color = _headColor.withValues(alpha: alpha * 0.92 * depthFade)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.0 + trailFrac * 2.5);

      canvas.drawCircle(Offset(p.x, p.y), radius, paint);
    }

    // Draw the bright star head on the correct layer
    final head = _orbit(theta0, cx, headY, R);
    if ((frontPass && head.z > 0) || (!frontPass && head.z <= 0)) {
      final pulse = (sin(progress * pi * 14) + 1) / 2;
      final headR = 2.2 + pulse * 1.8;
      final glowR = 5.0 + pulse * 3.0;

      // Glow
      canvas.drawCircle(
        Offset(head.x, head.y),
        glowR,
        Paint()
          ..color = _headColor.withValues(alpha: 0.55)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowR),
      );
      // White hot core
      canvas.drawCircle(
        Offset(head.x, head.y),
        headR,
        Paint()
          ..color = Colors.white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
  }

  @override
  bool shouldRepaint(_SelectionOrbitPainter old) =>
      old.progress != progress || old.frontPass != frontPass;
}

