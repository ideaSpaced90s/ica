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
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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

    return Column(
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
                        image: AssetImage('assets/persona/gm_chanakya.png'),
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
                              image: AssetImage('assets/persona/gm_chanakya.png'),
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(puzzlesProvider);
    final notifier = ref.read(puzzlesProvider.notifier);
    final showIntro = ref.watch(showPuzzlesIntroProvider);
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    ref.listen<int>(mobileNavIndexProvider, (previous, current) {
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        await _requestExitPuzzle();
      },
      child: AmbientScaffold(
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
                text: "The Puzzles chamber, Apprentice, is where we address chess blindspots and train your tactical sight. Chess is won in the details—the double attacks, the pins, the sudden checkmates that the untrained mind overlooks. In this room, you must solve a daily tailored challenge of hand-picked puzzle scenarios. Each puzzle is a tactical riddle designed to sharpen your pattern recognition and build muscle memory. The puzzles will help you even more if you play more rated games. Tap the thumbs up to begin your mental training. Let us see how quickly you spot the winning line.",
                onDismiss: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  ref.read(showPuzzlesIntroProvider.notifier).state = false;
                  final repo = ref.read(tutorialProgressRepositoryProvider);
                  // Non-blocking save
                  repo.setPuzzlesIntroSeen(true);
                },
              ),
          ],
        ),
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
                            Text(
                              '${state.isPlayerWhite ? "White" : "Black"} to play • ${_getInstructionText(p)}',
                              style: GoogleFonts.inter(
                                fontSize: 11.0,
                                color: ScholarlyTheme.textPrimary,
                                fontWeight: FontWeight.w700,
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

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (widget.isActive || _isPressed)
            ? (widget.activeColor?.withValues(alpha: 0.2) ?? ScholarlyTheme.accentBlue.withValues(alpha: 0.15))
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (widget.isActive || _isPressed)
              ? (widget.activeIconColor ?? ScholarlyTheme.accentBlue).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          widget.icon,
          size: 22,
          color: widget.isEnabled
              ? (widget.isActive
                    ? (widget.activeIconColor ?? ScholarlyTheme.accentBlue)
                    : ScholarlyTheme.textPrimary)
              : ScholarlyTheme.textSubtle,
        ),
      ),
    );

    final wrappedContent = widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: content)
        : content;

    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isEnabled ? widget.onTap : null,
      child: wrappedContent,
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

