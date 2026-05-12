import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stockfish_service.dart';

/// State of the Stockfish engine.
class StockfishState {
  final bool isReady;
  final bool isError;
  final String lastOutput;
  final String? bestMove;
  final String? pondermove;
  final String? evaluation;

  StockfishState({
    this.isReady = false,
    this.isError = false,
    this.lastOutput = '',
    this.bestMove,
    this.pondermove,
    this.evaluation,
  });

  StockfishState copyWith({
    bool? isReady,
    bool? isError,
    String? lastOutput,
    String? bestMove,
    String? pondermove,
    String? evaluation,
  }) {
    return StockfishState(
      isReady: isReady ?? this.isReady,
      isError: isError ?? this.isError,
      lastOutput: lastOutput ?? this.lastOutput,
      bestMove: bestMove ?? this.bestMove,
      pondermove: pondermove ?? this.pondermove,
      evaluation: evaluation ?? this.evaluation,
    );
  }
}

/// A controller to manage the Stockfish engine using StateNotifier.
class StockfishController extends StateNotifier<StockfishState> {
  final StockfishService _service;
  StreamSubscription? _subscription;
  DateTime _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(0);

  StockfishController(this._service) : super(StockfishState()) {
    _init();
  }

  void _init() {
    _subscription = _service.outputStream.listen(_handleOutput);
    _service.init().then((_) {
        state = state.copyWith(
            isReady: _service.isReady,
            isError: _service.isError,
        );
    });
  }

  void _handleOutput(String line) {
    if (line.startsWith('info')) {
      final now = DateTime.now();
      if (now.difference(_lastUpdateTime).inMilliseconds < 250) {
        return;
      }
      _lastUpdateTime = now;
    }

    state = state.copyWith(lastOutput: line);

    if (line == 'readyok') {
      state = state.copyWith(isReady: true);
    } else if (line.startsWith('bestmove')) {
      final parts = line.split(' ');
      if (parts.length >= 2) {
        state = state.copyWith(bestMove: parts[1]);
        if (parts.length >= 4 && parts[2] == 'ponder') {
          state = state.copyWith(pondermove: parts[3]);
        }
      }
    } else if (line.contains('score')) {
      state = state.copyWith(evaluation: line);
    }
  }

  /// Sends a UCI command to the engine.
  Future<void> sendCommand(String command) async {
    await _service.sendCommand(command);
  }

  /// Sets the position and starts analysis.
  Future<void> analyzePosition(String fen, {int depth = 15}) async {
    await _service.analyzePosition(fen, depth: depth);
  }

  /// Enables or disables Chess 960 rules inside Stockfish.
  Future<void> setChess960Mode(bool isEnabled) async {
    await _service.setChess960Mode(isEnabled);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for the StockfishController.
final stockfishControllerProvider =
    StateNotifierProvider<StockfishController, StockfishState>((ref) {
  final service = ref.watch(stockfishServiceProvider);
  return StockfishController(service);
});
