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

// Historical Cinema Imports
import '../../domain/models/historical_game.dart';
import '../../application/historical_cinema_provider.dart';
import '../academy/historical_cinema_page.dart';

import '../../application/var_notifier.dart';

final tutorialTabProvider = NotifierProvider<VarNotifier<int>, int>(() => VarNotifier(() => 0)); // 0 = Lessons, 1 = History
final historicalSubTabProvider = NotifierProvider<VarNotifier<int>, int>(() => VarNotifier(() => 0)); // 0 = Tactics, 1 = Positional, 2 = Dynamic, 3 = Endgame

class ChapterSelectScreen extends ConsumerWidget {
  const ChapterSelectScreen({super.key, required this.onSelectChapter});

  final void Function(int) onSelectChapter;

  static const List<_ChapterGroup> _groups = [
    _ChapterGroup(
      title: 'Foundations',
      subtitle: 'Board, coordinates, all six pieces, and capture rules',
      start: 1,
      end: 8,
      icon: Icons.grid_on_rounded,
      color: Color(0xFF059669),
    ),
    _ChapterGroup(
      title: 'Special Rules & King Safety',
      subtitle: 'Check, mate, stalemate, castling, promotion, en passant, draws',
      start: 9,
      end: 17,
      icon: Icons.security_rounded,
      color: ScholarlyTheme.accentBlue,
    ),
    _ChapterGroup(
      title: 'Tactics Set 1',
      subtitle: 'Piece values, opening habits, forks, pins, skewers, discovered attacks',
      start: 18,
      end: 25,
      icon: Icons.psychology_rounded,
      color: Color(0xFF7C3AED),
    ),
    _ChapterGroup(
      title: 'Tactics Set 2',
      subtitle: 'Undermining, overloading, decoy, clearance, interference, zwischenzug',
      start: 26,
      end: 31,
      icon: Icons.bolt_rounded,
      color: Color(0xFF0284C7),
    ),
    _ChapterGroup(
      title: 'Practical Openings',
      subtitle: 'Italian, Ruy Lopez, Sicilian, Queen\'s Gambit, King\'s Indian',
      start: 32,
      end: 36,
      icon: Icons.flag_rounded,
      color: Color(0xFFD97706),
    ),
    _ChapterGroup(
      title: 'Endgame Technique',
      subtitle: 'Queen mate, rook mate, opposition, wrong bishop, breakthrough, Lucena, Philidor',
      start: 37,
      end: 43,
      icon: Icons.workspace_premium_rounded,
      color: ScholarlyTheme.realGold,
    ),
    _ChapterGroup(
      title: 'Pawn Strategy',
      subtitle: 'Pawn chains, backward pawns, doubled pawns, isolated pawns',
      start: 44,
      end: 47,
      icon: Icons.track_changes_rounded,
      color: Color(0xFF0F766E),
    ),
    _ChapterGroup(
      title: 'Tactics Set 3: Master Class',
      subtitle: 'Légal\'s Mate, Windmill, Lasker, Alekhine\'s Gun, Saavedra, Two Bishops',
      start: 48,
      end: 53,
      icon: Icons.history_edu_rounded,
      color: Color(0xFF6B21A8),
    ),
    _ChapterGroup(
      title: 'Mastery',
      subtitle: 'Knight & Bishop mate, Steinitz majority',
      start: 54,
      end: 55,
      icon: Icons.emoji_events_rounded,
      color: Color(0xFF9F1239),
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
                        'Guided Foundations: Chapter ${targetLesson.chapterId} — ${targetLesson.title}. Complete it to continue your training.',
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
    final activeTab = ref.watch(tutorialTabProvider);

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
            if (!isOnboarding)
              SliverToBoxAdapter(
                child: _buildTabBar(context, ref, activeTab),
              ),
            if (isOnboarding) ...[
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
            ] else if (activeTab == 0) ...[
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
            ] else ...[
              ..._buildHistoricalCinemaSection(ref, context),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, WidgetRef ref, int activeTab) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: Container(
        height: 46,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;
            final double indicatorWidth = width / 2;

            return Stack(
              children: [
                // Selection indicator background
                AnimatedAlign(
                  alignment: activeTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    width: indicatorWidth,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ScholarlyTheme.accentBlue,
                          ScholarlyTheme.accentBlue.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab Buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                          ref.read(tutorialTabProvider.notifier).state = 0;
                        },
                        child: Center(
                          child: Text(
                            "Interactive Training",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: activeTab == 0 ? Colors.white : ScholarlyTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                          ref.read(tutorialTabProvider.notifier).state = 1;
                        },
                        child: Center(
                          child: Text(
                            "Historical Archives",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: activeTab == 1 ? Colors.white : ScholarlyTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _historicalTabs = [
    {
      'title': 'Tactics & Attack',
      'icon': Icons.local_fire_department_rounded,
      'color': Color(0xFFE11D48),
    },
    {
      'title': 'Positional & Strategy',
      'icon': Icons.security_rounded,
      'color': ScholarlyTheme.accentBlue,
    },
    {
      'title': 'Dynamic & Defense',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFF7C3AED),
    },
    {
      'title': 'Endgame & Specialty',
      'icon': Icons.workspace_premium_rounded,
      'color': ScholarlyTheme.realGold,
    },
  ];

  int _getTabForCategory(String category) {
    final catLower = category.toLowerCase();
    if (catLower.contains("cat_tactical") ||
        catLower.contains("horizons") ||
        catLower.contains("horisons") ||
        catLower.contains("cat_sacrifice") ||
        catLower.contains("sacrifice") ||
        catLower.contains("cat_initiative") ||
        catLower.contains("initiative")) {
      return 0; // Tactics & Attack
    } else if (catLower.contains("cat_positional") ||
        catLower.contains("fortress") ||
        catLower.contains("cat_closed_systems") ||
        catLower.contains("closed") ||
        catLower.contains("cat_pawn") ||
        catLower.contains("pawn") ||
        catLower.contains("cat_bishop") ||
        catLower.contains("bishop")) {
      return 1; // Positional & Strategy
    } else if (catLower.contains("cat_dynamic") ||
        catLower.contains("counterstrike") ||
        catLower.contains("cat_sicilian") ||
        catLower.contains("sicilian") ||
        catLower.contains("cat_defensive") ||
        catLower.contains("escape")) {
      return 2; // Dynamic & Defense
    } else {
      return 3; // Endgame & Specialty
    }
  }

  Widget _buildSubTabBar(BuildContext context, WidgetRef ref, int activeSubTab) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _historicalTabs.length,
        itemBuilder: (context, index) {
          final tab = _historicalTabs[index];
          final title = tab['title'] as String;
          final icon = tab['icon'] as IconData;
          final color = tab['color'] as Color;
          final isActive = activeSubTab == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
                ref.read(historicalSubTabProvider.notifier).state = index;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? color.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? color.withValues(alpha: 0.4) : ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
                    width: isActive ? 1.5 : 1.0,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isActive ? color : ScholarlyTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                        color: isActive ? color : ScholarlyTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildHistoricalCinemaSection(WidgetRef ref, BuildContext context) {
    final state = ref.watch(historicalCinemaProvider);
    if (state.isLoading) {
      return [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: CircularProgressIndicator(
                color: ScholarlyTheme.accentBlue,
              ),
            ),
          ),
        ),
      ];
    }

    final games = state.games;
    if (games.isEmpty) {
      return [];
    }

    // Group games by category
    final Map<String, List<HistoricalGame>> grouped = {};
    for (final game in games) {
      grouped.putIfAbsent(game.category, () => []).add(game);
    }

    final List<Widget> slivers = [];
    final activeSubTab = ref.watch(historicalSubTabProvider);

    // Header for the entire Historical Cinema section
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 24),
              Text(
                'Historical Archive',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Learn legendary games played in human history, annotated by GM Chanakya.',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Sub-tab selection bar
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildSubTabBar(context, ref, activeSubTab),
        ),
      ),
    );

    // Render each category in a structured order
    final categoryOrder = [
      'cat_tactical',
      'cat_positional',
      'cat_dynamic',
      'cat_endgame',
      'cat_sacrifice',
      'cat_hypermodern',
      'cat_closed_systems',
      'cat_sicilian_clashes',
      'cat_initiative',
      'cat_pawn_dynamics',
      'cat_bishop_pair',
      'cat_defensive_saves',
    ];

    final categories = grouped.keys.toList()
      ..sort((a, b) {
        int idxA = categoryOrder.indexWhere((key) => a.toLowerCase().contains(key));
        int idxB = categoryOrder.indexWhere((key) => b.toLowerCase().contains(key));
        if (idxA == -1) idxA = 999;
        if (idxB == -1) idxB = 999;
        return idxA.compareTo(idxB);
      });

    for (final category in categories) {
      // Filter categories to only match the active sub-tab
      if (_getTabForCategory(category) != activeSubTab) {
        continue;
      }

      final catGames = grouped[category]!;
      
      // Determine subgroup colors and icons
      IconData icon = Icons.movie_filter_rounded;
      Color color = ScholarlyTheme.accentBlue;
      String title = category;
      String subtitle = "Historical masterpieces of strategy";

      final catLower = category.toLowerCase();
      if (catLower.contains("cat_tactical") || catLower.contains("horizons") || catLower.contains("horisons")) {
        icon = Icons.grid_on_rounded;
        color = const Color(0xFF059669); // Emerald
        title = "Open Horizons & Gambits";
        subtitle = "Attacking lines, piece sacrifices, and tactical calculations";
      } else if (catLower.contains("cat_positional") || catLower.contains("fortress")) {
        icon = Icons.security_rounded;
        color = ScholarlyTheme.accentBlue;
        title = "The Iron Fortress";
        subtitle = "Prophylaxis, pawn structures, and positional suffocation";
      } else if (catLower.contains("cat_dynamic") || catLower.contains("counterstrike")) {
        icon = Icons.bolt_rounded;
        color = const Color(0xFF7C3AED); // Purple
        title = "The Counterstrike Collection";
        subtitle = "Sharp defense turning into instant attack and dynamics";
      } else if (catLower.contains("cat_endgame") || catLower.contains("endgame")) {
        icon = Icons.workspace_premium_rounded;
        color = ScholarlyTheme.realGold;
        title = "The Endgame Squeeze";
        subtitle = "Technical conversions, king activity, and promotion races";
      } else if (catLower.contains("cat_sacrifice") || catLower.contains("sacrifice")) {
        icon = Icons.local_fire_department_rounded;
        color = const Color(0xFFE11D48); // Rose
        title = "The Art of the Sacrifice";
        subtitle = "Direct piece sacrifices, king hunts, and mating combinations";
      } else if (catLower.contains("cat_hypermodern") || catLower.contains("hypermodern")) {
        icon = Icons.radar_rounded;
        color = const Color(0xFF0D9488); // Teal
        title = "Hypermodern Masterpieces";
        subtitle = "Flank control, fianchetto setups, and indirect center pressure";
      } else if (catLower.contains("cat_closed_systems") || catLower.contains("closed")) {
        icon = Icons.lock_rounded;
        color = const Color(0xFF4F46E5); // Indigo
        title = "Queen's Gambit & Closed Stratagems";
        subtitle = "Pawn structures, minority attacks, and tension in closed files";
      } else if (catLower.contains("cat_sicilian") || catLower.contains("sicilian")) {
        icon = Icons.offline_bolt_rounded;
        color = const Color(0xFFEA580C); // Orange
        title = "Razor-Sharp Sicilians";
        subtitle = "Asymmetrical tactical battles and opposite-side castling storms";
      } else if (catLower.contains("cat_initiative") || catLower.contains("initiative")) {
        icon = Icons.trending_up_rounded;
        color = const Color(0xFF2563EB); // Blue
        title = "Mastering the Initiative";
        subtitle = "Energetic play, continuous threats, and restricting the defender";
      } else if (catLower.contains("cat_pawn") || catLower.contains("pawn")) {
        icon = Icons.grain_rounded;
        color = const Color(0xFF65A30D); // Lime
        title = "Pawn Structure Dynamics";
        subtitle = "Carlsbad pawn chains, isolated pawns, and passed pawn advances";
      } else if (catLower.contains("cat_bishop") || catLower.contains("bishop")) {
        icon = Icons.layers_rounded;
        color = const Color(0xFF7C3AED); // Violet
        title = "The Power of the Bishop Pair";
        subtitle = "Long-range domination, knight restriction, and diagonal control";
      } else if (catLower.contains("cat_defensive") || catLower.contains("escape")) {
        icon = Icons.shield_rounded;
        color = const Color(0xFF475569); // Slate
        title = "The Art of the Escape";
        subtitle = "Miraculous swindles, constructing fortresses, and saving the game";
      }

      final fakeGroup = _ChapterGroup(
        title: title,
        subtitle: subtitle,
        start: 0,
        end: 0,
        icon: icon,
        color: color,
      );

      slivers.add(SliverToBoxAdapter(child: _GroupHeader(group: fakeGroup)));
      
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;
              final crossAxisCount = width >= 700 ? 3 : (width >= 480 ? 2 : 1);
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: 96,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final game = catGames[index];
                    return _HistoricalGameCard(
                      game: game,
                      groupColor: color,
                      onTap: () {
                        ref.read(historicalCinemaProvider.notifier).selectGame(game);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HistoricalCinemaPage(),
                          ),
                        );
                      },
                    );
                  },
                  childCount: catGames.length,
                ),
              );
            },
          ),
        ),
      );
    }

    return slivers;
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
                  final isUnlocked = true;
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
      // GROUP 1 — Foundations (1–8)
      case 1: return Icons.grid_on_rounded;           // Board Introduction
      case 2: return Icons.pin_drop_rounded;          // Coordinates & Tiles
      case 3: return Icons.arrow_upward_rounded;      // Pawn Movement & Capture
      case 4: return Icons.unfold_more_rounded;       // Rook Movement & Capture
      case 5: return Icons.open_in_full_rounded;      // Bishop Movement & Capture
      case 6: return Icons.shortcut_rounded;          // Knight Movement & Capture
      case 7: return Icons.workspace_premium_rounded; // Queen Movement & Capture
      case 8: return Icons.emoji_people_rounded;      // King Movement & Capture
      // GROUP 2 — Special Rules & King Safety (9–17)
      case 9: return Icons.upgrade_rounded;          // Pawn Promotion
      case 10: return Icons.castle_rounded;           // Kingside Castling
      case 11: return Icons.fort_rounded;             // Queenside Castling
      case 12: return Icons.bolt_rounded;             // En Passant
      case 13: return Icons.warning_amber_rounded;    // Understanding Check
      case 14: return Icons.security_rounded;         // Escaping Check
      case 15: return Icons.dangerous_rounded;        // Checkmate
      case 16: return Icons.balance_rounded;          // Stalemate
      case 17: return Icons.compare_arrows_rounded;   // Draw Conditions
      // GROUP 3 — Tactics Set 1 (18–25)
      case 18: return Icons.calculate_rounded;        // Piece Value Concepts
      case 19: return Icons.rocket_launch_rounded;    // Opening Principles
      case 20: return Icons.psychology_rounded;       // The Fork
      case 21: return Icons.push_pin_rounded;          // The Pin
      case 22: return Icons.call_made_rounded;        // The Skewer
      case 23: return Icons.visibility_rounded;       // Discovered Attack & Check
      case 24: return Icons.zoom_out_map_rounded;     // Principle of Mobility
      case 25: return Icons.view_week_rounded;        // Open Files & Penetration
      // GROUP 4 — Tactics Set 2 (26–31)
      case 26: return Icons.heart_broken_rounded;     // Undermining
      case 27: return Icons.scale_rounded;            // Overloading
      case 28: return Icons.radar_rounded;            // Decoy & Attraction
      case 29: return Icons.cleaning_services_rounded; // Clearance & Vacating
      case 30: return Icons.block_rounded;            // Interference
      case 31: return Icons.pending_actions_rounded;  // Zwischenzug
      // GROUP 5 — Practical Openings (32–36)
      case 32: return Icons.flag_rounded;             // Italian Game
      case 33: return Icons.account_tree_rounded;     // Ruy Lopez
      case 34: return Icons.call_split_rounded;       // Sicilian Defense
      case 35: return Icons.diamond_rounded;          // Queen's Gambit
      case 36: return Icons.shield_rounded;           // King's Indian Setup
      // GROUP 6 — Endgame Technique (37–43)
      case 37: return Icons.workspace_premium_rounded; // Queen Mate
      case 38: return Icons.vertical_align_top_rounded; // Rook Mate
      case 39: return Icons.compare_arrows_rounded;   // Opposition
      case 40: return Icons.grid_off_rounded;         // Wrong Bishop Draw
      case 41: return Icons.trending_up_rounded;      // Pawn Breakthrough
      case 42: return Icons.architecture_rounded;     // Lucena Position
      case 43: return Icons.horizontal_rule_rounded;  // Philidor Position
      // GROUP 7 — Pawn Strategy (44–47)
      case 44: return Icons.link_rounded;             // Pawn Chain
      case 45: return Icons.subdirectory_arrow_right_rounded; // Backward Pawn
      case 46: return Icons.layers_rounded;           // Doubled Pawns
      case 47: return Icons.grain_rounded;            // The Isolated Pawn
      // GROUP 8 — Tactics Set 3: Master Class (48–53)
      case 48: return Icons.offline_bolt_rounded;     // Légal's Mate
      case 49: return Icons.cyclone_rounded;          // The Windmill
      case 50: return Icons.filter_2_rounded;         // Lasker's Double Sacrifice
      case 51: return Icons.align_horizontal_left_rounded; // Alekhine's Gun
      case 52: return Icons.auto_awesome_rounded;     // Saavedra Study
      case 53: return Icons.people_outline_rounded;   // Two Bishops Mate
      // GROUP 9 — Mastery (54–55)
      case 54: return Icons.extension_rounded;        // Knight & Bishop Mate
      case 55: return Icons.groups_rounded;           // Steinitz's Majority
      default: return Icons.help_outline_rounded;
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
              onTap: isUnlocked && !isCompleted ? onTap : null,
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

class _HistoricalGameCard extends StatelessWidget {
  const _HistoricalGameCard({
    required this.game,
    required this.groupColor,
    required this.onTap,
  });

  final HistoricalGame game;
  final Color groupColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.92),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ScholarlyTheme.panelStroke.withValues(alpha: 0.72),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: groupColor.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      size: 20,
                      color: groupColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${game.white} vs. ${game.black}',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${game.event} (${game.year})',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          game.educationalTheme,
                          style: GoogleFonts.inter(
                            color: groupColor,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '#${game.id}',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textSubtle.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
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
