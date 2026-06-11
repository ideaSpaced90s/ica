import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/tutorial_provider.dart';
import '../../data/tutorial_lessons.dart';
import '../../domain/models/tutorial_constants.dart';
import '../scholarly_theme.dart';

class ChapterCompletionOverlay extends ConsumerStatefulWidget {
  const ChapterCompletionOverlay({super.key, required this.onNextChapter});

  final VoidCallback onNextChapter;

  @override
  ConsumerState<ChapterCompletionOverlay> createState() => _ChapterCompletionOverlayState();
}

class _ChapterCompletionOverlayState extends ConsumerState<ChapterCompletionOverlay> with TickerProviderStateMixin {
  late final AnimationController _enterController;
  late final AnimationController _star1Controller;
  late final AnimationController _star2Controller;
  late final AnimationController _star3Controller;
  int _earnedStars = 3;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _star1Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _star2Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _star3Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    _enterController.forward().then((_) => _animateStarsSequence());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = ref.read(tutorialProvider);
    if (state.mistakesMadeInChapter == 1) _earnedStars = 2;
    if (state.mistakesMadeInChapter > 1) _earnedStars = 1;
  }

  void _animateStarsSequence() async {
    if (!mounted) return;
    await _star1Controller.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 200));

    if (_earnedStars >= 2) {
      await _star2Controller.forward();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (_earnedStars >= 3) {
      await _star3Controller.forward();
    }
  }

  @override
  void dispose() {
    _enterController.dispose();
    _star1Controller.dispose();
    _star2Controller.dispose();
    _star3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tutorialProvider);
    final xpEarned = TutorialRewards.calculateXp(_earnedStars);
    final nextChapterId = state.currentLesson.chapterId + 1;
    final hasNextChapter = nextChapterId <= kTutorialChapterCount;
    final nextLesson = hasNextChapter ? TutorialLessonsDatabase.getLesson(nextChapterId) : null;

    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart.withValues(alpha: 0.85),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _enterController, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: CurvedAnimation(parent: _enterController, curve: Curves.easeOutBack),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.backgroundStart,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ScholarlyTheme.accentGold.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.accentGold.withValues(alpha: 0.15),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  // Crown icon accent
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.accentGold.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.emoji_events_rounded, size: 48, color: ScholarlyTheme.accentGold),
                  ),
                  
                  const SizedBox(height: 20),

                  Text(
                    hasNextChapter ? 'CHAPTER COMPLETE' : 'ACADEMY COMPLETE',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.accentGold,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  
                  const SizedBox(height: 8),

                  Text(
                    state.currentLesson.title,
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Star rating tally dashboard
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedStar(_star1Controller, _earnedStars >= 1),
                      const SizedBox(width: 16),
                      // Elevate middle star slightly for balanced classic styling
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: _buildAnimatedStar(_star2Controller, _earnedStars >= 2),
                      ),
                      const SizedBox(width: 16),
                      _buildAnimatedStar(_star3Controller, _earnedStars >= 3),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    '3 Stars: No Mistakes | 2 Stars: 1 Mistake | 1 Star: Completed',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.8)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          hasNextChapter ? Icons.route_rounded : Icons.workspace_premium_rounded,
                          size: 18,
                          color: hasNextChapter ? ScholarlyTheme.accentBlue : ScholarlyTheme.realGold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            hasNextChapter
                                ? 'Next: Chapter $nextChapterId - ${nextLesson!.title}'
                                : 'You have mastered all $kTutorialChapterCount chapters.',
                            style: GoogleFonts.inter(
                              color: ScholarlyTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // XP summary bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 20, color: ScholarlyTheme.accentBlue),
                        const SizedBox(width: 8),
                        Text(
                          '+$xpEarned XP Earned',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.accentBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Actions block
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onNextChapter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScholarlyTheme.accentGold,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        hasNextChapter ? 'Next Chapter' : 'Finish Tutorial',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildAnimatedStar(AnimationController controller, bool earned) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = CurvedAnimation(parent: controller, curve: Curves.easeOutBack).value;
        final rotation = (1.0 - scale) * math.pi * 0.25;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scaleByDouble(scale == 0.0 ? 0.01 : scale, scale == 0.0 ? 0.01 : scale, 1.0, 1.0)..rotateZ(rotation),
          child: Icon(
            earned ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 48,
            color: earned ? ScholarlyTheme.accentGold : ScholarlyTheme.panelStroke,
          ),
        );
      },
    );
  }
}
