import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:kingslayer_chess/src/rust/api/puzzles.dart' as rust_puzzles;
import 'package:http/http.dart' as http;
import '../data/puzzle_repository.dart';
import 'env_config.dart';

class CommentaryEngine {
  bool isInitialized = false;
  bool isInitializing = false;
  bool isGenerating = false;
  String? lastError;
  String? systemInstruction;
  LlamaEngine? _llamaEngine;
  EngineSession? _llamaSession;
  void Function(rust_puzzles.Puzzle puzzle)? onPuzzleLoaded;

  Future<void> _loadPersonaIfNeeded() async {
    if (systemInstruction != null && systemInstruction!.isNotEmpty) return;
    try {
      final personaText = await rootBundle.loadString('assets/persona/gmbard.md');
      if (personaText.isNotEmpty) {
        systemInstruction = personaText;
      }
    } catch (e) {
      debugPrint('CommentaryEngine: Failed to load gmbard.md: $e');
    }
  }

  Future<void> initialize() async {
    if (isInitialized || isInitializing) return;

    isInitializing = true;
    lastError = null;

    try {
      debugPrint('CommentaryEngine: Initializing local AI...');
      
      // 1. Copy GGUF model file from assets to local application directory if it doesn't exist
      final appDir = await getApplicationDocumentsDirectory();
      final localModelFile = File('${appDir.path}/SmolLM2-135M.gguf');

      if (!await localModelFile.exists()) {
        debugPrint('CommentaryEngine: Copying SmolLM2-135M.gguf model asset to local storage (first-run)...');
        final byteData = await rootBundle.load('assets/llm/SmolLM2-135M.gguf');
        await localModelFile.create(recursive: true);
        await localModelFile.writeAsBytes(
          byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
          flush: true,
        );
        debugPrint('CommentaryEngine: Model asset copied successfully.');
      } else {
        debugPrint('CommentaryEngine: Model file already exists locally.');
      }

      // 2. Setup LLM parameters for local inference using LlamaEngine
      String libraryPath = 'libllama.so';
      if (Platform.isWindows) {
        libraryPath = 'llama.dll';
      } else if (Platform.isMacOS) {
        libraryPath = 'libllama.dylib';
      }

      _llamaEngine = await LlamaEngine.spawn(
        libraryPath: libraryPath,
        modelParams: ModelParams(
          path: localModelFile.path,
          gpuLayers: 0,
        ),
        contextParams: const ContextParams(
          nCtx: 2048,
        ),
      );

      _llamaSession = await _llamaEngine!.createSession();

      // 3. Load dynamic persona once
      await _loadPersonaIfNeeded();

      isInitialized = true;
      debugPrint('CommentaryEngine: Local LLM initialized successfully.');
    } catch (error) {
      lastError = 'Kingslayer Local AI Initialization failed: $error';
      debugPrint('CommentaryEngine: Failed to initialize local LLM: $error');
      isInitialized = false;
    } finally {
      isInitializing = false;
    }
  }

  /// Generates commentary using either Sarvam AI (primary) or local llama_cpp_dart engine (fallback)
  Stream<String> generateCommentaryStream({
    String? player,
    String? move,
    String? evalScore,
    String? structuredPrompt,
    String? userQuery,
  }) async* {
    // 1. Intercept puzzle search queries deterministically to bypass LLM tool-calling
    final query = userQuery?.toLowerCase() ?? '';
    final isPuzzleRequest = query.contains('puzzle') || query.contains('train') || query.contains('exercise');
    if (isPuzzleRequest) {
      yield 'GM Bard is consulting the puzzle archives...';
      
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

      if (selectedPuzzle != null) {
        onPuzzleLoaded?.call(selectedPuzzle);
        yield 'Apprentice, I have retrieved a training exercise for you (Rating: ${selectedPuzzle.rating}, Theme: ${selectedPuzzle.themes}). Show me your tactical vision.';
      } else {
        yield 'I searched the archives but found no puzzle matching those criteria, Apprentice.';
      }
      return;
    }

    // Load GM Bard persona
    await _loadPersonaIfNeeded();

    // Check EnvConfig to see if Sarvam AI is configured
    await EnvConfig.load();
    final sarvamApiKey = EnvConfig.get('SARVAM_API_KEY');
    final sarvamModel = EnvConfig.get('SARVAM_MODEL') ?? 'sarvam-30b';

    // If Sarvam API key is dropped into the .env file, use it as primary
    if (sarvamApiKey != null &&
        sarvamApiKey.isNotEmpty &&
        sarvamApiKey != 'your_api_key_here') {
      try {
        debugPrint('CommentaryEngine: Utilizing Sarvam AI ($sarvamModel) as primary...');
        isGenerating = true;
        lastError = null;

        String accumulatedResponse = '';
        await for (final chunk in _streamSarvamAi(
          apiKey: sarvamApiKey,
          model: sarvamModel,
          prompt: structuredPrompt ?? userQuery ?? '',
        )) {
          accumulatedResponse += chunk;
          yield _cleanResponse(accumulatedResponse);
        }

        isGenerating = false;
        return; // Stream succeeded, exit early!
      } catch (e) {
        debugPrint('CommentaryEngine: Sarvam AI primary failed: $e. Falling back to secondary local AI...');
        lastError = 'Primary Sarvam AI failed: $e';
      } finally {
        isGenerating = false;
      }
    }

    // 2. Normal Commentary generation via Local LLM (Fallback / Secondary)
    if (!isInitialized) {
      await initialize();
    }

    if (!isInitialized || _llamaSession == null) {
      debugPrint('CommentaryEngine: GM Bard is Offline.');
      yield 'GM Bard is preparing training materials. Please try again in a moment.';
      return;
    }

    isGenerating = true;
    lastError = null;

    try {
      // Clear KV cache for a fresh generation
      await _llamaSession!.clear();

      final controller = StreamController<String>();

      final genSub = _llamaSession!.generate(
        prompt: structuredPrompt,
        addSpecial: true,
        sampler: const SamplerParams(
          temperature: 0.5,
          topK: 40,
          topP: 0.9,
        ),
      ).listen((event) {
        if (event is TokenEvent) {
          controller.add(event.text);
        } else if (event is DoneEvent) {
          if (event.trailingText.isNotEmpty) {
            controller.add(event.trailingText);
          }
          controller.close();
        }
      }, onError: (e) {
        controller.addError(e);
        controller.close();
      });

      String accumulatedResponse = '';
      await for (final token in controller.stream) {
        accumulatedResponse += token;
        yield _cleanResponse(accumulatedResponse);
      }

      await genSub.cancel();
      await controller.close();

      final cleaned = _cleanResponse(accumulatedResponse);
      if (cleaned.isEmpty) {
        yield 'GM Bard is contemplating the board state...';
      }
    } catch (error) {
      lastError = 'Local AI Request failed: $error';
      debugPrint('CommentaryEngine: Request failed: $error');
      yield 'GM Bard is out of reach. Please try again later.';
    } finally {
      isGenerating = false;
    }
  }

  /// Streams tokens from the Sarvam AI completions endpoint
  Stream<String> _streamSarvamAi({
    required String apiKey,
    required String model,
    required String prompt,
  }) async* {
    final client = http.Client();
    final url = Uri.parse('https://api.sarvam.ai/v1/chat/completions');

    final request = http.Request('POST', url)
      ..headers['Content-Type'] = 'application/json'
      ..headers['api-subscription-key'] = apiKey
      ..body = jsonEncode({
        'model': model,
        'messages': [
          if (systemInstruction != null && systemInstruction!.isNotEmpty)
            {'role': 'system', 'content': systemInstruction},
          {'role': 'user', 'content': prompt},
        ],
        'stream': true,
      });

    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        throw Exception('Sarvam AI returned status ${response.statusCode}: $body');
      }

      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        if (trimmed == 'data: [DONE]') break;
        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6).trim();
          try {
            final data = jsonDecode(jsonStr);
            final choices = data['choices'] as List?;
            if (choices != null && choices.isNotEmpty) {
              final delta = choices[0]['delta'] as Map?;
              if (delta != null) {
                final content = delta['content'] as String?;
                if (content != null) {
                  yield content;
                }
              }
            }
          } catch (_) {
            // Ignore parse errors on partial / malformed chunks
          }
        }
      }
    } finally {
      client.close();
    }
  }

  /// Generates a single block of commentary
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

  /// Clean ChatML tags or prompt markers leaking into output
  String _cleanResponse(String text) {
    return text
        .replaceAll('<|im_end|>', '')
        .replaceAll('<|im_start|>', '')
        .replaceAll('<|endoftext|>', '')
        .replaceAll('assistant\n', '')
        .replaceAll('assistant', '')
        .trim();
  }

  Future<void> dispose() async {
    isInitialized = false;
    await _llamaSession?.dispose();
    _llamaSession = null;
    await _llamaEngine?.dispose();
    _llamaEngine = null;
  }
}
