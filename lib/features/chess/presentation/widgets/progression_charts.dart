import 'dart:async';
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

class EloAscentChart extends ConsumerStatefulWidget {
  const EloAscentChart({super.key});

  @override
  ConsumerState<EloAscentChart> createState() => _EloAscentChartState();
}

class _EloAscentChartState extends ConsumerState<EloAscentChart> {
  String _selectedPeriod = 'ALL';
  List<ShowingTooltipIndicators> showingTooltipIndicators = [];
  Timer? _tooltipTimer;

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgState = ref.watch(battlegroundProvider);
    final ledger = bgState.cachedLedgerEntries;
    final ratedSaves = List<PerformanceLedgerEntry>.from(ledger);
    ratedSaves.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (ratedSaves.isEmpty) {
      return _buildEmptyState(
        'No rating data yet. Play a rated match to see your ascent.',
      );
    }

    // Filter by period
    final now = DateTime.now();
    DateTime cutoff;
    switch (_selectedPeriod) {
      case '1W':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case '1M':
        cutoff = now.subtract(const Duration(days: 30));
        break;
      case '3M':
        cutoff = now.subtract(const Duration(days: 90));
        break;
      case '6M':
        cutoff = now.subtract(const Duration(days: 180));
        break;
      case '1Y':
        cutoff = now.subtract(const Duration(days: 365));
        break;
      default:
        cutoff = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final filteredSaves = ratedSaves.where((s) => s.timestamp.isAfter(cutoff)).toList();

    if (filteredSaves.isEmpty) {
      return JuicyGlassCard(
        borderColor: const Color(0xFF06B6D4),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPeriodSelector(),
            const Spacer(),
            Center(
              child: Text(
                'No matches played in this period.',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    final bulletSpots = _getSpots(filteredSaves, 'bullet');
    final blitzSpots = _getSpots(filteredSaves, 'blitz');
    final rapidSpots = _getSpots(filteredSaves, 'rapid');

    final allSpots = [...bulletSpots, ...blitzSpots, ...rapidSpots];
    final List<DateTime> allTimestamps = filteredSaves.map((e) => e.timestamp).toList();

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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxXVal,
                minY: minYVal,
                maxY: maxYVal,
                clipData: const FlClipData.all(),
                showingTooltipIndicators: showingTooltipIndicators,
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
                        final maxLen = allTimestamps.length;
                        if (maxLen == 0) return const SizedBox.shrink();
                        final interval = math.max(1, (maxLen / 5).ceil());
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
                  handleBuiltInTouches: false,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                    if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
                      return;
                    }
                    if (event is FlTapDownEvent || event is FlPanDownEvent || event is FlPanStartEvent) {
                      _tooltipTimer?.cancel();
                      setState(() {
                        showingTooltipIndicators = [
                          ShowingTooltipIndicators(
                            response.lineBarSpots!,
                          ),
                        ];
                      });
                      _tooltipTimer = Timer(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            showingTooltipIndicators = [];
                          });
                        }
                      });
                    }
                  },
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
                        final barColor = spot.bar.color;
                        String category = 'rapid';
                        if (barColor == const Color(0xFF00F0FF)) {
                          category = 'bullet';
                        } else if (barColor == const Color(0xFFEC4899)) {
                          category = 'blitz';
                        }
                        
                        final categoryEntries = filteredSaves.where((s) => s.ratingCategory == category).toList();
                        DateTime date;
                        if (spot.x == 0) {
                          date = categoryEntries.isNotEmpty ? categoryEntries.first.timestamp.subtract(const Duration(days: 1)) : DateTime.now();
                        } else {
                          final idx = spot.x.toInt() - 1;
                          if (idx >= 0 && idx < categoryEntries.length) {
                            date = categoryEntries[idx].timestamp;
                          } else {
                            date = DateTime.now();
                          }
                        }
                        final formattedDate = DateFormat('dd/MM/yyyy').format(date);

                        return LineTooltipItem(
                          '${spot.y.toInt()} ELO\n[$formattedDate]',
                          GoogleFonts.jetBrainsMono(
                            color: spot.bar.color ?? ScholarlyTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['1W', '1M', '3M', '6M', '1Y', 'ALL'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: periods.map((p) {
        final isSelected = _selectedPeriod == p;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPeriod = p;
              showingTooltipIndicators = [];
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected 
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected 
                    ? ScholarlyTheme.accentBlue.withValues(alpha: 0.3) 
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Text(
              p,
              style: GoogleFonts.outfit(
                color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
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

  List<FlSpot> _getSpots(List<PerformanceLedgerEntry> saves, String category) {
    final filtered = saves.where((s) => s.ratingCategory == category).toList();
    if (filtered.isEmpty) return [];

    final List<FlSpot> spots = [];
    for (int i = 0; i < filtered.length; i++) {
      final snapshot = filtered[i].ratingSnapshot;
      spots.add(FlSpot(i.toDouble(), snapshot.toDouble()));
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
  final bool isMobile;
  const ModeDistributionChart({super.key, this.isMobile = false});

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

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GAME MODES',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$total MATCHES',
                style: GoogleFonts.jetBrainsMono(
                  color: ScholarlyTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (classic > 0)
                    Expanded(
                      flex: classic,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF8B5CF6), // Classic Violet
                        ),
                      ),
                    ),
                  if (nineSixty > 0)
                    Expanded(
                      flex: nineSixty,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFF59E0B), // 960 Gold
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildMiniLegend(const Color(0xFF8B5CF6), 'Classic', '$classicPct% ($classic)'),
              const SizedBox(width: 16),
              _buildMiniLegend(const Color(0xFFF59E0B), '960', '$nineSixtyPct% ($nineSixty)'),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 24,
                sections: [
                  PieChartSectionData(
                    color: const Color(0xFF8B5CF6), // Electric Violet
                    value: classic.toDouble(),
                    title: '',
                    radius: 14,
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFF59E0B), // Sunny Gold
                    value: nineSixty.toDouble(),
                    title: '',
                    radius: 14,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _buildMiniLegend(const Color(0xFF8B5CF6), 'Classic', '$classicPct%'),
            _buildMiniLegend(const Color(0xFFF59E0B), '960', '$nineSixtyPct%'),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniLegend(Color color, String label, String percentage) {
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
          '$label: ',
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          percentage,
          style: GoogleFonts.jetBrainsMono(
            color: ScholarlyTheme.textPrimary,
            fontSize: 10,
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
  late DateTime _selectedDate;

  DateTime _normalizeDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalizeDate(DateTime.now());
  }

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

  Widget _buildNavArrow({
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    final isDisabled = onTap == null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDisabled
                  ? Colors.transparent
                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDisabled
                    ? Colors.transparent
                    : ScholarlyTheme.panelStroke.withValues(alpha: 0.15),
              ),
            ),
            child: Icon(
              icon,
              color: isDisabled
                  ? ScholarlyTheme.textMuted.withValues(alpha: 0.25)
                  : ScholarlyTheme.textPrimary,
              size: 20,
            ),
          ),
        ),
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

    final today = _normalizeDate(DateTime.now());
    final selectedDate = _selectedDate;

    // Generate list of 30 days ending today
    final List<DateTime> dailyDates = List.generate(30, (index) {
      return today.subtract(Duration(days: 29 - index));
    });

    final List<double> dailyPointsList = [];
    for (final day in dailyDates) {
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

    final difference = selectedDate.difference(today).inDays;
    String formattedDayLabel;
    if (difference == 0) {
      formattedDayLabel = 'Today, ${DateFormat('MMM d').format(selectedDate)}';
    } else if (difference == -1) {
      formattedDayLabel = 'Yesterday, ${DateFormat('MMM d').format(selectedDate)}';
    } else if (difference == 1) {
      formattedDayLabel = 'Tomorrow, ${DateFormat('MMM d').format(selectedDate)}';
    } else {
      formattedDayLabel = DateFormat('EEEE, MMM d').format(selectedDate);
    }

    final dateKey = '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';
    final matches = dayMatches[dateKey] ?? [];

    final double totalPoints = matches.isEmpty
        ? 0.0
        : matches
            .map((m) {
              if (m.result == 'W') return 1.0;
              if (m.result == 'D') return 0.5;
              return 0.0;
            })
            .reduce((a, b) => a + b);

    final hasPrev = selectedDate.isAfter(today.subtract(const Duration(days: 29)));
    final hasNext = selectedDate.isBefore(today.add(const Duration(days: 1)));

    void onPrevDay() {
      if (hasPrev) {
        setState(() {
          _selectedDate = selectedDate.subtract(const Duration(days: 1));
        });
      }
    }

    void onNextDay() {
      if (hasNext) {
        setState(() {
          _selectedDate = selectedDate.add(const Duration(days: 1));
        });
      }
    }

    final detailsContent = matches.isNotEmpty
        ? LayoutBuilder(
            builder: (context, constraints) {
              Widget buildMatchRow(PerformanceLedgerEntry match) {
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
              return Column(
                children: matches.map<Widget>(buildMatchRow).toList(),
              );
            },
          )
        : Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: ScholarlyTheme.textMuted.withValues(alpha: 0.4),
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  difference == 1
                      ? 'No matches scheduled for tomorrow.'
                      : 'No rated battles on this day.',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textMuted,
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );

    final detailsWidget = Container(
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
          // Date Bar inside the container
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavArrow(
                icon: Icons.chevron_left_rounded,
                onTap: hasPrev ? onPrevDay : null,
                tooltip: 'Previous Day',
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedDayLabel,
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    if (matches.isNotEmpty)
                      Text(
                        'Score: ${totalPoints % 1 == 0 ? totalPoints.toInt() : totalPoints} / ${matches.length} matches',
                        style: GoogleFonts.jetBrainsMono(
                          color: ScholarlyTheme.accentBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      )
                    else
                      Text(
                        'No battles',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              _buildNavArrow(
                icon: Icons.chevron_right_rounded,
                onTap: hasNext ? onNextDay : null,
                tooltip: 'Next Day',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
            height: 1,
          ),
          const SizedBox(height: 12),
          detailsContent,
        ],
      ),
    );

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
                      final cellDate = dailyDates[index];
                      final isSelected = selectedDate == cellDate;
                      final tileColor = getTileColor(avg);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDate = cellDate;
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

          // Flippable Details Box
          FlippableDetailsContainer(
            selectedDate: selectedDate,
            onSwipeLeft: onNextDay,
            onSwipeRight: onPrevDay,
            child: detailsWidget,
          ),
        ],
      ),
    );
  }
}

class FlippableDetailsContainer extends StatefulWidget {
  final DateTime selectedDate;
  final Widget child;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;

  const FlippableDetailsContainer({
    super.key,
    required this.selectedDate,
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  @override
  State<FlippableDetailsContainer> createState() => _FlippableDetailsContainerState();
}

class _FlippableDetailsContainerState extends State<FlippableDetailsContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Widget? _oldChild;
  DateTime? _oldDate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _oldChild = widget.child;
    _oldDate = widget.selectedDate;
  }

  @override
  void didUpdateWidget(covariant FlippableDetailsContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate) {
      _oldChild = oldWidget.child;
      _oldDate = oldWidget.selectedDate;
      _controller.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _oldChild = widget.child;
            _oldDate = widget.selectedDate;
            _controller.value = 0.0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        // Swipe left (finger right to left) goes to next day (Tomorrow)
        if (details.primaryVelocity! < -200) {
          widget.onSwipeLeft();
        }
        // Swipe right (finger left to right) goes to previous day (Yesterday)
        else if (details.primaryVelocity! > 200) {
          widget.onSwipeRight();
        }
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final val = _animation.value;
          final isForward = _oldDate == null || widget.selectedDate.isAfter(_oldDate!);
          
          if (val == 0.0) {
            return widget.child;
          }

          final isFront = val < 0.5;
          final double angle = isFront
              ? (isForward ? -val * math.pi : val * math.pi)
              : (isForward ? (1.0 - val) * math.pi : -(1.0 - val) * math.pi);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: isFront ? (_oldChild ?? widget.child) : widget.child,
          );
        },
      ),
    );
  }
}
