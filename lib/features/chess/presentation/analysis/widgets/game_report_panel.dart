import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/analysis_engine_controller.dart';
import '../../../application/study_lab_provider.dart';
import '../../scholarly_theme.dart';

class GameReportPanel extends ConsumerWidget {
  const GameReportPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engineState = ref.watch(analysisEngineControllerProvider);
    final studyLabState = ref.watch(studyLabProvider);

    final classifications = engineState.classifications;
    final evalHistory = engineState.evalHistory;

    // Count classifications
    var bestCount = 0;
    var goodCount = 0;
    var inaccuracyCount = 0;
    var mistakeCount = 0;
    var blunderCount = 0;

    for (final c in classifications.values) {
      switch (c) {
        case MoveClassification.best:
          bestCount++;
          break;
        case MoveClassification.good:
          goodCount++;
          break;
        case MoveClassification.inaccuracy:
          inaccuracyCount++;
          break;
        case MoveClassification.mistake:
          mistakeCount++;
          break;
        case MoveClassification.blunder:
          blunderCount++;
          break;
        default:
          break;
      }
    }

    // Convert eval history map to ordered list
    // We get the mainline node indices path in order
    final mainlinePath = _getMainlineNodeIndices(studyLabState.nodes);
    final List<double> graphScores = [];
    for (final idx in mainlinePath) {
      if (evalHistory.containsKey(idx)) {
        graphScores.add(evalHistory[idx]!);
      }
    }

    if (engineState.isAnalyzing) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: ScholarlyTheme.accentBlue),
            const SizedBox(height: 16),
            Text(
              'Running Full Game Report...',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stockfish is analyzing each position at Depth 18.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: ScholarlyTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final hasReport = classifications.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'FULL GAME REPORT',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.2,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.analytics_outlined, size: 16, color: Colors.white),
                label: Text(
                  hasReport ? 'Re-Analyze' : 'Analyze Game',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                onPressed: () {
                  ref.read(analysisEngineControllerProvider.notifier).classifyFullGame(
                        studyLabState.nodes,
                        studyLabState.startFen,
                      );
                },
              ),
            ],
          ),
          const Divider(color: ScholarlyTheme.panelStroke, height: 20),

          if (!hasReport)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No report generated yet. Tap "Analyze Game" to start.',
                  style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 13),
                ),
              ),
            )
          else ...[
            // Move breakdown row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBadge('Best', bestCount, const Color(0xFF00E676)),
                  const SizedBox(width: 8),
                  _buildStatBadge('Good', goodCount, const Color(0xFF7C4DFF)),
                  const SizedBox(width: 8),
                  _buildStatBadge('Inaccuracy', inaccuracyCount, const Color(0xFFFFEA00)),
                  const SizedBox(width: 8),
                  _buildStatBadge('Mistake', mistakeCount, const Color(0xFFFF9100)),
                  const SizedBox(width: 8),
                  _buildStatBadge('Blunder', blunderCount, const Color(0xFFFF1744)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Graph Title
            Text(
              'Evaluation Graph (White\'s Perspective)',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: ScholarlyTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Custom Painted Graph
            if (graphScores.isNotEmpty)
              Container(
                height: 120,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.panelBase,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ScholarlyTheme.panelStroke),
                ),
                child: CustomPaint(
                  painter: EvalGraphPainter(scores: graphScores),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No mainline moves found to graph.',
                  style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count.toString(),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<int> _getMainlineNodeIndices(List<StudyLabMoveNode> nodes) {
    final path = <int>[];
    if (nodes.isEmpty) return path;

    var current = nodes.where((n) => n.parentIndex == null).firstOrNull;
    while (current != null) {
      path.add(current.index);
      if (current.childIndices.isEmpty) {
        break;
      }
      final nextIdx = current.childIndices.first;
      if (nextIdx >= nodes.length) break;
      current = nodes[nextIdx];
    }
    return path;
  }
}

class EvalGraphPainter extends CustomPainter {
  final List<double> scores;

  EvalGraphPainter({required this.scores});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    final double centerY = height / 2;

    // Draw Y = 0 center line
    final centerPaint = Paint()
      ..color = ScholarlyTheme.panelStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0.0;
    while (startX < width) {
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(startX + dashWidth, centerY),
        centerPaint,
      );
      startX += dashWidth + dashSpace;
    }

    final points = <Offset>[];
    final double xStep = scores.length > 1 ? width / (scores.length - 1) : width;

    for (var i = 0; i < scores.length; i++) {
      final score = scores[i].clamp(-8.0, 8.0);
      final y = centerY - (score / 8.0) * centerY;
      final x = i * xStep;
      points.add(Offset(x, y));
    }

    // Draw line connecting points
    final linePaint = Paint()
      ..color = ScholarlyTheme.accentBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, linePaint);

    // Draw dots at each position
    if (scores.length < 40) {
      final dotPaint = Paint()
        ..color = ScholarlyTheme.accentBlue
        ..style = PaintingStyle.fill;
      for (final pt in points) {
        canvas.drawCircle(pt, 3.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant EvalGraphPainter oldDelegate) {
    return oldDelegate.scores != scores;
  }
}
