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
import '../../services/chess_sound_service.dart';
import '../widgets/gm_chanakya_intro_overlay.dart';
import 'blueprint_tab_content.dart';
import '../widgets/landfall_overlay.dart';
import '../../application/chess_provider.dart';

import 'dart:ui';
import '../../application/onboarding_provider.dart';
import '../../application/historical_cinema_provider.dart';
import '../../application/tutorial_provider.dart';
import '../academy/historical_cinema_page.dart';
import '../../application/store_provider.dart';
import '../widgets/premium_nudge_overlay.dart';

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
            _buildCelebrationOverlay(context, state.dailyTasks[state.newlyCompletedTaskIndex]),
          if (state.landfallPendingIndex != null)
            LandfallOverlay(islandIndex: state.landfallPendingIndex!),
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
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.isCalibrated) ...[
                  _buildChanakyaGreeting(state),
                  const SizedBox(height: 20),
                  _buildCalendarStrip(state),
                  const SizedBox(height: 24),
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
                        fontSize: 18,
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
                  const SizedBox(height: 28),
                  Text(
                    "WEEKLY TRAINING GOAL",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
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
    final dateList = List.generate(7, (index) => today.subtract(Duration(days: 6 - index)));

    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              "ATTENDANCE LEDGER",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.textMuted,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  icon = const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22);
                } else {
                  // Day is still live — show a pending "?" in amber
                  icon = const Icon(Icons.help_outline_rounded, color: Colors.amber, size: 22);
                }
              } else if (pastCompleted == true) {
                icon = const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22);
              } else if (pastCompleted == false) {
                icon = const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 22);
              } else {
                // Future date or no record — empty circle
                icon = Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ScholarlyTheme.textSubtle, width: 2),
                  ),
                );
              }

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isToday
                        ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday ? ScholarlyTheme.accentBlue : Colors.transparent,
                      width: isToday ? 2.0 : 1.0,
                    ),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('E').format(date).toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                          color: isToday ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isToday ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      icon,
                    ],
                  ),
                ),
              );
            }).toList(),
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
      case DailyTaskType.analysis:
        icon = Icons.analytics_rounded;
        color = Colors.deepOrangeAccent;
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
                  // Progress display
                  if (!task.isCompleted &&
                      (task.taskType == DailyTaskType.puzzle ||
                          task.taskType == DailyTaskType.arena ||
                          task.taskType == DailyTaskType.historicalArchive))
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: task.targetValue > 0 ? (task.currentValue / task.targetValue) : 0.0,
                                backgroundColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                                minHeight: 4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${task.currentValue}/${task.targetValue}",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!task.isCompleted) ...[
                    _buildHintChip(task),
                    const SizedBox(height: 8),
                    _buildActionButton(context, task),
                  ],
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

  Widget _buildActionButton(BuildContext context, DailyTask task) {
    String label = "";
    IconData icon = Icons.play_arrow_rounded;
    Color buttonColor = ScholarlyTheme.accentBlue;

    switch (task.taskType) {
      case DailyTaskType.arena:
        label = "LAUNCH COMBAT";
        icon = Icons.sports_esports_rounded;
        buttonColor = Colors.cyan;
        break;
      case DailyTaskType.puzzle:
        label = "SOLVE PUZZLES";
        icon = Icons.extension_rounded;
        buttonColor = ScholarlyTheme.realGold;
        break;
      case DailyTaskType.tutorial:
        label = "START LESSON";
        icon = Icons.menu_book_rounded;
        buttonColor = Colors.purpleAccent;
        break;
      case DailyTaskType.historicalArchive:
        label = "STUDY CINEMA";
        icon = Icons.history_edu_rounded;
        buttonColor = ScholarlyTheme.accentGold;
        break;
      case DailyTaskType.analysis:
        label = "ANALYZE GAME";
        icon = Icons.analytics_rounded;
        buttonColor = Colors.deepOrangeAccent;
        break;
      case DailyTaskType.attendance:
        return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () => _handleTaskAction(context, task),
      icon: Icon(icon, size: 14, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _handleTaskAction(BuildContext context, DailyTask task) {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);

    switch (task.taskType) {
      case DailyTaskType.arena:
        final storeState = ref.read(storeProvider);
        final storeNotifier = ref.read(storeProvider.notifier);
        if (!storeState.isPremium && !storeNotifier.canPlayRatedGame()) {
          PremiumNudgeOverlay.show(
            context,
            ref,
            title: 'Daily Rated Game Limit Reached',
            description: 'You have played your 1 free Rated/Battleground game for today. Upgrade to unlock unlimited games.',
          );
          return;
        }
        ref.read(battlegroundProvider.notifier).launchAssignmentMatch(
          avatarId: task.targetId,
          baseTime: const Duration(minutes: 10),
          increment: Duration.zero,
        );
        ref.read(mobileNavIndexProvider.notifier).state = 2; // Battleground tab
        break;
      case DailyTaskType.puzzle:
        final storeState = ref.read(storeProvider);
        final storeNotifier = ref.read(storeProvider.notifier);
        if (!storeState.isPremium && !storeNotifier.canSolvePuzzle()) {
          PremiumNudgeOverlay.show(
            context,
            ref,
            title: 'Daily Puzzle Limit Reached',
            description: 'You have solved/attempted your 3 free Puzzles for today. Upgrade to unlock unlimited puzzles.',
          );
          return;
        }
        ref.read(mobileNavIndexProvider.notifier).state = 4; // Puzzles tab
        break;
      case DailyTaskType.tutorial:
        final chapterId = int.tryParse(task.targetId);
        if (chapterId != null) {
          ref.read(tutorialProvider.notifier).loadChapter(chapterId);
          ref.read(showChapterSelectionProvider.notifier).state = false;
          ref.read(mobileNavIndexProvider.notifier).state = 7; // Tutorial tab
        }
        break;
      case DailyTaskType.historicalArchive:
        final cinemaGames = ref.read(historicalCinemaProvider).games;
        final gameId = int.tryParse(task.targetId);
        if (gameId != null && cinemaGames.isNotEmpty) {
          final matchedGame = cinemaGames.firstWhere(
            (g) => g.id == gameId,
            orElse: () => cinemaGames.first,
          );
          ref.read(historicalCinemaProvider.notifier).selectGame(matchedGame);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HistoricalCinemaPage(),
            ),
          );
        } else {
          // Fallback to Academy tab if games not loaded
          ref.read(mobileNavIndexProvider.notifier).state = 3; 
        }
        break;
      case DailyTaskType.analysis:
        ref.read(mobileNavIndexProvider.notifier).state = 5; // Analysis tab
        break;
      case DailyTaskType.attendance:
        break;
    }
  }

  Widget _buildHintChip(DailyTask task) {
    String text = "";
    switch (task.taskType) {
      case DailyTaskType.attendance:
        text = "Completed automatically upon entering the Assignment Desk.";
        break;
      case DailyTaskType.arena:
        text = "Complete pre-configured rated game in Battleground";
        break;
      case DailyTaskType.puzzle:
        text = "Go to Puzzles tab — solve 3 puzzles on target axis";
        break;
      case DailyTaskType.tutorial:
        text = "Go to Academy — complete the prescribed chapter";
        break;
      case DailyTaskType.historicalArchive:
        text = "Go to Academy → Historical Cinema — watch until the final move";
        break;
      case DailyTaskType.analysis:
        text = "Go to Study Lab — perform move analysis on a saved game";
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

  Widget _buildCelebrationOverlay(BuildContext context, DailyTask task) {
    final title = task.title.toUpperCase();
    final description = task.description;

    return Positioned.fill(
      child: Stack(
        children: [
          // Blurred Darkened Backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),

          // Central Card Info
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.panelBase.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: ScholarlyTheme.accentGold.withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: ScholarlyTheme.accentGold.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.accentGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: ScholarlyTheme.accentGold,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "ASSIGNMENT COMPLETE",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ScholarlyTheme.accentGold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Apprentice, you have successfully completed the assignment:",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ScholarlyTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "\"Discipline is the forge of masters. Continue your path with diligence.\"",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: ScholarlyTheme.realGold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "— GM Chanakya",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        ref.read(assignmentProvider.notifier).clearCompletionAnimation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScholarlyTheme.accentGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        elevation: 4,
                      ),
                      child: Text(
                        "PROCEED",
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                  "Attend the Chess Academy, study the syllabus, and finish one game with GM Chanakya (win, loss, or draw). Once the game is completed, GM Chanakya's structural diagnostic report will automatically generate and be displayed below.",
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
                      icon: const Icon(Icons.school_rounded),
                      label: Text("Go to Academy Mode", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        ref.read(mobileNavIndexProvider.notifier).state = 3; // Redirect to Academy page
                      },
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        "Game Completed & Reviewed This Week",
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    state.weeklyReport!,
                    style: GoogleFonts.inter(fontSize: 13, height: 1.6, color: ScholarlyTheme.textPrimary),
                  ),
                  if (state.submittedGameId != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                          foregroundColor: ScholarlyTheme.accentBlue,
                          side: const BorderSide(color: ScholarlyTheme.accentBlue, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.analytics_rounded),
                        label: Text("Review Game in Analysis", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                          final chessState = ref.read(chessProvider);
                          final game = chessState.savedGames.where(
                            (g) => g.id == state.submittedGameId,
                          ).firstOrNull;
                          if (game != null) {
                            ref.read(studyLabProvider.notifier).loadGameEntry(
                              game,
                              chanakyaCommentary: game.commentaryHistory,
                            );
                            ref.read(mobileNavIndexProvider.notifier).state = 5; // Analysis tab
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Could not find the game in your library!"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
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

    return BlueprintTabContent(state: state, bgState: bgState);
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
      case DailyTaskType.analysis:
        return "True mastery is born in reflection. Analyze your decisions deeply.";
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
