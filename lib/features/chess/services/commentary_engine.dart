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
      if (structuredPrompt != null && structuredPrompt.startsWith('<|im_start|>')) {
        fullPrompt = structuredPrompt;
      } else {
        final query = userQuery?.toLowerCase() ?? '';
        if (userQuery != null && userQuery.isNotEmpty) {
          String customTask;
          if (query == 'analyze' || query == 'analyze position') {
            customTask = "Start your response with a brief, natural introductory sentence in the voice of GM Bard stating that you are performing a deep positional analysis of the board. Then, perform a deep positional analysis of the current board state, detailing pawn structures, active/passive pieces, and key strategic themes.";
          } else if (query == 'why' || query == "why did my opponent play that?" || query == "opponent's last move") {
            customTask = "Start your response with a brief, natural introductory sentence in the voice of GM Bard explaining that you are analyzing the opponent's last move and why it was played. Then, explain the tactical and strategic goal of the opponent's last move, what they are threatening, and if they left any weaknesses behind.";
          } else if (query == 'candidates' || query == 'candidate moves') {
            customTask = "Start your response with a brief, natural introductory sentence in the voice of GM Bard stating that you have calculated candidate moves for the Apprentice. Then, review the top candidate moves provided in the context, recommend the best options, and explain the pros, cons, and strategic ideas behind each in plain English.";
          } else if (query == 'tactics' || query == 'tactics check') {
            customTask = "Start your response with a brief, natural introductory sentence in the voice of GM Bard stating that you are scanning the board for tactical opportunities and threats. Then, identify all tactical threats, pins, forks, double-attacks, or mating patterns currently present on the board for either side.";
          } else if (query == 'plan' || query == 'middlegame plan') {
            customTask = "Start your response with a brief, natural introductory sentence in the voice of GM Bard stating that you are outlining a strategic middlegame plan based on the active pawn structures. Then, evaluate the pawn structures and minor piece coordination, and outline a clear mid-term strategic plan or goals for the Apprentice.";
          } else if (query == 'defend' || query == 'how to defend') {
            customTask = "Start your response with a brief, natural introductory sentence in the voice of GM Bard warning the Apprentice about their weaknesses and explaining how to secure their position. Then, evaluate the weaknesses and active threats against the Apprentice, suggesting the safest way to defend, neutralize threats, and consolidate their position.";
          } else {
            final isAskingForAdvice =
                query.contains('what') ||
                query.contains('play') ||
                query.contains('do') ||
                query.contains('advice') ||
                query.contains('should');
            if (isAskingForAdvice) {
              customTask = "Provide point-to-point tactical advice. Recommend the best continuation and explain the direct strategic benefit. Keep it concise.";
            } else {
              customTask = "Answer the Apprentice's query directly and concisely using the provided context.";
            }
          }
          fullPrompt = "Query: $userQuery\n\n[CONTEXT]\n$structuredPrompt\n\nTask: $customTask";
        } else {
          fullPrompt =
              "Current State: $move (Evaluation Shift: $evalScore)\n\n[SITUATION]\n$structuredPrompt\n\nTask: React to this move with a brief, instructional comment. Max 1-2 sentences. No fluff.";
        }
      }

      final content = [Content.text(fullPrompt)];      // Collect the response stream to inspect for tool requests
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
