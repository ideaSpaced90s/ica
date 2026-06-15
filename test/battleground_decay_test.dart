import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kingslayer_chess/features/chess/application/battleground_provider.dart';
import 'package:kingslayer_chess/features/chess/data/stockfish_service.dart';
import 'package:kingslayer_chess/features/chess/services/chess_sound_service.dart';
import 'package:kingslayer_chess/features/chess/services/chess_haptics_service.dart';
import 'package:kingslayer_chess/features/chess/data/performance_ledger_repository.dart';
import 'package:kingslayer_chess/features/chess/data/saved_game_repository.dart';
import 'package:kingslayer_chess/features/chess/data/settings_repository.dart';
import 'package:kingslayer_chess/features/chess/domain/performance_ledger_entry.dart';
import 'package:kingslayer_chess/features/chess/data/saved_game.dart';
import 'package:kingslayer_chess/features/chess/application/chess_provider.dart';
import 'package:kingslayer_chess/features/chess/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeStockfishService extends Fake implements StockfishService {
  @override
  bool get isReady => true;
  @override
  Stream<String> get outputStream => const Stream.empty();
  @override
  Future<void> init() async {}
  @override
  Future<void> setSkillLevel(int level, {int multiPV = 1}) async {}
  @override
  Future<void> stopAnalysis() async {}
  @override
  Future<void> sendCommand(String command) async {}
  @override
  void dispose() {}
}

class FakeChessSoundService extends Fake implements ChessSoundService {
  @override
  void playSfx(SoundEffect sfx) {}
  @override
  void updateSettings({
    required bool sfxEnabled,
    required bool bgmEnabled,
    bool gameSoundEnabled = true,
    Map<String, bool> soundSettings = const {},
    bool academySoundEnabled = true,
    Map<String, bool> academySoundSettings = const {},
    bool isAcademyActive = false,
    bool isRatedMode = false,
  }) {}
}

class FakeChessHapticsService extends Fake implements ChessHapticsService {
  @override
  Future<void> selection() async {}
  @override
  void updateSettings({required bool hapticsEnabled}) {}
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
  Future<List<SavedGameEntry>> save(SavedGameEntry entry) async => [];
}

class TestSettingsRepository implements SettingsRepository {
  AppSettings loadedSettings;
  AppSettings? savedSettings;

  TestSettingsRepository(this.loadedSettings);

  @override
  Future<AppSettings> loadSettings() async {
    return loadedSettings;
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    savedSettings = settings;
    loadedSettings = settings;
  }
}

void main() {
  group('ELO Inactivity Decay and Calibration Tests', () {
    late FakeStockfishService fakeStockfish;
    late FakeSavedGameRepository fakeSavedGameRepo;
    late FakePerformanceLedgerRepository fakeLedgerRepo;
    late FakeChessSoundService fakeSoundService;
    late FakeChessHapticsService fakeHapticsService;

    setUp(() {
      fakeStockfish = FakeStockfishService();
      fakeSavedGameRepo = FakeSavedGameRepository();
      fakeLedgerRepo = FakePerformanceLedgerRepository();
      fakeSoundService = FakeChessSoundService();
      fakeHapticsService = FakeChessHapticsService();
    });

    test('Initializes as uncalibrated when rating games < 10', () async {
      final initialSettings = AppSettings(
        consolidatedRating: 1200,
        totalRatedGamesCount: 4,
        lastRatedGameTimestampMs: null,
      );
      final fakeSettingsRepo = TestSettingsRepository(initialSettings);

      final container = ProviderContainer(
        overrides: [
          stockfishServiceProvider.overrideWithValue(fakeStockfish),
          savedGameRepositoryProvider.overrideWithValue(fakeSavedGameRepo),
          performanceLedgerRepositoryProvider.overrideWithValue(fakeLedgerRepo),
          chessSoundServiceProvider.overrideWithValue(fakeSoundService),
          chessHapticsServiceProvider.overrideWithValue(fakeHapticsService),
          settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(battlegroundProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(notifier.state.isCalibrated, isFalse);
      expect(notifier.state.isCalibrating, isTrue);
      expect(notifier.state.calibrationGamesRemaining, 6);
    });

    test('Triggers decay and recalibration after 15 days of inactivity', () async {
      // 15 days ago timestamp
      final fifteenDaysAgo = DateTime.now().subtract(const Duration(days: 15)).millisecondsSinceEpoch;

      final initialSettings = AppSettings(
        consolidatedRating: 1200,
        totalRatedGamesCount: 15,
        lastRatedGameTimestampMs: fifteenDaysAgo,
        recalibrationGamesRemaining: 0,
        decayIntervalsApplied: 0,
      );
      final fakeSettingsRepo = TestSettingsRepository(initialSettings);

      final container = ProviderContainer(
        overrides: [
          stockfishServiceProvider.overrideWithValue(fakeStockfish),
          savedGameRepositoryProvider.overrideWithValue(fakeSavedGameRepo),
          performanceLedgerRepositoryProvider.overrideWithValue(fakeLedgerRepo),
          chessSoundServiceProvider.overrideWithValue(fakeSoundService),
          chessHapticsServiceProvider.overrideWithValue(fakeHapticsService),
          settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(battlegroundProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 10));

      // 15 days inactivity = 2 periods of 7 days = 20 points decay
      // Consolidated Elo should drop from 1200 to 1180
      expect(notifier.state.consolidatedRating, 1180);
      expect(notifier.state.isCalibrated, isFalse);
      expect(notifier.state.recalibrationGamesRemaining, 5);
      expect(notifier.state.decayIntervalsApplied, 2);

      // Verify settings were saved automatically with updated values
      expect(fakeSettingsRepo.savedSettings, isNotNull);
      expect(fakeSettingsRepo.savedSettings!.consolidatedRating, 1180);
      expect(fakeSettingsRepo.savedSettings!.recalibrationGamesRemaining, 5);
      expect(fakeSettingsRepo.savedSettings!.decayIntervalsApplied, 2);
    });

    test('Decay logic does not double-apply on multiple initializations', () async {
      final fifteenDaysAgo = DateTime.now().subtract(const Duration(days: 15)).millisecondsSinceEpoch;

      final initialSettings = AppSettings(
        consolidatedRating: 1180,
        totalRatedGamesCount: 15,
        lastRatedGameTimestampMs: fifteenDaysAgo,
        recalibrationGamesRemaining: 5,
        decayIntervalsApplied: 2, // Already applied 2 intervals
      );
      final fakeSettingsRepo = TestSettingsRepository(initialSettings);

      final container = ProviderContainer(
        overrides: [
          stockfishServiceProvider.overrideWithValue(fakeStockfish),
          savedGameRepositoryProvider.overrideWithValue(fakeSavedGameRepo),
          performanceLedgerRepositoryProvider.overrideWithValue(fakeLedgerRepo),
          chessSoundServiceProvider.overrideWithValue(fakeSoundService),
          chessHapticsServiceProvider.overrideWithValue(fakeHapticsService),
          settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
          authServiceProvider.overrideWithValue(FakeAuthService()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(battlegroundProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 10));

      // Rating should remain 1180, no new decay since decayIntervalsApplied matches the elapsed time
      expect(notifier.state.consolidatedRating, 1180);
      expect(notifier.state.recalibrationGamesRemaining, 5);
      expect(notifier.state.decayIntervalsApplied, 2);
    });
  });
}
