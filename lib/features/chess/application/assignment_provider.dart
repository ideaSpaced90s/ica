import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:kingslayer_chess/src/rust/api/pgn_db.dart' as rust_pgn;
import '../domain/models/assignment_state.dart';
import '../domain/performance_ledger_entry.dart';
import '../data/assignment_repository.dart';
import 'battleground_provider.dart';
import 'arena_provider.dart';
import 'puzzles_provider.dart';
import 'tutorial_provider.dart';
import 'historical_cinema_provider.dart';
import '../data/historical_cinema_repository.dart';
import '../data/tutorial_lessons.dart';
import '../domain/models/tutorial_lesson.dart';
import 'store_provider.dart';
import 'chess_provider.dart';
import '../services/cloud_sync_service.dart';
import '../services/notification_service.dart';
import 'package:kingslayer_chess/src/rust/api/assignment.dart'
    as rust_assignment;
import 'package:kingslayer_chess/src/rust/api/cognitive.dart' as rust_cognitive;
import 'lifetime_xp_provider.dart';
import 'study_lab_provider.dart';
import 'navigation_provider.dart';

class AssignmentNotifier extends Notifier<AssignmentState> {
  late final AssignmentRepository _repository;
  bool _listenersSetup = false;

  Timer? _analysisActiveTimer;
  DateTime? _analysisMinuteStartTime;
  int _analysisActionsInCurrentMinute = 0;

  @override
  AssignmentState build() {
    _repository = ref.watch(assignmentRepositoryProvider);
    _init();

    return AssignmentState(
      lastResetDate: DateTime.now().subtract(const Duration(days: 1)),
    );
  }

  Future<void> _init() async {
    final loaded = await _repository.loadAssignment();
    state = loaded;

    // Wait for battleground provider to finish loading settings from disk (max 5 seconds)
    final startTime = DateTime.now();
    while (!ref.read(battlegroundProvider).hasLoadedSettings) {
      if (DateTime.now().difference(startTime).inSeconds >= 5) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 20));
    }

    final bgState = ref.read(battlegroundProvider);
    if (state.isCalibrated != bgState.isCalibrated) {
      if (bgState.isCalibrated) {
        _unlockCalibration(bgState.consolidatedRating);
      } else {
        state = state.copyWith(
          isCalibrated: false,
          calibrationGamesPlayed: bgState.totalRatedGamesCount,
        );
        await generateActiveTasks(bgState.consolidatedRating, isNewDay: true);
      }
      await _saveState();
    } else if (!state.isCalibrated) {
      // Sync calibration progress from battleground on startup if uncalibrated
      if (bgState.totalRatedGamesCount > state.calibrationGamesPlayed) {
        state = state.copyWith(calibrationGamesPlayed: bgState.totalRatedGamesCount);
        await _saveState();
      }
    }

    // Check daily reset on load
    await checkDailyReset();

    // Set up listeners for other providers to auto-complete tasks
    _setupListeners();

    // Check if already in Analysis mode on load
    if (ref.read(mobileNavIndexProvider) == 5) {
      _startAnalysisActiveTimer();
    }

    // Check if already calibrated on load (e.g. if provider loads after battleground has loaded)
    scheduleMicrotask(() {
      _checkInitialCalibration();
    });

    // Auto check-in attendance on load
    checkInAttendance();
  }

  /// Reloads assignment state from disk.
  /// Called after a cloud restore so the UI reflects the restored data
  /// without requiring an app restart (Bug C-02 fix).
  Future<void> reloadFromDisk() => _init();

  void _checkInitialCalibration() {
    if (!state.isCalibrated) {
      if (state.calibrationGamesPlayed >= 10) {
        final bgState = ref.read(battlegroundProvider);
        _unlockCalibration(bgState.consolidatedRating);
        _saveState();
      }
    }
  }

  void _setupListeners() {
    // Guard against duplicate subscriptions on re-init (e.g. after reloadFromDisk)
    if (_listenersSetup) return;
    _listenersSetup = true;

    ref.listen<int>(mobileNavIndexProvider, (previous, next) {
      if (next == 5) {
        _startAnalysisActiveTimer();
      } else {
        _stopAnalysisActiveTimer();
      }
    });

    // Listen to store provider for premium status changes
    ref.listen(storeProvider, (previous, next) {
      if (next.isPremium && !(previous?.isPremium ?? false)) {
        // User just subscribed to premium!
        _checkInitialCalibration();
        checkDailyReset();
      }
    });

    // Listen to battleground provider
    ref.listen(battlegroundProvider, (previous, next) {
      // Sync calibration status changes (e.g. from decay or recalibration completion)
      if (state.isCalibrated != next.isCalibrated) {
        if (next.isCalibrated) {
          _unlockCalibration(next.consolidatedRating);
        } else {
          state = state.copyWith(isCalibrated: false);
          _saveState();
          generateActiveTasks(next.consolidatedRating, isNewDay: true);
        }
        return;
      }

      if (!state.isCalibrated) {
        final isRecal = next.recalibrationGamesRemaining > 0;
        final currentPlayed = isRecal
            ? (5 - next.recalibrationGamesRemaining)
            : next.totalRatedGamesCount;

        if (isRecal) {
          final recalIndex = state.dailyTasks.indexWhere((t) => t.targetId == "recalibration");
          if (recalIndex != -1) {
            final task = state.dailyTasks[recalIndex];
            if (currentPlayed > task.currentValue && !task.isCompleted) {
              final isTaskCompleted = currentPlayed >= 5;
              final updated = List<DailyTask>.from(state.dailyTasks);
              updated[recalIndex] = task.copyWith(
                currentValue: currentPlayed,
                isCompleted: isTaskCompleted,
              );
              state = state.copyWith(
                dailyTasks: updated,
                newlyCompletedTaskIndex: isTaskCompleted ? recalIndex : -1,
              );
              _saveState();
            }
          }
        } else {
          if (next.totalRatedGamesCount > state.calibrationGamesPlayed) {
            state = state.copyWith(calibrationGamesPlayed: next.totalRatedGamesCount);
            if (next.totalRatedGamesCount >= 10) {
              _unlockCalibration(next.consolidatedRating);
            }
            _saveState();
          }
        }
      } else {
        // Rated match ended detection using cachedLedgerEntries changes
        if (previous != null && next.cachedLedgerEntries.length > previous.cachedLedgerEntries.length) {
          final newEntries = next.cachedLedgerEntries.sublist(previous.cachedLedgerEntries.length);
          for (final entry in newEntries) {
            if (entry.source == PerformanceLedgerEntry.ratedBattlegroundSource) {
              final result = entry.result; // 'W', 'L', 'D'
              int xpEarned = 0;
              if (result == 'W') {
                xpEarned = 85;
              } else if (result == 'D') {
                xpEarned = 20;
              }

              // Award Lifetime XP
              if (xpEarned > 0) {
                final opponentName = entry.opponentName;
                final message = result == 'W' ? "Defeated $opponentName" : "Drew with $opponentName";
                ref.read(lifetimeXpProvider.notifier).addXp(
                  xpEarned,
                  message,
                );
              }

              // Update Island Steps step 2 (Battle Proof) progress (Win 3 games)
              if (result == 'W') {
                _updateIslandStepProgress(state.currentIslandIndex, 1, 1);
              }
            }
          }

          // Refresh monthly stats using database entries
          _refreshMonthlyStats(next);
        }

        // Battleground no longer updates Arena tasks directly.
      }
    });

    // Listen to arena provider for daily task completion
    ref.listen(arenaProvider, (previous, next) {
      if (state.isCalibrated) {
        final arenaTaskIndex = state.dailyTasks.indexWhere(
          (t) => t.taskType == DailyTaskType.arena,
        );
        if (arenaTaskIndex != -1) {
          final task = state.dailyTasks[arenaTaskIndex];
          
          // Check if game just ended in Arena
          final previousEnded = previous != null && previous.isGameOver;
          final currentEnded = next.isGameOver;

          if (currentEnded && !previousEnded) {
            // Check if played against the correct avatar
            if (next.engineLevel == task.targetId && !task.isCompleted) {
              final newProgress = task.currentValue + 1;
              final isTaskCompleted = newProgress >= task.targetValue;

              final updated = List<DailyTask>.from(state.dailyTasks);
              updated[arenaTaskIndex] = task.copyWith(
                currentValue: newProgress,
                isCompleted: isTaskCompleted,
              );

              state = state.copyWith(
                dailyTasks: updated,
                newlyCompletedTaskIndex: isTaskCompleted ? arenaTaskIndex : -1,
              );
              _saveState();

              // Check if all daily tasks are completed (excluding tutorial weekly task)
              _checkAllDailyCompleted();
            }
          }
        }
      }
    });

    // Listen to puzzles provider
    ref.listen(puzzlesProvider, (previous, next) {
      if (state.isCalibrated) {
        final puzzleTaskIndex = state.dailyTasks.indexWhere(
          (t) => t.taskType == DailyTaskType.puzzle,
        );
        if (puzzleTaskIndex != -1) {
          final task = state.dailyTasks[puzzleTaskIndex];
          if (!task.isCompleted) {
            final axisName = next.activeAxis?.name;
            String? normalizedAxis;
            if (axisName != null) {
              switch (axisName) {
                case 'ksb': normalizedAxis = 'kingSafety'; break;
                case 'dgb': normalizedAxis = 'diagonalRetreats'; break;
                case 'hrz': normalizedAxis = 'horizontalSwings'; break;
                case 'knf': normalizedAxis = 'knightForks'; break;
                case 'tmp': normalizedAxis = 'timePanic'; break;
                case 'grd': normalizedAxis = 'materialGreed'; break;
                case 'tnl': normalizedAxis = 'tunnelVision'; break;
                case 'pin': normalizedAxis = 'pinnedPieces'; break;
                default: normalizedAxis = axisName;
              }
            }
            if (normalizedAxis == task.targetId || axisName == task.targetId) {
              final prevSolved = previous?.solvedCount ?? 0;
              if (next.solvedCount > prevSolved) {
                final solvedDiff = next.solvedCount - prevSolved;
                final newProgress = (task.currentValue + solvedDiff).clamp(0, task.targetValue);
                final isTaskCompleted = newProgress >= task.targetValue;
                
                final updated = List<DailyTask>.from(state.dailyTasks);
                updated[puzzleTaskIndex] = task.copyWith(
                  currentValue: newProgress,
                  isCompleted: isTaskCompleted,
                );
                
                state = state.copyWith(
                  dailyTasks: updated,
                  newlyCompletedTaskIndex: isTaskCompleted ? puzzleTaskIndex : -1,
                );
                _saveState();

                // Award Lifetime XP
                final isScotoma = next.activeAxis != null && next.activeAxis!.name != 'balanced';
                final xpAwarded = isScotoma ? 20 : 10;
                ref.read(lifetimeXpProvider.notifier).addXp(xpAwarded * solvedDiff, "Solved Puzzle");

                // Update Island Steps step 1 (Scotoma Scan) progress
                _updateIslandStepProgress(state.currentIslandIndex, 0, solvedDiff);

                _checkAllDailyCompleted();
              }
            }
          }
        }
      }
    });

    // Listen to tutorial provider
    ref.listen(tutorialProvider, (previous, next) {
      if (state.isCalibrated) {
        final tutorialTaskIndex = state.dailyTasks.indexWhere(
          (t) => t.taskType == DailyTaskType.tutorial,
        );
        if (tutorialTaskIndex != -1) {
          final task = state.dailyTasks[tutorialTaskIndex];
          final targetChapterId = int.tryParse(task.targetId);
          if (targetChapterId != null &&
              next.currentChapterIndex == targetChapterId &&
              next.isChapterComplete &&
              !(previous?.isChapterComplete ?? false) &&
              !task.isCompleted) {
            _markTaskCompleted(tutorialTaskIndex);

            // Award +60 Lifetime XP upon first-time chapter completion
            ref.read(lifetimeXpProvider.notifier).addXp(60, "Academy Chapter Completed");

            // Update Island Steps step 4 (Academy Pass) progress
            _updateIslandStepProgress(state.currentIslandIndex, 3, 1);
            
            _checkAllDailyCompleted();
          }
        }
      }
    });

    // Listen to historical cinema provider
    ref.listen(historicalCinemaProvider, (previous, next) {
      if (state.isCalibrated) {
        final archiveTaskIndex = state.dailyTasks.indexWhere(
          (t) => t.taskType == DailyTaskType.historicalArchive,
        );
        if (archiveTaskIndex != -1) {
          final task = state.dailyTasks[archiveTaskIndex];
          if (!task.isCompleted) {
            final activeGame = next.activeGame;
            if (activeGame != null && activeGame.id.toString() == task.targetId) {
              final currentProgress = next.currentMoveIndex;
              final maxProgress = currentProgress > task.currentValue ? currentProgress : task.currentValue;
              final newProgress = maxProgress.clamp(0, task.targetValue);
              final isTaskCompleted = newProgress >= task.targetValue;
              
              if (newProgress != task.currentValue) {
                final updated = List<DailyTask>.from(state.dailyTasks);
                updated[archiveTaskIndex] = task.copyWith(
                  currentValue: newProgress,
                  isCompleted: isTaskCompleted,
                );
                
                state = state.copyWith(
                  dailyTasks: updated,
                  newlyCompletedTaskIndex: isTaskCompleted ? archiveTaskIndex : -1,
                );
                _saveState();

                if (isTaskCompleted) {
                  // Award +40 Lifetime XP
                  ref.read(lifetimeXpProvider.notifier).addXp(40, "Cinema Game Studied");

                  // Update Island Steps step 3 (Cinema Study) progress
                  _updateIslandStepProgress(state.currentIslandIndex, 2, 1);
                  
                  _checkAllDailyCompleted();
                }
              }
            }
          }
        }
      }
    });

    // Listen to study lab provider
    ref.listen(studyLabProvider, (previous, next) {
      if (state.isCalibrated && ref.read(mobileNavIndexProvider) == 5) {
        _analysisActionsInCurrentMinute++;
        _analysisMinuteStartTime ??= DateTime.now();
      }
    });
  }

  void _markTaskCompleted(int index) {
    final updated = List<DailyTask>.from(state.dailyTasks);
    updated[index] = updated[index].copyWith(isCompleted: true);
    state = state.copyWith(dailyTasks: updated, newlyCompletedTaskIndex: index);
    _saveState();
  }

  void clearCompletionAnimation() {
    state = state.copyWith(newlyCompletedTaskIndex: -1);
  }

  void _unlockCalibration(int baselineRating) {
    final updatedHistory = Map<String, bool>.from(state.historyLog);
    updatedHistory.removeWhere((key, value) => value == false);

    state = state.copyWith(
      isCalibrated: true,
      startElo: baselineRating,
      goalElo: baselineRating + 150, // Baseline goal ELO +150
      goalDeadline: DateTime.now().add(const Duration(days: 30)),
      historyLog: updatedHistory,
    );
    generateActiveTasks(baselineRating, isNewDay: true);
    _saveState();
  }

  Future<void> checkDailyReset() async {
    final now = DateTime.now();
    final lastReset = state.lastResetDate;

    // Check if day changed
    if (now.year != lastReset.year ||
        now.month != lastReset.month ||
        now.day != lastReset.day) {
      // 1. Log yesterday's completion status
      final dateKey =
          "${lastReset.year}-${lastReset.month.toString().padLeft(2, '0')}-${lastReset.day.toString().padLeft(2, '0')}";
      final allDone =
          state.dailyTasks.isNotEmpty &&
          state.dailyTasks.every((t) => t.isCompleted);

      final updatedHistory = Map<String, bool>.from(state.historyLog);
      if (state.isCalibrated && state.dailyTasks.isNotEmpty) {
        updatedHistory[dateKey] = allDone;
      }

      state = state.copyWith(historyLog: updatedHistory, lastResetDate: now);

      // Check if month changed to reset monthly statistics and record history
      if (now.year != lastReset.year || now.month != lastReset.month) {
        final monthId = "${lastReset.year}-${lastReset.month.toString().padLeft(2, '0')}";
        final newHistoryEntry = MonthlySeasonHistory(
          monthId: monthId,
          wins: state.monthlyWins,
          draws: state.monthlyDraws,
          losses: state.monthlyLosses,
          lp: state.currentMonthLp,
          rank: state.formFactorRank,
          assignmentsCompleted: state.monthlyAssignmentsCompleted,
        );

        final updatedHistoryList = List<MonthlySeasonHistory>.from(state.seasonHistory)..add(newHistoryEntry);
        if (updatedHistoryList.length > 12) {
          updatedHistoryList.removeAt(0);
        }

        state = state.copyWith(
          seasonHistory: updatedHistoryList,
          monthlyWins: 0,
          monthlyDraws: 0,
          monthlyLosses: 0,
          monthlyAssignmentsCompleted: 0,
          currentMonthLp: 0,
          formFactorRank: 'Bronze',
        );
      }

      // Reset submission flag weekly on Mondays
      if (now.weekday == DateTime.monday) {
        state = state.copyWith(
          weeklyReviewSubmitted: false,
          weeklyReport: null,
          submittedGameId: null,
        );
      }

      // Rolling window reset for cinema ids: clear if history log exceeds 30
      if (updatedHistory.length >= 30) {
        state = state.copyWith(assignedCinemaIds: {});
      }

      // 2. Generate new tasks
      final bgState = ref.read(battlegroundProvider);
      await generateActiveTasks(bgState.consolidatedRating, isNewDay: true);
    }
  }

  Future<void> generateActiveTasks(int elo, {bool isNewDay = false}) async {
    final bgState = ref.read(battlegroundProvider);
    final tutorialState = ref.read(tutorialProvider);

    if (!state.isCalibrated) {
      // Calibration / Recalibration Mode Tasks
      final isRecalibrating = bgState.recalibrationGamesRemaining > 0;
      final targetGames = isRecalibrating ? 5 : 10;
      final currentPlayed = isRecalibrating
          ? (5 - bgState.recalibrationGamesRemaining)
          : bgState.totalRatedGamesCount;

      state = state.copyWith(
        calibrationGamesPlayed: bgState.totalRatedGamesCount,
        wisdomMessage: isRecalibrating
            ? "Your skills have decayed due to inactivity. Complete 5 Battleground games to recalibrate your dashboard."
            : "Apprentice, complete 10 Battleground games to calibrate your strength. Only then can I structure your daily training.",
        dailyTasks: [
          DailyTask(
            title: isRecalibrating ? "Recalibrate Strength" : "Calibrate Strength",
            description: isRecalibrating
                ? "Complete 5 Battleground games to recalibrate ELO and scotomas."
                : "Complete 10 Battleground games to calibrate ELO and scotomas.",
            taskType: DailyTaskType.arena,
            targetId: isRecalibrating ? "recalibration" : "calibration",
            targetValue: targetGames,
            currentValue: currentPlayed,
            isCompleted: currentPlayed >= targetGames,
          ),
        ],
      );
      await _saveState();
      return;
    }

    final scotomaInput =
        bgState.cachedScotoma ??
        const rust_cognitive.ScotomaResult(
          diagonalRetreats: 0.15,
          horizontalSwings: 0.15,
          knightForks: 0.15,
          timePanic: 0.15,
          materialGreed: 0.15,
          tunnelVision: 0.15,
          pinnedPieces: 0.15,
          kingSafety: 0.15,
          totalRatedGames: 0,
          analyzedGames: 0,
          skippedGames: 0,
        );

    final completedTutorials = tutorialState.progress.completedChapters.toList();

    // Call Rust FFI logic (with test fallback)
    late final rust_assignment.ChanakyaRoutine routine;
    try {
      routine = rust_assignment.recommendTasksRust(
        elo: elo,
        scotoma: scotomaInput,
        completedTutorials: completedTutorials,
      );
    } catch (_) {
      routine = const rust_assignment.ChanakyaRoutine(
        tasks: [
          rust_assignment.ChanakyaTask(
            title: "Arena Combat",
            description: "Play against a mock avatar",
            taskType: rust_assignment.ChanakyaTaskType.arena,
            targetId: "avatar_0",
            targetValue: 1,
          ),
          rust_assignment.ChanakyaTask(
            title: "Tactical Daily Challenge",
            description: "Solve 5 scotoma puzzles",
            taskType: rust_assignment.ChanakyaTaskType.puzzle,
            targetId: "ksb",
            targetValue: 5,
          ),
          rust_assignment.ChanakyaTask(
            title: "Academy Syllabus",
            description: "Complete Chapter 1",
            taskType: rust_assignment.ChanakyaTaskType.tutorial,
            targetId: "1",
            targetValue: 1,
          ),
        ],
        wisdomMessage: "Discipline is the only armor against structural flaws.",
      );
    }

    // Calculate ELO gap and dynamic Arena target value
    final eloGap = state.goalElo - elo;
    final int dynamicArenaGames;
    if (eloGap <= 0) {
      dynamicArenaGames = 1;
    } else {
      dynamicArenaGames = (eloGap ~/ 40 + 1).clamp(1, 5);
    }

    // Get worst and 2nd worst scotoma axes
    final axes = _getTop2ScotomaAxes(scotomaInput);

    // 1. Arena Task
    final arenaRoutineTask = routine.tasks.firstWhere(
      (t) => t.taskType == rust_assignment.ChanakyaTaskType.arena,
      orElse: () => const rust_assignment.ChanakyaTask(
        title: "Arena Combat",
        description: "Play against a mock avatar",
        taskType: rust_assignment.ChanakyaTaskType.arena,
        targetId: "avatar_0",
        targetValue: 1,
      ),
    );
    final arenaTask = DailyTask(
      title: arenaRoutineTask.title,
      description: "${arenaRoutineTask.description} (Complete $dynamicArenaGames game${dynamicArenaGames > 1 ? 's' : ''})",
      taskType: DailyTaskType.arena,
      targetId: arenaRoutineTask.targetId,
      targetValue: dynamicArenaGames,
      currentValue: 0,
      isCompleted: false,
    );

    // 2. Puzzle Task (Worst axis)
    final puzzleAxis = axes[0];
    final puzzleTask = DailyTask(
      title: "Tactical Daily Challenge",
      description: "Solve 3 scotoma-targeted puzzles on axis '$puzzleAxis'.",
      taskType: DailyTaskType.puzzle,
      targetId: puzzleAxis,
      targetValue: 3,
      currentValue: 0,
      isCompleted: false,
    );

    // 3. Historical Cinema Study Task (2nd worst axis)
    final cinemaStudyAxis = axes[1];
    final cinemaRepo = HistoricalCinemaRepository();
    final cinemaGame = await cinemaRepo.pickGameForScotoma(cinemaStudyAxis, state.assignedCinemaIds);
    DailyTask cinemaTask;
    int cinemaGameId = -1;
    if (cinemaGame != null) {
      cinemaGameId = cinemaGame.id;
      final totalMoves = cinemaGame.moves.length;
      cinemaTask = DailyTask(
        title: "HISTORICAL CINEMA: ${cinemaGame.event}",
        description: "${cinemaGame.white} vs ${cinemaGame.black} (${cinemaGame.year}) — Study and replay all $totalMoves moves.",
        taskType: DailyTaskType.historicalArchive,
        targetId: cinemaGame.id.toString(),
        targetValue: totalMoves,
        currentValue: 0,
        isCompleted: false,
      );
    } else {
      cinemaTask = const DailyTask(
        title: "HISTORICAL CINEMA",
        description: "Open any historical master game in Analysis to study and analyze key patterns.",
        taskType: DailyTaskType.historicalArchive,
        targetId: "-1",
        targetValue: 20,
        currentValue: 0,
        isCompleted: false,
      );
    }

    // 4. Saved Game Analysis Task
    final analysisTask = DailyTask(
      title: "Saved Game Analysis",
      description: "Active Analysis: open a saved game, annotate moves, comment, or spar. (Earn progress by interacting; 10 active minutes = complete)",
      taskType: DailyTaskType.analysis,
      targetId: "analysis",
      targetValue: 10,
      currentValue: 0,
      isCompleted: false,
    );

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isAttendanceDone = state.attendanceLaunchLog[todayStr] == true;

    final attendanceTask = DailyTask(
      title: "Daily Attendance",
      description: "Keep your training consistent: check in by opening the Academy today.",
      taskType: DailyTaskType.attendance,
      targetId: todayStr,
      targetValue: 1,
      currentValue: isAttendanceDone ? 1 : 0,
      isCompleted: isAttendanceDone,
    );

    final dailyTasks = [attendanceTask, arenaTask, puzzleTask, cinemaTask, analysisTask];

    // Preserve completion status and progress from existing daily tasks if it is NOT a new day
    final finalTasks = dailyTasks.map((newTask) {
      if (!isNewDay) {
        final existingIndex = state.dailyTasks.indexWhere((t) => t.taskType == newTask.taskType);
        if (existingIndex != -1) {
          final existing = state.dailyTasks[existingIndex];
          return newTask.copyWith(
            currentValue: existing.currentValue,
            isCompleted: existing.isCompleted,
          );
        }
      }
      return newTask;
    }).toList();

    // Check if we should preserve or generate the Weekly Tutorial task
    DailyTask? existingTutorial;
    final foundTutorialIndex = state.dailyTasks.indexWhere((t) => t.taskType == DailyTaskType.tutorial);
    if (foundTutorialIndex != -1) {
      existingTutorial = state.dailyTasks[foundTutorialIndex];
    }

    final isMonday = DateTime.now().weekday == DateTime.monday;
    if (existingTutorial != null && !isMonday) {
      // Preserve the weekly tutorial task across daily resets
      finalTasks.add(existingTutorial);
    } else {
      // Generate new weekly tutorial task!
      final chapterId = _selectWeeklyChapter(state.currentIslandIndex, completedTutorials);
      final chapterTitle = _getChapterTitle(chapterId);
      final weeklyTutorial = DailyTask(
        title: "Tutorial Assignments",
        description: "Complete Chapter $chapterId: '$chapterTitle' to master this week's syllabus.",
        taskType: DailyTaskType.tutorial,
        targetId: chapterId.toString(),
        targetValue: 1,
        currentValue: 0,
        isCompleted: false,
      );
      finalTasks.add(weeklyTutorial);
    }

    final isRevision =
        state.goalDeadline != null &&
        DateTime.now().isAfter(state.goalDeadline!) &&
        elo < state.goalElo;

    String wisdom = routine.wisdomMessage;

    if (isRevision) {
      final tutorialIndex = finalTasks.indexWhere(
        (t) => t.taskType == DailyTaskType.tutorial,
      );
      final revWorstAxis = _getWorstScotomaAxis(scotomaInput);
      final revChapterId = _mapScotomaToBasicChapter(revWorstAxis);
      final revChapterTitle = _getChapterTitle(revChapterId);
      
      final revisionTask = DailyTask(
        title: "Basic Revision",
        description:
            "Your target deadline has passed and your ELO is below target. GM Chanakya demands you revise Chapter $revChapterId: '$revChapterTitle'.",
        taskType: DailyTaskType.tutorial,
        targetId: revChapterId.toString(),
        targetValue: 1,
        isCompleted: false,
      );

      if (tutorialIndex != -1) {
        finalTasks[tutorialIndex] = revisionTask;
      } else {
        finalTasks.add(revisionTask);
      }
      wisdom =
          "Apprentice, your target deadline has passed but you remain below the target ELO of ${state.goalElo}. I have revised your syllabus to focus on basic moves revision. Repetition is the mother of wisdom.";
    }

    final updatedCinemaIds = Set<int>.from(state.assignedCinemaIds);
    if (cinemaGameId != -1) {
      updatedCinemaIds.add(cinemaGameId);
    }

    state = state.copyWith(
      dailyTasks: finalTasks,
      wisdomMessage: wisdom,
      assignedCinemaIds: updatedCinemaIds,
    );
  }

  int _selectWeeklyChapter(int islandIndex, List<int> completed) {
    final List<int> range;
    switch (islandIndex) {
      case 0: range = [1, 2, 3, 4, 5, 6, 7, 8]; break;
      case 1: range = [9, 10, 11, 12, 13, 14, 15, 16, 17]; break;
      case 2: range = [18, 19, 20, 21, 22, 23, 24, 25]; break;
      case 3: range = [26, 27, 28, 29, 30, 31]; break;
      case 4: range = [32, 33, 34, 35, 36]; break;
      case 5: range = [37, 38, 39, 40, 41, 42, 43]; break;
      case 6: range = [44, 45, 46, 47, 48, 49, 50, 51, 52, 53]; break;
      case 7: range = [54, 55]; break;
      default: range = [1, 2, 3, 4, 5, 6, 7, 8];
    }
    
    // Find first uncompleted chapter in range
    for (final ch in range) {
      if (!completed.contains(ch)) {
        return ch;
      }
    }
    // If all completed, return first in range
    return range.first;
  }

  List<String> _getTop2ScotomaAxes(rust_cognitive.ScotomaResult scotoma) {
    final scores = {
      'diagonalRetreats': scotoma.diagonalRetreats,
      'horizontalSwings': scotoma.horizontalSwings,
      'knightForks': scotoma.knightForks,
      'timePanic': scotoma.timePanic,
      'materialGreed': scotoma.materialGreed,
      'tunnelVision': scotoma.tunnelVision,
      'pinnedPieces': scotoma.pinnedPieces,
      'kingSafety': scotoma.kingSafety,
    };
    final sortedKeys = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    return [sortedKeys[0], sortedKeys[1]];
  }

  AssignmentState _checkIslandProgression(int elo) {
    int newIndex = 0;
    for (int i = 0; i < islandTiers.length; i++) {
      if (elo >= islandTiers[i].minElo && elo < islandTiers[i].maxElo) {
        newIndex = i;
        break;
      }
    }
    if (elo >= 2250) {
      newIndex = 7;
    }

    final updatedLanded = Set<int>.from(state.landedIslandIndices);
    int? landfallPending;

    if (!updatedLanded.contains(newIndex)) {
      updatedLanded.add(newIndex);
      landfallPending = newIndex;
      // Award landfall Lifetime XP
      ref.read(lifetimeXpProvider.notifier).addLandfall(newIndex, islandTiers[newIndex].name);

      // Trigger Milestone notification if enabled
      final isMilestonesEnabled = ref.read(chessProvider).milestonesEnabled;
      if (isMilestonesEnabled) {
        ref.read(notificationServiceProvider).showMilestoneNotification(
          '🏝️ New Territory Reached!',
          'You have reached the ${islandTiers[newIndex].name} tier. GM Chanakya acknowledges your progress.',
        );
      }
    }

    return state.copyWith(
      currentIslandIndex: newIndex,
      landedIslandIndices: updatedLanded,
      landfallPendingIndex: landfallPending,
    );
  }

  void _refreshMonthlyStats(BattlegroundState bgState) {
    final now = DateTime.now();
    // Filter ledger entries for the current calendar month
    final currentMonthEntries = bgState.cachedLedgerEntries.where((entry) {
      return entry.source == PerformanceLedgerEntry.ratedBattlegroundSource &&
          entry.timestamp.year == now.year &&
          entry.timestamp.month == now.month;
    }).toList();

    int newWins = 0;
    int newDraws = 0;
    int newLosses = 0;

    for (final entry in currentMonthEntries) {
      if (entry.result == 'W') {
        newWins++;
      } else if (entry.result == 'D') {
        newDraws++;
      } else if (entry.result == 'L') {
        newLosses++;
      }
    }

    // Calculate new LP using multipliers
    final totalPlayed = newWins + newDraws + newLosses;
    double multiplier = 1.0;
    if (totalPlayed > 0) {
      final winRate = newWins / totalPlayed;
      if (winRate < 0.20) {
        multiplier = 0.7;
      } else if (winRate < 0.40) {
        multiplier = 0.9;
      } else if (winRate < 0.60) {
        multiplier = 1.0;
      } else if (winRate < 0.80) {
        multiplier = 1.2;
      } else {
        multiplier = 1.5;
      }
    }

    final rawGameLp = (newWins * 30) + (newDraws * 10);
    final calculatedLp = (rawGameLp * multiplier).round() + (state.monthlyAssignmentsCompleted * 15);

    // Update Rank Tier
    String newRank = 'Bronze';
    if (calculatedLp >= 2000) {
      newRank = 'Diamond';
    } else if (calculatedLp >= 1200) {
      newRank = 'Platinum';
    } else if (calculatedLp >= 700) {
      newRank = 'Gold';
    } else if (calculatedLp >= 300) {
      newRank = 'Silver';
    }

    // Update island progression based on current ELO
    final newElo = bgState.consolidatedRating;
    final updatedIslandState = _checkIslandProgression(newElo);

    state = state.copyWith(
      monthlyWins: newWins,
      monthlyDraws: newDraws,
      monthlyLosses: newLosses,
      currentMonthLp: calculatedLp,
      formFactorRank: newRank,
      currentIslandIndex: updatedIslandState.currentIslandIndex,
      landedIslandIndices: updatedIslandState.landedIslandIndices,
      landfallPendingIndex: updatedIslandState.landfallPendingIndex,
    );
    _saveState();
  }

  void clearLandfallOverlay() {
    state = state.copyWith(landfallPendingIndex: null);
    _saveState();
  }

  void _updateIslandStepProgress(int islandIndex, int stepIndex, int increment) {
    final currentProgressList = List<int>.from(state.islandStepProgress[islandIndex] ?? [0, 0, 0, 0]);
    
    final targets = [15, 3, 2, 2]; // target values for step 1, 2, 3, 4
    final currentVal = currentProgressList[stepIndex];
    if (currentVal >= targets[stepIndex]) return; // Already cleared

    final newVal = (currentVal + increment).clamp(0, targets[stepIndex]);
    currentProgressList[stepIndex] = newVal;

    final updatedMap = Map<int, List<int>>.from(state.islandStepProgress);
    updatedMap[islandIndex] = currentProgressList;

    state = state.copyWith(islandStepProgress: updatedMap);
    _saveState();
  }

  void _checkAllDailyCompleted() {
    if (!state.isCalibrated) return;
    // Check daily completion of the daily tasks (Attendance, Arena, Puzzle, Cinema, Analysis)
    final dailyOnly = state.dailyTasks.where((t) => t.taskType != DailyTaskType.tutorial);
    if (dailyOnly.isNotEmpty && dailyOnly.every((t) => t.isCompleted)) {
      // Award +15 LP to monthly Form Factor and +150 XP bonus to Lifetime XP
      final dateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (state.historyLog[dateKey] != true) {
        final updatedHistory = Map<String, bool>.from(state.historyLog);
        updatedHistory[dateKey] = true;

        final newAssignmentsCompleted = state.monthlyAssignmentsCompleted + 1;
        
        // Recalculate monthly LP with the new assignments completed bonus
        final rawGameLp = (state.monthlyWins * 30) + (state.monthlyDraws * 10);
        final totalPlayed = state.monthlyWins + state.monthlyDraws + state.monthlyLosses;
        double multiplier = 1.0;
        if (totalPlayed > 0) {
          final winRate = state.monthlyWins / totalPlayed;
          if (winRate < 0.20) {
            multiplier = 0.7;
          } else if (winRate < 0.40) {
            multiplier = 0.9;
          } else if (winRate < 0.60) {
            multiplier = 1.0;
          } else if (winRate < 0.80) {
            multiplier = 1.2;
          } else {
            multiplier = 1.5;
          }
        }
        final calculatedLp = (rawGameLp * multiplier).round() + (newAssignmentsCompleted * 15);

        // Update Rank Tier
        String newRank = 'Bronze';
        if (calculatedLp >= 2000) {
          newRank = 'Diamond';
        } else if (calculatedLp >= 1200) {
          newRank = 'Platinum';
        } else if (calculatedLp >= 700) {
          newRank = 'Gold';
        } else if (calculatedLp >= 300) {
          newRank = 'Silver';
        }

        state = state.copyWith(
          historyLog: updatedHistory,
          monthlyAssignmentsCompleted: newAssignmentsCompleted,
          currentMonthLp: calculatedLp,
          formFactorRank: newRank,
        );
        _saveState();

        ref.read(lifetimeXpProvider.notifier).addXp(150, "Daily Tasks Completed");
      }
    }
  }

  String _getChapterTitle(int chapterId) {
    final lesson = TutorialLessonsDatabase.lessons.firstWhere(
      (l) => l.chapterId == chapterId,
      orElse: () => const TutorialLesson(chapterId: -1, title: 'Basic Moves', setupFen: '', steps: []),
    );
    return lesson.title;
  }

  String _getWorstScotomaAxis(rust_cognitive.ScotomaResult scotoma) {
    String worstName = "kingSafety";
    double worstScore = scotoma.kingSafety;

    if (scotoma.diagonalRetreats > worstScore) {
      worstName = "diagonalRetreats";
      worstScore = scotoma.diagonalRetreats;
    }
    if (scotoma.horizontalSwings > worstScore) {
      worstName = "horizontalSwings";
      worstScore = scotoma.horizontalSwings;
    }
    if (scotoma.knightForks > worstScore) {
      worstName = "knightForks";
      worstScore = scotoma.knightForks;
    }
    if (scotoma.timePanic > worstScore) {
      worstName = "timePanic";
      worstScore = scotoma.timePanic;
    }
    if (scotoma.materialGreed > worstScore) {
      worstName = "materialGreed";
      worstScore = scotoma.materialGreed;
    }
    if (scotoma.tunnelVision > worstScore) {
      worstName = "tunnelVision";
      worstScore = scotoma.tunnelVision;
    }
    if (scotoma.pinnedPieces > worstScore) {
      worstName = "pinnedPieces";
      worstScore = scotoma.pinnedPieces;
    }
    return worstName;
  }

  int _mapScotomaToBasicChapter(String worstAxis) {
    switch (worstAxis) {
      case "diagonalRetreats":
        return 5; // Bishop Movement
      case "horizontalSwings":
        return 4; // Rook Movement
      case "knightForks":
        return 6; // Knight Movement
      case "kingSafety":
        return 8; // King Movement
      case "materialGreed":
        return 9; // Capturing Pieces
      case "pinnedPieces":
        return 3; // Pawn Movement
      case "tunnelVision":
        return 2; // Coordinates & Tiles
      case "timePanic":
        return 7; // Queen Movement / Time Management
      default:
        return 1; // Board Introduction
    }
  }

  Future<void> setupGoal(int targetElo) async {
    state = state.copyWith(
      goalElo: targetElo,
      startElo: ref.read(battlegroundProvider).consolidatedRating,
      goalDeadline:
          state.goalDeadline ?? DateTime.now().add(const Duration(days: 30)),
    );
    await _saveState();
    final bgState = ref.read(battlegroundProvider);
    await generateActiveTasks(bgState.consolidatedRating, isNewDay: false);
  }

  Future<void> setupGoalDeadline(DateTime deadline) async {
    state = state.copyWith(goalDeadline: deadline);
    await _saveState();
    final bgState = ref.read(battlegroundProvider);
    await generateActiveTasks(bgState.consolidatedRating, isNewDay: false);
  }

  Future<void> submitGameForReview(String gameId, String pgnContent) async {
    state = state.copyWith(
      weeklyReviewSubmitted: true,
      submittedGameId: gameId,
      weeklyReport:
          "GM Chanakya is reviewing your game records... Please wait.",
    );
    await _saveState();

    try {
      final bgState = ref.read(battlegroundProvider);
      final scotomaInput =
          bgState.cachedScotoma ??
          const rust_cognitive.ScotomaResult(
            diagonalRetreats: 0.15,
            horizontalSwings: 0.15,
            knightForks: 0.15,
            timePanic: 0.15,
            materialGreed: 0.15,
            tunnelVision: 0.15,
            pinnedPieces: 0.15,
            kingSafety: 0.15,
            totalRatedGames: 0,
            analyzedGames: 0,
            skippedGames: 0,
          );

      // 1. Call Rust PGN analyzer
      final summary = rust_assignment.analyzeSubmittedGameRust(
        pgnContent: pgnContent,
        scotoma: scotomaInput,
      );

      state = state.copyWith(weeklyReport: summary.fallbackReport);
      await _saveState();

      // Award +200 XP
      ref.read(lifetimeXpProvider.notifier).addXp(200, "Weekly Review Completed");
    } catch (e) {
      state = state.copyWith(weeklyReport: "Failed to generate review: $e");
      await _saveState();
    }
  }

  Future<void> generateWeeklyReportFromAcademyGame(String gameId) async {
    // 1. Load the specific saved game
    final repo = ref.read(savedGameRepositoryProvider);
    final saves = await repo.listSaves();
    final game = saves.firstWhere(
      (g) => g.id == gameId,
      orElse: () => throw Exception('Saved game not found for ID $gameId'),
    );
    final moves = game.recentMoves;
    final commentary = game.commentaryHistory;
    final initialFen = game.initialFen ?? chess_lib.Chess.DEFAULT_POSITION;

    // 2. Reconstruct PGN with annotations/blunders
    final pgnMoves = StringBuffer();
    final tempGame = chess_lib.Chess.fromFEN(initialFen);

    for (int i = 0; i < moves.length; i++) {
      final moveSan = moves[i];
      if (i % 2 == 0) {
        final moveNumber = (i ~/ 2) + 1;
        pgnMoves.write('$moveNumber. ');
      }
      pgnMoves.write('$moveSan ');

      try {
        tempGame.move(moveSan);
        final fenAfterMove = tempGame.fen;

        // Find if there's a blunder comment
        final blunderComment = commentary.where(
          (entry) => !entry.isUser && entry.associatedFen == fenAfterMove && entry.text.toLowerCase().contains('blunder'),
        ).firstOrNull;

        if (blunderComment != null) {
          final cleanText = blunderComment.text.replaceAll(RegExp(r'\*\*.*?\*\*\n\n'), '').trim();
          pgnMoves.write('?? {$cleanText} ');
        } else {
          final normalComment = commentary.where(
            (entry) => !entry.isUser && entry.associatedFen == fenAfterMove,
          ).firstOrNull;
          if (normalComment != null) {
            final cleanText = normalComment.text.replaceAll(RegExp(r'\*\*.*?\*\*\n\n'), '').trim();
            pgnMoves.write('{$cleanText} ');
          }
        }
      } catch (e) {
        // Fallback for safety if move execution throws
      }
    }

    // Determine the result for PGN
    String pgnResult = "*";
    if (game.result == 'W') {
      pgnResult = game.isPlayerWhite ? "1-0" : "0-1";
    } else if (game.result == 'L') {
      pgnResult = game.isPlayerWhite ? "0-1" : "1-0";
    } else if (game.result == 'D') {
      pgnResult = "1/2-1/2";
    }

    final userName = ref.read(chessProvider).userName;
    final isPlayerWhite = game.isPlayerWhite;

    final header = rust_pgn.PgnGameHeader(
      event: "Academy Game vs GM Chanakya",
      site: "ideaSpace Academy",
      date: DateFormat('yyyy.MM.dd').format(game.savedAt),
      white: isPlayerWhite ? userName : "GM Chanakya",
      black: isPlayerWhite ? "GM Chanakya" : userName,
      whiteElo: isPlayerWhite
          ? (game.ratingSnapshot ?? ref.read(battlegroundProvider).consolidatedRating)
          : 1400, // GM Chanakya
      blackElo: isPlayerWhite
          ? 1400
          : (game.ratingSnapshot ?? ref.read(battlegroundProvider).consolidatedRating),
      result: pgnResult,
      eco: "?",
      opening: "?",
    );

    final fullPgn = rust_pgn.exportPgnWithHeaders(
      header: header,
      annotatedPgn: pgnMoves.toString().trim(),
    );

    // 3. Mark submitted and run analysis
    state = state.copyWith(
      weeklyReviewSubmitted: true,
      submittedGameId: gameId,
      weeklyReport: "GM Chanakya is reviewing your game records... Please wait.",
    );
    await _saveState();

    try {
      final bgState = ref.read(battlegroundProvider);
      final scotomaInput = bgState.cachedScotoma ??
          const rust_cognitive.ScotomaResult(
            diagonalRetreats: 0.15,
            horizontalSwings: 0.15,
            knightForks: 0.15,
            timePanic: 0.15,
            materialGreed: 0.15,
            tunnelVision: 0.15,
            pinnedPieces: 0.15,
            kingSafety: 0.15,
            totalRatedGames: 0,
            analyzedGames: 0,
            skippedGames: 0,
          );

      // Call Rust PGN analyzer
      final summary = rust_assignment.analyzeSubmittedGameRust(
        pgnContent: fullPgn,
        scotoma: scotomaInput,
      );

      state = state.copyWith(weeklyReport: summary.fallbackReport);
      await _saveState();

      // Award +200 XP
      ref.read(lifetimeXpProvider.notifier).addXp(200, "Weekly Review Completed");
    } catch (e) {
      state = state.copyWith(weeklyReport: "Failed to generate review: $e");
      await _saveState();
    }
  }

  void checkInAttendance() {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (state.attendanceLaunchLog[todayStr] == true) return;

    final updatedLaunchLog = Map<String, bool>.from(state.attendanceLaunchLog);
    updatedLaunchLog[todayStr] = true;

    state = state.copyWith(attendanceLaunchLog: updatedLaunchLog);

    if (state.dailyTasks.isEmpty) {
      _saveState();
      return;
    }

    final index = state.dailyTasks.indexWhere(
      (t) => t.taskType == DailyTaskType.attendance,
    );
    if (index != -1 && !state.dailyTasks[index].isCompleted) {
      final updatedTasks = List<DailyTask>.from(state.dailyTasks);
      updatedTasks[index] = updatedTasks[index].copyWith(
        currentValue: 1,
        isCompleted: true,
      );
      state = state.copyWith(
        dailyTasks: updatedTasks,
        newlyCompletedTaskIndex: index,
      );
      _saveState();
      _checkAllDailyCompleted();
    } else {
      _saveState();
    }
  }

  Future<void> forceResetDaily() async {
    state = state.copyWith(
      lastResetDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    await checkDailyReset();
  }

  Future<void> resetAssignmentProgress() async {
    state = AssignmentState(
      lastResetDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    await _saveState();
  }

  Future<void> _saveState() async {
    await _repository.saveAssignment(state);
    ref.read(cloudSyncProvider.notifier).backup(silent: true);
  }

  void _startAnalysisActiveTimer() {
    _analysisActiveTimer?.cancel();
    _analysisMinuteStartTime = DateTime.now();
    _analysisActionsInCurrentMinute = 0;

    _analysisActiveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (ref.read(mobileNavIndexProvider) != 5) {
        _stopAnalysisActiveTimer();
        return;
      }

      if (_analysisMinuteStartTime != null) {
        final diff = DateTime.now().difference(_analysisMinuteStartTime!);
        if (diff.inSeconds >= 60) {
          if (_analysisActionsInCurrentMinute >= 1) {
            _incrementAnalysisTaskProgress();
          }
          _analysisMinuteStartTime = DateTime.now();
          _analysisActionsInCurrentMinute = 0;
        }
      }
    });
  }

  void _stopAnalysisActiveTimer() {
    _analysisActiveTimer?.cancel();
    _analysisActiveTimer = null;
    _analysisMinuteStartTime = null;
    _analysisActionsInCurrentMinute = 0;
  }

  void _incrementAnalysisTaskProgress() {
    final idx = state.dailyTasks.indexWhere((t) => t.taskType == DailyTaskType.analysis);
    if (idx != -1) {
      final task = state.dailyTasks[idx];
      if (!task.isCompleted) {
        final newProgress = (task.currentValue + 1).clamp(0, task.targetValue);
        final isCompleted = newProgress >= task.targetValue;

        final updated = List<DailyTask>.from(state.dailyTasks);
        updated[idx] = task.copyWith(
          currentValue: newProgress,
          isCompleted: isCompleted,
        );

        state = state.copyWith(
          dailyTasks: updated,
          newlyCompletedTaskIndex: isCompleted ? idx : -1,
        );
        _saveState();

        ref.read(lifetimeXpProvider.notifier).addXp(15, "Active Game Analysis Minute");

        _checkAllDailyCompleted();
      }
    }
  }
}

class IslandTierInfo {
  final String name;
  final int minElo;
  final int maxElo;
  final String scotomaFocus;
  final String chapterRange;

  const IslandTierInfo({
    required this.name,
    required this.minElo,
    required this.maxElo,
    required this.scotomaFocus,
    required this.chapterRange,
  });
}

const List<IslandTierInfo> islandTiers = [
  IslandTierInfo(name: 'Footsoldier', minElo: 400, maxElo: 650, scotomaFocus: 'Piece safety, basic captures', chapterRange: 'Ch 1–8'),
  IslandTierInfo(name: 'Apprentice', minElo: 650, maxElo: 900, scotomaFocus: 'Pawn structure, pinned pieces', chapterRange: 'Ch 9–17'),
  IslandTierInfo(name: 'Tactician', minElo: 900, maxElo: 1100, scotomaFocus: 'Knight forks, diagonal retreats', chapterRange: 'Ch 18–25'),
  IslandTierInfo(name: 'Strategist', minElo: 1100, maxElo: 1350, scotomaFocus: 'King safety, tunnel vision', chapterRange: 'Ch 26–31'),
  IslandTierInfo(name: 'Inquisitor', minElo: 1350, maxElo: 1600, scotomaFocus: 'Time panic, material greed', chapterRange: 'Ch 32–36'),
  IslandTierInfo(name: 'Warlord', minElo: 1600, maxElo: 1900, scotomaFocus: 'Horizontal swings, multi-axis combos', chapterRange: 'Ch 37–43'),
  IslandTierInfo(name: 'Grandmaster', minElo: 1900, maxElo: 2250, scotomaFocus: 'Full scotoma mastery', chapterRange: 'Ch 44–53'),
  IslandTierInfo(name: 'Kingslayer', minElo: 2250, maxElo: 9999, scotomaFocus: 'Beyond the curriculum', chapterRange: 'Ch 54–55'),
];

final assignmentRepositoryProvider = Provider((ref) => AssignmentRepository());

final assignmentProvider =
    NotifierProvider<AssignmentNotifier, AssignmentState>(AssignmentNotifier.new);
