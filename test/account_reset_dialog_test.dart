import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kingslayer_chess/features/chess/presentation/account_page.dart';
import 'package:kingslayer_chess/features/chess/application/chess_provider.dart';
import 'package:kingslayer_chess/features/chess/application/store_provider.dart';
import 'package:kingslayer_chess/features/chess/services/auth_service.dart';
import 'package:kingslayer_chess/features/chess/services/chess_sound_service.dart';
import 'package:kingslayer_chess/features/chess/services/chess_haptics_service.dart';
import 'package:kingslayer_chess/features/chess/services/cloud_sync_service.dart';
import 'package:kingslayer_chess/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeAuthService extends Fake implements AuthService {
  @override
  User? get currentUser => null;
  @override
  bool get isPlayGamesUser => false;
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
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}

class FakeCloudSyncNotifier extends CloudSyncNotifier {
  FakeCloudSyncNotifier();

  @override
  Future<bool> backup({bool silent = false}) async {
    return true;
  }

  @override
  Future<bool> restore() async {
    return true;
  }
}

void main() {
  testWidgets('AccountPage Reset Progress Dialog test', (WidgetTester tester) async {
    // Initialize mock SharedPreferences as required by the app initialization
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();

    // Build AccountPage within a ProviderScope and MaterialApp with mocked dependencies
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(FakeAuthService()),
          chessSoundServiceProvider.overrideWithValue(FakeChessSoundService()),
          chessHapticsServiceProvider.overrideWithValue(FakeChessHapticsService()),
          cloudSyncProvider.overrideWith(() => FakeCloudSyncNotifier()),
          storeProvider.overrideWith(() => StoreNotifier(loadData: false)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: AccountPage(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    // Drag CustomScrollView down to make 'Reset Progress' visible
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1000));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify AccountPage 'Reset Progress' tile is rendered and visible
    final resetProgressTextFinder = find.text('Reset Progress');
    expect(resetProgressTextFinder, findsOneWidget);

    // Tap the 'Reset Progress' button
    await tester.tap(resetProgressTextFinder);
    await tester.pump(const Duration(milliseconds: 500));

    // Verify that the Reset Confirmation Dialog is shown
    expect(find.text('Reset All Progress?'), findsOneWidget);
    expect(find.text('To confirm, type "reset" below:'), findsOneWidget);

    // Locate the 'RESET ALL' button and verify it is disabled initially
    final buttonFinder = find.widgetWithText(FilledButton, 'RESET ALL');
    expect(buttonFinder, findsOneWidget);
    
    FilledButton button = tester.widget<FilledButton>(buttonFinder);
    expect(button.onPressed, isNull, reason: 'RESET ALL button should be disabled initially');

    // Type something other than 'reset' and check that it's still disabled
    await tester.enterText(find.byType(TextField), 'notreset');
    await tester.pump(const Duration(milliseconds: 500));
    
    button = tester.widget<FilledButton>(buttonFinder);
    expect(button.onPressed, isNull, reason: 'RESET ALL button should be disabled for incorrect input');

    // Type 'reset' (lowercase) and verify button is enabled
    await tester.enterText(find.byType(TextField), 'reset');
    await tester.pump(const Duration(milliseconds: 500));

    button = tester.widget<FilledButton>(buttonFinder);
    expect(button.onPressed, isNotNull, reason: 'RESET ALL button should be enabled when "reset" is entered');

    // Tap the enabled 'RESET ALL' button
    await tester.tap(buttonFinder);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify the dialog is closed
    expect(find.text('Reset All Progress?'), findsNothing);
  });
}
