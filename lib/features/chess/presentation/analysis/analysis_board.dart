import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../../application/chess_provider.dart';
import '../../application/study_lab_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import '../arena/themes/theme_registry.dart';

class StudyLabChessBoard extends ConsumerStatefulWidget {
  final StudyLabState state;
  final StudyLabNotifier notifier;
  final double boardSize;

  const StudyLabChessBoard({
    super.key,
    required this.state,
    required this.notifier,
    required this.boardSize,
  });

  @override
  ConsumerState<StudyLabChessBoard> createState() => _StudyLabChessBoardState();
}

class _StudyLabChessBoardState extends ConsumerState<StudyLabChessBoard> {
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  String? _pendingPromoFrom;
  String? _pendingPromoTo;

  @override
  void didUpdateWidget(StudyLabChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.activeFen != widget.state.activeFen) {
      _selectedSquare = null;
      _legalTargets = const [];
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
      final isCapture = chess.get(to) != null;
      widget.notifier.makeMove(from, to);
      
      if (isCapture) {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.capture);
      } else {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.move);
      }
      ref.read(chessHapticsServiceProvider).selection();
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);
    final themeId = ThemeRegistry.resolveThemeId(chessState);
    final theme = ThemeRegistry.getTheme(themeId);

    final chess = chess_lib.Chess.fromFEN(widget.state.activeFen);
    final squareSize = widget.boardSize / 8;

    String? lastMoveFrom;
    String? lastMoveTo;
    if (widget.state.currentNodeIndex != null && widget.state.currentNodeIndex! < widget.state.nodes.length) {
      final activeNode = widget.state.nodes[widget.state.currentNodeIndex!];
      if (activeNode.uci.length >= 4) {
        lastMoveFrom = activeNode.uci.substring(0, 2);
        lastMoveTo = activeNode.uci.substring(2, 4);
      }
    }

    return Container(
      width: widget.boardSize,
      height: widget.boardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: ScholarlyTheme.boardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background board frame / theme
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: theme.buildBackground(context, true),
          ),
          
          // Grid layer
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                        // Custom painter if theme defined
                        if (theme.getSquarePainter(isLight, 0) != null)
                          CustomPaint(
                            painter: theme.getSquarePainter(isLight, 0.0),
                            size: Size.infinite,
                          ),
                          
                        // Sibling last played move highlights
                        if (isLastStart || isLastEnd)
                          Container(
                            decoration: BoxDecoration(
                              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.12),
                              border: isLastEnd ? Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.5), width: 1.5) : null,
                            ),
                          ),

                        // Selection glowing overlay
                        if (isSelected)
                          Container(
                            color: ScholarlyTheme.selectedGlow.withValues(alpha: 0.2),
                          ),

                        // Drag hover highlighted square
                        if (isDragHover)
                          Container(
                            color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.35),
                          ),

                        // Render piece inside the square
                        if (pieceCode != null)
                          Center(
                            child: Draggable<String>(
                              data: squareName,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: squareSize * 1.2,
                                  height: squareSize * 1.2,
                                  child: theme.buildPiece(context, pieceCode.substring(1), pieceCode.startsWith('w'), false, 0),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.35,
                                child: theme.buildPiece(context, pieceCode.substring(1), pieceCode.startsWith('w'), false, 0),
                              ),
                              child: GestureDetector(
                                onTap: () => _handleSquareTap(squareName, chess),
                                child: theme.buildPiece(
                                  context, 
                                  pieceCode.substring(1), 
                                  pieceCode.startsWith('w'), 
                                  isSelected, 
                                  0
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

                        // Interactive target dot indicators
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

                        // Board coordinate labeling
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

          // Glowing Promotion Overlay over the grid board
          if (_pendingPromoFrom != null && _pendingPromoTo != null) ...[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
                      boxShadow: ScholarlyTheme.cardShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CHOOSE ASCENSION',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.5,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: ['Q', 'N', 'R', 'B'].map((type) {
                            final isWhite = chess.get(_pendingPromoFrom!)?.color == chess_lib.Color.WHITE;
                            return GestureDetector(
                              onTap: () {
                                widget.notifier.makeMove(
                                  _pendingPromoFrom!,
                                  _pendingPromoTo!,
                                  type.toLowerCase(),
                                );
                                setState(() {
                                  _pendingPromoFrom = null;
                                  _pendingPromoTo = null;
                                  _selectedSquare = null;
                                  _legalTargets = const [];
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
                                  boxShadow: ScholarlyTheme.cardShadow,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: theme.buildPiece(context, type, isWhite, false, 0),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
