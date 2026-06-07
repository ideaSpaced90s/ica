import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import '../application/battleground_provider.dart';
import '../application/arena_provider.dart';
import 'mobile_navigation_shell.dart';
import 'scholarly_theme.dart';
import 'widgets/progression_charts.dart';
import 'widgets/mini_board_preview.dart';
import 'widgets/ambient_scaffold.dart';
import 'widgets/profile_customization_overlay.dart';
import 'widgets/phase_analysis_widgets.dart';
import 'widgets/scotoma_card.dart';
import 'package:intl/intl.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final bgState = ref.watch(battlegroundProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile =
        screenWidth <
        1100; // Increased width threshold for better desktop layout spacing

    // LEFT COLUMN: Avatar, Master Standing, ELO Progression
    final Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          Center(
            child: GestureDetector(
              onTap: () => showProfileCustomizationOverlay(context, ref),
              child: Container(
                width: 140,
                height: 140,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.8),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: state.userAvatarPath.startsWith('assets/')
                      ? Image.asset(state.userAvatarPath, fit: BoxFit.cover)
                      : Image.file(
                          File(state.userAvatarPath),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),
          _buildMasterCard(state, bgState),
          const SizedBox(height: 32),
        ],
        _buildSectionHeader('30D', icon: Icons.calendar_today_rounded),
        const SizedBox(height: 16),
        const DominanceHeatmap(),
        const SizedBox(height: 32),
        _buildSectionHeader('ELO PROGRESS', icon: Icons.show_chart_rounded),
        const SizedBox(height: 16),
        const SizedBox(height: 240, child: EloAscentChart()),
      ],
    );

    // CENTER COLUMN: Arenas, Masterpieces
    final Widget centerColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('ARENAS', icon: Icons.workspace_premium_rounded),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isMobile ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 3.0 : 2.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildTierCard(
              'BULLET ARENA',
              Icons.bolt_rounded,
              bgState.bulletElo,
              bgState.bulletStreak,
              bgState.bulletGamesClassic,
              bgState.bulletGames960,
              bgState.bulletDominance,
            ),
            _buildTierCard(
              'BLITZ ARENA',
              Icons.local_fire_department_rounded,
              bgState.blitzElo,
              bgState.blitzStreak,
              bgState.blitzGamesClassic,
              bgState.blitzGames960,
              bgState.blitzDominance,
            ),
            _buildTierCard(
              'RAPID ARENA',
              Icons.timer_rounded,
              bgState.rapidElo,
              bgState.rapidStreak,
              bgState.rapidGamesClassic,
              bgState.rapidGames960,
              bgState.rapidDominance,
            ),
            _buildGameModesCard(),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionHeader(
          'RECENT WINS',
          icon: Icons.workspace_premium_rounded,
        ),
        const SizedBox(height: 16),
        _buildRecentMasterpieces(state),
        const SizedBox(height: 32),
        _buildSectionHeader('PHASE ANALYSIS', icon: Icons.insights_rounded),
        const SizedBox(height: 16),
        isMobile
            ? const Column(
                children: [
                  OpeningRepertoireCard(),
                  SizedBox(height: 16),
                  EndgameTechniqueCard(),
                ],
              )
            : const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: OpeningRepertoireCard()),
                  SizedBox(width: 16),
                  Expanded(child: EndgameTechniqueCard()),
                ],
              ),
      ],
    );

    // INSIGHT SECTIONS: Tactical Persona, Modes, Heatmap
    final Widget insightSections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PLAYSTYLE', icon: Icons.radar_rounded),
        const SizedBox(height: 16),
        const TacticalRadarChart(),
        const SizedBox(height: 32),
        _buildSectionHeader('SCOTOMA', icon: Icons.visibility_off_rounded),
        const SizedBox(height: 16),
        const ScotomaCard(),
      ],
    );

    return AmbientScaffold(
      blob1Color: const Color(0xFFDBEAFE),
      blob2Color: const Color(0xFFFEF3C7),
      blob3Color: const Color(0xFFF3E8FF),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leftColumn,
                    const SizedBox(height: 32),
                    centerColumn,
                    const SizedBox(height: 32),
                    insightSections,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(context, ref, state, bgState),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 320, child: leftColumn),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              centerColumn,
                              const SizedBox(height: 32),
                              insightSections,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    WidgetRef ref,
    ChessState state,
    BattlegroundState bgState,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final profile = Row(
            children: [
              GestureDetector(
                onTap: () => showProfileCustomizationOverlay(context, ref),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.8),
                      width: 3.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: state.userAvatarPath.startsWith('assets/')
                        ? Image.asset(state.userAvatarPath, fit: BoxFit.cover)
                        : Image.file(
                            File(state.userAvatarPath),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELCOME BACK,',
                      style: GoogleFonts.outfit(
                        color: ScholarlyTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.userName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '“The chess board is the world, the pieces are the phenomena of the universe...”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textSubtle,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final metrics = Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.end,
            children: [
              _buildHeaderMetricCard(
                title: 'CONSOLIDATED ELO',
                value: '${bgState.consolidatedRating}',
                color: ScholarlyTheme.accentBlue,
                icon: Icons.emoji_events_rounded,
              ),
              _buildHeaderMetricCard(
                title: 'TOTAL MATCHES',
                value: '${bgState.totalRatedGamesCount}',
                color: ScholarlyTheme.accentGold,
                icon: Icons.sports_esports_rounded,
              ),
              if (bgState.totalWinningStreak > 0)
                _buildHeaderMetricCard(
                  title: 'WIN STREAK',
                  value: '${bgState.totalWinningStreak}',
                  color: Colors.deepOrangeAccent,
                  icon: Icons.local_fire_department_rounded,
                ),
            ],
          );

          if (constraints.maxWidth < 1160) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [profile, const SizedBox(height: 20), metrics],
            );
          }

          return Row(
            children: [
              Expanded(child: profile),
              const SizedBox(width: 32),
              metrics,
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasterCard(ChessState state, BattlegroundState bgState) {
    final bulletCount = bgState.bulletGamesClassic + bgState.bulletGames960;
    final blitzCount = bgState.blitzGamesClassic + bgState.blitzGames960;
    final rapidCount = bgState.rapidGamesClassic + bgState.rapidGames960;
    final totalCount = bulletCount + blitzCount + rapidCount;

    double avgDominance = 0.0;
    if (totalCount > 0) {
      avgDominance =
          (bgState.bulletDominance * bulletCount +
              bgState.blitzDominance * blitzCount +
              bgState.rapidDominance * rapidCount) /
          totalCount;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: ScholarlyTheme.gradientCard(radius: 28),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.userName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (bgState.totalWinningStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.deepOrangeAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'STREAK: ${bgState.totalWinningStreak}',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBigStat('ELO', '${bgState.consolidatedRating}'),
              _buildBigStat('MATCHES', '${bgState.totalRatedGamesCount}'),
              _buildBigStat(
                'DOM',
                '${avgDominance >= 0 ? '+' : ''}${avgDominance.toStringAsFixed(1)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTierCard(
    String title,
    IconData icon,
    int elo,
    int streak,
    int classic,
    int nineSixty,
    double dominance,
  ) {
    final Color accentColor = title.contains('BULLET')
        ? Colors.cyan
        : title.contains('BLITZ')
        ? Colors.orangeAccent
        : ScholarlyTheme.accentBlue;

    return JuicyGlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (streak > 0)
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.deepOrangeAccent,
                            size: 10,
                          ),
                          Text(
                            ' $streak',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.deepOrangeAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '$elo ELO',
                      style: GoogleFonts.jetBrainsMono(
                        color: accentColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (dominance >= 0 ? Colors.green : Colors.red)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${dominance >= 0 ? '+' : ''}${dominance.toStringAsFixed(1)}',
                        style: GoogleFonts.jetBrainsMono(
                          color: dominance >= 0 ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'C: $classic | 960: $nineSixty',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textSubtle,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return JuicySectionHeader(title: title, icon: icon);
  }

  Widget _buildGameModesCard() {
    return JuicyGlassCard(
      borderRadius: 20,
      borderColor: const Color(0xFF06B6D4),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF06B6D4),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'GAME MODES',
                style: GoogleFonts.outfit(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Expanded(child: ModeDistributionChart()),
        ],
      ),
    );
  }

  Widget _buildRecentMasterpieces(ChessState state) {
    final ratedWins = state.savedGames
        .where((s) => s.isRatedMode && s.result == 'W')
        .take(5)
        .toList();

    if (ratedWins.isEmpty) {
      return JuicyGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 24),
        borderRadius: 16,
        child: Center(
          child: Text(
            'No rated victories recorded yet.',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: ratedWins.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final game = ratedWins[index];
          return SizedBox(
            width: 220,
            child: JuicyGlassCard(
              padding: const EdgeInsets.all(12),
              borderRadius: 16,
              child: Row(
                children: [
                  MiniBoardPreview(
                    fen: game.fen,
                    size: 70,
                    isFlipped: !game.isPlayerWhite,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          game.ratingCategory?.toUpperCase() ?? 'MATCH',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.accentBlue,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d').format(game.savedAt),
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.accentGold.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DOM: ${game.dominanceSnapshot?.toStringAsFixed(1) ?? "0.0"}',
                            style: GoogleFonts.jetBrainsMono(
                              color: ScholarlyTheme.accentGold,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

void exitToDashboardWithSidebar(BuildContext context, WidgetRef ref) {
  // Ensure the widget is still mounted before accessing ref or navigating.
  if (!context.mounted) return;
  // Use a post-frame callback to safely transition navigation.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    try {
      final container = ProviderScope.containerOf(context);
      final currentIndex = container.read(mobileNavIndexProvider);
      if (currentIndex == 1) {
        final arenaState = container.read(arenaProvider);
        if (arenaState.recentMoves.isNotEmpty &&
            !arenaState.game.gameOver &&
            !arenaState.isPaused) {
          container.read(arenaProvider.notifier).togglePause();
        }
      }
      container.read(mobileNavIndexProvider.notifier).state = 0;
    } catch (_) {
      // Fallback check if the container couldn't be obtained or widget was disposed
      if (ref.context.mounted) {
        final currentIndex = ref.read(mobileNavIndexProvider);
        if (currentIndex == 1) {
          final arenaState = ref.read(arenaProvider);
          if (arenaState.recentMoves.isNotEmpty &&
              !arenaState.game.gameOver &&
              !arenaState.isPaused) {
            ref.read(arenaProvider.notifier).togglePause();
          }
        }
        ref.read(mobileNavIndexProvider.notifier).state = 0;
      }
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  });
}
