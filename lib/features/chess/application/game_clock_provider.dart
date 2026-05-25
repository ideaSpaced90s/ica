import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chess_provider.dart';

const _sentinel = Object();

class GameClockState {
  final Duration whiteTimeLeft;
  final Duration blackTimeLeft;
  final bool clockStarted;
  final String? activeClockSide;
  final bool isTimeOut;

  const GameClockState({
    required this.whiteTimeLeft,
    required this.blackTimeLeft,
    required this.clockStarted,
    this.activeClockSide,
    required this.isTimeOut,
  });

  GameClockState copyWith({
    Duration? whiteTimeLeft,
    Duration? blackTimeLeft,
    bool? clockStarted,
    Object? activeClockSide = _sentinel,
    bool? isTimeOut,
  }) {
    return GameClockState(
      whiteTimeLeft: whiteTimeLeft ?? this.whiteTimeLeft,
      blackTimeLeft: blackTimeLeft ?? this.blackTimeLeft,
      clockStarted: clockStarted ?? this.clockStarted,
      activeClockSide: identical(activeClockSide, _sentinel)
          ? this.activeClockSide
          : activeClockSide as String?,
      isTimeOut: isTimeOut ?? this.isTimeOut,
    );
  }
}

class GameClockNotifier extends StateNotifier<GameClockState> {
  final Ref ref;
  Timer? _clockTimer;

  GameClockNotifier(this.ref)
      : super(const GameClockState(
          whiteTimeLeft: Duration(minutes: 10),
          blackTimeLeft: Duration(minutes: 10),
          clockStarted: false,
          activeClockSide: null,
          isTimeOut: false,
        ));

  void setClock({
    required Duration whiteTime,
    required Duration blackTime,
    required bool started,
    String? activeSide,
    required bool timeOut,
  }) {
    _clockTimer?.cancel();
    state = GameClockState(
      whiteTimeLeft: whiteTime,
      blackTimeLeft: blackTime,
      clockStarted: started,
      activeClockSide: activeSide,
      isTimeOut: timeOut,
    );
    if (started && activeSide != null) {
      _startTimer();
    }
  }

  void startClock() {
    if (state.clockStarted && state.activeClockSide != null) return;
    state = state.copyWith(clockStarted: true);
    _startTimer();
  }

  void stopClock() {
    _clockTimer?.cancel();
    _clockTimer = null;
    state = state.copyWith(clockStarted: false);
  }

  void setActiveSide(String? side) {
    if (side == null) {
      _clockTimer?.cancel();
      _clockTimer = null;
      state = state.copyWith(
        clockStarted: false,
        activeClockSide: null,
      );
    } else {
      state = state.copyWith(activeClockSide: side);
      if (state.clockStarted) {
        _startTimer();
      }
    }
  }

  void applyIncrement(Duration increment, bool isWhite) {
    if (isWhite) {
      state = state.copyWith(whiteTimeLeft: state.whiteTimeLeft + increment);
    } else {
      state = state.copyWith(blackTimeLeft: state.blackTimeLeft + increment);
    }
  }

  void _startTimer() {
    _clockTimer?.cancel();
    if (!state.clockStarted || state.activeClockSide == null) return;

    _clockTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final side = state.activeClockSide;
      if (side == null || !state.clockStarted) {
        _clockTimer?.cancel();
        return;
      }

      if (side == 'white') {
        final next = state.whiteTimeLeft - const Duration(milliseconds: 100);
        if (next <= Duration.zero) {
          _clockTimer?.cancel();
          state = state.copyWith(
            whiteTimeLeft: Duration.zero,
            isTimeOut: true,
            clockStarted: false,
            activeClockSide: null,
          );
          ref.read(chessProvider.notifier).handleClockTimeout('white');
          return;
        }
        state = state.copyWith(whiteTimeLeft: next);
        _triggerHeartbeatIfRequired(next);
      } else {
        final next = state.blackTimeLeft - const Duration(milliseconds: 100);
        if (next <= Duration.zero) {
          _clockTimer?.cancel();
          state = state.copyWith(
            blackTimeLeft: Duration.zero,
            isTimeOut: true,
            clockStarted: false,
            activeClockSide: null,
          );
          ref.read(chessProvider.notifier).handleClockTimeout('black');
          return;
        }
        state = state.copyWith(blackTimeLeft: next);
        _triggerHeartbeatIfRequired(next);
      }
    });
  }

  void _triggerHeartbeatIfRequired(Duration time) {
    final haptics = ref.read(chessHapticsServiceProvider);
    final isHapticsEnabled = ref.read(chessProvider).isHapticsEnabled;
    if (isHapticsEnabled && time <= const Duration(seconds: 10) && time.inMilliseconds % 1000 == 0) {
      haptics.heartbeat();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }
}

final gameClockProvider = StateNotifierProvider<GameClockNotifier, GameClockState>((ref) {
  return GameClockNotifier(ref);
});
