import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'chess_engine_service.dart';

/// A service to manage and communicate with the Crafty chess engine.
/// It implements ChessEngineService and handles protocol translation between WinBoard (Crafty) and UCI.
class CraftyService implements ChessEngineService {
  bool _isReady = false;
  bool _isDisposed = false;
  bool _isError = false;
  Completer<void>? _readyCompleter;
  Process? _process;
  final StreamController<String> _outputController =
      StreamController<String>.broadcast();
  StreamSubscription? _stdoutSubscription;
  StreamSubscription? _stderrSubscription;
  int _currentDepth = 15;

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
      debugPrint('CraftyService: Web platform detected, disabling engine.');
      _isError = true;
      return;
    }

    if (_process != null) {
      return;
    }

    _isReady = false;
    _isError = false;
    _readyCompleter = Completer<void>();

    try {
      if (Platform.isAndroid) {
        // Android native pathway (future libcrafty.so support via NDK)
        debugPrint('CraftyService: Android platform detected. Placeholder for native JNI subprocess.');
        _isError = true;
        _readyCompleter!.complete();
      } else if (Platform.isWindows) {
        final exePath = Platform.resolvedExecutable;
        final exeDir = p.dirname(exePath);
        
        const relPath = 'assets/engine/wincessengines/crafty/crafty.exe';

        final potentialPaths = [
          p.join(Directory.current.path, relPath),
          p.join(exeDir, 'data', 'flutter_assets', relPath),
          p.join(exeDir, relPath),
        ];

        String? craftyPath;
        for (final path in potentialPaths) {
          if (await File(path).exists()) {
            craftyPath = path;
            break;
          }
        }

        bool success = false;
        if (craftyPath != null) {
          debugPrint('CraftyService: Launching Crafty engine -> $craftyPath');
          success = await _tryLaunchEngine(craftyPath, const Duration(seconds: 15));
        }

        if (!success) {
          throw Exception('Crafty binary NOT FOUND or failed to execute on Windows.');
        }
      }
    } catch (e) {
      debugPrint('CraftyService: FAILED to start engine: $e');
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
          debugPrint('CraftyService: Process exited abnormally with code $code');
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
                _translateAndEmitOutput(trimmed);
              }
            },
            onError: (err) {
              debugPrint('CraftyService: [STDOUT ERROR] $err');
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
            (line) => debugPrint('Crafty [STDERR] -> $line'),
          );

      await Future.delayed(const Duration(milliseconds: 200));
      if (hasExited) {
        return false;
      }

      // Initialize using WinBoard commands
      _sendRawCommand('xboard');
      _sendRawCommand('protover 2');

      // Crafty is ready to accept commands immediately on startup.
      // We simulate standard UCI uciok and readyok responses so our standard UCI parser and
      // ChessNotifier are perfectly satisfied without rewriting any state machine.
      _outputController.add('uciok');
      _isReady = true;
      _outputController.add('readyok');

      if (!completer.isCompleted) {
        completer.complete(true);
      }
      if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
        _readyCompleter!.complete();
      }

      return true;
    } catch (e) {
      debugPrint('CraftyService error in _tryLaunchEngine: $e');
      _cleanupCurrentProcess();
      return false;
    }
  }

  void _translateAndEmitOutput(String line) {
    final trimmed = line.trim();

    // 1. If we receive a "move <coordinate_move>" command from Crafty (e.g. move e2e4):
    if (trimmed.startsWith('move ')) {
      final move = trimmed.substring(5).trim();
      _outputController.add('bestmove $move');
      return;
    }

    // 2. Intercept and translate Crafty's search info lines to standard UCI info format:
    // Format: "  depth   score   time   nodes   pv"
    // Example: "  12      35    123   12345   e2e4 e7e5"
    final match = RegExp(r'^\s*(\d+)\s+([+-]?\d+)\s+(\d+)\s+(\d+)(?:\s+(.+))?$').firstMatch(line);
    if (match != null) {
      final depth = match.group(1);
      final score = match.group(2);
      final timeCentis = int.tryParse(match.group(3) ?? '0') ?? 0;
      final timeMs = timeCentis * 10;
      final nodes = match.group(4);
      final pv = match.group(5) ?? '';
      
      _outputController.add('info depth $depth score cp $score nodes $nodes time $timeMs pv $pv');
      return;
    }

    // 3. Pass through general text as transparent info log
    _outputController.add(line);
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

  void _sendRawCommand(String command) {
    if (_process == null) return;
    try {
      _process!.stdin.writeln(command.trim());
    } catch (e) {
      debugPrint('CraftyService: Raw write failed for command "$command": $e');
    }
  }

  @override
  Future<void> sendCommand(String command) async {
    final trimmed = command.trim();
    if (_process == null && trimmed != 'uci' && trimmed != 'isready') {
      debugPrint('CraftyService: Cannot send command "$command", process is NULL.');
      return;
    }

    if (trimmed == 'uci') {
      _outputController.add('uciok');
    } else if (trimmed == 'isready') {
      _outputController.add('readyok');
    } else if (trimmed.startsWith('position fen ')) {
      final fen = trimmed.substring(13).trim();
      _sendRawCommand('force');
      _sendRawCommand('setboard $fen');
    } else if (trimmed.startsWith('go depth ')) {
      final depth = trimmed.substring(9).trim();
      _sendRawCommand('sd $depth');
      _sendRawCommand('go');
    } else if (trimmed == 'go' || trimmed == 'go infinite') {
      _sendRawCommand('sd $_currentDepth');
      _sendRawCommand('go');
    } else if (trimmed == 'stop') {
      _sendRawCommand('force');
    }
  }

  @override
  Future<void> analyzePosition(String fen, {int depth = 15}) async {
    if (!_isReady) await _readyCompleter?.future;
    _sendRawCommand('force');
    _sendRawCommand('setboard $fen');
    _sendRawCommand('sd $depth');
    _sendRawCommand('go');
  }

  @override
  Future<void> stopAnalysis() async {
    _sendRawCommand('force');
  }

  @override
  Future<void> setSkillLevel(int level, {int multiPV = 1}) async {
    // Map skill levels to corresponding avatar search depths
    if (level <= 0) {
      _currentDepth = 1; // Sparky (avatar_0)
    } else if (level <= 1) {
      _currentDepth = 2; // Pawnzy (avatar_1)
    } else if (level <= 6) {
      _currentDepth = 5; // Blitzer (avatar_4)
    } else if (level <= 14) {
      _currentDepth = 12; // Sentinel (avatar_7)
    } else if (level <= 18) {
      _currentDepth = 18; // Titan (avatar_9)
    } else {
      _currentDepth = 20; // Default / GM Bard / Full power
    }
    debugPrint('CraftyService: skillLevel set to $level, configured search depth limit: $_currentDepth');
  }

  @override
  Future<void> setChess960Mode(bool isEnabled) async {
    // Crafty operates in standard mode, so this is a safe no-op.
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

/// Provider for CraftyService.
final craftyServiceProvider = Provider<CraftyService>((ref) {
  final service = CraftyService();
  ref.onDispose(() => service.dispose());
  return service;
});
