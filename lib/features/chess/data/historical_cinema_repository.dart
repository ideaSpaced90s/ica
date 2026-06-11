import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../domain/models/historical_game.dart';

class HistoricalCinemaRepository {
  List<HistoricalGame>? _cache;

  Future<List<HistoricalGame>> loadAllGames() async {
    if (_cache != null) return _cache!;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/historical_cinema.json');
      final list = jsonDecode(jsonStr) as List;
      _cache = list.map((e) => HistoricalGame.fromJson(e as Map<String, dynamic>)).toList();
      return _cache!;
    } catch (e) {
      return [];
    }
  }

  Future<HistoricalGame?> pickGameForScotoma(
    String worstAxis,
    Set<int> alreadyAssigned,
  ) async {
    final all = await loadAllGames();
    if (all.isEmpty) return null;
    final targetCategory = _scotomaToCategory(worstAxis);
    
    // Filter to matching category, then exclude already-assigned IDs
    var pool = all.where((g) {
      final tag = _extractCategoryTag(g.category);
      return tag == targetCategory && !alreadyAssigned.contains(g.id);
    }).toList();
    
    if (pool.isEmpty) {
      // Fallback: ignore category, just find any unassigned game
      pool = all.where((g) => !alreadyAssigned.contains(g.id)).toList();
    }
    if (pool.isEmpty) {
      // Fallback 2: return any game (pool was completely exhausted)
      pool = all;
    }
    
    pool.shuffle();
    return pool.isNotEmpty ? pool.first : null;
  }

  String _extractCategoryTag(String categoryString) {
    final match = RegExp(r'cat_[a-z_]+').firstMatch(categoryString);
    return match != null ? match.group(0)! : 'cat_tactical';
  }

  String _scotomaToCategory(String axis) {
    switch (axis) {
      case 'kingSafety':       return 'cat_tactical';          // brutal attacks
      case 'knightForks':      return 'cat_tactical';          // knight combos
      case 'tunnelVision':     return 'cat_strategic_mastery'; // wide planning
      case 'timePanic':        return 'cat_tactical';          // precise quick play
      case 'materialGreed':    return 'cat_positional_squeeze';// sacrifice lessons
      case 'pinnedPieces':     return 'cat_endgame_precision'; // piece activity
      case 'diagonalRetreats': return 'cat_endgame_precision'; // bishop precision
      case 'horizontalSwings': return 'cat_endgame_precision'; // rook endings
      default:                 return 'cat_tactical';
    }
  }
}
