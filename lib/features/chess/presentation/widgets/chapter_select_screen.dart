import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/tutorial_provider.dart';
// Constants mapped locally or internally via progress state objects
import '../../domain/models/tutorial_lesson.dart';
import '../../domain/models/tutorial_progress.dart';
import '../../data/tutorial_lessons.dart';
import '../scholarly_theme.dart';

class ChapterSelectScreen extends ConsumerWidget {
  const ChapterSelectScreen({super.key, required this.onSelectChapter});

  final void Function(int) onSelectChapter;

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => const _TutorialSettingsModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tutorialProvider);
    final p = state.progress;
    final lessons = TutorialLessonsDatabase.lessons;

    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header dashboard strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: ScholarlyTheme.textPrimary),
                    tooltip: 'Exit Academy',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KINGSLAYER ACADEMY',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.accentGold,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Interactive Tutorial',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Rank and XP Summary Widget
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.backgroundStart.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ScholarlyTheme.panelStroke),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded, color: ScholarlyTheme.accentBlueSoft, size: 16),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.currentRank.displayName.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.accentBlueSoft,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              '${p.totalXp} XP',
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Custom tutorial preferences button
                  IconButton(
                    onPressed: () => _showSettingsDialog(context, ref),
                    icon: const Icon(Icons.settings_rounded, color: ScholarlyTheme.textSubtle),
                    tooltip: 'Tutorial Settings',
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: ScholarlyTheme.panelStroke),

            // Main horizontal browser grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 116,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: lessons.length,
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  final isUnlocked = p.unlockedChapters.contains(lesson.chapterId);
                  final isCompleted = p.completedChapters.contains(lesson.chapterId);
                  final stars = p.stars[lesson.chapterId] ?? 0;
                  final isActiveCheckpoint = p.activeChapterIndex == lesson.chapterId;

                  return _ChapterCard(
                    lesson: lesson,
                    isUnlocked: isUnlocked,
                    isCompleted: isCompleted,
                    stars: stars,
                    isActiveCheckpoint: isActiveCheckpoint,
                    onTap: () => onSelectChapter(lesson.chapterId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.lesson,
    required this.isUnlocked,
    required this.isCompleted,
    required this.stars,
    required this.isActiveCheckpoint,
    required this.onTap,
  });

  final TutorialLesson lesson;
  final bool isUnlocked;
  final bool isCompleted;
  final int stars;
  final bool isActiveCheckpoint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isActiveCheckpoint
        ? ScholarlyTheme.accentYellow
        : (isCompleted ? ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.4) : ScholarlyTheme.panelStroke);

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.4,
      child: InkWell(
        onTap: isUnlocked ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ScholarlyTheme.backgroundStart.withValues(alpha: isCompleted ? 0.4 : 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: isActiveCheckpoint ? 2.0 : 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.2)
                          : ScholarlyTheme.backgroundStart,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'CH. ${lesson.chapterId}',
                      style: GoogleFonts.inter(
                        color: isCompleted ? ScholarlyTheme.accentBlueSoft : ScholarlyTheme.textSubtle,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isActiveCheckpoint)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.accentYellow.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: ScholarlyTheme.accentYellow.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.accentYellow,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (isCompleted)
                    const Icon(Icons.replay_rounded, size: 12, color: ScholarlyTheme.textSubtle)
                  else if (!isUnlocked)
                    const Icon(Icons.lock_rounded, size: 12, color: ScholarlyTheme.textSubtle),
                ],
              ),
              
              const Spacer(),

              Text(
                lesson.title,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Bottom star tally strip
              if (isCompleted)
                Row(
                  children: List.generate(3, (idx) {
                    final earned = idx < stars;
                    return Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: Icon(
                        earned ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 12,
                        color: earned ? ScholarlyTheme.accentGold : ScholarlyTheme.panelStroke,
                      ),
                    );
                  }),
                )
              else
                Text(
                  '${lesson.steps.length} Steps',
                  style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 10),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialSettingsModal extends ConsumerStatefulWidget {
  const _TutorialSettingsModal();

  @override
  ConsumerState<_TutorialSettingsModal> createState() => _TutorialSettingsModalState();
}

class _TutorialSettingsModalState extends ConsumerState<_TutorialSettingsModal> {
  late bool skipAnimations;
  late bool showSubtitles;
  late double timerVal;

  @override
  void initState() {
    super.initState();
    final s = ref.read(tutorialProvider).progress.settings;
    skipAnimations = s.skipAnimations;
    showSubtitles = s.showSubtitles;
    timerVal = s.hesitationTimerSeconds.toDouble();
  }

  void _save() {
    final notifier = ref.read(tutorialProvider.notifier);
    notifier.updateSettings(TutorialSettings(
      skipAnimations: skipAnimations,
      showSubtitles: showSubtitles,
      hesitationTimerSeconds: timerVal.toInt(),
    ));
    Navigator.of(context).pop();
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScholarlyTheme.backgroundStart,
        title: Text('Reset Progress?', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary)),
        content: Text(
          'This will erase all Academy Tutorial chapter progress, stars, and XP. This action cannot be undone.',
          style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle)),
          ),
          TextButton(
            onPressed: () {
              ref.read(tutorialProvider.notifier).resetAllProgress();
              Navigator.of(ctx).pop(); // Close confirm
              Navigator.of(context).pop(); // Close settings modal
            },
            child: Text('Reset All', style: GoogleFonts.inter(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ScholarlyTheme.backgroundStart,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ScholarlyTheme.panelStroke),
      ),
      title: Text('Tutorial Preferences', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Text('Skip Dialogue Animations', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13)),
              subtitle: Text('Instantly renders mentor advice', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 11)),
              value: skipAnimations,
              activeThumbColor: ScholarlyTheme.accentGold,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => skipAnimations = val),
            ),
            SwitchListTile(
              title: Text('Show Subtitles', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13)),
              value: showSubtitles,
              activeThumbColor: ScholarlyTheme.accentGold,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => showSubtitles = val),
            ),
            const SizedBox(height: 12),
            Text('Hesitation Hint Delay: ${timerVal.toInt()}s', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13)),
            Slider(
              value: timerVal,
              min: 0,
              max: 30,
              divisions: 6,
              activeColor: ScholarlyTheme.accentBlueSoft,
              onChanged: (val) => setState(() => timerVal = val),
            ),
            Text('Set to 0s to disable automated hint reminders.', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 10)),
            
            const SizedBox(height: 24),
            const Divider(height: 1, color: ScholarlyTheme.panelStroke),
            const SizedBox(height: 12),

            // Nuclear DB purge control block
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmReset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                icon: const Icon(Icons.delete_forever_rounded, size: 16),
                label: Text('Erase All Tutorial Progress', style: GoogleFonts.inter(fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: ScholarlyTheme.accentGold, foregroundColor: Colors.black),
          child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
