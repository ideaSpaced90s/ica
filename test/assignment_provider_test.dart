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
import 'package:kingslayer_chess/features/chess/services/play_games_sync_service.dart';

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

  FakeBattlegroundState({
    required this.consolidatedRating,
    required this.totalRatedGamesCount,
    this.cachedScotoma,
  });
}

class FakeBattlegroundNotifier extends StateNotifier<BattlegroundState> implements BattlegroundNotifier {
  FakeBattlegroundNotifier(super.state);

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

class FakePuzzlesNotifier extends StateNotifier<PuzzlesState> implements PuzzlesNotifier {
  FakePuzzlesNotifier(super.state);

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
  FakeTutorialState({required this.progress});
}

class FakeTutorialNotifier extends StateNotifier<TutorialState> implements TutorialNotifier {
  FakeTutorialNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRef extends Fake implements Ref {
  final Ref _realRef;
  FakeRef(this._realRef);

  @override
  T read<T>(ProviderListenable<T> provider) {
    try {
      return _realRef.read(provider);
    } catch (e) {
      if (T == ChessState || (provider as dynamic) == chessProvider) {
        return FakeChessState() as T;
      }
      if (T == ChessNotifier || (provider as dynamic) == chessProvider.notifier) {
        return FakeChessNotifier(FakeChessState()) as T;
      }
      rethrow;
    }
  }
}

class FakeChessState extends Fake implements ChessState {
  @override
  final String engineLevel;
  @override
  final String bottomAvatarId;

  FakeChessState({
    this.engineLevel = 'avatar_6',
    this.bottomAvatarId = 'avatar_6',
  });
}

class FakeChessNotifier extends StateNotifier<ChessState> implements ChessNotifier {
  FakeChessNotifier(super.state);

  @override
  Future<void> setEngineLevel(String level) async {}

  @override
  Future<void> setBottomAvatarId(String id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStoreNotifier extends StoreNotifier {
  bool _allowStateSet = false;

  FakeStoreNotifier(Ref ref, StoreState initialState) : super(FakeRef(ref), loadData: false) {
    _allowStateSet = true;
    state = initialState;
    _allowStateSet = false;
  }

  @override
  set state(StoreState value) {
    if (!mounted) return;
    if (_allowStateSet) {
      super.state = value;
    }
  }

  void updateState(StoreState newState) {
    _allowStateSet = true;
    state = newState;
    _allowStateSet = false;
  }
}

class FakePlayGamesSyncNotifier extends StateNotifier<PlayGamesSyncState> implements PlayGamesSyncNotifier {
  FakePlayGamesSyncNotifier() : super(PlayGamesSyncState());

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
          battlegroundProvider.overrideWith((ref) => fakeBattleground),
          puzzlesProvider.overrideWith((ref) => fakePuzzles),
          tutorialProvider.overrideWith((ref) => fakeTutorial),
          chessProvider.overrideWith((ref) => FakeChessNotifier(FakeChessState())),
          storeProvider.overrideWith((ref) {
            return FakeStoreNotifier(ref, createMockStoreState(isPremium: isPremium));
          }),
          googleDriveSyncProvider.overrideWith((ref) => FakePlayGamesSyncNotifier()),
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
  });
}
