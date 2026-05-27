import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/services/chess_sound_service.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

void main() {
  test('diagnose chess sound service', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    debugPrint('Initializing ChessSoundService...');
    final service = ChessSoundService();
    expect(service, isNotNull);
    
    // Wait for the asynchronous _initAudio to run/fail
    await Future.delayed(const Duration(seconds: 2));
    
    bool isInitialized = false;
    try {
      isInitialized = SoLoud.instance.isInitialized;
    } catch (e) {
      debugPrint('Could not query SoLoud.instance.isInitialized (probably due to missing native library in test environment): $e');
    }
    debugPrint('Sound Service initialized state: $isInitialized');
  });
}
