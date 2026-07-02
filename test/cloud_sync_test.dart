import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:kingslayer_chess/features/chess/services/cloud_sync_service.dart';
import 'package:kingslayer_chess/features/chess/services/auth_service.dart';
import 'package:kingslayer_chess/features/chess/application/chess_provider.dart';
import 'package:kingslayer_chess/features/chess/application/store_provider.dart';
import 'package:kingslayer_chess/features/chess/data/saved_game.dart';
import 'package:kingslayer_chess/features/chess/data/saved_game_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kingslayer_chess/features/chess/data/tutorial_progress_repository.dart';
import 'package:kingslayer_chess/features/chess/application/tutorial_provider.dart';
import 'package:kingslayer_chess/features/chess/services/chess_sound_service.dart';

class MockUser extends Fake implements fb_auth.User {
  @override
  String get uid => 'test_user_id';
}

class MockAuthService extends Fake implements AuthService {
  @override
  fb_auth.User? get currentUser => MockUser();
}

class MockSavedGameRepository implements SavedGameRepository {
  List<SavedGameEntry> saves = [];

  @override
  Future<List<SavedGameEntry>> listSaves() async {
    return saves;
  }

  @override
  Future<void> writeAll(List<SavedGameEntry> entries) async {
    saves = List.from(entries);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTaskSnapshot extends Fake implements TaskSnapshot {}

class MockUploadTask extends Fake implements UploadTask {
  final Future<TaskSnapshot> _future = Future.value(FakeTaskSnapshot());

  @override
  Future<S> then<S>(FutureOr<S> Function(TaskSnapshot value) onValue, {Function? onError}) {
    return _future.then<S>(onValue, onError: onError);
  }

  @override
  Future<TaskSnapshot> whenComplete(FutureOr<dynamic> Function() action) {
    return _future.whenComplete(action);
  }
}

class MockReference extends Fake implements Reference {
  String? uploadedData;

  @override
  Reference child(String path) {
    return this;
  }

  @override
  UploadTask putString(
    String data, {
    PutStringFormat format = PutStringFormat.raw,
    SettableMetadata? metadata,
  }) {
    uploadedData = data;
    return MockUploadTask();
  }

  @override
  Future<Uint8List?> getData([int maxSize = 10485760]) async {
    if (uploadedData == null) {
      throw FirebaseException(
        plugin: 'storage',
        code: 'object-not-found',
      );
    }
    return Uint8List.fromList(utf8.encode(uploadedData!));
  }
}

class MockFirebaseStorage extends Fake implements FirebaseStorage {
  final MockReference mockRef = MockReference();

  @override
  Reference ref([String? path]) => mockRef;
}

class FakeChessState extends Fake implements ChessState {
  @override
  String get engineLevel => 'avatar_6';

  @override
  String get bottomAvatarId => 'avatar_6';

  @override
  String get boardThemeId => 'classic';

  @override
  bool get isBoardFlipped => false;

  @override
  bool get isPlayerWhite => true;

  @override
  String get gameMode => 'classic';

  @override
  bool get isSoundEnabled => true;

  @override
  bool get isMusicEnabled => false;

  @override
  bool get isGameSoundEnabled => true;

  @override
  Map<String, bool> get soundSettings => const {};

  @override
  bool get isAcademySoundEnabled => true;

  @override
  Map<String, bool> get academySoundSettings => const {};

  @override
  bool get isBattlegroundSoundEnabled => false;

  @override
  bool get isHapticsEnabled => true;
}

class FakeChessNotifier extends ChessNotifier {
  FakeChessNotifier();

  bool reloadSettingsCalled = false;

  @override
  ChessState build() {
    return FakeChessState();
  }

  @override
  Future<void> reloadSettings() async {
    reloadSettingsCalled = true;
  }

  @override
  Future<void> setEngineLevel(String level) async {}

  @override
  Future<void> setBottomAvatarId(String id) async {}
  @override
  Future<void> setBoardTheme(String themeId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChessSoundService extends Fake implements ChessSoundService {
  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late MockAuthService mockAuthService;
  late MockSavedGameRepository mockSavedGameRepo;
  late MockFirebaseStorage mockFirebaseStorage;
  late FakeChessNotifier fakeChessNotifier;
  late TutorialProgressRepository tutorialProgressRepo;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('ica_sync_test');
    
    // Set up path provider mock to return our temporary test directory
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );

    SharedPreferences.setMockInitialValues({});
    tutorialProgressRepo = TutorialProgressRepository(await SharedPreferences.getInstance());

    mockAuthService = MockAuthService();
    mockSavedGameRepo = MockSavedGameRepository();
    mockFirebaseStorage = MockFirebaseStorage();
    fakeChessNotifier = FakeChessNotifier();
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  test('Cloud Sync Backup and Restore properly syncs local saved games database', () async {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
        savedGameRepositoryProvider.overrideWithValue(mockSavedGameRepo),
        firebaseStorageProvider.overrideWithValue(mockFirebaseStorage),
        chessProvider.overrideWith(() => fakeChessNotifier),
        storeProvider.overrideWith(() => StoreNotifier(loadData: false)),
        tutorialProgressRepositoryProvider.overrideWithValue(tutorialProgressRepo),
        chessSoundServiceProvider.overrideWithValue(FakeChessSoundService()),
      ],
    );

    // 1. Populate the local repository database with a mock game save
    final testSave = SavedGameEntry(
      id: 'test_game_1',
      savedAt: DateTime.now(),
      fen: 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
      recentMoves: const ['e2e4'],
      isPlayerWhite: true,
      isBoardFlipped: false,
      whiteTimeLeftMs: 600000,
      blackTimeLeftMs: 600000,
      clockStarted: false,
      activeClockSide: 'white',
    );
    mockSavedGameRepo.saves = [testSave];

    // 2. Perform Cloud Backup
    final notifier = container.read(cloudSyncProvider.notifier);
    final backupResult = await notifier.backup();
    expect(backupResult, isTrue);

    // Verify that saved_games.json was written to disk
    final savedGamesFile = File('${tempDir.path}/saved_games.json');
    expect(savedGamesFile.existsSync(), isTrue);

    final fileContent = savedGamesFile.readAsStringSync();
    final List<dynamic> decodedFile = jsonDecode(fileContent);
    expect(decodedFile.length, 1);
    expect(decodedFile[0]['id'], 'test_game_1');

    // Verify that the payload uploaded to Firebase contains the saved games JSON
    final uploadedJson = mockFirebaseStorage.mockRef.uploadedData;
    expect(uploadedJson, isNotNull);

    final Map<String, dynamic> payload = jsonDecode(uploadedJson!);
    expect(payload.containsKey('saved_games'), isTrue);
    
    final savedGamesSyncString = payload['saved_games'] as String;
    final List<dynamic> syncedSaves = jsonDecode(savedGamesSyncString);
    expect(syncedSaves.length, 1);
    expect(syncedSaves[0]['id'], 'test_game_1');

    // 3. Clear local DB and local files to simulate a fresh install / recovery
    mockSavedGameRepo.saves = [];
    if (savedGamesFile.existsSync()) {
      savedGamesFile.deleteSync();
    }
    expect(mockSavedGameRepo.saves.isEmpty, isTrue);
    expect(savedGamesFile.existsSync(), isFalse);

    // 4. Perform Cloud Restore
    final restoreResult = await notifier.restore();
    expect(restoreResult, isTrue);

    // Verify that saved_games.json is written back to the filesystem
    expect(savedGamesFile.existsSync(), isTrue);

    // Verify that the games are successfully written back to our SQLite/Rust database
    expect(mockSavedGameRepo.saves.length, 1);
    expect(mockSavedGameRepo.saves[0].id, 'test_game_1');
    expect(mockSavedGameRepo.saves[0].recentMoves, const ['e2e4']);

    // Verify reloadSettings was called on the UI provider
    expect(fakeChessNotifier.reloadSettingsCalled, isTrue);
  });
}
