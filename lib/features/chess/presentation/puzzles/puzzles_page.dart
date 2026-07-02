import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;
import '../../application/puzzles_provider.dart';
import '../scholarly_theme.dart';
import 'puzzles_board.dart';
import '../widgets/ambient_scaffold.dart';
import '../dashboard_page.dart';
import '../mobile_navigation_shell.dart';
import 'widgets/pressure_cooker_timer.dart';
import 'dart:ui';
import '../../application/onboarding_provider.dart';
import '../../application/chess_provider.dart';
import '../../application/tutorial_provider.dart';
import '../../application/store_provider.dart';
import '../../services/chess_sound_service.dart';
import '../widgets/gm_chanakya_intro_overlay.dart';
import '../widgets/premium_nudge_overlay.dart';
import '../../application/assignment_provider.dart';
import '../../application/battleground_provider.dart';

class PuzzlesPage extends ConsumerStatefulWidget {
  const PuzzlesPage({super.key});

  @override
  ConsumerState<PuzzlesPage> createState() => _PuzzlesPageState();
}

class _PuzzlesPageState extends ConsumerState<PuzzlesPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late ConfettiController _confettiController;
  bool _hasTriggeredConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentIndex = ref.read(mobileNavIndexProvider);
      if (currentIndex == 4 && !ref.read(puzzlesProvider).isPuzzleMode) {
        if (!_checkPuzzleLimitAndUpsell(context, ref)) {
          ref.read(mobileNavIndexProvider.notifier).state = 0; // Redirect to Dashboard
          return;
        }
        ref.read(storeProvider.notifier).recordPuzzle();
        await ref.read(puzzlesProvider.notifier).startPrescriptionMode(silent: true);
      }
      if (mounted) {
        ref.read(backButtonOverridesProvider.notifier).update((map) => {
          ...map,
          4: _handleBackPress,
        });
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    ref.read(backButtonOverridesProvider.notifier).update((map) {
      final newMap = Map<int, Future<bool> Function()>.from(map);
      newMap.remove(4);
      return newMap;
    });
    super.dispose();
  }

  Future<bool> _handleBackPress() async {
    await _requestExitPuzzle();
    return true;
  }

  Future<void> _requestExitPuzzle() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Exit Puzzle Mode?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
        content: Text(
          'Do you want to exit the puzzle environment and return to the dashboard?',
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Stay',
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
              'Exit Puzzles',
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
      if (!mounted) return;
      await ref.read(puzzlesProvider.notifier).exitPuzzleMode();
      if (!mounted) return;
      exitToDashboardWithSidebar(context, ref);
    }
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    PuzzlesState state,
    PuzzlesNotifier notifier,
  ) {
    final bool isSolved = state.puzzleMovesRemaining.isEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // 1. Puzzle Info Header (Moved to top)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: _PuzzleStatusHeader(state: state),
                  ),

                  // Pressure Cooker Countdown Timer
                  if (state.isPressureCookerActive && !isSolved) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      child: PressureCookerTimer(),
                    ),
                  ],

                  if (state.isWrongMoveAttempted && !isSolved)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Incorrect move. Try again!',
                                style: GoogleFonts.inter(
                                  color: Colors.red.shade800,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8), // Snug spacing to keep board directly below Toughness Header

                  // 2. Board (Centered in the middle area)
                  const AspectRatio(
                    aspectRatio: 1.0,
                    child: PuzzlesBoard(alignment: Alignment.center),
                  ),

                  // GM Chanakya speech bubble
                  if (state.commentaryHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage('assets/persona/gm_chanakya.webp'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "GM CHANAKYA",
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: ScholarlyTheme.accentBlue,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.comicNeue(
                                        fontSize: 16,
                                        color: const Color(0xFF1E293B),
                                        fontWeight: FontWeight.w500,
                                        height: 1.35,
                                      ),
                                      children: _buildHighlightedText(state.commentaryHistory.last.text),
                                    ),
                                  ),
                                  if (isSolved) ...[
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          if (state.solvedCount >= 5) {
                                            await ref.read(puzzlesProvider.notifier).exitPuzzleMode();
                                            if (context.mounted) {
                                              ref.read(mobileNavIndexProvider.notifier).state = 1; // Back to Arena
                                            }
                                          } else {
                                            if (!_checkPuzzleLimitAndUpsell(context, ref)) return;
                                            ref.read(storeProvider.notifier).recordPuzzle();
                                            notifier.nextPrescriptionPuzzle(silent: true);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981), // Emerald
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                        label: Text(
                                          state.solvedCount >= 5 ? 'Test Progress in Arena' : 'Move to Next Puzzle',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Spacer to push actions/banner to bottom
                  const Spacer(),

                  // 3. Actions / Solved CTA Buttons
                  if (!isSolved)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _CompactActionIcon(
                            icon: state.isBulbGlowing
                                ? Icons.lightbulb_rounded
                                : Icons.lightbulb_outline_rounded,
                            tooltip: 'Hint',
                            isEnabled: !state.isHintLoading,
                            isActive: state.isBulbGlowing,
                            activeColor: ScholarlyTheme.accentYellowSoft,
                            activeIconColor: ScholarlyTheme.accentYellow,
                            onTap: () => notifier.requestHint(),
                          ),
                          const SizedBox(width: 16),
                          _CompactActionIcon(
                            icon: Icons.replay_rounded,
                            tooltip: 'Reset Puzzle',
                            isEnabled: true,
                            onTap: () => notifier.resetPuzzleLine(),
                          ),
                          const SizedBox(width: 16),
                          _CompactActionIcon(
                            icon: Icons.skip_next_rounded,
                            tooltip: 'Skip Puzzle',
                            isEnabled: true,
                            onTap: () async {
                              if (state.solvedCount >= 5) {
                                await ref.read(puzzlesProvider.notifier).exitPuzzleMode();
                                if (context.mounted) {
                                  ref.read(mobileNavIndexProvider.notifier).state = 1; // Back to Arena
                                }
                              } else {
                                if (!_checkPuzzleLimitAndUpsell(context, ref)) return;
                                ref.read(storeProvider.notifier).recordPuzzle();
                                notifier.nextPrescriptionPuzzle(silent: true);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    PuzzlesState state,
    PuzzlesNotifier notifier,
  ) {
    final bool isSolved = state.puzzleMovesRemaining.isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT COLUMN (Chessboard Area) - taking 55% of the space
        Expanded(
          flex: 11,
          child: const Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: PuzzlesBoard(alignment: Alignment.center),
            ),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Puzzle Status Header (Moved to top of right column)
                _PuzzleStatusHeader(state: state),
                const SizedBox(height: 6),

                // Pressure Cooker Countdown Timer
                if (state.isPressureCookerActive && !isSolved) ...[
                  const PressureCookerTimer(),
                  const SizedBox(height: 6),
                ],

                if (state.isWrongMoveAttempted && !isSolved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Incorrect move. Try again!',
                              style: GoogleFonts.inter(
                                color: Colors.red.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const Spacer(),

                 // Chanakya Speech Bubble
                if (state.commentaryHistory.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/persona/gm_chanakya.webp'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "GM CHANAKYA",
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: ScholarlyTheme.accentBlue,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: GoogleFonts.comicNeue(
                                    fontSize: 15,
                                    color: const Color(0xFF1E293B),
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                  children: _buildHighlightedText(state.commentaryHistory.last.text),
                                ),
                              ),
                              if (isSolved) ...[
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (state.solvedCount >= 5) {
                                        await ref.read(puzzlesProvider.notifier).exitPuzzleMode();
                                        if (context.mounted) {
                                          ref.read(mobileNavIndexProvider.notifier).state = 1; // Back to Arena
                                        }
                                      } else {
                                        if (!_checkPuzzleLimitAndUpsell(context, ref)) return;
                                        ref.read(storeProvider.notifier).recordPuzzle();
                                        notifier.nextPrescriptionPuzzle(silent: true);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981), // Emerald
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                                    label: Text(
                                      state.solvedCount >= 5 ? 'Test Progress in Arena' : 'Move to Next Puzzle',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // 3. Actions Row / Solved CTA Buttons
                if (!isSolved)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CompactActionIcon(
                          icon: state.isBulbGlowing
                              ? Icons.lightbulb_rounded
                              : Icons.lightbulb_outline_rounded,
                          tooltip: 'Hint',
                          isEnabled: !state.isHintLoading,
                          isActive: state.isBulbGlowing,
                          activeColor: ScholarlyTheme.accentYellowSoft,
                          activeIconColor: ScholarlyTheme.accentYellow,
                          onTap: () => notifier.requestHint(),
                        ),
                        const SizedBox(width: 16),
                        _CompactActionIcon(
                          icon: Icons.replay_rounded,
                           tooltip: 'Reset Puzzle',
                          isEnabled: true,
                          onTap: () => notifier.resetPuzzleLine(),
                        ),
                        const SizedBox(width: 16),
                        _CompactActionIcon(
                          icon: Icons.skip_next_rounded,
                          tooltip: 'Skip Puzzle',
                          isEnabled: true,
                          onTap: () async {
                            if (state.solvedCount >= 5) {
                              await ref.read(puzzlesProvider.notifier).exitPuzzleMode();
                              if (context.mounted) {
                                ref.read(mobileNavIndexProvider.notifier).state = 1; // Back to Arena
                              }
                            } else {
                              if (!_checkPuzzleLimitAndUpsell(context, ref)) return;
                              ref.read(storeProvider.notifier).recordPuzzle();
                              notifier.nextPrescriptionPuzzle(silent: true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLockedView(BuildContext context, BattlegroundState bgState) {
    return AmbientScaffold(
      blob1Color: const Color(0xFFF0F9FF),
      blob2Color: const Color(0xFFFDF2F8),
      blob3Color: const Color(0xFFFFFBEB),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.panelBase.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(color: ScholarlyTheme.borderMedium, width: 2),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: ScholarlyTheme.accentOrange,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'PUZZLES LOCKED',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Complete 10 rated Battleground games to calibrate your strength and unlock personalized puzzle training.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: ScholarlyTheme.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Calibration Progress Bar
              Container(
                width: 240,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.panelBase.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ScholarlyTheme.borderLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${bgState.totalRatedGamesCount}/10 games',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.accentOrange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (bgState.totalRatedGamesCount / 10).clamp(0.0, 1.0),
                        backgroundColor: ScholarlyTheme.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(ScholarlyTheme.accentOrange),
                        minHeight: 8,
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
    final assignmentState = ref.watch(assignmentProvider);
    final bgState = ref.watch(battlegroundProvider);

    if (!assignmentState.isCalibrated || bgState.totalRatedGamesCount < 10) {
      return _buildLockedView(context, bgState);
    }

    final state = ref.watch(puzzlesProvider);
    final notifier = ref.read(puzzlesProvider.notifier);
    final showIntro = ref.watch(showPuzzlesIntroProvider);
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    final storeState = ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);
    final isPremium = storeState.isPremium;
    final isLimitReached = !isPremium &&
        !storeNotifier.canSolvePuzzle() &&
        !(state.isPuzzleMode && state.currentPuzzle != null && state.puzzleMovesRemaining.isNotEmpty);

    if (isLimitReached) {
      return const PremiumNudgeOverlay(
        isFullScreen: true,
        title: 'Daily Puzzle Limit Reached',
        description: 'You have solved/attempted your 3 free Puzzles for today. Upgrade to unlock unlimited puzzles.',
      );
    }

    ref.listen<int>(mobileNavIndexProvider, (previous, current) {
      if (previous == 4 && current != 4) {
        final repo = ref.read(tutorialProgressRepositoryProvider);
        if (!repo.shouldPersistIntroSeen()) {
          ref.read(showPuzzlesIntroProvider.notifier).state = true;
        }
      }

      if (current == 4 && !ref.read(puzzlesProvider).isPuzzleMode) {
        if (!_checkPuzzleLimitAndUpsell(context, ref)) {
          ref.read(mobileNavIndexProvider.notifier).state = 0; // Redirect to Dashboard
          return;
        }
        ref.read(storeProvider.notifier).recordPuzzle();
        ref.read(puzzlesProvider.notifier).startPrescriptionMode(silent: true);
      }
    });

    ref.listen<PuzzlesState>(puzzlesProvider, (previous, current) {
      final wasSolved = previous?.puzzleMovesRemaining.isEmpty ?? false;
      final isSolved = current.puzzleMovesRemaining.isEmpty;
      if (isSolved && !wasSolved && current.currentPuzzle != null && !_hasTriggeredConfetti) {
        _hasTriggeredConfetti = true;
        _confettiController.play();
      } else if (!isSolved) {
        _hasTriggeredConfetti = false;
      }
    });

    return AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: const Color(0xFFF0F9FF), // Very light blue
        blob2Color: const Color(0xFFFDF2F8), // Very light pink
        blob3Color: const Color(0xFFFFFBEB), // Very light amber
        body: Stack(
          children: [
            SafeArea(
              top: false,
              child: isLandscape
                  ? _buildLandscapeLayout(context, state, notifier)
                  : _buildPortraitLayout(context, state, notifier),
            ),
            
            // Confetti Cannon Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                  Colors.yellow,
                ],
              ),
            ),
            if (showIntro)
              GMChanakyaIntroOverlay(
                pageTitle: 'PUZZLES',
                text: 'This chamber trains tactical sight. Solve tailored puzzles to sharpen patterns, reduce blind spots, and strengthen calculation.',
                onDismiss: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  ref.read(showPuzzlesIntroProvider.notifier).state = false;
                  final repo = ref.read(tutorialProgressRepositoryProvider);
                  if (repo.shouldPersistIntroSeen()) {
                    repo.setPuzzlesIntroSeen(true);
                  }
                },
              ),
          ],
        ),
      );
  }

  bool _checkPuzzleLimitAndUpsell(BuildContext context, WidgetRef ref) {
    final storeNotifier = ref.read(storeProvider.notifier);
    if (!storeNotifier.canSolvePuzzle()) {
      PremiumNudgeOverlay.show(
        context,
        ref,
        title: 'Daily Puzzle Limit Reached',
        description: 'You have solved/attempted your 3 free Puzzles for today. Upgrade to unlock unlimited puzzles.',
        onDismiss: () => exitToDashboardWithSidebar(context, ref),
      );
      return false;
    }
    return true;
  }
}

class _PuzzleStatusHeader extends ConsumerWidget {
  final PuzzlesState state;

  const _PuzzleStatusHeader({required this.state});

  String _getToughness(int rating) {
    if (rating < 1100) return 'Beginner';
    if (rating < 1500) return 'Easy';
    if (rating < 1900) return 'Medium';
    if (rating < 2300) return 'Hard';
    return 'Expert';
  }

  String _getInstructionText(rust_puzzles.Puzzle puzzle) {
    final themesList = puzzle.themes.split(' ');
    final mateTheme = themesList.firstWhere(
      (t) => t.startsWith('mateIn'),
      orElse: () => '',
    );
    if (mateTheme.isNotEmpty) {
      final count = mateTheme.replaceAll('mateIn', '');
      return 'Mate in $count';
    }
    
    final playerMovesCount = (puzzle.moves.length / 2).ceil();
    if (playerMovesCount == 1) {
      return 'Find the winning move';
    } else {
      return 'Find the winning sequence ($playerMovesCount moves)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = state.currentPuzzle;
    final bool isSolved = state.puzzleMovesRemaining.isEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSolved 
                ? Colors.green.withValues(alpha: 0.1) 
                : ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSolved 
                  ? Colors.greenAccent.withValues(alpha: 0.3) 
                  : ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isSolved ? Colors.greenAccent : ScholarlyTheme.accentBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isSolved ? Colors.greenAccent : ScholarlyTheme.accentBlue).withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Icon(
                  isSolved ? Icons.check_rounded : Icons.extension_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSolved
                          ? 'SOLVED (COUNT ${state.solvedCount}/5)'
                          : (p != null
                              ? '${_getToughness(p.rating).toUpperCase()} TOUGHNESS (COUNT ${state.solvedCount}/5)'
                              : (state.commentaryError != null
                                  ? 'ERROR'
                                  : 'LOADING...')),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSolved
                            ? Colors.green.shade700
                            : (state.commentaryError != null
                                ? Colors.redAccent
                                : ScholarlyTheme.textPrimary),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 0.5),
                    if (state.commentaryError != null && p == null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.commentaryError!,
                              style: GoogleFonts.inter(
                                fontSize: 9.5,
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => ref
                                .read(puzzlesProvider.notifier)
                                .nextPrescriptionPuzzle(silent: true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                'RETRY',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (p != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: state.isPlayerWhite ? Colors.white : const Color(0xFF1E293B),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 1.5,
                                    spreadRadius: 0.2,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${state.isPlayerWhite ? "White" : "Black"} to play • ${_getInstructionText(p)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11.0,
                                  color: ScholarlyTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (!isSolved && p != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(state.puzzleMovesRemaining.length / 2).ceil()} LEFT',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.accentBlue,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactActionIcon extends StatefulWidget {
  const _CompactActionIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.isEnabled = true,
    this.isActive = false,
    this.activeColor,
    this.activeIconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isEnabled;
  final bool isActive;
  final Color? activeColor;
  final Color? activeIconColor;

  @override
  State<_CompactActionIcon> createState() => _CompactActionIconState();
}

class _CompactActionIconState extends State<_CompactActionIcon> {
  bool _isPressed = false;

  List<Color> _getGradientColors() {
    final icon = widget.icon;
    if (icon == Icons.lightbulb_rounded || icon == Icons.lightbulb_outline_rounded) {
      return const [Color(0xFFEAB308), Color(0xFFCA8A04)];
    } else if (icon == Icons.replay_rounded) {
      return const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
    } else if (icon == Icons.skip_next_rounded) {
      return const [Color(0xFF0EA5E9), Color(0xFF0284C7)];
    }
    return const [Color(0xFF0D6EFD), Color(0xFF0A58CA)];
  }

  Color _getGlowColor() {
    final icon = widget.icon;
    if (icon == Icons.lightbulb_rounded || icon == Icons.lightbulb_outline_rounded) {
      return const Color(0xFFFDE047);
    } else if (icon == Icons.replay_rounded) {
      return const Color(0xFFA78BFA);
    } else if (icon == Icons.skip_next_rounded) {
      return const Color(0xFF38BDF8);
    }
    return const Color(0xFF3B82F6);
  }

  Color _getBorderColor() {
    final icon = widget.icon;
    if (icon == Icons.lightbulb_rounded || icon == Icons.lightbulb_outline_rounded) {
      return const Color(0xFFFEF08A);
    } else if (icon == Icons.replay_rounded) {
      return const Color(0xFFC084FC);
    } else if (icon == Icons.skip_next_rounded) {
      return const Color(0xFF7DD3FC);
    }
    return const Color(0xFF60A5FA);
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    final glowColor = _getGlowColor();
    final borderColor = _getBorderColor();

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: widget.isEnabled
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
              ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isEnabled
              ? borderColor.withValues(alpha: 0.6)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          if (widget.isEnabled)
            BoxShadow(
              color: glowColor.withValues(alpha: widget.isActive ? 0.5 : (_isPressed ? 0.4 : 0.25)),
              blurRadius: widget.isActive ? 12.0 : (_isPressed ? 14.0 : 8.0),
              spreadRadius: _isPressed ? 2.5 : 1.0,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            if (widget.isEnabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.28),
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            Center(
              child: Icon(
                widget.icon,
                size: 22,
                color: widget.isEnabled
                    ? Colors.white
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );

    final wrappedContent = widget.tooltip != null
        ? Tooltip(
            message: widget.tooltip!,
            decoration: BoxDecoration(
              color: ScholarlyTheme.backgroundDark.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            child: content,
          )
        : content;

    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: _isPressed ? Curves.easeOutCubic : Curves.elasticOut,
        child: wrappedContent,
      ),
    );
  }
}

List<InlineSpan> _buildHighlightedText(String text) {
  final List<InlineSpan> spans = [];
  final words = text.split(' ');
  for (int i = 0; i < words.length; i++) {
    final word = words[i];
    final cleanWord = word.replaceAll(RegExp(r'[.,!?:;🕉️]'), '').toLowerCase();
    
    Color? highlightColor;
    FontWeight fontWeight = FontWeight.normal;
    
    if (['apprentice', 'warrior', 'tactician'].contains(cleanWord)) {
      highlightColor = const Color(0xFFD97706); // Warm Amber
      fontWeight = FontWeight.bold;
    } else if (['diagonal', 'lateral', 'horizontal', 'flank', 'board', 'coordinates'].contains(cleanWord)) {
      highlightColor = const Color(0xFF2563EB); // Royal Blue
      fontWeight = FontWeight.bold;
    } else if (['bishop', 'rook', 'knight', 'king', 'piece', 'pieces', 'defender'].contains(cleanWord)) {
      highlightColor = const Color(0xFF7C3AED); // Purple
      fontWeight = FontWeight.bold;
    } else if (['scotoma', 'blindness', 'threat', 'greed', 'pinned', 'panic', 'danger', 'mating', 'checkmate', 'error', 'hasty', 'regret', 'vulnerable', 'frustration'].contains(cleanWord)) {
      highlightColor = const Color(0xFFDC2626); // Crimson Red
      fontWeight = FontWeight.bold;
    } else if (['discipline', 'calculation', 'sight', 'victory', 'patience', 'complete', 'completed', 'prescription', 'balance', 'mastery'].contains(cleanWord)) {
      highlightColor = const Color(0xFF059669); // Emerald Green
      fontWeight = FontWeight.bold;
    } else if (RegExp(r'^\d+$').hasMatch(cleanWord)) {
      highlightColor = const Color(0xFF4F46E5); // Indigo for numbers
      fontWeight = FontWeight.bold;
    }
    
    if (highlightColor != null) {
      spans.add(TextSpan(
        text: word,
        style: TextStyle(
          color: highlightColor,
          fontWeight: fontWeight,
        ),
      ));
    } else {
      spans.add(TextSpan(text: word));
    }
    
    if (i < words.length - 1) {
      spans.add(const TextSpan(text: ' '));
    }
  }
  return spans;
}


