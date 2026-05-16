import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'widgets/game_controls.dart';
import 'widgets/board_stage.dart';
import '../domain/models/ai_avatar.dart';
import 'widgets/opponent_avatar_indicator.dart';
import 'widgets/global_sidebar.dart';
import 'widgets/arena_time_display.dart';
import 'widgets/avatar_selection_sheet.dart';
import 'widgets/arena_turn_indicator.dart';
import 'widgets/evaluation_bar.dart';
import 'widgets/user_avatar_indicator.dart';

class ZenArenaPage extends ConsumerStatefulWidget {
  const ZenArenaPage({super.key});

  @override
  ConsumerState<ZenArenaPage> createState() => _ZenArenaPageState();
}

class _ZenArenaPageState extends ConsumerState<ZenArenaPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ConfettiController _confettiController;
  bool _hasTriggeredConfetti = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final chessState = ref.read(chessProvider);
      if (chessState.recentMoves.isNotEmpty && !chessState.game.gameOver) {
        ref.read(chessProvider.notifier).saveCurrentGame();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final bool? confirm = await _showExitConfirmation(context);
        if (confirm == true) {
          if (state.recentMoves.isNotEmpty) {
            await ref.read(chessProvider.notifier).saveCurrentGame();
          }
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: ScholarlyTheme.backgroundStart,
        drawer: const GlobalSidebar(),
        body: Stack(
          children: [
            _buildPortraitLayout(context, ref, state),
            if ((state.game.gameOver || state.isTimeOut) && !state.isGameOverDismissed)
              _buildGameOverOverlay(context, ref, state),
            
            // Confetti Layer
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  ScholarlyTheme.accentGold,
                  ScholarlyTheme.accentBlue,
                  Colors.white,
                  Colors.yellow,
                ],
                createParticlePath: (size) {
                  final path = Path();
                  path.addRect(Rect.fromLTWH(0, 0, size.width, size.height / 2));
                  return path;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, WidgetRef ref, ChessState state) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isTurn = _isPlayerTurn(state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Top Row: Stats & Clocks
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 32,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ArenaTurnIndicator(isActive: isTurn, isWhite: state.isPlayerWhite),
                      const SizedBox(width: 8),
                      EvaluationBar(fillFraction: _getEvalFraction(state, true)),
                    ],
                  ),
                  const Spacer(),
                  ArenaTimeDisplay(isActive: isTurn, timeLeft: state.isPlayerWhite ? state.whiteTimeLeft : state.blackTimeLeft),
                  const SizedBox(width: 12),
                  ArenaTimeDisplay(isActive: !isTurn, timeLeft: state.isPlayerWhite ? state.blackTimeLeft : state.whiteTimeLeft),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EvaluationBar(fillFraction: _getEvalFraction(state, false)),
                      const SizedBox(width: 8),
                      ArenaTurnIndicator(isActive: !isTurn, isWhite: !state.isPlayerWhite),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Opponent
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
        // Board
        Expanded(
          child: Stack(
            children: [
              const BoardStage(isExpanded: false),
              if (state.isPaused) _buildPauseOverlay(context, ref),
            ],
          ),
        ),
        // User
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: state.isEngineVsEngine
                ? OpponentAvatarIndicator(
                    avatar: AiAvatar.getAvatar(state.bottomAvatarId),
                    onTap: () => showAvatarSelectionSheet(context, ref, isBottomSlot: true),
                  )
                : const UserAvatarIndicator(),
          ),
        ),
        // Actions
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

  Widget _buildActionRow(BuildContext context, WidgetRef ref, ChessState state) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionIconButton(
            icon: Icons.menu_rounded,
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: Icons.add_box_rounded, // UNRATED uses +
            onTap: () => _handleNewGame(context, ref),
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: Icons.undo_rounded,
            isEnabled: state.canUndo,
            onTap: state.canUndo ? () => ref.read(chessProvider.notifier).undo() : null,
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: Icons.redo_rounded,
            isEnabled: state.canRedo,
            onTap: state.canRedo ? () => ref.read(chessProvider.notifier).redo() : null,
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: Icons.flip_camera_android_outlined,
            isActive: state.isBoardFlipped,
            onTap: () => ref.read(chessProvider.notifier).toggleBoardOrientation(),
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            isActive: state.isPaused,
            onTap: () => ref.read(chessProvider.notifier).togglePause(),
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: state.isEngineVsEngine ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
            isActive: state.isEngineVsEngine,
            onTap: () => ref.read(chessProvider.notifier).toggleEngineVsEngine(),
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: Icons.save_rounded,
            onTap: () => _handleSaveGame(context, ref),
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: state.isBulbGlowing ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
            isEnabled: !state.isHintLoading,
            isActive: state.isBulbGlowing,
            activeColor: ScholarlyTheme.accentYellowSoft,
            activeIconColor: ScholarlyTheme.accentYellow,
            onTap: () => ref.read(chessProvider.notifier).requestHint(),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseOverlay(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: GestureDetector(
                onTap: () => ref.read(chessProvider.notifier).togglePause(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.accentBlue,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'RESUME GAME',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, WidgetRef ref, ChessState state) {
    final isDraw = state.game.inDraw;
    final didWin = _didPlayerWin(state);
    
    if (didWin && !_hasTriggeredConfetti) {
      _hasTriggeredConfetti = true;
      _confettiController.play();
    }

    String title = isDraw ? 'Match Draw' : (didWin ? 'Victory!' : 'Match Lost');
    String msg = isDraw 
        ? 'A well-fought strategic stalemate.' 
        : (didWin ? 'Congratulations, you have dominated the arena!' : 'Defeat is but a stepping stone to mastery.');
    
    if (state.isTimeOut) {
      title = didWin ? 'Victory (Time)' : 'Loss (Time)';
      msg = didWin ? 'Opponent ran out of time!' : 'You ran out of time!';
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(32),
            decoration: ScholarlyTheme.modernDecoration().copyWith(
              border: Border.all(color: didWin ? ScholarlyTheme.accentGold : ScholarlyTheme.accentBlue, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!(state.isTimeOut && !didWin))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(title.toUpperCase(), 
                      style: GoogleFonts.inter(
                        color: didWin ? ScholarlyTheme.accentGold : ScholarlyTheme.textPrimary, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 24, 
                        letterSpacing: 1.5
                      )
                    ),
                  ),
                Icon(
                  isDraw ? Icons.handshake_rounded : (didWin ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded), 
                  size: 64, 
                  color: didWin ? ScholarlyTheme.accentGold : ScholarlyTheme.accentBlue
                ),
                const SizedBox(height: 20),
                Text(msg, style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                const SizedBox(height: 32),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            _hasTriggeredConfetti = false;
                          });
                          ref.read(chessProvider.notifier).reset();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: didWin ? ScholarlyTheme.accentGold : ScholarlyTheme.accentBlue,
                          foregroundColor: didWin ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('PLAY NEW MATCH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(chessProvider.notifier).dismissGameOver();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ScholarlyTheme.textMuted,
                          side: BorderSide(color: ScholarlyTheme.panelStroke),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('REVIEW BOARD', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _didPlayerWin(ChessState state) {
    if (state.game.inDraw) return false;
    
    if (state.isTimeOut) {
      final playerTimedOut = state.isPlayerWhite 
          ? state.whiteTimeLeft <= Duration.zero 
          : state.blackTimeLeft <= Duration.zero;
      return !playerTimedOut;
    }

    // Standard game over
    return !_isPlayerTurn(state);
  }

  bool _isPlayerTurn(ChessState state) {
    if (state.game.fen.split(' ').length > 1) {
      final turnWhite = state.game.fen.split(' ')[1] == 'w';
      return state.isPlayerWhite == turnWhite;
    }
    return true;
  }

  double _getEvalFraction(ChessState state, bool forPlayer) {
    final eval = forPlayer ? (state.isPlayerWhite ? state.currentEvaluation : -state.currentEvaluation) : (state.isPlayerWhite ? -state.currentEvaluation : state.currentEvaluation);
    return (eval.clamp(-5.0, 5.0) + 5.0) / 10.0;
  }

  Future<void> _handleNewGame(BuildContext context, WidgetRef ref) async {
    if (ref.read(chessProvider).recentMoves.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          title: const Text('New Game?'),
          content: const Text('Start a new game? Progress will be saved.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('New Game')),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await ref.read(chessProvider.notifier).reset();
  }

  Future<void> _handleSaveGame(BuildContext context, WidgetRef ref) async {
    final entry = await ref.read(chessProvider.notifier).saveCurrentGame();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(entry != null ? 'Saved' : 'Failed'), backgroundColor: ScholarlyTheme.accentBlue));
    }
  }

  Future<bool?> _showExitConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        title: const Text('Exit Kingslayer?'),
        content: const Text('Do you want to quit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Continue')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Quit')),
        ],
      ),
    );
  }
}
