import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models/performance_analytics_cache.dart';

class PerformanceAnalyticsCacheRepository {
  static const _fileName = 'performance_analytics_cache.json';

  Future<PerformanceAnalyticsCache?> loadCache() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return null;
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return PerformanceAnalyticsCache.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCache(PerformanceAnalyticsCache cache) async {
    try {
      final file = await _getFile();
      await file.parent.create(recursive: true);
      final raw = jsonEncode(cache.toJson());
      await file.writeAsString(raw, flush: true);
    } catch (_) {
      // Fail silently
    }
  }

  Future<void> clearCache() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Fail silently
    }
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _fileName));
  }
}
