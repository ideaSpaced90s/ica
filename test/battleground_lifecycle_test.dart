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
    return [entry];
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
  late ProviderContainer container;
  late BattlegroundNotifier notifier;
  late FakeArasanService fakeArasan;

  setUp(() {
    fakeArasan = FakeArasanService();
    container = ProviderContainer(
      overrides: [
        arasanServiceProvider.overrideWithValue(fakeArasan),
        savedGameRepositoryProvider.overrideWithValue(FakeSavedGameRepository()),
        performanceLedgerRepositoryProvider.overrideWithValue(FakePerformanceLedgerRepository()),
        chessSoundServiceProvider.overrideWithValue(FakeChessSoundService()),
        chessHapticsServiceProvider.overrideWithValue(FakeChessHapticsService()),
        settingsRepositoryProvider.overrideWithValue(FakeSettingsRepository()),
        authServiceProvider.overrideWithValue(FakeAuthService()),
        storeProvider.overrideWith(() => StoreNotifier(loadData: false, initializeBilling: false)),
      ],
    );
    notifier = container.read(battlegroundProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('Verify game pausing and resuming logic', () async {
    // 1. Reset match
    notifier.reset(forcedPlayerWhite: true);
    expect(notifier.state.isPaused, false);

    // 2. Start game services/clock ticker
    await notifier.ensureGameServicesStarted(analyzeCurrentPosition: false);
    // Since we are forcing a rated game or resetting it:
    // Let's start the match
    await notifier.startGame();
    expect(notifier.state.activeRatedMatchId, isNotNull);
    expect(notifier.state.isPaused, false);
    expect(notifier.state.clockStarted, true);

    // 3. Pause game
    notifier.pauseGame();
    expect(notifier.state.isPaused, true);
    
    // 4. Resume game
    notifier.resumeGame();
    expect(notifier.state.isPaused, false);
  });
}
