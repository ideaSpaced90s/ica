import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

enum SoundEffect {
  move,
  capture,
  illegal,
  click,
  check,
  gameover,
  uiClick,
  uiNavigate,
  uiToggle,
  // Arcade mode SFX (Kenney packs)
  captureImpact,
  pieceLand,
  checkAlert,
  uiTap,
  moveSoft,
}

class ChessSoundService {
  final List<String> _bgmTracks = [
    'assets/bgm/01_The_Grandmaster_s_Ascent.mp3',
    'assets/bgm/02_The_King_s_Gambit_Deferred.mp3',
    'assets/bgm/03_The_Strategist_s_Soliloquy.mp3',
    'assets/bgm/04_The_Grandmaster_s_Gambit.mp3',
    'assets/bgm/05_The_Grandmaster_s_Silence.mp3',
    'assets/bgm/The_Kingslayer_s_Overture.mp3',
  ];

  final Map<String, String> _sfxTracks = {
    'move': 'assets/sfx/move-self.mp3',
    'capture': 'assets/sfx/capture.mp3',
    'notify': 'assets/sfx/notify.mp3',
    'whoosh': 'assets/sfx/whoosh.mp3',
    'piecemove': 'assets/sfx/piecemove.mp3',
    'thud': 'assets/sfx/thud.mp3',
    'ui_click': 'assets/sfx/ui_click.ogg',
    'ui_navigate': 'assets/sfx/ui_navigate.ogg',
    'ui_toggle': 'assets/sfx/ui_toggle.ogg',
    // Arcade mode SFX (Kenney packs)
    'capture_impact': 'assets/sfx/capture_impact.ogg',
    'move_soft': 'assets/sfx/move_soft.ogg',
    'piece_land': 'assets/sfx/piece_land.ogg',
    'check_alert': 'assets/sfx/check_alert.ogg',
    'ui_tap': 'assets/sfx/ui_tap.ogg',
  };

  final List<AudioSource> _bgmSources = [];
  final Map<String, AudioSource> _sfxSources = {};

  SoundHandle? _bgmHandle;
  AudioSource? _currentBgmSource;
  bool isSfxEnabled = true;
  bool isBgmEnabled = false;
  bool _isInitialized = false;

  final double _bgmVolumeScale = 0.5;
  final double _sfxVolumeScale = 0.7;

  ChessSoundService() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    if (_isInitialized) return;

    unawaited(() async {
      try {
        if (!SoLoud.instance.isInitialized) {
          await SoLoud.instance.init();
        }

        // Load BGM tracks into memory buffers
        for (final track in _bgmTracks) {
          try {
            final source = await SoLoud.instance.loadAsset(track);
            _bgmSources.add(source);
          } catch (e) {
            debugPrint('Error loading BGM $track: $e');
          }
        }

        // Load SFX tracks into memory buffers
        for (final entry in _sfxTracks.entries) {
          try {
            final source = await SoLoud.instance.loadAsset(entry.value);
            _sfxSources[entry.key] = source;
          } catch (e) {
            debugPrint('Error loading SFX ${entry.key}: $e');
          }
        }

        _isInitialized = true;

        // Start BGM if enabled during initialization
        if (isBgmEnabled) {
          _playRandomBgm();
        }
      } catch (e) {
        debugPrint('ChessSoundService Init Error: $e');
      }
    }());
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
    if (!isBgmEnabled || _bgmSources.isEmpty || !SoLoud.instance.isInitialized) return;

    try {
      final sources = List<AudioSource>.from(_bgmSources)..shuffle();
      AudioSource nextSource = sources.first;
      if (nextSource == _currentBgmSource && sources.length > 1) {
        nextSource = sources[1];
      }

      final prevHandle = _bgmHandle;
      _currentBgmSource = nextSource;

      // Start playing the new BGM at volume 0
      _bgmHandle = await SoLoud.instance.play(
        nextSource,
        looping: true,
        volume: 0.0,
      );

      // Smooth C++ hardware-accelerated crossfade
      SoLoud.instance.fadeVolume(_bgmHandle!, _bgmVolumeScale, const Duration(seconds: 5));

      if (prevHandle != null) {
        SoLoud.instance.fadeVolume(prevHandle, 0.0, const Duration(seconds: 5));
        // Defer stopping to allow the fade out to complete
        Timer(const Duration(seconds: 5), () {
          try {
            if (SoLoud.instance.isInitialized) {
              SoLoud.instance.stop(prevHandle);
            }
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint('Error playing random BGM: $e');
    }
  }

  void _stopBgm() {
    if (_bgmHandle != null && SoLoud.instance.isInitialized) {
      try {
        SoLoud.instance.stop(_bgmHandle!);
        _bgmHandle = null;
        _currentBgmSource = null;
      } catch (e) {
        debugPrint('Error stopping BGM: $e');
      }
    }
  }

  Future<void> _playSound(String key) async {
    if (!isSfxEnabled || !_isInitialized || !SoLoud.instance.isInitialized) return;

    final source = _sfxSources[key];
    if (source != null) {
      try {
        await SoLoud.instance.play(source, volume: _sfxVolumeScale);
      } catch (e) {
        debugPrint('Error playing sound $key: $e');
      }
    }
  }

  Future<void> playMove() async => _playSound('move');
  Future<void> playCapture() async => _playSound('capture');
  Future<void> playNotify() async => _playSound('notify');
  Future<void> playWhoosh() async => _playSound('whoosh');
  Future<void> playPawnMove() async => _playSound('piecemove');
  Future<void> playKingMove() async => _playSound('move');

  void playSfx(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.move:
        playMove();
        break;
      case SoundEffect.capture:
        playCapture();
        break;
      case SoundEffect.illegal:
        _playSound('thud');
        break;
      case SoundEffect.click:
      case SoundEffect.uiClick:
        _playSound('ui_click');
        break;
      case SoundEffect.uiNavigate:
        _playSound('ui_navigate');
        break;
      case SoundEffect.uiToggle:
        _playSound('ui_toggle');
        break;
      case SoundEffect.check:
        playNotify();
        break;
      case SoundEffect.gameover:
        playWhoosh();
        break;
      // Arcade mode SFX
      case SoundEffect.captureImpact:
        _playSound('capture_impact');
        break;
      case SoundEffect.pieceLand:
        _playSound('piece_land');
        break;
      case SoundEffect.checkAlert:
        _playSound('check_alert');
        break;
      case SoundEffect.uiTap:
        _playSound('ui_tap');
        break;
      case SoundEffect.moveSoft:
        _playSound('move_soft');
        break;
    }
  }

  Future<void> duckBgmTemporarily({
    Duration hold = const Duration(milliseconds: 900),
  }) async {
    if (!isBgmEnabled || _bgmHandle == null || !SoLoud.instance.isInitialized) return;

    try {
      SoLoud.instance.fadeVolume(_bgmHandle!, _bgmVolumeScale * 0.32, const Duration(milliseconds: 180));
      
      await Future.delayed(hold);
      
      if (!isBgmEnabled || _bgmHandle == null || !SoLoud.instance.isInitialized) return;
      SoLoud.instance.fadeVolume(_bgmHandle!, _bgmVolumeScale, const Duration(milliseconds: 420));
    } catch (e) {
      debugPrint('Error ducking BGM: $e');
    }
  }

  void dispose() {
    if (SoLoud.instance.isInitialized) {
      try {
        SoLoud.instance.deinit();
        _isInitialized = false;
      } catch (e) {
        debugPrint('Error deinitializing SoLoud: $e');
      }
    }
  }
}
