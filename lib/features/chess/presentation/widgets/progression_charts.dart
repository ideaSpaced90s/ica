import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/saved_game.dart';
import '../scholarly_theme.dart';

class EloAscentChart extends StatelessWidget {
  final List<SavedGameEntry> saves;
  const EloAscentChart({super.key, required this.saves});

  @override
  Widget build(BuildContext context) {
    final ratedSaves = saves.where((s) => s.isRatedMode && s.ratingSnapshot != null).toList();
    ratedSaves.sort((a, b) => a.savedAt.compareTo(b.savedAt));

    if (ratedSaves.isEmpty) {
      return _buildEmptyState('No rating data yet. Play a rated match to see your ascent.');
    }

    final bulletSpots = _getSpots(ratedSaves, 'bullet');
    final blitzSpots = _getSpots(ratedSaves, 'blitz');
    final rapidSpots = _getSpots(ratedSaves, 'rapid');

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      decoration: ScholarlyTheme.modernDecoration(),
      child: LineChart(
        LineChartData(
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
            if (bulletSpots.isNotEmpty) _lineBarData(bulletSpots, Colors.cyanAccent),
            if (blitzSpots.isNotEmpty) _lineBarData(blitzSpots, Colors.orangeAccent),
            if (rapidSpots.isNotEmpty) _lineBarData(rapidSpots, ScholarlyTheme.accentBlue),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => ScholarlyTheme.panelBase,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()}',
                    GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getSpots(List<SavedGameEntry> saves, String category) {
    final filtered = saves.where((s) => s.ratingCategory == category).toList();
    return List.generate(filtered.length, (i) {
      final snapshot = filtered[i].ratingSnapshot;
      return FlSpot(i.toDouble(), (snapshot ?? 1200).toDouble());
    });
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

class TacticalRadarChart extends StatelessWidget {
  final List<SavedGameEntry> saves;
  const TacticalRadarChart({super.key, required this.saves});

  @override
  Widget build(BuildContext context) {
    final ratedSaves = saves.where((s) => s.isRatedMode).toList();
    if (ratedSaves.isEmpty) return const SizedBox.shrink();

    // Calculate Axes (0.0 to 1.0)
    // 1. Aggression (Dominance)
    final avgDom = ratedSaves.isNotEmpty 
      ? ratedSaves.map((s) => s.dominanceSnapshot ?? 0.0).reduce((a, b) => a + b) / ratedSaves.length
      : 0.0;
    final aggression = math.min(1.0, math.max(0.0, (avgDom + 5) / 10)); // Normalized around 0

    // 2. Power (Max Elo)
    final maxElo = ratedSaves.map((s) => s.ratingSnapshot ?? 1200).reduce(math.max);
    final power = math.min(1.0, (maxElo - 400) / 2000);

    // 3. Versatility (960 vs Classic)
    final count960 = ratedSaves.where((s) => s.gameMode == 'chess960').length;
    final versatility = count960 / ratedSaves.length;

    // 4. Intensity (Win Rate)
    final wins = ratedSaves.where((s) => s.result == 'W').length;
    final intensity = wins / ratedSaves.length;

    // 5. Speed (Time Management - placeholder for now)
    final speed = 0.7; 

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: ScholarlyTheme.modernDecoration(),
      child: RadarChart(
        RadarChartData(
          dataSets: [
            RadarDataSet(
              fillColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
              borderColor: ScholarlyTheme.accentBlue,
              entryRadius: 3,
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
          radarBorderData: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1),
          getTitle: (index, angle) {
            switch (index) {
              case 0: return RadarChartTitle(text: 'ATK', angle: angle);
              case 1: return RadarChartTitle(text: 'POW', angle: angle);
              case 2: return RadarChartTitle(text: 'VER', angle: angle);
              case 3: return RadarChartTitle(text: 'INT', angle: angle);
              case 4: return RadarChartTitle(text: 'SPD', angle: angle);
              default: return const RadarChartTitle(text: '');
            }
          },
          tickCount: 4,
          ticksTextStyle: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 8),
          gridBorderData: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1),
        ),
      ),
    );
  }
}

class ModeDistributionChart extends StatelessWidget {
  final List<SavedGameEntry> saves;
  const ModeDistributionChart({super.key, required this.saves});

  @override
  Widget build(BuildContext context) {
    final classic = saves.where((s) => s.gameMode == 'classic').length;
    final nineSixty = saves.where((s) => s.gameMode == 'chess960').length;
    final total = classic + nineSixty;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: ScholarlyTheme.modernDecoration(),
      child: PieChart(
        PieChartData(
          sectionsSpace: 6,
          centerSpaceRadius: 60,
          sections: [
            PieChartSectionData(
              color: ScholarlyTheme.accentBlue,
              value: classic.toDouble(),
              title: 'Classic\n${(classic / total * 100).toInt()}%',
              radius: 70,
              titleStyle: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            PieChartSectionData(
              color: Colors.orangeAccent,
              value: nineSixty.toDouble(),
              title: '960\n${(nineSixty / total * 100).toInt()}%',
              radius: 70,
              titleStyle: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class DominanceHeatmap extends StatelessWidget {
  final List<SavedGameEntry> saves;
  const DominanceHeatmap({super.key, required this.saves});

  @override
  Widget build(BuildContext context) {
    // Last 30 days
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    // Group by day
    final Map<String, List<double>> dailyDom = {};
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      dailyDom[dateKey] = [];
    }

    for (final s in saves) {
      if (s.savedAt.isAfter(thirtyDaysAgo)) {
        final dateKey = '${s.savedAt.year}-${s.savedAt.month}-${s.savedAt.day}';
        if (dailyDom.containsKey(dateKey) && s.dominanceSnapshot != null) {
          dailyDom[dateKey]!.add(s.dominanceSnapshot!);
        }
      }
    }

    final List<String> sortedKeys = dailyDom.keys.toList()..sort((a, b) => b.compareTo(a));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ScholarlyTheme.modernDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('COMBAT EFFICIENCY (30D)', 
            style: GoogleFonts.inter(color: ScholarlyTheme.accentBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0)
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sortedKeys.map((key) {
              final doms = dailyDom[key]!;
              final avg = doms.isEmpty ? 0.0 : doms.reduce((a, b) => a + b) / doms.length;
              
              Color color = ScholarlyTheme.panelStroke.withValues(alpha: 0.3);
              if (doms.isNotEmpty) {
                if (avg > 5) {
                  color = Colors.greenAccent;
                } else if (avg > 0) {
                  color = Colors.greenAccent.withValues(alpha: 0.5);
                } else if (avg > -5) {
                  color = Colors.orangeAccent.withValues(alpha: 0.5);
                } else {
                  color = Colors.redAccent.withValues(alpha: 0.5);
                }
              }

              return Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
