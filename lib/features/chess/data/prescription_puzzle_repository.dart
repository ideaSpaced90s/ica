import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;

enum ScotomaAxis {
  dgb, // diagonalRetreats
  hrz, // horizontalSwings
  knf, // knightForks
  tmp, // timePanic
  grd, // materialGreed
  tnl, // tunnelVision
  pin, // pinnedPieces
  ksb, // kingSafety
  balanced,
}

class PrescriptionPuzzleRepository {
  // Cache the JSON file parsed structures to prevent reloading from assets repeatedly
  final Map<String, dynamic> _fileCache = {};
  
  // Track already seen puzzle IDs in this session to prevent direct duplicates
  final Set<String> _seenPuzzleIds = {};

  // Filenames for the 8 scotoma axes
  static const Map<ScotomaAxis, String> _axisFileMap = {
    ScotomaAxis.dgb: 'long_diagonal_dgb.json',
    ScotomaAxis.hrz: 'lateral_sweeps_hrz.json',
    ScotomaAxis.knf: 'knight_vision_knf.json',
    ScotomaAxis.tmp: 'speed_vision_tmp.json',
    ScotomaAxis.grd: 'poisoned_apple_grd.json',
    ScotomaAxis.tnl: 'board_wide_tnl.json',
    ScotomaAxis.pin: 'unpinning_the_mind_pin.json',
    ScotomaAxis.ksb: 'king_radar_ksb.json',
  };

  // Filenames for balanced tiers
  static const Map<int, String> _balancedFileMap = {
    1: 'balanced_tier_1.json', // Beginner (< 1200)
    2: 'balanced_tier_2.json', // Intermediate (1200 - 1800)
    3: 'balanced_tier_3.json', // Advanced (> 1800)
  };

  // Maps ELO rating to one of the 3 tiers: 1 (Beginner), 2 (Intermediate), 3 (Advanced)
  int getTierByElo(int elo) {
    if (elo < 1200) return 1;
    if (elo <= 1800) return 2;
    return 3;
  }

  // Load and parse JSON file from assets
  Future<dynamic> _loadJsonFile(String fileName) async {
    if (_fileCache.containsKey(fileName)) {
      return _fileCache[fileName];
    }
    
    try {
      final jsonString = await rootBundle.loadString('assets/prescriptions/$fileName');
      final data = json.decode(jsonString);
      _fileCache[fileName] = data;
      return data;
    } catch (e) {
      debugPrint('PrescriptionPuzzleRepository: Failed to load asset $fileName: $e');
      rethrow;
    }
  }

  // Clear seen puzzles cache (e.g. on new session or when exhausted)
  void clearSeenHistory() {
    _seenPuzzleIds.clear();
  }

  // Get a prescription puzzle based on the axis and the player's current chess ELO
  Future<rust_puzzles.Puzzle?> getPrescriptionPuzzle({
    required ScotomaAxis axis,
    required int playerElo,
  }) async {
    final rand = Random();
    final tier = getTierByElo(playerElo);

    List<dynamic> puzzlesList = [];

    if (axis == ScotomaAxis.balanced) {
      final fileName = _balancedFileMap[tier] ?? 'balanced_tier_2.json';
      final dynamic data = await _loadJsonFile(fileName);
      if (data is List) {
        puzzlesList = data;
      }
    } else {
      final fileName = _axisFileMap[axis];
      if (fileName == null) return null;

      final dynamic data = await _loadJsonFile(fileName);
      if (data is Map<String, dynamic>) {
        final tierKey = 'tier_${tier}_${tier == 1 ? 'beginner' : tier == 2 ? 'intermediate' : 'advanced'}';
        final dynamic list = data[tierKey];
        if (list is List) {
          puzzlesList = list;
        }
      }
    }

    if (puzzlesList.isEmpty) {
      debugPrint('PrescriptionPuzzleRepository: No puzzles found for axis $axis and tier $tier');
      return null;
    }

    // Filter out already seen puzzles to ensure uniqueness, fallback if all seen
    var candidates = puzzlesList.where((p) {
      final id = p['PuzzleId']?.toString();
      return id != null && !_seenPuzzleIds.contains(id);
    }).toList();

    if (candidates.isEmpty) {
      debugPrint('PrescriptionPuzzleRepository: All candidates seen for axis $axis, resetting seen history');
      _seenPuzzleIds.clear();
      candidates = puzzlesList;
    }

    // Pick a random puzzle
    final selectedJson = candidates[rand.nextInt(candidates.length)];
    final puzzleId = selectedJson['PuzzleId']?.toString() ?? 'unknown';
    _seenPuzzleIds.add(puzzleId);

    // Parse Moves: space-separated UCI string -> List<String>
    final movesString = selectedJson['Moves']?.toString() ?? '';
    final movesList = movesString.split(' ').where((m) => m.isNotEmpty).toList();

    return rust_puzzles.Puzzle(
      id: puzzleId,
      fen: selectedJson['FEN']?.toString() ?? '',
      moves: movesList,
      rating: selectedJson['Rating'] is int ? selectedJson['Rating'] as int : int.parse(selectedJson['Rating'].toString()),
      themes: selectedJson['Themes']?.toString() ?? '',
    );
  }
}

final prescriptionPuzzleRepositoryProvider = Provider((ref) => PrescriptionPuzzleRepository());
