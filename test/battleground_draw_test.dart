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

  Future<void> makeGameMoves(List<List<String>> pairs) async {
    await notifier.ensureGameServicesStarted(analyzeCurrentPosition: false);
    for (final pair in pairs) {
      final from = pair[0];
      final to = pair[1];
      final turnWhite = notifier.state.game.fen.split(' ')[1] == 'w';
      final isPlayerTurn = notifier.state.isPlayerWhite == turnWhite;

      if (isPlayerTurn) {
        await notifier.makeMove(from, to);
      } else {
        fakeArasan.emitBestMove('$from$to');
      }
      await Future.delayed(const Duration(milliseconds: 30));
    }
  }

  test('Verify initial draw state and draw count increment', () async {
    notifier.reset(forcedPlayerWhite: true);
    expect(notifier.state.drawOffersCount, 0);
    expect(notifier.state.isDrawAgreed, false);

    // Call offerDraw - should fail because < 20 plies (10 moves) have been played
    final result = await notifier.offerDraw();
    expect(result, false);
    expect(notifier.state.drawOffersCount, 1);
  });

  test('Verify draw offer limit resets on new game', () async {
    notifier.reset(forcedPlayerWhite: true);
    await notifier.offerDraw();
    expect(notifier.state.drawOffersCount, 1);

    notifier.reset(forcedPlayerWhite: true);
    expect(notifier.state.drawOffersCount, 0);
  });

  test('Verify AI declines draw when move count is less than 20 plies', () async {
    notifier.reset(forcedPlayerWhite: true);
    
    // Play a few moves (6 plies)
    final moves = [
      ['e2', 'e4'], ['e7', 'e5'],
      ['g1', 'f3'], ['b8', 'c6'],
      ['f1', 'c4'], ['g8', 'f6']
    ];
    await makeGameMoves(moves);

    expect(notifier.state.recentMoves.length, 6);
    
    final result = await notifier.offerDraw();
    expect(result, false);
    expect(notifier.state.drawOffersCount, 1);
    expect(notifier.state.isDrawAgreed, false);
  });

  test('Verify AI accepts/declines based on evaluation when moves >= 20 plies', () async {
    notifier.reset(forcedPlayerWhite: true);
    
    // Setup a 20-ply game state by playing legal moves back and forth
    final moves = [
      ['e2', 'e4'], ['e7', 'e5'],
      ['g1', 'f3'], ['b8', 'c6'],
      ['a2', 'a3'], ['a7', 'a6'],
      ['h2', 'h3'], ['h7', 'h6'],
      ['d2', 'd3'], ['d7', 'd6'],
      ['b1', 'c3'], ['g8', 'f6'],
      ['b2', 'b3'], ['b7', 'b6'],
      ['g2', 'g3'], ['g7', 'g6'],
      ['f1', 'g2'], ['f8', 'g7'],
      ['c1', 'd2'], ['c8', 'd7']
    ];

    await makeGameMoves(moves);

    expect(notifier.state.recentMoves.length, 20);

    // Scenario A: Neutral/Balanced Evaluation (eval = 0.0)
    // AI has 0 contempt by default, so it accepts balanced position
    final result = await notifier.offerDraw();
    expect(result, true);
    expect(notifier.state.isDrawAgreed, true);
  });
}
