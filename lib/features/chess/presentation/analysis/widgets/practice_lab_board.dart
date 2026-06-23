import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../../../application/chess_provider.dart';
import '../../../application/study_lab_provider.dart';
import '../../../application/practice_lab_provider.dart';
import '../../../services/chess_sound_service.dart';
import '../../scholarly_theme.dart';
import '../themes/analysis_classic_theme.dart';

class PracticeLabBoard extends ConsumerStatefulWidget {
  final double boardSize;
  final bool? isFlippedOverride;

  const PracticeLabBoard({
    super.key,
    required this.boardSize,
    this.isFlippedOverride,
  });

  @override
  ConsumerState<PracticeLabBoard> createState() => _PracticeLabBoardState();
}

class _PracticeLabBoardState extends ConsumerState<PracticeLabBoard>
    with SingleTickerProviderStateMixin {
  String? _selectedSquare;
  List<String> _legalTargets = const [];

  late final AnimationController _promoAnimController;
  late final Animation<double> _promoScaleAnim;
  late final Animation<double> _promoFadeAnim;
  bool _wasPromoPending = false;

  @override
  void initState() {
    super.initState();
    _promoAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _promoScaleAnim = CurvedAnimation(
      parent: _promoAnimController,
      curve: Curves.easeOutBack,
    );
    _promoFadeAnim = CurvedAnimation(
      parent: _promoAnimController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _promoAnimController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PracticeLabBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear selection if the FEN has updated outside
    _selectedSquare = null;
    _legalTargets = const [];
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

  void _handleSquareTap(String squareName, chess_lib.Chess chess, bool isInteractionAllowed) {
    if (!isInteractionAllowed) return;

    if (_selectedSquare != null && _legalTargets.contains(squareName)) {
      _handleMove(_selectedSquare!, squareName, chess);
    } else {
      final piece = chess.get(squareName);
      final state = ref.read(practiceLabProvider);
      final playerColor = state.isPlayerWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;
      if (piece != null && piece.color == playerColor) {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceSelect);
        if (ref.read(chessProvider).isHapticsEnabled) {
          ref.read(chessHapticsServiceProvider).selection();
        }
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
      // Clear selection first so no stale highlight shows behind the promo overlay.
      _clearSelection();
      ref.read(practiceLabProvider.notifier).setPendingPromo(from, to);
    } else {
      ref.read(practiceLabProvider.notifier).makePlayerMove(from, to);
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    const theme = AnalysisClassicTheme();

    final studyState = ref.watch(studyLabProvider);
    final state = ref.watch(practiceLabProvider);
    final viewingMoveIndex = state.viewingMoveIndex;
    final fen = state.isSessionActive
        ? (viewingMoveIndex != null
            ? ref.read(practiceLabProvider.notifier).getFenAtMove(viewingMoveIndex)
            : state.fen)
        : studyState.activeFen;
    final chess = chess_lib.Chess.fromFEN(fen);
    final squareSize = widget.boardSize / 8;

    String? lastMoveFrom;
    String? lastMoveTo;
    final targetMoveIndex = viewingMoveIndex ?? (state.moveHistory.length - 1);
    if (state.moveHistory.isNotEmpty && targetMoveIndex >= 0 && targetMoveIndex < state.moveHistory.length) {
      final lastMove = state.moveHistory[targetMoveIndex];
      if (lastMove.length >= 4) {
        lastMoveFrom = lastMove.substring(0, 2);
        lastMoveTo = lastMove.substring(2, 4);
      }
    }

    final isPlayerTurn = (chess.turn == chess_lib.Color.WHITE) == state.isPlayerWhite;
    // Block interaction when the user is reviewing past moves (viewingMoveIndex != null)
    // so that historical board positions cannot be accidentally interacted with.
    final isInteractionAllowed = isPlayerTurn &&
        !state.isEngineThinking &&
        !state.isGameOver &&
        state.isSessionActive &&
        state.viewingMoveIndex == null;
    final playerColor = state.isPlayerWhite ? chess_lib.Color.WHITE : chess_lib.Color.BLACK;
    final isFlipped = widget.isFlippedOverride ?? state.isBoardFlipped;
    final isMobile = MediaQuery.of(context).size.width <= 800;
    final borderRadius = isMobile ? BorderRadius.zero : BorderRadius.circular(16);
    final boxShadow = isMobile ? null : ScholarlyTheme.boardShadow;

    return Center(
      child: Container(
        width: widget.boardSize,
        height: widget.boardSize,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: boxShadow,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Frame / Background
            ClipRRect(
              borderRadius: borderRadius,
              child: theme.buildBackground(context, true),
            ),

            // Squares Grid
            ClipRRect(
              borderRadius: borderRadius,
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
                  final squareName = _getSquareName(row, col, isFlipped);

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
                          if (theme.getSquarePainter(isLight, 0) != null)
                            CustomPaint(
                              painter: theme.getSquarePainter(isLight, 0.0),
                              size: Size.infinite,
                            ),

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
                              child: (isInteractionAllowed && piece?.color == playerColor)
                                  ? Draggable<String>(
                                      data: squareName,
                                      onDragStarted: () {
                                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceSelect);
                                        if (ref.read(chessProvider).isHapticsEnabled) {
                                          ref.read(chessHapticsServiceProvider).selection();
                                        }
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
                                        onTap: () => _handleSquareTap(squareName, chess, isInteractionAllowed),
                                        child: theme.buildPiece(
                                          context,
                                          pieceCode.substring(1),
                                          pieceCode.startsWith('w'),
                                          isSelected,
                                          0,
                                        ),
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () => _handleSquareTap(squareName, chess, isInteractionAllowed),
                                      child: theme.buildPiece(
                                        context,
                                        pieceCode.substring(1),
                                        pieceCode.startsWith('w'),
                                        isSelected,
                                        0,
                                      ),
                                    ),
                            )
                          else
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _handleSquareTap(squareName, chess, isInteractionAllowed),
                              child: const SizedBox.expand(),
                            ),

                          // Target dots
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

                          _buildCoordinatesForSquare(row, col, isLight, isFlipped),
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

            // Promotion overlay
            if (state.pendingPromoFrom != null && state.pendingPromoTo != null) ...[
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: borderRadius,
                  child: GestureDetector(
                    onTap: () {
                      _clearSelection();
                      ref.read(practiceLabProvider.notifier).setPendingPromo(null, null);
                    },
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _promoAnimController,
                  builder: (context, child) {
                    // Trigger the entrance animation whenever the promo panel
                    // transitions from hidden → visible.
                    final isPending = state.pendingPromoFrom != null;
                    if (isPending && !_wasPromoPending) {
                      _wasPromoPending = true;
                      // Reset and play the animation from zero so it always
                      // triggers even if it was interrupted previously.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _promoAnimController.forward(from: 0);
                        }
                      });
                    } else if (!isPending && _wasPromoPending) {
                      // Panel dismissed — reset flag and controller so next
                      // promotion shows the animation cleanly.
                      _wasPromoPending = false;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _promoAnimController.reset();
                      });
                    }
                    return FadeTransition(
                      opacity: _promoFadeAnim,
                      child: ScaleTransition(
                        scale: _promoScaleAnim,
                        child: child,
                      ),
                    );
                  },
                  child: ClipRRect(
                  borderRadius: borderRadius,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: borderRadius,
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
                              final isWhite = chess.get(state.pendingPromoFrom!)?.color == chess_lib.Color.WHITE;
                              return GestureDetector(
                                onTap: () {
                                  // Clear local selection first so the board state
                                  // is clean before any provider rebuild fires.
                                  _clearSelection();
                                  ref.read(practiceLabProvider.notifier).makePlayerMove(
                                    state.pendingPromoFrom!,
                                    state.pendingPromoTo!,
                                    type.toLowerCase(),
                                  );
                                  ref.read(practiceLabProvider.notifier).setPendingPromo(null, null);
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
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _clearSelection();
                              ref.read(practiceLabProvider.notifier).setPendingPromo(null, null);
                            },
                            child: Text(
                              'TAP OUTSIDE TO CANCEL',
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.textMuted,
                                fontSize: 9,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
