import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

/// Helper class to handle copying and locating the Arasan NNUE network file on Android.
class ArasanSetup {
  static String? _cachedNnuePath;

  static Future<String> getNnuePath() async {
    if (_cachedNnuePath != null) {
      return _cachedNnuePath!;
    }

    final docDir = await getApplicationDocumentsDirectory();
    final localPath = p.join(docDir.path, 'arasanv8-20260622.nnue');
    final localFile = File(localPath);

    // If file doesn't exist, copy it from assets
    if (!await localFile.exists()) {
      debugPrint('ArasanSetup: Copying NNUE network file from assets...');
      try {
        final data = await rootBundle.load('assets/data/arasanv8-20260622.nnue');
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await localFile.writeAsBytes(bytes, flush: true);
        debugPrint('ArasanSetup: NNUE network file successfully copied.');
      } catch (e) {
        debugPrint('ArasanSetup: Failed to copy NNUE file from assets: $e');
        rethrow;
      }
    } else {
      debugPrint('ArasanSetup: NNUE network file already exists at $localPath');
    }

    _cachedNnuePath = localPath;
    return localPath;
  }
}
