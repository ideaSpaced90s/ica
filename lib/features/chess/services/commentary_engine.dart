import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;
import 'package:kingslayer_chess/src/rust/api/commentary.dart' as rust_commentary;
import 'package:kingslayer_chess/src/rust/api/tactics.dart';
import '../data/puzzle_repository.dart';
import '../domain/models/position_context.dart';
import '../domain/models/candidate_move.dart';

class CommentaryEngine {
  bool isInitialized = true;
  bool isInitializing = false;
  bool isGenerating = false;
  String? lastError;
  String? systemInstruction;
  void Function(rust_puzzles.Puzzle puzzle)? onPuzzleLoaded;

  final Random _rng = Random();

  /// Picks a random string from a list.
  String _pick(List<String> pool) => pool[_rng.nextInt(pool.length)];

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

  // ── Chip-query response pools ────────────────────────────────────────────

  static const _tacticsLoaders = [
    'GM Chanakya is examining the proposed variations...',
    'Calculating the tactical ramifications of your sequence...',
    'Running the lines through the engine — a moment, Apprentice...',
    'Decoding the geometry of your tactical idea...',
  ];

  static const _puzzleLoaders = [
    'GM Chanakya is consulting the puzzle archives...',
    'Searching the training vaults for a fitting exercise...',
    'Retrieving a prescription from the tactical library...',
    'The archives are being searched. A fitting puzzle shall emerge.',
  ];

  static const _openingFallbacks = [
    'The board is in its pristine, starting state. Both armies stand ready. Establish your presence in the center, develop your forces, and prepare for the struggle ahead.',
    'An untouched board — a canvas of infinite possibility. Claim the center first, mobilize your minor pieces, and castle your king before the real battle begins.',
    'This is the moment before the storm. Every great chess battle started here. Your plan: control the center, develop with purpose, and make your king safe.',
    'The starting position holds no secrets — only principles. Center control, piece development, king safety. These three pillars define the opening.',
    'The armies have not yet committed. A thousand roads lie ahead. The wisest travelers take the central highway: 1.e4 or 1.d4 to stake your claim.',
  ];

  static const _openingWhyResponses = [
    'No moves have been made yet. The board is silent. Make your first move, and I shall explain the strategic ideas behind it.',
    'There is nothing to explain yet, Apprentice. The position is virgin. Move your pieces, and the story of the game will begin.',
    'The "why" becomes clear once the first moves are played. An empty board has no strategic narrative — only potential.',
    'Ask me "why" after the first move, and I will give you a complete strategic rationale. For now, the board speaks only of possibility.',
  ];

  static const _openingCandidateResponses = [
    'At the very beginning of the game, the classic candidates are 1.e4 or 1.d4 to seize control of the center, or 1.Nf3 or 1.c4 for a more hypermodern approach. The choice of battleground is yours.',
    'On the starting position, the strongest candidates are the central pawns: 1.e4 (Open game) and 1.d4 (Closed game). Alternatively, 1.Nf3 keeps options flexible. Choose your opening identity.',
    'Before the first pawn moves, your candidate list is vast. The most principled: 1.e4, 1.d4, 1.c4, 1.Nf3. Each defines a completely different strategic universe. I would begin with the center.',
    'The candidate moves on move one are the great openings of chess history. 1.e4 demands a fight. 1.d4 invites positional subtlety. 1.c4 the English, 1.Nf3 the hypermodern. The board is yours.',
  ];

  static const _openingTacticsResponses = [
    'There are no tactical complications on a fresh board. Tactics arise from positional tension and structural imbalances. Let us first develop our pieces.',
    'Tactics begin where development ends. On the starting position, there are no threats — only principles. Develop first; the tactics will come.',
    'An empty board holds no tactical puzzles. Tactics are born from complexity. Move your pieces into the center and create the conditions for tactical sharpness.',
    'There is nothing to calculate here — no pins, no forks, no back-rank weaknesses. That is the purpose of the opening: to create the conditions where tactics become decisive.',
  ];

  static const _openingPlanResponses = [
    'In the starting position, your plan should be fundamental: stake a claim in the center, develop your minor pieces toward active squares, castle your king to safety, and connect your rooks.',
    'The plan for every opening is the same at its core: control the center with pawns or pieces, develop all minor pieces, castle, and activate your rooks on open files.',
    'Your strategic plan begins with three pillars: center, development, king safety. After that, identify the pawn structures that define the opening system and build your plan around them.',
    'On the starting position, the plan is classical: 1.e4 or 1.d4 to grab the center, Nf3 and Bc4/Bb5/Bf4 to develop, O-O to castle, Re1 to connect. Simple, powerful, timeless.',
  ];

  static const _openingDefendResponses = [
    'There is nothing to defend against yet. The threat is non-existent. Use this peace to seize the initiative.',
    'On the starting position, every piece is defended and no weakness exists. Defense begins when you allow the opponent to create threats. Start by creating your own.',
    'No defense is needed when no attack has been launched. Play actively — develop your pieces and control the center before worrying about defending anything.',
    'The best defense is a good offense, Apprentice. On the starting board, focus on development and central control. A well-developed army defends itself.',
  ];

  // ── Active game query pools ──────────────────────────────────────────────

  static const _blunderOpeners = [
    'Be warned:',
    'This requires urgent attention:',
    'A critical error has occurred —',
    'Apprentice, heed this warning:',
    'The evaluation collapsed because:',
  ];

  static const _whyOpeners = [
    'The reasoning behind that move:',
    'Allow me to illuminate the strategic thinking:',
    'The logic is as follows:',
    'Here is what the position demanded:',
    'Let me decode the strategy for you:',
    'The idea behind that decision:',
    'A strategic explanation:',
    'The positional rationale is clear:',
  ];

  static const _candidateIntros = [
    'The candidate moves for this position are:\n\n',
    'Here are the strongest moves available in this position:\n\n',
    'Allow me to present the key candidates:\n\n',
    'The engine identifies these as the principal moves:\n\n',
    'Your candidate moves, ranked by priority:\n\n',
    'The strategic options available to you:\n\n',
  ];

  static const _candidateSingleBestOpeners = [
    'My recommended candidate in this position is',
    'The engine\'s strongest suggestion here is',
    'Above all other moves, I would recommend',
    'In this position, the most principled choice is',
    'After deep calculation, the strongest move is',
  ];

  static const _candidateFallbacks = [
    'The board state is complex, and the engine calculation is still maturing. I suggest developing your least active piece or securing your king\'s safety.',
    'This is a deeply complex position. No single move stands out decisively. Improve your worst-placed piece and keep the king safe while the engine ponders.',
    'The position is in flux — the engine has not converged on a decisive line. In the meantime, focus on piece coordination and avoid creating new weaknesses.',
    'Complex positions sometimes defy a single best move. Develop your least active piece, control key squares, and let the situation clarify itself.',
  ];

  static const _tacticsNoThreats = [
    'I detect no immediate tactical threats or hanging material in the current position. Use this stability to improve your positions and advance your strategic goals.',
    'The position is tactically quiet for now. No hanging pieces, no immediate combinations. This is the time to execute your long-term strategic plan.',
    'No tactical alarm bells are ringing in this position. The equilibrium holds. Use this calm to improve your piece coordination before creating new tensions.',
    'Tactically, the position is stable. No pins, forks, or back-rank issues are present. This is a purely positional moment — improve your worst-placed piece.',
    'The engine detects no tactical fireworks here. A peaceful moment in a complex game. Use it wisely: identify your strategic plan and execute one move at a time.',
  ];

  static const _tacticsThreatsOpeners = [
    'Remain vigilant. The board presents these tactical threats:',
    'Caution, Apprentice. The following tactical dangers are present:',
    'The position is sharp. These are the active threats you must address:',
    'Your attention is required here. The tactical threats are real:',
    'Calculate carefully before moving. The following dangers lurk in the position:',
    'Tactical alertness is essential. Here are the threats on the board:',
  ];

  static const _planOpeners = [
    'A sound plan from this position would be to follow this line:',
    'The strategic continuation that impresses me most is:',
    'Based on the position\'s demands, I would recommend this sequence:',
    'The principled plan here unfolds as follows:',
    'The engine\'s preferred strategic line from this position:',
  ];

  static const _planFallbacks = [
    'The plan here is positional. Secure control of open files, establish outposts for your knights, and ensure your pawn structure remains resilient against enemy pressure.',
    'In positions like this, the plan is structural: find the weak squares in the opponent\'s camp, route your pieces toward them, and create long-term pressure.',
    'The strategic blueprint is clear: identify the most active square available to your worst-placed piece and maneuver it there in as few moves as possible.',
    'Your plan must be built around the pawn structure. Find the weaknesses — yours and the opponent\'s — and orient all pieces toward exploiting them.',
  ];

  static const _generalFallbackConnectors = [
    'The strongest candidate to consider is',
    'I would direct your attention to',
    'The most principled move here is',
    'Engine evaluation points strongly to',
  ];

  static const _generalNoThreatClosers = [
    'The position is tactically secure for now.',
    'No tactical threats are present — consolidate and improve.',
    'The board is calm. Plan your strategic goals.',
    'No immediate danger. Use this moment to improve piece activity.',
  ];

  // ────────────────────────────────────────────────────────────────────────

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
    List<CandidateMove>? tacticsCandidates,
    bool isChess960 = false,
  }) async* {
    final isTacticsQuery = userQuery?.startsWith('[TACTICS_QUERY]') ?? false;
    if (isTacticsQuery) {
      if (tacticsBaseFen == null || tacticsSequence == null) {
        yield 'Apprentice, the tactical sequence could not be retrieved from the board.';
        return;
      }
      yield _pick(_tacticsLoaders);
      try {
        final engineAlternatives = (tacticsCandidates ?? []).map((c) => StockfishTacticLine(
          moveUci: c.uciMove,
          evaluation: c.evaluation,
          pv: c.fullPv,
        )).toList();

        final result = generateTacticsAnalysis(
          fen: tacticsBaseFen,
          userUciMoves: tacticsSequence,
          engineAlternatives: engineAlternatives,
          isChess960: isChess960,
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
      yield _pick(_puzzleLoaders);
      
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
      final q = userQuery?.trim().toLowerCase() ?? '';
      String response = '';
      if (q.contains('why')) {
        response = _pick(_openingWhyResponses);
      } else if (q.contains('candidates')) {
        response = _pick(_openingCandidateResponses);
      } else if (q.contains('tactics')) {
        response = _pick(_openingTacticsResponses);
      } else if (q.contains('plan')) {
        response = _pick(_openingPlanResponses);
      } else if (q.contains('defend')) {
        response = _pick(_openingDefendResponses);
      } else {
        response = _pick(_openingFallbacks);
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

        final opener = _pick(_blunderOpeners);
        response = "$opener playing $lastMoveClean is a blunder, dropping the evaluation by $absoluteDiff pawns.$threatPhrase Seek a more resilient path.";
      } else if (cleanQuery.contains('why') || cleanQuery.contains('explain') || cleanQuery.contains('reason')) {
        final lastMoveClean = cleanMoveName(context.moveDescription);
        final opener = _pick(_whyOpeners);
        if (context.pvLine.isNotEmpty) {
          final continuation = context.pvLine.take(3).map(cleanMoveName).join(' → ');
          response = '$opener I played $lastMoveClean, which I evaluate as a ${context.quality.toLowerCase()} decision. '
              'The position stands $descEval. By playing this, we align our pieces for the continuation: **$continuation**.';
        } else {
          response = '$opener I played $lastMoveClean, evaluated as a ${context.quality.toLowerCase()} decision. '
              'The position stands $descEval. This aligns with my ${context.positionStyle.toLowerCase()} style, and the tactical threat level is ${context.threatLevel.toLowerCase()}. ';
          if (context.tacticalThreats.isNotEmpty) {
            response += 'Key tactical details: ${context.tacticalThreats.join(" ")}';
          }
        }
      } else if (cleanQuery.contains('candidate') || cleanQuery.contains('move') || cleanQuery.contains('what to play') || cleanQuery.contains('what should i play') || cleanQuery.contains('suggest')) {
        if (context.candidates.isNotEmpty) {
          final buffer = StringBuffer();
          buffer.write(_pick(_candidateIntros));
          for (var i = 0; i < context.candidates.length; i++) {
            final c = context.candidates[i];
            final cleanedMove = cleanMoveName(c.uciMove);
            buffer.write('${i + 1}. $cleanedMove\n');
            if (c.fullPv.length > 1) {
              final cleanedPv = c.fullPv.skip(1).take(3).map(cleanMoveName).join(' → ');
              buffer.write('   => $cleanedPv\n');
            }
          }
          buffer.write('\nFocus on maintaining structural harmony while executing these paths.');
          response = buffer.toString();
        } else if (context.bestMove != null) {
          final cleanedBest = cleanMoveName(context.bestMove!);
          final opener = _pick(_candidateSingleBestOpeners);
          response = '$opener $cleanedBest. The engine evaluates the balance as $descEval. Maintain your coordination and seek activity.';
        } else {
          response = _pick(_candidateFallbacks);
        }
      } else if (cleanQuery.contains('tactics') || cleanQuery.contains('threat') || cleanQuery.contains('danger') || cleanQuery.contains('defend')) {
        final buffer = StringBuffer();
        if (context.tacticalThreats.isNotEmpty) {
          final opener = _pick(_tacticsThreatsOpeners);
          buffer.write('$opener ${context.tacticalThreats.join(" ")} ');
        } else {
          buffer.write('${_pick(_tacticsNoThreats)} ');
        }
        
        if (context.candidates.isNotEmpty) {
          final bestDef = context.candidates.first;
          final defMoveName = cleanMoveName(bestDef.uciMove);
          buffer.write('To maintain coordination, the most principled defense is **$defMoveName**. ');
          if (bestDef.fullPv.length > 1) {
            final continuation = bestDef.fullPv.take(4).map(cleanMoveName).join(' → ');
            buffer.write('=> **$continuation**');
          }
        } else {
          buffer.write('Focus on maintaining your structural harmony and piece activity.');
        }
        response = buffer.toString();
      } else if (cleanQuery.contains('plan') || cleanQuery.contains('continuation') || cleanQuery.contains('idea') || cleanQuery.contains('strategy')) {
        if (context.pvLine.isNotEmpty) {
          final opener = _pick(_planOpeners);
          if (context.pvLine.length >= 2) {
            final p1 = cleanMoveName(context.pvLine[0]);
            final p2 = cleanMoveName(context.pvLine[1]);
            response = '$opener My analysis suggests continuing with **$p1**, and you may then proceed with **$p2** to build your piece activity and secure positional strengths.';
          } else {
            final cleanedPv = context.pvLine.take(4).map(cleanMoveName).join(' → ');
            response = '$opener **$cleanedPv**. This sequence maintains piece activity and coordinates our forces toward key squares.';
          }
        } else {
          response = _pick(_planFallbacks);
        }
      } else {
        // Fallback for general queries
        final buffer = StringBuffer();
        buffer.write('The position stands $descEval. ');
        if (context.bestMove != null) {
          final cleanedBest = cleanMoveName(context.bestMove!);
          final connector = _pick(_generalFallbackConnectors);
          buffer.write('$connector $cleanedBest. ');
        }
        if (context.tacticalThreats.isNotEmpty) {
          buffer.write('Keep in mind these active threats: ${context.tacticalThreats.join(" ")}');
        } else {
          buffer.write(_pick(_generalNoThreatClosers));
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
