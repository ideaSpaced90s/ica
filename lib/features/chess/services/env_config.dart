import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class EnvConfig {
  static final Map<String, String> _env = {};
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    _loaded = true;

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
          final lines = await file.readAsLines();
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
          debugPrint('EnvConfig: Successfully loaded environment from $path');
          break; // Stop after first successful load
        } catch (e) {
          debugPrint('EnvConfig: Failed to read env from $path: $e');
        }
      }
    }
  }

  static String? get(String key) {
    return _env[key];
  }
}
