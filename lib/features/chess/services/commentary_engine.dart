import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;
import 'package:kingslayer_chess/src/rust/api/commentary.dart' as rust_commentary;
import 'package:kingslayer_chess/src/rust/api/tactics.dart';
import '../data/puzzle_repository.dart';
import '../domain/models/position_context.dart';

class CommentaryEngine {
  bool isInitialized = true;
  bool isInitializing = false;
  bool isGenerating = false;
  String? lastError;
  String? systemInstruction;
  void Function(rust_puzzles.Puzzle puzzle)? onPuzzleLoaded;

  Future<void> initialize() async {
    isInitialized = true;
    isInitializing = false;
    lastError = null;
    debugPrint('CommentaryEngine: Deterministic Engine initialized.');
  }

  /// Extracts the piece name from the moveDescription
  String _extractPiece(String moveDesc) {
    if (moveDesc.contains('castles')) return 'King';
    if (moveDesc.contains('en passant')) return 'Pawn';
    
    // Check if it's "moves {Piece} to"
    final movesMatch = RegExp(r'moves\s+(\w+)\s+to').firstMatch(moveDesc);
    if (movesMatch != null) return movesMatch.group(1)!;
    
    // Check if it's "'s {Piece} captures"
    final capturesMatch = RegExp(r"'s\s+(\w+)\s+captures").firstMatch(moveDesc);
    if (capturesMatch != null) return capturesMatch.group(1)!;
    
    // Check if it's "places a {Piece} on"
    final placesMatch = RegExp(r'places\s+a\s+(\w+)\s+on').firstMatch(moveDesc);
    if (placesMatch != null) return placesMatch.group(1)!;
    
    return 'piece';
  }

  /// Generates commentary using the deterministic Rust Engine and Dart parameter replacement
  Stream<String> generateCommentaryStream({
    String? player,
    String? move,
    String? evalScore,
    PositionContext? context,
    String? previousQuality,
    String? userQuery,
    String? structuredPrompt,
    String? userName,
    String? tacticsBaseFen,
    List<String>? tacticsSequence,
  }) async* {
    final isTacticsQuery = userQuery?.startsWith('[TACTICS_QUERY]') ?? false;
    if (isTacticsQuery) {
      if (tacticsBaseFen == null || tacticsSequence == null) {
        yield 'Apprentice, the tactical sequence could not be retrieved from the board.';
        return;
      }
      yield 'GM Chanakya is examining the proposed variations...';
      try {
        final result = generateTacticsAnalysis(
          fen: tacticsBaseFen,
          userUciMoves: tacticsSequence,
        );
        yield result.textResponse;
      } catch (e) {
        yield 'I encountered an error calculating the tactics: $e';
      }
      return;
    }

    final query = userQuery?.toLowerCase() ?? '';
    final isPuzzleRequest = query.contains('puzzle') || query.contains('train') || query.contains('exercise');
    if (isPuzzleRequest) {
      yield 'GM Chanakya is consulting the puzzle archives...';
      
      final repo = PuzzleRepository();
      rust_puzzles.Puzzle? selectedPuzzle;
      
      String? theme;
      if (query.contains('fork')) {
        theme = 'fork';
      } else if (query.contains('pin')) {
        theme = 'pin';
      } else if (query.contains('mate')) {
        theme = 'mate';
      } else if (query.contains('skewer')) {
        theme = 'skewer';
      } else if (query.contains('endgame')) {
        theme = 'endgame';
      }
      
      int? minR;
      int? maxR;
      if (query.contains('easy') || query.contains('beginner')) {
        minR = 600;
        maxR = 1200;
      } else if (query.contains('hard') || query.contains('advanced') || query.contains('difficult')) {
        minR = 1800;
        maxR = 2800;
      } else if (query.contains('medium') || query.contains('intermediate')) {
        minR = 1200;
        maxR = 1800;
      }
      
      if (theme != null || minR != null || maxR != null) {
        final list = await repo.searchPuzzles(
          theme: theme,
          minRating: minR,
          maxRating: maxR,
          limit: 1,
        );
        if (list.isNotEmpty) selectedPuzzle = list.first;
      } else {
        selectedPuzzle = await repo.getRandomPuzzle(
          minRating: minR,
          maxRating: maxR,
        );
      }

      final displayUser = userName != null ? '**$userName**' : 'Apprentice';
      if (selectedPuzzle != null) {
        onPuzzleLoaded?.call(selectedPuzzle);
        yield 'I have retrieved a training exercise for you, $displayUser (Rating: ${selectedPuzzle.rating}, Theme: ${selectedPuzzle.themes}). Show me your tactical vision.';
      } else {
        yield 'I searched the archives but found no puzzle matching those criteria, $displayUser.';
      }
      return;
    }

    if (context == null) {
      yield 'GM Chanakya is contemplating the board state...';
      return;
    }

    if (context.move == 'Opening') {
      final query = userQuery?.trim().toLowerCase() ?? '';
      String response = '';
      if (query.contains('why')) {
        response = 'No moves have been made yet. The board is silent. Make your first move, and I shall explain the strategic ideas behind it.';
      } else if (query.contains('candidates')) {
        response = 'At the very beginning of the game, the classic candidates are 1.e4 or 1.d4 to seize control of the center, or 1.Nf3 or 1.c4 for a more hypermodern approach. The choice of battleground is yours.';
      } else if (query.contains('tactics')) {
        response = 'There are no tactical complications on a fresh board. Tactics arise from positional tension and structural imbalances. Let us first develop our pieces.';
      } else if (query.contains('plan')) {
        response = 'In the starting position, your plan should be fundamental: stake a claim in the center, develop your minor pieces toward active squares, castle your king to safety, and connect your rooks.';
      } else if (query.contains('defend')) {
        response = 'There is nothing to defend against yet. The threat is non-existent. Use this peace to seize the initiative.';
      } else {
        // Default to Analyze
        response = 'The board is in its pristine, starting state. Both armies stand ready. Establish your presence in the center, develop your forces, and prepare for the struggle ahead.';
      }

      yield response;
      return;
    }

    // Handle user queries for active games (non-opening positions)
    final cleanQuery = userQuery?.trim().toLowerCase() ?? '';
    if (cleanQuery.isNotEmpty) {
      String response = '';
      
      String cleanMoveName(String m) {
        return m.replaceAll(RegExp(r'^(White|Black) moves '), '')
                .replaceAll(RegExp(r'^(White|Black)\s+played '), '')
                .replaceAll(RegExp(r'^(White|Black)\s+'), '')
                .replaceAll(RegExp(r'^played\s+'), '')
                .replaceAll(RegExp(r'^Move played:\s+'), '')
                .replaceAll(RegExp(r'\.$'), '');
      }

      String describeEvaluation(double eval) {
        if (eval > 1.5) {
          return 'strongly in our favor';
        } else if (eval > 0.5) {
          return 'slightly in our favor';
        } else if (eval < -1.5) {
          return 'strongly in the opponent\'s favor';
        } else if (eval < -0.5) {
          return 'slightly in the opponent\'s favor';
        } else {
          return 'dynamically balanced';
        }
      }

      final descEval = describeEvaluation(context.evaluation);

      if ((cleanQuery.contains('blunder') || cleanQuery.contains('blundered')) && (context.quality == 'Blunder' || context.evalDiff < -1.0)) {
        final lastMoveClean = cleanMoveName(context.moveDescription);
        final absoluteDiff = context.evalDiff.abs().toStringAsFixed(1);
        
        String threatPhrase = "";
        if (context.tacticalThreats.isNotEmpty) {
          threatPhrase = " It exposes a tactical vulnerability: ${context.tacticalThreats.first.toLowerCase()}.";
        } else {
          threatPhrase = " It disrupts your positional harmony and weakens your coordination.";
        }

        response = "Be warned: playing $lastMoveClean is a blunder, dropping the evaluation by $absoluteDiff pawns.$threatPhrase Seek a more resilient path.";
      } else if (cleanQuery.contains('why') || cleanQuery.contains('explain') || cleanQuery.contains('reason')) {
        final lastMoveClean = cleanMoveName(context.moveDescription);
        response = 'I played $lastMoveClean, which is evaluated as a ${context.quality.toLowerCase()} decision. '
            'The position stands $descEval. This aligns with my ${context.positionStyle.toLowerCase()} style, and the tactical threat level is ${context.threatLevel.toLowerCase()}. ';
        if (context.tacticalThreats.isNotEmpty) {
          response += 'Keep in mind these tactical details: ${context.tacticalThreats.join(" ")}';
        }
      } else if (cleanQuery.contains('candidate') || cleanQuery.contains('move') || cleanQuery.contains('what to play') || cleanQuery.contains('what should i play') || cleanQuery.contains('suggest')) {
        if (context.candidates.isNotEmpty) {
          final buffer = StringBuffer();
          buffer.write('The candidate moves for this position are:\n\n');
          for (var i = 0; i < context.candidates.length; i++) {
            final c = context.candidates[i];
            final cleanedMove = cleanMoveName(c.uciMove);
            buffer.write('${i + 1}. $cleanedMove\n');
            if (c.fullPv.length > 1) {
              final cleanedPv = c.fullPv.skip(1).take(3).map(cleanMoveName).join(' → ');
              buffer.write('   Continuation: $cleanedPv\n');
            }
          }
          buffer.write('\nFocus on maintaining structural harmony while executing these paths.');
          response = buffer.toString();
        } else if (context.bestMove != null) {
          final cleanedBest = cleanMoveName(context.bestMove!);
          response = 'My recommended candidate in this position is $cleanedBest. The engine evaluates the balance as $descEval. Maintain your coordination and seek activity.';
        } else {
          response = 'The board state is complex, and the engine calculation is still maturing. I suggest developing your least active piece or securing your king\'s safety.';
        }
      } else if (cleanQuery.contains('tactics') || cleanQuery.contains('threat') || cleanQuery.contains('danger') || cleanQuery.contains('defend')) {
        if (context.tacticalThreats.isNotEmpty) {
          final threatsStr = context.tacticalThreats.join(' ');
          response = 'Remain vigilant. The board presents these tactical threats: $threatsStr Calculate carefully before making your choice; I hardly overlook slip-ups.';
        } else {
          response = 'I detect no immediate tactical threats or hanging material in the current position. Use this stability to improve your positions and advance your strategic goals.';
        }
      } else if (cleanQuery.contains('plan') || cleanQuery.contains('continuation') || cleanQuery.contains('idea') || cleanQuery.contains('strategy')) {
        if (context.pvLine.isNotEmpty) {
          final cleanedPv = context.pvLine.take(4).map(cleanMoveName).join(' → ');
          response = 'A sound plan from this position would be to follow this line: $cleanedPv. This sequence maintains piece activity and coordinates our forces toward key squares.';
        } else {
          response = 'The plan here is positional. Secure control of open files, establish outposts for your knights, and ensure your pawn structure remains resilient against enemy pressure.';
        }
      } else {
        // Fallback for general queries
        final buffer = StringBuffer();
        buffer.write('The position stands $descEval. ');
        if (context.bestMove != null) {
          final cleanedBest = cleanMoveName(context.bestMove!);
          buffer.write('The strongest candidate to consider is $cleanedBest. ');
        }
        if (context.tacticalThreats.isNotEmpty) {
          buffer.write('Keep in mind these active threats: ${context.tacticalThreats.join(" ")}');
        } else {
          buffer.write('The position is tactically secure for now.');
        }
        response = buffer.toString();
      }

      yield response;
      return;
    }

    isGenerating = true;
    lastError = null;

    try {
      final hasFork = context.tacticalThreats.any((t) => t.toLowerCase().contains('fork'));
      final hasPin = context.tacticalThreats.any((t) => t.toLowerCase().contains('pin'));
      final hasHanging = context.tacticalThreats.any((t) => t.toLowerCase().contains('hanging') || t.toLowerCase().contains('undefended'));

      final template = rust_commentary.selectCommentaryTemplateRust(
        quality: context.quality,
        previousQuality: previousQuality ?? '',
        gamePhase: context.gamePhase,
        evalDiff: context.evalDiff,
        hasFork: hasFork,
        hasPin: hasPin,
        hasHanging: hasHanging,
      );

      final cleanMove = (move ?? 'board').replaceAll('-', '');
      final destinationSquare = cleanMove.length >= 4 ? cleanMove.substring(cleanMove.length - 2) : 'board';
      final pieceName = _extractPiece(context.moveDescription);

      var finalizedText = template
          .replaceAll('[Player]', player ?? 'Apprentice')
          .replaceAll('[Move]', move ?? '')
          .replaceAll('[Square]', destinationSquare)
          .replaceAll('[Piece]', pieceName);

      yield finalizedText;
    } catch (e) {
      debugPrint('Deterministic commentary error: $e');
      yield 'GM Chanakya is contemplating the board state...';
    } finally {
      isGenerating = false;
    }
  }

  /// Generates a single block of commentary
  Future<String> generateCommentary({
    required String player,
    required String move,
    required String evalScore,
    PositionContext? context,
  }) async {
    String lastChunk = '';
    await for (final chunk in generateCommentaryStream(
      player: player,
      move: move,
      evalScore: evalScore,
      context: context,
    )) {
      lastChunk = chunk;
    }
    return lastChunk;
  }

  Future<void> dispose() async {
    isInitialized = false;
  }
}
