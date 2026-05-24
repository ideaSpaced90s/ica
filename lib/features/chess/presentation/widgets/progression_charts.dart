import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../scholarly_theme.dart';
import '../../application/chess_provider.dart';
import '../../domain/performance_ledger_entry.dart';
import 'ambient_scaffold.dart';

class EloAscentChart extends ConsumerWidget {
  const EloAscentChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(chessProvider).cachedLedgerEntries;
    final ratedSaves = List<PerformanceLedgerEntry>.from(ledger);
    ratedSaves.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (ratedSaves.isEmpty) {
      return _buildEmptyState('No rating data yet. Play a rated match to see your ascent.');
    }

    final bulletSpots = _getSpots(ratedSaves, 'bullet');
    final blitzSpots = _getSpots(ratedSaves, 'blitz');
    final rapidSpots = _getSpots(ratedSaves, 'rapid');

    final allSpots = [...bulletSpots, ...blitzSpots, ...rapidSpots];
    double minYVal = 1000.0;
    double maxYVal = 1400.0;
    if (allSpots.isNotEmpty) {
      final yValues = allSpots.map((spot) => spot.y).toList();
      final minVal = yValues.reduce(math.min);
      final maxVal = yValues.reduce(math.max);
      final range = maxVal - minVal;
      final padding = range < 100 ? 50.0 : (range * 0.15);
      minYVal = math.max(0.0, (minVal - padding).floorToDouble());
      maxYVal = (maxVal + padding).ceilToDouble();
    }

    double maxXVal = 1.0;
    final lengths = [bulletSpots.length, blitzSpots.length, rapidSpots.length];
    final maxLen = lengths.reduce(math.max);
    if (maxLen > 1) {
      maxXVal = (maxLen - 1).toDouble();
    }

    return JuicyGlassCard(
      borderColor: const Color(0xFF06B6D4), // Vibrant Electric Cyan Border
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: maxXVal,
            minY: minYVal,
            maxY: maxYVal,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 10),
                  ),
                  reservedSize: 35,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              if (bulletSpots.isNotEmpty) _lineBarData(bulletSpots, const Color(0xFF00F0FF)), // Electric Neon Cyan
              if (blitzSpots.isNotEmpty) _lineBarData(blitzSpots, const Color(0xFFEC4899)), // Electric Neon Hot Pink
              if (rapidSpots.isNotEmpty) _lineBarData(rapidSpots, const Color(0xFF10B981)), // Electric Neon Emerald
            ],
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((spotIndex) {
                  return TouchedSpotIndicatorData(
                    FlLine(color: (barData.color ?? Colors.blue).withValues(alpha: 0.5), strokeWidth: 2, dashArray: [4, 4]),
                    FlDotData(
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 6,
                          color: barData.color ?? Colors.blue,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  );
                }).toList();
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => ScholarlyTheme.panelBase,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y.toInt()}',
                      GoogleFonts.jetBrainsMono(
                        color: spot.bar.color ?? ScholarlyTheme.textPrimary, 
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getSpots(List<PerformanceLedgerEntry> saves, String category) {
    final filtered = saves.where((s) => s.ratingCategory == category).toList();
    if (filtered.isEmpty) return [];

    final List<FlSpot> spots = [];
    spots.add(const FlSpot(0, 1200));

    for (int i = 0; i < filtered.length; i++) {
      final snapshot = filtered[i].ratingSnapshot;
      spots.add(FlSpot((i + 1).toDouble(), snapshot.toDouble()));
    }
    return spots;
  }

  LineChartBarData _lineBarData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      height: 200,
      decoration: ScholarlyTheme.modernDecoration(),
      child: Center(
        child: Text(msg, 
          style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class TacticalRadarChart extends ConsumerWidget {
  const TacticalRadarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playstyle = ref.watch(chessProvider).cachedPlaystyle;
    if (playstyle == null) return const SizedBox.shrink();

    final aggression = playstyle.aggression;
    final power = playstyle.power;
    final versatility = playstyle.versatility;
    final intensity = playstyle.intensity;
    final speed = playstyle.speed;

    // Determine the archetype based on highest value
    final axes = [
      (aggression, 'Aggressive Attacker', 'You consistently maintain high dominance on the board, pushing active threats.', const Color(0xFFEF4444)),
      (power, 'High-Power Veteran', 'Your rating profile shows seasoned, high-caliber positional strength.', const Color(0xFFF59E0B)),
      (versatility, 'Universalist', 'You are highly versatile, regularly transitioning between Chess960 and Classic formats.', const Color(0xFF8B5CF6)),
      (intensity, 'Relentless Competitor', 'Your profile highlights a high conversion and win rate in battles.', const Color(0xFF10B981)),
      (speed, 'Speed Demon', 'You manage your clock exceptionally well, keeping a healthy time advantage.', const Color(0xFF06B6D4)),
    ];

    var highestAxis = axes[0];
    for (final a in axes) {
      if (a.$1 > highestAxis.$1) {
        highestAxis = a;
      }
    }

    String archetypeTitle = highestAxis.$2.toUpperCase();
    String archetypeDesc = highestAxis.$3;
    Color archetypeColor = highestAxis.$4;

    if (highestAxis.$1 < 0.2) {
      archetypeTitle = 'APPRENTICE TACTICIAN';
      archetypeDesc = 'Your playstyle profile is stabilizing as you log more rated matches.';
      archetypeColor = const Color(0xFF8B5CF6);
    }

    return JuicyGlassCard(
      borderColor: const Color(0xFF8B5CF6), // Vibrant Electric Violet Border
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'PLAYSTYLE PROFILE',
              style: GoogleFonts.outfit(
                color: const Color(0xFF8B5CF6), // Violet Scholarly header
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Radar Chart inside constrained container
            SizedBox(
              height: 220,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: const Color(0x33A855F7), // Colorful purple translucent fill
                      borderColor: const Color(0xFFC084FC), // Colorful purple border
                      entryRadius: 4,
                      dataEntries: [
                        RadarEntry(value: aggression),
                        RadarEntry(value: power),
                        RadarEntry(value: versatility),
                        RadarEntry(value: intensity),
                        RadarEntry(value: speed),
                      ],
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: const BorderSide(color: Color(0xFFF3E8FF), width: 1),
                  getTitle: (index, angle) {
                    final text = ['ATK', 'POW', 'VER', 'INT', 'SPD'][index];
                    final color = [
                      const Color(0xFFEF4444), // ATK (Red)
                      const Color(0xFFF59E0B), // POW (Gold)
                      const Color(0xFF8B5CF6), // VER (Violet)
                      const Color(0xFF10B981), // INT (Emerald)
                      const Color(0xFF06B6D4), // SPD (Cyan)
                    ][index];
                    return RadarChartTitle(
                      text: '',
                      children: [
                        TextSpan(
                          text: text,
                          style: GoogleFonts.outfit(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                      angle: angle,
                    );
                  },
                  tickCount: 4,
                  ticksTextStyle: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 8),
                  gridBorderData: const BorderSide(color: Color(0xFFF3E8FF), width: 1),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Archetype Report Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: archetypeColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: archetypeColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lens_blur_rounded,
                        color: archetypeColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          archetypeTitle,
                          style: GoogleFonts.outfit(
                            color: archetypeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    archetypeDesc,
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 11.5,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Divider(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 16),
            Text(
              'PLAYSTYLE METRIC KEY',
              style: GoogleFonts.outfit(
                color: ScholarlyTheme.textSubtle,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            _buildLegendItem('ATK', 'Aggression (Attack)', 'Measures your average material and territory dominance over opponents.', const Color(0xFFEF4444)),
            const SizedBox(height: 10),
            _buildLegendItem('POW', 'Power rating', 'Scaled from your peak ELO rating achieved in rated battles.', const Color(0xFFF59E0B)),
            const SizedBox(height: 10),
            _buildLegendItem('VER', 'Versatility Index', 'Ratio of Chess960 variants played compared to Classic chess matches.', const Color(0xFF8B5CF6)),
            const SizedBox(height: 10),
            _buildLegendItem('INT', 'Intensity (Win Rate)', 'Win rate percentage calculated over all active rated matches.', const Color(0xFF10B981)),
            const SizedBox(height: 10),
            _buildLegendItem('SPD', 'Time Speed Management', 'Average ratio of remaining clock time upon match completion.', const Color(0xFF06B6D4)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String abbr, String title, String desc, Color badgeColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            abbr,
            style: GoogleFonts.jetBrainsMono(
              color: badgeColor,
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 10,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ModeDistributionChart extends ConsumerWidget {
  const ModeDistributionChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledger = ref.watch(chessProvider).cachedLedgerEntries;
    final classic = ledger.where((s) => s.gameMode == 'classic').length;
    final nineSixty = ledger.where((s) => s.gameMode == 'chess960').length;
    final total = classic + nineSixty;

    if (total == 0) {
      return Container(
        height: 180,
        decoration: ScholarlyTheme.modernDecoration(),
        child: Center(
          child: Text(
            'No rated matches played yet.',
            style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return JuicyGlassCard(
      borderColor: const Color(0xFFEC4899), // Vibrant Hot Pink Border
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 156,
        child: PieChart(
          PieChartData(
            sectionsSpace: 6,
            centerSpaceRadius: 35,
            sections: [
              PieChartSectionData(
                color: const Color(0xFF8B5CF6), // Electric Violet
                value: classic.toDouble(),
                title: 'Classic\n${(classic / total * 100).toInt()}%',
                radius: 30,
                titleStyle: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1.5)),
                  ],
                ),
              ),
              PieChartSectionData(
                color: const Color(0xFFF59E0B), // Sunny Gold
                value: nineSixty.toDouble(),
                title: '960\n${(nineSixty / total * 100).toInt()}%',
                radius: 30,
                titleStyle: GoogleFonts.jetBrainsMono(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DominanceHeatmap extends ConsumerStatefulWidget {
  const DominanceHeatmap({super.key});

  @override
  ConsumerState<DominanceHeatmap> createState() => _DominanceHeatmapState();
}

class _DominanceHeatmapState extends ConsumerState<DominanceHeatmap> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);
    final heatmap = chessState.cachedDominanceHeatmap;
    final ledgerEntries = chessState.cachedLedgerEntries;

    // Heatmap color logic helper
    Color getTileColor(double avg) {
      if (avg.isNaN) {
        return ScholarlyTheme.panelStroke.withValues(alpha: 0.3);
      }
      if (avg > 5) {
        return const Color(0xFF10B981); // Neon Emerald Green
      } else if (avg > 0) {
        return const Color(0xFF06B6D4); // Electric Cyan
      } else if (avg > -5) {
        return const Color(0xFFF59E0B); // Hot Amber
      } else {
        return const Color(0xFFEF4444); // Deep Crimson
      }
    }

    // Grouping ledger entries by day
    final Map<String, List<PerformanceLedgerEntry>> dayMatches = {};
    for (final entry in ledgerEntries) {
      final dateKey = '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}';
      dayMatches.putIfAbsent(dateKey, () => []).add(entry);
    }

    final now = DateTime.now();
    final List<Widget> dailyPerformanceWidgets = [];
    for (int i = 0; i < 30; i++) {
      final day = now.subtract(Duration(days: i));
      final dateKey = '${day.year}-${day.month}-${day.day}';
      final matches = dayMatches[dateKey];
      if (matches == null || matches.isEmpty) continue;

      // Calculate daily average
      final avgDom = matches.map((m) => m.dominance).reduce((a, b) => a + b) / matches.length;

      // Group display for this active day
      final formattedDayLabel = i == 0
          ? 'Today, ${DateFormat('MMMM d').format(day)}'
          : i == 1
              ? 'Yesterday, ${DateFormat('MMMM d').format(day)}'
              : DateFormat('EEEE, MMMM d').format(day);

      dailyPerformanceWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ScholarlyTheme.panelBase.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDayLabel,
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: getTileColor(avgDom).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: getTileColor(avgDom).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Avg: ${avgDom >= 0 ? '+' : ''}${avgDom.toStringAsFixed(1)}',
                      style: GoogleFonts.jetBrainsMono(
                        color: getTileColor(avgDom),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...matches.map((match) {
                final matchTime = DateFormat('jm').format(match.timestamp);
                final modeLabel = '${match.ratingCategory.toUpperCase()} ${match.gameMode == 'chess960' ? '960' : 'Classic'}';
                Color outcomeColor = Colors.grey;
                if (match.result == 'W') {
                  outcomeColor = Colors.green;
                } else if (match.result == 'L') {
                  outcomeColor = Colors.red;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        match.result == 'W'
                            ? Icons.check_circle_outline_rounded
                            : match.result == 'L'
                                ? Icons.cancel_outlined
                                : Icons.remove_circle_outline_rounded,
                        size: 14,
                        color: outcomeColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$matchTime • $modeLabel vs ${match.opponentName}',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dom: ${match.dominance >= 0 ? '+' : ''}${match.dominance.toStringAsFixed(1)}',
                        style: GoogleFonts.jetBrainsMono(
                          color: getTileColor(match.dominance),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );
    }

    return JuicyGlassCard(
      borderColor: const Color(0xFF10B981), // Vibrant Emerald Green Border
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Wrap Grid
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: heatmap.map((avg) {
                return Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: getTileColor(avg),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          
          // Timeline Labels (Oldest to Newest, chronologically corrected)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '30 days ago',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Today',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 8),

          // Mini Legend Row
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendTag('■ No Play', ScholarlyTheme.panelStroke.withValues(alpha: 0.4)),
              _buildLegendTag('■ Deficit', const Color(0xFFEF4444)),
              _buildLegendTag('■ Disadvantage', const Color(0xFFF59E0B)),
              _buildLegendTag('■ Close/Equal', const Color(0xFF06B6D4)),
              _buildLegendTag('■ Dominant', const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 12),

          // Collapsible Trigger button
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              icon: Icon(
                _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: ScholarlyTheme.accentBlue,
              ),
              label: Text(
                _isExpanded ? 'Hide Details' : 'Show Details & Formula',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.accentBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          // Collapsible Expanded Content
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Divider(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 16),

            // 1. Traditional Piece Value / Formula Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: ScholarlyTheme.accentBlue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'HOW DOMINANCE IS CALCULATED',
                        style: GoogleFonts.outfit(
                          color: ScholarlyTheme.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dominance measures your final material advantage at the end of rated matches. We evaluate remaining pieces using traditional values:',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Grid of values
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildPieceValueTile('♙ Pawn', '1.0'),
                      _buildPieceValueTile('♘/♗ Knight/Bishop', '3.0'),
                      _buildPieceValueTile('♖ Rook', '5.0'),
                      _buildPieceValueTile('♕ Queen', '9.0'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      'Formula: Your Pieces Value - Opponent\'s Pieces Value',
                      style: GoogleFonts.jetBrainsMono(
                        color: ScholarlyTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Day-by-Day Match Performance List
            Text(
              'DAILY PERFORMANCE LOG',
              style: GoogleFonts.outfit(
                color: ScholarlyTheme.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            if (dailyPerformanceWidgets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No match records found in the ledger for the last 30 days.',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...dailyPerformanceWidgets,
          ],
        ],
      ),
    );
  }

  Widget _buildLegendTag(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text.replaceAll('■ ', ''),
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPieceValueTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($value)',
            style: GoogleFonts.jetBrainsMono(
              color: ScholarlyTheme.accentBlue,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
