import 'dart:async';
import 'dart:math' show exp;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analysis_stockfish_service.dart';
import '../data/uci_parser.dart';
import '../domain/chess_game.dart';
import 'study_lab_provider.dart';
import 'practice_lab_provider.dart';

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
  final double? whiteAccuracy; // 0-100
  final double? blackAccuracy; // 0-100

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
    this.whiteAccuracy,
    this.blackAccuracy,
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
    Object? whiteAccuracy = _sentinel,
    Object? blackAccuracy = _sentinel,
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
      whiteAccuracy: whiteAccuracy == _sentinel ? this.whiteAccuracy : whiteAccuracy as double?,
      blackAccuracy: blackAccuracy == _sentinel ? this.blackAccuracy : blackAccuracy as double?,
    );
  }
}

// Sentinel object to distinguish "not provided" from explicit null in copyWith
const Object _sentinel = Object();


class AnalysisEngineController extends Notifier<AnalysisEngineState> {
  late final AnalysisStockfishService _service;
  StreamSubscription? _subscription;

  // Throttling fields
  Timer? _throttleTimer;
  final Map<int, EngineLineResult> _pendingLines = {};
  int _pendingDepth = 0;
  double? _pendingEvalScore;
  bool _pendingIsMate = false;
  int? _pendingMateIn;

  @override
  AnalysisEngineState build() {
    _service = ref.watch(analysisStockfishServiceProvider);
    _init();
    ref.onDispose(() {
      _throttleTimer?.cancel();
      _subscription?.cancel();
    });
    return AnalysisEngineState();
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
      final practiceState = ref.read(practiceLabProvider);
      if (practiceState.isSessionActive) {
        await ref.read(practiceLabProvider.notifier).endSessionWithoutRestartingEngine();
      }

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
        whiteAccuracy: null,
        blackAccuracy: null,
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
    final whiteLosses = <double>[];
    final blackLosses = <double>[];

    for (var i = 0; i < mainlineIndices.length; i++) {
      final nodeIdx = mainlineIndices[i];
      final node = nodes[nodeIdx];

      // FEN before this move
      final fenBefore = node.parentIndex == null ? startFen : nodes[node.parentIndex!].fen;
      final isWhite = !fenBefore.contains(' b ');

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
        // Best move = 0 cp loss
        if (isWhite) {
          whiteLosses.add(0.0);
        } else {
          blackLosses.add(0.0);
        }
      } else {
        final double scoreBefore = _parseScoreToDouble(beforeEval);
        final double scoreAfterOpponent = _parseScoreToDouble(afterEval);
        final double scorePlayed = -scoreAfterOpponent;
        final double loss = scoreBefore - scorePlayed;

        // Accumulate cp loss for accuracy computation
        final double cpLoss = (loss * 100).clamp(0.0, double.infinity);
        if (isWhite) {
          whiteLosses.add(cpLoss);
        } else {
          blackLosses.add(cpLoss);
        }

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

    final wAccuracy = _computeAccuracy(whiteLosses);
    final bAccuracy = _computeAccuracy(blackLosses);

    state = state.copyWith(
      isAnalyzing: false,
      classifications: results,
      evalHistory: history,
      whiteAccuracy: wAccuracy,
      blackAccuracy: bAccuracy,
    );

    if (wasEngineOn) {
      final activeFen = nodes.isEmpty ? startFen : nodes.last.fen;
      await toggleEngine(true, activeFen);
    }
  }

  /// CAPS-style accuracy formula: 103.1668 * exp(-0.04354 * avgLoss) - 3.1669
  /// avgLoss is in centipawns; result is clamped to [0, 100].
  double _computeAccuracy(List<double> cpLosses) {
    if (cpLosses.isEmpty) return 100.0;
    final avgLoss = cpLosses.reduce((a, b) => a + b) / cpLosses.length;
    final accuracy = 103.1668 * exp(-0.04354 * avgLoss) - 3.1669;
    return accuracy.clamp(0.0, 100.0);
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

  Future<Map<String, dynamic>> classifyUciMoves(
    List<String> uciMoves,
    String startFen, {
    int targetDepth = 16,
    Function(double)? onProgress,
  }) async {
    final wasEngineOn = state.isEngineOn;
    if (wasEngineOn) {
      await _service.stopAnalysis();
    }

    final results = <int, MoveClassification>{};
    final history = <double>[];
    final whiteLosses = <double>[];
    final blackLosses = <double>[];

    final wCounts = <MoveClassification, int>{
      MoveClassification.brilliant: 0,
      MoveClassification.best: 0,
      MoveClassification.good: 0,
      MoveClassification.inaccuracy: 0,
      MoveClassification.mistake: 0,
      MoveClassification.blunder: 0,
      MoveClassification.none: 0,
    };
    final bCounts = Map<MoveClassification, int>.from(wCounts);

    // Reconstruct list of FENs before each move
    final fensBefore = <String>[];
    final tempGame = ChessGame(fen: startFen);
    for (final uci in uciMoves) {
      fensBefore.add(tempGame.fen);
      tempGame.makeMove({'from': uci.substring(0, 2), 'to': uci.substring(2, 4), 'promotion': uci.length > 4 ? uci[4] : 'q'});
    }

    final totalMoves = uciMoves.length;
    for (var i = 0; i < totalMoves; i++) {
      final playedMove = uciMoves[i];
      final fenBefore = fensBefore[i];
      final isWhite = !fenBefore.contains(' b ');

      // Evaluate position before
      final beforeEval = await _evaluatePositionAtDepth(fenBefore, targetDepth);
      final bestMove = beforeEval['bestMove'] as String?;

      // Reconstruct FEN after this specific move
      final afterGame = ChessGame(fen: fenBefore);
      afterGame.makeMove({'from': playedMove.substring(0, 2), 'to': playedMove.substring(2, 4), 'promotion': playedMove.length > 4 ? playedMove[4] : 'q'});
      final fenAfter = afterGame.fen;

      // Evaluate position after
      final afterEval = await _evaluatePositionAtDepth(fenAfter, targetDepth);
      final double scorePlayedWhite = _parseScoreToWhitePerspective(afterEval, fenAfter);
      history.add(scorePlayedWhite);

      MoveClassification classification = MoveClassification.best;

      if (playedMove == bestMove) {
        // Did we play the best move? Check if it can be considered Brilliant or Great
        final double scoreBefore = _parseScoreToDouble(beforeEval);
        final isMateThreat = beforeEval['scoreType'] == 'mate';
        
        if (playedMove.length >= 4 && (afterGame.inCheckmate || (isMateThreat && scoreBefore.abs() < 5.0))) {
          classification = MoveClassification.brilliant;
        } else if (i > 2 && (playedMove.contains('x') || playedMove.length > 4)) {
          classification = MoveClassification.brilliant;
        } else {
          classification = MoveClassification.best;
        }

        if (isWhite) {
          whiteLosses.add(0.0);
        } else {
          blackLosses.add(0.0);
        }
      } else {
        final double scoreBefore = _parseScoreToDouble(beforeEval);
        final double scoreAfterOpponent = _parseScoreToDouble(afterEval);
        final double scorePlayed = -scoreAfterOpponent;
        final double loss = scoreBefore - scorePlayed;

        // Accumulate cp loss for accuracy computation
        final double cpLoss = (loss * 100).clamp(0.0, double.infinity);
        if (isWhite) {
          whiteLosses.add(cpLoss);
        } else {
          blackLosses.add(cpLoss);
        }

        // Expanded Classification Rules
        if (loss < 0.15) {
          classification = MoveClassification.best;
        } else if (loss < 0.35) {
          classification = MoveClassification.good;
        } else if (loss < 0.7) {
          classification = MoveClassification.inaccuracy;
        } else if (loss < 1.5) {
          classification = MoveClassification.mistake;
        } else {
          classification = MoveClassification.blunder;
        }
      }

      results[i] = classification;
      if (isWhite) {
        wCounts[classification] = (wCounts[classification] ?? 0) + 1;
      } else {
        bCounts[classification] = (bCounts[classification] ?? 0) + 1;
      }

      if (onProgress != null) {
        onProgress((i + 1) / totalMoves);
      }
    }

    final wAccuracy = _computeAccuracy(whiteLosses);
    final bAccuracy = _computeAccuracy(blackLosses);

    // Estimate Elos
    final whiteElo = (wAccuracy * 20 + 400).toInt();
    final blackElo = (bAccuracy * 20 + 400).toInt();

    if (wasEngineOn) {
      final activeFen = uciMoves.isEmpty ? startFen : fensBefore.last;
      await toggleEngine(true, activeFen);
    }

    return {
      'classifications': results,
      'whiteAccuracy': wAccuracy,
      'blackAccuracy': bAccuracy,
      'whiteCounts': wCounts,
      'blackCounts': bCounts,
      'whiteElo': whiteElo,
      'blackElo': blackElo,
      'evalHistory': history,
    };
  }
}

final analysisEngineControllerProvider =
    NotifierProvider<AnalysisEngineController, AnalysisEngineState>(AnalysisEngineController.new);
