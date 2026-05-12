import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// A service to manage and communicate with the Stockfish engine via UCI.
/// This implementation treats Stockfish as a separate, independent executable
/// for GPL compliance and uses a platform channel to find the executable path on Android.
class StockfishService {
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

  bool get isReady => _isReady;
  bool get isError => _isError;
  Stream<String> get outputStream => _outputController.stream;

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

    try {
      // debugPrint('StockfishService: Starting unified initialization sequence...');
      _isReady = false;
      _isError = false;
      _readyCompleter = Completer<void>();

      String? enginePath;

      if (Platform.isAndroid) {
        // debugPrint('StockfishService: Android detected. Using Native Library hunting logic...');
        final String libDir = await _channel.invokeMethod(
          'getNativeLibraryDir',
        );
        enginePath = p.join(libDir, 'libstockfish.so');
      } else if (Platform.isWindows) {
        // debugPrint('StockfishService: Windows detected. Using Asset mapping logic...');
        final exePath = Platform.resolvedExecutable;
        final exeDir = p.dirname(exePath);
        const relPath = 'assets/engine/stockfish.exe';

        final potentialPaths = [
          p.join(Directory.current.path, relPath),
          p.join(exeDir, 'data', 'flutter_assets', relPath),
          p.join(exeDir, relPath), // Direct asset path in some build modes
          'C:\\Stockfish\\stockfish.exe', // Fallback for some users
        ];

        // debugPrint('StockfishService: Searching for engine in potential locations:');
        for (final path in potentialPaths) {
          final exists = await File(path).exists();
          // debugPrint('  - Checking: $path [Exists: $exists]');
          if (exists) {
            enginePath = path;
            break;
          }
        }
      }

      if (enginePath == null || !await File(enginePath).exists()) {
        final errorMsg = 'Stockfish binary NOT FOUND. (Path: $enginePath)';
        debugPrint('StockfishService CRITICAL: $errorMsg');
        throw Exception(errorMsg);
      }

      // debugPrint('StockfishService: Launching engine -> $enginePath');
      _process = await Process.start(enginePath, []);
      // debugPrint('StockfishService: Process up. PID: ${_process?.pid}');

      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              final trimmed = line.trim();
              if (trimmed.isNotEmpty) {
                // debugPrint('Stockfish >>> $trimmed');
                _outputController.add(trimmed);

                if (trimmed == 'uciok') {
                  sendCommand('isready');
                }
                if (trimmed == 'readyok') {
                  // debugPrint('StockfishService: Engine STATUS -> READY');
                  _isReady = true;
                  if (_readyCompleter != null &&
                      !_readyCompleter!.isCompleted) {
                    _readyCompleter!.complete();
                  }
                }
              }
            },
            onError: (err) {
              debugPrint('StockfishService: [STDOUT ERROR] $err');
            },
            onDone: () {
              // debugPrint('StockfishService: [STDOUT] Stream closed.');
              _isReady = false;
            },
          );

      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) => debugPrint('Stockfish [STDERR] -> $line'),
            onDone: () {
              /* debugPrint('StockfishService: [STDERR] Stream closed.'); */
            },
          );

      // Monitor process exit
      _process!.exitCode.then((code) {
        if (code != 0) {
          debugPrint(
            'StockfishService: Process exited abnormally with code $code',
          );
        }
        _isReady = false;
        _process = null;
      });

      // Wait a tiny bit for the process to be fully ready for input
      await Future.delayed(const Duration(milliseconds: 500));

      // debugPrint('StockfishService: Handshaking with engine (uci)...');
      sendCommand('uci');

      // Standardized 20s timeout for all platforms
      await _readyCompleter?.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          debugPrint('StockfishService: TIMEOUT waiting for readyok.');
          _isError = true;
          if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
            _readyCompleter!.complete();
          }
        },
      );

      // debugPrint('StockfishService: Handshake complete. Ready: $_isReady');
    } catch (e) {
      debugPrint('StockfishService: FAILED to start engine: $e');
      _isError = true;
      if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
        _readyCompleter!.complete();
      }
    }
  }

  Future<void> sendCommand(String command) async {
    if (_process == null) {
      debugPrint(
        'StockfishService: Cannot send command "$command", process is NULL.',
      );
      return;
    }
    try {
      final cmd = command.endsWith('\n') ? command : '$command\n';
      _process!.stdin.write(cmd);
      await _process!.stdin.flush();
    } catch (e) {
      debugPrint('StockfishService: Failed to send command "$command": $e');
      _isReady = false;
    }
  }

  Future<void> analyzePosition(String fen, {int depth = 15}) async {
    if (!_isReady) await _readyCompleter?.future;
    await sendCommand('stop');
    await sendCommand('position fen $fen');
    await sendCommand('go depth $depth');
  }

  Future<void> stopAnalysis() async {
    if (!_isReady) return;
    await sendCommand('stop');
  }

  Future<void> setSkillLevel(int level) async {
    await sendCommand('setoption name Skill Level value $level');
  }

  Future<void> setChess960Mode(bool isEnabled) async {
    await sendCommand(
      'setoption name UCI_Chess960 value ${isEnabled ? "true" : "false"}',
    );
  }

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
