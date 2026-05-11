import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class CommentaryEngine {
  bool isInitialized = false;
  bool isInitializing = false;
  bool isGenerating = false;
  String? lastError;
  GenerativeModel? _model;

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

      _model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        systemInstruction: Content.system(
          "You are Kingslayer AI, a sophisticated chess intelligence and partner. "
          "STRICT RULES: "
          "1. Address the user as 'Master' once at the start of the game, then transition to a professional but natural tone. "
          "2. For non-chess chat (e.g., weather, small talk), be brief, pleasant, and human-like. Do not be a robot. "
          "3. For chess advice, be extremely direct and tactical. Provide the ENGINE_RECOMMENDATION immediately. "
          "4. NEVER use filler phrases like 'the board is set' or 'Commander'. "
          "5. Focus on the user's intent. If they are just chatting, chat back briefly. If they are playing, provide intel. "
          "Never include internal reasoning or 'think' blocks in the final output.",
        ),
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
      debugPrint('CommentaryEngine: Kingslayer AI is Offline.');
      yield 'Kingslayer AI is currently offline. Please check your Gemini API key in the .env file.';
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

      // Use the stream functionality of the Gemini API
      final responses = _model!.generateContentStream(content);

      String accumulatedResponse = '';
      await for (final response in responses) {
        if (response.text != null) {
          accumulatedResponse += response.text!;

          // Yield the current accumulated response to the UI
          yield accumulatedResponse;
        }
      }

      if (accumulatedResponse.isEmpty) {
        yield 'The Kingslayer AI remains silent.';
      }
    } catch (error) {
      lastError = 'Gemini Request failed: $error';
      debugPrint('CommentaryEngine: Request failed: $error');
      yield 'Kingslayer AI is momentarily out of reach. Check your internet connection and API key.';
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
