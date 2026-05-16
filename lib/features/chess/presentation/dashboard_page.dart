import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'widgets/global_sidebar.dart';
import 'widgets/game_controls.dart';

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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ScholarlyTheme.backgroundStart,
      drawer: const GlobalSidebar(),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TACTICAL COMMAND',
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.accentBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                              ),
                            ),
                            Text(
                              'Center',
                              style: GoogleFonts.outfit(
                                color: ScholarlyTheme.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.panelBase,
                            shape: BoxShape.circle,
                            border: Border.all(color: ScholarlyTheme.panelStroke),
                          ),
                          child: const Icon(Icons.person_rounded, color: ScholarlyTheme.accentBlue, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // MASTER STANDING CARD
                    _buildMasterCard(state),

                    const SizedBox(height: 32),
                    Text(
                      'ARENA PERFORMANCE',
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
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
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
          
          // Action Row
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ActionIconButton(
                  icon: Icons.menu_rounded,
                  size: 24,
                  shouldBlink: !state.hasBlinkedMenu,
                  onBlinkComplete: () => notifier.markMenuAsBlinked(),
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Text(
                  'DASHBOARD',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
            ScholarlyTheme.accentBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MASTER STANDING',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.accentBlue,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Level VIII',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (state.totalWinningStreak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepOrangeAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrangeAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'STREAK: ${state.totalWinningStreak}',
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.deepOrangeAccent,
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
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTierCard(String title, IconData icon, int elo, int streak, int classic, int nineSixty, double dominance) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ScholarlyTheme.panelStroke),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: ScholarlyTheme.accentBlue, size: 24),
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
                          color: ScholarlyTheme.accentBlue,
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
                            color: dominance >= 0 ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.05),
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
}
