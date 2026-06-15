import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:kingslayer_chess/src/rust/api/pgn_db.dart' as rust_pgn;
import 'saved_game.dart';

class SavedGameRepository {
  Future<List<SavedGameEntry>> listSaves() async {
    try {
      final dbPath = await _getDbPath();
      final List<String> rawList = rust_pgn.loadAllGamesFromDb(dbPath: dbPath);

      final List<SavedGameEntry> saves = [];
      final Set<String> seenIds = {};

      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            var entry = SavedGameEntry.fromJson(decoded);
            if (seenIds.contains(entry.id)) {
              final newId = '${entry.id}_${saves.length}_${DateTime.now().microsecondsSinceEpoch}';
              entry = entry.copyWith(id: newId);
            }
            seenIds.add(entry.id);
            saves.add(entry);
          }
        } catch (_) {
          // Skip malformed/outdated entry gracefully
        }
      }
      saves.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return saves;
    } catch (_) {
      return [];
    }
  }

  Future<List<SavedGameEntry>> save(SavedGameEntry entry) async {
    try {
      final dbPath = await _getDbPath();
      final jsonData = jsonEncode(entry.toJson());
      rust_pgn.saveGameToDb(
        dbPath: dbPath,
        id: entry.id,
        savedAt: entry.savedAt.toIso8601String(),
        jsonData: jsonData,
      );
    } catch (_) {
      // Handle error gracefully
    }
    return listSaves();
  }

  Future<List<SavedGameEntry>> delete(String id) async {
    try {
      final dbPath = await _getDbPath();
      rust_pgn.deleteGameFromDb(dbPath: dbPath, id: id);
    } catch (_) {
      // Handle error gracefully
    }
    return listSaves();
  }

  Future<List<SavedGameEntry>> update(SavedGameEntry entry) async {
    return save(entry);
  }

  Future<void> clearAll() async {
    try {
      final dbPath = await _getDbPath();
      rust_pgn.clearAllGames(dbPath: dbPath);
    } catch (_) {
      // Handle error gracefully
    }
  }

  Future<void> writeAll(List<SavedGameEntry> entries) async {
    try {
      final dbPath = await _getDbPath();
      rust_pgn.clearAllGames(dbPath: dbPath);
      for (final entry in entries) {
        final jsonData = jsonEncode(entry.toJson());
        rust_pgn.saveGameToDb(
          dbPath: dbPath,
          id: entry.id,
          savedAt: entry.savedAt.toIso8601String(),
          jsonData: jsonData,
        );
      }
    } catch (_) {
      // Handle error gracefully
    }
  }

  Future<String> _getDbPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, 'ideaspace_games.db');
  }
}
