import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'mobile_navigation_shell.dart';
import 'scholarly_theme.dart';
import 'widgets/progression_charts.dart';
import 'widgets/mini_board_preview.dart';
import 'widgets/ambient_scaffold.dart';
import 'widgets/profile_customization_overlay.dart';
import 'widgets/phase_analysis_widgets.dart';
import 'package:intl/intl.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    // LEFT COLUMN: Avatar, Master Standing, ELO Progression
    final Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    ? Image.asset(
                        state.userAvatarPath,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        File(state.userAvatarPath),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ),
        ),
        _buildMasterCard(state),
        const SizedBox(height: 32),
        _buildSectionHeader('ELO PROGRESS', icon: Icons.show_chart_rounded),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: EloAscentChart(saves: state.savedGames),
        ),
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
              state.bulletElo,
              state.bulletStreak,
              state.bulletGamesClassic,
              state.bulletGames960,
              state.bulletDominance,
            ),
            _buildTierCard(
              'BLITZ ARENA',
              Icons.local_fire_department_rounded,
              state.blitzElo,
              state.blitzStreak,
              state.blitzGamesClassic,
              state.blitzGames960,
              state.blitzDominance,
            ),
            _buildTierCard(
              'RAPID ARENA',
              Icons.timer_rounded,
              state.rapidElo,
              state.rapidStreak,
              state.rapidGamesClassic,
              state.rapidGames960,
              state.rapidDominance,
            ),
          ],
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('RECENT WINS', icon: Icons.workspace_premium_rounded),
        const SizedBox(height: 16),
        _buildRecentMasterpieces(state),
        const SizedBox(height: 32),
        _buildSectionHeader('PHASE ANALYSIS', icon: Icons.insights_rounded),
        const SizedBox(height: 16),
        isMobile
            ? Column(
                children: [
                  OpeningRepertoireCard(saves: state.savedGames),
                  const SizedBox(height: 16),
                  EndgameTechniqueCard(saves: state.savedGames),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: OpeningRepertoireCard(saves: state.savedGames)),
                  const SizedBox(width: 16),
                  Expanded(child: EndgameTechniqueCard(saves: state.savedGames)),
                ],
              ),
      ],
    );

    // RIGHT COLUMN: Tactical Persona, Modes, Heatmap
    final Widget rightColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('PLAYSTYLE', icon: Icons.radar_rounded),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: TacticalRadarChart(saves: state.savedGames),
        ),
        const SizedBox(height: 32),
        _buildSectionHeader('GAME MODES', icon: Icons.pie_chart_rounded),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ModeDistributionChart(saves: state.savedGames),
        ),
        const SizedBox(height: 32),
        DominanceHeatmap(saves: state.savedGames),
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
                    rightColumn,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 320, child: leftColumn),
                    const SizedBox(width: 32),
                    Expanded(child: centerColumn),
                    const SizedBox(width: 32),
                    SizedBox(width: 320, child: rightColumn),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMasterCard(ChessState state) {
    final bulletCount = state.bulletGamesClassic + state.bulletGames960;
    final blitzCount = state.blitzGamesClassic + state.blitzGames960;
    final rapidCount = state.rapidGamesClassic + state.rapidGames960;
    final totalCount = bulletCount + blitzCount + rapidCount;
    
    double avgDominance = 0.0;
    if (totalCount > 0) {
      avgDominance = (state.bulletDominance * bulletCount + 
                      state.blitzDominance * blitzCount + 
                      state.rapidDominance * rapidCount) / totalCount;
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
                    Text(
                      'Master Standing (Level VIII)',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.totalWinningStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'STREAK: ${state.totalWinningStreak}',
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
              _buildBigStat('ELO', '${state.consolidatedRating}'),
              _buildBigStat('MATCHES', '${state.totalRatedGamesCount}'),
              _buildBigStat('DOM', '${avgDominance >= 0 ? '+' : ''}${avgDominance.toStringAsFixed(1)}'),
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

  Widget _buildTierCard(String title, IconData icon, int elo, int streak, int classic, int nineSixty, double dominance) {
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
                          const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 10),
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
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: (dominance >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
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

  Widget _buildRecentMasterpieces(ChessState state) {
    final ratedWins = state.savedGames.where((s) => s.isRatedMode && s.result == 'W').take(5).toList();
    
    if (ratedWins.isEmpty) {
      return JuicyGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 24),
        borderRadius: 16,
        child: Center(
          child: Text('No rated victories recorded yet.', 
            style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12)
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
                  MiniBoardPreview(fen: game.fen, size: 70, isFlipped: !game.isPlayerWhite),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          game.ratingCategory?.toUpperCase() ?? 'MATCH',
                          style: GoogleFonts.inter(color: ScholarlyTheme.accentBlue, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d').format(game.savedAt),
                          style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.accentGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DOM: ${game.dominanceSnapshot?.toStringAsFixed(1) ?? "0.0"}',
                            style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.accentGold, fontSize: 9, fontWeight: FontWeight.bold),
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
      ProviderScope.containerOf(context).read(mobileNavIndexProvider.notifier).state = 0;
    } catch (_) {
      // Fallback check if the container couldn't be obtained or widget was disposed
      if (ref.context.mounted) {
        ref.read(mobileNavIndexProvider.notifier).state = 0;
      }
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  });
}

