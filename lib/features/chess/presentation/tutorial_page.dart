import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/tutorial_provider.dart';
import '../application/onboarding_provider.dart';
import '../application/chess_provider.dart';
import '../domain/models/tutorial_constants.dart';
import '../services/chess_sound_service.dart';
import 'scholarly_theme.dart';
import 'tutorial_board_stage.dart';
import 'widgets/chapter_completion_overlay.dart';
import 'widgets/chapter_select_screen.dart';
import 'widgets/illegal_move_feedback.dart';
import 'widgets/mentor_panel.dart';
import 'widgets/ambient_scaffold.dart';
import 'mobile_navigation_shell.dart';
import 'dashboard_page.dart';


class TutorialPage extends ConsumerStatefulWidget {
  const TutorialPage({super.key});

  @override
  ConsumerState<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends ConsumerState<TutorialPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _getGroupName(int chapterId) {
    if (chapterId >= 1 && chapterId <= 8) return 'Foundations';
    if (chapterId >= 9 && chapterId <= 17) return 'Special Rules';
    if (chapterId >= 18 && chapterId <= 25) return 'Tactics Set 1';
    if (chapterId >= 26 && chapterId <= 31) return 'Tactics Set 2';
    if (chapterId >= 32 && chapterId <= 36) return 'Practical Openings';
    if (chapterId >= 37 && chapterId <= 43) return 'Endgame Technique';
    if (chapterId >= 44 && chapterId <= 47) return 'Pawn Strategy';
    if (chapterId >= 48 && chapterId <= 53) return 'Tactics Master Class';
    if (chapterId >= 54 && chapterId <= 55) return 'Mastery';
    return 'Tutorial';
  }

  void _confirmSkip(BuildContext context, int chapterId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Skip Chapter?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to skip this chapter and proceed to the next lesson?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
              OnboardingService(ref).advanceGuidedTutorial(chapterId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ScholarlyTheme.accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Skip',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(backButtonOverridesProvider.notifier).update((map) => {
          ...map,
          7: _handleBackPress,
        });
      }
    });
  }

  @override
  void dispose() {
    ref.read(backButtonOverridesProvider.notifier).update((map) {
      final newMap = Map<int, Future<bool> Function()>.from(map);
      newMap.remove(7);
      return newMap;
    });
    super.dispose();
  }

  Future<bool> _handleBackPress() async {
    final state = ref.read(tutorialProvider);
    if (state.isChapterComplete) {
      ref.read(tutorialProvider.notifier).loadChapter(state.currentChapterIndex);
      ref.read(showChapterSelectionProvider.notifier).state = true;
      return true;
    } else if (!ref.read(showChapterSelectionProvider)) {
      await showTutorialExitPrompt(context, ref);
      return true;
    }
    return false;
  }

  void _handleChapterSelected(int chapterId) {
    ref.read(tutorialProvider.notifier).loadChapter(chapterId);
    ref.read(showChapterSelectionProvider.notifier).state = false;
  }

  Widget _buildLandscapeLayout(BuildContext context, TutorialState state) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left column: Chess board (taking square aspect ratio)
            const Expanded(
              flex: 11,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: TutorialIllegalMoveFeedback(
                    child: TutorialBoardStage(),
                  ),
                ),
              ),
            ),

            // Separator
            Container(
              width: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
            ),

            // Right column: Mentor panel and progress footer
            Expanded(
              flex: 9,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const Expanded(
                    child: TutorialMentorPanel(),
                  ),
                  const SizedBox(height: 8),
                  _buildProgressFooter(state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);
    final isChapterSelectionVisible = ref.watch(showChapterSelectionProvider);

    Widget content;

    // 1. Chapter Graduation Intercept Overlay
    if (state.isChapterComplete) {
      content = ChapterCompletionOverlay(
        onNextChapter: () {
          final nextChap = state.currentChapterIndex + 1;
          if (ref.read(isOnboardingProvider)) {
            OnboardingService(ref).advanceGuidedTutorial(state.currentLesson.chapterId);
          } else {
            // Determine if target next chapter falls within active bounds
            // Otherwise loop back to selection dashboard cleanly
            if (nextChap <= kTutorialChapterCount) {
              _handleChapterSelected(nextChap);
            } else {
              ref.read(tutorialProvider.notifier).dismissCompletionOverlay();
              ref.read(showChapterSelectionProvider.notifier).state = true;
            }
          }
        },
      );
    }
    // 2. Main Module Browser / Dashboard
    else if (isChapterSelectionVisible) {
      content = ChapterSelectScreen(onSelectChapter: _handleChapterSelected);
    }
    // 3. Main Active Lesson Runtime Surface
    else {
      final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;
      
      content = AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: const Color(0xFFFEF9C3), // Soft Gold
        blob2Color: const Color(0xFFDBEAFE), // Soft Blue
        blob3Color: const Color(0xFFF3E8FF), // Soft Purple
        body: isLandscape
            ? _buildLandscapeLayout(context, state)
            : SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Top side chessboard taking exact square space, extending edge-to-edge
                    const AspectRatio(
                      aspectRatio: 1.0,
                      child: TutorialIllegalMoveFeedback(
                        child: TutorialBoardStage(),
                      ),
                    ),

                    // 2. Base adaptive advisor panel claiming remaining space
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: TutorialMentorPanel(),
                      ),
                    ),

                    _buildProgressFooter(state),
                  ],
                ),
              ),
      );
    }

    return content;
  }

  Widget _buildProgressFooter(TutorialState state) {
    final isGuided = ref.watch(isOnboardingProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: JuicyGlassCard(
        padding: const EdgeInsets.all(12),
        borderRadius: 14,
        borderColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.18),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                ref.read(showChapterSelectionProvider.notifier).state = true;
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.grid_view_rounded,
                      size: 20,
                      color: ScholarlyTheme.accentBlue,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chapters',
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.accentBlue,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getGroupName(state.currentLesson.chapterId).toUpperCase(),
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.accentBlue,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chapter ${state.currentLesson.chapterId}: ${state.currentLesson.title}',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${state.currentStepIndex + 1}/${state.currentLesson.steps.length}',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (state.currentStepIndex + 1) / state.currentLesson.steps.length,
                      backgroundColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.55),
                      color: ScholarlyTheme.accentBlue,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            if (isGuided) ...[
              const SizedBox(width: 10),
              TextButton.icon(
                onPressed: () => _confirmSkip(context, state.currentLesson.chapterId),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: ScholarlyTheme.accentBlue,
                ),
                icon: const Icon(Icons.skip_next_rounded, size: 16),
                label: Text(
                  'Skip',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool> showTutorialExitPrompt(BuildContext context, WidgetRef ref) async {
  final tutorialState = ref.read(tutorialProvider);
  final isChapterSelectionVisible = ref.read(showChapterSelectionProvider);
  if (tutorialState.isChapterComplete || isChapterSelectionVisible) {
    return false;
  }

  final result = await showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        surfaceTintColor: ScholarlyTheme.accentBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.5),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 36,
                backgroundImage: AssetImage('assets/persona/gm_chanakya.webp'),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'GM Chanakya',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: ScholarlyTheme.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        content: Text(
          'Apprentice, this chapter will wait for you. Complete it in your own due time, but do not leave your training unfinished for long.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textPrimary,
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop('stay'),
                style: FilledButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'STAY',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop('exit'),
                child: Text(
                  'EXIT TO DASHBOARD',
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );

  if (result == 'exit' && context.mounted) {
    exitToDashboardWithSidebar(context, ref);
  }
  return true;
}
