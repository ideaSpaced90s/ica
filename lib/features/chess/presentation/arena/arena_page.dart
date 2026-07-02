import 'dart:async';
import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../application/arena_provider.dart';
import '../../application/store_provider.dart';
import '../../application/analysis_engine_controller.dart';
import 'widgets/game_review_overlay.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import '../widgets/game_controls.dart';
import 'arena_board.dart';
import '../widgets/captured_pieces_inline.dart';
import '../../domain/models/ai_avatar.dart';
import '../widgets/opponent_avatar_indicator.dart';
import '../widgets/arena_time_display.dart';
import '../widgets/evaluation_bar.dart';
import '../widgets/user_avatar_indicator.dart';
import '../widgets/ambient_flow_backdrop.dart';
import '../widgets/tabbed_game_panel.dart';
import '../widgets/premium_nudge_overlay.dart';
import '../dashboard_page.dart';
import '../mobile_navigation_shell.dart';
import 'arena_settings_page.dart';
import 'chessboard_themes_page.dart';
import 'arena_personas_selection_page.dart';
import 'arena_random_persona_page.dart';
import '../../application/onboarding_provider.dart';
import '../../application/tutorial_provider.dart';
import '../widgets/gm_chanakya_intro_overlay.dart';
import '../widgets/gm_chanakya_new_game_overlay.dart';
import '../widgets/neural_connectivity_mesh.dart';

class _ArenaTabDef {
  final String label;
  final IconData icon;
  const _ArenaTabDef(this.label, this.icon);
}

const List<_ArenaTabDef> _kArenaTabs = [
  _ArenaTabDef('Board', Icons.grid_on_rounded),
  _ArenaTabDef('Themes', Icons.palette_rounded),
  _ArenaTabDef('Persona', Icons.people_alt_rounded),
  _ArenaTabDef('Settings', Icons.settings_rounded),
];

class ArenaPage extends ConsumerStatefulWidget {
  const ArenaPage({super.key});

  @override
  ConsumerState<ArenaPage> createState() => _ArenaPageState();
}

class _ArenaPageState extends ConsumerState<ArenaPage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ConfettiController _confettiController;
  late ConfettiController _confettiBottomController;
  bool _hasTriggeredConfetti = false;
  bool _showGameOverOverlayDelayed = false;
  bool _showNewGameConfirmOverlay = false;
  int _selectedArenaTab = 0;
  int _selectedPersonaSubTab = 0;
  Timer? _gameOverDelayTimer;
  bool _isAnalyzingGame = false;
  double _analysisProgress = 0.0;
  bool _showGameReviewOverlay = false;
  String _currentTip = "Analyzing your moves...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiBottomController = ConfettiController(duration: const Duration(seconds: 3));
    
    final initialState = ref.read(arenaProvider);
    _showGameOverOverlayDelayed = (initialState.isGameOver || initialState.isTimeOut) && !initialState.isGameOverDismissed;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(backButtonOverridesProvider.notifier).update((map) => {
          ...map,
          1: _handleBackPress,
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _confettiBottomController.dispose();
    _gameOverDelayTimer?.cancel();
    ref.read(backButtonOverridesProvider.notifier).update((map) {
      final newMap = Map<int, Future<bool> Function()>.from(map);
      newMap.remove(1);
      return newMap;
    });
    super.dispose();
  }

  Future<bool> _handleBackPress() async {
    if (_showNewGameConfirmOverlay) {
      setState(() {
        _showNewGameConfirmOverlay = false;
      });
      return true;
    }
    return false;
  }

  void _exitWithNudgeCheck(BuildContext context, WidgetRef ref) {
    void exitAction() => exitToDashboardWithSidebar(context, ref);
    final storeState = ref.read(storeProvider);
    if (!storeState.isPremium) {
      PremiumNudgeOverlay.show(
        context,
        ref,
        title: 'IDEASPACE PREMIUM',
        description: 'Keep mastering chess! Upgrade to unlock unlimited games, coaching, and custom themes.',
        onDismiss: exitAction,
      );
    } else {
      exitAction();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      final arenaState = ref.read(arenaProvider);
      if (arenaState.recentMoves.isNotEmpty && !arenaState.isGameOver) {
        if (!arenaState.isPaused) {

          ref.read(arenaProvider.notifier).togglePause();
        }
      }
    }
  }

  Future<void> _startGameReviewAnalysis() async {
    final state = ref.read(arenaProvider);
    if (state.recentMovesUci.isEmpty) {
      setState(() {
        _showGameReviewOverlay = true;
      });
      return;
    }

    setState(() {
      _isAnalyzingGame = true;
      _analysisProgress = 0.0;
      _currentTip = "Analyzing opening lines...";
    });

    final tips = [
      "Analyzing opening lines...",
      "Calculating middlegame strategy...",
      "Evaluating critical tactical moments...",
      "Engine is searching deep for alternate paths...",
      "Looking for brilliant sacrifices...",
      "Formulating final report..."
    ];
    int tipIndex = 0;
    final tipTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || !_isAnalyzingGame) {
        timer.cancel();
        return;
      }
      setState(() {
        tipIndex = (tipIndex + 1) % tips.length;
        _currentTip = tips[tipIndex];
      });
    });

    try {
      final results = await ref.read(analysisEngineControllerProvider.notifier).classifyUciMoves(
        state.recentMovesUci,
        state.game.initialFen,
        targetDepth: 20,
        onProgress: (prog) {
          if (mounted) {
            setState(() {
              _analysisProgress = prog;
            });
          }
        },
      );

      tipTimer.cancel();

      if (mounted) {
        ref.read(arenaProvider.notifier).setReviewData(
          classifications: results['classifications'] as Map<int, MoveClassification>,
          whiteAccuracy: results['whiteAccuracy'] as double,
          blackAccuracy: results['blackAccuracy'] as double,
          whiteCounts: results['whiteCounts'] as Map<MoveClassification, int>,
          blackCounts: results['blackCounts'] as Map<MoveClassification, int>,
          reviewEstimatedWhiteRating: results['whiteElo'] as int,
          reviewEstimatedBlackRating: results['blackElo'] as int,
          evalHistory: results['evalHistory'] as List<double>,
        );

        setState(() {
          _isAnalyzingGame = false;
          _showGameReviewOverlay = true;
        });
      }
    } catch (e) {
      tipTimer.cancel();
      debugPrint('Game Review Analysis failed: $e');
      if (mounted) {
        setState(() {
          _isAnalyzingGame = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to run Engine Game Review.')),
        );
      }
    }
  }

  Widget _buildFloatingAnnotationCard(ArenaState state) {
    if (state.reviewClassifications == null) return const SizedBox.shrink();
    
    final curIdx = state.viewingMoveIndex ?? (state.recentMoves.length - 1);
    if (curIdx < 0 || curIdx >= state.recentMoves.length) return const SizedBox.shrink();
    
    final classification = state.reviewClassifications![curIdx];
    if (classification == MoveClassification.none) return const SizedBox.shrink();
    
    final moveLabel = state.recentMoves[curIdx];
    final moveNum = (curIdx ~/ 2) + 1;
    final isWhite = curIdx % 2 == 0;
    final moveText = isWhite ? '$moveNum. $moveLabel' : '$moveNum... $moveLabel';
    
    String text = '';
    Color color = Colors.grey;
    
    switch (classification) {
      case MoveClassification.brilliant:
        text = 'is a Brilliant move! !!';
        color = const Color(0xFF00BCD4);
        break;
      case MoveClassification.best:
        text = 'is the Best move.';
        color = const Color(0xFF00C853);
        break;
      case MoveClassification.good:
        text = 'is a Good move.';
        color = const Color(0xFF4CAF50);
        break;
      case MoveClassification.inaccuracy:
        text = 'is an Inaccuracy. ?!';
        color = const Color(0xFFFFB300);
        break;
      case MoveClassification.mistake:
        text = 'is a Mistake. ?';
        color = const Color(0xFFFF6D00);
        break;
      case MoveClassification.blunder:
        text = 'is a Blunder! ??';
        color = const Color(0xFFD50000);
        break;
      default:
        return const SizedBox.shrink();
    }
    
    final isBad = classification == MoveClassification.inaccuracy ||
                  classification == MoveClassification.mistake ||
                  classification == MoveClassification.blunder;
                  
    final textColor = isBad ? const Color(0xFFE53935) : const Color(0xFF00C853);

    return Positioned(
      bottom: 8,
      left: 24,
      right: 24,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    classification == MoveClassification.brilliant ? '!!' :
                    classification == MoveClassification.blunder ? '??' :
                    classification == MoveClassification.mistake ? '?' :
                    classification == MoveClassification.inaccuracy ? '?!' : '✓',
                    style: GoogleFonts.outfit(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ScholarlyTheme.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: '$moveText ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: text,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arenaProvider);



    final storeState = ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);
    final isPremium = storeState.isPremium;
    final isLimitReached = !isPremium && !storeNotifier.canPlayArenaGame() && !(state.recentMoves.isNotEmpty && !state.isGameOver);

    if (isLimitReached) {
      return const PremiumNudgeOverlay(
        isFullScreen: true,
        title: 'Daily Arena Game Limit Reached',
        description: 'You have played your 3 free Arena games for today. Upgrade to unlock unlimited games.',
      );
    }

    final showIntro = ref.watch(showArenaIntroProvider);
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    ref.listen<ArenaState>(arenaProvider, (previous, next) {
      final wasGameOver = (previous?.isGameOver ?? false) || (previous?.isTimeOut ?? false);
      final isGameOver = next.isGameOver || next.isTimeOut;
      final wasDismissed = previous?.isGameOverDismissed ?? false;
      final isDismissed = next.isGameOverDismissed;

      if (isGameOver && !wasGameOver) {
        _gameOverDelayTimer?.cancel();
        _gameOverDelayTimer = Timer(const Duration(milliseconds: 1300), () {
          if (mounted) {
            setState(() {
              _showGameOverOverlayDelayed = true;
            });
          }
        });
      } else if (!isGameOver || (isDismissed && !wasDismissed)) {
        _gameOverDelayTimer?.cancel();
        if (_showGameOverOverlayDelayed) {
          setState(() {
            _showGameOverOverlayDelayed = false;
          });
        }
      }
    });

    ref.listen<int>(mobileNavIndexProvider, (previous, current) {
      if (previous == 1 && current != 1) {
        final repo = ref.read(tutorialProgressRepositoryProvider);
        if (!repo.shouldPersistIntroSeen()) {
          ref.read(showArenaIntroProvider.notifier).state = true;
        }
      }
    });

    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: ScholarlyTheme.backgroundStart,
        bottomNavigationBar: _buildBottomNavigationBar(context),
        body: Stack(
          children: [
            const AmbientFlowBackdrop(),
            if (_selectedArenaTab == 0) ...[
              Positioned.fill(
                child: isLandscape
                    ? _buildLandscapeLayout(context, ref, state)
                    : _buildPortraitLayout(context, ref, state),
              ),
              if (_showGameOverOverlayDelayed && !state.isGameOverDismissed)
                state.isTimeOut && !state.isGameOver
                    ? _buildTimeOutOverlay(context, ref, state)
                    : _buildGameOverOverlay(context, ref, state),
              if (_showNewGameConfirmOverlay)
                GMChanakyaNewGameOverlay(
                  onConfirm: () async {
                    if (ref.read(arenaProvider).recentMoves.isNotEmpty) {
                      await ref.read(arenaProvider.notifier).saveCurrentGame();
                    }
                    ref.read(storeProvider.notifier).recordArenaGame();
                    ref.read(arenaProvider.notifier).reset();
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.dice);
                    setState(() {
                      _showNewGameConfirmOverlay = false;
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('New Match Started'),
                          duration: Duration(milliseconds: 1500),
                          backgroundColor: ScholarlyTheme.accentBlue,
                        ),
                      );
                    }
                  },
                  onCancel: () {
                    setState(() {
                      _showNewGameConfirmOverlay = false;
                    });
                  },
                ),
              
              // Confetti Layer
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  numberOfParticles: ref.watch(chessProvider.select(
                    (s) => (s.animationSettings['arcadeMode'] ?? false) ? 40 : 20,
                  )),
                  colors: const [
                    ScholarlyTheme.accentGold,
                    ScholarlyTheme.accentBlue,
                    Colors.white,
                    Colors.yellow,
                    Color(0xFF60A5FA), // arcade blue
                    Color(0xFF7C3AED), // violet
                  ],
                  createParticlePath: (size) {
                    final path = Path();
                    path.addRect(Rect.fromLTWH(0, 0, size.width, size.height / 2));
                    return path;
                  },
                ),
              ),
              // Arcade Mode: second bottom-blast confetti
              if (ref.watch(chessProvider.select(
                (s) => s.animationSettings['arcadeMode'] ?? false,
              )))
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiBottomController,
                    blastDirectionality: BlastDirectionality.explosive,
                    blastDirection: -3.14 / 2, // upward
                    shouldLoop: false,
                    numberOfParticles: 30,
                    gravity: 0.05,
                    colors: const [
                      Color(0xFF3B82F6),
                      Color(0xFF60A5FA),
                      Color(0xFFBAE6FD),
                      Colors.white,
                      Color(0xFF7C3AED),
                      ScholarlyTheme.accentGold,
                    ],
                    createParticlePath: (size) {
                      final path = Path();
                      path.addOval(
                        Rect.fromCircle(
                          center: Offset(size.width / 2, size.height / 2),
                          radius: size.width / 2,
                        ),
                      );
                      return path;
                    },
                  ),
                ),
              if (showIntro)
                GMChanakyaIntroOverlay(
                  pageTitle: 'ARENA',
                  text: 'Welcome to the Arena. Practice freely here: test ideas, face AI avatars, adjust difficulty, and learn without rating pressure.',
                  onDismiss: () {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    ref.read(showArenaIntroProvider.notifier).state = false;
                    final repo = ref.read(tutorialProgressRepositoryProvider);
                    if (repo.shouldPersistIntroSeen()) {
                      repo.setArenaIntroSeen(true);
                    }
                  },
                ),
              if (_isAnalyzingGame)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.75),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            width: 320,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                    color: ScholarlyTheme.accentBlue,
                                    strokeWidth: 4,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'ANALYZING MATCH',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                    color: ScholarlyTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: _analysisProgress,
                                  backgroundColor: Colors.grey.shade200,
                                  color: ScholarlyTheme.accentBlue,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(_analysisProgress * 100).toInt()}% Complete (Depth 20)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: ScholarlyTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),
                                Text(
                                  _currentTip,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: ScholarlyTheme.textPrimary,
                                    fontStyle: FontStyle.italic,
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
              if (_showGameReviewOverlay)
                GameReviewOverlay(
                  whiteAccuracy: state.whiteAccuracy ?? 0.0,
                  blackAccuracy: state.blackAccuracy ?? 0.0,
                  whiteElo: state.reviewEstimatedWhiteRating ?? 1200,
                  blackElo: state.reviewEstimatedBlackRating ?? 1200,
                  whiteCounts: state.whiteCounts ?? const {},
                  blackCounts: state.blackCounts ?? const {},
                  evalHistory: state.evalHistory ?? const [],
                  recentMoves: state.recentMoves,
                  reviewClassifications: state.reviewClassifications ?? const {},
                  whitePlayerName: state.isPlayerWhite ? 'You' : AiAvatar.getAvatar(state.engineLevel).name,
                  blackPlayerName: state.isPlayerWhite ? AiAvatar.getAvatar(state.engineLevel).name : 'You',
                  onStartReview: () {
                    setState(() {
                      _showGameReviewOverlay = false;
                    });
                  },
                ),
            ] else if (_selectedArenaTab == 1) ...[
              Positioned.fill(
                child: _buildThemesTab(),
              ),
            ] else if (_selectedArenaTab == 2) ...[
              Positioned.fill(
                child: _buildPersonaTab(context),
              ),
            ] else if (_selectedArenaTab == 3) ...[
              Positioned.fill(
                child: _buildSettingsTab(),
              ),
            ],
          ],
        ),
      );
  }

  Widget _buildThemesTab() {
    return ChessboardThemesPage(
      embedMode: true,
      onThemeSelected: () {
        setState(() {
          _selectedArenaTab = 0;
        });
      },
    );
  }

  Widget _buildPersonaTab(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSubTabButton(
                      label: 'Explore',
                      isSelected: _selectedPersonaSubTab == 0,
                      onTap: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        setState(() => _selectedPersonaSubTab = 0);
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildSubTabButton(
                      label: 'Shuffle',
                      isSelected: _selectedPersonaSubTab == 1,
                      onTap: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        setState(() => _selectedPersonaSubTab = 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedPersonaSubTab,
            children: [
              ArenaPersonasSelectionPage(embedMode: true),
              ArenaRandomPersonaPage(
                embedMode: true,
                onMatchCommitted: () {
                  // Stay on shuffle page — selection is already committed to provider
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ScholarlyTheme.accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : ScholarlyTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildSettingsTab() {
    return const ArenaSettingsPage(
      embedMode: true,
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_kArenaTabs.length, (i) {
              final tab = _kArenaTabs[i];
              final isSelected = _selectedArenaTab == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    setState(() => _selectedArenaTab = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ScholarlyTheme.accentBlue.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          color: isSelected
                              ? ScholarlyTheme.accentBlue
                              : ScholarlyTheme.textMuted,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tab.label,
                            style: GoogleFonts.outfit(
                              color: isSelected
                                  ? ScholarlyTheme.accentBlue
                                  : ScholarlyTheme.textMuted,
                              fontSize: 9,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context, WidgetRef ref, ArenaState state) {
    final isTurn = _isPlayerTurn(state);
    final showHistoricalTimes = state.viewingMoveIndex != null &&
        state.whiteTimeHistory.length > state.viewingMoveIndex! &&
        state.blackTimeHistory.length > state.viewingMoveIndex!;
        
    final whiteTimeToShow = showHistoricalTimes
        ? (state.viewingMoveIndex! < 0 ? state.baseTimeDuration : state.whiteTimeHistory[state.viewingMoveIndex!])
        : state.whiteTimeLeft;
        
    final blackTimeToShow = showHistoricalTimes
        ? (state.viewingMoveIndex! < 0 ? state.baseTimeDuration : state.blackTimeHistory[state.viewingMoveIndex!])
        : state.blackTimeLeft;
    final isFlipped = state.isBoardFlipped;
    final topPieces = isFlipped ? state.game.capturedByWhite : state.game.capturedByBlack;
    final bottomPieces = isFlipped ? state.game.capturedByBlack : state.game.capturedByWhite;

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
              // Top Player (Opponent) Row - stabilized height
              SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ArenaTimeDisplay(
                            isWhite: !state.isPlayerWhite,
                            isActive: !isTurn,
                            timeLeft: !state.isPlayerWhite ? whiteTimeToShow : blackTimeToShow,
                            baseTimeDuration: state.baseTimeDuration,
                          ),
                          const SizedBox(width: 8),
                          EvaluationBar(fillFraction: _getEvalFraction(state, false)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildThinkingFlashButton(context: context, ref: ref, state: state),
                          ActiveAvatarWrapper(
                            isActive: !isTurn,
                            child: OpponentAvatarIndicator(
                              avatar: AiAvatar.getAvatar(state.engineLevel),
                              onTap: null, // Read-only from unrated arena
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Top Captured Pieces stacked below top player row - stabilized height
              SizedBox(
                height: 34,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: CapturedPiecesInline(
                          pieces: topPieces,
                          opponentPieces: bottomPieces,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              // BoardStage centered
              Expanded(
                child: Stack(
                  children: [
                    const ArenaChessBoard(alignment: Alignment.topCenter),
                    if (state.isPaused) _buildPauseOverlay(context, ref),
                    _buildFloatingAnnotationCard(state),
                  ],
                ),
              ),
              // Bottom Captured Pieces stacked above bottom player row - stabilized height
              SizedBox(
                height: 34,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(width: 8),
                      Flexible(
                        child: CapturedPiecesInline(
                          pieces: bottomPieces,
                          opponentPieces: topPieces,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Player (User/Down Engine) Row - stabilized height
              SizedBox(
                height: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ActiveAvatarWrapper(
                            isActive: isTurn,
                            child: state.isEngineVsEngine
                                ? OpponentAvatarIndicator(
                                    avatar: AiAvatar.getAvatar(state.bottomAvatarId),
                                    onTap: null, // Read-only from unrated arena
                                  )
                                : const UserAvatarIndicator(),
                          ),
                          _buildBottomThinkingIndicator(context: context, ref: ref, state: state),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          EvaluationBar(fillFraction: _getEvalFraction(state, true)),
                          const SizedBox(width: 8),
                          ArenaTimeDisplay(
                            isWhite: state.isPlayerWhite,
                            isActive: isTurn,
                            timeLeft: state.isPlayerWhite ? whiteTimeToShow : blackTimeToShow,
                            baseTimeDuration: state.baseTimeDuration,
                          ),
                        ],
                      ),
                    ],
                  ),
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
                Expanded(
                  child: TabbedGamePanel(
                    recentMoves: state.recentMoves,
                    viewingMoveIndex: state.viewingMoveIndex,
                    onMoveTap: (idx) => ref.read(arenaProvider.notifier).setViewingMoveIndex(idx),
                    game: state.game,
                    gameMode: state.gameMode,
                    isRatedMode: false,
                    engineLevel: state.engineLevel,
                    isPlayerWhite: state.isPlayerWhite,
                    currentEvaluation: state.currentEvaluation,
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom Section: Action Row (reusing portrait action row!)
                _buildActionRow(context, ref, state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BuildContext context, WidgetRef ref, ArenaState state) {
    final isTurn = _isPlayerTurn(state);
    final showHistoricalTimes = state.viewingMoveIndex != null &&
        state.whiteTimeHistory.length > state.viewingMoveIndex! &&
        state.blackTimeHistory.length > state.viewingMoveIndex!;
        
    final whiteTimeToShow = showHistoricalTimes
        ? (state.viewingMoveIndex! < 0 ? state.baseTimeDuration : state.whiteTimeHistory[state.viewingMoveIndex!])
        : state.whiteTimeLeft;
        
    final blackTimeToShow = showHistoricalTimes
        ? (state.viewingMoveIndex! < 0 ? state.baseTimeDuration : state.blackTimeHistory[state.viewingMoveIndex!])
        : state.blackTimeLeft;
    final isFlipped = state.isBoardFlipped;
    final topPieces = isFlipped ? state.game.capturedByWhite : state.game.capturedByBlack;
    final bottomPieces = isFlipped ? state.game.capturedByBlack : state.game.capturedByWhite;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // Top Player (Opponent) Row - stabilized height
        SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ArenaTimeDisplay(
                      isWhite: !state.isPlayerWhite,
                      isActive: !isTurn,
                      timeLeft: !state.isPlayerWhite ? whiteTimeToShow : blackTimeToShow,
                      baseTimeDuration: state.baseTimeDuration,
                    ),
                    const SizedBox(width: 8),
                    EvaluationBar(fillFraction: _getEvalFraction(state, false)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThinkingFlashButton(context: context, ref: ref, state: state),
                    ActiveAvatarWrapper(
                      isActive: !isTurn,
                      child: OpponentAvatarIndicator(
                        avatar: AiAvatar.getAvatar(state.engineLevel),
                        onTap: null, // Read-only from unrated arena
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Top Captured Pieces stacked below top player row - stabilized height
        SizedBox(
          height: 26,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: CapturedPiecesInline(
                    pieces: topPieces,
                    opponentPieces: bottomPieces,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        // Board
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Stack(
              children: [
                const ArenaChessBoard(alignment: Alignment.center),
                if (state.isPaused) _buildPauseOverlay(context, ref),
                _buildFloatingAnnotationCard(state),
              ],
            ),
          ),
        ),
        // Bottom Captured Pieces stacked above bottom player row - stabilized height
        SizedBox(
          height: 26,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(width: 8),
                Flexible(
                  child: CapturedPiecesInline(
                    pieces: bottomPieces,
                    opponentPieces: topPieces,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Bottom Player (User/Down Engine) Row - stabilized height
        SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ActiveAvatarWrapper(
                      isActive: isTurn,
                      child: state.isEngineVsEngine
                          ? OpponentAvatarIndicator(
                              avatar: AiAvatar.getAvatar(state.bottomAvatarId),
                              onTap: null, // Read-only from unrated arena
                          )
                          : const UserAvatarIndicator(),
                    ),
                    _buildBottomThinkingIndicator(context: context, ref: ref, state: state),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EvaluationBar(fillFraction: _getEvalFraction(state, true)),
                    const SizedBox(width: 8),
                    ArenaTimeDisplay(
                      isWhite: state.isPlayerWhite,
                      isActive: isTurn,
                      timeLeft: state.isPlayerWhite ? whiteTimeToShow : blackTimeToShow,
                      baseTimeDuration: state.baseTimeDuration,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!isKeyboardOpen) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: _buildActionRow(context, ref, state, isDocked: false),
          ),
        ],
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref, ArenaState state, {bool isDocked = false}) {
    if (isDocked) {
      return Container(
        decoration: BoxDecoration(
          color: ScholarlyTheme.panelBase,
          border: Border(top: BorderSide(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.15))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildActionButtons(context, ref, state, isDocked: true),
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _buildActionButtons(context, ref, state, isDocked: false),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context, WidgetRef ref, ArenaState state, {required bool isDocked}) {
    final chessState = ref.watch(chessProvider);
    final savedGame = chessState.savedGames.where((e) => e.id == state.loadedGameId).firstOrNull;
    bool isDirty = false;
    if (state.recentMoves.isNotEmpty) {
      if (state.loadedGameId == null || savedGame == null) {
        isDirty = true;
      } else if (savedGame.recentMoves.length != state.recentMoves.length) {
        isDirty = true;
      } else {
        for (int i = 0; i < state.recentMoves.length; i++) {
          if (savedGame.recentMoves[i] != state.recentMoves[i]) {
            isDirty = true;
            break;
          }
        }
      }
    }

    return [
      ActionIconButton(
        icon: Icons.add_box_rounded, // UNRATED uses +
        isFlat: isDocked,
        onTap: () => _handleNewGame(context, ref),
      ),
      const SizedBox(width: 8),
      ActionIconButton(
        icon: Icons.undo_rounded,
        isEnabled: state.canUndo,
        isFlat: isDocked,
        enableLongPressRepeat: true,
        onTap: state.canUndo ? () => ref.read(arenaProvider.notifier).undo() : null,
      ),
      const SizedBox(width: 8),
      ActionIconButton(
        icon: Icons.redo_rounded,
        isEnabled: state.canRedo,
        isFlat: isDocked,
        enableLongPressRepeat: true,
        onTap: state.canRedo ? () => ref.read(arenaProvider.notifier).redo() : null,
      ),
      const SizedBox(width: 8),
      ActionIconButton(
        icon: Icons.flip_camera_android_outlined,
        isActive: state.isBoardFlipped,
        isFlat: isDocked,
        onTap: () => ref.read(arenaProvider.notifier).toggleBoardOrientation(),
      ),
      const SizedBox(width: 8),
      ActionIconButton(
        icon: state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
        isActive: state.isPaused,
        isFlat: isDocked,
        onTap: () => ref.read(arenaProvider.notifier).togglePause(),
      ),
      const SizedBox(width: 8),
      ActionIconButton(
        icon: state.isEngineVsEngine ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
        isActive: state.isEngineVsEngine,
        isFlat: isDocked,
        onTap: () {
          ref.read(arenaProvider.notifier).toggleEngineVsEngine();
          final updatedState = ref.read(arenaProvider);
          final isEvE = updatedState.isEngineVsEngine;
          final upEngineName = AiAvatar.getAvatar(updatedState.engineLevel).name;
          
          String message = '';
          if (isEvE) {
            final downEngineName = AiAvatar.getAvatar(updatedState.bottomAvatarId).name;
            message = 'The game will now be played between $upEngineName and $downEngineName.';
          } else {
            final userName = ref.read(chessProvider).userName;
            message = 'The game will now be played between $upEngineName and $userName.';
          }

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              backgroundColor: ScholarlyTheme.panelBase.withValues(alpha: 0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ScholarlyTheme.accentBlue, width: 1.5),
              ),
              content: Row(
                children: [
                  const Icon(Icons.smart_toy_rounded, color: ScholarlyTheme.accentBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(width: 8),
      ActionIconButton(
        icon: Icons.flash_on_rounded,
        isBlinkingContinuous: ref.watch(chessProvider).quickPlay || state.isTemporaryQuickPlay,
        isActive: state.isEngineThinking && (!_isPlayerTurn(state) || state.isEngineVsEngine),
        isEnabled: !_isPlayerTurn(state) || state.isEngineVsEngine,
        isFlat: isDocked,
        activeColor: Colors.amber,
        activeIconColor: Colors.black,
        baseColor: (ref.watch(chessProvider).quickPlay || state.isTemporaryQuickPlay) ? Colors.amber : Colors.white.withValues(alpha: 0.12),
        iconColor: (ref.watch(chessProvider).quickPlay || state.isTemporaryQuickPlay) ? Colors.black : Colors.white.withValues(alpha: 0.35),
        onTap: () => ref.read(arenaProvider.notifier).activateTemporaryQuickPlay(),
      ),
      const SizedBox(width: 8),
      Stack(
        clipBehavior: Clip.none,
        children: [
          ActionIconButton(
            icon: Icons.save_rounded,
            isFlat: isDocked,
            onTap: () => _handleSaveGame(context, ref),
          ),
          if (isDirty)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6B35),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(width: 8),
      ActionIconButton(
        icon: state.isBulbGlowing ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
        isEnabled: _isPlayerTurn(state),
        isActive: state.isBulbGlowing,
        isBlinkingContinuous: state.isHintLoading,
        isFlat: isDocked,
        activeColor: ScholarlyTheme.accentYellowSoft,
        activeIconColor: ScholarlyTheme.accentYellow,
        onTap: () => ref.read(arenaProvider.notifier).requestHint(),
      ),
    ];
  }

  Widget _buildPauseOverlay(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => ref.read(arenaProvider.notifier).togglePause(),
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
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => ref.read(arenaProvider.notifier).reset(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFC8181), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flag_rounded, color: Color(0xFFFC8181), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'QUIT',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFC8181),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context, WidgetRef ref, ArenaState state) {
    final isDraw = state.game.inDraw;
    final didWin = _didPlayerWin(state);
    
    if (didWin && !_hasTriggeredConfetti) {
      _hasTriggeredConfetti = true;
      _confettiController.play();
      final arcadeMode = ref.read(chessProvider).animationSettings['arcadeMode'] ?? false;
      if (arcadeMode) {
        _confettiBottomController.play();
      }
    }

    String title = isDraw ? 'Match Draw' : (didWin ? 'Victory!' : 'Match Lost');
    String msg = isDraw 
        ? 'A well-fought strategic stalemate.' 
        : (didWin ? 'Congratulations, you have dominated the arena!' : 'Defeat is but a stepping stone to mastery.');
    
    if (state.isTimeOut) {
      title = didWin ? 'Victory (Time)' : 'Loss (Time)';
      msg = didWin ? 'Opponent ran out of time!' : 'You ran out of time!';
    }

    final accentColor = isDraw
        ? ScholarlyTheme.accentBlue
        : (didWin ? ScholarlyTheme.accentGold : const Color(0xFFFC8181));

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
                      color: accentColor.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with glow
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.12),
                          border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isDraw
                              ? Icons.handshake_rounded
                              : (didWin ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded),
                          size: 36,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Title
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        msg,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 58,
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
                            onPressed: () async {
                              if (!_checkArenaLimitAndUpsell(context, ref)) return;
                              // Close the game-over overlay then show the
                              // full new-game confirmation popup (with match
                              // details) – same experience as tapping +.
                              ref.read(arenaProvider.notifier).dismissGameOver();
                              setState(() {
                                _hasTriggeredConfetti = false;
                                _showNewGameConfirmOverlay = true;
                              });
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: didWin ? Colors.black : Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'START NEW GAME',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Last game will be saved',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: didWin ? Colors.black54 : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(arenaProvider.notifier).dismissGameOver();
                            _startGameReviewAnalysis();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ScholarlyTheme.accentBlue,
                            side: BorderSide(
                              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'BACK TO BOARD',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Review the final board position',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: ScholarlyTheme.accentBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton(
                          onPressed: () {
                            _exitWithNudgeCheck(context, ref);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ScholarlyTheme.textMuted,
                            side: BorderSide(
                              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CLOSE',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Game will not be saved',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: ScholarlyTheme.textMuted,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildTimeOutOverlay(BuildContext context, WidgetRef ref, ArenaState state) {
    final playerTimedOut = state.isPlayerWhite
        ? state.whiteTimeLeft <= Duration.zero
        : state.blackTimeLeft <= Duration.zero;

    final title = '⏱️ TIME\'S UP!';
    final msg = playerTimedOut
        ? 'Your clock has run out! Would you like to continue playing with the clock disabled, or review your moves?'
        : 'Your opponent ran out of time! Would you like to continue playing with the clock disabled, or review your moves?';

    final accentColor = ScholarlyTheme.accentBlue;

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
                      color: accentColor.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with glow
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.12),
                          border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.timer_off_rounded,
                          size: 36,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Title
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: 2.0,
                          shadows: [
                            Shadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        msg,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 58,
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
                              ref.read(arenaProvider.notifier).continueAfterTimeout();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'CONTINUE PLAYING',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Clock will be disabled',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton(
                          onPressed: () async {
                            if (!_checkArenaLimitAndUpsell(context, ref)) return;
                            // Dismiss the timeout overlay and show the
                            // full new-game confirmation popup.
                            ref.read(arenaProvider.notifier).dismissGameOver();
                            setState(() {
                              _showNewGameConfirmOverlay = true;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ScholarlyTheme.accentGold,
                            side: BorderSide(
                              color: ScholarlyTheme.accentGold.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'START NEW GAME',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Last game will be saved',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: ScholarlyTheme.accentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(arenaProvider.notifier).dismissGameOver();
                            _startGameReviewAnalysis();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ScholarlyTheme.accentBlue,
                            side: BorderSide(
                              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'BACK TO BOARD',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Review the final board position',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: ScholarlyTheme.accentBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: OutlinedButton(
                          onPressed: () {
                            _exitWithNudgeCheck(context, ref);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ScholarlyTheme.textMuted,
                            side: BorderSide(
                              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CLOSE',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Game will not be saved',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: ScholarlyTheme.textMuted,
                                ),
                              ),
                            ],
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
      ),
    );
  }


  bool _didPlayerWin(ArenaState state) {
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

  bool _isPlayerTurn(ArenaState state) {
    if (state.game.fen.split(' ').length > 1) {
      final turnWhite = state.game.fen.split(' ')[1] == 'w';
      return state.isPlayerWhite == turnWhite;
    }
    return true;
  }

  double _getEvalFraction(ArenaState state, bool forPlayer) {
    final eval = forPlayer ? (state.isPlayerWhite ? state.currentEvaluation : -state.currentEvaluation) : (state.isPlayerWhite ? -state.currentEvaluation : state.currentEvaluation);
    return (eval.clamp(-5.0, 5.0) + 5.0) / 10.0;
  }

  Widget _buildThinkingFlashButton({
    required BuildContext context,
    required WidgetRef ref,
    required ArenaState state,
  }) {
    final isAiTurn = !_isPlayerTurn(state);
    final isThinking = state.isEngineThinking && isAiTurn;

    if (!isThinking) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.only(right: 8),
      child: Tooltip(
        message: 'Engine is thinking...',
        child: ThinkingDotsAnimation(),
      ),
    );
  }

  Widget _buildBottomThinkingIndicator({
    required BuildContext context,
    required WidgetRef ref,
    required ArenaState state,
  }) {
    final isBottomAiTurn = state.isEngineVsEngine && _isPlayerTurn(state);
    final isThinking = state.isEngineThinking && isBottomAiTurn;

    if (!isThinking) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.only(left: 8),
      child: Tooltip(
        message: 'Engine is thinking...',
        child: ThinkingDotsAnimation(),
      ),
    );
  }


  bool _checkArenaLimitAndUpsell(BuildContext context, WidgetRef ref) {
    final storeNotifier = ref.read(storeProvider.notifier);
    if (!storeNotifier.canPlayArenaGame()) {
      PremiumNudgeOverlay.show(
        context,
        ref,
        title: 'Daily Arena Game Limit Reached',
        description: 'You have played your 3 free Arena games for today. Upgrade to unlock unlimited games.',
        onDismiss: () => exitToDashboardWithSidebar(context, ref),
      );
      return false;
    }
    return true;
  }

  Future<void> _handleNewGame(BuildContext context, WidgetRef ref) async {
    if (!_checkArenaLimitAndUpsell(context, ref)) return;

    setState(() {
      _showNewGameConfirmOverlay = true;
    });
  }

  Future<void> _handleSaveGame(BuildContext context, WidgetRef ref) async {
    await ref.read(arenaProvider.notifier).saveCurrentGame();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved'), backgroundColor: ScholarlyTheme.accentBlue));
    }
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

class ThinkingDotsAnimation extends StatelessWidget {
  const ThinkingDotsAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return const NeuralConnectivityMesh();
  }
}


