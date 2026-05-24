import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../../application/chess_provider.dart';
import '../../domain/chess_game.dart';
import '../scholarly_theme.dart';

import '../shared/themes/chess_theme.dart';
import '../shared/widgets/chess_piece_widget.dart';
import '../shared/widgets/orbiting_star_animation.dart';
import '../shared/widgets/promotion_overlay.dart';
import '../shared/animations/signature_move_overlay.dart';
import '../shared/animations/landing_feedback.dart';
import '../shared/animations/tap_ripple.dart';
import '../shared/animations/piece_motion_profile.dart';
import '../shared/animations/shake_animation.dart';

import 'themes/academy_classic_theme.dart';

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

  // Tap ripple entries: board-local top-left Offset of the tapped square
  final List<Offset> _tapRipples = [];

  // Landing micro-settle entries: {square, profile, row, col}
  final List<Map<String, dynamic>> _landingFeedbacks = [];

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);
    const chessTheme = AcademyClassicTheme();

    // Use currentBoardFen for display during analysis/history viewing
    final displayGame = ChessGame(fen: chessState.currentBoardFen);

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

                  if (chessState.game.inCheck)
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
                                          if (isSelected)
                                            const OrbitingStarAnimation(
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
                                              ref
                                                  .read(
                                                    chessProvider.notifier,
                                                  )
                                                  .isAnimationTypeEnabled(
                                                    'indicators',
                                                  ))
                                            const OrbitingStarAnimation(
                                              color:
                                                  ScholarlyTheme.accentGold,
                                              isActive: true,
                                            ),
                                          if (isThreatened && !isSuggestionTarget && !isGlow &&
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
                                            ),
                                          if (isGlow)
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
                                                  isSuggestedTo))
                                            const OrbitingStarAnimation(
                                              color:
                                                  ScholarlyTheme.accentYellow,
                                              isActive: true,
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
                                              child: ChessPieceWidget(
                                                squareName: squareName,
                                                highlighted: isSelected,
                                                rotation: 0.0,
                                                theme: chessTheme,
                                                isMoving:
                                                    chessState
                                                            .moveAnimation
                                                            ?.from ==
                                                        squareName ||
                                                    chessState
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
                    ),

                  PromotionOverlay(theme: chessTheme),
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
    final haptics = ref.read(chessHapticsServiceProvider);
    haptics.selection();
    final chessState = ref.read(chessProvider);
    final displayGame = ChessGame(fen: chessState.currentBoardFen);

    // Tap ripple on every tap (gated by animations setting)
    if (ref.read(chessProvider.notifier).isAnimationTypeEnabled('feedback')) {
      _triggerTapRipple(squareName);
    }

    if (_selectedSquare != null && _legalTargets.contains(squareName)) {
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

    final isWhiteTurn = displayGame.turn == chess_lib.Color.WHITE;
    if (piece.color == chess_lib.Color.WHITE && !isWhiteTurn) {
      _clearSelection();
      return;
    }
    if (piece.color == chess_lib.Color.BLACK && isWhiteTurn) {
      _clearSelection();
      return;
    }

    // Lock board controls if game is over, it's AI turn, or engine vs engine
    final isGameOver = chessState.game.gameOver;
    final isAiTurn = _isAiTurn(chessState);
    final isEvE = chessState.isEngineVsEngine;
    if (isGameOver || isAiTurn || isEvE) {
      _clearSelection();
      return;
    }

    setState(() {
      _selectedSquare = squareName;
      _legalTargets = displayGame.legalDestinations(squareName);
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedSquare = null;
      _legalTargets = const [];
    });
  }

  bool _isAiTurn(ChessState state) {
    if (!state.isAiOperational) return false;
    final fenParts = state.game.fen.split(' ');
    if (fenParts.length > 1) {
      final turnWhite = fenParts[1] == 'w';
      return state.isPlayerWhite != turnWhite;
    }
    return false;
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

  const AcademySuggestionOverlay({
    super.key,
    required this.data,
    required this.boardSize,
    required this.isFlipped,
    required this.trigger,
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
      duration: const Duration(milliseconds: 1000),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _startAnimation();
  }

  void _startAnimation() {
    setState(() => _isVisible = true);
    _controller.reset();
    _controller.forward().then((_) {
      // Auto-vanish the whole overlay after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _isVisible = false);
      });
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

    return IgnorePointer(
      child: Stack(
        children: [
          // 1. Animated Scholarly Arrow
          CustomPaint(
            size: Size(widget.boardSize, widget.boardSize),
            painter: AcademyArrowPainter(
              from: fromPos + Offset(squareSize / 2, squareSize / 2),
              to: toPos + Offset(squareSize / 2, squareSize / 2),
              progress: _animation.value,
            ),
          ),

          // 2. Gliding Ghost Piece
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              // Quadratic Bezier path for ghost piece (matching the arrow)
              final p0 = fromPos;
              final p2 = toPos;
              final p1 = Offset(
                (p0.dx + p2.dx) / 2,
                (p0.dy + p2.dy) / 2 - 30, // Arc matching AcademyArrowPainter
              );

              final t = _animation.value;
              final currentPos = Offset(
                (1 - t) * (1 - t) * p0.dx +
                    2 * (1 - t) * t * p1.dx +
                    t * t * p2.dx,
                (1 - t) * (1 - t) * p0.dy +
                    2 * (1 - t) * t * p1.dy +
                    t * t * p2.dy,
              );

              // Fade in at start, fade out at end (to reveal stationary ghost)
              double opacity = 0.4;
              if (t < 0.2) opacity = (t / 0.2) * 0.4;
              if (t > 0.8) opacity = 0.4 - ((t - 0.8) / 0.2) * 0.4;

              return Positioned(
                left: currentPos.dx,
                top: currentPos.dy,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: squareSize,
                    height: squareSize,
                    padding: const EdgeInsets.all(4),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/pieces/${widget.data.pieceCode}.svg',
                        fit: BoxFit.contain,
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

  AcademyArrowPainter({
    required this.from,
    required this.to,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final paint = Paint()
      ..color = ScholarlyTheme.accentBlue.withValues(alpha: 0.4)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final controlPoint = Offset(
      (from.dx + to.dx) / 2,
      (from.dy + to.dy) / 2 - 30,
    );

    final path = Path()..moveTo(from.dx, from.dy);

    // Draw the path up to the current progress
    if (progress < 1.0) {
      // Approximate quadratic bezier for animation
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

    canvas.drawPath(path, paint);

    // Arrowhead (only show if progress > 0.8)
    if (progress > 0.8) {
      final t = progress;
      final headOpacity = (t - 0.8) / 0.2;

      final paintHead = Paint()
        ..color = ScholarlyTheme.accentBlue.withValues(alpha: 0.4 * headOpacity)
        ..style = PaintingStyle.fill;

      // Current direction at the tip of the path
      final dx = 2 * (1 - t) * (controlPoint.dx - from.dx) +
          2 * t * (to.dx - controlPoint.dx);
      final dy = 2 * (1 - t) * (controlPoint.dy - from.dy) +
          2 * t * (to.dy - controlPoint.dy);
      final angle = Offset(dx, dy).direction;

      const arrowSize = 12.0;
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
      oldDelegate.from != from ||
      oldDelegate.to != to;
}

class AcademySquareGlow extends StatefulWidget {
  final Color color;

  const AcademySquareGlow({super.key, required this.color});

  @override
  State<AcademySquareGlow> createState() => _AcademySquareGlowState();
}

class _AcademySquareGlowState extends State<AcademySquareGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
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
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.6 * (1.0 - _controller.value)),
                blurRadius: 20 * _controller.value,
                spreadRadius: 10 * _controller.value,
              ),
            ],
            border: Border.all(
              color: widget.color.withValues(alpha: 0.8 * (1.0 - _controller.value)),
              width: 2,
            ),
          ),
        );
      },
    );
  }
}
