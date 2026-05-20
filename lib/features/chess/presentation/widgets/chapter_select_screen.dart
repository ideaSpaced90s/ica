import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/tutorial_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
// Constants mapped locally or internally via progress state objects
import '../../domain/models/tutorial_lesson.dart';
import '../../domain/models/tutorial_progress.dart';
import '../../data/tutorial_lessons.dart';
import '../scholarly_theme.dart';
import 'global_sidebar.dart';
import 'game_controls.dart';
import 'ambient_scaffold.dart';


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
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final state = ref.watch(tutorialProvider);
    final p = state.progress;
    final lessons = TutorialLessonsDatabase.lessons;

    return AmbientScaffold(
      scaffoldKey: scaffoldKey,
      drawer: const GlobalSidebar(),
      blob1Color: const Color(0xFFFEF9C3), // Soft Gold
      blob2Color: const Color(0xFFDBEAFE), // Soft Blue
      blob3Color: const Color(0xFFF3E8FF), // Soft Purple
      body: Stack(
        children: [
          // 1. Dashboard Content Layer
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top margin since header is gone
                const SizedBox(height: 60),

                const Divider(height: 1, color: Colors.white30),

                // Main horizontal browser grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
                        onTap: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                          onSelectChapter(lesson.chapterId);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. Absolute Utility Layer (Outside primary safe area flow)
          
          // XP count container (Top Left)
          Positioned(
            top: 16,
            left: 16,
            child: JuicyGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              borderRadius: 12,
              borderColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
              shadows: [
                BoxShadow(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school_rounded, color: ScholarlyTheme.accentBlue, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${p.totalXp} XP',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.accentBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Settings Gear (Top Right)
          Positioned(
            top: 12,
            right: 8,
            child: IconButton(
              onPressed: () => _showSettingsDialog(context, ref),
              icon: const Icon(Icons.settings_rounded, color: ScholarlyTheme.textPrimary, size: 20),
              tooltip: 'Tutorial Settings',
            ),
          ),

          // Bottom Action Row for Global Consistency - stylized as a floating glass dock
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: JuicyGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              borderRadius: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ActionIconButton(
                    icon: Icons.menu_rounded,
                    size: 20,
                    onTap: () => scaffoldKey.currentState?.openDrawer(),
                  ),
                  Text(
                    'TUTORIAL',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.accentBlue,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 32), // balance layout
                ],
              ),
            ),
          ),
        ],
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

  IconData _getChapterIcon(int chapterId) {
    switch (chapterId) {
      case 1:
        return Icons.grid_on_rounded;
      case 2:
        return Icons.pin_drop_rounded;
      case 3:
        return Icons.arrow_upward_rounded;
      case 4:
        return Icons.unfold_more_rounded;
      case 5:
        return Icons.open_in_full_rounded;
      case 6:
        return Icons.shortcut_rounded;
      case 7:
        return Icons.workspace_premium_rounded;
      case 8:
        return Icons.emoji_people_rounded;
      case 9:
        return Icons.gavel_rounded;
      case 10:
        return Icons.warning_amber_rounded;
      case 11:
        return Icons.security_rounded;
      case 12:
        return Icons.dangerous_rounded;
      case 13:
        return Icons.balance_rounded;
      case 14:
        return Icons.castle_rounded;
      case 15:
        return Icons.fort_rounded;
      case 16:
        return Icons.bolt_rounded;
      case 17:
        return Icons.upgrade_rounded;
      case 18:
        return Icons.compare_arrows_rounded;
      case 19:
        return Icons.rocket_launch_rounded;
      case 20:
        return Icons.calculate_rounded;
      case 21:
        return Icons.psychology_rounded;
      case 22:
        return Icons.fitness_center_rounded;
      case 23:
        return Icons.school_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isActiveCheckpoint
        ? ScholarlyTheme.accentYellow
        : (isCompleted ? ScholarlyTheme.accentBlue.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.45));

    final cardBg = isActiveCheckpoint
        ? ScholarlyTheme.accentYellow.withValues(alpha: 0.08)
        : (isCompleted
            ? ScholarlyTheme.accentBlue.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.35));

    final glowShadow = isActiveCheckpoint
        ? [
            BoxShadow(
              color: ScholarlyTheme.accentYellow.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
        : (isCompleted
            ? [
                BoxShadow(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]);

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.45,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: isActiveCheckpoint ? 1.8 : 1.2),
              boxShadow: glowShadow,
            ),
            child: InkWell(
              onTap: isUnlocked ? onTap : null,
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCompleted
                                ? ScholarlyTheme.accentBlue.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.4),
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          'CH. ${lesson.chapterId}',
                          style: GoogleFonts.inter(
                            color: isCompleted ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isActiveCheckpoint)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.accentYellow.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: ScholarlyTheme.accentYellow.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: GoogleFonts.inter(
                              color: ScholarlyTheme.realGold,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else if (isCompleted)
                        const Icon(Icons.check_circle_rounded, size: 14, color: ScholarlyTheme.accentBlue)
                      else if (!isUnlocked)
                        const Icon(Icons.lock_rounded, size: 14, color: ScholarlyTheme.textSubtle),
                    ],
                  ),
                  
                  const Spacer(),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            if (isCompleted)
                              Row(
                                children: List.generate(3, (idx) {
                                  final earned = idx < stars;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Icon(
                                      earned ? Icons.star_rounded : Icons.star_outline_rounded,
                                      size: 13,
                                      color: earned ? ScholarlyTheme.realGold : ScholarlyTheme.textSubtle.withValues(alpha: 0.5),
                                    ),
                                  );
                                }),
                              )
                            else
                              Text(
                                '${lesson.steps.length} Steps',
                                style: GoogleFonts.inter(
                                  color: ScholarlyTheme.textSubtle,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15)
                              : (isUnlocked
                                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCompleted
                                ? ScholarlyTheme.accentBlue.withValues(alpha: 0.35)
                                : (isUnlocked
                                    ? ScholarlyTheme.accentBlue.withValues(alpha: 0.2)
                                    : Colors.transparent),
                            width: 1.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            _getChapterIcon(lesson.chapterId),
                            size: 18,
                            color: isCompleted
                                ? ScholarlyTheme.accentBlue
                                : (isUnlocked
                                    ? ScholarlyTheme.accentBlue
                                    : ScholarlyTheme.textSubtle),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: JuicyGlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          borderColor: Colors.white.withValues(alpha: 0.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Progress?',
                style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'This will erase all Academy Tutorial chapter progress, stars, and XP. This action cannot be undone.',
                style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(tutorialProvider.notifier).resetAllProgress();
                      Navigator.of(ctx).pop(); // Close confirm
                      Navigator.of(context).pop(); // Close settings modal
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Reset All', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: JuicyGlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        borderColor: Colors.white.withValues(alpha: 0.5),
        child: SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tutorial Preferences',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Skip Dialogue Animations', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('Instantly renders mentor advice', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 11)),
                value: skipAnimations,
                activeThumbColor: ScholarlyTheme.accentBlue,
                activeTrackColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                  setState(() => skipAnimations = val);
                },
              ),
              SwitchListTile(
                title: Text('Show Subtitles', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                value: showSubtitles,
                activeThumbColor: ScholarlyTheme.accentBlue,
                activeTrackColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                  setState(() => showSubtitles = val);
                },
              ),
              const SizedBox(height: 12),
              Text('Hesitation Hint Delay: ${timerVal.toInt()}s', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              Slider(
                value: timerVal,
                min: 0,
                max: 30,
                divisions: 6,
                activeColor: ScholarlyTheme.accentBlue,
                inactiveColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                onChanged: (val) => setState(() => timerVal = val),
              ),
              Text('Set to 0s to disable automated hint reminders.', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 10)),
              
              const SizedBox(height: 20),
              const Divider(height: 1, color: Colors.white24),
              const SizedBox(height: 16),

              // Nuclear DB purge control block
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.delete_forever_rounded, size: 16),
                  label: Text('Erase All Tutorial Progress', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScholarlyTheme.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
