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
import 'widgets/global_sidebar.dart';
import 'widgets/game_controls.dart';


class TutorialPage extends ConsumerStatefulWidget {
  const TutorialPage({super.key});

  @override
  ConsumerState<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends ConsumerState<TutorialPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isChapterSelectionVisible = true;

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


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);


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
      return ChapterSelectScreen(onSelectChapter: _handleChapterSelected);
    }

    // 3. Main Active Lesson Runtime Surface
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ScholarlyTheme.backgroundStart,
      drawer: const GlobalSidebar(),
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
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: ScholarlyTheme.modernDecoration().copyWith(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ActionIconButton(
                      icon: Icons.menu_rounded,
                      size: 20,
                      onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => setState(() => _isChapterSelectionVisible = true),
                      icon: const Icon(Icons.grid_view_rounded, size: 20, color: ScholarlyTheme.accentBlue),
                      tooltip: 'Chapter Selection',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
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
          ],
        ),
      ),
    );
  }
}
