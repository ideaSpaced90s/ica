import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chess/chess.dart' as chess_lib;

import 'scholarly_theme.dart';
import 'shared/widgets/orbiting_star_animation.dart';
import '../application/tutorial_provider.dart';
import '../application/chess_provider.dart';
import '../services/chess_sound_service.dart';
import '../domain/models/tutorial_lesson.dart';
import 'widgets/tutorial_board_overlay.dart';
import 'arena/themes/theme_registry.dart';

class TutorialBoardStage extends ConsumerStatefulWidget {
  const TutorialBoardStage({super.key});

  @override
  ConsumerState<TutorialBoardStage> createState() => _TutorialBoardStageState();
}

class _TutorialBoardStageState extends ConsumerState<TutorialBoardStage> with SingleTickerProviderStateMixin {
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSquareTap(String squareName, TutorialState state, TutorialNotifier notifier) {
    notifier.clearIllegalFeedback();

    if (state.currentStep.type == TutorialStepType.awaitSquareTap) {
      notifier.handleSquareTap(squareName);
      return;
    }

    if (state.currentStep.type == TutorialStepType.awaitMove) {
      // 1. If no piece selected yet, see if tapped square has a piece of our turn
      if (_selectedSquare == null) {
        final piece = state.board.get(squareName);
        if (piece != null && piece.color == state.board.turn) {
          // Verify if piece has potential matching target lines to explore
          final expected = state.currentStep.expectedMove;
          if (expected != null && expected.startsWith(squareName)) {
            setState(() {
              _selectedSquare = squareName;
              // Provide visual tracking dot hint on target square cleanly
              _legalTargets = [expected.substring(2, 4)];
            });
          } else {
            // General piece preview feedback
            setState(() {
              _selectedSquare = squareName;
              _legalTargets = [];
            });
            // Treat selecting off-script piece as hesitation/mistake loop
            notifier.handleMoveAttempt(squareName, squareName);
          }
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceSelect);
        }
      } else {
        // 2. Target destination selected
        final source = _selectedSquare!;
        setState(() {
          _selectedSquare = null;
          _legalTargets = const [];
        });
        
        if (source != squareName) {
          notifier.handleMoveAttempt(source, squareName);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);
    final notifier = ref.read(tutorialProvider.notifier);
    final theme = ThemeRegistry.getTheme('classic'); // Universal crisp default

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = math.min(constraints.maxWidth, constraints.maxHeight);
        final double sqSize = boardSize / 8;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Base UI grid layer
                Container(
                  decoration: BoxDecoration(
                    boxShadow: ScholarlyTheme.boardShadow,
                    border: Border.all(color: ScholarlyTheme.boardFrame, width: 2),
                  ),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                    ),
                    padding: EdgeInsets.zero,
                    itemCount: 64,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final row = index ~/ 8;
                      final col = index % 8;
                      final isLight = (row + col) % 2 == 0;
                      final squareName = _getSquareName(row, col);

                      final isSelected = _selectedSquare == squareName;
                      final isTargetHint = _legalTargets.contains(squareName);
                      final pieceObj = state.board.get(squareName);

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _handleSquareTap(squareName, state, notifier),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: isLight ? theme.lightSquare : theme.darkSquare,
                            border: Border.all(
                              color: isSelected
                                  ? ScholarlyTheme.accentGold
                                  : Colors.transparent,
                              width: isSelected ? 3.0 : 0.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Target hint dot indicator
                              if (isTargetHint)
                                Center(
                                  child: Container(
                                    width: sqSize * 0.3,
                                    height: sqSize * 0.3,
                                    decoration: BoxDecoration(
                                      color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.8),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: ScholarlyTheme.accentBlue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // Selected square orbiting star overlay
                              if (isSelected)
                                const OrbitingStarAnimation(
                                  color: ScholarlyTheme.accentGold,
                                  isActive: true,
                                ),

                              // Piece rendering engine
                              if (pieceObj != null)
                                Center(
                                  child: SizedBox(
                                    width: sqSize * 0.95,
                                    height: sqSize * 0.95,
                                    child: theme.buildPiece(
                                      context,
                                      pieceObj.type.toUpperCase(),
                                      pieceObj.color == chess_lib.Color.WHITE,
                                      false,
                                      0.0,
                                    ),
                                  ),
                                ),

                              // Scholarly clean coordinate margin overlay
                              if (col == 0 || row == 7)
                                _buildSimpleCoordinate(row, col, isLight),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: TutorialBoardOverlayPainter(
                          effect: state.currentStep.overlayEffect,
                          highlightSquares: state.highlightSquares,
                          animatePathSquares: state.animatePathSquares,
                          glowSquare: state.glowSquare,
                          dangerZone: state.dangerZone,
                          animationProgress: _pulseController.value,
                        ),
                        size: Size(boardSize, boardSize),
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

  String _getSquareName(int row, int col) {
    final fileChar = String.fromCharCode('a'.codeUnitAt(0) + col);
    final rankChar = String.fromCharCode('1'.codeUnitAt(0) + (7 - row));
    return '$fileChar$rankChar';
  }

  Widget _buildSimpleCoordinate(int row, int col, bool isLight) {
    final textColor = isLight ? Colors.black54 : Colors.white70;
    return Stack(
      children: [
        if (col == 0) // Rank numbers left
          Positioned(
            top: 2,
            left: 3,
            child: Text(
              '${8 - row}',
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (row == 7) // File letters bottom
          Positioned(
            bottom: 2,
            right: 3,
            child: Text(
              String.fromCharCode('a'.codeUnitAt(0) + col),
              style: TextStyle(
                color: textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
