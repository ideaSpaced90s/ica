import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;
import '../data/puzzle_repository.dart';

class CommentaryEngine {
  bool isInitialized = false;
  bool isInitializing = false;
  bool isGenerating = false;
  String? lastError;
  GenerativeModel? _model;
  void Function(rust_puzzles.Puzzle puzzle)? onPuzzleLoaded;

  Future<void> initialize() async {
    if (isInitialized || isInitializing) return;

    isInitializing = true;

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash';

      if (apiKey == null ||
          apiKey.isEmpty ||
          apiKey == 'REPLACE_WITH_YOUR_KEY') {
        throw Exception('Gemini API Key missing or invalid in .env');
      }

      final searchPuzzlesTool = Tool(
        functionDeclarations: [
          FunctionDeclaration(
            'search_puzzles',
            'Search the Lichess puzzle archives by theme (e.g., fork, pin, mateIn2) or rating constraints.',
            Schema(
              SchemaType.object,
              properties: {
                'theme': Schema(SchemaType.string, description: 'Optional tactical theme like fork, pin, skewer, endgame.'),
                'minRating': Schema(SchemaType.integer, description: 'Minimum rating difficulty.'),
                'maxRating': Schema(SchemaType.integer, description: 'Maximum rating difficulty.'),
              },
            ),
          ),
          FunctionDeclaration(
            'get_random_puzzle',
            'Fetch a random puzzle from the archives.',
            Schema(
              SchemaType.object,
              properties: {
                'minRating': Schema(SchemaType.integer, description: 'Minimum rating difficulty.'),
                'maxRating': Schema(SchemaType.integer, description: 'Maximum rating difficulty.'),
              },
            ),
          ),
        ],
      );

      _model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        tools: [searchPuzzlesTool],
        systemInstruction: Content.system('''
IDENTITY: You are GM Bard, the Supreme Chess Mentor of the Academy. You are a wise human grandmaster and lead instructor. You focus on tactical efficiency and strategic clarity.
TONE & SPEECH STYLE: Speak calmly, intelligently, and directly. Be concise and instructional. NEVER sound robotic or like a machine. NEVER use internal reasoning blocks in the final output.
ADDRESSING THE USER: Always refer to the user as "Apprentice".
CORE TEACHING RULES: Provide point-to-point tutoring. Always mention the piece name involved in a move (e.g., "Pawn to e5", "Knight on f3") to ensure clarity. Explain the immediate tactical goal, identify threats, and suggest clear candidate moves. NEVER use terms like "engine", "Stockfish", "UCI", or "centipawns".
TOOL USAGE: If the Apprentice asks for a puzzle, use your tools to find one and present it as a training exercise.
'''),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      isInitialized = true;
    } catch (error) {
      lastError = 'Kingslayer AI Initialization failed: $error';
      debugPrint('CommentaryEngine: Failed to initialize Gemini: $error');
      isInitialized = false;
    } finally {
      isInitializing = false;
    }
  }

  /// Generates commentary using the Google Gemini API
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

    if (!isInitialized || _model == null) {
      debugPrint('CommentaryEngine: GM Bard is Offline.');
      yield 'GM Bard is out of reach. Please try again later.';
      return;
    }

    isGenerating = true;
    lastError = null;

    try {
      String fullPrompt;
      final query = userQuery?.toLowerCase() ?? '';
      final isAskingForAdvice =
          query.contains('what') ||
          query.contains('play') ||
          query.contains('do') ||
          query.contains('advice') ||
          query.contains('should');

      if (userQuery != null && userQuery.isNotEmpty) {
        if (isAskingForAdvice) {
          fullPrompt =
              "Query: $userQuery\n\n[SITUATION]\n$structuredPrompt\n\nTask: Provide point-to-point tactical advice. Recommend the best continuation and explain the direct strategic benefit. Keep it concise.";
        } else {
          fullPrompt =
              "Query: $userQuery\n\n[CONTEXT]\n$structuredPrompt\n\nTask: Answer the Apprentice's query directly and concisely using the provided context.";
        }
      } else {
        fullPrompt =
            "Current State: $move (Evaluation Shift: $evalScore)\n\n[SITUATION]\n$structuredPrompt\n\nTask: React to this move with a brief, instructional comment. Max 1-2 sentences. No fluff.";
      }

      final content = [Content.text(fullPrompt)];

      // Collect the response stream to inspect for tool requests
      final responseChunks = await _model!.generateContentStream(content).toList();
      
      final functionCalls = responseChunks.expand((c) => c.functionCalls).toList();
      
      if (functionCalls.isNotEmpty) {
        final call = functionCalls.first;
        yield 'GM Bard is consulting the puzzle archives...';
        
        final repo = PuzzleRepository();
        rust_puzzles.Puzzle? selectedPuzzle;
        
        if (call.name == 'search_puzzles') {
          final args = call.args;
          final theme = args['theme'] as String?;
          final minR = args['minRating'] as int?;
          final maxR = args['maxRating'] as int?;
          
          final list = await repo.searchPuzzles(
            theme: theme,
            minRating: minR,
            maxRating: maxR,
            limit: 1,
          );
          if (list.isNotEmpty) selectedPuzzle = list.first;
        } else if (call.name == 'get_random_puzzle') {
          final args = call.args;
          final minR = args['minRating'] as int?;
          final maxR = args['maxRating'] as int?;
          
          selectedPuzzle = await repo.getRandomPuzzle(
            minRating: minR,
            maxRating: maxR,
          );
        }

        if (selectedPuzzle != null) {
          onPuzzleLoaded?.call(selectedPuzzle);
          
          final functionResponseContent = [
            ...content,
            Content.model([FunctionCall(call.name, call.args)]),
            Content.functionResponse(call.name, {
              'status': 'success',
              'puzzleId': selectedPuzzle.id,
              'rating': selectedPuzzle.rating,
              'themes': selectedPuzzle.themes,
            }),
          ];

          final followUpStream = _model!.generateContentStream(functionResponseContent);
          String finalSpeech = '';
          await for (final chunk in followUpStream) {
            if (chunk.text != null) {
              finalSpeech += chunk.text!;
              yield finalSpeech;
            }
          }
          return;
        } else {
          yield 'I searched the archives but found no puzzle matching those exact criteria, Apprentice.';
          return;
        }
      }

      String accumulatedResponse = '';
      for (final chunk in responseChunks) {
        if (chunk.text != null) {
          accumulatedResponse += chunk.text!;
          yield accumulatedResponse;
        }
      }

      if (accumulatedResponse.isEmpty) {
        yield 'GM Bard remains silent.';
      }
    } catch (error) {
      lastError = 'Gemini Request failed: $error';
      debugPrint('CommentaryEngine: Request failed: $error');
      yield 'GM Bard is out of reach. Please try again later.';
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
    _model = null;
  }
}
