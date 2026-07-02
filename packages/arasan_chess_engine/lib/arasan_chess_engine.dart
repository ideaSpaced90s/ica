import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:ffi/ffi.dart';

import 'arasan_chess_engine_bindings_generated.dart';
import 'arasan_chess_engine_state.dart';

const String _libName = 'arasan_chess_engine';

final DynamicLibrary _dylib = () {
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

final ArasanChessEngineBindings _bindings =
    ArasanChessEngineBindings(_dylib);

class Arasan {
  final Completer<Arasan>? completer;

  final _state = _ArasanState();
  final _stdoutController = StreamController<String>.broadcast();
  final _stderrController = StreamController<String>.broadcast();
  final _mainPort = ReceivePort();
  final _stdoutPort = ReceivePort();
  final _stderrPort = ReceivePort();
  SendPort? _stdoutSendPort;
  SendPort? _stderrSendPort;

  late StreamSubscription _mainSubscription;
  late StreamSubscription _stdoutSubscription;
  late StreamSubscription _stderrSubscription;

  Arasan._({this.completer}) {
    _mainSubscription = _mainPort.listen((message) {
      _cleanUp(message is int ? message : 1);
    });
    _stdoutSubscription = _stdoutPort.listen((message) {
      if (message is String) {
        _stdoutController.sink.add(message);
      } else if (message is SendPort) {
        _stdoutSendPort = message;
      }
    });
    _stderrSubscription = _stderrPort.listen((message) {
      if (message is String) {
        _stderrController.sink.add(message);
      } else if (message is SendPort) {
        _stderrSendPort = message;
      }
    });
    compute(_spawnIsolates,
        [_mainPort.sendPort, _stdoutPort.sendPort, _stderrPort.sendPort]).then(
      (success) {
        final state = success ? ArasanState.ready : ArasanState.error;
        _state._setValue(state);
        if (state == ArasanState.ready) {
          completer?.complete(this);
        }
      },
      onError: (error) {
        developer.log('The init isolate encountered an error $error',
            name: 'Arasan');
        _cleanUp(1);
      },
    );
  }

  static Arasan? _instance;

  factory Arasan() {
    if (_instance != null) {
      return _instance!;
    }

    _instance = Arasan._();
    return _instance!;
  }

  ValueListenable<ArasanState> get state => _state;

  Stream<String> get stdout => _stdoutController.stream;

  Stream<String> get stderr => _stderrController.stream;

  set stdin(String line) {
    final stateValue = _state.value;
    if (stateValue != ArasanState.ready) {
      throw StateError('Arasan is not ready ($stateValue)');
    }

    final unicodePointer = '$line\n'.toNativeUtf8();
    final pointer = unicodePointer.cast<Char>();
    _bindings.arasan_stdin_write(pointer);
    calloc.free(unicodePointer);
  }

  void dispose() {
    final stateValue = _state.value;
    if (stateValue == ArasanState.ready) {
      stdin = 'quit';
    }
    _cleanUp(0);
  }

  void _cleanUp(int exitCode) {
    _stderrController.close();
    _stdoutController.close();

    _mainSubscription.cancel();
    _stdoutSubscription.cancel();
    _stderrSubscription.cancel();

    _stdoutSendPort?.send("stop");
    _stderrSendPort?.send("stop");

    _state._setValue(
        exitCode == 0 ? ArasanState.disposed : ArasanState.error);

    _instance = null;
  }
}

Future<Arasan> arasanAsync() {
  if (Arasan._instance != null) {
    return Future.error(StateError('Only one instance can be used at a time'));
  }

  final completer = Completer<Arasan>();
  Arasan._instance = Arasan._(completer: completer);
  return completer.future;
}

class _ArasanState extends ChangeNotifier
    implements ValueListenable<ArasanState> {
  ArasanState _value = ArasanState.starting;

  @override
  ArasanState get value => _value;

  _setValue(ArasanState v) {
    if (v == _value) return;
    _value = v;
    notifyListeners();
  }
}

void _isolateMain(SendPort mainPort) {
  final exitCode = _bindings.arasan_main();
  mainPort.send(exitCode);

  developer.log('nativeMain returns $exitCode', name: 'Arasan');
}

void _isolateStdout(SendPort stdoutPort) async {
  ReceivePort receivePort = ReceivePort();
  stdoutPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message == 'stop') {
      receivePort.close();
      developer.log('stdout isolate stopped', name: 'Arasan');
      Isolate.exit();
    }
  });

  String previous = '';

  while (true) {
    final pointer = _bindings.arasan_stdout_read();

    if (pointer.address == 0) {
      await Future.delayed(const Duration(milliseconds: 10));
      continue;
    }

    Uint8List newContentCharList;

    final newContentLength = pointer.cast<Utf8>().length;
    newContentCharList = Uint8List.view(
        pointer.cast<Uint8>().asTypedList(newContentLength).buffer,
        0,
        newContentLength);

    final newContent = utf8.decode(newContentCharList);

    final data = previous + newContent;
    final lines = data.split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stdoutPort.send(line);
    }
  }
}

void _isolateStderr(SendPort stderrPort) async {
  ReceivePort receivePort = ReceivePort();
  stderrPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message == 'stop') {
      receivePort.close();
      developer.log('stderr isolate stopped', name: 'Arasan');
      Isolate.exit();
    }
  });

  String previous = '';

  while (true) {
    final pointer = _bindings.arasan_stderr_read();

    if (pointer.address == 0) {
      await Future.delayed(const Duration(milliseconds: 10));
      continue;
    }

    Uint8List newContentCharList;

    final newContentLength = pointer.cast<Utf8>().length;
    newContentCharList = Uint8List.view(
        pointer.cast<Uint8>().asTypedList(newContentLength).buffer,
        0,
        newContentLength);

    final newContent = utf8.decode(newContentCharList);

    final data = previous + newContent;
    final lines = data.split('\n');
    previous = lines.removeLast();
    for (final line in lines) {
      stderrPort.send(line);
    }
  }
}

Future<bool> _spawnIsolates(List<SendPort> mainAndStdoutAndStdErr) async {
  try {
    await Isolate.spawn(_isolateStderr, mainAndStdoutAndStdErr[2]);
  } catch (error) {
    developer.log('Failed to spawn stderr isolate: $error', name: 'Arasan');
    return false;
  }

  try {
    await Isolate.spawn(_isolateStdout, mainAndStdoutAndStdErr[1]);
  } catch (error) {
    developer.log('Failed to spawn stdout isolate: $error', name: 'Arasan');
    return false;
  }

  try {
    await Isolate.spawn(_isolateMain, mainAndStdoutAndStdErr[0]);
  } catch (error) {
    developer.log('Failed to spawn main isolate: $error', name: 'Arasan');
    return false;
  }

  return true;
}
