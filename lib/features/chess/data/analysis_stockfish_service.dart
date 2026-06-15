import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'chess_engine_service.dart';

/// An isolated, independent Stockfish engine service dedicated specifically for the Analysis Page / Study Lab.
/// This prevents any overlap or interference with the active Arena and Battleground games.
class AnalysisStockfishService implements ChessEngineService {
  static const _channel = MethodChannel('com.dsamok.ideaspacechess/native_path');

  bool _isReady = false;
  bool _isDisposed = false;
  bool _isError = false;
  Completer<void>? _readyCompleter;
  Process? _process;
  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;

  @override
  bool get isReady => _isReady;
  @override
  bool get isError => _isError;
  @override
  Stream<String> get outputStream => _outputController.stream;

  @override
  Future<void> init() async {
    if (_isDisposed) _isDisposed = false;

    if (_process != null) {
      return;
    }

    _isReady = false;
    _isError = false;
    _readyCompleter = Completer<void>();

    try {
      final String libDir = await _channel.invokeMethod(
        'getNativeLibraryDir',
      );
      final enginePath = p.join(libDir, 'libstockfish_chess_engine.so');
      final success = await _tryLaunchEngine(enginePath, const Duration(seconds: 20));
      if (!success) {
        throw Exception('Failed to start Stockfish on Android for Analysis');
      }
    } catch (e) {
      debugPrint('AnalysisStockfishService: FAILED to start engine: $e');
      _isError = true;
      if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
        _readyCompleter!.complete();
      }
    }
  }

  Future<bool> _tryLaunchEngine(String enginePath, Duration timeout) async {
    _cleanupCurrentProcess();

    final completer = Completer<bool>();
    var hasExited = false;
    var isTimedOut = false;

    try {
      if (!await File(enginePath).exists()) {
        return false;
      }

      _process = await Process.start(enginePath, []);

      _process!.exitCode.then((code) {
        hasExited = true;
        if (code != 0) {
          debugPrint('AnalysisStockfishService: Process exited abnormally with code $code');
        }
        _isReady = false;
        if (!completer.isCompleted && !isTimedOut) {
          completer.complete(false);
        }
      });

      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              final trimmed = line.trim();
              if (trimmed.isNotEmpty) {
                _outputController.add(trimmed);

                if (trimmed == 'uciok') {
                  sendCommand('isready');
                }
                if (trimmed == 'readyok') {
                  _isReady = true;
                  // Configure MultiPV to 3 immediately for multi-line analysis
                  sendCommand('setoption name MultiPV value 3');
                  if (!completer.isCompleted) {
                    completer.complete(true);
                  }
                  if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
                    _readyCompleter!.complete();
                  }
                }
              }
            },
            onError: (err) {
              debugPrint('AnalysisStockfishService: [STDOUT ERROR] $err');
              if (!completer.isCompleted) completer.complete(false);
            },
            onDone: () {
              _isReady = false;
              if (!completer.isCompleted) completer.complete(false);
            },
          );

      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) => debugPrint('AnalysisStockfish [STDERR] -> $line'),
            onDone: () {},
          );

      await Future.delayed(const Duration(milliseconds: 200));
      if (hasExited) {
        return false;
      }

      sendCommand('uci');

      final result = await completer.future.timeout(
        timeout,
        onTimeout: () {
          isTimedOut = true;
          debugPrint('AnalysisStockfishService: Timeout waiting for handshake for $enginePath');
          return false;
        },
      );

      if (!result) {
        _cleanupCurrentProcess();
      }
      return result;
    } catch (e) {
      debugPrint('AnalysisStockfishService error in _tryLaunchEngine for $enginePath: $e');
      _cleanupCurrentProcess();
      return false;
    }
  }

  void _cleanupCurrentProcess() {
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription?.cancel();
    _stderrSubscription = null;
    _process?.kill();
    _process = null;
    _isReady = false;
  }

  @override
  Future<void> sendCommand(String command) async {
    if (_process == null) {
      debugPrint('AnalysisStockfishService: Cannot send command "$command", process is NULL.');
      return;
    }
    try {
      _process!.stdin.writeln(command.trim());
    } catch (e) {
      debugPrint('AnalysisStockfishService: Failed to send command "$command": $e');
      _isReady = false;
    }
  }

  /// Launch continuous infinite analysis on a FEN position.
  Future<void> infiniteAnalysis(String fen) async {
    if (!_isReady) await _readyCompleter?.future;
    await sendCommand('stop');
    await sendCommand('position fen $fen');
    await sendCommand('go infinite');
  }

  @override
  Future<void> analyzePosition(
    String fen, {
    int depth = 15,
    Duration? wTime,
    Duration? bTime,
    Duration? wInc,
    Duration? bInc,
  }) async {
    if (!_isReady) await _readyCompleter?.future;
    await sendCommand('stop');
    await sendCommand('position fen $fen');
    if (wTime != null || bTime != null) {
      final wt = wTime?.inMilliseconds ?? 0;
      final bt = bTime?.inMilliseconds ?? 0;
      final wi = wInc?.inMilliseconds ?? 0;
      final bi = bInc?.inMilliseconds ?? 0;
      await sendCommand('go wtime $wt btime $bt winc $wi binc $bi');
    } else {
      await sendCommand('go depth $depth');
    }
  }

  @override
  Future<void> stopAnalysis() async {
    if (!_isReady) return;
    await sendCommand('stop');
  }

  @override
  Future<void> setSkillLevel(int level, {int multiPV = 1}) async {
    // Keep it at full strength, but support setting MultiPV if requested.
    await sendCommand('setoption name MultiPV value $multiPV');
  }

  @override
  Future<void> setChess960Mode(bool isEnabled) async {
    await sendCommand(
      'setoption name UCI_Chess960 value ${isEnabled ? "true" : "false"}',
    );
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _stdoutSubscription?.cancel();
    _stderrSubscription?.cancel();
    _process?.kill();
    _process = null;
    _isReady = false;
    _outputController.close();
  }
}

/// Provider for the AnalysisStockfishService.
final analysisStockfishServiceProvider = Provider<AnalysisStockfishService>((ref) {
  final service = AnalysisStockfishService();
  ref.onDispose(() => service.dispose());
  return service;
});
