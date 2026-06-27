import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/application/store_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('ica_store_provider_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => tempDir.path,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('subscription account id is scoped to active premium cycle', () async {
    final container = ProviderContainer(
      overrides: [
        storeProvider.overrideWith(
          () => StoreNotifier(
            loadData: false,
            initializeBilling: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(storeProvider.notifier);

    notifier.simulateUSDSubscription('monthly');
    final firstId = container.read(storeProvider).subscriptionAccountId;

    expect(firstId, isNotNull);
    expect(firstId, startsWith('ICA-'));

    notifier.simulateUSDSubscription('monthly');
    expect(container.read(storeProvider).subscriptionAccountId, firstId);

    notifier.cancelSubscription();
    expect(container.read(storeProvider).isPremium, false);
    expect(container.read(storeProvider).subscriptionAccountId, firstId);

    await Future<void>.delayed(const Duration(milliseconds: 2));
    notifier.simulateUSDSubscription('monthly');
    final secondId = container.read(storeProvider).subscriptionAccountId;

    expect(secondId, isNotNull);
    expect(secondId, firstId);

    // Give time for fire-and-forget saveStore async I/O to finish before tearDown deletes tempDir
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  test('Persia theme is premium and locked by default, but can be purchased or unlocked via premium', () async {
    final container = ProviderContainer(
      overrides: [
        storeProvider.overrideWith(
          () => StoreNotifier(
            loadData: false,
            initializeBilling: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final storeNotifier = container.read(storeProvider.notifier);

    // Verify classic is free and unlocked
    expect(storeNotifier.isBoardThemePurchased('classic'), isTrue);

    // Verify Persia is not free and locked by default
    expect(storeNotifier.isBoardThemePurchased('sprite_persia'), isFalse);

    // Verify Persia is in premium cycle allocation
    storeNotifier.simulateUSDSubscription('monthly');
    expect(container.read(storeProvider).cycleThemeAllocation, contains('sprite_persia'));

    // Verify purchase unlocks Persia
    storeNotifier.purchaseBoardTheme('sprite_persia');
    expect(storeNotifier.isBoardThemePurchased('sprite_persia'), isTrue);

    // Give time for fire-and-forget saveStore async I/O to finish before tearDown deletes tempDir
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });
}
