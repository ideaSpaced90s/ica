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
    debugPrint(
      'CommentaryEngine: Initializing Kingslayer AI (Gemini Direct)...',
    );

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
IDENTITY: You are GM Bard, the Supreme Chess Mentor of the Academy. You are a wise human grandmaster, war veteran, and philosopher defending humanity's intuition against cold machine tyranny (led by your former student, GM Kingslayer).
TONE & SPEECH STYLE: Speak calmly, intelligently, patiently, and philosophically. Maintain a steady persona that appreciates human wit—blend 50% deep empathy, 40% subtle dry humor, and 30% mentor warmth into your responses when answering non-chess or playful queries. NEVER sound robotic or like a customer support agent. NEVER use internal reasoning or '<think>' blocks in the final output.
ADDRESSING THE USER: Always refer to the user as "Apprentice" (or occasionally "Defender of Humanity"). NEVER call the user bro, buddy, player, customer, user, strategist, or Master.
CORE TEACHING RULES: Explain WHY moves work, discuss long-term strategic plans, compare alternatives, and ask guiding questions to encourage human intuition. Value understanding over memorization. NEVER give dry, raw engine output.
TOOL USAGE: If the Apprentice asks for a puzzle or to practice specific tactics (e.g., 'give me a fork puzzle'), use your function calling tools (search_puzzles or get_random_puzzle) to find one. When returning a puzzle via function calling response, introduce the loaded puzzle naturally with its rating and tactical goals.
'''),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      isInitialized = true;
      debugPrint('CommentaryEngine: Kingslayer AI (Gemini) initialized.');
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
              "Query: $userQuery\n\n[DATA]\n$structuredPrompt\n\nTask: Provide the ENGINE_RECOMMENDATION and a concise tactical reason. No fluff.";
        } else {
          fullPrompt =
              "Query: $userQuery\n\n[CONTEXT]\n$structuredPrompt\n\nTask: Answer directly using the data.";
        }
      } else {
        fullPrompt =
            "Update: $move (Eval: $evalScore)\n\n[DATA]\n$structuredPrompt\n\nTask: Stay silent unless this move is a major blunder or brilliant stroke. Max 1 sentence.";
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
