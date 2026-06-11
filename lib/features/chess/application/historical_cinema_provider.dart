import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/historical_game.dart';

class HistoricalCinemaState {
  final List<HistoricalGame> games;
  final bool isLoading;
  final HistoricalGame? activeGame;
  final int currentMoveIndex;
  final bool isPlaying;
  final double playbackSpeedSeconds; // e.g. 2.5 seconds per move

  const HistoricalCinemaState({
    this.games = const [],
    this.isLoading = true,
    this.activeGame,
    this.currentMoveIndex = 0,
    this.isPlaying = false,
    this.playbackSpeedSeconds = 2.5,
  });

  HistoricalCinemaState copyWith({
    List<HistoricalGame>? games,
    bool? isLoading,
    HistoricalGame? activeGame,
    int? currentMoveIndex,
    bool? isPlaying,
    double? playbackSpeedSeconds,
  }) {
    return HistoricalCinemaState(
      games: games ?? this.games,
      isLoading: isLoading ?? this.isLoading,
      activeGame: activeGame ?? this.activeGame,
      currentMoveIndex: currentMoveIndex ?? this.currentMoveIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackSpeedSeconds: playbackSpeedSeconds ?? this.playbackSpeedSeconds,
    );
  }
}

class HistoricalCinemaNotifier extends StateNotifier<HistoricalCinemaState> {
  HistoricalCinemaNotifier() : super(const HistoricalCinemaState()) {
    _loadGames();
  }

  Timer? _playbackTimer;

  Future<void> _loadGames() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/historical_cinema.json');
      final List<dynamic> list = json.decode(jsonString) as List<dynamic>;
      final games = list.map((item) => HistoricalGame.fromJson(item as Map<String, dynamic>)).toList();
      if (mounted) {
        state = state.copyWith(games: games, isLoading: false);
      }
    } catch (e) {
      // Fallback in case of failure or incomplete build
      if (mounted) {
        state = state.copyWith(games: [], isLoading: false);
      }
    }
  }

  void selectGame(HistoricalGame game) {
    _playbackTimer?.cancel();
    state = state.copyWith(
      activeGame: game,
      currentMoveIndex: 0,
      isPlaying: false,
    );
  }

  void play() {
    if (state.activeGame == null || state.isPlaying) return;
    
    state = state.copyWith(isPlaying: true);
    _startTimer();
  }

  void pause() {
    _playbackTimer?.cancel();
    state = state.copyWith(isPlaying: false);
  }

  void togglePlay() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    final duration = Duration(milliseconds: (state.playbackSpeedSeconds * 1000).toInt());
    _playbackTimer = Timer.periodic(duration, (timer) {
      nextMove();
    });
  }

  void nextMove() {
    final game = state.activeGame;
    if (game == null) return;

    if (state.currentMoveIndex < game.moves.length) {
      state = state.copyWith(currentMoveIndex: state.currentMoveIndex + 1);
    } else {
      // Game ended
      pause();
    }
  }

  void previousMove() {
    if (state.currentMoveIndex > 0) {
      state = state.copyWith(currentMoveIndex: state.currentMoveIndex - 1);
      if (state.isPlaying) {
        // Pause playback if user manually steps backward to inspect
        pause();
      }
    }
  }

  void jumpToMove(int index) {
    final game = state.activeGame;
    if (game == null) return;

    final target = index.clamp(0, game.moves.length);
    state = state.copyWith(currentMoveIndex: target);
    if (state.isPlaying) {
      pause();
    }
  }

  void setSpeed(double seconds) {
    state = state.copyWith(playbackSpeedSeconds: seconds);
    if (state.isPlaying) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }
}

final historicalCinemaProvider =
    StateNotifierProvider<HistoricalCinemaNotifier, HistoricalCinemaState>((ref) {
  return HistoricalCinemaNotifier();
});
