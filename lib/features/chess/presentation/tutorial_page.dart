import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/tutorial_provider.dart';
import '../application/onboarding_provider.dart';
import '../application/chess_provider.dart';
import '../services/chess_sound_service.dart';
import 'scholarly_theme.dart';
import 'tutorial_board_stage.dart';
import 'widgets/chapter_completion_overlay.dart';
import 'widgets/chapter_select_screen.dart';
import 'widgets/illegal_move_feedback.dart';
import 'widgets/mentor_panel.dart';
import 'widgets/ambient_scaffold.dart';
import 'dashboard_page.dart';


class TutorialPage extends ConsumerStatefulWidget {
  const TutorialPage({super.key});

  @override
  ConsumerState<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends ConsumerState<TutorialPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _handleChapterSelected(int chapterId) {
    ref.read(tutorialProvider.notifier).loadChapter(chapterId);
    ref.read(showChapterSelectionProvider.notifier).state = false;
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
            // In onboarding, complete or skip goes to next milestone
            OnboardingService(ref).skipToNextMilestone(state.currentLesson.chapterId);
          } else {
            // Determine if target next chapter falls within active bounds
            // Otherwise loop back to selection dashboard cleanly
            if (nextChap <= 23) {
              _handleChapterSelected(nextChap);
            } else {
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
      content = AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: const Color(0xFFFEF9C3), // Soft Gold
        blob2Color: const Color(0xFFDBEAFE), // Soft Blue
        blob3Color: const Color(0xFFF3E8FF), // Soft Purple
        body: SafeArea(
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

              // 3. Bottom Action / Breadcrumb Header Strip (now at bottom)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: JuicyGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => ref.read(showChapterSelectionProvider.notifier).state = true,
                        icon: const Icon(Icons.grid_view_rounded, size: 20, color: ScholarlyTheme.accentBlue),
                        tooltip: 'Chapter Selection',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      if (ref.watch(isOnboardingProvider)) ...[
                        TextButton.icon(
                          onPressed: () {
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                            OnboardingService(ref).skipToNextMilestone(state.currentLesson.chapterId);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: ScholarlyTheme.accentBlue,
                          ),
                          icon: const Icon(Icons.skip_next_rounded, size: 16),
                          label: Text(
                            'Skip Guide',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final showCompact = constraints.maxWidth < 160;
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        showCompact
                                            ? 'CH. ${state.currentLesson.chapterId}'
                                            : 'CHAPTER ${state.currentLesson.chapterId}',
                                        style: GoogleFonts.inter(
                                          color: ScholarlyTheme.accentBlue,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.0,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        showCompact
                                            ? '${state.currentStepIndex + 1}/${state.currentLesson.steps.length}'
                                            : 'STEP ${state.currentStepIndex + 1} OF ${state.currentLesson.steps.length}',
                                        style: GoogleFonts.inter(
                                          color: ScholarlyTheme.textMuted,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (state.currentStepIndex + 1) / state.currentLesson.steps.length,
                                backgroundColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                                color: ScholarlyTheme.accentBlue,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (state.isChapterComplete) {
          ref.read(tutorialProvider.notifier).loadChapter(state.currentChapterIndex);
          ref.read(showChapterSelectionProvider.notifier).state = true;
        } else if (!ref.read(showChapterSelectionProvider)) {
          ref.read(showChapterSelectionProvider.notifier).state = true;
        } else {
          exitToDashboardWithSidebar(context, ref);
        }
      },
      child: content,
    );
  }
}
