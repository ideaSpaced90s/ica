import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/saved_game.dart';
import '../../domain/opening_classifier.dart';
import '../../domain/fen_parser.dart';
import '../scholarly_theme.dart';
import 'ambient_scaffold.dart';

class OpeningRepertoireCard extends StatelessWidget {
  final List<SavedGameEntry> saves;

  const OpeningRepertoireCard({super.key, required this.saves});

  @override
  Widget build(BuildContext context) {
    final ratedSaves = saves.where((s) => s.isRatedMode).toList();
    
    if (ratedSaves.isEmpty) {
      return _buildEmptyCard(
        title: 'REPERTOIRE',
        message: 'No rated matches recorded yet.\nPlay a rated match to identify your opening weapon.',
      );
    }

    // Aggregate statistics
    final Map<String, _OpeningStats> statsMap = {};
    for (final s in ratedSaves) {
      final op = OpeningClassifier.detectOpening(s.recentMoves, gameMode: s.gameMode);
      if (!statsMap.containsKey(op)) {
        statsMap[op] = _OpeningStats(name: op);
      }
      statsMap[op]!.addPlay(s.result);
    }

    final sortedStats = statsMap.values.toList()
      ..sort((a, b) => b.plays.compareTo(a.plays));

    final totalPlays = ratedSaves.length;

    return JuicyGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REPERTOIRE',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.accentBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sortedStats.length} DISTINCT LNS',
                  style: GoogleFonts.jetBrainsMono(
                    color: ScholarlyTheme.accentBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...sortedStats.take(3).map((stats) {
            final double playPercentage = (stats.plays / totalPlays) * 100;
            final double winRate = (stats.wins + 0.5 * stats.draws) / stats.plays * 100;

            final winPercent = stats.plays > 0 ? (stats.wins / stats.plays) : 0.0;
            final drawPercent = stats.plays > 0 ? (stats.draws / stats.plays) : 0.0;
            final lossPercent = stats.plays > 0 ? (stats.losses / stats.plays) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stats.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${winRate.toStringAsFixed(1)}% WR',
                        style: GoogleFonts.jetBrainsMono(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Played ${stats.plays} times (${playPercentage.toStringAsFixed(0)}% of matches)',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${stats.wins}W - ${stats.draws}D - ${stats.losses}L',
                        style: GoogleFonts.jetBrainsMono(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tri-color horizontal distribution bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      height: 8,
                      width: double.infinity,
                      child: Row(
                        children: [
                          if (winPercent > 0)
                            Expanded(
                              flex: (winPercent * 1000).toInt(),
                              child: Container(color: const Color(0xFF10B981)), // Win Green
                            ),
                          if (drawPercent > 0)
                            Expanded(
                              flex: (drawPercent * 1000).toInt(),
                              child: Container(color: const Color(0xFF64748B)), // Draw Slate Grey
                            ),
                          if (lossPercent > 0)
                            Expanded(
                              flex: (lossPercent * 1000).toInt(),
                              child: Container(color: const Color(0xFFEF4444)), // Loss Red
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyCard({required String title, required String message}) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: ScholarlyTheme.accentBlue,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _OpeningStats {
  final String name;
  int plays = 0;
  int wins = 0;
  int draws = 0;
  int losses = 0;

  _OpeningStats({required this.name});

  void addPlay(String? result) {
    plays++;
    if (result == 'W') {
      wins++;
    } else if (result == 'D') {
      draws++;
    } else {
      losses++;
    }
  }
}

class EndgameTechniqueCard extends StatelessWidget {
  final List<SavedGameEntry> saves;

  const EndgameTechniqueCard({super.key, required this.saves});

  @override
  Widget build(BuildContext context) {
    final ratedSaves = saves.where((s) => s.isRatedMode).toList();
    final endgameSaves = ratedSaves.where((s) => FenParser.isEndgame(s.fen)).toList();

    if (endgameSaves.isEmpty) {
      return _buildEmptyCard(
        title: 'ENDGAME PERFORMANCE',
        message: 'No endgame positions recorded yet.\nPlay matches to the endgame to populate your metrics.',
      );
    }

    double totalWeightedScore = 0.0;
    double totalWeight = 0.0;

    int advantageGames = 0;
    int advantageWins = 0;

    int disadvantageGames = 0;
    int disadvantageSaves = 0; // wins + draws

    for (final s in endgameSaves) {
      final score = s.result == 'W' ? 1.0 : (s.result == 'D' ? 0.5 : 0.0);
      final balance = FenParser.calculateMaterialBalance(s.fen, s.isPlayerWhite);

      double complexity = 1.0;
      if (balance > 0) {
        complexity = 2.0; // Attacking advantage
        advantageGames++;
        if (s.result == 'W') advantageWins++;
      } else if (balance < 0) {
        complexity = 1.5; // Defensive disadvantage
        disadvantageGames++;
        if (s.result == 'W' || s.result == 'D') disadvantageSaves++;
      } else {
        complexity = 1.0; // Equal
      }

      totalWeightedScore += (score * complexity);
      totalWeight += complexity;
    }

    final double epi = totalWeight > 0 ? (totalWeightedScore / totalWeight) * 100 : 0.0;
    final double conversionRate = advantageGames > 0 ? (advantageWins / advantageGames) * 100 : 0.0;
    final double saveRate = disadvantageGames > 0 ? (disadvantageSaves / disadvantageGames) * 100 : 0.0;

    String ratingCategory = 'Provisional';
    if (endgameSaves.length >= 15) {
      if (epi >= 85) {
        ratingCategory = 'Endgame Grandmaster';
      } else if (epi >= 70) {
        ratingCategory = 'Endgame Specialist';
      } else if (epi >= 50) {
        ratingCategory = 'Tactician Class I';
      } else {
        ratingCategory = 'Endgame Scholar';
      }
    } else {
      if (epi >= 75) {
        ratingCategory = 'Technician (Provisional)';
      } else {
        ratingCategory = 'Apprentice (Provisional)';
      }
    }


    return JuicyGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENDGAME PERFORMANCE',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.accentBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${endgameSaves.length} ENDGAMES',
                  style: GoogleFonts.jetBrainsMono(
                    color: ScholarlyTheme.accentBlue,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular score widget
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                    width: 6,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${epi.toStringAsFixed(1)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: ScholarlyTheme.accentBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'EPI',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ratingCategory.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complexity-weighted scoring based on endgame material balance and results.',
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textMuted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Sub-metrics
          _buildProgressMetric(
            label: 'Conversion Efficiency',
            value: conversionRate,
            gamesCount: advantageGames,
            description: 'Win rate in advantageous endgames',
          ),
          const SizedBox(height: 12),
          _buildProgressMetric(
            label: 'Defensive Save Rate',
            value: saveRate,
            gamesCount: disadvantageGames,
            description: 'Draw or Win rate when defending disadvantages',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric({
    required String label,
    required double value,
    required int gamesCount,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
            Text(
              gamesCount > 0 ? '${value.toStringAsFixed(0)}% ($gamesCount matches)' : 'N/A',
              style: GoogleFonts.jetBrainsMono(
                color: ScholarlyTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 6,
            width: double.infinity,
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
            child: gamesCount > 0
                ? FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value / 100,
                    child: Container(
                      color: ScholarlyTheme.accentBlue,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard({required String title, required String message}) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: ScholarlyTheme.accentBlue,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
