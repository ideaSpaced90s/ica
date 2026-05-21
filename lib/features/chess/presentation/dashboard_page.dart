import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'widgets/global_sidebar.dart';
import 'widgets/game_controls.dart';
import 'widgets/progression_charts.dart';
import 'widgets/mini_board_preview.dart';
import 'widgets/ambient_scaffold.dart';
import 'widgets/profile_customization_overlay.dart';
import 'package:intl/intl.dart';

final openSidebarOnDashboardProvider = StateProvider<bool>((ref) => false);

void exitToDashboardWithSidebar(BuildContext context, WidgetRef ref) {
  ref.read(openSidebarOnDashboardProvider.notifier).state = true;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => const DashboardPage()),
    (route) => false,
  );
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    final shouldOpenSidebar = ref.watch(openSidebarOnDashboardProvider);
    if (shouldOpenSidebar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scaffoldKey.currentState != null && !_scaffoldKey.currentState!.isDrawerOpen) {
          _scaffoldKey.currentState!.openDrawer();
          ref.read(openSidebarOnDashboardProvider.notifier).state = false;
        }
      });
    }

    return AmbientScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const GlobalSidebar(),
      blob1Color: const Color(0xFFDBEAFE),
      blob2Color: const Color(0xFFFEF3C7),
      blob3Color: const Color(0xFFF3E8FF),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Glowing Profile Image (The "Sun")
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  child: GestureDetector(
                    onTap: () => showProfileCustomizationOverlay(context, ref),
                    child: Container(
                      width: 180,
                      height: 180,
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
                // Main Content Column
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Submerge 20% of circle (180 * 0.2 = 36).
                      // Top of circle is at MediaQuery.of(context).padding.top + 16.
                      // Bottom of circle is at MediaQuery.of(context).padding.top + 16 + 180.
                      // We want MasterCard's top to be 36px higher than the bottom of the circle,
                      // i.e., at MediaQuery.of(context).padding.top + 16 + 144 = MediaQuery.of(context).padding.top + 160.
                      SizedBox(height: MediaQuery.of(context).padding.top + 160),

                      // MASTER STANDING CARD
                      _buildMasterCard(state),

                      const SizedBox(height: 32),
                      _buildSectionHeader('ELO PROGRESSION', icon: Icons.show_chart_rounded),
                      const SizedBox(height: 16),
                      EloAscentChart(saves: state.savedGames),

                      const SizedBox(height: 32),
                      _buildSectionHeader('ARENA PERFORMANCE', icon: Icons.workspace_premium_rounded),
                      const SizedBox(height: 16),

                      // TIERED ARENA GRID
                      GridView.count(
                        crossAxisCount: 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.5,
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
                      _buildSectionHeader('TACTICAL PERSONA', icon: Icons.radar_rounded),
                      const SizedBox(height: 16),
                      TacticalRadarChart(saves: state.savedGames),

                      const SizedBox(height: 32),
                      _buildSectionHeader('MODES', icon: Icons.pie_chart_rounded),
                      const SizedBox(height: 16),
                      ModeDistributionChart(saves: state.savedGames),

                      const SizedBox(height: 32),
                      DominanceHeatmap(saves: state.savedGames),

                      const SizedBox(height: 32),
                      _buildSectionHeader('RECENT MASTERPIECES', icon: Icons.workspace_premium_rounded),
                      const SizedBox(height: 16),
                      _buildRecentMasterpieces(state),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating 3-bar drawer menu button (fixed at top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: ActionIconButton(
              icon: Icons.menu_rounded,
              size: 24,
              shouldBlink: !state.hasBlinkedMenu,
              onBlinkComplete: () => notifier.markMenuAsBlinked(),
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.userName.toUpperCase(),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBigStat('CONSOLIDATED ELO', '${state.consolidatedRating}'),
                const SizedBox(width: 24),
                _buildBigStat('TOTAL MATCHES', '${state.totalRatedGamesCount}'),
                const SizedBox(width: 24),
                _buildBigStat('AVG. DOMINANCE', '${avgDominance >= 0 ? '+' : ''}${avgDominance.toStringAsFixed(1)}'),
              ],
            ),
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
            fontSize: 32,
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
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            margin: const EdgeInsets.only(right: 16),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: 20),
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (streak > 0)
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 12),
                          Text(
                            ' $streak',
                            style: GoogleFonts.jetBrainsMono(
                              color: Colors.deepOrangeAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        '$elo ELO',
                        style: GoogleFonts.jetBrainsMono(
                          color: accentColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (dominance >= 0 ? Colors.green : Colors.red).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${dominance >= 0 ? '+' : ''}${dominance.toStringAsFixed(1)}',
                          style: GoogleFonts.jetBrainsMono(
                            color: dominance >= 0 ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'C: $classic | 960: $nineSixty',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textSubtle,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: ratedWins.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final game = ratedWins[index];
          return SizedBox(
            width: 240,
            child: JuicyGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: Row(
                children: [
                  MiniBoardPreview(fen: game.fen, size: 80, isFlipped: !game.isPlayerWhite),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          game.ratingCategory?.toUpperCase() ?? 'MATCH',
                          style: GoogleFonts.inter(color: ScholarlyTheme.accentBlue, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d').format(game.savedAt),
                          style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.accentGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DOM: ${game.dominanceSnapshot?.toStringAsFixed(1) ?? "0.0"}',
                            style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
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
