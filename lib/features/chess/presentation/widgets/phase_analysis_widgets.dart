import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scholarly_theme.dart';
import '../../application/battleground_provider.dart';
import '../../domain/models/dashboard_stats.dart';
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
  'Four Knights Game',
  'Open Game',
  "King's Pawn Game",
  // d4 openings
  "Queen's Gambit",
  "Queen's Gambit Declined",
  "King's Indian Defense",
  'Catalan Opening',
  'Benoni Defense',
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
  'Four Knights Game': Color(0xFF06B6D4),
  'Open Game': Color(0xFF06B6D4),
  "King's Pawn Game": Color(0xFF06B6D4),
  "Queen's Gambit": Color(0xFF8B5CF6),
  "Queen's Gambit Declined": Color(0xFF8B5CF6),
  "King's Indian Defense": Color(0xFF8B5CF6),
  'Catalan Opening': Color(0xFF8B5CF6),
  'Benoni Defense': Color(0xFF8B5CF6),
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
                  return _buildOpeningChip(name, stats, accentColor);
                },
              );
            },
          ),

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

  Widget _buildOpeningChip(String name, OpeningRepertoireStats? stats, Color accentColor) {
    final bool played = stats != null && stats.plays > 0;
    final double opacity = played ? 1.0 : 0.38;
    final Color borderColor = played
        ? accentColor.withValues(alpha: 0.5)
        : ScholarlyTheme.panelStroke.withValues(alpha: 0.3);

    final winPct = (stats != null && stats.plays > 0) ? stats.wins / stats.plays : 0.0;
    final drawPct = (stats != null && stats.plays > 0) ? stats.draws / stats.plays : 0.0;
    final lossPct = (stats != null && stats.plays > 0) ? stats.losses / stats.plays : 0.0;

    return Opacity(
      opacity: opacity,
      child: Container(
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
      ),
    );
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
    return Opacity(
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
  }
}
