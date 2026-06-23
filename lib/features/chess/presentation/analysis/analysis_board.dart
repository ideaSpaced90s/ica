import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../../application/chess_provider.dart';
import '../../application/study_lab_provider.dart';
import '../../application/analysis_engine_controller.dart';
import '../../services/chess_sound_service.dart';

import '../scholarly_theme.dart';
import 'themes/analysis_classic_theme.dart';
import '../shared/widgets/promotion_overlay.dart';

class StudyLabChessBoard extends ConsumerStatefulWidget {
  final StudyLabState state;
  final StudyLabNotifier notifier;
  final double boardSize;
  final bool showEvalBar;
  final bool isEditorMode;
  final void Function(String square)? onSquareTap;

  const StudyLabChessBoard({
    super.key,
    required this.state,
    required this.notifier,
    required this.boardSize,
    this.showEvalBar = true,
    this.isEditorMode = false,
    this.onSquareTap,
  });

  @override
  ConsumerState<StudyLabChessBoard> createState() => _StudyLabChessBoardState();
}

class _StudyLabChessBoardState extends ConsumerState<StudyLabChessBoard> {
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  String? _pendingPromoFrom;
  String? _pendingPromoTo;

  // Arrow drawing fields
  String? _drawStartSquare;
  String? _hoverSquare;
  String _currentColor = 'green';

  @override
  void didUpdateWidget(StudyLabChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.activeFen != widget.state.activeFen) {
      _selectedSquare = null;
      _legalTargets = const [];
      _playMoveSoundForFenTransition(oldWidget.state.activeFen, widget.state.activeFen);
    }
  }

  void _clearSelection() {
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

  String? _getSquareFromOffset(Offset localOffset, double boardSize) {
    final sqSize = boardSize / 8;
    final col = (localOffset.dx / sqSize).floor().clamp(0, 7);
    final row = (localOffset.dy / sqSize).floor().clamp(0, 7);
    return _getSquareName(row, col, widget.state.isBoardFlipped);
  }

  String _detectColor(PointerEvent event) {
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isControl = HardwareKeyboard.instance.isControlPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;
    if (isShift) return 'red';
    if (isAlt) return 'blue';
    if (isControl) return 'yellow';
    return 'green';
  }

  void _handleMarkupComplete(String start, String end) {
    final activeNodeIdx = widget.state.currentNodeIndex;
    if (activeNodeIdx == null) return;

    if (start == end) {
      // Circle Highlight
      final currentHighlights = widget.state.nodes[activeNodeIdx].highlights;
      final existing = currentHighlights.where((h) => h.square == end).firstOrNull;

      if (existing != null) {
        widget.notifier.addHighlight(activeNodeIdx, existing); // Remove
        // Cycle colors: green -> red -> blue -> yellow -> remove
        final colors = ['green', 'red', 'blue', 'yellow'];
        final nextIdx = (colors.indexOf(existing.color) + 1) % (colors.length + 1);
        if (nextIdx < colors.length) {
          widget.notifier.addHighlight(
            activeNodeIdx,
            BoardHighlight(square: end, color: colors[nextIdx]),
          );
        }
      } else {
        widget.notifier.addHighlight(
          activeNodeIdx,
          BoardHighlight(square: end, color: _currentColor),
        );
      }
    } else {
      // Arrow
      final arrow = BoardArrow(from: start, to: end, color: _currentColor);
      widget.notifier.addArrow(activeNodeIdx, arrow);
    }
  }

  Color _getHighlightColor(String colorName) {
    switch (colorName) {
      case 'red': return Colors.red.withValues(alpha: 0.25);
      case 'blue': return Colors.blue.withValues(alpha: 0.25);
      case 'yellow': return Colors.yellow.withValues(alpha: 0.25);
      case 'green':
      default:
        return Colors.green.withValues(alpha: 0.25);
    }
  }

  Widget _buildCoordinatesForSquare(int row, int col, bool isLight, bool isFlipped) {
    final showFile = row == 7;
    final showRank = col == 0;

    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    final fileIndex = isFlipped ? 7 - col : col;
    final rankIndex = isFlipped ? 7 - row : row;

    final color = isLight ? ScholarlyTheme.textMuted : Colors.white.withValues(alpha: 0.7);

    return Stack(
      children: [
        if (showFile)
          Positioned(
            bottom: 2,
            right: 4,
            child: Text(
              files[fileIndex],
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        if (showRank)
          Positioned(
            top: 2,
            left: 4,
            child: Text(
              ranks[rankIndex],
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
      ],
    );
  }

  void _handleSquareTap(String squareName, chess_lib.Chess chess) {
    if (widget.isEditorMode && widget.onSquareTap != null) {
      widget.onSquareTap!(squareName);
      return;
    }
    if (_selectedSquare != null && _legalTargets.contains(squareName)) {
      _handleMove(_selectedSquare!, squareName, chess);
    } else {
      final piece = chess.get(squareName);
      if (piece != null) {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceSelect);
        setState(() {
          _selectedSquare = squareName;
          _legalTargets = chess.generate_moves({'square': squareName})
              .map((m) => chess_lib.Chess.algebraic(m.to))
              .toList();
        });
      } else {
        _clearSelection();
      }
    }
  }

  void _handleMove(String from, String to, chess_lib.Chess chess) {
    final piece = chess.get(from);
    final isPawn = piece?.type == chess_lib.PieceType.PAWN;
    final isWhite = piece?.color == chess_lib.Color.WHITE;
    final isPromo = isPawn && ((isWhite && to.endsWith('8')) || (!isWhite && to.endsWith('1')));

    if (isPromo) {
      setState(() {
        _pendingPromoFrom = from;
        _pendingPromoTo = to;
      });
    } else {
      _executeMoveOrPromo(from, to, '', chess);
      ref.read(chessHapticsServiceProvider).selection();
      _clearSelection();
    }
  }

  void _executeMoveOrPromo(String from, String to, String promotion, chess_lib.Chess chess) {
    widget.notifier.makeMove(from, to, promotion);
  }

  void _playMoveSoundForFenTransition(String prevFen, String nextFen) {
    if (prevFen == nextFen) return;
    try {
      final prevChess = chess_lib.Chess.fromFEN(prevFen);
      
      final moves = prevChess.generate_moves();
      bool isGameMove = false;
      bool isCapture = false;
      bool isCastling = false;
      bool isPromotion = false;
      bool isCheck = false;

      for (final m in moves) {
        prevChess.move(m);
        if (prevChess.fen == nextFen) {
          isGameMove = true;
          isCapture = m.captured != null;
          isCastling = (m.flags & 32) != 0 || (m.flags & 64) != 0;
          isPromotion = m.promotion != null;
          isCheck = prevChess.in_check;
          prevChess.undo();
          break;
        }
        prevChess.undo();
      }

      final soundService = ref.read(chessSoundServiceProvider);
      if (isGameMove) {
        if (isCheck) {
          soundService.playSfx(SoundEffect.check);
        } else if (isPromotion) {
          soundService.playSfx(SoundEffect.promote);
        } else if (isCapture) {
          soundService.playSfx(SoundEffect.capture);
        } else if (isCastling) {
          soundService.playSfx(SoundEffect.castle);
        } else {
          soundService.playSfx(SoundEffect.move);
        }
      } else {
        soundService.playSfx(SoundEffect.uiNavigate);
      }
    } catch (e) {
      debugPrint("Error parsing chess FEN transition for sound: $e");
      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.move);
    }
  }

  @override
  Widget build(BuildContext context) {
    const theme = AnalysisClassicTheme();

    const bool isInteractionDisabled = false;

    final chess = chess_lib.Chess.fromFEN(widget.state.activeFen);

    final engineState = ref.watch(analysisEngineControllerProvider);
    final showEval = widget.showEvalBar && engineState.isEngineOn;
    const double evalBarWidth = 6.0;
    const double evalBarPadding = 4.0;
    final double actualBoardSize = showEval
        ? (widget.boardSize - evalBarWidth - evalBarPadding)
        : widget.boardSize;

    final squareSize = actualBoardSize / 8;

    String? lastMoveFrom;
    String? lastMoveTo;
    if (widget.state.currentNodeIndex != null && widget.state.currentNodeIndex! < widget.state.nodes.length) {
      final activeNode = widget.state.nodes[widget.state.currentNodeIndex!];
      if (activeNode.uci.length >= 4) {
        lastMoveFrom = activeNode.uci.substring(0, 2);
        lastMoveTo = activeNode.uci.substring(2, 4);
      }
    }

    final activeNode = widget.state.currentNodeIndex != null && widget.state.currentNodeIndex! < widget.state.nodes.length
        ? widget.state.nodes[widget.state.currentNodeIndex!]
        : null;

    final arrows = activeNode?.arrows ?? const [];
    final highlights = activeNode?.highlights ?? const [];

    // Temporary/Preview Arrow drawing list
    final List<BoardArrow> allArrows = List.from(arrows);
    if (_drawStartSquare != null && _hoverSquare != null && _drawStartSquare != _hoverSquare) {
      allArrows.add(BoardArrow(from: _drawStartSquare!, to: _hoverSquare!, color: _currentColor));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showEval) ...[
          // 1. Eval Bar
          EvalBar(
            evalScore: engineState.evalScore,
            isMate: engineState.isMate,
            mateIn: engineState.mateIn,
            isEngineOn: engineState.isEngineOn,
            isFlipped: widget.state.isBoardFlipped,
            height: actualBoardSize,
            width: evalBarWidth,
          ),
          const SizedBox(width: evalBarPadding),
        ],

        // 2. Chessboard
        Listener(
          onPointerDown: (event) {
            if (event.buttons == kSecondaryMouseButton) {
              final sq = _getSquareFromOffset(event.localPosition, actualBoardSize);
              setState(() {
                _drawStartSquare = sq;
                _currentColor = _detectColor(event);
              });
            }
          },
          onPointerMove: (event) {
            if (event.buttons == kSecondaryMouseButton && _drawStartSquare != null) {
              final sq = _getSquareFromOffset(event.localPosition, actualBoardSize);
              setState(() {
                _hoverSquare = sq;
              });
            }
          },
          onPointerUp: (event) {
            if (_drawStartSquare != null && event.buttons == 0) {
              final endSquare = _getSquareFromOffset(event.localPosition, actualBoardSize);
              if (endSquare != null) {
                _handleMarkupComplete(_drawStartSquare!, endSquare);
              }
              setState(() {
                _drawStartSquare = null;
                _hoverSquare = null;
              });
            }
          },
          child: GestureDetector(
            onLongPressStart: (details) {
              final sq = _getSquareFromOffset(details.localPosition, actualBoardSize);
              setState(() {
                _drawStartSquare = sq;
                _currentColor = 'green';
              });
            },
            onLongPressMoveUpdate: (details) {
              if (_drawStartSquare != null) {
                final sq = _getSquareFromOffset(details.localPosition, actualBoardSize);
                setState(() {
                  _hoverSquare = sq;
                });
              }
            },
            onLongPressEnd: (details) {
              if (_drawStartSquare != null) {
                final endSquare = _getSquareFromOffset(details.localPosition, actualBoardSize);
                if (endSquare != null) {
                  _handleMarkupComplete(_drawStartSquare!, endSquare);
                }
                setState(() {
                  _drawStartSquare = null;
                  _hoverSquare = null;
                });
              }
            },
            child: Container(
              width: actualBoardSize,
              height: actualBoardSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: ScholarlyTheme.boardShadow,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Frame / Background
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: theme.buildBackground(context, true),
                  ),

                  // Squares Grid Layout
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AbsorbPointer(
                      absorbing: isInteractionDisabled,
                      child: GridView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8,
                      ),
                      itemCount: 64,
                      itemBuilder: (context, index) {
                        final row = index ~/ 8;
                        final col = index % 8;
                        final isLight = (row + col) % 2 == 0;
                        final squareName = _getSquareName(row, col, widget.state.isBoardFlipped);

                        final isSelected = _selectedSquare == squareName;
                        final isTarget = _legalTargets.contains(squareName);
                        final isLastStart = lastMoveFrom == squareName;
                        final isLastEnd = lastMoveTo == squareName;

                        // Graphic circle highlight matching square
                        final highlight = highlights.where((h) => h.square == squareName).firstOrNull;
                        Color? highlightColor;
                        if (highlight != null) {
                          highlightColor = _getHighlightColor(highlight.color);
                        }

                        final piece = chess.get(squareName);
                        String? pieceCode;
                        if (piece != null) {
                          final colorPrefix = piece.color == chess_lib.Color.WHITE ? 'w' : 'b';
                          final typeStr = piece.type.toString().toUpperCase();
                          pieceCode = '$colorPrefix$typeStr';
                        }

                        return DragTarget<String>(
                          onWillAcceptWithDetails: (details) => _legalTargets.contains(squareName),
                          onAcceptWithDetails: (details) {
                            _handleMove(details.data, squareName, chess);
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isDragHover = candidateData.isNotEmpty;

                            Widget squareChild = Stack(
                              children: [
                                if (theme.getSquarePainter(isLight, 0) != null)
                                  CustomPaint(
                                    painter: theme.getSquarePainter(isLight, 0.0),
                                    size: Size.infinite,
                                  ),

                                // Circle highlight overlay
                                if (highlightColor != null)
                                  Container(color: highlightColor),

                                // Last move overlay (light green highlight)
                                if (isLastStart || isLastEnd)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0x73A3D28E), // Soft light green overlay
                                      border: isLastEnd
                                          ? Border.all(
                                              color: const Color(0xCCA3D28E),
                                              width: 1.5)
                                          : null,
                                    ),
                                  ),

                                // Selection glow
                                if (isSelected)
                                  Container(color: ScholarlyTheme.selectedGlow.withValues(alpha: 0.2)),

                                // Drag hover overlay
                                if (isDragHover)
                                  Container(color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.35)),

                                // Piece renderer
                                if (pieceCode != null)
                                  Center(
                                    child: Draggable<String>(
                                      data: squareName,
                                      onDragStarted: () {
                                        setState(() {
                                          _selectedSquare = squareName;
                                          _legalTargets = chess
                                              .generate_moves({'square': squareName})
                                              .map((m) => chess_lib.Chess.algebraic(m.to))
                                              .toList();
                                        });
                                      },
                                      onDraggableCanceled: (velocity, offset) => _clearSelection(),
                                      onDragEnd: (_) => _clearSelection(),
                                      feedback: Material(
                                        color: Colors.transparent,
                                        child: SizedBox(
                                          width: squareSize * 1.2,
                                          height: squareSize * 1.2,
                                          child: theme.buildPiece(
                                            context,
                                            pieceCode.substring(1),
                                            pieceCode.startsWith('w'),
                                            false,
                                            0,
                                          ),
                                        ),
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: 0.35,
                                        child: theme.buildPiece(
                                          context,
                                          pieceCode.substring(1),
                                          pieceCode.startsWith('w'),
                                          false,
                                          0,
                                        ),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _handleSquareTap(squareName, chess),
                                        child: theme.buildPiece(
                                          context,
                                          pieceCode.substring(1),
                                          pieceCode.startsWith('w'),
                                          isSelected,
                                          0,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _handleSquareTap(squareName, chess),
                                    child: const SizedBox.expand(),
                                  ),

                                // Targets dot indicators
                                if (isTarget)
                                  Center(
                                    child: Container(
                                      width: pieceCode != null ? 22 : 12,
                                      height: pieceCode != null ? 22 : 12,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: pieceCode != null
                                            ? Colors.transparent
                                            : ScholarlyTheme.accentBlue.withValues(alpha: 0.5),
                                        border: pieceCode != null
                                            ? Border.all(color: ScholarlyTheme.accentBlue, width: 2.2)
                                            : null,
                                      ),
                                    ),
                                  ),

                                _buildCoordinatesForSquare(row, col, isLight, widget.state.isBoardFlipped),
                              ],
                            );

                            return Container(
                              decoration: BoxDecoration(
                                color: isLight ? theme.lightSquare : theme.darkSquare,
                              ),
                              child: squareChild,
                            );
                          },
                        );
                      },
                    ),
                    ),
                  ),

                  // 3. Arrow Paint Overlay
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size(actualBoardSize, actualBoardSize),
                      painter: BoardArrowPainter(
                        arrows: allArrows,
                        isFlipped: widget.state.isBoardFlipped,
                      ),
                    ),
                  ),

                  // Premium Pawn Promotion Overlay
                  PromotionOverlay(
                    theme: theme,
                    isPromotingOverride: _pendingPromoFrom != null && _pendingPromoTo != null,
                    isWhiteOverride: _pendingPromoFrom != null
                        ? chess.get(_pendingPromoFrom!)?.color == chess_lib.Color.WHITE
                        : true,
                    onCompleteOverride: (piece) {
                      _executeMoveOrPromo(
                        _pendingPromoFrom!,
                        _pendingPromoTo!,
                        piece,
                        chess,
                      );
                      setState(() {
                        _pendingPromoFrom = null;
                        _pendingPromoTo = null;
                        _selectedSquare = null;
                        _legalTargets = const [];
                      });
                    },
                    onCancelOverride: () {
                      setState(() {
                        _pendingPromoFrom = null;
                        _pendingPromoTo = null;
                      });
                    },
                  ),


                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Draw graphical arrows compatible with standard chess applications
class BoardArrowPainter extends CustomPainter {
  final List<BoardArrow> arrows;
  final bool isFlipped;

  BoardArrowPainter({required this.arrows, required this.isFlipped});

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;

    for (final arrow in arrows) {
      final start = _getCenter(arrow.from, size.width);
      final rawEnd = _getCenter(arrow.to, size.width);

      final angle = atan2(rawEnd.dy - start.dy, rawEnd.dx - start.dx);

      // Shorten the end point slightly so arrowheads end just before the target piece center
      final end = Offset(
        rawEnd.dx - 18 * cos(angle),
        rawEnd.dy - 18 * sin(angle),
      );

      final paint = Paint()
        ..color = _getArrowColor(arrow.color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);

      // Draw Arrow Head triangle
      final arrowSize = squareSize * 0.25;
      final arrowPaint = Paint()
        ..color = _getArrowColor(arrow.color)
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(end.dx, end.dy);
      path.lineTo(
        end.dx - arrowSize * cos(angle - pi / 6),
        end.dy - arrowSize * sin(angle - pi / 6),
      );
      path.lineTo(
        end.dx - arrowSize * cos(angle + pi / 6),
        end.dy - arrowSize * sin(angle + pi / 6),
      );
      path.close();
      canvas.drawPath(path, arrowPaint);
    }
  }

  Offset _getCenter(String square, double width) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    final fileIndex = files.indexOf(square[0]);
    final rankIndex = ranks.indexOf(square[1]);

    final col = isFlipped ? 7 - fileIndex : fileIndex;
    final row = isFlipped ? 7 - rankIndex : rankIndex;

    final sqSize = width / 8;
    return Offset(
      col * sqSize + sqSize / 2,
      row * sqSize + sqSize / 2,
    );
  }

  Color _getArrowColor(String name) {
    switch (name) {
      case 'red': return Colors.red.withValues(alpha: 0.7);
      case 'blue': return Colors.blue.withValues(alpha: 0.7);
      case 'yellow': return Colors.yellow.withValues(alpha: 0.7);
      case 'green':
      default:
        return Colors.green.withValues(alpha: 0.7);
    }
  }

  @override
  bool shouldRepaint(covariant BoardArrowPainter oldDelegate) {
    return oldDelegate.arrows != arrows || oldDelegate.isFlipped != isFlipped;
  }
}

// Side evaluation bar widget
class EvalBar extends StatelessWidget {
  final double? evalScore;
  final bool isMate;
  final int? mateIn;
  final bool isEngineOn;
  final bool isFlipped;
  final double height;
  final double width;

  const EvalBar({
    super.key,
    required this.evalScore,
    required this.isMate,
    required this.mateIn,
    required this.isEngineOn,
    required this.isFlipped,
    required this.height,
    this.width = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!isEngineOn) {
      return const SizedBox.shrink();
    }

    final score = evalScore ?? 0.0;
    final capped = score.clamp(-10.0, 10.0);

    // Default perspective: Black top, White bottom
    // If flipped: White top, Black bottom
    double whiteRatio = 0.5 + (capped / 20.0);
    if (isMate && mateIn != null) {
      whiteRatio = mateIn! > 0 ? 0.95 : 0.05;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: 0.5, end: whiteRatio),
          builder: (context, value, child) {
            final topHeightShare = isFlipped ? value : (1.0 - value);

            return Stack(
              children: [
                // Top Color Fill
                Container(
                  color: isFlipped ? Colors.white : Colors.black,
                ),
                // Bottom Color Fill
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: 1.0 - topHeightShare,
                    child: Container(
                      color: isFlipped ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
