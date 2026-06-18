import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../scholarly_theme.dart';
import '../../widgets/ambient_scaffold.dart';
import '../../widgets/hover_scale_effect.dart';
import '../../widgets/progression_charts.dart';
import '../../widgets/mini_board_preview.dart';
import '../../../application/chess_provider.dart';
import '../../../application/battleground_provider.dart';

class MatchBreakdownRow extends StatelessWidget {
  final String label;
  final int classic;
  final int nineSixty;
  final Color dotColor;

  const MatchBreakdownRow({
    super.key,
    required this.label,
    required this.classic,
    required this.nineSixty,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textPrimary,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          'C:$classic | 960:$nineSixty',
          style: GoogleFonts.jetBrainsMono(
            color: ScholarlyTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class MobileMatchBreakdownRow extends StatelessWidget {
  final String label;
  final int classic;
  final int nineSixty;
  final Color dotColor;

  const MobileMatchBreakdownRow({
    super.key,
    required this.label,
    required this.classic,
    required this.nineSixty,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          'Classic: $classic  |  960: $nineSixty',
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ConsolidatedEloCard extends StatelessWidget {
  final BattlegroundState bgState;

  const ConsolidatedEloCard({
    super.key,
    required this.bgState,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = ScholarlyTheme.accentBlue;
    final isCalibrated = bgState.isCalibrated;
    final isCalibratingInitial = bgState.totalRatedGamesCount < 10;
    final gamesRemaining = isCalibratingInitial
        ? (10 - bgState.totalRatedGamesCount)
        : bgState.recalibrationGamesRemaining;

    final lastGameMs = bgState.lastRatedGameTimestampMs;
    String lastPlayedString = 'Never';
    if (lastGameMs != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(lastGameMs).toLocal();
      lastPlayedString = DateFormat.yMd().add_jm().format(dt);
    }

    return SizedBox(
      width: 200,
      height: 208,
      child: HoverScaleEffect(
        child: JuicyGlassCard(
          borderRadius: 20,
          borderColor: color,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'CONSOLIDATED ELO',
                      style: GoogleFonts.outfit(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Text(
                  '${bgState.consolidatedRating}',
                  style: GoogleFonts.outfit(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCalibrated
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isCalibrated ? 'Calibrated' : 'Uncalibrated',
                    style: GoogleFonts.inter(
                      color: isCalibrated
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (!isCalibrated) ...[
                const SizedBox(height: 3),
                Text(
                  '($gamesRemaining matches left)',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFF59E0B),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                'Last game: $lastPlayedString',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TotalMatchesCard extends StatelessWidget {
  final BattlegroundState bgState;

  const TotalMatchesCard({
    super.key,
    required this.bgState,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = ScholarlyTheme.accentGold;
    return SizedBox(
      width: 200,
      height: 208,
      child: HoverScaleEffect(
        child: JuicyGlassCard(
          borderRadius: 20,
          borderColor: color,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sports_esports_rounded,
                      color: color,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TOTAL MATCHES',
                      style: GoogleFonts.outfit(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Text(
                  '${bgState.totalRatedGamesCount}',
                  style: GoogleFonts.outfit(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const Spacer(),
              MatchBreakdownRow(
                label: 'BULLET',
                classic: bgState.bulletGamesClassic,
                nineSixty: bgState.bulletGames960,
                dotColor: Colors.cyan,
              ),
              const SizedBox(height: 3),
              MatchBreakdownRow(
                label: 'BLITZ',
                classic: bgState.blitzGamesClassic,
                nineSixty: bgState.blitzGames960,
                dotColor: Colors.orangeAccent,
              ),
              const SizedBox(height: 3),
              MatchBreakdownRow(
                label: 'RAPID',
                classic: bgState.rapidGamesClassic,
                nineSixty: bgState.rapidGames960,
                dotColor: ScholarlyTheme.accentBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WinStreakBanner extends StatelessWidget {
  final BattlegroundState bgState;

  const WinStreakBanner({
    super.key,
    required this.bgState,
  });

  @override
  Widget build(BuildContext context) {
    return HoverScaleEffect(
      child: JuicyGlassCard(
        borderRadius: 24,
        borderColor: Colors.deepOrangeAccent.withValues(alpha: 0.6),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        backgroundColor: Colors.white.withValues(alpha: 0.45),
        shadows: [
          BoxShadow(
            color: Colors.deepOrangeAccent.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final mainStreakInfo = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepOrangeAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrangeAccent.withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.deepOrangeAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'WIN STREAK',
                      style: GoogleFonts.outfit(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${bgState.totalWinningStreak} GAMES ON FIRE',
                      style: GoogleFonts.outfit(
                        color: Colors.deepOrangeAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            );

            final specificStreaks = Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (bgState.bulletStreak > 0)
                  _buildSubStreakPill('BULLET', bgState.bulletStreak, Colors.cyan),
                if (bgState.blitzStreak > 0)
                  _buildSubStreakPill('BLITZ', bgState.blitzStreak, Colors.orangeAccent),
                if (bgState.rapidStreak > 0)
                  _buildSubStreakPill('RAPID', bgState.rapidStreak, ScholarlyTheme.accentBlue),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mainStreakInfo,
                  if (bgState.bulletStreak > 0 || bgState.blitzStreak > 0 || bgState.rapidStreak > 0) ...[
                    const SizedBox(height: 16),
                    specificStreaks,
                  ],
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                mainStreakInfo,
                specificStreaks,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubStreakPill(String mode, int streak, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$mode: $streak 🔥',
            style: GoogleFonts.jetBrainsMono(
              color: ScholarlyTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class MasterCard extends StatelessWidget {
  final ChessState state;
  final BattlegroundState bgState;

  const MasterCard({
    super.key,
    required this.state,
    required this.bgState,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: bgState.isCalibrated
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bgState.isCalibrated ? 'CALIBRATED' : 'UNCALIBRATED',
                          style: GoogleFonts.inter(
                            color: bgState.isCalibrated
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    if (!bgState.isCalibrated) ...[
                      Text(
                        bgState.totalRatedGamesCount < 10
                            ? '${10 - bgState.totalRatedGamesCount} games left'
                            : '${bgState.recalibrationGamesRemaining} games left',
                        style: GoogleFonts.inter(
                          color: const Color(0xFFF59E0B),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LAST GAME',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      bgState.lastRatedGameTimestampMs != null
                          ? DateFormat.yMd().add_jm().format(
                              DateTime.fromMillisecondsSinceEpoch(
                                bgState.lastRatedGameTimestampMs!,
                              ).toLocal())
                          : 'Never',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 8),
                MobileMatchBreakdownRow(
                  label: 'BULLET',
                  classic: bgState.bulletGamesClassic,
                  nineSixty: bgState.bulletGames960,
                  dotColor: Colors.cyan,
                ),
                const SizedBox(height: 4),
                MobileMatchBreakdownRow(
                  label: 'BLITZ',
                  classic: bgState.blitzGamesClassic,
                  nineSixty: bgState.blitzGames960,
                  dotColor: Colors.orangeAccent,
                ),
                const SizedBox(height: 4),
                MobileMatchBreakdownRow(
                  label: 'RAPID',
                  classic: bgState.rapidGamesClassic,
                  nineSixty: bgState.rapidGames960,
                  dotColor: ScholarlyTheme.accentBlue,
                ),
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class TierCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final int elo;
  final int streak;
  final int classic;
  final int nineSixty;
  final double dominance;

  const TierCard({
    super.key,
    required this.title,
    required this.icon,
    required this.elo,
    required this.streak,
    required this.classic,
    required this.nineSixty,
    required this.dominance,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor = title.contains('BULLET')
        ? Colors.cyan
        : title.contains('BLITZ')
            ? Colors.orangeAccent
            : ScholarlyTheme.accentBlue;

    return HoverScaleEffect(
      child: JuicyGlassCard(
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameModesCard extends StatelessWidget {
  final bool isMobile;
  const GameModesCard({super.key, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return HoverScaleEffect(
        child: JuicyGlassCard(
          borderRadius: 20,
          borderColor: const Color(0xFF06B6D4),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 40,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: Color(0xFF06B6D4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: ModeDistributionChart(isMobile: true),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: 200,
      height: 208,
      child: HoverScaleEffect(
        child: JuicyGlassCard(
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
              const SizedBox(height: 12),
              const Expanded(child: ModeDistributionChart(isMobile: false)),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentMasterpieces extends StatelessWidget {
  final ChessState state;

  const RecentMasterpieces({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
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
