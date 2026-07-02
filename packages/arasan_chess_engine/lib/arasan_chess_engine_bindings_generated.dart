// ignore_for_file: always_specify_types
// ignore_for_file: camel_case_types
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: type=lint
import 'dart:ffi' as ffi;

/// Bindings for `src/arasan_chess_engine.h`.
class ArasanChessEngineBindings {
  /// Holds the symbol lookup function.
  final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  ArasanChessEngineBindings(ffi.DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  ArasanChessEngineBindings.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  /// Arasan main loop.
  int arasan_main() {
    return _arasan_main();
  }

  late final _arasan_mainPtr =
      _lookup<ffi.NativeFunction<ffi.Int Function()>>('arasan_main');
  late final _arasan_main = _arasan_mainPtr.asFunction<int Function()>();

  /// Writing to Arasan STDIN.
  int arasan_stdin_write(
    ffi.Pointer<ffi.Char> data,
  ) {
    return _arasan_stdin_write(
      data,
    );
  }

  late final _arasan_stdin_writePtr =
      _lookup<ffi.NativeFunction<ssize_t Function(ffi.Pointer<ffi.Char>)>>(
          'arasan_stdin_write');
  late final _arasan_stdin_write = _arasan_stdin_writePtr
      .asFunction<int Function(ffi.Pointer<ffi.Char>)>();

  /// Reading Arasan STDOUT.
  ffi.Pointer<ffi.Char> arasan_stdout_read() {
    return _arasan_stdout_read();
  }

  late final _arasan_stdout_readPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'arasan_stdout_read');
  late final _arasan_stdout_read =
      _arasan_stdout_readPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();

  /// Reading Arasan STDERR.
  ffi.Pointer<ffi.Char> arasan_stderr_read() {
    return _arasan_stderr_read();
  }

  late final _arasan_stderr_readPtr =
      _lookup<ffi.NativeFunction<ffi.Pointer<ffi.Char> Function()>>(
          'arasan_stderr_read');
  late final _arasan_stderr_read =
      _arasan_stderr_readPtr.asFunction<ffi.Pointer<ffi.Char> Function()>();
}

typedef ssize_t = __ssize_t;
typedef __ssize_t = ffi.Long;
typedef Dart__ssize_t = int;
