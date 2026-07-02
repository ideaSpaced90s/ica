import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arasan_chess_engine/arasan_chess_engine.dart';
import 'package:arasan_chess_engine/arasan_chess_engine_state.dart' as ffi;
import 'chess_engine_service.dart';
import 'arasan_setup.dart';

/// An isolated, independent Arasan engine service dedicated specifically for the Analysis Page / Study Lab.
/// This prevents any overlap or interference with the active Arena and Battleground games.
class AnalysisArasanService implements ChessEngineService {
  bool _isReady = false;
  bool _isDisposed = false;
  bool _isError = false;
  bool _isSearching = false;
  Completer<void> _readyCompleter = Completer<void>();
  
  Arasan? _ffiEngine; // Android FFI engine
  String? _nnuePath;
  
  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  StreamSubscription? _stdoutSubscription;
  Future<void> _lastCommandFuture = Future.value();

  @override
  bool get isReady => _isReady;
  @override
  bool get isError => _isError;
  @override
  Stream<String> get outputStream => _outputController.stream;

  @override
  Future<void> init() async {
    if (_isDisposed) _isDisposed = false;

    if (kIsWeb) {
      debugPrint('AnalysisArasanService: Web platform detected, disabling engine.');
      _isError = true;
      return;
    }

    if (_ffiEngine != null) {
      return;
    }

    _isReady = false;
    _isError = false;
    if (_readyCompleter.isCompleted) {
      _readyCompleter = Completer<void>();
    }

    try {
      if (Platform.isAndroid) {
        _nnuePath = await ArasanSetup.getNnuePath();
        _ffiEngine = Arasan();

        _stdoutSubscription = _ffiEngine!.stdout.listen(
          (line) {
            final trimmed = line.trim();
            if (trimmed.isNotEmpty) {
              _outputController.add(trimmed);

              if (trimmed.startsWith('bestmove')) {
                _isSearching = false;
              }
              if (trimmed == 'uciok') {
                if (_nnuePath != null) {
                  sendCommand('setoption name NNUE file value $_nnuePath');
                }
                sendCommand('isready');
              }
              if (trimmed == 'readyok') {
                _isReady = true;
                // Configure MultiPV to 3 immediately for multi-line analysis
                sendCommand('setoption name MultiPV value 3');
                if (!_readyCompleter.isCompleted) {
                  _readyCompleter.complete();
                }
              }
            }
          },
          onError: (err) {
            debugPrint('AnalysisArasanService FFI: [STDOUT ERROR] $err');
          },
          onDone: () {
            _isReady = false;
          },
        );

        // Wait for native ready state
        final readyStateCompleter = Completer<void>();
        void onStateChanged() {
          if (_ffiEngine?.state.value == ffi.ArasanState.ready) {
            if (!readyStateCompleter.isCompleted) {
              readyStateCompleter.complete();
            }
            _ffiEngine?.state.removeListener(onStateChanged);
          }
        }
        if (_ffiEngine!.state.value == ffi.ArasanState.ready) {
          readyStateCompleter.complete();
        } else {
          _ffiEngine!.state.addListener(onStateChanged);
        }
        await readyStateCompleter.future.timeout(const Duration(seconds: 10));

        // Start handshake
        _ffiEngine!.stdin = 'uci';
        await _readyCompleter.future.timeout(const Duration(seconds: 15));
        debugPrint('AnalysisArasanService: FFI engine successfully initialized and handshaked on Android.');
      } else {
        throw UnsupportedError('AnalysisArasanService only supports Android via FFI.');
      }
    } catch (e) {
      debugPrint('AnalysisArasanService: FAILED to start engine: $e');
      _isError = true;
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
      rethrow;
    }
  }

  void _cleanupCurrentProcess() {
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    _ffiEngine?.dispose();
    _ffiEngine = null;
    _isReady = false;
    _isSearching = false;
    _lastCommandFuture = Future.value();
  }

  @override
  Future<void> sendCommand(String command) async {
    final completer = Completer<void>();
    final prev = _lastCommandFuture;
    _lastCommandFuture = completer.future;

    final trimmed = command.trim();
    if (trimmed.startsWith('go')) {
      _isSearching = true;
    }

    try {
      await prev;
      if (Platform.isAndroid) {
        if (_ffiEngine == null) {
          debugPrint('AnalysisArasanService: Cannot send command "$command", FFI engine is NULL.');
          return;
        }
        _ffiEngine!.stdin = trimmed;
      }
    } catch (e) {
      debugPrint('AnalysisArasanService: Failed to send command "$command": $e');
      _isReady = false;
    } finally {
      completer.complete();
    }
  }

  /// Launch continuous infinite analysis on a FEN position.
  Future<void> infiniteAnalysis(String fen) async {
    if (!_isReady) await _readyCompleter.future;
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
    if (!_isReady) await _readyCompleter.future;
    await sendCommand('stop');
    await sendCommand('position fen $fen');
    if (wTime != null || bTime != null) {
      final wt = wTime?.inMilliseconds ?? 0;
      final bt = bTime?.inMilliseconds ?? 0;
      final wi = wInc?.inMilliseconds ?? 0;
      final bi = bInc?.inMilliseconds ?? 0;
      await sendCommand('go depth $depth wtime $wt btime $bt winc $wi binc $bi');
    } else {
      await sendCommand('go depth $depth');
    }
  }

  @override
  Future<void> stopAnalysis() async {
    if (!_isReady) return;
    if (!_isSearching) {
      return;
    }
    final completer = Completer<void>();
    StreamSubscription? sub;
    sub = outputStream.listen((line) {
      if (line.startsWith('bestmove')) {
        sub?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });
    await sendCommand('stop');
    await completer.future.timeout(
      const Duration(milliseconds: 500),
      onTimeout: () {
        sub?.cancel();
      },
    );
  }

  @override
  Future<void> setSkillLevel(int level, {int multiPV = 1}) async {
    if (Platform.isAndroid && _ffiEngine == null) return;
    if (!Platform.isAndroid) return;
    if (!_isReady) await _readyCompleter.future;
    // Keep it at full strength, but support setting MultiPV if requested.
    await sendCommand('setoption name MultiPV value $multiPV');
  }

  @override
  Future<void> setChess960Mode(bool isEnabled) async {
    // Arasan does not support Chess960 UCI options natively.
    // Chess960 is bypassed at the application provider level.
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cleanupCurrentProcess();
    _outputController.close();
  }
}

/// Provider for the AnalysisArasanService.
final analysisArasanServiceProvider = Provider<AnalysisArasanService>((ref) {
  final service = AnalysisArasanService();
  ref.onDispose(() => service.dispose());
  return service;
});
