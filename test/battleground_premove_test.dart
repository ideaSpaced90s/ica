import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kingslayer_chess/features/chess/application/battleground_provider.dart';
import 'package:kingslayer_chess/features/chess/data/arasan_service.dart';
import 'package:kingslayer_chess/features/chess/services/chess_sound_service.dart';
import 'package:kingslayer_chess/features/chess/services/chess_haptics_service.dart';
import 'package:kingslayer_chess/features/chess/data/performance_ledger_repository.dart';
import 'package:kingslayer_chess/features/chess/data/saved_game_repository.dart';
import 'package:kingslayer_chess/features/chess/data/settings_repository.dart';
import 'package:kingslayer_chess/features/chess/domain/performance_ledger_entry.dart';
import 'package:kingslayer_chess/features/chess/data/saved_game.dart';
import 'package:kingslayer_chess/features/chess/application/chess_provider.dart';
import 'package:kingslayer_chess/features/chess/application/store_provider.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:kingslayer_chess/features/chess/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeArasanService extends Fake implements ArasanService {
  final _controller = StreamController<String>.broadcast();

  @override
  bool get isReady => true;

  @override
  Stream<String> get outputStream => _controller.stream;

  void emitBestMove(String move) {
    _controller.add('bestmove $move');
  }

  @override
  Future<void> init() async {}
  @override
  Future<void> setSkillLevel(int level, {int multiPV = 1}) async {}
  @override
  Future<void> setChess960Mode(bool isEnabled) async {}
  @override
  Future<void> stopAnalysis() async {}
  @override
  Future<void> sendCommand(String command) async {
    if (command.trim() == 'isready') {
      _controller.add('readyok');
    }
  }
  @override
  Future<void> analyzePosition(
    String fen, {
    int depth = 15,
    Duration? wTime,
    Duration? bTime,
    Duration? wInc,
    Duration? bInc,
  }) async {}

  @override
  void dispose() {}
}

class FakeChessSoundService extends Fake implements ChessSoundService {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class FakeChessHapticsService extends Fake implements ChessHapticsService {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class FakeAuthService extends Fake implements AuthService {
  @override
  User? get currentUser => null;
  @override
  bool get isPlayGamesUser => false;
}

class FakePerformanceLedgerRepository extends Fake implements PerformanceLedgerRepository {
  @override
  Future<List<PerformanceLedgerEntry>> listEntries() async => [];
}

class FakeSavedGameRepository extends Fake implements SavedGameRepository {
  @override
  Future<List<SavedGameEntry>> save(SavedGameEntry entry) async {
    return [];
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
  test('Verify pre-move setup and auto-execution after bot move', () async {
    final fakeArasan = FakeArasanService();
    final fakeSavedGameRepo = FakeSavedGameRepository();
    final fakeLedgerRepo = FakePerformanceLedgerRepository();
    final fakeSoundService = FakeChessSoundService();
    final fakeHapticsService = FakeChessHapticsService();
    final fakeSettingsRepo = FakeSettingsRepository();

    final container = ProviderContainer(
      overrides: [
        arasanServiceProvider.overrideWithValue(fakeArasan),
        savedGameRepositoryProvider.overrideWithValue(fakeSavedGameRepo),
        performanceLedgerRepositoryProvider.overrideWithValue(fakeLedgerRepo),
        chessSoundServiceProvider.overrideWithValue(fakeSoundService),
        chessHapticsServiceProvider.overrideWithValue(fakeHapticsService),
        settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        storeProvider.overrideWith(() => StoreNotifier(loadData: false, initializeBilling: false)),
      ],
    );
    addTearDown(container.dispose);

    // Get the Battleground notifier from the container
    final notifier = container.read(battlegroundProvider.notifier);

    // Initialize with White player turn
    notifier.reset(forcedPlayerWhite: true);
    await notifier.ensureGameServicesStarted(analyzeCurrentPosition: false);
    
    // 1. Play first player move: e2e4
    await notifier.makeMove('e2', 'e4');
    expect(notifier.state.game.turn, chess_lib.Color.BLACK); // Now Black's turn (bot's turn)
    expect(notifier.state.premoveFrom, isNull);

    // 2. Queue player's pre-move: g1f3 (during bot's turn)
    await notifier.makeMove('g1', 'f3');
    expect(notifier.state.premoveFrom, 'g1');
    expect(notifier.state.premoveTo, 'f3');
    expect(notifier.state.game.turn, chess_lib.Color.BLACK); // Still Black's turn

    // 3. Emit bot move: d7d5
    fakeArasan.emitBestMove('d7d5');

    // Wait for the asynchronous events and delayed pre-move execution (300ms)
    await Future.delayed(const Duration(milliseconds: 500));

    // Verify that the pre-move has executed!
    // Since White played g1f3 after Black played d7d5, it should be Black's turn now.
    expect(notifier.state.game.turn, chess_lib.Color.BLACK);
    // And the move history should contain both d7d5 and g1f3!
    expect(notifier.state.uciMoves, containsAll(['e2e4', 'd7d5', 'g1f3']));
  });
}
