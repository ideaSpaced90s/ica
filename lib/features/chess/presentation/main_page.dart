import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../application/chess_provider.dart';
import 'evaluation_bar.dart';
import 'chess_clock.dart';
import 'scholarly_theme.dart';
import 'widgets/commentary_history.dart';

import 'widgets/game_controls.dart';
import 'widgets/board_stage.dart';
import 'settings_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  bool _isCommentaryExpanded = false;

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);

    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: Stack(
        children: [
          _buildPortraitLayout(context, ref, chessState),

          if (chessState.game.gameOver && !chessState.isGameOverDismissed)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: ScholarlyTheme.modernDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Game Over',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Icon(
                          chessState.game.inDraw
                              ? Icons.handshake_rounded
                              : (_getGameOverMessage(chessState) ==
                                        'Congratulations'
                                    ? Icons.emoji_events_rounded
                                    : Icons.sentiment_dissatisfied_rounded),
                          size: 48,
                          color: ScholarlyTheme.accentBlue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          chessState.game.inDraw
                              ? 'Game Draw. New game?'
                              : '${_getGameOverMessage(chessState)}. New game?',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FilledButton(
                              onPressed: () {
                                ref.read(chessProvider.notifier).reset();
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: ScholarlyTheme.accentBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Yes',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(chessProvider.notifier)
                                    .dismissGameOver();
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'No',
                                style: GoogleFonts.inter(
                                  color: ScholarlyTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isPlayerTurn(ChessState state) {
    if (state.game.fen.split(' ').length > 1) {
      final turnWhite = state.game.fen.split(' ')[1] == 'w';
      return state.isPlayerWhite == turnWhite;
    }
    return true; // Default fallback
  }

  String _getGameOverMessage(ChessState state) {
    if (state.game.inDraw) {
      return 'Game Draw';
    }
    if (_isPlayerTurn(state)) {
      return 'Try again';
    } else {
      return 'Congratulations';
    }
  }



  Widget _buildPortraitLayout(
    BuildContext context,
    WidgetRef ref,
    ChessState state,
  ) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPortraitHeader(context, ref, state),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
          child: EvaluationBar(evaluation: state.currentEvaluation),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _KnightTurnIndicator(
                isActive: _isPlayerTurn(state),
                isWhite: state.isPlayerWhite,
              ),
              const Spacer(),
              _KnightTimeDisplay(
                isActive: _isPlayerTurn(state),
                timeLeft: state.isPlayerWhite ? state.whiteTimeLeft : state.blackTimeLeft,
              ),
              const SizedBox(width: 12),
              _KnightTimeDisplay(
                isActive: !_isPlayerTurn(state),
                timeLeft: state.isPlayerWhite ? state.blackTimeLeft : state.whiteTimeLeft,
              ),
              const Spacer(),
              _KnightTurnIndicator(
                isActive: !_isPlayerTurn(state),
                isWhite: !state.isPlayerWhite,
              ),
            ],
          ),
        ),
        // Board Area
        if (_isCommentaryExpanded)
          Flexible(
            flex: isKeyboardOpen ? 1 : 0,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: BoardStage(isExpanded: true),
            ),
          )
        else
          Expanded(
            child: const BoardStage(isExpanded: false),
          ),

        // Chat Area
        if (_isCommentaryExpanded)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildCommentaryPanel(context, ref, state),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildCollapsedCommentaryHeader(context, ref, state),
          ),
        if (!isKeyboardOpen) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: _buildActionRow(context, ref, state),
          ),
        ],
      ],
    );
  }

  Widget _buildPortraitHeader(
    BuildContext context,
    WidgetRef ref,
    ChessState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(chessProvider.notifier).toggleAiOperational(),
                child: _AiProfileAnimation(
                  isOperational: state.isAiOperational,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/board/profile.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'KINGSLAYER',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          Text(
            'powered by ideaspace',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildActionRow(
    BuildContext context,
    WidgetRef ref,
    ChessState state,
  ) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionIconButton(
            icon: Icons.add_box_rounded,
            onTap: () => _handleNewGame(context, ref),
          ),
          const SizedBox(width: 6),
          ActionIconButton(
            icon: Icons.tune_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 6),
          ActionIconButton(
            icon: Icons.undo_rounded,
            isEnabled: state.canUndo,
            onTap: state.canUndo
                ? () => ref.read(chessProvider.notifier).undo()
                : null,
          ),
          const SizedBox(width: 6),
          ActionIconButton(
            icon: Icons.redo_rounded,
            isEnabled: state.canRedo,
            onTap: state.canRedo
                ? () => ref.read(chessProvider.notifier).redo()
                : null,
          ),
          const SizedBox(width: 10),
          ActionIconButton(
            icon: Icons.flip_camera_android_outlined,
            isActive: state.isBoardFlipped,
            onTap: () =>
                ref.read(chessProvider.notifier).toggleBoardOrientation(),
          ),
          const SizedBox(width: 6),
          ActionIconButton(
            icon: state.isEngineVsEngine
                ? Icons.smart_toy_rounded
                : Icons.smart_toy_outlined,
            isActive: state.isEngineVsEngine,
            onTap: () {
              ref.read(chessProvider.notifier).toggleEngineVsEngine();
              // If we enable engine vs engine, we might want to flip board to side to move
              // but staying as is is also fine as per user request (persist until clicked again).
            },
          ),
          const SizedBox(width: 6),
          ActionIconButton(
            icon: state.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            isActive: state.isPaused,
            onTap: () => ref.read(chessProvider.notifier).togglePause(),
          ),
          const SizedBox(
            width: 12,
          ), // Reduced spacing slightly instead of Spacer
          ActionIconButton(
            icon: Icons.bolt_rounded,
            onTap: () => _showStrengthOverlay(context, ref),
          ),
          const SizedBox(width: 6),
          ActionIconButton(
            icon: state.isHintVisible
                ? Icons.lightbulb_rounded
                : Icons.lightbulb_outline_rounded,
            isEnabled: true,
            isActive: state.isHintVisible,
            onTap: () {
              // Placeholder: Navigation to analysis page removed
            },
          ),
          if (_isCommentaryExpanded) ...[
            const SizedBox(width: 6),
            ActionIconButton(
              icon: state.showLog
                  ? Icons.chat_bubble_outline_rounded
                  : Icons.history_edu_rounded,
              isActive: state.showLog,
              onTap: () => ref.read(chessProvider.notifier).toggleLog(),
            ),
            const SizedBox(width: 6),
            ActionIconButton(
              icon: Icons.close_rounded,
              onTap: () {
                setState(() => _isCommentaryExpanded = false);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentaryPanel(
    BuildContext context,
    WidgetRef ref,
    ChessState state,
  ) {
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4), // Reduced padding
      child: state.showLog
          ? _buildMoveLog(context, state)
          : CommentaryHistory(state: state),
    );
  }

  Widget _buildCollapsedCommentaryHeader(
    BuildContext context,
    WidgetRef ref,
    ChessState state,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _isCommentaryExpanded = true);
        if (!state.isPaused) {
          ref.read(chessProvider.notifier).togglePause();
        }
      },
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: _buildCommentaryHeader(context, ref, state, isExpanded: false),
      ),
    );
  }

  Widget _buildCommentaryHeader(
    BuildContext context,
    WidgetRef ref,
    ChessState state, {
    required bool isExpanded,
  }) {
    return Row(
      children: [
        const Spacer(),
        _buildHeaderIconButton(
          icon: state.showLog
              ? Icons.chat_bubble_outline_rounded
              : Icons.history_edu_rounded,
          onTap: () => ref.read(chessProvider.notifier).toggleLog(),
          isActive: state.showLog,
        ),
        const SizedBox(width: 6),
        _buildHeaderIconButton(
          icon: isExpanded
              ? Icons.close_rounded
              : Icons.keyboard_arrow_up_rounded,
          onTap: () {
            setState(() {
              _isCommentaryExpanded = !isExpanded;
              if (_isCommentaryExpanded && !state.isPaused) {
                ref.read(chessProvider.notifier).togglePause();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: ScholarlyTheme.modernDecoration().copyWith(
          color: isActive
              ? ScholarlyTheme.accentBlueSoft
              : ScholarlyTheme.panelBase,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? ScholarlyTheme.accentBlue
                : ScholarlyTheme.panelStroke,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          color: isActive
              ? ScholarlyTheme.accentBlue
              : ScholarlyTheme.textPrimary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMoveLog(BuildContext context, ChessState state) {
    final moves = state.recentMoves;
    if (moves.isEmpty) {
      return const Center(
        child: Text(
          'Log is empty.',
          style: TextStyle(
            color: ScholarlyTheme.textMuted,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final List<List<String>> pairs = [];
    for (int i = 0; i < moves.length; i += 2) {
      pairs.add([moves[i], if (i + 1 < moves.length) moves[i + 1]]);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: pairs.length,
      itemBuilder: (context, index) {
        final pair = pairs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}.',
                  style: GoogleFonts.jetBrainsMono(
                    color: ScholarlyTheme.accentBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  pair[0],
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
              if (pair.length > 1)
                Expanded(
                  child: Text(
                    pair[1],
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        );
      },
    );
  }


  Future<void> _handleNewGame(BuildContext context, WidgetRef ref) async {
    final state = ref.read(chessProvider);
    final bool hasProgress = state.recentMoves.isNotEmpty;

    if (hasProgress) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'New Game?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'All progress in current game will be lost if not saved.',
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'No',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Yes',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    await ref.read(chessProvider.notifier).reset();
  }

  void _showStrengthOverlay(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final currentLevel = ref.watch(chessProvider).engineLevel;
            return Padding(
              padding: const EdgeInsets.all(16),
              child: GlassPanel(
                padding: const EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engine Strength',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['A', 'B', 'C', 'D', 'E'].map((level) {
                          final isSelected = currentLevel == level;
                          return InkWell(
                            onTap: () {
                              ref
                                  .read(chessProvider.notifier)
                                  .setEngineLevel(level);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ScholarlyTheme.accentBlue
                                    : ScholarlyTheme.panelBase,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? ScholarlyTheme.accentBlue
                                      : ScholarlyTheme.panelStroke,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  level,
                                  style: GoogleFonts.inter(
                                    color: isSelected
                                        ? Colors.white
                                        : ScholarlyTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'A: Grandmaster (Strongest)  |  E: Beginner (Weakest)',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
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

}

class _AiProfileAnimation extends StatefulWidget {
  final bool isOperational;
  final Widget child;

  const _AiProfileAnimation({required this.isOperational, required this.child});

  @override
  State<_AiProfileAnimation> createState() => _AiProfileAnimationState();
}

class _AiProfileAnimationState extends State<_AiProfileAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(
      begin: 1.0,
      end: 4.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isOperational) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AiProfileAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOperational != oldWidget.isOperational) {
      if (widget.isOperational) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    if (!widget.isOperational) {
      // Grayscale Matrix
      content = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: content,
      );
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            boxShadow: widget.isOperational
                ? [
                    BoxShadow(
                      color: ScholarlyTheme.accentBlue.withValues(
                        alpha: 0.3 * (1.0 - _controller.value),
                      ),
                      blurRadius: _glowAnimation.value * 2,
                      spreadRadius: _glowAnimation.value / 2,
                    ),
                  ]
                : null,
          ),
          child: child,
        );
      },
      child: content,
    );
  }
}



class _KnightTimeDisplay extends StatelessWidget {
  final bool isActive;
  final Duration timeLeft;

  const _KnightTimeDisplay({
    required this.isActive,
    required this.timeLeft,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ScholarlyTheme.modernDecoration(sunken: !isActive).copyWith(
        color: isActive ? ScholarlyTheme.panelBase : ScholarlyTheme.backgroundEnd,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive ? ScholarlyTheme.cardShadow : [],
      ),
      child: ChessClock(
        isActive: isActive,
        timeLeft: timeLeft,
      ),
    );
  }
}

class _KnightTurnIndicator extends StatefulWidget {
  final bool isActive;
  final bool isWhite;

  const _KnightTurnIndicator({
    required this.isActive,
    required this.isWhite,
  });

  @override
  State<_KnightTurnIndicator> createState() => _KnightTurnIndicatorState();
}

class _KnightTurnIndicatorState extends State<_KnightTurnIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isActive) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_KnightTurnIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive) {
      _controller.stop();
      _controller.animateTo(0, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isWhite ? Colors.black87 : Colors.white;
    final pieceAsset = widget.isWhite ? 'assets/pieces/wN.svg' : 'assets/pieces/bN.svg';
    final accentColor = widget.isWhite ? Colors.blueAccent : Colors.orangeAccent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isActive
                      ? accentColor.withValues(alpha: 0.8)
                      : Colors.grey.withValues(alpha: 0.3),
                  width: widget.isActive ? 3 : 1.5,
                ),
                boxShadow: widget.isActive
                    ? [
                        BoxShadow(
                          color: accentColor.withValues(
                            alpha: 0.4 * _controller.value,
                          ),
                          blurRadius: 12 * _controller.value,
                          spreadRadius: 4 * _controller.value,
                        )
                      ]
                    : [],
              ),
              padding: const EdgeInsets.all(6),
              child: SvgPicture.asset(
                pieceAsset,
                colorFilter: widget.isActive ? null : ColorFilter.mode(
                  Colors.grey.withValues(alpha: 0.5),
                  BlendMode.srcIn,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
