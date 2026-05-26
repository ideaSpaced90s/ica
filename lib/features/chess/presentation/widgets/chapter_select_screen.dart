import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/chess_provider.dart';
import '../../application/onboarding_provider.dart';
import '../../application/tutorial_provider.dart';
import '../../data/tutorial_lessons.dart';
import '../../domain/models/tutorial_constants.dart';
import '../../domain/models/tutorial_lesson.dart';
import '../../services/chess_sound_service.dart';
import '../mobile_navigation_shell.dart';
import '../scholarly_theme.dart';
import 'ambient_scaffold.dart';
import 'game_controls.dart';

class ChapterSelectScreen extends ConsumerWidget {
  const ChapterSelectScreen({super.key, required this.onSelectChapter});

  final void Function(int) onSelectChapter;

  static const List<_ChapterGroup> _groups = [
    _ChapterGroup(
      title: 'Foundations',
      subtitle: 'Board, coordinates, pieces, and capture rules',
      start: 1,
      end: 9,
      icon: Icons.grid_on_rounded,
      color: Color(0xFF059669),
    ),
    _ChapterGroup(
      title: 'King Safety',
      subtitle: 'Check, mate, stalemate, castling, and special rules',
      start: 10,
      end: 18,
      icon: Icons.security_rounded,
      color: ScholarlyTheme.accentBlue,
    ),
    _ChapterGroup(
      title: 'Practice Core',
      subtitle: 'Opening habits, material value, tactics, and graduation',
      start: 19,
      end: 23,
      icon: Icons.psychology_rounded,
      color: Color(0xFF7C3AED),
    ),
    _ChapterGroup(
      title: 'Openings',
      subtitle: 'Classic structures and first strategic plans',
      start: 24,
      end: 28,
      icon: Icons.flag_rounded,
      color: Color(0xFFD97706),
    ),
    _ChapterGroup(
      title: 'Technique',
      subtitle: 'Mating patterns and essential endgame positions',
      start: 29,
      end: 34,
      icon: Icons.workspace_premium_rounded,
      color: ScholarlyTheme.realGold,
    ),
    _ChapterGroup(
      title: 'Expert Mastery',
      subtitle: 'Technical checkmates, breakthroughs, and tactical traps',
      start: 35,
      end: 39,
      icon: Icons.history_edu_rounded,
      color: Color(0xFF0284C7),
    ),
    _ChapterGroup(
      title: 'Strategic Mastery',
      subtitle: 'Mobility, pawn chains, backward pawns, doubled pawns, and open files',
      start: 40,
      end: 44,
      icon: Icons.track_changes_rounded,
      color: Color(0xFF0F766E),
    ),
  ];

  Widget _buildHeader({
    required WidgetRef ref,
    required int completedCount,
    required int totalXp,
    required TutorialRank rank,
    required bool isOnboarding,
    required TutorialLesson targetLesson,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tutorial',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOnboarding
                          ? 'Guided target: Chapter ${targetLesson.chapterId} - ${targetLesson.title}'
                          : 'Choose a lesson, resume a checkpoint, or replay the guided path.',
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ActionIconButton(
                icon: Icons.explore_rounded,
                size: 24,
                onTap: () {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                  final repo = ref.read(tutorialProgressRepositoryProvider);
                  unawaited(repo.setWelcomeGuideSeen(false));
                  ref.read(showWelcomeDialogProvider.notifier).state = true;
                  ref.read(mobileNavIndexProvider.notifier).state = 0;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Rank',
                  value: rank.displayName,
                  icon: Icons.military_tech_rounded,
                  color: ScholarlyTheme.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'XP',
                  value: '$totalXp',
                  icon: Icons.stars_rounded,
                  color: ScholarlyTheme.realGold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricTile(
                  label: 'Done',
                  value: '$completedCount/$kTutorialChapterCount',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingAdvisor({
    required WidgetRef ref,
    required TutorialLesson targetLesson,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: ScholarlyTheme.shadowColor.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.45)),
                    image: const DecorationImage(
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
                        'GM CHANAKYA',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.accentBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your guided path continues with Chapter ${targetLesson.chapterId}: ${targetLesson.title}. Complete it to unlock the next guided stop.',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                      OnboardingService(ref).endGuidedTour(markWelcomeSeen: true);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ScholarlyTheme.textMuted,
                      side: BorderSide(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.9)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: Text(
                      'End Guide',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                      onSelectChapter(targetLesson.chapterId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScholarlyTheme.accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(
                      'Continue',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final state = ref.watch(tutorialProvider);
    final progress = state.progress;
    final lessons = TutorialLessonsDatabase.lessons;
    final isOnboarding = ref.watch(isOnboardingProvider);
    final targetChapter = ref.watch(onboardingTargetChapterProvider);
    final targetLesson = TutorialLessonsDatabase.getLesson(targetChapter);

    return AmbientScaffold(
      scaffoldKey: scaffoldKey,
      blob1Color: const Color(0xFFFEF9C3),
      blob2Color: const Color(0xFFDBEAFE),
      blob3Color: const Color(0xFFE0F2FE),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(
                ref: ref,
                completedCount: progress.completedChapters.length,
                totalXp: progress.totalXp,
                rank: progress.currentRank,
                isOnboarding: isOnboarding,
                targetLesson: targetLesson,
              ),
            ),
            if (isOnboarding)
              SliverToBoxAdapter(
                child: _buildOnboardingAdvisor(
                  ref: ref,
                  targetLesson: targetLesson,
                ),
              ),
            for (final group in _groups)
              ..._buildChapterGroup(
                ref: ref,
                group: group,
                lessons: lessons
                    .where((lesson) => lesson.chapterId >= group.start && lesson.chapterId <= group.end)
                    .toList(),
                isOnboarding: isOnboarding,
                targetChapter: targetChapter,
                completedChapters: progress.completedChapters,
                unlockedChapters: progress.unlockedChapters,
                stars: progress.stars,
                activeChapter: progress.activeChapterIndex,
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildChapterGroup({
    required WidgetRef ref,
    required _ChapterGroup group,
    required List<TutorialLesson> lessons,
    required bool isOnboarding,
    required int targetChapter,
    required Set<int> completedChapters,
    required Set<int> unlockedChapters,
    required Map<int, int> stars,
    required int? activeChapter,
  }) {
    return [
      SliverToBoxAdapter(child: _GroupHeader(group: group)),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            final crossAxisCount = width >= 700 ? 4 : (width >= 480 ? 3 : 2);
            return SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: 122,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final lesson = lessons[index];
                  final isTarget = isOnboarding && lesson.chapterId == targetChapter;
                  final isUnlocked = isOnboarding
                      ? isTarget
                      : unlockedChapters.contains(lesson.chapterId);
                  final isCompleted = completedChapters.contains(lesson.chapterId);

                  return PulsingGlowWrapper(
                    isActive: isTarget,
                    glowColor: group.color,
                    child: _ChapterCard(
                      lesson: lesson,
                      groupColor: group.color,
                      isUnlocked: isUnlocked,
                      isCompleted: isCompleted,
                      stars: stars[lesson.chapterId] ?? 0,
                      isActiveCheckpoint: activeChapter == lesson.chapterId,
                      isGuidedTarget: isTarget,
                      onTap: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                        onSelectChapter(lesson.chapterId);
                      },
                    ),
                  );
                },
                childCount: lessons.length,
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _ChapterGroup {
  final String title;
  final String subtitle;
  final int start;
  final int end;
  final IconData icon;
  final Color color;

  const _ChapterGroup({
    required this.title,
    required this.subtitle,
    required this.start,
    required this.end,
    required this.icon,
    required this.color,
  });
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final _ChapterGroup group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: group.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: group.color.withValues(alpha: 0.20)),
            ),
            child: Icon(group.icon, color: group.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.title,
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  group.subtitle,
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
    required this.groupColor,
    required this.isUnlocked,
    required this.isCompleted,
    required this.stars,
    required this.isActiveCheckpoint,
    required this.isGuidedTarget,
    required this.onTap,
  });

  final TutorialLesson lesson;
  final Color groupColor;
  final bool isUnlocked;
  final bool isCompleted;
  final int stars;
  final bool isActiveCheckpoint;
  final bool isGuidedTarget;
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
      case 24:
        return Icons.flag_rounded;
      case 25:
        return Icons.account_tree_rounded;
      case 26:
        return Icons.call_split_rounded;
      case 27:
        return Icons.diamond_rounded;
      case 28:
        return Icons.shield_rounded;
      case 29:
        return Icons.workspace_premium_rounded;
      case 30:
        return Icons.vertical_align_top_rounded;
      case 31:
        return Icons.compare_arrows_rounded;
      case 32:
        return Icons.architecture_rounded;
      case 33:
        return Icons.horizontal_rule_rounded;
      case 34:
        return Icons.auto_awesome_rounded;
      case 35:
        return Icons.people_outline_rounded;
      case 36:
        return Icons.extension_rounded;
      case 37:
        return Icons.offline_bolt_rounded;
      case 38:
        return Icons.trending_up_rounded;
      case 39:
        return Icons.grid_off_rounded;
      case 40:
        return Icons.zoom_out_map_rounded;
      case 41:
        return Icons.link_rounded;
      case 42:
        return Icons.subdirectory_arrow_right_rounded;
      case 43:
        return Icons.layers_rounded;
      case 44:
        return Icons.view_week_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isGuidedTarget
        ? groupColor
        : isActiveCheckpoint
            ? ScholarlyTheme.realGold
            : isCompleted
                ? groupColor.withValues(alpha: 0.36)
                : ScholarlyTheme.panelStroke.withValues(alpha: 0.72);

    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.38,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            color: Colors.white.withValues(alpha: isUnlocked ? 0.92 : 0.62),
            child: InkWell(
              onTap: isUnlocked ? onTap : null,
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor, width: isGuidedTarget ? 1.8 : 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: groupColor.withValues(alpha: isGuidedTarget ? 0.14 : 0.04),
                      blurRadius: isGuidedTarget ? 18 : 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'CH. ${lesson.chapterId}',
                          style: GoogleFonts.inter(
                            color: groupColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        _buildStatusIcon(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lesson.title,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: groupColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(_getChapterIcon(lesson.chapterId), size: 17, color: groupColor),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: isCompleted ? _buildStars() : _buildStepCount(),
                        ),
                      ],
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

  Widget _buildStatusIcon() {
    if (isGuidedTarget) {
      return Icon(Icons.play_circle_fill_rounded, size: 16, color: groupColor);
    }
    if (isActiveCheckpoint) {
      return const Icon(Icons.bookmark_rounded, size: 15, color: ScholarlyTheme.realGold);
    }
    if (isCompleted) {
      return Icon(Icons.check_circle_rounded, size: 15, color: groupColor);
    }
    if (!isUnlocked) {
      return const Icon(Icons.lock_rounded, size: 14, color: ScholarlyTheme.textSubtle);
    }
    return const Icon(Icons.radio_button_unchecked_rounded, size: 14, color: ScholarlyTheme.textSubtle);
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: List.generate(3, (idx) {
        final earned = idx < stars;
        return Icon(
          earned ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 13,
          color: earned ? ScholarlyTheme.realGold : ScholarlyTheme.textSubtle.withValues(alpha: 0.55),
        );
      }),
    );
  }

  Widget _buildStepCount() {
    return Text(
      '${lesson.steps.length} steps',
      textAlign: TextAlign.right,
      style: GoogleFonts.inter(
        color: ScholarlyTheme.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class PulsingGlowWrapper extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Color glowColor;

  const PulsingGlowWrapper({
    super.key,
    required this.child,
    required this.isActive,
    this.glowColor = ScholarlyTheme.accentBlue,
  });

  @override
  State<PulsingGlowWrapper> createState() => _PulsingGlowWrapperState();
}

class _PulsingGlowWrapperState extends State<PulsingGlowWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.018).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 4.0, end: 16.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingGlowWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(
                    alpha: 0.28 * (1.0 - _controller.value),
                  ),
                  blurRadius: _glowAnimation.value,
                  spreadRadius: _controller.value * 2.0,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
