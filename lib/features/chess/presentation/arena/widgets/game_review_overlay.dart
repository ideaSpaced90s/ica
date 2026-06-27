import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../scholarly_theme.dart';
import '../../../application/analysis_engine_controller.dart';

class GameReviewOverlay extends StatelessWidget {
  final double whiteAccuracy;
  final double blackAccuracy;
  final int whiteElo;
  final int blackElo;
  final Map<MoveClassification, int> whiteCounts;
  final Map<MoveClassification, int> blackCounts;
  final List<double> evalHistory;
  final VoidCallback onStartReview;
  final String whitePlayerName;
  final String blackPlayerName;

  const GameReviewOverlay({
    super.key,
    required this.whiteAccuracy,
    required this.blackAccuracy,
    required this.whiteElo,
    required this.blackElo,
    required this.whiteCounts,
    required this.blackCounts,
    required this.evalHistory,
    required this.onStartReview,
    required this.whitePlayerName,
    required this.blackPlayerName,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: Colors.black.withValues(alpha: 0.65),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.94),
                          Colors.white.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          'GAME REVIEW',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Stockfish Match Analysis Summary',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Accuracy Comparison
                        _buildAccuracySection(),
                        const SizedBox(height: 24),

                        // Move Classification Table
                        _buildClassificationTable(),
                        const SizedBox(height: 24),

                        // Evaluation Chart
                        if (evalHistory.isNotEmpty) ...[
                          Text(
                            'Advantage Chart (White\'s Perspective)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildEvalChart(),
                          const SizedBox(height: 28),
                        ],

                        // Start Review Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: onStartReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853), // Chess green
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0xFF00C853).withValues(alpha: 0.4),
                            ),
                            child: Text(
                              'START REVIEW',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccuracySection() {
    return Row(
      children: [
        Expanded(
          child: _buildAccuracyCard(
            whitePlayerName,
            whiteAccuracy,
            whiteElo,
            Colors.white,
            ScholarlyTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAccuracyCard(
            blackPlayerName,
            blackAccuracy,
            blackElo,
            const Color(0xFF1E293B),
            Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildAccuracyCard(String name, double accuracy, int elo, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.5),
        boxShadow: ScholarlyTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            name.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textCol.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '${accuracy.toStringAsFixed(1)}%',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: textCol,
            ),
          ),
          Text(
            'Accuracy',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: textCol.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: textCol.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Est. Elo: $elo',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: textCol,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassificationTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ScholarlyTheme.panelStroke),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 16),
          _buildClassificationRow(MoveClassification.brilliant, 'Brilliant', '!!', const Color(0xFF00BCD4)),
          _buildClassificationRow(MoveClassification.best, 'Best Move', '★', const Color(0xFF00C853)),
          _buildClassificationRow(MoveClassification.good, 'Good', '✓', const Color(0xFF4CAF50)),
          _buildClassificationRow(MoveClassification.inaccuracy, 'Inaccuracy', '?!', const Color(0xFFFFB300)),
          _buildClassificationRow(MoveClassification.mistake, 'Mistake', '?', const Color(0xFFFF6D00)),
          _buildClassificationRow(MoveClassification.blunder, 'Blunder', '??', const Color(0xFFD50000)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'WHITE',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: ScholarlyTheme.textMuted),
        ),
        Text(
          'CLASSIFICATION',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: ScholarlyTheme.textPrimary),
        ),
        Text(
          'BLACK',
          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: ScholarlyTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildClassificationRow(MoveClassification type, String name, String glyph, Color color) {
    final wCount = whiteCounts[type] ?? 0;
    final bCount = blackCounts[type] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // White Count
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$wCount',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
            ),
          ),
          // Icon and Name
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    glyph,
                    style: GoogleFonts.outfit(
                      fontSize: glyph.length > 1 ? 9 : 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          // Black Count
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$bCount',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvalChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < evalHistory.length; i++) {
      double score = evalHistory[i].clamp(-7.0, 7.0);
      spots.add(FlSpot(i.toDouble(), score));
    }

    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScholarlyTheme.panelStroke),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(
            show: true,
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 10.0,
          minY: -7.0,
          maxY: 7.0,
          lineBarsData: [
            LineChartBarData(
              spots: spots.isEmpty ? [const FlSpot(0, 0), const FlSpot(10, 0)] : spots,
              isCurved: true,
              color: ScholarlyTheme.accentBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0,
                color: Colors.grey.withValues(alpha: 0.3),
                strokeWidth: 1.5,
                dashArray: [4, 4],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
