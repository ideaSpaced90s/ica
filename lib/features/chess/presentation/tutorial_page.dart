import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../application/tutorial_provider.dart';
import 'scholarly_theme.dart';
import 'tutorial_board_stage.dart';
import 'widgets/chapter_completion_overlay.dart';
import 'widgets/chapter_select_screen.dart';
import 'widgets/illegal_move_feedback.dart';
import 'widgets/mentor_panel.dart';

class TutorialPage extends ConsumerStatefulWidget {
  const TutorialPage({super.key});

  @override
  ConsumerState<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends ConsumerState<TutorialPage> {
  bool _isChapterSelectionVisible = true;
  bool _hasCheckedResumePrompt = false;

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
    setState(() {
      _isChapterSelectionVisible = false;
    });
  }

  void _resumeSession() {
    ref.read(tutorialProvider.notifier).resumeActiveSession();
    setState(() {
      _isChapterSelectionVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);

    // Evaluate single-run initial mid-lesson resume check
    final p = state.progress;
    if (!_hasCheckedResumePrompt && p.hasActiveSession) {
      _hasCheckedResumePrompt = true;
      // Show active session check inline below
    } else if (!_hasCheckedResumePrompt) {
      _hasCheckedResumePrompt = true;
    }

    // 1. Chapter Graduation Intercept Overlay
    if (state.isChapterComplete) {
      return ChapterCompletionOverlay(
        onNextChapter: () {
          final nextChap = state.currentChapterIndex + 1;
          // Determine if target next chapter falls within active bounds
          // Otherwise loop back to selection dashboard cleanly
          if (nextChap <= 23) {
            _handleChapterSelected(nextChap);
          } else {
            setState(() => _isChapterSelectionVisible = true);
          }
        },
      );
    }

    // 2. Main Module Browser / Dashboard
    if (_isChapterSelectionVisible) {
      return Stack(
        children: [
          ChapterSelectScreen(onSelectChapter: _handleChapterSelected),

          // Mid-Lesson recovery prompt banner overlay
          if (p.hasActiveSession)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.accentYellow.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.accentYellow.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restore_rounded, color: Colors.black, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SESSION RECOVERED',
                                style: GoogleFonts.inter(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                'Resume Chapter ${p.activeChapterIndex} from Step ${p.activeStepIndex}?',
                                style: GoogleFonts.inter(
                                  color: Colors.black87,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            ref.read(tutorialProvider.notifier).clearIllegalFeedback();
                            ref.read(tutorialProvider.notifier).loadChapter(1);
                          },
                          child: Text(
                            'Restart',
                            style: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _resumeSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: ScholarlyTheme.accentYellow,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: Text('Resume', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // 3. Main Active Lesson Runtime Surface
    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Action / Breadcrumb Header Strip matching the app's modern glass panels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: ScholarlyTheme.modernDecoration().copyWith(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _isChapterSelectionVisible = true),
                      icon: const Icon(Icons.grid_view_rounded, size: 20, color: ScholarlyTheme.accentBlue),
                      tooltip: 'Chapter Selection',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'CHAPTER ${state.currentLesson.chapterId}',
                                style: GoogleFonts.inter(
                                  color: ScholarlyTheme.accentBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'STEP ${state.currentStepIndex + 1} OF ${state.currentLesson.steps.length}',
                                style: GoogleFonts.inter(
                                  color: ScholarlyTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
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

            // Isolated interactive board container
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: TutorialIllegalMoveFeedback(
                  child: TutorialBoardStage(),
                ),
              ),
            ),

            // Base adaptive advisor bottom panel
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: TutorialMentorPanel(),
            ),
          ],
        ),
      ),
    );
  }
}
