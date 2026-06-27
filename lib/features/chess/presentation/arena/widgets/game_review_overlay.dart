import 'dart:math' as math;
import 'dart:ui';
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
  final List<String> recentMoves;
  final Map<int, MoveClassification> reviewClassifications;

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
    required this.recentMoves,
    required this.reviewClassifications,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.94),
                          Colors.white.withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Engine Match Analysis Summary',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Accuracy Comparison
                        _buildAccuracySection(),
                        const SizedBox(height: 10),

                        // Move Classification Table
                        _buildClassificationTable(),
                        const SizedBox(height: 10),

                        // Evaluation Chart
                        if (evalHistory.isNotEmpty) ...[
                          Text(
                            'Advantage Chart (White\'s Perspective)',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildEvalChart(),
                          const SizedBox(height: 10),
                        ],

                        // Start Review Button
                        SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: onStartReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C853), // Chess green
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              shadowColor: const Color(0xFF00C853).withValues(alpha: 0.3),
                            ),
                            child: Text(
                              'START REVIEW',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
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
        const SizedBox(width: 10),
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
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.0),
        boxShadow: ScholarlyTheme.cardShadow,
      ),
      child: Column(
        children: [
          Text(
            name.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: textCol.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${accuracy.toStringAsFixed(1)}%',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: textCol,
            ),
          ),
          Text(
            'Accuracy',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: textCol.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: textCol.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Est. Elo: $elo',
              style: GoogleFonts.outfit(
                fontSize: 9,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScholarlyTheme.panelStroke),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          const Divider(height: 6, thickness: 0.8),
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
          style: GoogleFonts.outfit(fontSize: 8.5, fontWeight: FontWeight.w900, color: ScholarlyTheme.textMuted),
        ),
        Text(
          'CLASSIFICATION',
          style: GoogleFonts.outfit(fontSize: 8.5, fontWeight: FontWeight.w900, color: ScholarlyTheme.textPrimary),
        ),
        Text(
          'BLACK',
          style: GoogleFonts.outfit(fontSize: 8.5, fontWeight: FontWeight.w900, color: ScholarlyTheme.textMuted),
        ),
      ],
    );
  }

  Widget _buildClassificationRow(MoveClassification type, String name, String glyph, Color color) {
    final wCount = whiteCounts[type] ?? 0;
    final bCount = blackCounts[type] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          // White Count
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$wCount',
                style: GoogleFonts.outfit(
                  fontSize: 11,
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
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.0),
                ),
                child: Center(
                  child: Text(
                    glyph,
                    style: GoogleFonts.outfit(
                      fontSize: glyph.length > 1 ? 6.5 : 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 65,
                child: Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 10,
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
                  fontSize: 11,
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
    if (evalHistory.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double columnWidth = 44.0;
        final int moveCount = evalHistory.length;
        
        // Calculate total width of the graph content.
        // If it fits within the card, stretch columns to fill the space.
        // If it exceeds, use fixed column width and let it scroll.
        final double contentWidth = math.max(
          constraints.maxWidth,
          moveCount * columnWidth + 24.0,
        );
        
        final double actualColWidth = moveCount > 0 
            ? (contentWidth - 24.0) / moveCount 
            : columnWidth;

        return Container(
          height: 130,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Slate 900 for dark contrast
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              child: Stack(
                children: [
                  // 1. The CustomPaint Graph (drawn behind everything)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: CustomPaint(
                        painter: ChessEvalChartPainter(
                          evalHistory: evalHistory,
                          classifications: reviewClassifications,
                        ),
                      ),
                    ),
                  ),
                  
                  // 2. The Interactive/Informational columns
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: List.generate(moveCount, (index) {
                        final moveText = recentMoves.length > index ? recentMoves[index] : '';
                        final isWhite = index % 2 == 0;
                        final moveNum = (index ~/ 2) + 1;
                        final displayLabel = isWhite ? '$moveNum. $moveText' : '$moveNum... $moveText';
                        
                        final classification = reviewClassifications[index] ?? MoveClassification.none;
                        final hasBadge = classification != MoveClassification.none;
                        
                        final score = evalHistory[index];
                        String scoreText = '';
                        if (score >= 90.0) {
                          scoreText = 'M';
                        } else if (score <= -90.0) {
                          scoreText = '-M';
                        } else {
                          scoreText = (score >= 0 ? '+' : '') + score.toStringAsFixed(1);
                        }

                        return SizedBox(
                          width: actualColWidth,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top: Move Label Pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isWhite 
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: isWhite 
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  displayLabel,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                    color: isWhite ? Colors.white : Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),

                              // Classification Badge (just above graph area)
                              SizedBox(
                                height: 12,
                                child: hasBadge
                                    ? _buildClassificationBadge(classification)
                                    : const SizedBox.shrink(),
                              ),

                              // Spacer matching the graph height area
                              const SizedBox(height: 60),

                              // Evaluation value text
                              Text(
                                scoreText,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.65),
                                ),
                              ),

                              // Side circle (Who made the move)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isWhite ? Colors.white : Colors.black,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isWhite ? Colors.transparent : Colors.white38,
                                    width: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

  Widget _buildClassificationBadge(MoveClassification classification) {
    String glyph = '';
    Color color = Colors.grey;
    switch (classification) {
      case MoveClassification.brilliant:
        glyph = '!!';
        color = const Color(0xFF00BCD4);
        break;
      case MoveClassification.best:
        glyph = '★';
        color = const Color(0xFF00C853);
        break;
      case MoveClassification.good:
        glyph = '✓';
        color = const Color(0xFF4CAF50);
        break;
      case MoveClassification.inaccuracy:
        glyph = '?!';
        color = const Color(0xFFFFB300);
        break;
      case MoveClassification.mistake:
        glyph = '?';
        color = const Color(0xFFFF6D00);
        break;
      case MoveClassification.blunder:
        glyph = '??';
        color = const Color(0xFFD50000);
        break;
      case MoveClassification.none:
        return const SizedBox.shrink();
    }

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 0.5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          glyph,
          style: GoogleFonts.outfit(
            fontSize: glyph.length > 1 ? 6.0 : 8.0,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class ChessEvalChartPainter extends CustomPainter {
  final List<double> evalHistory;
  final Map<int, MoveClassification> classifications;
  final double maxEval;

  ChessEvalChartPainter({
    required this.evalHistory,
    required this.classifications,
    this.maxEval = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (evalHistory.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    final double centerY = height / 2;

    // Draw reference grid lines (dashed or faint solid)
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.8;

    // Zero baseline
    final zeroPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), zeroPaint);

    // +3.0 and -3.0 lines
    final double yPlus3 = centerY - (3.0 / maxEval) * (height / 2 * 0.85);
    final double yMinus3 = centerY + (3.0 / maxEval) * (height / 2 * 0.85);
    canvas.drawLine(Offset(0, yPlus3), Offset(width, yPlus3), gridPaint);
    canvas.drawLine(Offset(0, yMinus3), Offset(width, yMinus3), gridPaint);

    final int totalMoves = evalHistory.length;
    final double columnWidth = width / totalMoves;
    final double barWidth = 5.0;

    // First, draw the faint tracks and the active bars
    for (int i = 0; i < totalMoves; i++) {
      final double score = evalHistory[i].clamp(-maxEval, maxEval);
      final double x = i * columnWidth + columnWidth / 2;
      final double y = centerY - (score / maxEval) * (centerY * 0.85);

      // Draw faint track from bottom to top
      final trackPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.03)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - barWidth / 2, 4, x + barWidth / 2, height - 4),
          const Radius.circular(3),
        ),
        trackPaint,
      );

      // Get color for move classification
      final classification = classifications[i] ?? MoveClassification.none;
      final Color barColor = _getClassificationColor(classification);

      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      // Draw active bar from centerY to y
      double top = score >= 0 ? y : centerY;
      double bottom = score >= 0 ? centerY : y;

      // Ensure a minimum height for visibility if eval is exactly 0
      if ((bottom - top).abs() < 2.0) {
        if (score >= 0) {
          top = centerY - 1.5;
        } else {
          bottom = centerY + 1.5;
        }
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(x - barWidth / 2, top, x + barWidth / 2, bottom),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }

    // Now, draw the evaluation curve
    final curvePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85) // Glowing neon cyan
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < totalMoves; i++) {
      final double score = evalHistory[i].clamp(-maxEval, maxEval);
      final double x = i * columnWidth + columnWidth / 2;
      final double y = centerY - (score / maxEval) * (centerY * 0.85);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        // Draw smooth bezier curve
        final prevScore = evalHistory[i - 1].clamp(-maxEval, maxEval);
        final prevX = (i - 1) * columnWidth + columnWidth / 2;
        final prevY = centerY - (prevScore / maxEval) * (centerY * 0.85);
        
        final controlX1 = prevX + columnWidth / 2;
        final controlY1 = prevY;
        final controlX2 = x - columnWidth / 2;
        final controlY2 = y;
        
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }
    canvas.drawPath(path, curvePaint);

    // Draw little dots on the curve for each point
    final dotPaint = Paint()
      ..style = PaintingStyle.fill;
    for (int i = 0; i < totalMoves; i++) {
      final double score = evalHistory[i].clamp(-maxEval, maxEval);
      final double x = i * columnWidth + columnWidth / 2;
      final double y = centerY - (score / maxEval) * (centerY * 0.85);

      final classification = classifications[i] ?? MoveClassification.none;
      dotPaint.color = _getClassificationColor(classification);

      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);
      canvas.drawCircle(Offset(x, y), 1.2, Paint()..color = Colors.white);
    }
  }

  Color _getClassificationColor(MoveClassification classification) {
    switch (classification) {
      case MoveClassification.brilliant:
        return const Color(0xFF00BCD4); // Cyan
      case MoveClassification.best:
        return const Color(0xFF00C853); // Green
      case MoveClassification.good:
        return const Color(0xFF4CAF50); // Light Green
      case MoveClassification.inaccuracy:
        return const Color(0xFFFFB300); // Amber
      case MoveClassification.mistake:
        return const Color(0xFFFF6D00); // Orange
      case MoveClassification.blunder:
        return const Color(0xFFD50000); // Red
      case MoveClassification.none:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  @override
  bool shouldRepaint(covariant ChessEvalChartPainter oldDelegate) {
    return oldDelegate.evalHistory != evalHistory ||
        oldDelegate.classifications != classifications ||
        oldDelegate.maxEval != maxEval;
  }
}
