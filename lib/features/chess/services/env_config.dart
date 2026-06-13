import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

class EnvConfig {
  static final Map<String, String> _env = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

    // 1. Attempt to load from Flutter's rootBundle (for Android/iOS assets)
    try {
      final content = await rootBundle.loadString('.env');
      _parseEnvString(content);
      debugPrint('EnvConfig: Successfully loaded environment from rootBundle asset.');
      return;
    } catch (e) {
      debugPrint('EnvConfig: Asset load from rootBundle failed (expected on desktop dev or unit tests): $e');
    }

    // 2. Fallback to raw File loading (for desktop, development path, and unit tests)
    final potentialPaths = [
      '.env',
      'assets/.env',
      'C:\\Users\\Public\\Documents\\ideaspace\\kingslayer_flutter\\.env',
    ];

    // Try to get next to running executable (e.g. build/windows/x64/runner/Debug/.env)
    try {
      final exeDir = p.dirname(Platform.resolvedExecutable);
      potentialPaths.add(p.join(exeDir, '.env'));
    } catch (_) {}

    for (final path in potentialPaths) {
      final file = File(path);
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          _parseEnvString(content);
          debugPrint('EnvConfig: Successfully loaded environment from file path: $path');
          break; // Stop after first successful load
        } catch (e) {
          debugPrint('EnvConfig: Failed to read env from file path $path: $e');
        }
      }
    }
  }

  static void _parseEnvString(String content) {
    final lines = content.split(RegExp(r'\r?\n'));
    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final equalsIdx = line.indexOf('=');
      if (equalsIdx > 0) {
        final key = line.substring(0, equalsIdx).trim();
        final val = line.substring(equalsIdx + 1).trim();
        _env[key] = val;
      }
    }
  }

  static String? get(String key) {
    return _env[key];
  }
}
