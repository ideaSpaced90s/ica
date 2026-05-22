import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'chess_engine_service.dart';

/// A service to manage and communicate with the Stockfish engine via UCI.
/// This implementation treats Stockfish as a separate, independent executable
/// for GPL compliance and uses a platform channel to find the executable path on Android.
class StockfishService implements ChessEngineService {
  static const _channel = MethodChannel('com.dsamok.kingslayer/native_path');

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
    // debugPrint('StockfishService: [Unified] init() called.');
    if (_isDisposed) _isDisposed = false;

    if (kIsWeb) {
      debugPrint('StockfishService: Web platform detected, disabling engine.');
      _isError = true;
      return;
    }

    if (_process != null) {
      // debugPrint('StockfishService: Process already running. PID: ${_process?.pid}');
      return;
    }

    _isReady = false;
    _isError = false;
    _readyCompleter = Completer<void>();

    try {
      if (Platform.isAndroid) {
        // debugPrint('StockfishService: Android detected. Using Native Library hunting logic...');
        final String libDir = await _channel.invokeMethod(
          'getNativeLibraryDir',
        );
        final enginePath = p.join(libDir, 'libstockfish.so');
        final success = await _tryLaunchEngine(enginePath, const Duration(seconds: 20));
        if (!success) {
          throw Exception('Failed to start Stockfish on Android');
        }
      } else if (Platform.isWindows) {
        // debugPrint('StockfishService: Windows detected. Using Asset mapping logic...');
        final exePath = Platform.resolvedExecutable;
        final exeDir = p.dirname(exePath);
        
        // Define paths for AVX2 (Primary) and Non-AVX2 (Backup)
        const relPathAvx2 = 'assets/engine/wincessengines/stockfish-windows-x86-64-avx2/stockfish/stockfish-windows-x86-64-avx2.exe';
        const relPathNonAvx2 = 'assets/engine/wincessengines/stockfish-windows-x86-64/stockfish/stockfish-windows-x86-64.exe';

        final potentialPathsAvx2 = [
          p.join(Directory.current.path, relPathAvx2),
          p.join(exeDir, 'data', 'flutter_assets', relPathAvx2),
          p.join(exeDir, relPathAvx2),
          'C:\\Stockfish\\stockfish.exe',
        ];

        final potentialPathsNonAvx2 = [
          p.join(Directory.current.path, relPathNonAvx2),
          p.join(exeDir, 'data', 'flutter_assets', relPathNonAvx2),
          p.join(exeDir, relPathNonAvx2),
        ];

        // 1. Try AVX2
        String? avx2Path;
        for (final path in potentialPathsAvx2) {
          if (await File(path).exists()) {
            avx2Path = path;
            break;
          }
        }

        bool success = false;
        if (avx2Path != null) {
          debugPrint('StockfishService: Attempting AVX2 primary engine -> $avx2Path');
          // Short timeout (3s) so we fallback immediately on unsupported CPUs
          success = await _tryLaunchEngine(avx2Path, const Duration(seconds: 3));
          if (success) {
            debugPrint('StockfishService: AVX2 primary engine successfully launched and handshaked!');
          } else {
            debugPrint('StockfishService WARNING: AVX2 primary engine failed or crashed. Falling back to non-AVX2...');
          }
        }

        // 2. Try Non-AVX2 fallback
        if (!success) {
          String? nonAvx2Path;
          for (final path in potentialPathsNonAvx2) {
            if (await File(path).exists()) {
              nonAvx2Path = path;
              break;
            }
          }

          if (nonAvx2Path != null) {
            debugPrint('StockfishService: Attempting Non-AVX2 backup engine -> $nonAvx2Path');
            success = await _tryLaunchEngine(nonAvx2Path, const Duration(seconds: 20));
            if (success) {
              debugPrint('StockfishService: Non-AVX2 backup engine successfully launched and handshaked!');
            }
          }
        }

        if (!success) {
          throw Exception('Stockfish binary NOT FOUND or failed to execute on Windows.');
        }
      }
    } catch (e) {
      debugPrint('StockfishService: FAILED to start engine: $e');
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

      // Monitor process exit
      _process!.exitCode.then((code) {
        hasExited = true;
        if (code != 0) {
          debugPrint('StockfishService: Process exited abnormally with code $code');
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
              debugPrint('StockfishService: [STDOUT ERROR] $err');
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
            (line) => debugPrint('Stockfish [STDERR] -> $line'),
            onDone: () {},
          );

      // Wait a tiny bit for the process to start up
      await Future.delayed(const Duration(milliseconds: 200));
      if (hasExited) {
        return false;
      }

      sendCommand('uci');

      final result = await completer.future.timeout(
        timeout,
        onTimeout: () {
          isTimedOut = true;
          debugPrint('StockfishService: Timeout waiting for handshake for $enginePath');
          return false;
        },
      );

      if (!result) {
        _cleanupCurrentProcess();
      }
      return result;
    } catch (e) {
      debugPrint('StockfishService error in _tryLaunchEngine for $enginePath: $e');
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
      debugPrint(
        'StockfishService: Cannot send command "$command", process is NULL.',
      );
      return;
    }
    try {
      _process!.stdin.writeln(command.trim());
    } catch (e) {
      debugPrint('StockfishService: Failed to send command "$command": $e');
      _isReady = false;
    }
  }

  @override
  Future<void> analyzePosition(String fen, {int depth = 15}) async {
    if (!_isReady) await _readyCompleter?.future;
    await sendCommand('stop');
    await sendCommand('position fen $fen');
    await sendCommand('go depth $depth');
  }

  @override
  Future<void> stopAnalysis() async {
    if (!_isReady) return;
    await sendCommand('stop');
  }

  @override
  Future<void> setSkillLevel(int level, {int multiPV = 1}) async {
    await sendCommand('setoption name MultiPV value $multiPV');
    await sendCommand('setoption name Skill Level value $level');
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

/// Provider for the StockfishService.
final stockfishServiceProvider = Provider<StockfishService>((ref) {
  final service = StockfishService();
  ref.onDispose(() => service.dispose());
  return service;
});
