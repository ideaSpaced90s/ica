import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/battleground_provider.dart';
import '../../application/store_provider.dart';
import '../mobile_navigation_shell.dart';
import '../scholarly_theme.dart';
import '../widgets/game_controls.dart';
import '../widgets/premium_nudge_overlay.dart';
import 'battleground_board.dart';
import '../../domain/models/ai_avatar.dart';
import '../widgets/opponent_avatar_indicator.dart';
import '../widgets/arena_time_display.dart';
import '../widgets/arena_turn_indicator.dart';
import '../widgets/evaluation_bar.dart';
import '../widgets/user_avatar_indicator.dart';
import '../widgets/captured_pieces_inline.dart';
import '../widgets/dice_rolling_overlay.dart';
import '../widgets/ambient_flow_backdrop.dart';
import '../widgets/ambient_scaffold.dart';
import '../widgets/tabbed_game_panel.dart';
import 'package:confetti/confetti.dart';
import '../dashboard_page.dart';
import '../../application/onboarding_provider.dart';
import '../../application/tutorial_provider.dart';
import '../widgets/gm_chanakya_intro_overlay.dart';
import '../widgets/neural_connectivity_mesh.dart';
import '../widgets/countdown_overlay.dart';

class BattlegroundPage extends ConsumerStatefulWidget {
  const BattlegroundPage({super.key});

  @override
  ConsumerState<BattlegroundPage> createState() => _BattlegroundPageState();
}

class _BattlegroundPageState extends ConsumerState<BattlegroundPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _hasShownRatedCaution = false;
  bool _wasVisible = false;
  bool _isDiceRolling = false;
  bool _assignedWhite = true;
  late ConfettiController _confettiController;
  late ConfettiController _confettiBottomController;
  bool _hasTriggeredConfetti = false;
  bool _isCountdownActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiBottomController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(backButtonOverridesProvider.notifier).update((map) => {
          ...map,
          2: _handleBackPress,
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _confettiBottomController.dispose();
    ref.read(backButtonOverridesProvider.notifier).update((map) {
      final newMap = Map<int, Future<bool> Function()>.from(map);
      newMap.remove(2);
      return newMap;
    });
    super.dispose();
  }

  Future<bool> _handleBackPress() async {
    final bgState = ref.read(battlegroundProvider);
    final isMatchActive = bgState.activeRatedMatchId != null;
    if (isMatchActive) {
      final resigned = await showRatedExitDialog(context);
      if (resigned == true) {
        await ref.read(battlegroundProvider.notifier).resignRatedGame();
        return false; // let the default exit to dashboard happen

      }
      return true; // stay on page
    }
    return false; // let the default exit to dashboard happen
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final bgState = ref.read(battlegroundProvider);
      if (bgState.activeRatedMatchId != null) {
        ref.read(battlegroundProvider.notifier).resignRatedGame();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(battlegroundProvider);

    final storeState = ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);
    final isPremium = storeState.isPremium;
    final isLimitReached = !isPremium && !storeNotifier.canPlayRatedGame() && state.activeRatedMatchId == null;

    if (isLimitReached) {
      return const PremiumNudgeOverlay(
        isFullScreen: true,
        title: 'Daily Rated Game Limit Reached',
        description: 'You have played your 1 free Rated/Battleground game for today. Upgrade to unlock unlimited games.',
      );
    }

    ref.listen<BattlegroundState>(battlegroundProvider, (previous, next) {
      final wasGameOver = (previous?.game.gameOver ?? false) || (previous?.isTimeOut ?? false);
      final isGameOver = next.game.gameOver || next.isTimeOut;
      final isDismissed = next.isGameOverDismissed;
      final wasDismissed = previous?.isGameOverDismissed ?? false;

      if (isGameOver && !wasGameOver) {
        if (_didPlayerWin(next) && !_hasTriggeredConfetti) {
          setState(() {
            _hasTriggeredConfetti = true;
          });
          _confettiController.play();
          _confettiBottomController.play();
        }
      } else if (!isGameOver || (isDismissed && !wasDismissed)) {
        setState(() {
          _hasTriggeredConfetti = false;
        });
      }
    });

    final showIntro = ref.watch(showBattlegroundIntroProvider);
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
    final currentNavIndex = ref.watch(mobileNavIndexProvider);
    final isVisible = currentNavIndex == 2; // Tab 2 in MobileNavigationShell is BattlegroundPage

    ref.listen<int>(mobileNavIndexProvider, (previous, current) {
      if (previous == 2 && current != 2) {
        final repo = ref.read(tutorialProgressRepositoryProvider);
        if (!repo.shouldPersistIntroSeen()) {
          ref.read(showBattlegroundIntroProvider.notifier).state = true;
        }
      }
    });

    if (isVisible && !_wasVisible) {
      _wasVisible = true;
      if (state.activeRatedMatchId == null) {
        _hasShownRatedCaution = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(battlegroundProvider.notifier).clearBoard();
          }
        });
      }
    } else if (!isVisible && _wasVisible) {
      _wasVisible = false;
    }

    // One-time Rated Caution Popup, only show if this page/tab is currently active/visible to the user, the Chanakya intro has been seen/dismissed, and no active match is configured
    if (isVisible && !showIntro && !_hasShownRatedCaution && state.activeRatedMatchId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted && !_hasShownRatedCaution && state.activeRatedMatchId == null) {
          setState(() => _hasShownRatedCaution = true);
          final isReady = await _showRatedCautionDialog(context);
          if (isReady && context.mounted) {
            await _showModeSelectionDialog(context);
            if (context.mounted) {
              await _showTimeArenaSelectionDialog(context);
              _triggerDiceRoll();
            }
          }
        }
      });
    }

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: ScholarlyTheme.backgroundStart,
        body: Stack(
          children: [
            const AmbientFlowBackdrop(),
            isLandscape
                ? _buildLandscapeLayout(context, ref, state)
                : _buildPortraitLayout(context, ref, state),
            if ((state.game.gameOver || state.isTimeOut || state.isResigned || state.isDrawAgreed) && !state.isGameOverDismissed)
              _buildGameOverOverlay(context, ref, state),
            if (_isDiceRolling)
              DiceRollingOverlay(
                isWhite: _assignedWhite,
                onComplete: _onDiceRollComplete,
              ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  ScholarlyTheme.accentBlue,
                  ScholarlyTheme.accentGold,
                  Colors.white,
                  Colors.blueAccent,
                  Colors.orangeAccent,
                ],
                numberOfParticles: 60,
                gravity: 0.2,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConfettiWidget(
                confettiController: _confettiBottomController,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: -3.14 / 2, // upward
                shouldLoop: false,
                numberOfParticles: 60,
                gravity: 0.05,
                colors: const [
                  ScholarlyTheme.accentBlue,
                  ScholarlyTheme.accentGold,
                  Colors.white,
                  Colors.blueAccent,
                  Colors.orangeAccent,
                ],
              ),
            ),
            if (showIntro)
              GMChanakyaIntroOverlay(
                pageTitle: 'BATTLEGROUND',
                text: 'Enter the Battleground. These rated games test your decisions under clock pressure and shape your training profile.',
                onDismiss: () {
                  // Sound effects disabled in Battleground
                  // ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  ref.read(showBattlegroundIntroProvider.notifier).state = false;
                  final repo = ref.read(tutorialProgressRepositoryProvider);
                  if (repo.shouldPersistIntroSeen()) {
                    repo.setBattlegroundIntroSeen(true);
                  }
                },
              ),
          ],
        ),
      );
  }

  Widget _buildLandscapeLayout(BuildContext context, WidgetRef ref, BattlegroundState state) {
    final isTurn = _isPlayerTurn(state);
    final isFlipped = state.isBoardFlipped;
    final topPieces = isFlipped ? state.game.capturedByWhite : state.game.capturedByBlack;
    final bottomPieces = isFlipped ? state.game.capturedByBlack : state.game.capturedByWhite;
    final opponentAvatar = state.activeOpponent ?? AiAvatar.getBestMatch(state.consolidatedRating);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT COLUMN (Chessboard Area) - taking 55% of the space
        Expanded(
          flex: 11,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Opponent Avatar Indicator (Top Left) with Inline Captured Pieces
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ActiveAvatarWrapper(
                          isActive: !isTurn,
                          child: OpponentAvatarIndicator(
                            avatar: opponentAvatar,
                            onTap: null, // Read-only from rated arena
                          ),
                        ),
                        const SizedBox(width: 12),
                        CapturedPiecesInline(
                          pieces: topPieces,
                          opponentPieces: bottomPieces,
                          useBnwTheme: true,
                        ),
                      ],
                    ),
                    _buildThinkingFlashButton(context: context, ref: ref, state: state),
                  ],
                ),
              ),
              // BoardStage centered
              Expanded(
                child: Stack(
                  children: [
                    const BattlegroundBoard(alignment: Alignment.topCenter),
                    if (_isCountdownActive)
                      Positioned.fill(
                        child: CountdownOverlay(
                          onComplete: _startNewGame,
                        ),
                      ),
                  ],
                ),
              ),
              // User Avatar Indicator (Bottom Right) with Inline Captured Pieces
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: CapturedPiecesInline(
                        pieces: bottomPieces,
                        opponentPieces: topPieces,
                        useBnwTheme: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ActiveAvatarWrapper(
                      isActive: isTurn,
                      child: const UserAvatarIndicator(isRated: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),

        // VERTICAL SEPARATOR
        Container(
          width: 1.5,
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
        ),

        // RIGHT COLUMN (Sidebar Area) - taking 45% of the space
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Stats & Clocks wrapped in glass
                JuicyGlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: 400,
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
                          ArenaTimeDisplay(
                            isWhite: state.isPlayerWhite,
                            isActive: isTurn,
                            timeLeft: state.isPlayerWhite ? state.whiteTimeLeft : state.blackTimeLeft,
                            baseTimeDuration: state.baseTimeDuration,
                          ),
                          const SizedBox(width: 12),
                          ArenaTimeDisplay(
                            isWhite: !state.isPlayerWhite,
                            isActive: !isTurn,
                            timeLeft: state.isPlayerWhite ? state.blackTimeLeft : state.whiteTimeLeft,
                            baseTimeDuration: state.baseTimeDuration,
                          ),
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
                const SizedBox(height: 12),

                Expanded(
                  child: TabbedGamePanel(
                    recentMoves: state.recentMoves,
                    viewingMoveIndex: state.viewingMoveIndex,
                    onMoveTap: (idx) {
                      ref.read(battlegroundProvider.notifier).setViewingMoveIndex(idx == -1 ? null : idx);
                    },
                    game: state.game,
                    gameMode: state.gameMode,
                    isRatedMode: true,
                    engineLevel: opponentAvatar.id,
                    isPlayerWhite: state.isPlayerWhite,
                    currentEvaluation: state.currentEvaluation,
                    academyState: null,
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Section: Rated Action Row wrapped in JuicyGlassCard
                JuicyGlassCard(
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: _buildRatedActionRow(context, ref, state),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, WidgetRef ref, BattlegroundState state) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isTurn = _isPlayerTurn(state);
    final isFlipped = state.isBoardFlipped;
    final topPieces = isFlipped ? state.game.capturedByWhite : state.game.capturedByBlack;
    final bottomPieces = isFlipped ? state.game.capturedByBlack : state.game.capturedByWhite;
    final opponentAvatar = state.activeOpponent ?? AiAvatar.getBestMatch(state.consolidatedRating);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Stats
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: JuicyGlassCard(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 60,
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
                    ArenaTimeDisplay(
                      isWhite: state.isPlayerWhite,
                      isActive: isTurn,
                      timeLeft: state.isPlayerWhite ? state.whiteTimeLeft : state.blackTimeLeft,
                      baseTimeDuration: state.baseTimeDuration,
                    ),
                    const SizedBox(width: 12),
                    ArenaTimeDisplay(
                      isWhite: !state.isPlayerWhite,
                      isActive: !isTurn,
                      timeLeft: state.isPlayerWhite ? state.blackTimeLeft : state.whiteTimeLeft,
                      baseTimeDuration: state.baseTimeDuration,
                    ),
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
        ),
        // Opponent with inline captured pieces
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActiveAvatarWrapper(
                      isActive: !isTurn,
                      child: OpponentAvatarIndicator(
                        avatar: opponentAvatar,
                        onTap: null, // Read-only from rated arena
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: CapturedPiecesInline(
                        pieces: topPieces,
                        opponentPieces: bottomPieces,
                        useBnwTheme: true,
                      ),
                    ),
                  ],
                ),
              ),
              _buildThinkingFlashButton(context: context, ref: ref, state: state),
            ],
          ),
        ),
        // Board
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Stack(
              children: [
                const BattlegroundBoard(alignment: Alignment.center),
                if (_isCountdownActive)
                  Positioned.fill(
                    child: CountdownOverlay(
                      onComplete: _startNewGame,
                    ),
                  ),
              ],
            ),
          ),
        ),
        // User with inline captured pieces
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: CapturedPiecesInline(
                  pieces: bottomPieces,
                  opponentPieces: topPieces,
                  useBnwTheme: true,
                ),
              ),
              const SizedBox(width: 12),
              ActiveAvatarWrapper(
                isActive: isTurn,
                child: const UserAvatarIndicator(isRated: true),
              ),
            ],
          ),
        ),
        // Rated Actions (5 icons, Dice in middle, special sizes)
        if (!isKeyboardOpen) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: JuicyGlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: _buildRatedActionRow(context, ref, state),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRatedActionRow(BuildContext context, WidgetRef ref, BattlegroundState state) {
    final isMatchActive = state.activeRatedMatchId != null;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Draw Button (Handshake)
          ActionIconButton(
            icon: Icons.handshake_rounded,
            size: 30,
            isEnabled: isMatchActive && state.drawOffersCount < 3,
            onTap: () async {
              final remaining = 3 - state.drawOffersCount;
              final confirm = await _showDrawConfirmationDialog(context, remaining);
              if (confirm == true) {
                if (!context.mounted) return;
                _showDrawConsideringDialog(context);
                
                await Future.delayed(const Duration(milliseconds: 1500));
                
                if (!context.mounted) return;
                Navigator.pop(context); // Close considering dialog
                
                final accepted = await ref.read(battlegroundProvider.notifier).offerDraw();
                
                if (!context.mounted) return;
                if (!accepted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Opponent declined the draw offer.',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 16),
          // 2. New Match Button (Dice)
          ActionIconButton(
            icon: Icons.casino_rounded,
            size: 30,
            onTap: () async {
              if (isMatchActive) {
                final resigned = await _showRatedNewGameDialog(context);
                if (resigned == true) {
                  if (context.mounted && !_checkRatedLimitAndUpsell(context, ref)) return;
                  await ref.read(battlegroundProvider.notifier).resignRatedGame();
                  if (context.mounted) {
                    await _showModeSelectionDialog(context);
                    if (context.mounted) {
                      await _showTimeArenaSelectionDialog(context);
                      _triggerDiceRoll();
                    }
                  }
                }
              } else {
                if (!_checkRatedLimitAndUpsell(context, ref)) return;
                await _showModeSelectionDialog(context);
                if (context.mounted) {
                  await _showTimeArenaSelectionDialog(context);
                  _triggerDiceRoll();
                }
              }
            },
          ),
          const SizedBox(width: 16),
          // 3. Resign Button (Flag)
          ActionIconButton(
            icon: Icons.flag_rounded,
            size: 30,
            isEnabled: isMatchActive,
            onTap: () async {
              final confirm = await _showResignConfirmationDialog(context);
              if (confirm == true) {
                await ref.read(battlegroundProvider.notifier).resignRatedGame();
              }
            },
          ),
        ],
      ),
    );
  }


  Widget _buildGameOverOverlay(BuildContext context, WidgetRef ref, BattlegroundState state) {
    final isDraw = state.game.inDraw || state.isDrawAgreed;
    final didWin = _didPlayerWin(state);

    String title = '';
    String msg = '';

    if (isDraw) {
      title = 'MATCH TIED';
      msg = state.isDrawAgreed ? 'Draw by mutual agreement.' : 'A well-fought game.';
    } else {
      if (didWin) {
        title = state.isTimeOut ? 'VICTORY (TIME)' : 'VICTORY!';
        msg = state.isTimeOut ? 'Opponent ran out of time!' : 'Congratulations, you have won!';
      } else {
        if (state.isResigned) {
          title = 'DEFEAT (RESIGNED)';
          msg = 'You surrendered the battle.';
        } else {
          title = state.isTimeOut ? 'LOSS (TIME)' : 'MATCH LOST';
          msg = state.isTimeOut ? 'You ran out of time!' : 'Defeat is but a stepping stone to mastery.';
        }
      }
    }

    final accentColor = isDraw
        ? ScholarlyTheme.accentBlue
        : (didWin ? ScholarlyTheme.realGold : const Color(0xFFFC8181));

    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: Center(
              child: _SpringEntrance(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.92),
                        Colors.white.withValues(alpha: 0.80),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.15),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          title.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: accentColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      Icon(
                        isDraw
                            ? Icons.handshake_rounded
                            : (didWin
                                ? Icons.emoji_events_rounded
                                : Icons.sentiment_dissatisfied_rounded),
                        size: 64,
                        color: accentColor,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        msg,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    accentColor,
                                    accentColor.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: FilledButton(
                                onPressed: () {
                                  if (!_checkRatedLimitAndUpsell(context, ref)) return;
                                  setState(() {
                                    _hasTriggeredConfetti = false;
                                    _hasShownRatedCaution = false;
                                    _isCountdownActive = false;
                                  });
                                  ref.read(battlegroundProvider.notifier).dismissGameOver();
                                  ref.read(battlegroundProvider.notifier).clearBoard();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: didWin ? Colors.black : Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: Text(
                                  didWin ? 'PLAY NEW MATCH' : 'TRY AGAIN',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: OutlinedButton(
                              onPressed: () async {
                                ref.read(battlegroundProvider.notifier).dismissGameOver();
                                if (context.mounted) {
                                  exitToDashboardWithSidebar(context, ref);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ScholarlyTheme.textMuted,
                                side: BorderSide(
                                  color: ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                'EXIT',
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
        ),
      ),
    );
  }

  Widget _buildThinkingFlashButton({
    required BuildContext context,
    required WidgetRef ref,
    required BattlegroundState state,
  }) {
    final isAiTurn = !_isPlayerTurn(state);
    final isThinking = state.isEngineThinking && isAiTurn;

    if (!isThinking) {
      return const SizedBox(width: 48, height: 48);
    }

    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 14),
      child: Tooltip(
        message: 'Engine is thinking...',
        child: ThinkingDotsAnimation(),
      ),
    );
  }

  bool _didPlayerWin(BattlegroundState state) {
    if (state.isResigned) return false;
    if (state.game.inDraw) return false;
    
    if (state.isTimeOut) {
      final playerTimedOut = state.isPlayerWhite 
          ? state.whiteTimeLeft <= Duration.zero 
          : state.blackTimeLeft <= Duration.zero;
      return !playerTimedOut;
    }
    
    if (state.game.gameOver) {
      // If game is over and not a draw, and it's NOT the player's turn, the player won.
      return !_isPlayerTurn(state);
    }
    
    return false;
  }

  void _triggerDiceRoll() {
    setState(() {
      _isDiceRolling = true;
      _assignedWhite = math.Random().nextBool();
    });
  }

  void _onDiceRollComplete() {
    if (mounted) {
      ref.read(battlegroundProvider.notifier).reset(
        forcedPlayerWhite: _assignedWhite,
        startClockImmediate: false,
      );
      setState(() {
        _isDiceRolling = false;
        _isCountdownActive = true;
      });
    }
  }

  bool _checkRatedLimitAndUpsell(BuildContext context, WidgetRef ref) {
    final storeNotifier = ref.read(storeProvider.notifier);
    if (!storeNotifier.canPlayRatedGame()) {
      PremiumNudgeOverlay.show(
        context,
        ref,
        title: 'Daily Rated Game Limit Reached',
        description: 'You have played your 1 free Rated/Battleground game for today. Upgrade to unlock unlimited games.',
        onDismiss: () => exitToDashboardWithSidebar(context, ref),
      );
      return false;
    }
    return true;
  }

  void _startNewGame() {
    if (mounted) {
      setState(() {
        _isCountdownActive = false;
      });
      ref.read(storeProvider.notifier).recordRatedGame();
      ref.read(battlegroundProvider.notifier).startGame();
    }
  }

  bool _isPlayerTurn(BattlegroundState state) {
    if (state.game.fen.split(' ').length > 1) {
      final turnWhite = state.game.fen.split(' ')[1] == 'w';
      return state.isPlayerWhite == turnWhite;
    }
    return true;
  }

  double _getEvalFraction(BattlegroundState state, bool forPlayer) {
    final eval = forPlayer ? (state.isPlayerWhite ? state.currentEvaluation : -state.currentEvaluation) : (state.isPlayerWhite ? -state.currentEvaluation : state.currentEvaluation);
    return (eval.clamp(-5.0, 5.0) + 5.0) / 10.0;
  }

  Future<bool?> _showResignConfirmationDialog(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        surfaceTintColor: ScholarlyTheme.accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2), width: 1)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.flag_rounded, color: ScholarlyTheme.accentBlue, size: 24),
            ),
            const SizedBox(height: 16),
            Text('Resign Game?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to resign?', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('This will count as an immediate defeat and your rating will decrease.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue, foregroundColor: Colors.white),
            child: const Text('RESIGN'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDrawConfirmationDialog(BuildContext context, int remainingOffers) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        surfaceTintColor: ScholarlyTheme.accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2), width: 1)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.handshake_rounded, color: ScholarlyTheme.accentBlue, size: 24),
            ),
            const SizedBox(height: 16),
            Text('Offer a Draw?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to offer a draw?', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('You can make at most 3 draw offers per game. Offers remaining: $remainingOffers.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue, foregroundColor: Colors.white),
            child: const Text('OFFER DRAW'),
          ),
        ],
      ),
    );
  }

  void _showDrawConsideringDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          surfaceTintColor: ScholarlyTheme.accentBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2), width: 1)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(ScholarlyTheme.accentBlue)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Opponent is considering the draw offer...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: ScholarlyTheme.textPrimary, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
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
          Text('Starting a new match now requires you to formally Resign from the present game. This will be recorded as a loss and will affect your rating.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12, height: 1.5)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue, foregroundColor: Colors.white), child: const Text('RESIGN')),
        ],
      ),
    );
  }

  Future<bool> _showRatedCautionDialog(BuildContext context) async {
    final bool? result = await showDialog<bool>(
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
          const Text('Welcome to the Battleground.', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Every match played here is recorded for your rating and the same will be displayed in the Dashboard. Resigning or abandoning a game prematurely will negatively impact your ELO rating. Proceed if you can completly dedicate focus and time.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12, height: 1.6)),
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
                    onPressed: () => Navigator.pop(context, true),
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
                      Navigator.pop(context, false); // Close dialog
                      if (context.mounted) {
                        exitToDashboardWithSidebar(context, ref); // Exit page
                      }
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
    return result ?? false;
  }

  Future<void> _showModeSelectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        surfaceTintColor: ScholarlyTheme.accentBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2), width: 1)),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.settings_suggest_rounded, color: ScholarlyTheme.accentBlue, size: 24)),
          const SizedBox(height: 16),
          Text('Select Arena Mode', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary, fontSize: 20)),
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
                    onPressed: () {
                      ref.read(battlegroundProvider.notifier).setGameMode('classic');
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ScholarlyTheme.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CLASSIC CHESS', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(battlegroundProvider.notifier).setGameMode('chess960');
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ScholarlyTheme.accentBlue,
                      side: BorderSide(color: ScholarlyTheme.accentBlue, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('CHESS 960', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimeArenaSelectionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(battlegroundProvider);
            final notifier = ref.read(battlegroundProvider.notifier);
            
            final bulletPresets = [
              {'label': '0.5+0', 'min': 0, 'sec': 30, 'inc': 0},
              {'label': '1+0', 'min': 1, 'sec': 0, 'inc': 0},
              {'label': '2+1', 'min': 2, 'sec': 0, 'inc': 1},
            ];
            final blitzPresets = [
              {'label': '3+0', 'min': 3, 'sec': 0, 'inc': 0},
              {'label': '3+2', 'min': 3, 'sec': 0, 'inc': 2},
              {'label': '5+0', 'min': 5, 'sec': 0, 'inc': 0},
            ];
            final rapidPresets = [
              {'label': '10+0', 'min': 10, 'sec': 0, 'inc': 0},
              {'label': '15+10', 'min': 15, 'sec': 0, 'inc': 10},
              {'label': '30+0', 'min': 30, 'sec': 0, 'inc': 0},
            ];

            Widget buildGroup(String title, IconData icon, List<Map<String, dynamic>> group) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: ScholarlyTheme.accentBlue, size: 16),
                      const SizedBox(width: 8),
                      Text(title.toUpperCase(), style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: group.map((p) {
                      final isSelected = state.baseTimeDuration.inMinutes == p['min'] && 
                                       state.baseTimeDuration.inSeconds % 60 == p['sec'] &&
                                       state.incrementDuration.inSeconds == p['inc'];
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text(p['label'] as String),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            notifier.setTimeControl(
                              Duration(minutes: p['min'] as int, seconds: p['sec'] as int),
                              Duration(seconds: p['inc'] as int),
                            );
                          }
                        },
                        selectedColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                        labelStyle: GoogleFonts.inter(
                          color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke),
                        backgroundColor: ScholarlyTheme.panelBase,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }

            return AlertDialog(
              backgroundColor: ScholarlyTheme.panelBase,
              surfaceTintColor: ScholarlyTheme.accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: BorderSide(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2), width: 1)),
              title: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.timer_rounded, color: ScholarlyTheme.accentBlue, size: 24)),
                const SizedBox(height: 16),
                Text('Tiered Time Arenas', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary, fontSize: 20)),
              ]),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildGroup('Bullet Arena', Icons.bolt_rounded, bulletPresets),
                    buildGroup('Blitz Arena', Icons.local_fire_department_rounded, blitzPresets),
                    buildGroup('Rapid Arena', Icons.timer_rounded, rapidPresets),
                  ],
                ),
              ),
              actions: [
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
                    child: const Text('CONFIRM SELECTION', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


}

class ActiveAvatarWrapper extends StatefulWidget {
  final Widget child;
  final bool isActive;

  const ActiveAvatarWrapper({
    super.key,
    required this.child,
    required this.isActive,
  });

  @override
  State<ActiveAvatarWrapper> createState() => _ActiveAvatarWrapperState();
}

class _ActiveAvatarWrapperState extends State<ActiveAvatarWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final curved = CurvedAnimation(parent: _controller, curve: Curves.linear);
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 70,
      ),
    ]).animate(curved);

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(ActiveAvatarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: widget.isActive
              ? [
                  BoxShadow(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.20),
                    blurRadius: 14,
                    spreadRadius: 3,
                  )
                ]
              : [],
        ),
        child: widget.child,
      ),
    );
  }
}

class _SpringEntrance extends StatefulWidget {
  final Widget child;
  const _SpringEntrance({required this.child});

  @override
  State<_SpringEntrance> createState() => _SpringEntranceState();
}

class _SpringEntranceState extends State<_SpringEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
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
        return Opacity(
          opacity: _opacityAnim.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}

Future<bool?> showRatedExitDialog(BuildContext context) async {
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
        Text('As this is a Rated game, exiting now will result in an automatic Loss and a deduction from your current ratings.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12, height: 1.5)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('STAY & PLAY')),
        FilledButton(onPressed: () => Navigator.pop(context, true), style: FilledButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue, foregroundColor: Colors.white), child: const Text('RESIGN')),
      ],
    ),
  );
}

class ThinkingDotsAnimation extends StatelessWidget {
  const ThinkingDotsAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return const NeuralConnectivityMesh();
  }
}

