import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/assignment_state.dart';
import '../data/assignment_repository.dart';
import 'battleground_provider.dart';
import 'puzzles_provider.dart';
import 'tutorial_provider.dart';
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

    // Check daily reset on load
    await checkDailyReset();

    // Set up listeners for other providers to auto-complete tasks
    _setupListeners();

    // Check if already calibrated on load (e.g. if provider loads after battleground has loaded)
    _checkInitialCalibration();
  }

  void _checkInitialCalibration() {
    if (!state.isCalibrated) {
      final bgState = ref.read(battlegroundProvider);
      if (bgState.totalRatedGamesCount >= 10) {
        _unlockCalibration(bgState.consolidatedRating);
        _saveState();
      }
    }
  }

  void _setupListeners() {
    // Listen to battleground provider
    ref.listen(battlegroundProvider, (previous, next) {
      if (!state.isCalibrated) {
        final currentPlayed = next.totalRatedGamesCount;
        if (currentPlayed != previous?.totalRatedGamesCount) {
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
  }

  void _markTaskCompleted(int index) {
    final updated = List<DailyTask>.from(state.dailyTasks);
    updated[index] = updated[index].copyWith(isCompleted: true);
    state = state.copyWith(dailyTasks: updated);
    _saveState();
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

      // 2. Generate new tasks
      final bgState = ref.read(battlegroundProvider);

      if (!state.isCalibrated) {
        // Calibration Mode Tasks
        state = state.copyWith(
          calibrationGamesPlayed: bgState.totalRatedGamesCount,
          wisdomMessage:
              "Apprentice, complete 10 rated games to calibrate your strength. Only then can I structure your daily training.",
          dailyTasks: [
            DailyTask(
              title: "Calibrate Strength",
              description:
                  "Complete 10 rated games in Battleground to calibrate ELO and scotomas.",
              taskType: DailyTaskType.arena,
              targetId: "calibration",
              targetValue: 10,
              isCompleted: bgState.totalRatedGamesCount >= 10,
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

    // Map tasks
    final dailyTasks = routine.tasks.map((t) {
      DailyTaskType type = DailyTaskType.arena;
      switch (t.taskType) {
        case rust_assignment.ChanakyaTaskType.arena:
          type = DailyTaskType.arena;
          break;
        case rust_assignment.ChanakyaTaskType.puzzle:
          type = DailyTaskType.puzzle;
          break;
        case rust_assignment.ChanakyaTaskType.tutorial:
          type = DailyTaskType.tutorial;
          break;
      }
      return DailyTask(
        title: t.title,
        description: t.description,
        taskType: type,
        targetId: t.targetId,
        targetValue: t.targetValue,
        isCompleted: false,
      );
    }).toList();

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
        final worstAxis = _getWorstScotomaAxis(scotomaInput);
        final chapterId = _mapScotomaToBasicChapter(worstAxis);
        final chapterTitle = _getChapterTitleText(chapterId);

        dailyTasks[tutorialIndex] = DailyTask(
          title: "Basic Revision",
          description:
              "Your target deadline has passed and your ELO is below target. GM Chanakya demands you revise Chapter $chapterId: '$chapterTitle'.",
          taskType: DailyTaskType.tutorial,
          targetId: chapterId.toString(),
          targetValue: 1,
          isCompleted: false,
        );
      }
      wisdom =
          "Apprentice, your target deadline has passed but you remain below the target ELO of ${state.goalElo}. I have revised your syllabus to focus on basic moves revision. Repetition is the mother of wisdom.";
    }

    state = state.copyWith(dailyTasks: dailyTasks, wisdomMessage: wisdom);
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

  String _getChapterTitleText(int chap) {
    switch (chap) {
      case 1:
        return "Board Introduction";
      case 2:
        return "Coordinates & Tiles";
      case 3:
        return "Pawn Movement";
      case 4:
        return "Rook Movement";
      case 5:
        return "Bishop Movement";
      case 6:
        return "Knight Movement";
      case 7:
        return "Queen Movement";
      case 8:
        return "King Movement";
      case 9:
        return "Capturing Pieces";
      default:
        return "Basic Moves";
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
