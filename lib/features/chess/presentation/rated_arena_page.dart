import 'dart:math' as math;
import 'dart:ui';
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
import 'rated_settings_page.dart';
import 'widgets/arena_time_display.dart';
import 'widgets/arena_turn_indicator.dart';
import 'widgets/evaluation_bar.dart';
import 'widgets/user_avatar_indicator.dart';
import 'widgets/dice_rolling_overlay.dart';

class RatedArenaPage extends ConsumerStatefulWidget {
  const RatedArenaPage({super.key});

  @override
  ConsumerState<RatedArenaPage> createState() => _RatedArenaPageState();
}

class _RatedArenaPageState extends ConsumerState<RatedArenaPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasShownRatedCaution = false;
  bool _isDiceRolling = false;
  bool _assignedWhite = true;

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
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);

    // One-time Rated Caution Popup
    if (!_hasShownRatedCaution) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted && !_hasShownRatedCaution) {
          setState(() => _hasShownRatedCaution = true);
          await _showRatedCautionDialog(context);
          _triggerDiceRoll();
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final isMatchActive = state.recentMoves.isNotEmpty && !state.game.gameOver;
        if (isMatchActive) {
          final resigned = await _showRatedExitDialog(context);
          if (resigned == true) {
            await ref.read(chessProvider.notifier).resignRatedGame();
            SystemNavigator.pop();
          }
        } else {
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
            if (state.game.gameOver && !state.isGameOverDismissed)
              _buildGameOverOverlay(context, ref, state),
            if (_isDiceRolling)
              DiceRollingOverlay(
                isWhite: _assignedWhite,
                onComplete: _onDiceRollComplete,
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
        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
        // Opponent
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OpponentAvatarIndicator(
              avatar: AiAvatar.getAvatar(state.engineLevel),
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
            child: const UserAvatarIndicator(),
          ),
        ),
        // Rated Actions (5 icons, Dice in middle, special sizes)
        if (!isKeyboardOpen) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: _buildRatedActionRow(context, ref, state),
          ),
        ],
      ],
    );
  }

  Widget _buildRatedActionRow(BuildContext context, WidgetRef ref, ChessState state) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActionIconButton(
            icon: Icons.menu_rounded,
            size: 22,
            onTap: () async {
              if (state.recentMoves.isNotEmpty && !state.game.gameOver) {
                final resigned = await _showRatedExitDialog(context);
                if (resigned == true) {
                  await ref.read(chessProvider.notifier).resignRatedGame();
                  _scaffoldKey.currentState?.openDrawer();
                }
              } else {
                _scaffoldKey.currentState?.openDrawer();
              }
            },
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: Icons.timer_rounded,
            size: 22,
            onTap: () => _showTimeControlSelector(context, ref),
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: Icons.casino_rounded, // RATED uses Dice
            size: 30, // 20% reduction logic
            onTap: () async {
              if (state.recentMoves.isNotEmpty && !state.game.gameOver) {
                final resigned = await _showRatedNewGameDialog(context);
                if (resigned == true) {
                  await ref.read(chessProvider.notifier).resignRatedGame();
                  _triggerDiceRoll();
                }
              } else {
                _triggerDiceRoll();
              }
            },
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            isActive: state.isPaused,
            size: 22,
            onTap: () => ref.read(chessProvider.notifier).togglePause(),
          ),
          const SizedBox(width: 8),
          ActionIconButton(
            icon: Icons.settings_suggest_rounded,
            activeColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
            activeIconColor: ScholarlyTheme.accentBlue,
            isActive: true,
            size: 22,
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RatedSettingsPage()));
            },
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
                      BoxShadow(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.4), blurRadius: 15, spreadRadius: 2),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text('RESUME GAME', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2)),
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
    final msg = state.game.inDraw ? 'Game Draw' : (_isPlayerTurn(state) ? 'Try again' : 'Congratulations');
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: ScholarlyTheme.modernDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Game Over', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 16),
                Icon(state.game.inDraw ? Icons.handshake_rounded : (msg == 'Congratulations' ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded), size: 48, color: ScholarlyTheme.accentBlue),
                const SizedBox(height: 16),
                Text('$msg. New game?', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: () {
                        ref.read(chessProvider.notifier).dismissGameOver();
                        _triggerDiceRoll();
                      },
                      style: FilledButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue, foregroundColor: Colors.white),
                      child: const Text('Yes'),
                    ),
                    const SizedBox(width: 16),
                    TextButton(onPressed: () => ref.read(chessProvider.notifier).dismissGameOver(), child: Text('No', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _triggerDiceRoll() {
    setState(() {
      _isDiceRolling = true;
      _assignedWhite = math.Random().nextBool();
    });
  }

  void _onDiceRollComplete() {
    if (mounted) {
      ref.read(chessProvider.notifier).reset(forcedPlayerWhite: _assignedWhite);
      setState(() => _isDiceRolling = false);
    }
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

  Future<bool?> _showRatedExitDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        surfaceTintColor: ScholarlyTheme.accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2), width: 1)),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.logout_rounded, color: ScholarlyTheme.accentBlue, size: 24)),
          const SizedBox(height: 16),
          Text('Resign & Exit?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary, fontSize: 20)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Are you sure you wish to leave the match?', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('As this is a sanctioned Rated Arena game, exiting now will result in an automatic Loss and a deduction from your competitive ELO rating.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12, height: 1.5)),
        ]),
        actions: [
          Row(children: [
            Expanded(child: TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('STAY & PLAY'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue, foregroundColor: Colors.white), child: const Text('RESIGN'))),
          ]),
        ],
      ),
    );
  }

  Future<bool?> _showRatedNewGameDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        surfaceTintColor: ScholarlyTheme.accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2), width: 1)),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.refresh_rounded, color: ScholarlyTheme.accentBlue, size: 24)),
          const SizedBox(height: 16),
          Text('Start New Match?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary, fontSize: 20)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('A decision must be made regarding your current sanctioned game.', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text('Starting a new match now requires you to formally Resign from the present game. This will be recorded as a loss and will affect your competitive rating.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12, height: 1.5)),
        ]),
        actions: [
          Row(children: [
            Expanded(child: TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue, foregroundColor: Colors.white), child: const Text('RESIGN'))),
          ]),
        ],
      ),
    );
  }

  Future<void> _showRatedCautionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        surfaceTintColor: ScholarlyTheme.accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2), width: 1)),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.shield_rounded, color: ScholarlyTheme.accentBlue, size: 24)),
          const SizedBox(height: 16),
          Text('Rated Arena Entry', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary, fontSize: 20)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Welcome to the competitive arena.', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Every match played here is recorded for your professional standing. Resigning or abandoning a game prematurely will negatively impact your ELO rating.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12, height: 1.6)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: ScholarlyTheme.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('I AM READY', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Exit page
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'I AM NOT READY',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeControlSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(chessProvider);
            final notifier = ref.read(chessProvider.notifier);
            final presets = [
              {'label': '1+0', 'min': 1, 'inc': 0},
              {'label': '3+0', 'min': 3, 'inc': 0},
              {'label': '3+2', 'min': 3, 'inc': 2},
              {'label': '10+0', 'min': 10, 'inc': 0},
              {'label': '10+5', 'min': 10, 'inc': 5},
              {'label': '5+25', 'min': 5, 'inc': 25},
            ];

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: ScholarlyTheme.panelBase, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border.all(color: ScholarlyTheme.panelStroke)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sanctioned Time Control', style: GoogleFonts.inter(color: ScholarlyTheme.accentBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presets.map((p) {
                      final isSelected = state.whiteTimeLeft.inMinutes == p['min'] && state.incrementDuration.inSeconds == p['inc'];
                      return ChoiceChip(label: Text(p['label'] as String), selected: isSelected, onSelected: (selected) { if (selected) { notifier.setTimeControl(Duration(minutes: p['min'] as int), Duration(seconds: p['inc'] as int)); Navigator.pop(context); } }, selectedColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.2), labelStyle: GoogleFonts.inter(color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal));
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
