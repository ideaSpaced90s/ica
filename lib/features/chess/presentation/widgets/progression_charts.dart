import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../scholarly_theme.dart';
import '../../application/battleground_provider.dart';
import '../../domain/performance_ledger_entry.dart';
import 'ambient_scaffold.dart';

class EloAscentChart extends ConsumerWidget {
  const EloAscentChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgState = ref.watch(battlegroundProvider);
    final ledger = bgState.cachedLedgerEntries;
    final ratedSaves = List<PerformanceLedgerEntry>.from(ledger);
    ratedSaves.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (ratedSaves.isEmpty) {
      return _buildEmptyState(
        'No rating data yet. Play a rated match to see your ascent.',
      );
    }

    final bulletSpots = _getSpots(ratedSaves, 'bullet');
    final blitzSpots = _getSpots(ratedSaves, 'blitz');
    final rapidSpots = _getSpots(ratedSaves, 'rapid');

    final allSpots = [...bulletSpots, ...blitzSpots, ...rapidSpots];
    // Build a timestamp index for all rated games (sorted by timestamp)
    // Used to map X-axis index → date label
    final List<DateTime> allTimestamps = ratedSaves.map((e) => e.timestamp).toList();

    double minYVal = 200.0;
    double maxYVal = 700.0;
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
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    // Show at most 5 date labels at equally spaced intervals
                    final maxLen = allTimestamps.length;
                    if (maxLen == 0) return const SizedBox.shrink();
                    final interval = math.max(1, (maxLen / 5).ceil());
                    // Only show label at index 0 or multiples of interval
                    if (idx < 0 || idx >= maxLen) return const SizedBox.shrink();
                    if (idx != 0 && idx % interval != 0) return const SizedBox.shrink();
                    final date = allTimestamps[idx];
                    final label = DateFormat('MMM d').format(date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        label,
                        style: GoogleFonts.jetBrainsMono(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 9,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: GoogleFonts.jetBrainsMono(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  reservedSize: 35,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              if (bulletSpots.isNotEmpty)
                _lineBarData(
                  bulletSpots,
                  const Color(0xFF00F0FF),
                ), // Electric Neon Cyan
              if (blitzSpots.isNotEmpty)
                _lineBarData(
                  blitzSpots,
                  const Color(0xFFEC4899),
                ), // Electric Neon Hot Pink
              if (rapidSpots.isNotEmpty)
                _lineBarData(
                  rapidSpots,
                  const Color(0xFF10B981),
                ), // Electric Neon Emerald
            ],
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              getTouchedSpotIndicator:
                  (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: (barData.color ?? Colors.blue).withValues(
                            alpha: 0.5,
                          ),
                          strokeWidth: 2,
                          dashArray: [4, 4],
                        ),
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
    spots.add(const FlSpot(0, 400));

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
        child: Text(
          msg,
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textMuted,
            fontSize: 12,
          ),
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
    final bgState = ref.watch(battlegroundProvider);
    final playstyle = bgState.cachedPlaystyle;
    if (playstyle == null) return const SizedBox.shrink();

    final aggression = playstyle.aggression;
    final power = playstyle.power;
    final versatility = playstyle.versatility;
    final intensity = playstyle.intensity;
    final speed = playstyle.speed;

    // Determine the archetype based on highest value
    final axes = [
      (
        aggression,
        'Aggressive Attacker',
        'You consistently maintain high dominance on the board, pushing active threats.',
        const Color(0xFFEF4444),
      ),
      (
        power,
        'High-Power Veteran',
        'Your rating profile shows seasoned, high-caliber positional strength.',
        const Color(0xFFF59E0B),
      ),
      (
        versatility,
        'Universalist',
        'You are highly versatile, regularly transitioning between Chess960 and Classic formats.',
        const Color(0xFF8B5CF6),
      ),
      (
        intensity,
        'Relentless Competitor',
        'Your profile highlights a high conversion and win rate in battles.',
        const Color(0xFF10B981),
      ),
      (
        speed,
        'Speed Demon',
        'You manage your clock exceptionally well, keeping a healthy time advantage.',
        const Color(0xFF06B6D4),
      ),
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
      archetypeDesc =
          'Your playstyle profile is stabilizing as you log more rated matches.';
      archetypeColor = const Color(0xFF8B5CF6);
    }

    final Widget radarChart = SizedBox(
      height: 350,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF8B5CF6).withValues(alpha: 0.08), // Violet core glow
              const Color(0xFF8B5CF6).withValues(alpha: 0.03),
              Colors.transparent,
            ],
            stops: const [0.35, 0.75, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: RadarChart(
          RadarChartData(
            titlePositionPercentageOffset: 0.15,
            dataSets: [
              // 1. Reference baseline dataset
              RadarDataSet(
                fillColor: Colors.transparent,
                borderColor: ScholarlyTheme.textSubtle.withValues(alpha: 0.45),
                borderWidth: 1.5,
                entryRadius: 0,
                dataEntries: const [
                  RadarEntry(value: 0.50), // ATK Aggression
                  RadarEntry(value: 0.45), // POW Power
                  RadarEntry(value: 0.35), // VER Versatility
                  RadarEntry(value: 0.55), // INT Intensity
                  RadarEntry(value: 0.60), // SPD Speed
                ],
              ),
              // 2. Actual dataset
              RadarDataSet(
                fillColor: const Color(0x28A855F7),
                borderColor: const Color(0xFFC084FC),
                borderWidth: 2.5,
                entryRadius: 4.5,
                dataEntries: [
                  RadarEntry(value: aggression),
                  RadarEntry(value: power),
                  RadarEntry(value: versatility),
                  RadarEntry(value: intensity),
                  RadarEntry(value: speed),
                ],
              ),
              // 3. Dummy invisible dataset to lock scale at 1.0
              RadarDataSet(
                fillColor: Colors.transparent,
                borderColor: Colors.transparent,
                entryRadius: 0,
                dataEntries: List.generate(5, (_) => const RadarEntry(value: 1.0)),
              ),
            ],
            radarBackgroundColor: Colors.transparent,
            borderData: FlBorderData(show: false),
            radarBorderData: const BorderSide(color: Color(0xFFF3E8FF), width: 1),
            getTitle: (index, angle) {
              final text = ['ATK', 'POW', 'VER', 'INT', 'SPD'][index];
              final color = [
                const Color(0xFFEF4444),
                const Color(0xFFF59E0B),
                const Color(0xFF8B5CF6),
                const Color(0xFF10B981),
                const Color(0xFF06B6D4),
              ][index];
              final val = [aggression, power, versatility, intensity, speed][index];
              final percentText = '${(val * 100).toStringAsFixed(0)}%';
              return RadarChartTitle(
                text: '',
                angle: 0.0, // Force titles to be straight (horizontal)
                children: [
                  TextSpan(
                    text: '$text\n',
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: percentText,
                    style: GoogleFonts.jetBrainsMono(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
            tickCount: 4,
            ticksTextStyle: GoogleFonts.jetBrainsMono(
              color: ScholarlyTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
            ),
            gridBorderData: const BorderSide(color: Color(0xFFF3E8FF), width: 1),
          ),
        ),
      ),
    );

    final Widget archetypeBox = Container(
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
              Icon(Icons.lens_blur_rounded, color: archetypeColor, size: 16),
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
    );

    final Widget legendSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _buildLegendItem(
          'ATK',
          'Aggression (Attack)',
          'Measures your average material and territory dominance over opponents.',
          const Color(0xFFEF4444),
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'POW',
          'Power rating',
          'Scaled from your peak ELO rating achieved in rated battles.',
          const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'VER',
          'Versatility Index',
          'Ratio of Chess960 variants played compared to Classic chess matches.',
          const Color(0xFF8B5CF6),
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'INT',
          'Intensity (Win Rate)',
          'Win rate percentage calculated over all active rated matches.',
          const Color(0xFF10B981),
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'SPD',
          'Time Speed Management',
          'Average ratio of remaining clock time upon match completion.',
          const Color(0xFF06B6D4),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 32,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ScholarlyTheme.textSubtle.withValues(alpha: 0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '---',
                style: TextStyle(
                  color: ScholarlyTheme.textSubtle.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Typical Master Target (Baseline)',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return JuicyGlassCard(
      borderColor: const Color(0xFF8B5CF6),
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 560;

            // Header shared
            final header = Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'PLAYSTYLE PROFILE',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8B5CF6),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            );

            if (isWide) {
              // ── Landscape / desktop: chart left | archetype + legend right ──
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: radar chart
                        Expanded(flex: 5, child: radarChart),
                        const SizedBox(width: 24),
                        VerticalDivider(
                          color: ScholarlyTheme.panelStroke.withValues(
                            alpha: 0.4,
                          ),
                          width: 1,
                          thickness: 1,
                        ),
                        const SizedBox(width: 24),
                        // Right: archetype box + legend
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              archetypeBox,
                              const SizedBox(height: 20),
                              Divider(
                                color: ScholarlyTheme.panelStroke.withValues(
                                  alpha: 0.5,
                                ),
                                height: 1,
                              ),
                              const SizedBox(height: 16),
                              legendSection,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            // ── Portrait / mobile: stacked ──
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                radarChart,
                const SizedBox(height: 20),
                archetypeBox,
                const SizedBox(height: 20),
                Divider(
                  color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                  height: 1,
                ),
                const SizedBox(height: 16),
                legendSection,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    String abbr,
    String title,
    String desc,
    Color badgeColor,
  ) {
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
    final bgState = ref.watch(battlegroundProvider);
    final ledger = bgState.cachedLedgerEntries;
    final classic = ledger.where((s) => s.gameMode == 'classic').length;
    final nineSixty = ledger.where((s) => s.gameMode == 'chess960').length;
    final total = classic + nineSixty;

    if (total == 0) {
      return Center(
        child: Text(
          'No rated matches played yet.',
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textMuted,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final classicPct = total > 0 ? (classic / total * 100).toInt() : 0;
    final nineSixtyPct = total > 0 ? (nineSixty / total * 100).toInt() : 0;

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 26,
              sections: [
                PieChartSectionData(
                  color: const Color(0xFF8B5CF6), // Electric Violet
                  value: classic.toDouble(),
                  title: '',
                  radius: 18,
                ),
                PieChartSectionData(
                  color: const Color(0xFFF59E0B), // Sunny Gold
                  value: nineSixty.toDouble(),
                  title: '',
                  radius: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(const Color(0xFF8B5CF6), 'Classic', '$classicPct%'),
            const SizedBox(width: 12),
            _buildLegendItem(const Color(0xFFF59E0B), '960', '$nineSixtyPct%'),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String percentage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textPrimary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          percentage,
          style: GoogleFonts.jetBrainsMono(
            color: ScholarlyTheme.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class DominanceHeatmap extends ConsumerStatefulWidget {
  const DominanceHeatmap({super.key});

  @override
  ConsumerState<DominanceHeatmap> createState() => _DominanceHeatmapState();
}

class _DominanceHeatmapState extends ConsumerState<DominanceHeatmap> {
  int? _selectedTileIndex;

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgState = ref.watch(battlegroundProvider);
    final ledgerEntries = bgState.cachedLedgerEntries;

    // Heatmap color logic helper (Match Points based)
    Color getTileColor(double avg) {
      if (avg.isNaN) {
        return ScholarlyTheme.panelStroke.withValues(alpha: 0.3);
      }
      if (avg > 0.5) {
        return const Color(0xFF10B981); // Neon Emerald Green (Win / Advantage)
      } else if (avg == 0.5) {
        return const Color(0xFF06B6D4); // Electric Cyan (Draws / Equal)
      } else if (avg > 0.0) {
        return const Color(0xFFF59E0B); // Hot Amber (Mixed / Disadvantage)
      } else {
        return const Color(0xFFEF4444); // Deep Crimson (Losses)
      }
    }

    // Grouping ledger entries by day
    final Map<String, List<PerformanceLedgerEntry>> dayMatches = {};
    for (final entry in ledgerEntries) {
      final dateKey =
          '${entry.timestamp.year}-${entry.timestamp.month}-${entry.timestamp.day}';
      dayMatches.putIfAbsent(dateKey, () => []).add(entry);
    }

    final now = DateTime.now();
    final List<double> dailyPointsList = [];
    for (int i = 29; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dateKey = '${day.year}-${day.month}-${day.day}';
      final matches = dayMatches[dateKey];
      if (matches == null || matches.isEmpty) {
        dailyPointsList.add(double.nan);
      } else {
        final totalPoints = matches
            .map((m) {
              if (m.result == 'W') return 1.0;
              if (m.result == 'D') return 0.5;
              return 0.0;
            })
            .reduce((a, b) => a + b);
        final avgPoints = totalPoints / matches.length;
        dailyPointsList.add(avgPoints);
      }
    }

    // Default to the most recent active day if not selected yet
    int? selectedIdx = _selectedTileIndex;
    if (selectedIdx == null && dailyPointsList.isNotEmpty) {
      for (int i = dailyPointsList.length - 1; i >= 0; i--) {
        if (!dailyPointsList[i].isNaN) {
          selectedIdx = i;
          break;
        }
      }
    }

    Widget detailsWidget;
    if (selectedIdx != null) {
      final selectedDate = now.subtract(Duration(days: 29 - selectedIdx));
      final dateKey =
          '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
      final matches = dayMatches[dateKey] ?? [];

      final formattedDayLabel = (29 - selectedIdx) == 0
          ? 'Today, ${DateFormat('MMM d').format(selectedDate)}'
          : (29 - selectedIdx) == 1
          ? 'Yesterday, ${DateFormat('MMM d').format(selectedDate)}'
          : DateFormat('EEEE, MMM d').format(selectedDate);

      if (matches.isNotEmpty) {
        final totalPoints = matches
            .map((m) {
              if (m.result == 'W') return 1.0;
              if (m.result == 'D') return 0.5;
              return 0.0;
            })
            .reduce((a, b) => a + b);

        detailsWidget = Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: ScholarlyTheme.panelBase.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      formattedDayLabel,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ScholarlyTheme.accentBlue.withValues(
                          alpha: 0.15,
                        ),
                      ),
                    ),
                    child: Text(
                      'Score: ${totalPoints % 1 == 0 ? totalPoints.toInt() : totalPoints} / ${matches.length}',
                      style: GoogleFonts.jetBrainsMono(
                        color: ScholarlyTheme.accentBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Match grid — 2 cols on desktop, 1 col on mobile
              LayoutBuilder(
                builder: (context, constraints) {
                  Widget buildMatchRow(match) {
                    final matchTime = DateFormat('jm').format(match.timestamp);
                    final modeLabel =
                        '${match.ratingCategory.toUpperCase()} ${match.gameMode == 'chess960' ? '960' : 'Classic'}';

                    Color outcomeColor;
                    String resultText;
                    if (match.result == 'W') {
                      outcomeColor = const Color(0xFF10B981);
                      resultText = 'W';
                    } else if (match.result == 'L') {
                      outcomeColor = const Color(0xFFEF4444);
                      resultText = 'L';
                    } else {
                      outcomeColor = const Color(0xFF64748B);
                      resultText = 'D';
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: outcomeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: outcomeColor.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              resultText,
                              style: GoogleFonts.jetBrainsMono(
                                color: outcomeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'vs ${match.opponentName}',
                                  style: GoogleFonts.inter(
                                    color: ScholarlyTheme.textPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$matchTime • $modeLabel',
                                  style: GoogleFonts.inter(
                                    color: ScholarlyTheme.textMuted,
                                    fontSize: 9.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${match.ratingSnapshot} ELO',
                            style: GoogleFonts.jetBrainsMono(
                              color: ScholarlyTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final isWide = constraints.maxWidth > 600;
                  if (isWide) {
                    // Two-column grid via Wrap
                    final colWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 0,
                      children: matches
                          .map<Widget>(
                            (match) => SizedBox(
                              width: colWidth,
                              child: buildMatchRow(match),
                            ),
                          )
                          .toList(),
                    );
                  }
                  // Single column
                  return Column(
                    children: matches.map<Widget>(buildMatchRow).toList(),
                  );
                },
              ),
            ],
          ),
        );
      } else {
        detailsWidget = Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ScholarlyTheme.panelBase.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: ScholarlyTheme.textMuted.withValues(alpha: 0.4),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                'No rated battles on this day.',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      }
    } else {
      detailsWidget = Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ScholarlyTheme.panelBase.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              color: ScholarlyTheme.textMuted.withValues(alpha: 0.4),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              'No matches played in the last 30 days.',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textMuted,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final double gridWidth = (24.0 * 30) + (5.0 * 29);

    return JuicyGlassCard(
      borderColor: const Color(0xFF10B981),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: gridWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 30 Days in a Single Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(30, (index) {
                      final avg = dailyPointsList[index];
                      final isSelected = selectedIdx == index;
                      final tileColor = getTileColor(avg);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTileIndex = index;
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: tileColor,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: isSelected
                                  ? ScholarlyTheme.accentBlue
                                  : ScholarlyTheme.panelStroke.withValues(
                                      alpha: 0.15,
                                    ),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (avg.isNaN
                                              ? ScholarlyTheme.accentBlue
                                              : tileColor)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),

                  // Timeline Labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '30 days ago',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Today',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: 10),

          // Single-line Legend
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'No Play',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Loss',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                children: [
                  _buildLegendDot(const Color(0xFFEF4444)),
                  const SizedBox(width: 2),
                  _buildLegendDot(const Color(0xFFF59E0B)),
                  const SizedBox(width: 2),
                  _buildLegendDot(const Color(0xFF06B6D4)),
                  const SizedBox(width: 2),
                  _buildLegendDot(const Color(0xFF10B981)),
                ],
              ),
              const SizedBox(width: 6),
              Text(
                'Win',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Daily details
          detailsWidget,
        ],
      ),
    );
  }
}
