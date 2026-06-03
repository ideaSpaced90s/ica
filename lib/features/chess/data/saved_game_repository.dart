import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'saved_game.dart';

class SavedGameRepository {
  static const _fileName = 'saved_games.json';

  Future<List<SavedGameEntry>> listSaves() async {
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

      final List<SavedGameEntry> saves = [];
      final Set<String> seenIds = {};
      for (final item in decoded.whereType<Map>()) {
        try {
          var entry = SavedGameEntry.fromJson(Map<String, dynamic>.from(item));
          if (seenIds.contains(entry.id)) {
            final newId = '${entry.id}_${saves.length}_${DateTime.now().microsecondsSinceEpoch}';
            entry = entry.copyWith(id: newId);
          }
          seenIds.add(entry.id);
          saves.add(entry);
        } catch (_) {
          // Skip malformed/outdated entry gracefully
        }
      }
      saves.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return saves;
    } catch (_) {
      // If file is completely unreadable/corrupted, return empty list safely
      return [];
    }
  }

  Future<List<SavedGameEntry>> save(SavedGameEntry entry) async {
    final saves = await listSaves();
    final index = saves.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      saves[index] = entry;
    } else {
      saves.insert(0, entry);
    }
    await writeAll(saves);
    return saves;
  }

  Future<List<SavedGameEntry>> delete(String id) async {
    final saves = await listSaves();
    saves.removeWhere((entry) => entry.id == id);
    await writeAll(saves);
    return saves;
  }

  Future<List<SavedGameEntry>> update(SavedGameEntry entry) async {
    final saves = await listSaves();
    final index = saves.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      saves[index] = entry;
      await writeAll(saves);
    }
    return saves;
  }

  Future<void> clearAll() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> writeAll(List<SavedGameEntry> saves) async {
    final file = await _getFile();
    await file.parent.create(recursive: true);
    final payload = saves.map((entry) => entry.toJson()).toList();
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _fileName));
  }
}
