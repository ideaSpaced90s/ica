import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../application/assignment_provider.dart';
import '../../application/battleground_provider.dart';
import '../../domain/models/assignment_state.dart';
import '../scholarly_theme.dart';
import '../widgets/ambient_scaffold.dart';
import '../widgets/island_path_painter.dart';
import '../mobile_navigation_shell.dart';

class BlueprintTabContent extends ConsumerStatefulWidget {
  final AssignmentState state;
  final BattlegroundState bgState;

  const BlueprintTabContent({
    super.key,
    required this.state,
    required this.bgState,
  });

  @override
  ConsumerState<BlueprintTabContent> createState() => _BlueprintTabContentState();
}

class _BlueprintTabContentState extends ConsumerState<BlueprintTabContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  bool _isStepsExpanded = true;
  bool _isSeasonsExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getRankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze':
        return const Color(0xFF92400E);
      case 'silver':
        return const Color(0xFF6B7280);
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'platinum':
        return const Color(0xFF0D9488);
      case 'diamond':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF6B7280);
    }
  }



  IconData _getIslandIcon(int index) {
    switch (index) {
      case 0: return Icons.person_rounded;
      case 1: return Icons.extension_rounded;
      case 2: return Icons.explore_rounded;
      case 3: return Icons.fort_rounded;
      case 4: return Icons.auto_awesome_rounded;
      case 5: return Icons.gavel_rounded;
      case 6: return Icons.workspace_premium_rounded;
      case 7: return Icons.military_tech_rounded;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bgState = widget.bgState;

    final currentElo = bgState.consolidatedRating;
    final currentLp = state.currentMonthLp;
    final rank = state.formFactorRank;
    final rankColor = _getRankColor(rank);

    // Form Factor Progress toward next rank
    int nextRankLp = 300;
    int currentRankStartLp = 0;
    if (currentLp >= 2000) {
      nextRankLp = 3000; // soft cap
      currentRankStartLp = 2000;
    } else if (currentLp >= 1200) {
      nextRankLp = 2000;
      currentRankStartLp = 1200;
    } else if (currentLp >= 700) {
      nextRankLp = 1200;
      currentRankStartLp = 700;
    } else if (currentLp >= 300) {
      nextRankLp = 700;
      currentRankStartLp = 300;
    }

    final double lpProgress = ((currentLp - currentRankStartLp) / (nextRankLp - currentRankStartLp)).clamp(0.0, 1.0);

    // Days remaining in month
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;

    // Island Dimensions
    const double verticalSpacing = 135.0;
    const double bottomPadding = 80.0;
    const double totalHeight = 8 * verticalSpacing + 120.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Form Factor Card
              JuicyGlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                backgroundColor: ScholarlyTheme.backgroundDark.withValues(alpha: 0.85),
                borderColor: rankColor.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.shield_rounded, color: rankColor, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              '⚔️ FORM FACTOR',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$daysLeft Days Left',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${rank.toUpperCase()} RANK',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: rankColor,
                          ),
                        ),
                        Text(
                          '${NumberFormat("#,###").format(currentLp)} LP',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: lpProgress,
                        minHeight: 6,
                        backgroundColor: Colors.white10,
                        color: rankColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.monthlyWins}W • ${state.monthlyDraws}D • ${state.monthlyLosses}L',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Assignments LP: +${state.monthlyAssignmentsCompleted * 15}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Island Steps Panel (Accordion)
              if (_isStepsExpanded) ...[
                _buildStepsPanel(context, state),
                const SizedBox(height: 20),
              ],

              // Seasons History Collapsible Section
              InkWell(
                onTap: () {
                  setState(() {
                    _isSeasonsExpanded = !_isSeasonsExpanded;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "FORM FACTOR SEASONS",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: ScholarlyTheme.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(
                      _isSeasonsExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: ScholarlyTheme.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_isSeasonsExpanded) ...[
                _buildSeasonsPanel(context, state),
                const SizedBox(height: 20),
              ],

              // 3. Winding Island Journey Map
              Text(
                "MAP ARCHIPELAGO",
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: ScholarlyTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              JuicyGlassCard(
                padding: EdgeInsets.zero,
                borderRadius: 24,
                child: Container(
                  height: totalHeight,
                  width: double.infinity,
                  color: Colors.blue.withValues(alpha: 0.03), // subtle sea tint
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double centerX = constraints.maxWidth / 2;
                      const double xOffset = 45.0;

                      Offset getIslandPos(int idx) {
                        final double y = totalHeight - bottomPadding - (idx * verticalSpacing);
                        final double x = centerX + ((idx % 2 == 0) ? -xOffset : xOffset);
                        return Offset(x, y);
                      }

                      return Stack(
                        children: [
                          // Path Painter behind nodes
                          Positioned.fill(
                            child: CustomPaint(
                              painter: IslandPathPainter(
                                currentIslandIndex: state.currentIslandIndex,
                                totalIslands: 8,
                                animationValue: _animationController.value,
                              ),
                            ),
                          ),
                          // 8 Island Nodes
                          for (int i = 0; i < 8; i++) _buildIslandNode(context, i, getIslandPos(i), state, currentElo),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIslandNode(
    BuildContext context,
    int index,
    Offset pos,
    AssignmentState state,
    int currentElo,
  ) {
    final bool isCompleted = index < state.currentIslandIndex;
    final bool isCurrent = index == state.currentIslandIndex;
    final bool isKingslayer = index == 7;
    final tier = islandTiers[index];
    final icon = _getIslandIcon(index);

    double nodeSize = 64.0;
    if (isCurrent) nodeSize = 74.0;
    if (isKingslayer) nodeSize = 80.0;

    return Positioned(
      left: pos.dx - (nodeSize / 2),
      top: pos.dy - (nodeSize / 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (index > state.currentIslandIndex) {
                // Locked
                _showLockedBottomSheet(context, tier);
              } else if (isCurrent) {
                // Toggle active steps panel
                setState(() {
                  _isStepsExpanded = !_isStepsExpanded;
                });
              } else {
                // Cleared
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Cleared ${tier.name} Island! focus: ${tier.scotomaFocus}."),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              width: nodeSize,
              height: nodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCompleted
                    ? const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)])
                    : isKingslayer
                        ? const LinearGradient(colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)])
                        : isCurrent
                            ? null
                            : const LinearGradient(colors: [Color(0xFFE5E7EB), Color(0xFFD1D5DB)]),
                color: isCurrent ? Colors.white : null,
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFFF59E0B)
                      : isKingslayer
                          ? const Color(0xFFF59E0B)
                          : isCurrent
                              ? const Color(0xFF0D6EFD)
                              : const Color(0xFFD1D5DB),
                  width: isCurrent ? 3.5 : 2.0,
                ),
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: const Color(0xFF0D6EFD).withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 4 * (1.0 - lpProgressRatio(pos)), // subtle pulsing shadow
                        ),
                      ]
                    : isKingslayer
                        ? [
                            BoxShadow(
                              color: const Color(0xFF7F1D1D).withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    isKingslayer && !isCurrent && !isCompleted ? Icons.lock_rounded : icon,
                    color: isCompleted
                        ? Colors.white
                        : isKingslayer
                            ? const Color(0xFFF59E0B)
                            : isCurrent
                                ? const Color(0xFF0D6EFD)
                                : const Color(0xFF9CA3AF),
                    size: isKingslayer ? 34 : 26,
                  ),
                  if (isCurrent)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D6EFD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "YOU",
                          style: GoogleFonts.outfit(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tier.name.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isCurrent
                  ? const Color(0xFF0D6EFD)
                  : index > state.currentIslandIndex
                      ? ScholarlyTheme.textMuted.withValues(alpha: 0.6)
                      : ScholarlyTheme.textPrimary,
            ),
          ),
          Text(
            index == 7 ? "2250+ ELO" : "${tier.minElo}-${tier.maxElo} ELO",
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              color: ScholarlyTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  double lpProgressRatio(Offset pos) {
    // Return animated value based on oscillation
    return (math.sin(_animationController.value * math.pi * 2) + 1.0) / 2.0;
  }

  void _showLockedBottomSheet(BuildContext context, IslandTierInfo tier) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(Icons.lock_rounded, size: 48, color: ScholarlyTheme.textMuted),
              const SizedBox(height: 16),
              Text(
                "${tier.name} Island is Locked",
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Reach ${tier.minElo} ELO in Battleground to unlock this training tier.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: ScholarlyTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Understood"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepsPanel(BuildContext context, AssignmentState state) {
    final int idx = state.currentIslandIndex;
    final tier = islandTiers[idx];
    final stepsProgress = state.islandStepProgress[idx] ?? [0, 0, 0, 0];

    final isStep1Done = stepsProgress[0] >= 15;
    final isStep2Done = stepsProgress[1] >= 3;
    final isStep3Done = stepsProgress[2] >= 2;
    final isStep4Done = stepsProgress[3] >= 2;

    // Active steps are unlocked sequentially
    final bool step2Unlocked = isStep1Done;
    final bool step3Unlocked = isStep2Done;
    final bool step4Unlocked = isStep1Done && isStep2Done && isStep3Done;

    return JuicyGlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      borderColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏝️ ${tier.name.toUpperCase()} ISLAND TRAINING',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: ScholarlyTheme.accentBlue,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Focus: ${tier.scotomaFocus}',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Step 1: Scotoma Scan
          _buildStepTile(
            title: "Step 1: Scotoma Scan",
            description: "Solve 15 scotoma puzzles on focus: '${tier.scotomaFocus}'",
            current: stepsProgress[0],
            target: 15,
            isCompleted: isStep1Done,
            isLocked: false,
            onAction: () {
              ref.read(mobileNavIndexProvider.notifier).state = 1; // Puzzles
            },
            actionLabel: "GO TO PUZZLES",
          ),
          const Divider(height: 24, color: ScholarlyTheme.panelStroke),

          // Step 2: Battle Proof
          _buildStepTile(
            title: "Step 2: Battle Proof",
            description: "Win 3 arena games on ${tier.name} tier",
            current: stepsProgress[1],
            target: 3,
            isCompleted: isStep2Done,
            isLocked: !step2Unlocked,
            onAction: () {
              ref.read(mobileNavIndexProvider.notifier).state = 2; // Battleground
            },
            actionLabel: "BATTLEGROUND",
          ),
          const Divider(height: 24, color: ScholarlyTheme.panelStroke),

          // Step 3: Cinema Study
          _buildStepTile(
            title: "Step 3: Cinema Study",
            description: "Complete 2 historical cinema games for this tier",
            current: stepsProgress[2],
            target: 2,
            isCompleted: isStep3Done,
            isLocked: !step3Unlocked,
            onAction: () {
              ref.read(mobileNavIndexProvider.notifier).state = 3; // Cinema / Academy Syllabus tab (usually Cinema tab)
            },
            actionLabel: "GO TO CINEMA",
          ),
          const Divider(height: 24, color: ScholarlyTheme.panelStroke),

          // Step 4: Academy Pass
          _buildStepTile(
            title: "Step 4: Academy Pass",
            description: "Complete the 2 academy chapters assigned: ${tier.chapterRange}",
            current: stepsProgress[3],
            target: 2,
            isCompleted: isStep4Done,
            isLocked: !step4Unlocked,
            onAction: () {
              ref.read(mobileNavIndexProvider.notifier).state = 0; // Academy tab
            },
            actionLabel: "OPEN ACADEMY",
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile({
    required String title,
    required String description,
    required int current,
    required int target,
    required bool isCompleted,
    required bool isLocked,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    final double fraction = (current / target).clamp(0.0, 1.0);

    return Opacity(
      opacity: isLocked ? 0.45 : 1.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.1)
                  : isLocked
                      ? Colors.grey.withValues(alpha: 0.1)
                      : ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : isLocked
                      ? Icons.lock_outline_rounded
                      : Icons.play_circle_outline_rounded,
              color: isCompleted
                  ? Colors.green
                  : isLocked
                      ? Colors.grey
                      : ScholarlyTheme.accentBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                if (!isCompleted && !isLocked) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 5,
                            backgroundColor: ScholarlyTheme.panelStroke,
                            color: ScholarlyTheme.accentBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$current/$target',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.accentBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (!isLocked && !isCompleted)
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(60, 24),
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(
                      actionLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.accentBlue,
                      ),
                    ),
                  ),
                if (isCompleted)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "COMPLETED",
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonsPanel(BuildContext context, AssignmentState state) {
    final history = state.seasonHistory;
    return JuicyGlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      borderColor: Colors.teal.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history_edu_rounded, color: Colors.teal, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '📜 SEASONS HISTORY',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.teal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '${history.length} Seasons',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No season data recorded yet. Your rank will archive here at the end of the month!',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: ScholarlyTheme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length,
              separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 16),
              itemBuilder: (context, index) {
                final season = history[history.length - 1 - index]; // Show newest first
                final rankColor = _getRankColor(season.rank);

                // Parse month ID like "2026-06" to friendly "June 2026"
                String displayMonth = season.monthId;
                try {
                  final parts = season.monthId.split('-');
                  if (parts.length == 2) {
                    final year = int.parse(parts[0]);
                    final month = int.parse(parts[1]);
                    final date = DateTime(year, month, 1);
                    displayMonth = DateFormat('MMMM yyyy').format(date);
                  }
                } catch (_) {}

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayMonth,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: ScholarlyTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${season.wins}W • ${season.draws}D • ${season.losses}L • ${season.assignmentsCompleted} Assignments',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                color: ScholarlyTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: rankColor.withValues(alpha: 0.4), width: 1),
                            ),
                            child: Text(
                              season.rank.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: rankColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${NumberFormat("#,###").format(season.lp)} LP',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
