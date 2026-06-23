import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class EngineArrowState {
  final bool showBestMove;   // green arrow for PV[0] (best move)
  final bool showThreat;     // red arrow for PV[1] (opponent's reply)
  final bool showRefutation; // animated red arrows cycling PV[1..4]
  final int refutationStep;  // current animation step index (0-based)

  const EngineArrowState({
    this.showBestMove = true,
    this.showThreat = true,
    this.showRefutation = true,
    this.refutationStep = 0,
  });

  EngineArrowState copyWith({
    bool? showBestMove,
    bool? showThreat,
    bool? showRefutation,
    int? refutationStep,
  }) {
    return EngineArrowState(
      showBestMove: showBestMove ?? this.showBestMove,
      showThreat: showThreat ?? this.showThreat,
      showRefutation: showRefutation ?? this.showRefutation,
      refutationStep: refutationStep ?? this.refutationStep,
    );
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class EngineArrowController extends Notifier<EngineArrowState> {
  Timer? _refutationTimer;

  @override
  EngineArrowState build() {
    ref.onDispose(() => _refutationTimer?.cancel());
    
    // Automatically start the refutation animation timer
    _refutationTimer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      state = state.copyWith(refutationStep: (state.refutationStep + 1) % 4);
    });

    return const EngineArrowState(
      showBestMove: true,
      showThreat: true,
      showRefutation: true,
      refutationStep: 0,
    );
  }

  void toggleBestMove() =>
      state = state.copyWith(showBestMove: !state.showBestMove);

  void toggleThreat() =>
      state = state.copyWith(showThreat: !state.showThreat);

  void toggleRefutation() {
    if (state.showRefutation) {
      _stopRefutation();
    } else {
      _startRefutation();
    }
  }

  void _startRefutation() {
    state = state.copyWith(showRefutation: true, refutationStep: 0);
    _refutationTimer?.cancel();
    _refutationTimer =
        Timer.periodic(const Duration(milliseconds: 900), (t) {
      state =
          state.copyWith(refutationStep: (state.refutationStep + 1) % 4);
    });
  }

  void _stopRefutation() {
    _refutationTimer?.cancel();
    _refutationTimer = null;
    state = state.copyWith(showRefutation: false, refutationStep: 0);
  }

  /// Call when the board position changes to restart any running animation.
  void onPositionChanged() {
    if (state.showRefutation) {
      _startRefutation(); // restart animation for the new position
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final engineArrowControllerProvider =
    NotifierProvider<EngineArrowController, EngineArrowState>(
  EngineArrowController.new,
);
