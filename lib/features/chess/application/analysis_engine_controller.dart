import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analysis_stockfish_service.dart';
import '../data/uci_parser.dart';
import 'study_lab_provider.dart';

enum MoveClassification {
  brilliant,
  best,
  good,
  inaccuracy,
  mistake,
  blunder,
  none,
}

class EngineLineResult {
  final int pvIndex;
  final List<String> moves;
  final double eval;
  final bool isMate;
  final int? mateIn;

  EngineLineResult({
    required this.pvIndex,
    required this.moves,
    required this.eval,
    required this.isMate,
    this.mateIn,
  });

  @override
  String toString() {
    return 'EngineLineResult(pvIndex: $pvIndex, moves: $moves, eval: $eval, isMate: $isMate, mateIn: $mateIn)';
  }
}

class AnalysisEngineState {
  final bool isEngineOn;
  final bool isAnalyzing;
  final List<EngineLineResult> topLines;
  final double? evalScore;
  final bool isMate;
  final int? mateIn;
  final int currentDepth;
  final Map<int, MoveClassification> classifications;
  final Map<int, double> evalHistory; // nodeIndex -> double evaluation score

  AnalysisEngineState({
    this.isEngineOn = false,
    this.isAnalyzing = false,
    this.topLines = const [],
    this.evalScore,
    this.isMate = false,
    this.mateIn,
    this.currentDepth = 0,
    this.classifications = const {},
    this.evalHistory = const {},
  });

  AnalysisEngineState copyWith({
    bool? isEngineOn,
    bool? isAnalyzing,
    List<EngineLineResult>? topLines,
    double? evalScore,
    bool? isMate,
    int? mateIn,
    int? currentDepth,
    Map<int, MoveClassification>? classifications,
    Map<int, double>? evalHistory,
  }) {
    return AnalysisEngineState(
      isEngineOn: isEngineOn ?? this.isEngineOn,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      topLines: topLines ?? this.topLines,
      evalScore: evalScore ?? this.evalScore,
      isMate: isMate ?? this.isMate,
      mateIn: mateIn ?? this.mateIn,
      currentDepth: currentDepth ?? this.currentDepth,
      classifications: classifications ?? this.classifications,
      evalHistory: evalHistory ?? this.evalHistory,
    );
  }
}


class AnalysisEngineController extends StateNotifier<AnalysisEngineState> {
  final AnalysisStockfishService _service;
  StreamSubscription? _subscription;

  // Throttling fields
  Timer? _throttleTimer;
  final Map<int, EngineLineResult> _pendingLines = {};
  int _pendingDepth = 0;
  double? _pendingEvalScore;
  bool _pendingIsMate = false;
  int? _pendingMateIn;

  AnalysisEngineController(this._service) : super(AnalysisEngineState()) {
    _init();
  }

  void _init() {
    _subscription = _service.outputStream.listen(_handleLiveOutput);
    _service.init().then((_) {
      debugPrint('AnalysisEngineController: Analysis Stockfish service initialized.');
    });
  }

  void _handleLiveOutput(String line) {
    if (!state.isEngineOn) return;

    if (line.startsWith('info')) {
      final parsed = UCIParser.parseLine(line);
      if (parsed.containsKey('multipv') && parsed.containsKey('pv')) {
        final mpv = parsed['multipv'] as int;
        final pvList = parsed['pv'] as List<String>;
        final depth = parsed['depth'] as int? ?? 0;

        if (pvList.isNotEmpty) {
          double eval = 0.0;
          bool isMate = false;
          int? mateIn;
          if (parsed.containsKey('score')) {
            final score = parsed['score'] as int;
            if (parsed['scoreType'] == 'mate') {
              isMate = true;
              mateIn = score;
              eval = score > 0 ? 99.0 : -99.0;
            } else {
              eval = score / 100.0;
            }
          }

          final lineResult = EngineLineResult(
            pvIndex: mpv,
            moves: pvList,
            eval: eval,
            isMate: isMate,
            mateIn: mateIn,
          );

          _pendingLines[mpv] = lineResult;
          if (depth > _pendingDepth) {
            _pendingDepth = depth;
          }

          if (mpv == 1) {
            _pendingEvalScore = eval;
            _pendingIsMate = isMate;
            _pendingMateIn = mateIn;
          }

          // Throttle updates to 150ms to keep the UI buttery smooth
          _throttleTimer ??= Timer(const Duration(milliseconds: 150), _flushState);
        }
      }
    } else if (line.startsWith('bestmove')) {
      // Finished a search segment
      state = state.copyWith(isAnalyzing: false);
    }
  }

  void _flushState() {
    _throttleTimer = null;
    if (!mounted) return;

    final sortedLines = _pendingLines.values.toList()
      ..sort((a, b) => a.pvIndex.compareTo(b.pvIndex));

    state = state.copyWith(
      topLines: sortedLines,
      evalScore: _pendingEvalScore,
      isMate: _pendingIsMate,
      mateIn: _pendingMateIn,
      currentDepth: _pendingDepth,
    );
  }

  /// Toggles continuous analysis on/off for the active position.
  Future<void> toggleEngine(bool on, String fen) async {
    _throttleTimer?.cancel();
    _throttleTimer = null;

    if (on) {
      state = state.copyWith(
        isEngineOn: true,
        isAnalyzing: true,
        topLines: const [],
        evalScore: null,
        isMate: false,
        mateIn: null,
        currentDepth: 0,
      );
      _pendingLines.clear();
      _pendingDepth = 0;
      _pendingEvalScore = null;
      _pendingIsMate = false;
      _pendingMateIn = null;
      
      await _service.infiniteAnalysis(fen);
    } else {
      await _service.stopAnalysis();
      state = state.copyWith(
        isEngineOn: false,
        isAnalyzing: false,
        topLines: const [],
        evalScore: null,
        isMate: false,
        mateIn: null,
        currentDepth: 0,
      );
    }
  }

  /// Sets a new position and restarts the analysis engine.
  Future<void> setFen(String fen) async {
    if (!state.isEngineOn) return;

    _throttleTimer?.cancel();
    _throttleTimer = null;

    _pendingLines.clear();
    _pendingDepth = 0;
    _pendingEvalScore = null;
    _pendingIsMate = false;
    _pendingMateIn = null;

    state = state.copyWith(
      isAnalyzing: true,
      topLines: const [],
      evalScore: null,
      isMate: false,
      mateIn: null,
      currentDepth: 0,
    );

    await _service.infiniteAnalysis(fen);
  }

  /// Evaluates a single position at a target depth synchronously.
  Future<Map<String, dynamic>> _evaluatePositionAtDepth(String fen, int targetDepth) async {
    final completer = Completer<Map<String, dynamic>>();
    StreamSubscription? sub;
    Map<String, dynamic>? bestResult;

    sub = _service.outputStream.listen((line) {
      if (line.startsWith('info')) {
        final parsed = UCIParser.parseLine(line);
        final mpv = parsed['multipv'] as int? ?? 1;
        if (mpv == 1 && parsed.containsKey('depth')) {
          final depth = parsed['depth'] as int;
          if (depth >= targetDepth || line.contains('seldepth')) {
            bestResult = parsed;
          }
        }
      } else if (line.startsWith('bestmove')) {
        final parsed = UCIParser.parseLine(line);
        if (bestResult == null) {
          bestResult = parsed;
        } else {
          bestResult!['bestMove'] = parsed['bestMove'];
        }
        sub?.cancel();
        if (!completer.isCompleted) {
          completer.complete(bestResult);
        }
      }
    });

    await _service.sendCommand('stop');
    await _service.sendCommand('position fen $fen');
    await _service.sendCommand('go depth $targetDepth');

    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        sub?.cancel();
        return bestResult ?? {};
      },
    );
  }

  /// Runs full game classification at the specified depth for the mainline moves.
  Future<void> classifyFullGame(List<StudyLabMoveNode> nodes, String startFen, {int depth = 18}) async {
    final wasEngineOn = state.isEngineOn;
    if (wasEngineOn) {
      await _service.stopAnalysis();
    }

    state = state.copyWith(
      isAnalyzing: true,
      classifications: const {},
      evalHistory: const {},
    );

    final mainlineIndices = _getMainlineNodeIndices(nodes);
    final results = <int, MoveClassification>{};
    final history = <int, double>{};

    for (var i = 0; i < mainlineIndices.length; i++) {
      final nodeIdx = mainlineIndices[i];
      final node = nodes[nodeIdx];

      // FEN before this move
      final fenBefore = node.parentIndex == null ? startFen : nodes[node.parentIndex!].fen;

      // Evaluate position before
      final beforeEval = await _evaluatePositionAtDepth(fenBefore, depth);
      final bestMove = beforeEval['bestMove'] as String?;
      final playedMove = node.uci;

      // Record evaluation after the move (White's perspective)
      final afterEval = await _evaluatePositionAtDepth(node.fen, depth);
      final double scorePlayedWhite = _parseScoreToWhitePerspective(afterEval, node.fen);
      history[nodeIdx] = scorePlayedWhite;

      if (playedMove == bestMove) {
        results[nodeIdx] = MoveClassification.best;
      } else {
        final double scoreBefore = _parseScoreToDouble(beforeEval);
        final double scoreAfterOpponent = _parseScoreToDouble(afterEval);
        final double scorePlayed = -scoreAfterOpponent;
        final double loss = scoreBefore - scorePlayed;

        if (loss < 0.15) {
          results[nodeIdx] = MoveClassification.best;
        } else if (loss < 0.35) {
          results[nodeIdx] = MoveClassification.good;
        } else if (loss < 0.6) {
          results[nodeIdx] = MoveClassification.inaccuracy;
        } else if (loss < 1.2) {
          results[nodeIdx] = MoveClassification.mistake;
        } else {
          results[nodeIdx] = MoveClassification.blunder;
        }
      }
    }

    state = state.copyWith(
      isAnalyzing: false,
      classifications: results,
      evalHistory: history,
    );

    if (wasEngineOn) {
      final activeFen = nodes.isEmpty ? startFen : nodes.last.fen;
      await toggleEngine(true, activeFen);
    }
  }

  double _parseScoreToWhitePerspective(Map<String, dynamic> eval, String fen) {
    if (!eval.containsKey('score')) return 0.0;
    final score = eval['score'] as int;
    final double rawScore = eval['scoreType'] == 'mate'
        ? (score > 0 ? 99.0 : -99.0)
        : score / 100.0;
    final isWhiteToMove = !fen.contains(' b ');
    return isWhiteToMove ? rawScore : -rawScore;
  }


  List<int> _getMainlineNodeIndices(List<StudyLabMoveNode> nodes) {
    final path = <int>[];
    if (nodes.isEmpty) return path;

    var current = nodes.where((n) => n.parentIndex == null).firstOrNull;
    while (current != null) {
      path.add(current.index);
      if (current.childIndices.isEmpty) {
        break;
      }
      final nextIdx = current.childIndices.first;
      if (nextIdx >= nodes.length) break;
      current = nodes[nextIdx];
    }
    return path;
  }

  double _parseScoreToDouble(Map<String, dynamic> eval) {
    if (!eval.containsKey('score')) return 0.0;
    final score = eval['score'] as int;
    if (eval['scoreType'] == 'mate') {
      return score > 0 ? 99.0 : -99.0;
    }
    return score / 100.0;
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}

final analysisEngineControllerProvider =
    StateNotifierProvider<AnalysisEngineController, AnalysisEngineState>((ref) {
  final service = ref.watch(analysisStockfishServiceProvider);
  return AnalysisEngineController(service);
});
