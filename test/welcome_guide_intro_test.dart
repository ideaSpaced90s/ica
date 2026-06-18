import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kingslayer_chess/features/chess/application/onboarding_provider.dart';
import 'package:kingslayer_chess/features/chess/application/tutorial_provider.dart';
import 'package:kingslayer_chess/features/chess/data/tutorial_progress_repository.dart';
import 'package:kingslayer_chess/features/chess/presentation/mobile_navigation_shell.dart';
import 'package:kingslayer_chess/features/chess/presentation/widgets/welcome_guide_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<TutorialProgressRepository> repoWithPrefs(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return TutorialProgressRepository(await SharedPreferences.getInstance());
  }

  test('intro seen state only persists for signed users', () async {
    final guestRepo = await repoWithPrefs({'user_is_google_signed_in': false});
    expect(guestRepo.shouldPersistIntroSeen(), isFalse);

    final signedRepo = await repoWithPrefs({'user_is_google_signed_in': true});
    expect(signedRepo.shouldPersistIntroSeen(), isTrue);
  });

  testWidgets('welcome guide advances through five steps before training', (tester) async {
    final repo = await repoWithPrefs({'user_is_google_signed_in': true});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tutorialProgressRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: WelcomeGuidePage(),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Begin Training'), findsNothing);
    expect(find.text('1/5'), findsOneWidget);

    for (var step = 1; step < 5; step++) {
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('${step + 1}/5'), findsOneWidget);
    }

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Continue'), findsNothing);
    expect(find.text('Begin Training'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
      listen: false,
    );
    expect(container.read(isOnboardingProvider), isTrue);
    expect(container.read(onboardingTargetChapterProvider), 1);
    expect(container.read(mobileNavIndexProvider), 7);
  });
}
