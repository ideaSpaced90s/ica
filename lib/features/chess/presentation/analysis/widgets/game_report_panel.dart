import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/analysis_engine_controller.dart';
import '../../../application/study_lab_provider.dart';
import '../../scholarly_theme.dart';

class GameReportPanel extends ConsumerStatefulWidget {
  const GameReportPanel({super.key});

  @override
  ConsumerState<GameReportPanel> createState() => _GameReportPanelState();
}

class _GameReportPanelState extends ConsumerState<GameReportPanel> {
  int? _selectedIdx;

  bool _isWhiteMove(String fen) {
    final parts = fen.split(' ');
    if (parts.length > 1) {
      return parts[1] == 'w';
    }
    return true; // default
  }

  int _getMoveNumberFromFen(String fen) {
    final parts = fen.split(' ');
    if (parts.length >= 6) {
      return int.tryParse(parts[5]) ?? 1;
    }
    return 1;
  }

  String _formatScore(double score) {
    if (score >= 90.0) {
      return 'M+';
    } else if (score <= -90.0) {
      return 'M-';
    } else {
      final sign = score >= 0 ? '+' : '';
      return '$sign${score.toStringAsFixed(2)}';
    }
  }


  @override
  Widget build(BuildContext context) {
    final engineState = ref.watch(analysisEngineControllerProvider);
    final studyLabState = ref.watch(studyLabProvider);

    final classifications = engineState.classifications;
    final evalHistory = engineState.evalHistory;

    // Count classifications for White and Black
    var whiteBestCount = 0;
    var whiteGoodCount = 0;
    var whiteInaccuracyCount = 0;
    var whiteMistakeCount = 0;
    var whiteBlunderCount = 0;

    var blackBestCount = 0;
    var blackGoodCount = 0;
    var blackInaccuracyCount = 0;
    var blackMistakeCount = 0;
    var blackBlunderCount = 0;

    for (final entry in classifications.entries) {
      final nodeIdx = entry.key;
      final c = entry.value;
      if (nodeIdx >= studyLabState.nodes.length) continue;
      final node = studyLabState.nodes[nodeIdx];
      
      final fenBefore = node.parentIndex == null
          ? studyLabState.startFen
          : studyLabState.nodes[node.parentIndex!].fen;
      
      final isWhiteMove = _isWhiteMove(fenBefore);

      if (isWhiteMove) {
        switch (c) {
          case MoveClassification.best:
            whiteBestCount++;
            break;
          case MoveClassification.good:
            whiteGoodCount++;
            break;
          case MoveClassification.inaccuracy:
            whiteInaccuracyCount++;
            break;
          case MoveClassification.mistake:
            whiteMistakeCount++;
            break;
          case MoveClassification.blunder:
            whiteBlunderCount++;
            break;
          default:
            break;
        }
      } else {
        switch (c) {
          case MoveClassification.best:
            blackBestCount++;
            break;
          case MoveClassification.good:
            blackGoodCount++;
            break;
          case MoveClassification.inaccuracy:
            blackInaccuracyCount++;
            break;
          case MoveClassification.mistake:
            blackMistakeCount++;
            break;
          case MoveClassification.blunder:
            blackBlunderCount++;
            break;
          default:
            break;
        }
      }
    }

    // Convert eval history map to ordered list
    final mainlinePath = _getMainlineNodeIndices(studyLabState.nodes);
    final List<double> graphScores = [];
    final List<StudyLabMoveNode> graphNodes = [];
    for (final idx in mainlinePath) {
      if (evalHistory.containsKey(idx)) {
        graphScores.add(evalHistory[idx]!);
        graphNodes.add(studyLabState.nodes[idx]);
      }
    }

    if (_selectedIdx != null && _selectedIdx! >= graphScores.length) {
      _selectedIdx = null;
    }

    if (engineState.isAnalyzing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: ModernLoader(),
        ),
      );
    }

    final hasReport = classifications.isNotEmpty;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasReport)
            Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.65,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.analytics_outlined,
                        size: 48,
                        color: ScholarlyTheme.accentBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Ready to Analyze',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'Get a move-by-move accuracy report and a comprehensive evaluation graph powered by Stockfish.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScholarlyTheme.accentBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.flash_on_rounded, size: 20, color: Colors.white),
                      label: Text(
                        'Analyze Game',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        if (studyLabState.nodes.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Kindly load a game or play some moves on the board first.',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        } else {
                          ref.read(analysisEngineControllerProvider.notifier).classifyFullGame(
                                studyLabState.nodes,
                                studyLabState.startFen,
                              );
                        }
                      },
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Accuracy Grid Header
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
              child: Text(
                'Move Classification Comparison',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
            ),

            // Comparison grid cells
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatGridCell('Best', whiteBestCount, blackBestCount, const Color(0xFF00E676))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatGridCell('Good', whiteGoodCount, blackGoodCount, const Color(0xFF7C4DFF))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildStatGridCell('Inaccuracy', whiteInaccuracyCount, blackInaccuracyCount, const Color(0xFFFFEA00))),
                    const SizedBox(width: 10),
                    Expanded(child: _buildStatGridCell('Mistake', whiteMistakeCount, blackMistakeCount, const Color(0xFFFF9100))),
                  ],
                ),
                const SizedBox(height: 10),
                _buildStatGridCell('Blunder', whiteBlunderCount, blackBlunderCount, const Color(0xFFFF1744)),
              ],
            ),
            const SizedBox(height: 24),

            // Graph Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Evaluation Graph',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                Text(
                  'White (+) / Black (-)',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Selected Move Detail Card
            if (_selectedIdx != null && _selectedIdx! < graphNodes.length) ...[
              _buildSelectedMoveCard(
                graphNodes[_selectedIdx!],
                graphScores[_selectedIdx!],
                classifications[graphNodes[_selectedIdx!].index] ?? MoveClassification.none,
              ),
              const SizedBox(height: 12),
            ],

            // Custom Painted Graph
            if (graphScores.isNotEmpty) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  const paddingLeft = 35.0;
                  final graphWidth = width - paddingLeft;
                  final xStep = graphScores.length > 1
                      ? graphWidth / (graphScores.length - 1)
                      : graphWidth;

                  void handleTouch(Offset localPos) {
                    if (graphScores.isEmpty) return;
                    final double xInGraph = (localPos.dx - paddingLeft).clamp(0.0, graphWidth);
                    final int index = (xInGraph / xStep).round().clamp(0, graphScores.length - 1);
                    if (_selectedIdx != index) {
                      setState(() {
                        _selectedIdx = index;
                      });
                    }
                  }

                  return GestureDetector(
                    onTapDown: (details) => handleTouch(details.localPosition),
                    onPanUpdate: (details) => handleTouch(details.localPosition),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.panelBase,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ScholarlyTheme.panelStroke),
                      ),
                      child: CustomPaint(
                        painter: EvalGraphPainter(
                          scores: graphScores,
                          selectedIdx: _selectedIdx,
                          paddingLeft: paddingLeft,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Tip: Tap or drag on the graph to inspect specific moves.',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No mainline moves found to graph.',
                  style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
                ),
              ),
            const SizedBox(height: 28),

            // Move Analysis Log Section
            Text(
              'Move Analysis Log',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: ScholarlyTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: ScholarlyTheme.panelBase,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ScholarlyTheme.panelStroke),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: graphNodes.length,
                separatorBuilder: (context, index) => const Divider(
                  color: ScholarlyTheme.panelStroke,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final node = graphNodes[index];
                  final score = graphScores[index];
                  final classification = classifications[node.index] ?? MoveClassification.none;
                  return _buildLogItem(node, score, classification);
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildStatGridCell(
    String label,
    int whiteCount,
    int blackCount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
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
                label.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WHITE',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
                  Text(
                    whiteCount.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'BLACK',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
                  Text(
                    blackCount.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMoveCard(
    StudyLabMoveNode node,
    double score,
    MoveClassification classification,
  ) {
    final isWhite = _isWhiteMove(node.parentIndex == null
        ? ref.read(studyLabProvider).startFen
        : ref.read(studyLabProvider).nodes[node.parentIndex!].fen);
    
    final moveNumber = _getMoveNumberFromFen(node.fen);
    final moveLabel = isWhite ? '$moveNumber. ${node.san}' : '${moveNumber - 1}... ${node.san}';
    final playerLabel = isWhite ? 'White' : 'Black';
    
    Color classColor = Colors.grey;
    String classLabel = 'None';
    IconData classIcon = Icons.help_outline;

    switch (classification) {
      case MoveClassification.brilliant:
        classColor = const Color(0xFF00B0FF);
        classLabel = 'Brilliant';
        classIcon = Icons.star_purple500_rounded;
        break;
      case MoveClassification.best:
        classColor = const Color(0xFF00E676);
        classLabel = 'Best Move';
        classIcon = Icons.check_circle_rounded;
        break;
      case MoveClassification.good:
        classColor = const Color(0xFF7C4DFF);
        classLabel = 'Good Move';
        classIcon = Icons.thumb_up_rounded;
        break;
      case MoveClassification.inaccuracy:
        classColor = const Color(0xFFFFEA00);
        classLabel = 'Inaccuracy';
        classIcon = Icons.warning_amber_rounded;
        break;
      case MoveClassification.mistake:
        classColor = const Color(0xFFFF9100);
        classLabel = 'Mistake';
        classIcon = Icons.error_outline_rounded;
        break;
      case MoveClassification.blunder:
        classColor = const Color(0xFFFF1744);
        classLabel = 'Blunder';
        classIcon = Icons.dangerous_rounded;
        break;
      default:
        classColor = ScholarlyTheme.textMuted;
        classLabel = 'Book / Normal';
        classIcon = Icons.bookmark_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: classColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: classColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isWhite ? Colors.white : Colors.black87,
              shape: BoxShape.circle,
              border: Border.all(color: ScholarlyTheme.panelStroke, width: 1),
            ),
            child: Icon(
              isWhite ? Icons.circle_outlined : Icons.circle,
              size: 18,
              color: isWhite ? Colors.black87 : Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      moveLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '($playerLabel)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ScholarlyTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(classIcon, color: classColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      classLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: classColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'EVAL',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                _formatScore(score),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: score >= 0 ? ScholarlyTheme.accentBlue : Colors.redAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(
    StudyLabMoveNode node,
    double score,
    MoveClassification classification,
  ) {
    final isWhite = _isWhiteMove(node.parentIndex == null
        ? ref.read(studyLabProvider).startFen
        : ref.read(studyLabProvider).nodes[node.parentIndex!].fen);
    
    final moveNumber = _getMoveNumberFromFen(node.fen);
    final moveLabel = isWhite ? '$moveNumber. ${node.san}' : '${moveNumber - 1}... ${node.san}';
    
    String coordText = '';
    if (node.uci.length >= 4) {
      final fromSquare = node.uci.substring(0, 2);
      final toSquare = node.uci.substring(2, 4);
      coordText = '$fromSquare ➔ $toSquare';
    }

    Color classColor = Colors.grey;
    String classLabel = '';
    IconData classIcon = Icons.help_outline;

    switch (classification) {
      case MoveClassification.brilliant:
        classColor = const Color(0xFF00B0FF);
        classLabel = 'Brilliant';
        classIcon = Icons.star_purple500_rounded;
        break;
      case MoveClassification.best:
        classColor = const Color(0xFF00E676);
        classLabel = 'Best';
        classIcon = Icons.check_circle_rounded;
        break;
      case MoveClassification.good:
        classColor = const Color(0xFF7C4DFF);
        classLabel = 'Good';
        classIcon = Icons.thumb_up_rounded;
        break;
      case MoveClassification.inaccuracy:
        classColor = const Color(0xFFFFEA00);
        classLabel = 'Inaccuracy';
        classIcon = Icons.warning_amber_rounded;
        break;
      case MoveClassification.mistake:
        classColor = const Color(0xFFFF9100);
        classLabel = 'Mistake';
        classIcon = Icons.error_outline_rounded;
        break;
      case MoveClassification.blunder:
        classColor = const Color(0xFFFF1744);
        classLabel = 'Blunder';
        classIcon = Icons.dangerous_rounded;
        break;
      default:
        classColor = ScholarlyTheme.textSubtle;
        classLabel = 'Book/Normal';
        classIcon = Icons.bookmark_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: classColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moveLabel,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                if (coordText.isNotEmpty)
                  Text(
                    coordText,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(classIcon, color: classColor, size: 14),
                const SizedBox(width: 4),
                Text(
                  classLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: classColor,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatScore(score),
              textAlign: TextAlign.end,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: score >= 0 ? ScholarlyTheme.accentBlue : Colors.redAccent,
              ),
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
  final int? selectedIdx;
  final double paddingLeft;

  EvalGraphPainter({
    required this.scores,
    this.selectedIdx,
    required this.paddingLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double centerY = height / 2;
    final double graphWidth = width - paddingLeft;

    final gridPaint = Paint()
      ..color = ScholarlyTheme.panelStroke.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final centerPaint = Paint()
      ..color = ScholarlyTheme.panelStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    void drawGridLineAndLabel(double score, String label, {bool isCenter = false}) {
      final double scoreClamp = score.clamp(-8.0, 8.0);
      final double y = centerY - (scoreClamp / 8.0) * centerY;

      textPainter.text = TextSpan(
        text: label,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: ScholarlyTheme.textSubtle,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );

      if (isCenter) {
        const dashWidth = 5.0;
        const dashSpace = 3.0;
        double startX = paddingLeft;
        while (startX < width) {
          canvas.drawLine(
            Offset(startX, y),
            Offset(startX + dashWidth, y),
            centerPaint,
          );
          startX += dashWidth + dashSpace;
        }
      } else {
        canvas.drawLine(
          Offset(paddingLeft, y),
          Offset(width, y),
          gridPaint,
        );
      }
    }

    drawGridLineAndLabel(6.0, '+6.0');
    drawGridLineAndLabel(3.0, '+3.0');
    drawGridLineAndLabel(0.0, '0.0', isCenter: true);
    drawGridLineAndLabel(-3.0, '-3.0');
    drawGridLineAndLabel(-6.0, '-6.0');

    if (scores.isEmpty) return;

    final points = <Offset>[];
    final double xStep = scores.length > 1 ? graphWidth / (scores.length - 1) : graphWidth;

    for (var i = 0; i < scores.length; i++) {
      final score = scores[i].clamp(-8.0, 8.0);
      final y = centerY - (score / 8.0) * centerY;
      final x = paddingLeft + (i * xStep);
      points.add(Offset(x, y));
    }

    final fillPath = Path();
    fillPath.moveTo(points.first.dx, centerY);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(points.last.dx, centerY);
    fillPath.close();

    // White Advantage Fill (top half)
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(paddingLeft, 0, width, centerY));
    final whiteFillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
          ScholarlyTheme.accentBlue.withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(paddingLeft, 0, width, centerY))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, whiteFillPaint);
    canvas.restore();

    // Black Advantage Fill (bottom half)
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(paddingLeft, centerY, width, height));
    final blackFillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0F172A).withValues(alpha: 0.02),
          const Color(0xFF0F172A).withValues(alpha: 0.35),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(paddingLeft, centerY, width, height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, blackFillPaint);
    canvas.restore();

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

    if (scores.length < 50) {
      final dotPaint = Paint()
        ..color = ScholarlyTheme.accentBlue
        ..style = PaintingStyle.fill;
      for (final pt in points) {
        canvas.drawCircle(pt, 2.5, dotPaint);
      }
    }

    if (selectedIdx != null && selectedIdx! < points.length) {
      final selPt = points[selectedIdx!];

      final indicatorPaint = Paint()
        ..color = ScholarlyTheme.accentBlue.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawLine(
        Offset(selPt.dx, 0),
        Offset(selPt.dx, height),
        indicatorPaint,
      );

      final glowPaint = Paint()
        ..color = ScholarlyTheme.accentBlue.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selPt, 7.0, glowPaint);

      final solidDotPaint = Paint()
        ..color = ScholarlyTheme.accentBlue
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selPt, 4.0, solidDotPaint);

      final innerWhiteDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selPt, 1.5, innerWhiteDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant EvalGraphPainter oldDelegate) {
    return oldDelegate.scores != scores || oldDelegate.selectedIdx != selectedIdx;
  }
}

class ModernLoader extends StatefulWidget {
  const ModernLoader({super.key});

  @override
  State<ModernLoader> createState() => _ModernLoaderState();
}

class _ModernLoaderState extends State<ModernLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glowing pulse ring
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.06),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Rotating indicator
              RotationTransition(
                turns: _rotateAnimation,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: ScholarlyTheme.accentBlue,
                    backgroundColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                  ),
                ),
              ),
              // Trophy/Insight icon in the center
              const Icon(
                Icons.insights_rounded,
                color: ScholarlyTheme.accentBlue,
                size: 24,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Analyzing...',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: ScholarlyTheme.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
