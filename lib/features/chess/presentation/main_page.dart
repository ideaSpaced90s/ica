import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../application/chess_provider.dart';
import 'chess_clock.dart';
import 'scholarly_theme.dart';
import 'widgets/commentary_history.dart';

import 'widgets/game_controls.dart';
import 'widgets/board_stage.dart';
import 'settings_page.dart';
import '../domain/models/ai_avatar.dart';
import 'widgets/opponent_avatar_indicator.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage>
    with WidgetsBindingObserver {
  bool _isCommentaryExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final chessState = ref.read(chessProvider);
      // Auto-save only if game has started and not over
      if (chessState.recentMoves.isNotEmpty && !chessState.game.gameOver) {
        ref.read(chessProvider.notifier).saveCurrentGame();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: ScholarlyTheme.panelBase,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Exit Kingslayer?',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: ScholarlyTheme.textPrimary,
              ),
            ),
            content: Text(
              'Do you want to quit? Your current game progress will be saved automatically.',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Continue Play',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Quit',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          final chessState = ref.read(chessProvider);
          if (chessState.recentMoves.isNotEmpty) {
            await ref.read(chessProvider.notifier).saveCurrentGame();
          }
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
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
        const SizedBox(height: 16),
        // Original Master Top Row: Both Players' Turn Indicators, Eval Bars, and Clocks
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _KnightTurnIndicator(
                    isActive: _isPlayerTurn(state),
                    isWhite: state.isPlayerWhite,
                  ),
                  const SizedBox(width: 8),
                  _VerticalEvaluationBar(
                    fillFraction: ((
                      (state.isPlayerWhite ? state.currentEvaluation : -state.currentEvaluation)
                      .clamp(-5.0, 5.0) + 5.0) / 10.0),
                  ),
                ],
              ),
              const Spacer(),
              _KnightTimeDisplay(
                isActive: _isPlayerTurn(state),
                timeLeft: state.isPlayerWhite
                    ? state.whiteTimeLeft
                    : state.blackTimeLeft,
              ),
              const SizedBox(width: 12),
              _KnightTimeDisplay(
                isActive: !_isPlayerTurn(state),
                timeLeft: state.isPlayerWhite
                    ? state.blackTimeLeft
                    : state.whiteTimeLeft,
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _VerticalEvaluationBar(
                    fillFraction: ((
                      (state.isPlayerWhite ? -state.currentEvaluation : state.currentEvaluation)
                      .clamp(-5.0, 5.0) + 5.0) / 10.0),
                  ),
                  const SizedBox(width: 8),
                  _KnightTurnIndicator(
                    isActive: !_isPlayerTurn(state),
                    isWhite: !state.isPlayerWhite,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Top-Left aligned Opponent Avatar Indicator Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OpponentAvatarIndicator(
              avatar: AiAvatar.getAvatar(state.engineLevel),
              onTap: () => showAvatarSelectionSheet(context, ref, isBottomSlot: false),
            ),
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
          Expanded(child: const BoardStage(isExpanded: false)),

        // Bottom Side Footer Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bottom-Left: Circular AI Chat toggle icon
              GestureDetector(
                onTap: () {
                  setState(() => _isCommentaryExpanded = !_isCommentaryExpanded);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isCommentaryExpanded 
                        ? ScholarlyTheme.accentBlueSoft 
                        : ScholarlyTheme.panelBase,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isCommentaryExpanded 
                          ? ScholarlyTheme.accentBlue 
                          : ScholarlyTheme.panelStroke,
                      width: 1.5,
                    ),
                    boxShadow: ScholarlyTheme.cardShadow,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: _isCommentaryExpanded 
                        ? ScholarlyTheme.accentBlue 
                        : ScholarlyTheme.accentBlue.withValues(alpha: 0.8),
                    size: 20,
                  ),
                ),
              ),
              // Bottom-Right: Switchable User/Bot indicator
              Flexible(
                child: state.isEngineVsEngine
                    ? OpponentAvatarIndicator(
                        avatar: AiAvatar.getAvatar(state.bottomAvatarId),
                        onTap: () => showAvatarSelectionSheet(context, ref, isBottomSlot: true),
                      )
                    : const _UserAvatarIndicator(),
              ),
            ],
          ),
        ),

        // Chat Area (Expanded view)
        if (_isCommentaryExpanded)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildCommentaryPanel(context, ref, state),
            ),
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
            icon: Icons.save_rounded,
            onTap: () async {
              final entry = await ref
                  .read(chessProvider.notifier)
                  .saveCurrentGame();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      entry != null
                          ? 'Game saved successfully.'
                          : 'Failed to save game.',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: entry != null
                        ? ScholarlyTheme.accentBlue
                        : Colors.redAccent,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 6),
          ActionIconButton(
            icon: state.isBulbGlowing
                ? Icons.lightbulb_rounded
                : Icons.lightbulb_outline_rounded,
            isEnabled: !state.isHintLoading,
            isActive: state.isBulbGlowing,
            activeColor: ScholarlyTheme.accentYellowSoft,
            activeIconColor: ScholarlyTheme.accentYellow,
            onTap: () => ref.read(chessProvider.notifier).requestHint(),
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
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          content: Text(
            'Start a new game? Your current game progress will be saved automatically to history.',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textPrimary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
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
                'New Game',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Game saved to history.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: ScholarlyTheme.accentBlue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    await ref.read(chessProvider.notifier).reset();
  }
}



class _KnightTimeDisplay extends StatelessWidget {
  final bool isActive;
  final Duration timeLeft;

  const _KnightTimeDisplay({required this.isActive, required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ScholarlyTheme.modernDecoration(sunken: !isActive).copyWith(
        color: isActive
            ? ScholarlyTheme.panelBase
            : ScholarlyTheme.backgroundEnd,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? ScholarlyTheme.accentBlue
              : ScholarlyTheme.panelStroke,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive ? ScholarlyTheme.cardShadow : [],
      ),
      child: ChessClock(isActive: isActive, timeLeft: timeLeft),
    );
  }
}

class _KnightTurnIndicator extends StatefulWidget {
  final bool isActive;
  final bool isWhite;

  const _KnightTurnIndicator({required this.isActive, required this.isWhite});

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
    final pieceAsset = widget.isWhite
        ? 'assets/pieces/wN.svg'
        : 'assets/pieces/bN.svg';
    final accentColor = widget.isWhite
        ? Colors.blueAccent
        : Colors.orangeAccent;

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
                        ),
                      ]
                    : [],
              ),
              padding: const EdgeInsets.all(6),
              child: SvgPicture.asset(
                pieceAsset,
                colorFilter: widget.isActive
                    ? null
                    : ColorFilter.mode(
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

class _VerticalEvaluationBar extends StatelessWidget {
  final double fillFraction; // 0.0 to 1.0

  const _VerticalEvaluationBar({required this.fillFraction});

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors;
    Color glowColor;

    if (fillFraction > 0.55) {
      gradientColors = [const Color(0xFF00C853), const Color(0xFF69F0AE)];
      glowColor = const Color(0xFF00C853);
    } else if (fillFraction < 0.45) {
      gradientColors = [const Color(0xFFD50000), const Color(0xFFFF5252)];
      glowColor = const Color(0xFFD50000);
    } else {
      gradientColors = [const Color(0xFFFFD600), const Color(0xFFFFE57F)];
      glowColor = const Color(0xFFFFD600);
    }

    final targetHeight = 40.0 * fillFraction.clamp(0.08, 1.0);

    return Container(
      width: 8,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: 8,
        height: targetHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.4),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatarIndicator extends ConsumerStatefulWidget {
  const _UserAvatarIndicator();

  @override
  ConsumerState<_UserAvatarIndicator> createState() => _UserAvatarIndicatorState();
}

class _UserAvatarIndicatorState extends ConsumerState<_UserAvatarIndicator> {
  bool _isExpanded = false;
  Timer? _collapseTimer;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
      _collapseTimer?.cancel();
      _collapseTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _isExpanded = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final isRated = state.isRatedMode;
    final primaryColor = isRated ? Colors.amber : ScholarlyTheme.textMuted;
    final bgColor = isRated ? Colors.amber.withValues(alpha: 0.15) : ScholarlyTheme.panelStroke;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: _isExpanded ? 12 : 8,
          vertical: 6,
        ),
        decoration: ScholarlyTheme.modernDecoration().copyWith(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primaryColor.withValues(alpha: _isExpanded ? 0.8 : 0.4),
            width: 1.5,
          ),
          boxShadow: [
            if (isRated)
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Styled Avatar Icon ring
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isRated ? Icons.emoji_events_rounded : Icons.person_outline_rounded,
                  color: primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              // Always visible tiny rating/status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  isRated ? '${state.userFideRating} ELO' : 'UNRATED',
                  style: GoogleFonts.jetBrainsMono(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Expanding Contents
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                child: _isExpanded
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 8),
                          // Name & Subtitle
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isRated ? 'Competitor' : 'Casual Player',
                                    style: GoogleFonts.inter(
                                      color: ScholarlyTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (state.currentWinningStreak > 0 && isRated) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.deepOrangeAccent,
                                      size: 12,
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                isRated
                                    ? 'Games: ${state.ratedGamesCount}'
                                    : 'Stats Disabled',
                                style: GoogleFonts.inter(
                                  color: ScholarlyTheme.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
