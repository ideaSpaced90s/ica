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
    expect(container.read(storeProvider).subscriptionAccountId, isNull);

    await Future<void>.delayed(const Duration(milliseconds: 2));
    notifier.simulateUSDSubscription('monthly');
    final secondId = container.read(storeProvider).subscriptionAccountId;

    expect(secondId, isNotNull);
    expect(secondId, isNot(firstId));
  });
}
