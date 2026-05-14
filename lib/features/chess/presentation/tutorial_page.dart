import 'package:flutter/material.dart';
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
                child: Row(
                  children: [
                    const Icon(Icons.restore_rounded, color: Colors.black, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MID-LESSON SESSION RECOVERED',
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Dismiss snapshot and allow browse
                        ref.read(tutorialProvider.notifier).clearIllegalFeedback();
                        // Trigger immediate state reload clean loop
                        ref.read(tutorialProvider.notifier).loadChapter(1);
                      },
                      child: Text(
                        'Restart Chapter',
                        style: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _resumeSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: ScholarlyTheme.accentYellow,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text('Resume', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
      backgroundColor: ScholarlyTheme.panelBase,
      body: SafeArea(
        child: Row(
          children: [
            // Left Action / Breadcrumb Header Column
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isChapterSelectionVisible = true),
                    icon: const Icon(Icons.grid_view_rounded, color: ScholarlyTheme.textSubtle),
                    tooltip: 'Chapter Selection',
                  ),
                  const Spacer(),
                  // Progress metrics indicator
                  Text(
                    '${state.currentStepIndex + 1}/${state.currentLesson.steps.length}',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textSubtle,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    width: 4,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: LinearProgressIndicator(
                        value: (state.currentStepIndex + 1) / state.currentLesson.steps.length,
                        backgroundColor: ScholarlyTheme.panelStroke,
                        color: ScholarlyTheme.accentBlueSoft,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // Isolated interactive board container
            const Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: TutorialIllegalMoveFeedback(
                  child: TutorialBoardStage(),
                ),
              ),
            ),

            // Right adaptive advisor side panel
            const Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.only(top: 16, bottom: 16, right: 16),
                child: TutorialMentorPanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
