/// C++ engine state.
enum ArasanState {
  /// Engine has been stopped.
  disposed,

  /// An error occurred (engine could not start).
  error,

  /// Engine is running.
  ready,

  /// Engine is starting.
  starting,
}
