import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scholarly_theme.dart';
import '../../application/battleground_provider.dart';
import '../../application/assignment_provider.dart';
import 'ambient_scaffold.dart';

bool hasScotomaDiagnosis({
  required double peakRate,
  required int analyzedGames,
}) {
  final affectedGames = (peakRate * analyzedGames).round();
  return analyzedGames >= 5 && peakRate >= 0.15 && affectedGames >= 2;
}

String scotomaAnalysisSummary({
  required int analyzedGames,
  required int totalRatedGames,
  required int skippedGames,
}) {
  return 'Analyzed $analyzedGames of $totalRatedGames rated Battleground games'
      '${skippedGames > 0 ? ' ($skippedGames skipped)' : ''}.';
}

class ScotomaCard extends ConsumerWidget {
  const ScotomaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bgState = ref.watch(battlegroundProvider);
    final assignmentState = ref.watch(assignmentProvider);
    final scotoma = bgState.cachedScotoma;

    if (scotoma == null || !assignmentState.isCalibrated || bgState.totalRatedGamesCount < 10) {
      final textMessage = bgState.totalRatedGamesCount < 10
          ? 'Scotoma analysis calibration in progress. Play ${10 - bgState.totalRatedGamesCount} more rated matches in Battleground to calibrate visual scotoma scanning.'
          : (bgState.recalibrationGamesRemaining > 0
              ? 'Recalibration in progress. Play ${bgState.recalibrationGamesRemaining} more rated matches to update visual scotoma scanning.'
              : 'Play your first rated arena match to initialize visual scotoma scanning.');
      return JuicyGlassCard(
        borderColor: const Color(0xFFEF4444), // Crimson border for diagnostics
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        borderRadius: 24,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.visibility_off_rounded,
                color: ScholarlyTheme.textMuted.withValues(alpha: 0.5),
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                textMessage,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final List<double> values = [
      scotoma.diagonalRetreats,
      scotoma.horizontalSwings,
      scotoma.knightForks,
      scotoma.timePanic,
      scotoma.materialGreed,
      scotoma.tunnelVision,
      scotoma.pinnedPieces,
      scotoma.kingSafety,
    ];

    final maxVal = values.reduce(math.max);
    final maxIndex = values.indexOf(maxVal);
    final hasEnoughEvidence = scotoma.analyzedGames >= 5;
    final hasDiagnosis = hasScotomaDiagnosis(
      peakRate: maxVal,
      analyzedGames: scotoma.analyzedGames,
    );

    String diagnosticTitle = 'BALANCED VISION';
    String diagnosticDesc =
        'Diagnostic scan complete. Your visual fields are balanced and show no dominant scotomata.';
    Color diagnosticColor = const Color(0xFF10B981); // Emerald

    if (!hasEnoughEvidence) {
      diagnosticTitle = 'INSUFFICIENT DIAGNOSTIC DATA';
      diagnosticDesc =
          'Play 5 Battleground games to see your raw scotoma radar chart, and complete 10 Battleground games to fully calibrate your strength and unlock daily training.';
      diagnosticColor = const Color(0xFFF59E0B);
    } else if (hasDiagnosis) {
      diagnosticColor = const Color(0xFFEF4444); // Crimson
      switch (maxIndex) {
        case 0:
          diagnosticTitle = 'DIAGONAL RETREAT BLINDNESS (DGB)';
          diagnosticDesc =
              'Your brain consistently misses long-range diagonal Bishop or Queen retreats moving back towards the home ranks.';
          break;
        case 1:
          diagnosticTitle = 'HORIZONTAL SWING BLINDNESS (HRZ)';
          diagnosticDesc =
              'Attentional gap detected in lateral Rook moves. You struggle to visualize rook sweeps shifting horizontally across files.';
          break;
        case 2:
          diagnosticTitle = 'FLANK KNIGHT BLINDNESS (KNF)';
          diagnosticDesc =
              'Visual scotoma in L-shaped trajectories. You consistently miss Knight forks originating from the A or H files.';
          break;
        case 3:
          diagnosticTitle = 'TIME PRESSURE DISTRESS (TMP)';
          diagnosticDesc =
              'Tactical vision decay. Your calculation accuracy drops by over 30% when your clock falls below 45 seconds.';
          break;
        case 4:
          diagnosticTitle = 'MATERIAL GREED BIAS (GRD)';
          diagnosticDesc =
              'Cognitive capture bias. You are attracted to capturing pieces, overlooking immediate tactical refutations.';
          break;
        case 5:
          diagnosticTitle = 'FLANK TUNNEL VISION (TNL)';
          diagnosticDesc =
              'Attentional focus error. You focus heavily on one flank of the board while the decisive blow is delivered on the other.';
          break;
        case 6:
          diagnosticTitle = 'PINNED PIECE HALLUCINATION (PIN)';
          diagnosticDesc =
              'Calculation gap in pins. You tend to move pinned pieces illegally or assume pinned opponent pieces defend critical squares.';
          break;
        case 7:
          diagnosticTitle = 'KING SAFETY BLINDNESS (KSB)';
          diagnosticDesc =
              'Defensive visual scan error. You fail to foresee mating nests or direct king checks on the back ranks.';
          break;
      }
    }

    final Widget radarChart = SizedBox(
      height: 350,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF10B981).withValues(alpha: 0.08), // Safe zone (emerald green center)
              const Color(0xFFF59E0B).withValues(alpha: 0.07), // Caution zone (amber middle)
              const Color(0xFFEF4444).withValues(alpha: 0.05), // Critical zone (crimson outer)
              Colors.transparent,
            ],
            stops: const [0.25, 0.50, 0.90, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: RadarChart(
          RadarChartData(
            titlePositionPercentageOffset: 0.15,
            dataSets: [
              // Actual dataset
              RadarDataSet(
                fillColor: const Color(0x22EF4444),
                borderColor: const Color(0xFFF87171),
                borderWidth: 2.5,
                entryRadius: 4.0,
                dataEntries: values.map((val) => RadarEntry(value: val)).toList(),
              ),
              // Dummy invisible dataset to lock scale at 0.6
              RadarDataSet(
                fillColor: Colors.transparent,
                borderColor: Colors.transparent,
                entryRadius: 0,
                dataEntries: List.generate(8, (_) => const RadarEntry(value: 0.60)),
              ),
            ],
            radarBackgroundColor: Colors.transparent,
            borderData: FlBorderData(show: false),
            radarBorderData: BorderSide(
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
              width: 1,
            ),
            getTitle: (index, angle) {
              final text = [
                'DGB',
                'HRZ',
                'KNF',
                'TMP',
                'GRD',
                'TNL',
                'PIN',
                'KSB',
              ][index];
              final isPeak = index == maxIndex && hasDiagnosis;
              final val = values[index];
              final percentText = '${(val * 100).toStringAsFixed(0)}%';
              return RadarChartTitle(
                text: '',
                angle: 0.0, // Force titles to be straight (horizontal)
                children: [
                  TextSpan(
                    text: '$text\n',
                    style: GoogleFonts.jetBrainsMono(
                      color: isPeak
                          ? const Color(0xFFEF4444)
                          : ScholarlyTheme.textPrimary,
                      fontSize: isPeak ? 13.0 : 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: percentText,
                    style: GoogleFonts.jetBrainsMono(
                      color: isPeak
                          ? const Color(0xFFEF4444)
                          : ScholarlyTheme.textMuted,
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
            tickCount: 3,
            ticksTextStyle: GoogleFonts.jetBrainsMono(
              color: ScholarlyTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 8.0,
              fontWeight: FontWeight.bold,
            ),
            gridBorderData: BorderSide(
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
        ),
      ),
    );

    final Widget diagnosticBox = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: diagnosticColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: diagnosticColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDiagnosis
                    ? Icons.warning_amber_rounded
                    : hasEnoughEvidence
                    ? Icons.check_circle_outline_rounded
                    : Icons.hourglass_top_rounded,
                color: diagnosticColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  diagnosticTitle,
                  style: GoogleFonts.outfit(
                    color: diagnosticColor,
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
            diagnosticDesc,
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textMuted,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            scotomaAnalysisSummary(
              analyzedGames: scotoma.analyzedGames,
              totalRatedGames: scotoma.totalRatedGames,
              skippedGames: scotoma.skippedGames,
            ),
            style: GoogleFonts.jetBrainsMono(
              color: ScholarlyTheme.textSubtle,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    final Widget legendSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COGNITIVE METRIC KEY',
          style: GoogleFonts.outfit(
            color: ScholarlyTheme.textSubtle,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        _buildLegendItem(
          'DGB',
          'Diagonal Retreat Blindness',
          'Consistently misses long diagonal bishop/queen retreats.',
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'HRZ',
          'Horizontal Swing Blindness',
          'Attentional gaps in rook sweeps shifting horizontally.',
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'KNF',
          'Flank Knight Blindness',
          'Fails to notice knight forks originating from side files.',
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'TMP',
          'Time Panic Distress',
          'Tactical vision and accuracy decay under 45 seconds on the clock.',
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'GRD',
          'Material Greed Bias',
          'Overlooking immediate tactical refutations to capture pieces.',
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'TNL',
          'Flank Tunnel Vision',
          'Attentional capture on one side of the board while the other is struck.',
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'PIN',
          'Pinned Piece Hallucination',
          'Moving pinned pieces illegally or assuming pinned pieces defend.',
        ),
        const SizedBox(height: 10),
        _buildLegendItem(
          'KSB',
          'King Safety Blindness',
          'Failure to foresee mating patterns or back-rank checks.',
        ),
      ],
    );

    return JuicyGlassCard(
      borderColor: const Color(0xFFEF4444),
      padding: const EdgeInsets.all(20),
      borderRadius: 28,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 560;
          if (isWide) {
            // ── Landscape / desktop: chart left | diagnostic + legend right ──
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: chart
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: radarChart,
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Divider
                  VerticalDivider(
                    color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4),
                    width: 1,
                    thickness: 1,
                  ),
                  const SizedBox(width: 24),
                  // Right: diagnostic + legend
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          diagnosticBox,
                          const SizedBox(height: 20),
                          Divider(
                            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                            height: 1,
                          ),
                          const SizedBox(height: 16),
                          legendSection,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          // ── Portrait / mobile: stacked ──
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              radarChart,
              const SizedBox(height: 20),
              diagnosticBox,
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
    );
  }

  Widget _buildLegendItem(String abbr, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            abbr,
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFFEF4444),
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
