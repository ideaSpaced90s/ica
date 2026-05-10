import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class ChessSoundService {
  final Map<String, AudioPlayer> _players = {};
  final AudioPlayer _bgmPlayer1 = AudioPlayer();
  final AudioPlayer _bgmPlayer2 = AudioPlayer();
  AudioPlayer? _activePlayer;
  String? _currentTrack;
  Duration? _activeDuration;
  bool _transitionTriggered = false;

  final List<StreamSubscription> _subscriptions = [];

  final List<String> _bgmTracks = [
    '01_The_Grandmaster_s_Ascent.mp3',
    '02_The_King_s_Gambit_Deferred.mp3',
    '03_The_Strategist_s_Soliloquy.mp3',
    '04_The_Grandmaster_s_Gambit.mp3',
    '05_The_Grandmaster_s_Silence.mp3',
    'The_Kingslayer_s_Overture.mp3',
  ];

  bool isSfxEnabled = true;
  bool isBgmEnabled = false;

  ChessSoundService() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      // Configure global audio context strictly to prevent threading conflicts on Android/Windows
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.game,
            contentType: AndroidContentType.music,
            audioFocus: AndroidAudioFocus.none,
            stayAwake: true,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
        ),
      );

      // Set release mode to stop so we can manually trigger the next track
      await _bgmPlayer1.setReleaseMode(ReleaseMode.stop);
      await _bgmPlayer2.setReleaseMode(ReleaseMode.stop);

      _cancelSubscriptions();

      // Listen for duration and position to trigger overlapping transitions with subscription safety
      _subscriptions.add(_bgmPlayer1.onDurationChanged.listen((d) {
        if (_activePlayer == _bgmPlayer1) _activeDuration = d;
      }));
      _subscriptions.add(_bgmPlayer2.onDurationChanged.listen((d) {
        if (_activePlayer == _bgmPlayer2) _activeDuration = d;
      }));

      _subscriptions.add(_bgmPlayer1.onPositionChanged.listen((p) => _checkTransition(_bgmPlayer1, p)));
      _subscriptions.add(_bgmPlayer2.onPositionChanged.listen((p) => _checkTransition(_bgmPlayer2, p)));
      
      // Safety fallback for completion
      _subscriptions.add(_bgmPlayer1.onPlayerComplete.listen((_) => _onTrackFinish(_bgmPlayer1)));
      _subscriptions.add(_bgmPlayer2.onPlayerComplete.listen((_) => _onTrackFinish(_bgmPlayer2)));
    } catch (e) {
      debugPrint('ChessSoundService Init Error: $e');
    }
  }

  void _cancelSubscriptions() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  void _checkTransition(AudioPlayer player, Duration position) {
    if (player != _activePlayer || _transitionTriggered || _activeDuration == null) return;

    final remaining = _activeDuration! - position;
    if (remaining <= const Duration(seconds: 5)) {
      _transitionTriggered = true;
      _playRandomBgm();
    }
  }

  void _onTrackFinish(AudioPlayer player) {
    if (player == _activePlayer && !_transitionTriggered) {
      _playRandomBgm();
    }
  }

  void updateSettings({required bool sfxEnabled, required bool bgmEnabled}) {
    isSfxEnabled = sfxEnabled;
    
    if (isBgmEnabled != bgmEnabled) {
      isBgmEnabled = bgmEnabled;
      if (isBgmEnabled) {
        _playRandomBgm();
      } else {
        _stopBgm();
      }
    }
  }

  Future<void> _playRandomBgm() async {
    if (!isBgmEnabled) return;

    // Reset transition flag for the new track
    _transitionTriggered = false;
    _activeDuration = null;

    // Select a random track different from the current one if possible
    final tracks = List<String>.from(_bgmTracks)..shuffle();
    String nextTrack = tracks.first;
    if (nextTrack == _currentTrack && tracks.length > 1) {
      nextTrack = tracks[1];
    }
    _currentTrack = nextTrack;

    final prevPlayer = _activePlayer;
    final nextPlayer = (_activePlayer == _bgmPlayer1) ? _bgmPlayer2 : _bgmPlayer1;
    
    _activePlayer = nextPlayer;

    try {
      // Prepare the next player
      await nextPlayer.setSource(AssetSource('bgm/$nextTrack'));
      await nextPlayer.setVolume(0);
      await nextPlayer.resume();

      // Perform crossfade
      _crossfade(prevPlayer, nextPlayer);
    } catch (e) {
      debugPrint('Error playing random BGM: $e');
    }
  }

  void _crossfade(AudioPlayer? from, AudioPlayer to) async {
    const duration = Duration(milliseconds: 5000); // 5 seconds crossfade
    const steps = 50;
    final stepDuration = Duration(milliseconds: duration.inMilliseconds ~/ steps);

    for (int i = 1; i <= steps; i++) {
      if (!isBgmEnabled || to != _activePlayer) return;
      
      final volume = i / steps;
      try {
        await to.setVolume(volume);
        if (from != null) {
          await from.setVolume(1.0 - volume);
        }
      } catch (e) {
        // Stop fade on error
        break;
      }
      await Future.delayed(stepDuration);
    }

    if (from != null && from != _activePlayer) {
      try {
        await from.stop();
      } catch (e) {
        // Native thread errors on stop are ignored as the intent is achieved
      }
    }
  }

  void _stopBgm() {
    _bgmPlayer1.stop();
    _bgmPlayer2.stop();
    _activePlayer = null;
    _currentTrack = null;
    _activeDuration = null;
    _transitionTriggered = false;
  }

  Future<void> _playSound(String fileName) async {
    if (!isSfxEnabled) return;

    try {
      if (!_players.containsKey(fileName)) {
        final newPlayer = AudioPlayer();
        await newPlayer.setReleaseMode(ReleaseMode.stop);
        // Pre-set the source on first use
        await newPlayer.setSource(AssetSource('sfx/$fileName'));
        _players[fileName] = newPlayer;
      }

      final player = _players[fileName]!;
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      
      // We seek to zero and resume since the source is already mapped
      await player.seek(Duration.zero);
      await player.resume();
    } catch (e) {
      debugPrint('Error playing sound $fileName: $e');
    }
  }

  Future<void> playMove() async => _playSound('move-self.mp3');
  Future<void> playCapture() async => _playSound('capture.mp3');
  Future<void> playNotify() async => _playSound('notify.mp3');
  Future<void> playWhoosh() async => _playSound('whoosh.mp3');
  Future<void> playPawnMove() async => _playSound('piecemove.mp3');
  Future<void> playKingMove() async => _playSound('move-self.mp3');

  void dispose() {
    _cancelSubscriptions();
    _bgmPlayer1.dispose();
    _bgmPlayer2.dispose();
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }
}
