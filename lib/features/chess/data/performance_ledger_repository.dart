import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/performance_ledger_entry.dart';

class PerformanceLedgerRepository {
  static const _fileName = 'performance_ledger.json';

  Future<List<PerformanceLedgerEntry>> listEntries() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return [];
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) {
        return [];
      }

      final List<PerformanceLedgerEntry> entries = [];
      for (final item in decoded.whereType<Map>()) {
        try {
          entries.add(PerformanceLedgerEntry.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Skip malformed/outdated entry gracefully
        }
      }
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (_) {
      // If file is completely unreadable/corrupted, return empty list safely
      return [];
    }
  }

  Future<List<PerformanceLedgerEntry>> addEntry(PerformanceLedgerEntry entry) async {
    final entries = await listEntries();
    if (entries.any((e) => e.id == entry.id)) {
      return entries;
    }
    entries.insert(0, entry);
    await _writeAll(entries);
    return entries;
  }

  Future<void> clearAll() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _writeAll(List<PerformanceLedgerEntry> entries) async {
    final file = await _getFile();
    await file.parent.create(recursive: true);
    final payload = entries.map((entry) => entry.toJson()).toList();
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _fileName));
  }
}
