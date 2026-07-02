import 'dart:async';
import 'package:arasan_chess_engine/arasan_chess_engine.dart';
import 'package:arasan_chess_engine/arasan_chess_engine_state.dart';

/// A unified interface for a Chess Engine Service (e.g. Arasan).
abstract class ChessEngineService {
  Future<void> init();
  bool get isReady;
  bool get isError;
  Stream<String> get outputStream;
  Future<void> sendCommand(String command);
  Future<void> analyzePosition(
    String fen, {
    int depth = 15,
    Duration? wTime,
    Duration? bTime,
    Duration? wInc,
    Duration? bInc,
  });
  Future<void> stopAnalysis();
  Future<void> setSkillLevel(int level, {int multiPV = 1});
  Future<void> setChess960Mode(bool isEnabled);
  void dispose();
}

/// Manages a single shared instance of the Arasan engine via Dart FFI.
class SharedArasanManager {
  static Arasan? _instance;
  static Arasan? get instance => _instance;
  static bool _isReady = false;
  static Completer<void>? _readyCompleter;
  static final StreamController<String> _outputController = StreamController<String>.broadcast();

  static Future<Arasan> getEngine() async {
    if (_instance != null) {
      return _instance!;
    }
    
    _readyCompleter = Completer<void>();
    _instance = Arasan();
    
    _instance!.stdout.listen((line) {
      final trimmed = line.trim();
      _outputController.add(trimmed);
      if (trimmed == 'uciok') {
        _instance!.stdin = 'isready';
      }
      if (trimmed == 'readyok') {
        _isReady = true;
        if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
          _readyCompleter!.complete();
        }
      }
    });

    // Wait for native ready state
    final readyStateCompleter = Completer<void>();
    void onStateChanged() {
      if (_instance?.state.value == ArasanState.ready) {
        if (!readyStateCompleter.isCompleted) {
          readyStateCompleter.complete();
        }
        _instance?.state.removeListener(onStateChanged);
      }
    }
    if (_instance!.state.value == ArasanState.ready) {
      readyStateCompleter.complete();
    } else {
      _instance!.state.addListener(onStateChanged);
    }
    await readyStateCompleter.future.timeout(const Duration(seconds: 10));

    // Start handshake
    _instance!.stdin = 'uci';
    await _readyCompleter!.future.timeout(const Duration(seconds: 10));
    
    return _instance!;
  }

  static Stream<String> get outputStream => _outputController.stream;
  static bool get isReady => _isReady;
}
