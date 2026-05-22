import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/tutorial_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
// Constants mapped locally or internally via progress state objects
import '../../domain/models/tutorial_lesson.dart';
import '../../data/tutorial_lessons.dart';
import '../scholarly_theme.dart';
import 'game_controls.dart';
import 'ambient_scaffold.dart';
import '../mobile_navigation_shell.dart';
import '../../application/onboarding_provider.dart';


class ChapterSelectScreen extends ConsumerWidget {
  const ChapterSelectScreen({super.key, required this.onSelectChapter});

  final void Function(int) onSelectChapter;

  Widget _buildOnboardingAdvisor(int targetChapter) {
    String message = '';
    switch (targetChapter) {
      case 1:
        message = 'Apprentice, the journey of a thousand leagues begins with the board itself. Touch Chapter 1 to learn the foundation.';
        break;
      case 10:
        message = 'You have bypassed the basics. Now, let us study Check—the warning that precedes the fall. Touch Chapter 10.';
        break;
      case 14:
        message = 'Castling is the ultimate defensive maneuver, hiding the King behind his fortress. Touch Chapter 14 to proceed.';
        break;
      default:
        message = 'Touch the highlighted chapter to continue your guided learning.';
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: ScholarlyTheme.glassPanelDecoration(radius: 16).copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            border: Border.all(
              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ScholarlyTheme.accentBlue, width: 1.5),
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
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final state = ref.watch(tutorialProvider);
    final p = state.progress;
    final lessons = TutorialLessonsDatabase.lessons;
    final isOnboarding = ref.watch(isOnboardingProvider);
    final targetChapter = ref.watch(onboardingTargetChapterProvider);

    return AmbientScaffold(
      scaffoldKey: scaffoldKey,
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

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'TUTORIAL',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ),

                if (isOnboarding)
                  _buildOnboardingAdvisor(targetChapter),

                const Divider(height: 1, color: Colors.white30),

                // Main horizontal browser grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 116,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: lessons.length,
                    itemBuilder: (context, index) {
                      final lesson = lessons[index];
                      final isUnlocked = !isOnboarding || lesson.chapterId == targetChapter;
                      final isCompleted = p.completedChapters.contains(lesson.chapterId);
                      final stars = p.stars[lesson.chapterId] ?? 0;
                      final isActiveCheckpoint = p.activeChapterIndex == lesson.chapterId;

                      final animIndex = index < 8 ? index : 8;
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 400 + animIndex * 80),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1.0 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: PulsingGlowWrapper(
                          isActive: isOnboarding && lesson.chapterId == targetChapter,
                          child: _ChapterCard(
                            lesson: lesson,
                            isUnlocked: isUnlocked,
                            isCompleted: isCompleted,
                            stars: stars,
                            isActiveCheckpoint: isActiveCheckpoint,
                            onTap: () {
                              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                              onSelectChapter(lesson.chapterId);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 2. Absolute Utility Layer (Outside primary safe area flow)
          // XP count container
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
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

          // Replay App Tour (Walkthrough) button - aligned to top right
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: ActionIconButton(
              icon: Icons.explore_rounded,
              size: 24,
              onTap: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                // Clear guide flags and activate the welcome guide dialog overlay
                final repo = ref.read(tutorialProgressRepositoryProvider);
                repo.setWelcomeGuideSeen(false);
                ref.read(showWelcomeDialogProvider.notifier).state = true;
                // Navigate to home dashboard screen where guide overlays render
                ref.read(mobileNavIndexProvider.notifier).state = 0;
              },
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
      opacity: isUnlocked ? 1.0 : 0.3,
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

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.025).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 4.0, end: 18.0).animate(
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
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(
                    alpha: 0.4 * (1.0 - _controller.value),
                  ),
                  blurRadius: _glowAnimation.value,
                  spreadRadius: _controller.value * 2.5,
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
