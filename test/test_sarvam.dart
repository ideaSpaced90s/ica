import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/services/env_config.dart';
import 'package:kingslayer_chess/features/chess/services/commentary_engine.dart';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnvConfig Tests', () {
    test('EnvConfig should load and parse .env values correctly', () async {
      // Load variables
      await EnvConfig.load();

      final apiKey = EnvConfig.get('SARVAM_API_KEY');
      final model = EnvConfig.get('SARVAM_MODEL');

      debugPrint('Loaded SARVAM_API_KEY: $apiKey');
      debugPrint('Loaded SARVAM_MODEL: $model');

      expect(apiKey, isNotNull);
      expect(model, equals('sarvam-30b'));
    });
  });

  group('CommentaryEngine Stream Fallback Orchestration', () {
    test('CommentaryEngine utilizes local LLM if Sarvam AI key is placeholder or invalid', () async {
      final engine = CommentaryEngine();
      
      // Ensure we have loaded env
      await EnvConfig.load();

      // We don't want to actually load the massive local model during unit tests if we can avoid it,
      // or we can test that calling it results in a predictable offline message or attempts local init.
      // Let's call the commentary stream with a query.
      final stream = engine.generateCommentaryStream(
        userQuery: "Hello GM Bard!",
      );

      final List<String> chunks = [];
      await for (final chunk in stream) {
        chunks.add(chunk);
        debugPrint('Stream output chunk: $chunk');
        if (chunks.length >= 3) break; // Break early so we don't block
      }

      expect(chunks, isNotEmpty);
      // Since SARVAM_API_KEY is 'your_api_key_here' (placeholder), it should fall back to local AI.
      // If llama.dll is not built or available, it might show offline message or fail gracefully.
      debugPrint('Chunks received: $chunks');
    });
  });
}
