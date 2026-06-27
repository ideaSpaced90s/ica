import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kingslayer_chess/features/chess/application/arena_provider.dart';
import 'package:kingslayer_chess/features/chess/data/stockfish_service.dart';
import 'package:kingslayer_chess/features/chess/services/chess_sound_service.dart';
import 'package:kingslayer_chess/features/chess/services/chess_haptics_service.dart';
import 'package:kingslayer_chess/features/chess/data/saved_game_repository.dart';
import 'package:kingslayer_chess/features/chess/data/saved_game.dart';
import 'package:kingslayer_chess/features/chess/application/chess_provider.dart';
import 'package:kingslayer_chess/features/chess/data/settings_repository.dart';
import 'package:kingslayer_chess/features/chess/application/store_provider.dart';

class FakeStockfishService extends Fake implements StockfishService {
  final _controller = StreamController<String>.broadcast();

  @override
  bool get isReady => true;

  @override
  Stream<String> get outputStream => _controller.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #dispose) {
      return null;
    }
    return Future.value(null);
  }
}

class FakeChessSoundService extends Fake implements ChessSoundService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value(null);
  }
}

class FakeChessHapticsService extends Fake implements ChessHapticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value(null);
  }
}

class FakeSavedGameRepository extends Fake implements SavedGameRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #listSaves) {
      return Future.value(<SavedGameEntry>[]);
    }
    return Future.value(null);
  }
}

class FakeSettingsRepository extends Fake implements SettingsRepository {
  AppSettings _settings = AppSettings();

  @override
  Future<AppSettings> loadSettings({bool forceReload = false}) async {
    return _settings;
  }
  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
  @override
  Future<AppSettings> updateSettings(
    AppSettings Function(AppSettings current) updater,
  ) async {
    _settings = updater(_settings);
    return _settings;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Verify undo after timeout resets isTimeOut and isGameOverDismissed', () async {
    final fakeStockfish = FakeStockfishService();
    final fakeSavedGameRepo = FakeSavedGameRepository();
    final fakeSoundService = FakeChessSoundService();
    final fakeHapticsService = FakeChessHapticsService();
    final fakeSettingsRepo = FakeSettingsRepository();

    final container = ProviderContainer(
      overrides: [
        stockfishServiceProvider.overrideWithValue(fakeStockfish),
        savedGameRepositoryProvider.overrideWithValue(fakeSavedGameRepo),
        chessSoundServiceProvider.overrideWithValue(fakeSoundService),
        chessHapticsServiceProvider.overrideWithValue(fakeHapticsService),
        settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
        storeProvider.overrideWith(() => StoreNotifier(loadData: false, initializeBilling: false)),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(arenaProvider.notifier);

    // Start Arena game and await service startup
    notifier.reset(forcedPlayerWhite: true);
    await notifier.ensureGameServicesStarted(analyzeCurrentPosition: false);
    
    // Play a move so we have a snapshot to undo to
    await notifier.makeMove('e2', 'e4');
    expect(notifier.state.isTimeOut, isFalse);
    expect(notifier.state.canUndo, isTrue);

    // Simulate timeout by manually setting state.isTimeOut and state.isGameOverDismissed
    notifier.state = notifier.state.copyWith(
      isTimeOut: true,
      isGameOverDismissed: false,
    );
    expect(notifier.state.isTimeOut, isTrue);
    expect(notifier.state.isGameOverDismissed, isFalse);

    // Dismiss game over overlay (mimic clicking "BACK TO BOARD")
    notifier.dismissGameOver();
    expect(notifier.state.isGameOverDismissed, isTrue);

    // Trigger Undo (revert move)
    notifier.undo();

    // Verify that the timeout state is reset, and the user is back to active play state
    expect(notifier.state.isTimeOut, isFalse);
    expect(notifier.state.isGameOverDismissed, isFalse);

    // Allow pending async microtasks to settle before disposing container
    await Future.delayed(const Duration(milliseconds: 500));
  });

  test('Verify isEngineThinking shows up immediately when AI goes first on game start or board flip', () async {
    final fakeStockfish = FakeStockfishService();
    final fakeSavedGameRepo = FakeSavedGameRepository();
    final fakeSoundService = FakeChessSoundService();
    final fakeHapticsService = FakeChessHapticsService();
    final fakeSettingsRepo = FakeSettingsRepository();

    final container = ProviderContainer(
      overrides: [
        stockfishServiceProvider.overrideWithValue(fakeStockfish),
        savedGameRepositoryProvider.overrideWithValue(fakeSavedGameRepo),
        chessSoundServiceProvider.overrideWithValue(fakeSoundService),
        chessHapticsServiceProvider.overrideWithValue(fakeHapticsService),
        settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
        storeProvider.overrideWith(() => StoreNotifier(loadData: false, initializeBilling: false)),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(arenaProvider.notifier);

    // Case 1: Start a new game as Black, meaning AI goes first.
    // The thinking indicator (isEngineThinking) should be true immediately.
    notifier.reset(forcedPlayerWhite: false);
    expect(notifier.state.isEngineThinking, isTrue);

    // Reset back to player playing White (AI turn is false).
    notifier.reset(forcedPlayerWhite: true);
    expect(notifier.state.isEngineThinking, isFalse);

    // Case 2: Toggle/flip the board orientation when it is the first move.
    // Flipping makes the player Black and the AI White (so AI's turn immediately).
    // The thinking indicator (isEngineThinking) should become true immediately.
    notifier.toggleBoardOrientation();
    expect(notifier.state.isEngineThinking, isTrue);

    await Future.delayed(const Duration(milliseconds: 500));
  });
}
