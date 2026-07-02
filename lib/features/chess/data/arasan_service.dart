import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arasan_chess_engine/arasan_chess_engine.dart';
import 'package:arasan_chess_engine/arasan_chess_engine_state.dart' as ffi;
import 'chess_engine_service.dart';
import 'arasan_setup.dart';

/// A service to manage and communicate with the Arasan engine via UCI.
/// This implementation uses Dart FFI (via the arasan_chess_engine package) on Android
/// to bypass modern SELinux/Process.start restrictions.
class ArasanService implements ChessEngineService {
  bool _isReady = false;
  bool _isDisposed = false;
  bool _isError = false;
  bool _isSearching = false;
  Completer<void>? _stopCompleter;
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
      debugPrint('ArasanService: Web platform detected, disabling engine.');
      _isError = true;
      return;
    }

    if (_ffiEngine != null) {
      return;
    }

    _isReady = false;
    _isError = false;
    _isSearching = false;
    _stopCompleter = null;
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
              if (!trimmed.startsWith('info')) {
                debugPrint('ArasanService FFI [RECV] -> $trimmed');
              }
              _outputController.add(trimmed);

              if (trimmed == 'uciok') {
                if (_nnuePath != null) {
                  sendCommand('setoption name NNUE file value $_nnuePath');
                }
                sendCommand('isready');
              }
              if (trimmed.startsWith('bestmove')) {
                _isSearching = false;
                if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
                  _stopCompleter!.complete();
                }
              }
              if (trimmed == 'readyok') {
                _isReady = true;
                if (!_readyCompleter.isCompleted) {
                  _readyCompleter.complete();
                }
              }
            }
          },
          onError: (err) {
            debugPrint('ArasanService FFI: [STDOUT ERROR] $err');
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
        debugPrint('ArasanService: FFI engine successfully initialized and handshaked on Android.');
      } else {
        throw UnsupportedError('ArasanService only supports Android via FFI.');
      }
    } catch (e) {
      debugPrint('ArasanService: FAILED to start engine: $e');
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
    _lastCommandFuture = Future.value();
  }

  @override
  Future<void> sendCommand(String command) async {
    final completer = Completer<void>();
    final prev = _lastCommandFuture;
    _lastCommandFuture = completer.future;

    final trimmed = command.trim();

    try {
      await prev;
      if (Platform.isAndroid) {
        if (_ffiEngine == null) {
          debugPrint(
            'ArasanService: Cannot send command "$command", FFI engine is NULL.',
          );
          return;
        }
        debugPrint('ArasanService FFI [SEND] -> $trimmed');
        if (trimmed.startsWith('go')) {
          _isSearching = true;
        }
        _ffiEngine!.stdin = trimmed;
      }
    } catch (e) {
      debugPrint('ArasanService: Failed to send command "$command": $e');
      _isReady = false;
    } finally {
      completer.complete();
    }
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
    if (_isSearching) {
      if (_stopCompleter == null || _stopCompleter!.isCompleted) {
        _stopCompleter = Completer<void>();
      }
      await sendCommand('stop');
      await _stopCompleter!.future.timeout(const Duration(seconds: 2), onTimeout: () {});
      _stopCompleter = null;
      _isSearching = false;
    }
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
    await sendCommand('stop');
  }

  @override
  Future<void> setSkillLevel(int level, {int multiPV = 1}) async {
    if (Platform.isAndroid && _ffiEngine == null) return;
    if (!Platform.isAndroid) return;
    if (!_isReady) await _readyCompleter.future;
    await sendCommand('setoption name MultiPV value $multiPV');
    
    // Map Stockfish skill levels (0-20) to Arasan ELO limiting.
    if (level < 20) {
      await sendCommand('setoption name UCI_LimitStrength value true');
      final elo = 1000 + (level * 122);
      await sendCommand('setoption name UCI_Elo value $elo');
    } else {
      await sendCommand('setoption name UCI_LimitStrength value false');
    }
  }

  @override
  Future<void> setChess960Mode(bool isEnabled) async {
    if (Platform.isAndroid && _ffiEngine == null) return;
    if (!Platform.isAndroid) return;
    if (!_isReady) await _readyCompleter.future;
    await sendCommand('setoption name UCI_Chess960 value $isEnabled');
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cleanupCurrentProcess();
    _outputController.close();
  }
}

/// Provider for the ArasanService.
final arasanServiceProvider = Provider<ArasanService>((ref) {
  final service = ArasanService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Dedicated practice/sparring arasan service provider.
final practiceArasanServiceProvider = Provider<ArasanService>((ref) {
  final service = ArasanService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Dedicated academy coaching/analysis arasan service provider.
final academyAnalysisArasanServiceProvider = Provider<ArasanService>((ref) {
  final service = ArasanService();
  ref.onDispose(() => service.dispose());
  return service;
});
