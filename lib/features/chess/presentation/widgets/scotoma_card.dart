import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scholarly_theme.dart';
import '../../application/chess_provider.dart';
import 'ambient_scaffold.dart';

class ScotomaCard extends ConsumerWidget {
  const ScotomaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final scotoma = state.cachedScotoma;

    if (scotoma == null) {
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
                'Play your first rated arena match to initialize visual scotoma scanning.',
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

    final values = [
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

    String diagnosticTitle = 'BALANCED VISION';
    String diagnosticDesc = 'Diagnostic scan complete. Your visual fields are balanced and show no dominant scotomata.';
    Color diagnosticColor = const Color(0xFF10B981); // Emerald

    if (maxVal > 0.3) {
      diagnosticColor = const Color(0xFFEF4444); // Crimson
      switch (maxIndex) {
        case 0:
          diagnosticTitle = 'DIAGONAL RETREAT BLINDNESS (DGB)';
          diagnosticDesc = 'Your brain consistently misses long-range diagonal Bishop or Queen retreats moving back towards the home ranks.';
          break;
        case 1:
          diagnosticTitle = 'HORIZONTAL SWING BLINDNESS (HRZ)';
          diagnosticDesc = 'Attentional gap detected in lateral Rook moves. You struggle to visualize rook sweeps shifting horizontally across files.';
          break;
        case 2:
          diagnosticTitle = 'FLANK KNIGHT BLINDNESS (KNF)';
          diagnosticDesc = 'Visual scotoma in L-shaped trajectories. You consistently miss Knight forks originating from the A or H files.';
          break;
        case 3:
          diagnosticTitle = 'TIME PRESSURE DISTRESS (TMP)';
          diagnosticDesc = 'Tactical vision decay. Your calculation accuracy drops by over 30% when your clock falls below 45 seconds.';
          break;
        case 4:
          diagnosticTitle = 'MATERIAL GREED BIAS (GRD)';
          diagnosticDesc = 'Cognitive capture bias. You are attracted to capturing pieces, overlooking immediate tactical refutations.';
          break;
        case 5:
          diagnosticTitle = 'FLANK TUNNEL VISION (TNL)';
          diagnosticDesc = 'Attentional focus error. You focus heavily on one flank of the board while the decisive blow is delivered on the other.';
          break;
        case 6:
          diagnosticTitle = 'PINNED PIECE HALLUCINATION (PIN)';
          diagnosticDesc = 'Calculation gap in pins. You tend to move pinned pieces illegally or assume pinned opponent pieces defend critical squares.';
          break;
        case 7:
          diagnosticTitle = 'KING SAFETY BLINDNESS (KSB)';
          diagnosticDesc = 'Defensive visual scan error. You fail to foresee mating nests or direct king checks on the back ranks.';
          break;
      }
    }

    return JuicyGlassCard(
      borderColor: const Color(0xFFEF4444), // Vibrant crimson diagnostic border
      padding: const EdgeInsets.all(20),
      borderRadius: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // 8-Axis Radar Chart
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  RadarDataSet(
                    fillColor: const Color(0x22EF4444), // Translucent Crimson
                    borderColor: const Color(0xFFF87171), // Crimson stroke
                    entryRadius: 3.5,
                    dataEntries: values.map((val) => RadarEntry(value: val)).toList(),
                  ),
                ],
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5), width: 1),
                getTitle: (index, angle) {
                  final text = ['DGB', 'HRZ', 'KNF', 'TMP', 'GRD', 'TNL', 'PIN', 'KSB'][index];
                  final isPeak = index == maxIndex && maxVal > 0.3;
                  return RadarChartTitle(
                    text: '',
                    angle: angle,
                    children: [
                      TextSpan(
                        text: text,
                        style: GoogleFonts.jetBrainsMono(
                          color: isPeak ? const Color(0xFFEF4444) : ScholarlyTheme.textSubtle,
                          fontSize: isPeak ? 10.5 : 9,
                          fontWeight: isPeak ? FontWeight.w900 : FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
                tickCount: 3,
                ticksTextStyle: GoogleFonts.jetBrainsMono(
                  color: ScholarlyTheme.textMuted.withValues(alpha: 0.4),
                  fontSize: 8,
                ),
                gridBorderData: BorderSide(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3), width: 1),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Diagnostic Summary Box
          Container(
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
                      maxVal > 0.3 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
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
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5), height: 1),
          const SizedBox(height: 16),
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
          _buildLegendItem('DGB', 'Diagonal Retreat Blindness', 'Consistently misses long diagonal bishop/queen retreats.'),
          const SizedBox(height: 10),
          _buildLegendItem('HRZ', 'Horizontal Swing Blindness', 'Attentional gaps in rook sweeps shifting horizontally.'),
          const SizedBox(height: 10),
          _buildLegendItem('KNF', 'Flank Knight Blindness', 'Fails to notice knight forks originating from side files.'),
          const SizedBox(height: 10),
          _buildLegendItem('TMP', 'Time Panic Distress', 'Tactical vision and accuracy decay under 45 seconds on the clock.'),
          const SizedBox(height: 10),
          _buildLegendItem('GRD', 'Material Greed Bias', 'Overlooking immediate tactical refutations to capture pieces.'),
          const SizedBox(height: 10),
          _buildLegendItem('TNL', 'Flank Tunnel Vision', 'Attentional capture on one side of the board while the other is struck.'),
          const SizedBox(height: 10),
          _buildLegendItem('PIN', 'Pinned Piece Hallucination', 'Moving pinned pieces illegally or assuming pinned pieces defend.'),
          const SizedBox(height: 10),
          _buildLegendItem('KSB', 'King Safety Blindness', 'Failure to foresee mating patterns or back-rank checks.'),
        ],
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
