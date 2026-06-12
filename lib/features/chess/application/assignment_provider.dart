import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/assignment_state.dart';
import '../data/assignment_repository.dart';
import 'battleground_provider.dart';
import 'puzzles_provider.dart';
import 'tutorial_provider.dart';
import 'historical_cinema_provider.dart';
import '../data/historical_cinema_repository.dart';
import '../data/tutorial_lessons.dart';
import '../domain/models/tutorial_lesson.dart';
import 'store_provider.dart';
import 'package:kingslayer_chess/src/rust/api/assignment.dart'
    as rust_assignment;
import 'package:kingslayer_chess/src/rust/api/cognitive.dart' as rust_cognitive;

class AssignmentNotifier extends StateNotifier<AssignmentState> {
  final AssignmentRepository _repository;
  final Ref ref;

  AssignmentNotifier(this._repository, this.ref)
    : super(
        AssignmentState(
          lastResetDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ) {
    _init();
  }

  Future<void> _init() async {
    final loaded = await _repository.loadAssignment();
    state = loaded;

    // Sync calibration progress from battleground on startup if uncalibrated
    if (!state.isCalibrated) {
      final bgState = ref.read(battlegroundProvider);
      if (bgState.totalRatedGamesCount > state.calibrationGamesPlayed) {
        state = state.copyWith(calibrationGamesPlayed: bgState.totalRatedGamesCount);
      }
    }

    // Check daily reset on load
    await checkDailyReset();

    // Set up listeners for other providers to auto-complete tasks
    _setupListeners();

    // Check if already calibrated on load (e.g. if provider loads after battleground has loaded)
    _checkInitialCalibration();
  }

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
      if (!state.isCalibrated) {
        final currentPlayed = next.totalRatedGamesCount;
        if (currentPlayed > state.calibrationGamesPlayed) {
          state = state.copyWith(calibrationGamesPlayed: currentPlayed);
          if (currentPlayed >= 10) {
            // Unlocked calibration!
            _unlockCalibration(next.consolidatedRating);
          }
          _saveState();
        }
      } else {
        if (next.game.gameOver && !(previous?.game.gameOver ?? false)) {
          // Check if today's arena task is completed
          final arenaTaskIndex = state.dailyTasks.indexWhere(
            (t) => t.taskType == DailyTaskType.arena,
          );
          if (arenaTaskIndex != -1) {
            final task = state.dailyTasks[arenaTaskIndex];
            if (next.activeOpponent?.id == task.targetId && !task.isCompleted) {
              _markTaskCompleted(arenaTaskIndex);
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
          // Check if solvedCount matches target value
          if (next.solvedCount >= task.targetValue && !task.isCompleted) {
            final axisName = next.activeAxis?.name;
            if (axisName == task.targetId) {
              _markTaskCompleted(puzzleTaskIndex);
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
              if (next.currentMoveIndex >= task.targetValue) {
                _markTaskCompleted(archiveTaskIndex);
              }
            }
          }
        }
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
    state = state.copyWith(
      isCalibrated: true,
      startElo: baselineRating,
      goalElo: baselineRating + 150, // Baseline goal ELO +150
      goalDeadline: DateTime.now().add(const Duration(days: 30)),
    );
    generateActiveTasks(baselineRating);
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
      updatedHistory[dateKey] = allDone;

      state = state.copyWith(historyLog: updatedHistory, lastResetDate: now);

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

      if (!state.isCalibrated) {
        // Calibration Mode Tasks
        state = state.copyWith(
          calibrationGamesPlayed: state.calibrationGamesPlayed,
          wisdomMessage:
              "Apprentice, complete 10 rated games to calibrate your strength. Only then can I structure your daily training.",
          dailyTasks: [
            const DailyTask(
              title: "DAILY ROLL CALL",
              description: "Report to the Chess Academy for today's training.",
              taskType: DailyTaskType.attendance,
              targetId: "daily_checkin",
              targetValue: 1,
              isCompleted: false,
            ),
            DailyTask(
              title: "Calibrate Strength",
              description:
                  "Complete 10 rated games in Battleground to calibrate ELO and scotomas.",
              taskType: DailyTaskType.arena,
              targetId: "calibration",
              targetValue: 10,
              isCompleted: state.calibrationGamesPlayed >= 10,
            ),
          ],
        );
      } else {
        await generateActiveTasks(bgState.consolidatedRating);
      }
      await _saveState();
    }
  }

  Future<void> generateActiveTasks(int elo) async {
    final bgState = ref.read(battlegroundProvider);
    final tutorialState = ref.read(tutorialProvider);

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

    final completedTutorials = tutorialState.progress.completedChapters
        .toList();

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
            title: "Tactical Prescription",
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
      description: arenaRoutineTask.description,
      taskType: DailyTaskType.arena,
      targetId: arenaRoutineTask.targetId,
      targetValue: arenaRoutineTask.targetValue,
      isCompleted: false,
    );

    // 2. Puzzle Task
    final puzzleRoutineTask = routine.tasks.firstWhere(
      (t) => t.taskType == rust_assignment.ChanakyaTaskType.puzzle,
      orElse: () => const rust_assignment.ChanakyaTask(
        title: "Tactical Prescription",
        description: "Solve 3 scotoma puzzles",
        taskType: rust_assignment.ChanakyaTaskType.puzzle,
        targetId: "ksb",
        targetValue: 3,
      ),
    );
    final puzzleTask = DailyTask(
      title: puzzleRoutineTask.title,
      description: "Solve 3 scotoma-targeted puzzles on axis '${puzzleRoutineTask.targetId}'.",
      taskType: DailyTaskType.puzzle,
      targetId: puzzleRoutineTask.targetId,
      targetValue: 3, // Force target value to 3
      isCompleted: false,
    );

    // 3. Tutorial Task
    final chapterId = _pickTutorialChapter(elo, tutorialState.progress.completedChapters.toList());
    final chapterTitle = _getChapterTitle(chapterId);
    final tutorialTask = DailyTask(
      title: "ACADEMY SYLLABUS",
      description: "Complete Chapter $chapterId: '$chapterTitle'. Focus on piece coordinate precision and fundamental technique.",
      taskType: DailyTaskType.tutorial,
      targetId: chapterId.toString(),
      targetValue: 1,
      isCompleted: false,
    );

    // 4. Historical Archive Task
    final worstAxis = _getWorstScotomaAxis(scotomaInput);
    final cinemaRepo = HistoricalCinemaRepository();
    final cinemaGame = await cinemaRepo.pickGameForScotoma(worstAxis, state.assignedCinemaIds);
    DailyTask cinemaTask;
    int cinemaGameId = -1;
    if (cinemaGame != null) {
      cinemaGameId = cinemaGame.id;
      cinemaTask = DailyTask(
        title: "HISTORICAL ARCHIVE: ${cinemaGame.event}",
        description: "${cinemaGame.white} vs ${cinemaGame.black} (${cinemaGame.year}) — ${cinemaGame.educationalTheme}. Open in Analysis to study.",
        taskType: DailyTaskType.historicalArchive,
        targetId: cinemaGame.id.toString(),
        targetValue: 5, // 5 moves navigated to count as "studied"
        isCompleted: false,
      );
    } else {
      cinemaTask = const DailyTask(
        title: "HISTORICAL ARCHIVE",
        description: "Open any historical master game in Analysis to study and analyze key patterns.",
        taskType: DailyTaskType.historicalArchive,
        targetId: "-1",
        targetValue: 5,
        isCompleted: false,
      );
    }

    final attendanceTask = const DailyTask(
      title: "DAILY ROLL CALL",
      description: "Report to the Chess Academy for today's training.",
      taskType: DailyTaskType.attendance,
      targetId: "daily_checkin",
      targetValue: 1,
      isCompleted: false,
    );

    final dailyTasks = [attendanceTask, arenaTask, puzzleTask, tutorialTask, cinemaTask];

    final isRevision =
        state.goalDeadline != null &&
        DateTime.now().isAfter(state.goalDeadline!) &&
        elo < state.goalElo;

    String wisdom = routine.wisdomMessage;

    if (isRevision) {
      final tutorialIndex = dailyTasks.indexWhere(
        (t) => t.taskType == DailyTaskType.tutorial,
      );
      if (tutorialIndex != -1) {
        final revWorstAxis = _getWorstScotomaAxis(scotomaInput);
        final revChapterId = _mapScotomaToBasicChapter(revWorstAxis);
        final revChapterTitle = _getChapterTitle(revChapterId);

        dailyTasks[tutorialIndex] = DailyTask(
          title: "Basic Revision",
          description:
              "Your target deadline has passed and your ELO is below target. GM Chanakya demands you revise Chapter $revChapterId: '$revChapterTitle'.",
          taskType: DailyTaskType.tutorial,
          targetId: revChapterId.toString(),
          targetValue: 1,
          isCompleted: false,
        );
      }
      wisdom =
          "Apprentice, your target deadline has passed but you remain below the target ELO of ${state.goalElo}. I have revised your syllabus to focus on basic moves revision. Repetition is the mother of wisdom.";
    }

    final updatedCinemaIds = Set<int>.from(state.assignedCinemaIds);
    if (cinemaGameId != -1) {
      updatedCinemaIds.add(cinemaGameId);
    }

    state = state.copyWith(
      dailyTasks: dailyTasks,
      wisdomMessage: wisdom,
      assignedCinemaIds: updatedCinemaIds,
    );
  }

  int _getTierStart(int elo) {
    if (elo < 600) return 1;
    if (elo < 900) return 13;
    if (elo < 1100) return 29;
    if (elo < 1400) return 41;
    return 51;
  }

  int _getTierEnd(int elo) {
    if (elo < 600) return 12;
    if (elo < 900) return 28;
    if (elo < 1100) return 40;
    if (elo < 1400) return 50;
    return 55;
  }

  int _pickTutorialChapter(int elo, List<int> completedChapters) {
    final completedSet = completedChapters.toSet();
    final start = _getTierStart(elo);
    final end = _getTierEnd(elo);
    for (int c = start; c <= end; c++) {
      if (!completedSet.contains(c)) return c;
    }
    // Spill into next tier if all current tier is done
    if (end < 55) {
      for (int c = end + 1; c <= 55; c++) {
        if (!completedSet.contains(c)) return c;
      }
    }
    // All 55 done — loop back to tier start for revision
    return start;
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
    await generateActiveTasks(bgState.consolidatedRating);
  }

  Future<void> setupGoalDeadline(DateTime deadline) async {
    state = state.copyWith(goalDeadline: deadline);
    await _saveState();
    final bgState = ref.read(battlegroundProvider);
    await generateActiveTasks(bgState.consolidatedRating);
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
    } catch (e) {
      state = state.copyWith(weeklyReport: "Failed to generate review: $e");
      await _saveState();
    }
  }

  void checkInAttendance() {
    if (state.dailyTasks.isEmpty) return;
    final index = state.dailyTasks.indexWhere(
      (t) => t.taskType == DailyTaskType.attendance,
    );
    if (index != -1 && !state.dailyTasks[index].isCompleted) {
      _markTaskCompleted(index);
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
  }
}

final assignmentRepositoryProvider = Provider((ref) => AssignmentRepository());

final assignmentProvider =
    StateNotifierProvider<AssignmentNotifier, AssignmentState>((ref) {
      final repository = ref.watch(assignmentRepositoryProvider);
      return AssignmentNotifier(repository, ref);
    });
