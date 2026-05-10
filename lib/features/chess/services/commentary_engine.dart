import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CommentaryEngine {
  bool isInitialized = false;
  bool isInitializing = false;
  bool isGenerating = false;
  String? lastError;

  // The High Council's Bridge to the Backend
  static const String _backendUrl = 'http://127.0.0.1:8000/generate_commentary';
  static const String _healthCheckUrl = 'http://127.0.0.1:8000/';

  Future<void> initialize() async {
    if (isInitialized || isInitializing) return;
    
    isInitializing = true;
    debugPrint('CommentaryEngine: Seeking the High Council via Local Backend...');
    
    try {
      // Check if backend is running
      final uri = Uri.parse(_healthCheckUrl);
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        debugPrint('CommentaryEngine: Backend Council reached.');
        isInitialized = true;
      } else {
        throw Exception('Backend returned ${response.statusCode}');
      }
    } catch (error) {
       lastError = 'Backend unreachable. Ensure your Python council is running.';
       debugPrint('CommentaryEngine: Failed to reach Backend: $error');
       isInitialized = false; 
    } finally {
      isInitializing = false;
    }
  }

  /// Generates commentary by consulting the local Python backend
  Stream<String> generateCommentaryStream({
    String? player,
    String? move,
    String? evalScore,
    String? structuredPrompt,
    String? userQuery,
  }) async* {
    if (!isInitialized) {
      await initialize();
    }

    if (!isInitialized) {
      debugPrint('CommentaryEngine: Fallback to Grandmaster Classic Voice.');
      final classic = _generateClassicCommentary(move ?? '', player: player ?? 'Unknown');
      final words = classic.split(' ');
      String current = '';
      for (var i = 0; i < words.length; i++) {
        current += (i == 0 ? '' : ' ') + words[i];
        yield current;
        await Future.delayed(const Duration(milliseconds: 30));
      }
      return;
    }

    isGenerating = true;
    lastError = null;

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'player': player ?? 'Unknown',
          'move': move ?? 'Unknown',
          'eval_score': evalScore ?? '0.0',
          'history': structuredPrompt ?? '',
          'user_query': userQuery ?? '',
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final commentary = data['commentary'] as String;
        
        // Split into "pseudo-chunks" to maintain the typing effect in the UI
        // We yield the FULL string so far, so the consumer should REPLACE, not APPEND.
        final words = commentary.split(' ');
        String current = '';
        for (var i = 0; i < words.length; i++) {
          current += (i == 0 ? '' : ' ') + words[i];
          yield current;
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } else {
        debugPrint('Backend API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Council Response Error: ${response.statusCode}');
      }
    } catch (error) {
      lastError = 'The Council remains silent.';
      debugPrint('CommentaryEngine: Request failed: $error');
      final classic = _generateClassicCommentary(move ?? '', player: player ?? 'Unknown');
      final words = classic.split(' ');
      String current = '';
      for (var i = 0; i < words.length; i++) {
        current += (i == 0 ? '' : ' ') + words[i];
        yield current;
        await Future.delayed(const Duration(milliseconds: 30));
      }
    } finally {
      isGenerating = false;
    }
  }

  Future<String> generateCommentary({
    required String player,
    required String move,
    required String evalScore,
    String? structuredPrompt,
  }) async {
    String lastChunk = '';
    await for (final chunk in generateCommentaryStream(
      player: player,
      move: move,
      evalScore: evalScore,
      structuredPrompt: structuredPrompt,
    )) {
      lastChunk = chunk;
    }
    return lastChunk;
  }

  Future<void> dispose() async {
    isInitialized = false;
  }

  String _generateClassicCommentary(String move, {required String player}) {
    if (move.isEmpty) return 'The board awaits your first command.';
    
    final isCapture = move.contains('x');
    final isCheck = move.contains('+');
    final isCheckmate = move.contains('#');
    
    String description = '';
    if (move.startsWith('N')) {
      description = 'The Knight leaps';
    } else if (move.startsWith('B')) {
      description = 'The Bishop glides';
    } else if (move.startsWith('R')) {
      description = 'The Rook marches';
    } else if (move.startsWith('Q')) {
      description = 'The Queen enters the fray';
    } else if (move.startsWith('K')) {
      description = 'The King repositioned';
    } else {
      description = 'The Pawn advances';
    }

    if (isCheckmate) return 'Checkmate! $player has claimed final victory with a masterful move.';
    if (isCheck) return 'Check! $player puts the King in grave danger with $move.';
    if (isCapture) return 'A calculated strike! $player captures a piece on the field.';
    
    final templates = [
      'The board trembles. $player commands $move with clinical precision.',
      'A shadowy maneuver! $move repositioned, casting a long shadow over the center.',
      'The metal echoes. $player $description, a play that reeks of cold ambition.',
      '$description to ${move.substring(move.length - 2)}. The center is now a fortress of will.',
      'Unexpected! $player strikes with $move, a move the Council did not foresee.',
      'Classic development. $player fortifies the position, one square at a time.',
      'The strategy deepens. By moving $move, $player invites a storm of complexity.',
      'A silent advance. $description slips into position, waiting for the killing blow.',
      'Masterful positioning. The move $move signals the end of the beginning.',
      'The pieces are alive tonight! $player $description, weaving a web of steel.',
      'Tactical brilliance! $move is a stone cast into a dark pond. Watch the ripples.',
      'Conservative yet firm. $player holds the line, refusing to yield a single inch.',
    ];
    
    // Use the move's character codes to pick a "random" but consistent template for that move
    final seed = move.runes.fold(0, (a, b) => a + b);
    final index = seed % templates.length;
    return templates[index];
  }
}

