import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A simple, generic Notifier implementation that mimics the behavior
/// of StateProvider in a way that is fully compatible with the Riverpod 3.0 Notifier API.
class VarNotifier<T> extends Notifier<T> {
  final T Function() _init;
  VarNotifier(this._init);

  @override
  T build() => _init();

  @override
  set state(T value) => super.state = value;

  void update(T Function(T state) cb) => state = cb(state);
}
