import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kingslayer_chess/features/chess/domain/models/assignment_state.dart';
import 'package:kingslayer_chess/features/chess/domain/models/tutorial_progress.dart';
import 'package:kingslayer_chess/features/chess/data/assignment_repository.dart';
import 'package:kingslayer_chess/features/chess/application/assignment_provider.dart';
import 'package:kingslayer_chess/features/chess/application/battleground_provider.dart';
import 'package:kingslayer_chess/features/chess/application/puzzles_provider.dart';
import 'package:kingslayer_chess/features/chess/application/tutorial_provider.dart';
import 'package:kingslayer_chess/features/chess/data/prescription_puzzle_repository.dart';
import 'package:kingslayer_chess/features/chess/application/store_provider.dart';
import 'package:kingslayer_chess/features/chess/application/chess_provider.dart';
import 'package:kingslayer_chess/src/rust/api/cognitive.dart' as rust_cognitive;
import 'package:kingslayer_chess/features/chess/services/cloud_sync_service.dart';
import 'package:kingslayer_chess/features/chess/domain/performance_ledger_entry.dart';

class FakeAssignmentRepository implements AssignmentRepository {
  AssignmentState? savedState;

  @override
  Future<AssignmentState> loadAssignment() async {
    return savedState ?? AssignmentState(lastResetDate: DateTime.now().subtract(const Duration(days: 1)));
  }

  @override
  Future<void> saveAssignment(AssignmentState state) async {
    savedState = state;
  }
}

class FakeBattlegroundState extends Fake implements BattlegroundState {
  @override
  final int consolidatedRating;
  @override
  final int totalRatedGamesCount;
  @override
  final rust_cognitive.ScotomaResult? cachedScotoma;
  @override
  final bool hasLoadedSettings;
  @override
  final List<PerformanceLedgerEntry> cachedLedgerEntries;
  @override
  final int recalibrationGamesRemaining;

  @override
  bool get isCalibrated => totalRatedGamesCount >= 10 && recalibrationGamesRemaining == 0;

  FakeBattlegroundState({
    required this.consolidatedRating,
    required this.totalRatedGamesCount,
    this.cachedScotoma,
    this.hasLoadedSettings = true,
    this.cachedLedgerEntries = const [],
    this.recalibrationGamesRemaining = 0,
  });
}

class FakeBattlegroundNotifier extends Notifier<BattlegroundState> implements BattlegroundNotifier {
  final BattlegroundState initialState;
  FakeBattlegroundNotifier(this.initialState);

  @override
  BattlegroundState build() {
    return initialState;
  }

  void updateState(BattlegroundState newState) {
    state = newState;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePuzzlesState extends Fake implements PuzzlesState {
  @override
  final int solvedCount;
  @override
  final ScotomaAxis? activeAxis;

  FakePuzzlesState({
    required this.solvedCount,
    this.activeAxis,
  });
}

class FakePuzzlesNotifier extends Notifier<PuzzlesState> implements PuzzlesNotifier {
  final PuzzlesState initialState;
  FakePuzzlesNotifier(this.initialState);

  @override
  PuzzlesState build() {
    return initialState;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTutorialProgress extends Fake implements TutorialProgress {
  @override
  final Set<int> completedChapters;
  FakeTutorialProgress({required this.completedChapters});
}

class FakeTutorialState extends Fake implements TutorialState {
  @override
  final TutorialProgress progress;
  @override
  final int currentChapterIndex;
  @override
  final bool isChapterComplete;

  FakeTutorialState({
    required this.progress,
    this.currentChapterIndex = 1,
    this.isChapterComplete = false,
  });
}

class FakeTutorialNotifier extends Notifier<TutorialState> implements TutorialNotifier {
  final TutorialState initialState;
  FakeTutorialNotifier(this.initialState);

  @override
  TutorialState build() {
    return initialState;
  }

  void updateState(TutorialState newState) {
    state = newState;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChessState extends Fake implements ChessState {
  @override
  final String engineLevel;
  @override
  final String bottomAvatarId;
  @override
  final bool isBoardFlipped;
  @override
  final bool isPlayerWhite;
  @override
  final String gameMode;

  FakeChessState({
    this.engineLevel = 'avatar_6',
    this.bottomAvatarId = 'avatar_6',
    this.isBoardFlipped = false,
    this.isPlayerWhite = true,
    this.gameMode = 'classic',
  });
}

class FakeChessNotifier extends Notifier<ChessState> implements ChessNotifier {
  final ChessState initialState;
  FakeChessNotifier(this.initialState);

  @override
  ChessState build() {
    return initialState;
  }

  @override
  Future<void> setEngineLevel(String level) async {}

  @override
  Future<void> setBottomAvatarId(String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStoreNotifier extends StoreNotifier {
  final StoreState initialState;
  FakeStoreNotifier(this.initialState) : super(loadData: false);

  @override
  StoreState build() {
    return initialState;
  }

  void updateState(StoreState newState) {
    state = newState;
  }
}

class FakeCloudSyncNotifier extends Notifier<CloudSyncState> implements CloudSyncNotifier {
  @override
  CloudSyncState build() {
    return CloudSyncState();
  }

  @override
  Future<bool> backup({bool silent = false}) async {
    return true;
  }

  @override
  Future<bool> restore() async {
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      return '.';
    },
  );

  group('DailyTask and AssignmentState Model Tests', () {
    test('DailyTask toJson and fromJson match', () {
      const task = DailyTask(
        title: 'Arena Battle',
        description: 'Defeat Sparky',
        taskType: DailyTaskType.arena,
        targetId: 'avatar_0',
        targetValue: 1,
        isCompleted: true,
      );

      final json = task.toJson();
      final fromJson = DailyTask.fromJson(json);

      expect(fromJson.title, task.title);
      expect(fromJson.description, task.description);
      expect(fromJson.taskType, task.taskType);
      expect(fromJson.targetId, task.targetId);
      expect(fromJson.targetValue, task.targetValue);
      expect(fromJson.isCompleted, task.isCompleted);
    });

    test('AssignmentState toJson and fromJson match', () {
      final state = AssignmentState(
        calibrationGamesPlayed: 5,
        isCalibrated: true,
        goalElo: 1200,
        startElo: 1050,
        goalDeadline: DateTime(2026, 7, 6),
        dailyTasks: const [
          DailyTask(
            title: 'Solve Puzzles',
            description: 'Solve 5 pinned puzzles',
            taskType: DailyTaskType.puzzle,
            targetId: 'pin',
            targetValue: 5,
            isCompleted: false,
          ),
        ],
        lastResetDate: DateTime(2026, 6, 6),
        historyLog: const {'2026-06-05': true},
        weeklyReviewSubmitted: true,
        submittedGameId: 'game_123',
        weeklyReport: 'Excellent play!',
        wisdomMessage: 'Patience is a weapon.',
      );

      final json = state.toJson();
      final fromJson = AssignmentState.fromJson(json);

      expect(fromJson.calibrationGamesPlayed, state.calibrationGamesPlayed);
      expect(fromJson.isCalibrated, state.isCalibrated);
      expect(fromJson.goalElo, state.goalElo);
      expect(fromJson.startElo, state.startElo);
      expect(fromJson.goalDeadline, state.goalDeadline);
      expect(fromJson.dailyTasks.length, state.dailyTasks.length);
      expect(fromJson.dailyTasks.first.title, state.dailyTasks.first.title);
      expect(fromJson.lastResetDate.year, state.lastResetDate.year);
      expect(fromJson.historyLog, state.historyLog);
      expect(fromJson.weeklyReviewSubmitted, state.weeklyReviewSubmitted);
      expect(fromJson.submittedGameId, state.submittedGameId);
      expect(fromJson.weeklyReport, state.weeklyReport);
      expect(fromJson.wisdomMessage, state.wisdomMessage);
    });
  });

  group('AssignmentProvider State and Logic Tests', () {
    late FakeAssignmentRepository fakeRepository;
    late FakeBattlegroundNotifier fakeBattleground;
    late FakePuzzlesNotifier fakePuzzles;
    late FakeTutorialNotifier fakeTutorial;

    StoreState createMockStoreState({bool isPremium = true}) {
      return StoreState(
        goldBalance: 1000,
        isPremium: isPremium,
        joinedFreeDate: DateTime.now(),
        purchasedAvatars: {},
        purchasedBoardThemes: {},
        freeTierUsage: FreeTierUsage(
          dateKey: '',
          ratedGamesPlayed: 0,
          arenaGamesPlayed: 0,
          chipPromptsUsed: 0,
          puzzlesSolved: 0,
        ),
        cycleThemeUsageDates: {},
      );
    }

    setUp(() {
      fakeRepository = FakeAssignmentRepository();
      fakeBattleground = FakeBattlegroundNotifier(FakeBattlegroundState(
        consolidatedRating: 1200,
        totalRatedGamesCount: 0,
      ));
      fakePuzzles = FakePuzzlesNotifier(FakePuzzlesState(
        solvedCount: 0,
      ));
      fakeTutorial = FakeTutorialNotifier(FakeTutorialState(
        progress: FakeTutorialProgress(completedChapters: const {}),
      ));
    });

    ProviderContainer createContainer({bool isPremium = true}) {
      final container = ProviderContainer(
        overrides: [
          assignmentRepositoryProvider.overrideWithValue(fakeRepository),
          battlegroundProvider.overrideWith(() => fakeBattleground),
          puzzlesProvider.overrideWith(() => fakePuzzles),
          tutorialProvider.overrideWith(() => fakeTutorial),
          chessProvider.overrideWith(() => FakeChessNotifier(FakeChessState())),
          storeProvider.overrideWith(() {
            return FakeStoreNotifier(createMockStoreState(isPremium: isPremium));
          }),
          cloudSyncProvider.overrideWith(() => FakeCloudSyncNotifier()),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('Initializes with default calibration state', () async {
      final container = createContainer(isPremium: true);

      // Trigger and wait for initialization
      container.read(assignmentProvider);
      await Future.delayed(const Duration(milliseconds: 20));
      
      final updatedState = container.read(assignmentProvider);
      expect(updatedState.isCalibrated, isFalse);
      expect(updatedState.calibrationGamesPlayed, 0);
      expect(updatedState.dailyTasks, isNotEmpty); // Initial calibration task generated
    });

    test('setupGoal sets new target rating', () async {
      final container = createContainer(isPremium: true);

      // Wait for notifier initialization first
      final notifier = container.read(assignmentProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 20));

      await notifier.setupGoal(1400);

      final state = container.read(assignmentProvider);
      expect(state.goalElo, 1400);
      expect(state.goalDeadline, isNotNull);
      expect(fakeRepository.savedState?.goalElo, 1400);
    });

    test('setupGoal preserves completed tasks when updated on the same day', () async {
      final container = createContainer(isPremium: true);
      final notifier = container.read(assignmentProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 20));

      // Calibrate first to generate active tasks
      notifier.state = notifier.state.copyWith(
        isCalibrated: true,
        startElo: 1200,
        goalElo: 1350,
      );
      await notifier.generateActiveTasks(1200, isNewDay: true);

      // Mark the arena task as completed
      final arenaIndex = notifier.state.dailyTasks.indexWhere((t) => t.taskType == DailyTaskType.arena);
      expect(arenaIndex, isNot(-1));
      notifier.state = notifier.state.copyWith(
        dailyTasks: notifier.state.dailyTasks.map((t) => t.taskType == DailyTaskType.arena ? t.copyWith(isCompleted: true) : t).toList(),
      );

      // Adjust the goal (which calls generateActiveTasks internally with isNewDay = false)
      await notifier.setupGoal(1400);

      // Check if the arena task is still completed
      final updatedArenaTask = notifier.state.dailyTasks.firstWhere((t) => t.taskType == DailyTaskType.arena);
      expect(updatedArenaTask.isCompleted, isTrue);
    });

    test('daily reset does not log yesterday as failure if dailyTasks was empty', () async {
      final container = createContainer(isPremium: true);
      final notifier = container.read(assignmentProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 20));

      // Start with empty tasks and yesterday's lastResetDate
      notifier.state = notifier.state.copyWith(
        dailyTasks: const [],
        lastResetDate: DateTime.now().subtract(const Duration(days: 1)),
        historyLog: const {},
      );

      // Perform reset
      await notifier.checkDailyReset();

      // Yesterday should NOT be in the history log
      expect(notifier.state.historyLog, isEmpty);
    });

    test('resetAssignmentProgress clears all progress', () async {
      final container = createContainer(isPremium: true);

      final notifier = container.read(assignmentProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 20));

      // 1. Mutate goal first
      await notifier.setupGoal(1500);
      expect(container.read(assignmentProvider).goalElo, 1500);

      // 2. Clear progress
      await notifier.resetAssignmentProgress();
      
      final state = container.read(assignmentProvider);
      expect(state.goalElo, 0);
      expect(state.isCalibrated, isFalse);
      expect(fakeRepository.savedState?.goalElo, 0);
    });

    test('Revision mode triggers basic moves tutorial when goal deadline expires with low ELO', () async {
      final container = createContainer(isPremium: true);

      final notifier = container.read(assignmentProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 20));

      notifier.state = notifier.state.copyWith(
        isCalibrated: true,
        goalElo: 1400,
        startElo: 1200,
        goalDeadline: DateTime.now().subtract(const Duration(days: 1)),
      );

      await notifier.generateActiveTasks(1200);

      final state = container.read(assignmentProvider);
      
      final tutorialTask = state.dailyTasks.firstWhere((t) => t.taskType == DailyTaskType.tutorial);
      expect(tutorialTask.title, "Basic Revision");
      expect(tutorialTask.description, contains("GM Chanakya demands you revise Chapter"));
      expect(state.wisdomMessage, contains("I have revised your syllabus to focus on basic moves revision"));
    });

    test('Triggers calibration when totalRatedGamesCount reaches 10 via listener', () async {
      final container = createContainer(isPremium: true);

      // Trigger initialization
      container.read(assignmentProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(container.read(assignmentProvider).isCalibrated, isFalse);

      // Simulate reaching 10 games
      fakeBattleground.updateState(FakeBattlegroundState(
        consolidatedRating: 1350,
        totalRatedGamesCount: 10,
      ));

      // Wait for listener to process
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(assignmentProvider);
      expect(state.isCalibrated, isTrue);
      expect(state.startElo, 1350);
      expect(state.goalElo, 1500); // 1350 + 150
    });

    test('Initializes as calibrated if totalRatedGamesCount is already >= 10 on start', () async {
      // Set initial state of battleground to 10 games
      fakeBattleground = FakeBattlegroundNotifier(FakeBattlegroundState(
        consolidatedRating: 1400,
        totalRatedGamesCount: 10,
      ));

      // Set repository saved state to mimic 10 calibration games played
      fakeRepository.savedState = AssignmentState(
        calibrationGamesPlayed: 10,
        lastResetDate: DateTime.now().subtract(const Duration(days: 1)),
      );

      final container = createContainer(isPremium: true);

      // Trigger initialization
      container.read(assignmentProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      final state = container.read(assignmentProvider);
      expect(state.isCalibrated, isTrue);
      expect(state.startElo, 1400);
      expect(state.goalElo, 1550);
    });

    test('Triggers calibration even if user is free (ungated calibration)', () async {
      final container = createContainer(isPremium: false);

      // Trigger initialization
      container.read(assignmentProvider);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(container.read(assignmentProvider).isCalibrated, isFalse);

      // Simulate reaching 10 games played on Battleground
      fakeBattleground.updateState(FakeBattlegroundState(
        consolidatedRating: 1350,
        totalRatedGamesCount: 10,
      ));

      // Wait for listener to process
      await Future.delayed(const Duration(milliseconds: 10));

      final state = container.read(assignmentProvider);
      // Should now be calibrated since calibration is no longer premium gated
      expect(state.isCalibrated, isTrue);
    });

    test('Allows Step 4 (Academy Pass) progress to accumulate even if Steps 1-3 are incomplete', () async {
      final container = createContainer(isPremium: true);
      final notifier = container.read(assignmentProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 20));

      // 1. Manually initialize assignment state to calibrated on Footsoldier (island index 0)
      notifier.state = notifier.state.copyWith(
        isCalibrated: true,
        startElo: 500,
        goalElo: 650,
        currentIslandIndex: 0,
        islandStepProgress: {
          0: [0, 0, 0, 0], // Steps 1, 2, 3, 4 all at 0
        },
      );

      // Generate active tasks to ensure dailyTasks is populated
      await notifier.generateActiveTasks(500, isNewDay: true);

      // 2. Identify the weekly chapter assigned for index 0 (Footsoldier range is chapters 1-8).
      final tutIndex = notifier.state.dailyTasks.indexWhere((t) => t.taskType == DailyTaskType.tutorial);
      expect(tutIndex, isNot(-1));
      final task = notifier.state.dailyTasks[tutIndex];
      final targetChapterId = int.tryParse(task.targetId);
      expect(targetChapterId, isNotNull);

      // 3. Simulate completion of the assigned chapter in tutorial progress, even though steps 1-3 are still at 0.
      fakeTutorial.updateState(FakeTutorialState(
        progress: FakeTutorialProgress(completedChapters: {targetChapterId!}),
        currentChapterIndex: targetChapterId,
        isChapterComplete: true,
      ));

      // Wait for listener to process
      await Future.delayed(const Duration(milliseconds: 20));

      // 4. Assert that the tutorial daily task is marked completed, and island step progress at index 3 is incremented.
      final stateAfter = container.read(assignmentProvider);
      final updatedTutTask = stateAfter.dailyTasks[tutIndex];
      expect(updatedTutTask.isCompleted, isTrue);

      final stepsProgress = stateAfter.islandStepProgress[0];
      expect(stepsProgress, isNotNull);
      expect(stepsProgress![3], 1); // Step 4 (index 3) must be incremented to 1
    });
  });
}
