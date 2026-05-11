import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'saved_game.dart';

class SavedGameRepository {
  static const _fileName = 'saved_games.json';

  Future<List<SavedGameEntry>> listSaves() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return const [];
    }

    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return const [];
    }

    final saves = decoded
        .whereType<Map>()
        .map((item) => SavedGameEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    saves.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return saves;
  }

  Future<List<SavedGameEntry>> save(SavedGameEntry entry) async {
    final saves = await listSaves();
    saves.insert(0, entry);
    await _writeAll(saves);
    return saves;
  }

  Future<List<SavedGameEntry>> delete(String id) async {
    final saves = await listSaves();
    saves.removeWhere((entry) => entry.id == id);
    await _writeAll(saves);
    return saves;
  }

  Future<List<SavedGameEntry>> update(SavedGameEntry entry) async {
    final saves = await listSaves();
    final index = saves.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      saves[index] = entry;
      await _writeAll(saves);
    }
    return saves;
  }

  Future<void> clearAll() async {
    final file = await _getFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _writeAll(List<SavedGameEntry> saves) async {
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
