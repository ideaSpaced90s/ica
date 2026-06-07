import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:intl/intl.dart';
import '../scholarly_theme.dart';
import '../../application/battleground_provider.dart';
import '../../domain/models/dashboard_stats.dart';
import 'ambient_scaffold.dart';
import 'hover_scale_effect.dart';
import 'mini_board_preview.dart';
import '../../application/chess_provider.dart';
import '../../application/study_lab_provider.dart';
import '../mobile_navigation_shell.dart';
import '../../domain/opening_classifier.dart';
import '../../services/chess_sound_service.dart';
import '../../domain/performance_ledger_entry.dart';

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

            return InkWell(
              onTap: () {
                _showOpeningDetailSheet(context, ref, stats.name, stats);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
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

class MiddlegamePerformanceCard extends ConsumerWidget {
  const MiddlegamePerformanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgState = ref.watch(battlegroundProvider);
    final middlegames = bgState.cachedMiddlegames;

    if (middlegames == null) {
      return _buildEmptyCard(
        title: 'MIDGAME PERFORMANCE',
        message: 'No middlegame positions recorded yet.\nPlay matches past move 10 to populate your metrics.',
      );
    }

    final double mpi = middlegames.mpi;
    final double winRate = middlegames.winRate;
    final double decidedPercentage = middlegames.decidedPercentage;
    final String archetype = middlegames.archetype;
    final String description = middlegames.description;
    final int totalMiddlegames = middlegames.totalMiddlegames;

    return JuicyGlassCard(
      borderColor: const Color(0xFF8B5CF6), // Royal Purple Border
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
                  'MIDGAME PERFORMANCE',
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
                  '$totalMiddlegames MATCHES',
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
              // Circular progress dial widget
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: mpi / 100,
                      strokeWidth: 6,
                      backgroundColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${mpi.toStringAsFixed(1)}%',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF8B5CF6),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'MPI',
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
                      archetype.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
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
            label: 'Middlegame Win Rate',
            value: winRate,
            gamesCount: totalMiddlegames,
            description: 'Overall win/draw performance in the middlegame',
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 12),
          _buildProgressMetric(
            label: 'Decided in Middlegame',
            value: decidedPercentage,
            gamesCount: totalMiddlegames,
            description: 'Matches won or lost before reaching the endgame',
            color: const Color(0xFF8B5CF6),
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
    required Color color,
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
              gamesCount > 0 ? '${value.toStringAsFixed(0)}%' : 'N/A',
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
                      color: color,
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

// ─────────────────────────────────────────────────────────────────────────────
// RepertoireCard — Desktop merged Repertoire (Opening + Endgame)
// ─────────────────────────────────────────────────────────────────────────────

/// All recognisable opening names produced by OpeningClassifier, in fixed
/// canonical order grouped by first-move family.
const List<String> _kAllOpenings = [
  // e4 openings
  'Ruy Lopez',
  'Sicilian Defense',
  'Italian Game',
  'French Defense',
  'Caro-Kann Defense',
  "Petrov's Defense",
  'Pirc Defense',
  'Modern Defense',
  'Scandinavian Defense',
  "Alekhine's Defense",
  'Vienna Game',
  'Scotch Game',
  "King's Gambit",
  'Philidor Defense',
  'Four Knights Game',
  'Open Game',
  "King's Pawn Game",
  // d4 openings
  "Queen's Gambit",
  "Queen's Gambit Declined",
  "King's Indian Defense",
  'Catalan Opening',
  'Benoni Defense',
  'Slav Defense',
  'Nimzo-Indian Defense',
  'Grünfeld Defense',
  'Dutch Defense',
  'London System',
  'Closed Game',
  "Queen's Pawn Game",
  // Flank / other
  'Réti Opening',
  'English Opening',
  "Bird's Opening",
  "King's Fianchetto",
  'Nimzowitsch-Larsen Attack',
  // Variants / catch-alls
  'Chess 960 Variant',
  'Custom / Unclassified',
];

const Map<String, Color> _kOpeningGroupColor = {
  'Ruy Lopez': Color(0xFF06B6D4),
  'Sicilian Defense': Color(0xFF06B6D4),
  'Italian Game': Color(0xFF06B6D4),
  'French Defense': Color(0xFF06B6D4),
  'Caro-Kann Defense': Color(0xFF06B6D4),
  "Petrov's Defense": Color(0xFF06B6D4),
  'Pirc Defense': Color(0xFF06B6D4),
  'Modern Defense': Color(0xFF06B6D4),
  'Scandinavian Defense': Color(0xFF06B6D4),
  "Alekhine's Defense": Color(0xFF06B6D4),
  'Vienna Game': Color(0xFF06B6D4),
  'Scotch Game': Color(0xFF06B6D4),
  "King's Gambit": Color(0xFF06B6D4),
  'Philidor Defense': Color(0xFF06B6D4),
  'Four Knights Game': Color(0xFF06B6D4),
  'Open Game': Color(0xFF06B6D4),
  "King's Pawn Game": Color(0xFF06B6D4),
  "Queen's Gambit": Color(0xFF8B5CF6),
  "Queen's Gambit Declined": Color(0xFF8B5CF6),
  "King's Indian Defense": Color(0xFF8B5CF6),
  'Catalan Opening': Color(0xFF8B5CF6),
  'Benoni Defense': Color(0xFF8B5CF6),
  'Slav Defense': Color(0xFF8B5CF6),
  'Nimzo-Indian Defense': Color(0xFF8B5CF6),
  'Grünfeld Defense': Color(0xFF8B5CF6),
  'Dutch Defense': Color(0xFF8B5CF6),
  'London System': Color(0xFF8B5CF6),
  'Closed Game': Color(0xFF8B5CF6),
  "Queen's Pawn Game": Color(0xFF8B5CF6),
  'Réti Opening': Color(0xFF10B981),
  'English Opening': Color(0xFF10B981),
  "Bird's Opening": Color(0xFF10B981),
  "King's Fianchetto": Color(0xFF10B981),
  'Nimzowitsch-Larsen Attack': Color(0xFF10B981),
  'Chess 960 Variant': Color(0xFFF59E0B),
  'Custom / Unclassified': Color(0xFF94A3B8),
};

class RepertoireCard extends ConsumerWidget {
  const RepertoireCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgState = ref.watch(battlegroundProvider);
    final openings = bgState.cachedOpenings;
    final middlegames = bgState.cachedMiddlegames;
    final endgames = bgState.cachedEndgames;

    // Build a fast lookup map: opening name → stats
    final Map<String, OpeningRepertoireStats> openingMap = {
      for (final o in openings) o.name: o,
    };

    return JuicyGlassCard(
      borderColor: const Color(0xFF14B8A6),
      padding: const EdgeInsets.all(24),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── OPENING GROUP ──────────────────────────────────────────────
          _buildGroupHeader('OPENING', Icons.menu_book_rounded, const Color(0xFF06B6D4)),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.4,
                ),
                itemCount: _kAllOpenings.length,
                itemBuilder: (context, index) {
                  final name = _kAllOpenings[index];
                  final stats = openingMap[name];
                  final accentColor = _kOpeningGroupColor[name] ?? ScholarlyTheme.accentBlue;
                  return _buildOpeningChip(context, ref, name, stats, accentColor);
                },
              );
            },
          ),

          const SizedBox(height: 28),
          Divider(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4), height: 1),
          const SizedBox(height: 24),

          // ── MIDGAME GROUP ──────────────────────────────────────────────
          _buildGroupHeader('MIDGAME', Icons.insights_rounded, const Color(0xFF8B5CF6)),
          const SizedBox(height: 16),
          _buildMiddlegameGroup(middlegames),

          const SizedBox(height: 28),
          Divider(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4), height: 1),
          const SizedBox(height: 24),

          // ── ENDGAME GROUP ──────────────────────────────────────────────
          _buildGroupHeader('ENDGAME', Icons.flag_rounded, const Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          _buildEndgameGroup(endgames),
        ],
      ),
    );
  }

  Widget _buildMiddlegameGroup(MiddlegamePerformanceStats? middlegames) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 480;

        if (middlegames != null) {
          final m = middlegames;
          return _endgameRow([
            _buildEndgameMetricCard(
              label: 'MPI Score',
              icon: Icons.track_changes_rounded,
              value: '${m.mpi.toStringAsFixed(1)}%',
              sub: m.archetype,
              accentColor: const Color(0xFF8B5CF6),
              active: true,
              progressValue: m.mpi / 100,
            ),
            _buildEndgameMetricCard(
              label: 'Win Rate',
              icon: Icons.arrow_upward_rounded,
              value: '${m.winRate.toStringAsFixed(0)}%',
              sub: 'win/draw performance',
              accentColor: const Color(0xFF10B981),
              active: true,
              progressValue: m.winRate / 100,
            ),
            _buildEndgameMetricCard(
              label: 'Decided Midgame',
              icon: Icons.insights_rounded,
              value: '${m.decidedPercentage.toStringAsFixed(0)}%',
              sub: 'no endgame reached',
              accentColor: const Color(0xFF06B6D4),
              active: true,
              progressValue: m.decidedPercentage / 100,
            ),
            _buildEndgameMetricCard(
              label: 'Total Midgames',
              icon: Icons.workspace_premium_rounded,
              value: '${m.totalMiddlegames}',
              sub: 'middlegame matches',
              accentColor: const Color(0xFFF59E0B),
              active: true,
              progressValue: null,
            ),
          ], isNarrow);
        }

        // No middlegame data yet — all greyed out
        return _endgameRow([
          _buildEndgameMetricCard(
            label: 'MPI Score',
            icon: Icons.track_changes_rounded,
            value: '—',
            sub: 'No data',
            accentColor: const Color(0xFF8B5CF6),
            active: false,
            progressValue: null,
          ),
          _buildEndgameMetricCard(
            label: 'Win Rate',
            icon: Icons.arrow_upward_rounded,
            value: '—',
            sub: 'No data',
            accentColor: const Color(0xFF10B981),
            active: false,
            progressValue: null,
          ),
          _buildEndgameMetricCard(
            label: 'Decided Midgame',
            icon: Icons.insights_rounded,
            value: '—',
            sub: 'No data',
            accentColor: const Color(0xFF06B6D4),
            active: false,
            progressValue: null,
          ),
          _buildEndgameMetricCard(
            label: 'Total Midgames',
            icon: Icons.workspace_premium_rounded,
            value: '0',
            sub: 'middlegame matches',
            accentColor: const Color(0xFFF59E0B),
            active: false,
            progressValue: null,
          ),
        ], isNarrow);
      },
    );
  }

  Widget _buildGroupHeader(String label, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildOpeningChip(BuildContext context, WidgetRef ref, String name, OpeningRepertoireStats? stats, Color accentColor) {
    final bool played = stats != null && stats.plays > 0;
    final double opacity = played ? 1.0 : 0.38;
    final Color borderColor = played
        ? accentColor.withValues(alpha: 0.5)
        : ScholarlyTheme.panelStroke.withValues(alpha: 0.3);

    final winPct = (stats != null && stats.plays > 0) ? stats.wins / stats.plays : 0.0;
    final drawPct = (stats != null && stats.plays > 0) ? stats.draws / stats.plays : 0.0;
    final lossPct = (stats != null && stats.plays > 0) ? stats.losses / stats.plays : 0.0;

    final Widget chipContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: played
            ? accentColor.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Name + play count badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: played ? ScholarlyTheme.textPrimary : ScholarlyTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: played
                      ? accentColor.withValues(alpha: 0.12)
                      : ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  played ? '${stats.plays}' : '0',
                  style: GoogleFonts.jetBrainsMono(
                    color: played ? accentColor : ScholarlyTheme.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Win rate + tri-bar (only when played)
          if (played) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${stats.winRate.toStringAsFixed(0)}% WR',
                  style: GoogleFonts.jetBrainsMono(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    if (winPct > 0)
                      Expanded(
                        flex: (winPct * 1000).toInt(),
                        child: Container(color: const Color(0xFF10B981)),
                      ),
                    if (drawPct > 0)
                      Expanded(
                        flex: (drawPct * 1000).toInt(),
                        child: Container(color: const Color(0xFF64748B)),
                      ),
                    if (lossPct > 0)
                      Expanded(
                        flex: (lossPct * 1000).toInt(),
                        child: Container(color: const Color(0xFFEF4444)),
                      ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'No games yet',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textMuted,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );

    final Widget chip = Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: () {
          _showOpeningDetailSheet(context, ref, name, stats);
        },
        borderRadius: BorderRadius.circular(12),
        child: chipContent,
      ),
    );

    // Only apply hover scale to chips that have been played
    if (played) {
      return HoverScaleEffect(
        scale: 1.03,
        child: chip,
      );
    }
    return chip;
  }

  Widget _buildEndgameGroup(EndgamePerformanceStats? endgames) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 480;

        if (endgames != null) {
          final e = endgames;
          return _endgameRow([
            _buildEndgameMetricCard(
              label: 'EPI Score',
              icon: Icons.track_changes_rounded,
              value: '${e.epi.toStringAsFixed(1)}%',
              sub: e.ratingCategory,
              accentColor: const Color(0xFFF59E0B),
              active: true,
              progressValue: e.epi / 100,
            ),
            _buildEndgameMetricCard(
              label: 'Conversion Rate',
              icon: Icons.arrow_upward_rounded,
              value: '${e.conversionRate.toStringAsFixed(0)}%',
              sub: '${e.advantageGames} adv. games',
              accentColor: const Color(0xFF10B981),
              active: true,
              progressValue: e.conversionRate / 100,
            ),
            _buildEndgameMetricCard(
              label: 'Defensive Save',
              icon: Icons.shield_rounded,
              value: '${e.saveRate.toStringAsFixed(0)}%',
              sub: '${e.disadvantageGames} def. games',
              accentColor: const Color(0xFF06B6D4),
              active: true,
              progressValue: e.saveRate / 100,
            ),
            _buildEndgameMetricCard(
              label: 'Total Endgames',
              icon: Icons.flag_rounded,
              value: '${e.endgameSavesCount}',
              sub: 'endgame positions',
              accentColor: const Color(0xFFA855F7),
              active: true,
              progressValue: null,
            ),
          ], isNarrow);
        }

        // No endgame data yet — all greyed out
        return _endgameRow([
          _buildEndgameMetricCard(
            label: 'EPI Score',
            icon: Icons.track_changes_rounded,
            value: '—',
            sub: 'No data',
            accentColor: const Color(0xFFF59E0B),
            active: false,
            progressValue: null,
          ),
          _buildEndgameMetricCard(
            label: 'Conversion Rate',
            icon: Icons.arrow_upward_rounded,
            value: '—',
            sub: 'No data',
            accentColor: const Color(0xFF10B981),
            active: false,
            progressValue: null,
          ),
          _buildEndgameMetricCard(
            label: 'Defensive Save',
            icon: Icons.shield_rounded,
            value: '—',
            sub: 'No data',
            accentColor: const Color(0xFF06B6D4),
            active: false,
            progressValue: null,
          ),
          _buildEndgameMetricCard(
            label: 'Total Endgames',
            icon: Icons.flag_rounded,
            value: '0',
            sub: 'endgame positions',
            accentColor: const Color(0xFFA855F7),
            active: false,
            progressValue: null,
          ),
        ], isNarrow);
      },
    );
  }

  Widget _endgameRow(List<Widget> cards, bool isNarrow) {
    if (isNarrow) {
      return Column(
        children: cards
            .map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: c))
            .toList(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildEndgameMetricCard({
    required String label,
    required IconData icon,
    required String value,
    required String sub,
    required Color accentColor,
    required bool active,
    double? progressValue,
  }) {
    final opacity = active ? 1.0 : 0.38;
    final Widget card = Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: active ? 0.06 : 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? accentColor.withValues(alpha: 0.3)
                : ScholarlyTheme.panelStroke.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: accentColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textMuted,
                fontSize: 10.5,
              ),
            ),
            if (progressValue != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 5,
                  color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressValue.clamp(0.0, 1.0),
                    child: Container(color: accentColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    // Only apply hover scale to active metric cards
    if (active) {
      return HoverScaleEffect(
        scale: 1.03,
        child: card,
      );
    }
    return card;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Opening Repertoire Bottom Sheet & Details Widgets
// ─────────────────────────────────────────────────────────────────────────────

void _showOpeningDetailSheet(
  BuildContext context,
  WidgetRef ref,
  String openingName,
  OpeningRepertoireStats? stats,
) {
  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _OpeningDetailSheet(
      openingName: openingName,
      stats: stats,
    ),
  );
}

class _OpeningDetailSheet extends ConsumerStatefulWidget {
  final String openingName;
  final OpeningRepertoireStats? stats;

  const _OpeningDetailSheet({
    required this.openingName,
    this.stats,
  });

  @override
  ConsumerState<_OpeningDetailSheet> createState() => _OpeningDetailSheetState();
}

class _OpeningDetailSheetState extends ConsumerState<_OpeningDetailSheet> {
  bool _isLoadingGame = false;
  String? _loadingGameId;

  @override
  Widget build(BuildContext context) {
    final bgState = ref.watch(battlegroundProvider);
    final ratedSaves = selectScotomaLedgerEntries(bgState.cachedLedgerEntries);
    final matchingGames = ratedSaves.where((s) {
      final op = OpeningClassifier.detectOpening(s.recentMoves, gameMode: s.gameMode);
      return op == widget.openingName;
    }).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final totalPlays = matchingGames.length;
    final totalWins = matchingGames.where((g) => g.result == 'W').length;
    final totalDraws = matchingGames.where((g) => g.result == 'D').length;
    final winRate = totalPlays > 0 ? ((totalWins + 0.5 * totalDraws) / totalPlays * 100) : 0.0;

    final whiteGames = matchingGames.where((g) => g.isPlayerWhite).toList();
    final blackGames = matchingGames.where((g) => !g.isPlayerWhite).toList();

    final whiteWins = whiteGames.where((g) => g.result == 'W').length;
    final whiteDraws = whiteGames.where((g) => g.result == 'D').length;
    final whiteLosses = whiteGames.where((g) => g.result == 'L').length;

    final blackWins = blackGames.where((g) => g.result == 'W').length;
    final blackDraws = blackGames.where((g) => g.result == 'D').length;
    final blackLosses = blackGames.where((g) => g.result == 'L').length;

    final canonicalMoves = _kOpeningCanonicalMoves[widget.openingName] ?? [];
    
    String startingFen = chess_lib.Chess.DEFAULT_POSITION;
    if (widget.openingName == 'Chess 960 Variant') {
      if (matchingGames.isNotEmpty) {
        startingFen = matchingGames.first.initialFen ?? chess_lib.Chess.DEFAULT_POSITION;
      }
    } else {
      startingFen = _getFenForCanonicalMoves(canonicalMoves);
    }

    String movesText = '';
    if (canonicalMoves.isNotEmpty) {
      final buffer = StringBuffer();
      for (int i = 0; i < canonicalMoves.length; i++) {
        if (i % 2 == 0) {
          buffer.write('${(i ~/ 2) + 1}. ');
        }
        buffer.write('${canonicalMoves[i]} ');
      }
      movesText = buffer.toString().trim();
    } else if (widget.openingName == 'Chess 960 Variant') {
      movesText = 'Starting configuration varies per game';
    } else {
      movesText = 'Initial board position';
    }

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 680),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewSection(startingFen, movesText, totalPlays, winRate, whiteGames.length, blackGames.length),
                      const SizedBox(height: 24),
                      _buildColorComparisonRow(whiteGames.length, whiteWins, whiteDraws, whiteLosses, blackGames.length, blackWins, blackDraws, blackLosses),
                      const SizedBox(height: 24),
                      _buildStrategicPersonaCard(),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, color: ScholarlyTheme.accentBlue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'MATCH RECORD LOG',
                            style: GoogleFonts.outfit(
                              color: ScholarlyTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (matchingGames.isEmpty)
                        _buildEmptyMatchesView()
                      else
                        _buildGamesListView(matchingGames, canonicalMoves),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrategicPersonaCard() {
    final persona = _kOpeningStrategicPersonas[widget.openingName] ?? 
                    _kOpeningStrategicPersonas['Custom / Unclassified']!;
    final accentColor = _kOpeningGroupColor[widget.openingName] ?? ScholarlyTheme.accentBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'TACTICAL CHARACTER',
                style: GoogleFonts.outfit(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            persona,
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textPrimary,
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.openingName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'WEAPON MASTER FILE',
                        style: GoogleFonts.jetBrainsMono(
                          color: ScholarlyTheme.accentBlue,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: ScholarlyTheme.textMuted),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection(
    String startingFen,
    String movesText,
    int totalPlays,
    double winRate,
    int whiteCount,
    int blackCount,
  ) {
    final accentColor = _kOpeningGroupColor[widget.openingName] ?? ScholarlyTheme.accentBlue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            MiniBoardPreview(
              fen: startingFen,
              size: 130,
              isFlipped: blackCount > whiteCount,
            ),
            const SizedBox(height: 8),
            Container(
              width: 130,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ScholarlyTheme.panelStroke, width: 1),
              ),
              child: Text(
                movesText,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsTile('TOTAL RATED MATCHES', '$totalPlays', accentColor),
              const SizedBox(height: 12),
              _buildStatsTile('OVERALL WIN RATE', totalPlays > 0 ? '${winRate.toStringAsFixed(1)}%' : '—', accentColor),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildPerspectiveTile('AS WHITE', '$whiteCount matches', Colors.white, ScholarlyTheme.textPrimary)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildPerspectiveTile('AS BLACK', '$blackCount matches', Colors.black, Colors.white)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTile(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: ScholarlyTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerspectiveTile(String label, String sub, Color bgColor, Color textColor) {
    final bool dark = bgColor == Colors.black;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: dark ? Colors.black : ScholarlyTheme.panelStroke,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: dark ? Colors.white60 : ScholarlyTheme.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorComparisonRow(
    int whiteCount, int whiteWins, int whiteDraws, int whiteLosses,
    int blackCount, int blackWins, int blackDraws, int blackLosses,
  ) {
    final double whiteWinRate = whiteCount > 0 ? (whiteWins + 0.5 * whiteDraws) / whiteCount * 100 : 0.0;
    final double blackWinRate = blackCount > 0 ? (blackWins + 0.5 * blackDraws) / blackCount * 100 : 0.0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AS WHITE', style: GoogleFonts.outfit(color: ScholarlyTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      whiteCount > 0 ? '${whiteWinRate.toStringAsFixed(0)}% WR' : '—',
                      style: GoogleFonts.jetBrainsMono(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  whiteCount > 0 ? '$whiteWins W - $whiteDraws D - $whiteLosses L' : '0 W - 0 D - 0 L',
                  style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 10),
                ),
                const SizedBox(height: 8),
                _buildDistributionBar(whiteCount, whiteWins, whiteDraws, whiteLosses),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('AS BLACK', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      blackCount > 0 ? '${blackWinRate.toStringAsFixed(0)}% WR' : '—',
                      style: GoogleFonts.jetBrainsMono(color: const Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  blackCount > 0 ? '$blackWins W - $blackDraws D - $blackLosses L' : '0 W - 0 D - 0 L',
                  style: GoogleFonts.jetBrainsMono(color: Colors.white70, fontSize: 10),
                ),
                const SizedBox(height: 8),
                _buildDistributionBar(blackCount, blackWins, blackDraws, blackLosses),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionBar(int count, int wins, int draws, int losses) {
    if (count == 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: Container(height: 6, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4)),
      );
    }

    final winPercent = wins / count;
    final drawPercent = draws / count;
    final lossPercent = losses / count;

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            if (wins > 0)
              Expanded(
                flex: (winPercent * 1000).toInt(),
                child: Container(color: const Color(0xFF10B981)),
              ),
            if (draws > 0)
              Expanded(
                flex: (drawPercent * 1000).toInt(),
                child: Container(color: const Color(0xFF64748B)),
              ),
            if (losses > 0)
              Expanded(
                flex: (lossPercent * 1000).toInt(),
                child: Container(color: const Color(0xFFEF4444)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamesListView(List<PerformanceLedgerEntry> games, List<String> canonicalMoves) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final game = games[index];
        final isWin = game.result == 'W';
        final isDraw = game.result == 'D';
        final resultColor = isWin
            ? const Color(0xFF10B981)
            : (isDraw ? const Color(0xFF64748B) : const Color(0xFFEF4444));
        final resultLabel = isWin ? 'WIN' : (isDraw ? 'DRAW' : 'LOSS');

        final int totalMoves = (game.recentMoves.length / 2).ceil();
        final int deviationPly = _calculateDeviationMove(game.recentMoves, canonicalMoves);

        final dateStr = formatter.format(game.timestamp);
        final formatLabel = '${game.ratingCategory.toUpperCase()} | vs. ${game.opponentName}';

        final isThisLoading = _isLoadingGame && _loadingGameId == game.id;

        return HoverScaleEffect(
          scale: 1.02,
          child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  color: resultColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: resultColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                resultLabel,
                                style: GoogleFonts.jetBrainsMono(
                                  color: resultColor,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              dateStr,
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Total: $totalMoves moves',
                              style: GoogleFonts.inter(
                                color: ScholarlyTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                            if (widget.openingName != 'Chess 960 Variant' && canonicalMoves.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: ScholarlyTheme.panelStroke)),
                              const SizedBox(width: 8),
                              Text(
                                deviationPly > (game.recentMoves.length)
                                    ? 'Followed theory line'
                                    : 'Deviated at move $deviationPly',
                                style: GoogleFonts.inter(
                                  color: deviationPly > (game.recentMoves.length) ? const Color(0xFF10B981) : ScholarlyTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: deviationPly > (game.recentMoves.length) ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: isThisLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: ScholarlyTheme.accentBlue),
                          )
                        : TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: ScholarlyTheme.accentBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.science_outlined, size: 14),
                            label: Text(
                              'ANALYZE',
                              style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _handleAnalyzeMatch(game),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  Widget _buildEmptyMatchesView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
      ),
      child: Center(
        child: Text(
          'No rated matches recorded for this opening weapon.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textMuted,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  int _calculateDeviationMove(List<String> gameMoves, List<String> canonicalMoves) {
    if (canonicalMoves.isEmpty) return 1;
    int i = 0;
    while (i < gameMoves.length && i < canonicalMoves.length) {
      if (gameMoves[i] != canonicalMoves[i]) break;
      i++;
    }
    return (i / 2).ceil() + 1;
  }

  Future<void> _handleAnalyzeMatch(PerformanceLedgerEntry game) async {
    setState(() {
      _isLoadingGame = true;
      _loadingGameId = game.id;
    });

    try {
      final savedGames = await ref.read(chessProvider.notifier).loadSavedGames();
      final entry = savedGames.where((g) => g.id == game.id).firstOrNull;

      if (entry != null) {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
        ref.read(studyLabProvider.notifier).loadGameEntry(entry);
        ref.read(mobileNavIndexProvider.notifier).state = 5;
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Match entry not found in the local archive.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load match in analysis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load match: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGame = false;
          _loadingGameId = null;
        });
      }
    }
  }
}

// Canonical opening move databases
const Map<String, List<String>> _kOpeningCanonicalMoves = {
  'Ruy Lopez': ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'],
  'Sicilian Defense': ['e4', 'c5'],
  "Queen's Gambit": ['d4', 'd5', 'c4'],
  'Italian Game': ['e4', 'e5', 'Nf3', 'Nc6', 'Bc4'],
  'French Defense': ['e4', 'e6'],
  'Caro-Kann Defense': ['e4', 'c6'],
  "King's Indian Defense": ['d4', 'Nf6', 'c4', 'g6'],
  "Petrov's Defense": ['e4', 'e5', 'Nf3', 'Nf6'],
  "Queen's Gambit Declined": ['d4', 'd5', 'c4', 'e6'],
  'Catalan Opening': ['d4', 'Nf6', 'c4', 'e6', 'g3', 'd5'],
  'Benoni Defense': ['d4', 'Nf6', 'c4', 'c5', 'd5'],
  'Pirc Defense': ['e4', 'd6'],
  'Modern Defense': ['e4', 'g6'],
  'Scandinavian Defense': ['e4', 'd5'],
  "Alekhine's Defense": ['e4', 'Nf6'],
  'Vienna Game': ['e4', 'e5', 'Nc3'],
  'Scotch Game': ['e4', 'e5', 'Nf3', 'Nc6', 'd4'],
  "King's Gambit": ['e4', 'e5', 'f4'],
  'Philidor Defense': ['e4', 'e5', 'Nf3', 'd6'],
  'Slav Defense': ['d4', 'd5', 'c4', 'c6'],
  'Nimzo-Indian Defense': ['d4', 'Nf6', 'c4', 'e6', 'Nc3', 'Bb4'],
  'Grünfeld Defense': ['d4', 'Nf6', 'c4', 'g6', 'Nc3', 'd5'],
  'Dutch Defense': ['d4', 'f5'],
  'London System': ['d4', 'd5', 'Nf3', 'Nf6', 'Bf4'],
  'Four Knights Game': ['e4', 'e5', 'Nf3', 'Nc6', 'Nc3', 'Nf6'],
  'Open Game': ['e4', 'e5'],
  "King's Pawn Game": ['e4'],
  "Queen's Pawn Game": ['d4'],
  'Réti Opening': ['Nf3'],
  'English Opening': ['c4'],
  "Bird's Opening": ['f4'],
  "King's Fianchetto": ['g3'],
  'Nimzowitsch-Larsen Attack': ['b3'],
};

String _getFenForCanonicalMoves(List<String> moves) {
  if (moves.isEmpty) {
    return chess_lib.Chess.DEFAULT_POSITION;
  }
  try {
    final chess = chess_lib.Chess();
    for (final move in moves) {
      chess.move(move);
    }
    return chess.fen;
  } catch (e) {
    debugPrint('Failed to generate FEN for opening moves: $e');
    return chess_lib.Chess.DEFAULT_POSITION;
  }
}

// Opening tactical profile database mapping
const Map<String, String> _kOpeningStrategicPersonas = {
  'Ruy Lopez': 'High play counts in the Ruy Lopez suggest a classical, balanced player. You value deep theoretical lines, subtle positional sparring, and complex middlegames with rich tactical and strategic opportunities.',
  'Sicilian Defense': 'Playing the Sicilian Defense frequently indicates an aggressive, counter-punching spirit. You reject symmetrical stability and welcome sharp, double-edged complications where precise calculation outweighs quiet maneuvering.',
  'Italian Game': 'A preference for the Italian Game reflects a direct, active approach to chess. You enjoy classic open positions, rapid development, and tactical piece play targeting weaknesses like the f7/f2 square.',
  'French Defense': 'Frequent plays of the French Defense suggest a resilient, counter-attacking character. You don\'t mind starting in a cramped position, trusting in your ability to undermine White\'s center and strike back on the queenside.',
  'Caro-Kann Defense': 'Relying on the Caro-Kann reveals a solid, patient, and highly dependable style. You prioritize pawn structure integrity, safe king placement, and outplaying your opponent in late-stage positional endgames.',
  "Petrov's Defense": 'Playing Petrov\'s Defense points to a highly disciplined, risk-averse style. You value symmetry, strong defensive walls, and seek to neutralize White\'s first-move advantage early to play for solid outcomes.',
  'Pirc Defense': 'Choosing the Pirc Defense shows a hypermodern, flexible mindset. You invite your opponent to occupy the center with pawns, planning to break it down later through dynamic flank play and piece pressure.',
  'Modern Defense': 'A high volume of Modern Defense games indicates an unconventional, creative approach. You focus on king safety and fianchettoed bishops, delaying central engagement to launch unexpected counter-strikes.',
  'Scandinavian Defense': 'Playing the Scandinavian indicates a proactive, combative style. You enjoy immediate contact, clear-cut piece development paths, and forcing the game into your own territory from move one.',
  "Alekhine's Defense": 'Relying on Alekhine\'s Defense suggests a provocative and counter-attacking style. You invite the opponent\'s pawns forward, planning to target their overextended structure later.',
  'Vienna Game': 'Frequent plays of the Vienna Game point to a flexible, creative tactician. You develop your Nc3 first to keep pawn options open, ready to transition from solid position to a sudden kingside attack.',
  'Scotch Game': 'Playing the Scotch Game shows an active, open-board weapon. You strike directly in the center on move three, opening diagonals for rapid piece activation and active skirmishes.',
  "King's Gambit": 'The King\'s Gambit indicates a romantic, high-stakes tactical character. You gladly sacrifice material to open lines, targeting the f7 square and launching a chaotic kingside storm.',
  'Philidor Defense': 'Relying on the Philidor Defense indicates a quiet, safety-first defensive style. You establish a compact, solid defensive wall, aiming to absorb early white aggression and counter-strike patiently.',
  'Slav Defense': 'The Slav Defense represents rock-solid stability. You support your center with c6 rather than blocking your light-squared bishop, aiming for robust pawn structures and counter-chances in positional endgames.',
  'Nimzo-Indian Defense': 'Playing the Nimzo-Indian indicates a sophisticated, dynamic approach. You are comfortable fighting for the center with piece activity and are willing to double White\'s pawns to gain positional control.',
  'Grünfeld Defense': 'The Grünfeld Defense indicates a highly combative and hypermodern spirit. You allow White a big center only to immediately attack it with active piece coordination and rapid central pawn breaks.',
  'Dutch Defense': 'A preference for the Dutch Defense reflects an ambitious, asymmetric mindset. You seek to control key central squares with f5, setting up rich, double-edged kingside attacking chances.',
  'London System': 'Choosing the London System shows a highly practical and reliable strategic character. You value harmonious development, strong center pyramids, and minimizing early tactical risks.',
  'Four Knights Game': 'Symmetrical and solid, playing the Four Knights Game shows a classical, safety-first attitude. You prioritize rapid development, control of the center, and avoiding early complications.',
  'Open Game': 'A preference for the Open Game suggests you thrive in open tactical boards. You enjoy classical piece play, active skirmishes, and rapid development where tactical awareness is paramount.',
  "King's Pawn Game": 'Playing the King\'s Pawn Game reflects a classical, active playing style. You prefer open lines, direct contact, and classical development paths to seek active positions.',
  "Queen's Gambit": 'Frequently playing the Queen\'s Gambit demonstrates a professional, dominant positional style. You enjoy pressuring the center, dictating the space advantage, and maneuvering in structured, technical positions.',
  "Queen's Gambit Declined": 'Choosing the Queen\'s Gambit Declined reflects a deeply classical, resilient foundation. You prioritize central defense, strong pawn chains, and patience in navigating complex middlegames.',
  "King's Indian Defense": 'A preference for the King\'s Indian reveals a fierce, hypermodern attacking style. You are comfortable letting your opponent take the center in exchange for building a devastating king-side storm.',
  'Catalan Opening': 'Playing the Catalan Opening shows a sophisticated, master-class positional style. You enjoy combining central pressure with a powerful fianchettoed bishop on g2, squeezing your opponent slowly.',
  'Benoni Defense': 'A high play count in the Benoni Defense reveals a daring, hyper-aggressive tactician. You welcome highly asymmetrical pawn structures, open diagonals, and dynamic, double-edged combat.',
  'Closed Game': 'A high play count under Closed Game means you are comfortable in strategic, grind-it-out positions where tactical blunders are less common, but deep positional understanding (outmaneuvering, space advantage) is required to win.',
  "Queen's Pawn Game": 'A preference for the Queen\'s Pawn Game indicates a solid, controlled approach. You prefer closed structures, reliable setups, and positional maneuvering over open-board chaos.',
  'Réti Opening': 'Relying on the Réti Opening shows a highly flexible, positional style. You avoid early concrete pawn clashes, choosing to control the center from a distance with pieces and strike late.',
  'English Opening': 'Playing the English Opening reflects a mature, strategic approach. You prefer to fight for the center indirectly, maneuvering with a space advantage and steering the game into technical territory.',
  "Bird's Opening": 'Choosing Bird\'s Opening shows an individualistic, aggressive mindset. You seek to take opponents out of their comfort zone early, grabbing kingside space and playing for early attacking lines.',
  "King's Fianchetto": 'A preference for the King\'s Fianchetto points to a quiet, hypermodern flexibility. You prioritize absolute king safety and diagonal piece pressure, adapting your strategy to your opponent\'s choices.',
  'Nimzowitsch-Larsen Attack': 'Playing the Nimzowitsch-Larsen Attack shows a creative, flank-focused strategist. You love the power of a long-range queenside bishop controlling the critical central dark squares.',
  'Chess 960 Variant': 'Playing Chess 960 frequently indicates a pure chess thinker. You rely entirely on raw calculation, logic, and fundamental chess principles rather than memorized opening theory.',
  'Custom / Unclassified': 'Unclassified games show a highly tactical, non-conformist style. You play by intuition and immediate tactical calculations, steering away from traditional theoretical guidelines.',
};
