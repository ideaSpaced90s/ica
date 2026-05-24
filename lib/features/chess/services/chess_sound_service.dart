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
  // Kenney-based RPG/UI sound enhancements
  gmchanakyaThinking,
  gmchanakyaComplete,
  victory,
  defeat,
  draw,
  castle,
  promote,
  tabSwipe,
  switchToggle,
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
    // Kenney-based RPG/UI sound enhancements
    'book_open': 'assets/sfx/book_open.ogg',
    'book_close': 'assets/sfx/book_close.ogg',
    'click_soft1': 'assets/sfx/click_soft1.ogg',
    'click_soft2': 'assets/sfx/click_soft2.ogg',
    'click_soft3': 'assets/sfx/click_soft3.ogg',
    'click_soft4': 'assets/sfx/click_soft4.ogg',
    'click_soft5': 'assets/sfx/click_soft5.ogg',
    'coins': 'assets/sfx/coins.ogg',
    'creak': 'assets/sfx/creak.ogg',
    'metal_latch': 'assets/sfx/metal_latch.ogg',
    'castle_impact': 'assets/sfx/castle_impact.ogg',
    'promotion_bell': 'assets/sfx/promotion_bell.ogg',
    'tab_swipe': 'assets/sfx/tab_swipe.ogg',
    'switch_toggle': 'assets/sfx/switch_toggle.ogg',
  };

  final List<AudioSource> _bgmSources = [];
  final Map<String, AudioSource> _sfxSources = {};

  SoundHandle? _bgmHandle;
  final List<SoundHandle> _activeBgmHandles = [];
  AudioSource? _currentBgmSource;
  bool isSfxEnabled = true;
  bool isGameSoundEnabled = true;
  bool isAcademySoundEnabled = true;
  bool isAcademyActive = false;
  bool isRatedMode = false;
  Map<String, bool> soundSettings = const {
    'moveSounds': true,
    'captureSounds': true,
    'alertSounds': true,
  };
  Map<String, bool> academySoundSettings = const {
    'moveSounds': true,
    'captureSounds': true,
    'alertSounds': true,
    'outcomeSounds': true,
    'coachSounds': true,
    'ambientClicks': true,
  };
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

  void updateSettings({
    required bool sfxEnabled,
    required bool bgmEnabled,
    bool gameSoundEnabled = true,
    Map<String, bool> soundSettings = const {},
    bool academySoundEnabled = true,
    Map<String, bool> academySoundSettings = const {},
    bool isAcademyActive = false,
    bool isRatedMode = false,
  }) {
    isSfxEnabled = sfxEnabled;
    isGameSoundEnabled = gameSoundEnabled;
    isAcademySoundEnabled = academySoundEnabled;
    this.isAcademyActive = isAcademyActive;
    this.isRatedMode = isRatedMode;
    if (soundSettings.isNotEmpty) {
      this.soundSettings = soundSettings;
    }
    if (academySoundSettings.isNotEmpty) {
      this.academySoundSettings = academySoundSettings;
    }

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
      final handle = await SoLoud.instance.play(
        nextSource,
        looping: true,
        volume: 0.0,
      );

      if (!isBgmEnabled) {
        // If BGM was disabled while we were awaiting, stop this handle immediately
        try {
          if (SoLoud.instance.isInitialized) {
            SoLoud.instance.stop(handle);
          }
        } catch (_) {}
        _currentBgmSource = null;
        return;
      }

      _bgmHandle = handle;
      _activeBgmHandles.add(handle);

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
          _activeBgmHandles.remove(prevHandle);
        });
      }
    } catch (e) {
      debugPrint('Error playing random BGM: $e');
    }
  }

  void _stopBgm() {
    if (SoLoud.instance.isInitialized && _activeBgmHandles.isNotEmpty) {
      for (final handle in _activeBgmHandles) {
        try {
          SoLoud.instance.stop(handle);
        } catch (_) {}
      }
    }
    _activeBgmHandles.clear();
    _bgmHandle = null;
    _currentBgmSource = null;
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

  bool _isCategoryEnabled(String key) {
    if (isAcademyActive) {
      if (!isAcademySoundEnabled) return false;
      return academySoundSettings[key] ?? true;
    } else {
      if (!isGameSoundEnabled) return false;
      if (key == 'outcomeSounds' || key == 'coachSounds' || key == 'ambientClicks') {
        return false;
      }
      return soundSettings[key] ?? true;
    }
  }

  Future<void> playMove() async {
    if (isRatedMode) return;
    if (!_isCategoryEnabled('moveSounds')) return;
    await _playSound('move');
  }

  Future<void> playCapture() async {
    if (isRatedMode) return;
    if (!_isCategoryEnabled('captureSounds')) return;
    await _playSound('capture');
  }

  Future<void> playNotify() async {
    if (isRatedMode) return;
    if (!_isCategoryEnabled('alertSounds')) return;
    await _playSound('notify');
  }

  Future<void> playWhoosh() async {
    if (isRatedMode) return;
    if (!_isCategoryEnabled('outcomeSounds')) return;
    await _playSound('whoosh');
  }

  Future<void> playPawnMove() async {
    if (isRatedMode) return;
    if (!_isCategoryEnabled('moveSounds')) return;
    await _playSound('piecemove');
  }

  Future<void> playKingMove() async {
    if (isRatedMode) return;
    if (!_isCategoryEnabled('moveSounds')) return;
    await _playSound('move');
  }

  // Sequential state index to cycle through soft typing sounds organically
  int _writingSoundIndex = 0;

  Future<void> playWriting() async {
    if (isRatedMode) return;
    if (!isSfxEnabled || !_isCategoryEnabled('ambientClicks') || !_isInitialized || !SoLoud.instance.isInitialized) return;
    
    // Cycle through 5 clicks to sound like real typing
    _writingSoundIndex = (_writingSoundIndex % 5) + 1;
    final source = _sfxSources['click_soft$_writingSoundIndex'];
    if (source != null) {
      try {
        // Play at lower volume so it remains a subtle background texture
        await SoLoud.instance.play(source, volume: _sfxVolumeScale * 0.45);
      } catch (e) {
        debugPrint('Error playing writing click: $e');
      }
    }
  }

  bool _isGameSound(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.move:
      case SoundEffect.capture:
      case SoundEffect.illegal:
      case SoundEffect.check:
      case SoundEffect.gameover:
      case SoundEffect.captureImpact:
      case SoundEffect.pieceLand:
      case SoundEffect.checkAlert:
      case SoundEffect.moveSoft:
      case SoundEffect.gmchanakyaThinking:
      case SoundEffect.gmchanakyaComplete:
      case SoundEffect.victory:
      case SoundEffect.defeat:
      case SoundEffect.draw:
      case SoundEffect.castle:
      case SoundEffect.promote:
        return true;
      case SoundEffect.click:
      case SoundEffect.uiClick:
      case SoundEffect.uiNavigate:
      case SoundEffect.uiToggle:
      case SoundEffect.uiTap:
      case SoundEffect.tabSwipe:
      case SoundEffect.switchToggle:
        return false;
    }
  }

  void playSfx(SoundEffect effect) {
    if (!isSfxEnabled) return;
    final isGame = _isGameSound(effect);
    if (isGame && isRatedMode) return;
    final enabled = isGame
        ? (isAcademyActive ? isAcademySoundEnabled : isGameSoundEnabled)
        : true;
    if (!enabled) return;

    // Check specific sub-categories for game sounds
    if (isGame) {
      switch (effect) {
        case SoundEffect.move:
        case SoundEffect.moveSoft:
        case SoundEffect.castle:
        case SoundEffect.promote:
          if (!_isCategoryEnabled('moveSounds')) return;
          break;
        case SoundEffect.capture:
        case SoundEffect.captureImpact:
          if (!_isCategoryEnabled('captureSounds')) return;
          break;
        case SoundEffect.illegal:
        case SoundEffect.check:
        case SoundEffect.checkAlert:
        case SoundEffect.pieceLand:
          if (!_isCategoryEnabled('alertSounds')) return;
          break;
        case SoundEffect.gameover:
        case SoundEffect.victory:
        case SoundEffect.defeat:
        case SoundEffect.draw:
          if (!_isCategoryEnabled('outcomeSounds')) return;
          break;
        case SoundEffect.gmchanakyaThinking:
        case SoundEffect.gmchanakyaComplete:
          if (!_isCategoryEnabled('coachSounds')) return;
          break;
        default:
          break;
      }
    }

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
      // Kenney-based RPG/UI sound enhancements
      case SoundEffect.gmchanakyaThinking:
        _playSound('book_open');
        break;
      case SoundEffect.gmchanakyaComplete:
        _playSound('book_close');
        break;
      case SoundEffect.victory:
        _playSound('coins');
        break;
      case SoundEffect.defeat:
        _playSound('creak');
        break;
      case SoundEffect.draw:
        _playSound('metal_latch');
        break;
      case SoundEffect.castle:
        _playSound('castle_impact');
        break;
      case SoundEffect.promote:
        _playSound('promotion_bell');
        break;
      case SoundEffect.tabSwipe:
        _playSound('tab_swipe');
        break;
      case SoundEffect.switchToggle:
        _playSound('switch_toggle');
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
    try {
      if (SoLoud.instance.isInitialized) {
        SoLoud.instance.deinit();
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('Error deinitializing SoLoud: $e');
    }
  }
}
