import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;

class PuzzleRepository {
  String? _cachedDbPath;

  Future<String> getDatabasePath() async {
    if (_cachedDbPath != null) return _cachedDbPath!;

    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'lichess_puzzles_50k.db');
    final file = File(dbPath);

    if (!await file.exists()) {
      debugPrint('PuzzleRepository: Copying pre-populated database from assets...');
      try {
        final byteData = await rootBundle.load('assets/data/lichess_puzzles_50k.db');
        final bytes = byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
        await file.writeAsBytes(bytes, flush: true);
        debugPrint('PuzzleRepository: Database successfully copied to $dbPath');
      } catch (e) {
        debugPrint('PuzzleRepository: Failed to copy asset database: $e');
        rethrow;
      }
    }

    _cachedDbPath = dbPath;
    return dbPath;
  }

  Future<List<rust_puzzles.Puzzle>> searchPuzzles({
    String? theme,
    int? minRating,
    int? maxRating,
    int? limit,
  }) async {
    try {
      final path = await getDatabasePath();
      return await rust_puzzles.searchPuzzles(
        dbPath: path,
        theme: theme,
        minRating: minRating,
        maxRating: maxRating,
        limit: limit,
      );
    } catch (e) {
      debugPrint('PuzzleRepository: Query failed: $e');
      return [];
    }
  }

  Future<rust_puzzles.Puzzle?> getRandomPuzzle({
    int? minRating,
    int? maxRating,
  }) async {
    try {
      final path = await getDatabasePath();
      return await rust_puzzles.getRandomPuzzle(
        dbPath: path,
        minRating: minRating,
        maxRating: maxRating,
      );
    } catch (e) {
      debugPrint('PuzzleRepository: Get random puzzle failed: $e');
      return null;
    }
  }
}

final puzzleRepositoryProvider = Provider((ref) => PuzzleRepository());
