import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scholarly_theme.dart';
import '../../application/battleground_provider.dart';
import 'ambient_scaffold.dart';

class OpeningRepertoireCard extends ConsumerWidget {
  const OpeningRepertoireCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgState = ref.watch(battlegroundProvider);
    final openings = bgState.cachedOpenings;
    
    if (openings.isEmpty) {
      return _buildEmptyCard(
        title: 'REPERTOIRE',
        message: 'No rated matches recorded yet.\nPlay a rated match to identify your opening weapon.',
      );
    }

    return JuicyGlassCard(
      borderColor: const Color(0xFF14B8A6), // Vibrant Teal Border
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'REPERTOIRE',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.accentBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${openings.length} DISTINCT LNS',
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
          ...openings.take(3).map((stats) {
            final double playPercentage = stats.playPercentage;
            final double winRate = stats.winRate;

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
                      Expanded(
                        child: Text(
                          'Played ${stats.plays} times (${playPercentage.toStringAsFixed(0)}% of matches)',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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

class EndgameTechniqueCard extends ConsumerWidget {
  const EndgameTechniqueCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgState = ref.watch(battlegroundProvider);
    final endgames = bgState.cachedEndgames;

    if (endgames == null) {
      return _buildEmptyCard(
        title: 'ENDGAME PERFORMANCE',
        message: 'No endgame positions recorded yet.\nPlay matches to the endgame to populate your metrics.',
      );
    }

    final double epi = endgames.epi;
    final double conversionRate = endgames.conversionRate;
    final double saveRate = endgames.saveRate;
    final String ratingCategory = endgames.ratingCategory;
    final int advantageGames = endgames.advantageGames;
    final int disadvantageGames = endgames.disadvantageGames;
    final int endgameSavesCount = endgames.endgameSavesCount;


    return JuicyGlassCard(
      borderColor: const Color(0xFFF59E0B), // Vibrant Amber Border
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ENDGAME PERFORMANCE',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.accentBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$endgameSavesCount ENDGAMES',
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
              // Circular progress dial widget representing real math calculations
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: epi / 100,
                      strokeWidth: 6,
                      backgroundColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${epi.toStringAsFixed(1)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFFF59E0B),
                          fontSize: 15,
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
                ],
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
            Expanded(
              child: Column(
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
            ),
            const SizedBox(width: 8),
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
