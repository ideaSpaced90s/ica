import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../application/assignment_provider.dart';
import '../../domain/models/assignment_state.dart';
import '../../application/battleground_provider.dart';
import '../../application/study_lab_provider.dart';
import '../widgets/animated_check_widget.dart';
import '../mobile_navigation_shell.dart';
import '../widgets/ambient_scaffold.dart';
import '../scholarly_theme.dart';
import 'package:kingslayer_chess/src/rust/api/pgn_db.dart' as rust_pgn;
import '../../services/chess_sound_service.dart';
import '../widgets/gm_chanakya_intro_overlay.dart';
import '../../application/chess_provider.dart';

class AssignmentPage extends ConsumerStatefulWidget {
  const AssignmentPage({super.key});

  @override
  ConsumerState<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends ConsumerState<AssignmentPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showChanakyaIntro = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final bgState = ref.watch(battlegroundProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(assignmentProvider.notifier).checkInAttendance();
      }
    });

    ref.listen<int>(mobileNavIndexProvider, (previous, current) {
      if (current != 11) {
        if (!_showChanakyaIntro) {
          setState(() {
            _showChanakyaIntro = true;
          });
        }
      }
    });

    return AmbientScaffold(
      blob1Color: const Color(0xFFDBEAFE),
      blob2Color: const Color(0xFFFEF3C7),
      blob3Color: const Color(0xFFF3E8FF),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Premium Tab Bar Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: JuicyGlassCard(
                    borderRadius: 16,
                    padding: EdgeInsets.zero,
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25), width: 1.5),
                      ),
                      labelColor: ScholarlyTheme.accentBlue,
                      unselectedLabelColor: ScholarlyTheme.textMuted,
                      labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: "DESK", icon: Icon(Icons.assignment_rounded, size: 20)),
                        Tab(text: "REVIEW", icon: Icon(Icons.rate_review_rounded, size: 20)),
                        Tab(text: "BLUEPRINT", icon: Icon(Icons.architecture_rounded, size: 20)),
                      ],
                    ),
                  ),
                ),

                // Tab View Body
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildDeskTab(context, state, bgState, isMobile),
                      _buildReviewTab(context, state, isMobile),
                      _buildBlueprintTab(context, state, bgState, isMobile),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showChanakyaIntro && !state.isCalibrated)
            GMChanakyaIntroOverlay(
              pageTitle: 'ASSIGNMENTS',
              text: "Welcome to your Assignment Desk, Apprentice. I am GM Chanakya. To construct a tailored activity of daily training scenarios for you, a baseline calibration of 10 rated games is required. Complete your rated games in the Battleground so I can analyze your strength and design your personalized training program.",
              onDismiss: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                setState(() {
                  _showChanakyaIntro = false;
                });
              },
            )
          else if (state.newlyCompletedTaskIndex >= 0)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: JuicyCompletionBanner(
                task: state.dailyTasks[state.newlyCompletedTaskIndex],
                onDismiss: () {
                  ref.read(assignmentProvider.notifier).clearCompletionAnimation();
                },
              ),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 1: APPRENTICE DESK (DAILY CHECKLIST)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildDeskTab(BuildContext context, AssignmentState state, BattlegroundState bgState, bool isMobile) {
    if (isMobile) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isCalibrated) ...[
              _buildChanakyaGreeting(state),
              const SizedBox(height: 20),
            ],
            if (state.isCalibrated &&
                state.goalDeadline != null &&
                DateTime.now().isAfter(state.goalDeadline!) &&
                bgState.consolidatedRating < state.goalElo) ...[
              _buildRevisionWarningCard(state),
              const SizedBox(height: 20),
            ],
            if (state.isCalibrated) ...[
              _buildCalendarStrip(state),
              const SizedBox(height: 16),
              _buildStreakCard(state),
              const SizedBox(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TODAY'S TRAINING",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                if (state.isCalibrated)
                  TextButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text("Reset", style: GoogleFonts.inter(fontSize: 11)),
                    onPressed: () {
                      ref.read(assignmentProvider.notifier).forceResetDaily();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (!state.isCalibrated)
              _buildCalibrationCard(state, bgState)
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.dailyTasks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final task = state.dailyTasks[index];
                  return _buildTaskCard(context, task, index, state);
                },
              ),
              const SizedBox(height: 24),
              Text(
                "WEEKLY TRAINING GOAL",
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildWeeklyGoalCard(context, state),
            ],
          ],
        ),
      );
    } else {
      // Desktop Layout (screenWidth >= 900)
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (Tasks and Greetings)
            Expanded(
              flex: state.isCalibrated ? 6 : 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.isCalibrated) ...[
                    _buildChanakyaGreeting(state),
                    const SizedBox(height: 20),
                  ],
                  if (state.isCalibrated &&
                      state.goalDeadline != null &&
                      DateTime.now().isAfter(state.goalDeadline!) &&
                      bgState.consolidatedRating < state.goalElo) ...[
                    _buildRevisionWarningCard(state),
                    const SizedBox(height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TODAY'S TRAINING",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (state.isCalibrated)
                        TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: Text("Reset", style: GoogleFonts.inter(fontSize: 11)),
                          onPressed: () {
                            ref.read(assignmentProvider.notifier).forceResetDaily();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!state.isCalibrated)
                    _buildCalibrationCard(state, bgState)
                  else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.dailyTasks.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = state.dailyTasks[index];
                        return _buildTaskCard(context, task, index, state);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "WEEKLY TRAINING GOAL",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildWeeklyGoalCard(context, state),
                  ],
                ],
              ),
            ),
            if (state.isCalibrated) ...[
              const SizedBox(width: 24),
              // Right Column (Attendance Ledger & Streak Card)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendarStrip(state),
                    const SizedBox(height: 16),
                    _buildStreakCard(state),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }
  }


  Widget _buildChanakyaGreeting(AssignmentState state) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ScholarlyTheme.accentGold.withValues(alpha: 0.5), width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/persona/gm_chanakya.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "GM CHANAKYA",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: ScholarlyTheme.accentBlue,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.wisdomMessage.isNotEmpty
                      ? state.wisdomMessage
                      : "Welcome back, Apprentice. Discipline is the only armor against structural flaws. Complete your daily routine.",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: ScholarlyTheme.textPrimary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarStrip(AssignmentState state) {
    final today = DateTime.now();
    final dateList = List.generate(10, (index) => today.subtract(Duration(days: 9 - index)));

    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 10),
            child: Text(
              "ATTENDANCE LEDGER",
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dateList.map((date) {
                final dateKey = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                
                // For today: show green checkmark if all done, amber "?" if in progress,
                // never a red cross (the day isn't finished yet).
                // For past days: read from the persistent history log.
                bool? pastCompleted;
                bool todayAllDone = false;
                if (isToday) {
                  todayAllDone = state.dailyTasks.isNotEmpty && state.dailyTasks.every((t) => t.isCompleted);
                } else {
                  pastCompleted = state.historyLog[dateKey];
                }

                Widget icon;
                if (isToday) {
                  if (todayAllDone) {
                    icon = const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18);
                  } else {
                    // Day is still live — show a pending "?" in amber
                    icon = const Icon(Icons.help_outline_rounded, color: Colors.amber, size: 18);
                  }
                } else if (pastCompleted == true) {
                  icon = const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18);
                } else if (pastCompleted == false) {
                  icon = const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 18);
                } else {
                  // Future date or no record — empty circle
                  icon = Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: ScholarlyTheme.textSubtle, width: 2),
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isToday ? ScholarlyTheme.accentBlue.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25), width: 1)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isToday ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      icon,
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationCard(AssignmentState state, BattlegroundState bgState) {
    final currentGamesCount = state.calibrationGamesPlayed;
    final progress = currentGamesCount / 10.0;
    return JuicyGlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.query_stats_rounded, color: ScholarlyTheme.realGold, size: 28),
              const SizedBox(width: 12),
              Text(
                "CALIBRATION",
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "GM Chanakya requires a baseline of 10 rated games to identify your ELO strength, playstyle biases, and cognitive scotomas. Play rated games to unlock tailored assignments.",
            style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: ScholarlyTheme.textMuted),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Calibration Progress",
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
              ),
              Text(
                "$currentGamesCount / 10 Games",
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: ScholarlyTheme.panelStroke,
              color: ScholarlyTheme.accentBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, DailyTask task, int index, AssignmentState state) {
    IconData icon = Icons.assignment_rounded;
    Color color = Colors.blue;
    switch (task.taskType) {
      case DailyTaskType.attendance:
        icon = Icons.how_to_reg_rounded;
        color = const Color(0xFF10B981);
        break;
      case DailyTaskType.arena:
        icon = Icons.sports_esports_rounded;
        color = Colors.cyan;
        break;
      case DailyTaskType.puzzle:
        icon = Icons.extension_rounded;
        color = ScholarlyTheme.realGold;
        break;
      case DailyTaskType.tutorial:
        icon = Icons.menu_book_rounded;
        color = Colors.purpleAccent;
        break;
      case DailyTaskType.historicalArchive:
        icon = Icons.history_edu_rounded;
        color = ScholarlyTheme.accentGold;
        break;
    }

    final bool justCompleted = state.newlyCompletedTaskIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        border: task.isCompleted
            ? Border.all(color: Colors.green.withValues(alpha: 0.3), width: 1.5)
            : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: JuicyGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted),
                  ),
                  if (!task.isCompleted) _buildHintChip(task),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedCheckWidget(
              isCompleted: task.isCompleted,
              animate: justCompleted,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintChip(DailyTask task) {
    String text = "";
    switch (task.taskType) {
      case DailyTaskType.attendance:
        text = "Completed automatically upon entering the Assignment Desk.";
        break;
      case DailyTaskType.arena:
        text = "Go to Arena tab — win recorded automatically";
        break;
      case DailyTaskType.puzzle:
        text = "Go to Puzzles tab — solve 3 puzzles on target axis";
        break;
      case DailyTaskType.tutorial:
        text = "Go to Academy — complete the prescribed chapter";
        break;
      case DailyTaskType.historicalArchive:
        text = "Go to Academy → Historical Cinema — watch at least 5 moves";
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            color: ScholarlyTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildRevisionWarningCard(AssignmentState state) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      borderColor: Colors.redAccent.withValues(alpha: 0.3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "GOAL DEADLINE EXPIRED",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your target deadline has passed, but your ELO remains below the goal of ${state.goalElo}. GM Chanakya has set you onto a basic moves revision routine.",
                  style: GoogleFonts.inter(
                     fontSize: 12,
                     height: 1.4,
                     color: ScholarlyTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // ────────────────────────────────────────────────────────────────────────────
  // TAB 3: WEEKLY REVIEW (COACH SUBMISSIONS)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildReviewTab(BuildContext context, AssignmentState state, bool isMobile) {
    if (!state.isCalibrated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.query_stats_rounded, color: ScholarlyTheme.textMuted, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Weekly review unlocks after strength calibration is completed.",
                textAlign: TextAlign.center,
                style: TextStyle(color: ScholarlyTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          JuicyGlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.rate_review_rounded, color: ScholarlyTheme.accentBlue, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      "WEEKLY MASTER REVIEW",
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Annotate a defeated game from your archive in the Analysis page (add comments/marks), and save it. Submit it here to GM Chanakya for structural diagnostics.",
                  style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: ScholarlyTheme.textMuted),
                ),
                const SizedBox(height: 16),
                if (!state.weeklyReviewSubmitted)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: ScholarlyTheme.accentBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text("Submit Game from Library", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      onPressed: () => _showGameSubmissionSelector(context),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Game Submitted for Review This Week",
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Generated Report Display
          if (state.weeklyReport != null) ...[
            Text(
              "CHANAKYA'S ASSESSMENT REPORT",
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: ScholarlyTheme.textMuted, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            JuicyGlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: SelectableText(
                state.weeklyReport!,
                style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: ScholarlyTheme.textPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showGameSubmissionSelector(BuildContext context) async {
    final studyNotifier = ref.read(studyLabProvider.notifier);
    final records = await studyNotifier.loadGamesFromLibrary();

    if (!context.mounted) return;

    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No saved games in your Library! Go to Analysis mode to annotate and save a game."),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: ScholarlyTheme.panelBase,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Select Annotated Game to Submit",
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
                ),
              ),
              const Divider(color: ScholarlyTheme.panelStroke),
              Expanded(
                child: ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (context, index) => const Divider(color: ScholarlyTheme.panelStroke, height: 1),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return ListTile(
                      leading: const Icon(Icons.history_edu_rounded, color: ScholarlyTheme.realGold),
                      title: Text(
                        record.header.event,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
                      ),
                      subtitle: Text(
                        "ECO: ${record.header.eco} | Result: ${record.header.result}",
                        style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Assemble PGN content with annotations
                        final pgn = rust_pgn.exportPgnWithHeaders(
                          header: record.header,
                          annotatedPgn: record.movesPgn,
                        );
                        ref.read(assignmentProvider.notifier).submitGameForReview(
                          record.header.event,
                          pgn,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 4: BLUEPRINT (TARGET & PATH)
  // ────────────────────────────────────────────────────────────────────────────
  Widget _buildBlueprintTab(BuildContext context, AssignmentState state, BattlegroundState bgState, bool isMobile) {
    if (!state.isCalibrated) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.architecture_rounded, color: ScholarlyTheme.textMuted, size: 48),
              SizedBox(height: 16),
              Text(
                "Blueprint unlocks after calibration is completed.",
                style: TextStyle(color: ScholarlyTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final currentElo = bgState.consolidatedRating;
    final targetElo = state.goalElo;
    final startElo = state.startElo;

    // Calculate progress fraction
    double progress = 0.0;
    if (targetElo > startElo) {
      progress = (currentElo - startElo) / (targetElo - startElo);
    }

    // Days remaining
    final daysRemaining = state.goalDeadline != null
        ? state.goalDeadline!.difference(DateTime.now()).inDays
        : 30;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Goal Progress Display Card
          JuicyGlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "MONTHLY ASSIGNMENT TARGET",
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: ScholarlyTheme.accentBlue, letterSpacing: 0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.realGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$daysRemaining Days Left",
                        style: GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.bold, color: ScholarlyTheme.realGold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEloStatColumn("STARTING ELO", startElo.toString(), Colors.grey),
                    const Icon(Icons.arrow_forward_rounded, color: ScholarlyTheme.textSubtle, size: 24),
                    _buildEloStatColumn("CURRENT ELO", currentElo.toString(), ScholarlyTheme.accentBlue),
                    const Icon(Icons.arrow_forward_rounded, color: ScholarlyTheme.textSubtle, size: 24),
                    _buildEloStatColumn("TARGET ELO", targetElo.toString(), Colors.green),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Target Progress",
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
                    ),
                    Text(
                      "${(progress * 100).toStringAsFixed(0)}%",
                      style: GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: FontWeight.bold, color: ScholarlyTheme.accentBlue),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: ScholarlyTheme.panelStroke,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Custom Goal Builder
          Text(
            "GOAL BUILDER",
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: ScholarlyTheme.textMuted, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          JuicyGlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Adjust Monthly Blueprint Goal",
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  "Choose a monthly ELO target rating and date to complete your training routine blueprint.",
                  style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTargetOptionButton(context, currentElo + 100),
                    _buildTargetOptionButton(context, currentElo + 200),
                    _buildTargetOptionButton(context, currentElo + 300),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: ScholarlyTheme.panelStroke),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Target Date:",
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_month_rounded, size: 18, color: ScholarlyTheme.accentBlue),
                      label: Text(
                        state.goalDeadline != null
                            ? DateFormat.yMMMd().format(state.goalDeadline!)
                            : "Select Date",
                        style: GoogleFonts.jetBrainsMono(fontSize: 13, fontWeight: FontWeight.bold, color: ScholarlyTheme.accentBlue),
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: state.goalDeadline ?? DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now().subtract(const Duration(days: 30)), // allow selecting slightly past date to test revision mode
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: ScholarlyTheme.accentBlue,
                                  onPrimary: Colors.white,
                                  onSurface: ScholarlyTheme.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          ref.read(assignmentProvider.notifier).setupGoalDeadline(picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEloStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: ScholarlyTheme.textMuted),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildTargetOptionButton(BuildContext context, int target) {
    final state = ref.watch(assignmentProvider);
    final isSelected = state.goalElo == target;

    return Expanded(
      child: Padding(
        key: ValueKey(target),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? ScholarlyTheme.accentBlue.withValues(alpha: 0.1) : Colors.transparent,
            side: BorderSide(
              color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
              width: isSelected ? 1.5 : 1,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () {
            ref.read(assignmentProvider.notifier).setupGoal(target);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Goal ELO updated to $target!"), backgroundColor: Colors.green),
            );
          },
          child: Text(
            "$target ELO",
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyGoalCard(BuildContext context, AssignmentState state) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_rounded, color: ScholarlyTheme.accentBlue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ATTEND ACADEMIC CLASS",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Submit an annotated game from your Library for GM Chanakya's Weekly Master Review.",
                  style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted),
                ),
                if (!state.weeklyReviewSubmitted)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "Go to Review tab to submit your annotated game",
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                          color: ScholarlyTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedCheckWidget(
            isCompleted: state.weeklyReviewSubmitted,
            animate: false,
            size: 30,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(AssignmentState state) {
    int streak = _calculateStreak(state);

    return JuicyGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.orangeAccent,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "CURRENT DAILY STREAK",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: ScholarlyTheme.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$streak ${streak == 1 ? 'Day' : 'Days'}",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  streak > 0 
                      ? "Keep the fire burning, Apprentice!"
                      : "Start your streak today!",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _calculateStreak(AssignmentState state) {
    int streak = 0;
    final today = DateTime.now();
    final todayCompleted = state.dailyTasks.isNotEmpty && state.dailyTasks.every((t) => t.isCompleted);

    DateTime checkDate;
    if (todayCompleted) {
      streak = 1;
      checkDate = today.subtract(const Duration(days: 1));
    } else {
      checkDate = today.subtract(const Duration(days: 1));
    }

    while (true) {
      final key = "${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}";
      if (state.historyLog[key] == true) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}

class JuicyCompletionBanner extends StatefulWidget {
  final DailyTask task;
  final VoidCallback onDismiss;

  const JuicyCompletionBanner({
    super.key,
    required this.task,
    required this.onDismiss,
  });

  @override
  State<JuicyCompletionBanner> createState() => _JuicyCompletionBannerState();
}

class _JuicyCompletionBannerState extends State<JuicyCompletionBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _offsetAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();

    _dismissTimer = Timer(const Duration(milliseconds: 2900), () {
      if (mounted) {
        _slideController.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  String _getChanakyaQuote(DailyTaskType type) {
    switch (type) {
      case DailyTaskType.attendance:
        return "Punctuality and presence are the first steps to master-level discipline.";
      case DailyTaskType.arena:
        return "Combat experience is the forge of all theory.";
      case DailyTaskType.puzzle:
        return "Each tactical pattern burned into memory is a weapon forged.";
      case DailyTaskType.tutorial:
        return "Knowledge built layer by layer — this is how champions are made.";
      case DailyTaskType.historicalArchive:
        return "You have studied the masters. Now let their wisdom flow through your play.";
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = _getChanakyaQuote(widget.task.taskType);

    return SlideTransition(
      position: _offsetAnimation,
      child: JuicyGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        borderRadius: 20,
        borderColor: Colors.green.withValues(alpha: 0.4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "TASK COMPLETED!",
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.greenAccent,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.task.title.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"$quote"',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
