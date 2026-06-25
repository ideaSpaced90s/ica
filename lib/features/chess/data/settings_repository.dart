import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppSettings {
  final String boardThemeId;
  final bool isSoundEnabled;
  final bool isGameSoundEnabled;
  final bool isAcademySoundEnabled;
  final bool isMusicEnabled;
  final bool isAnimationsEnabled;
  final bool isHapticsEnabled;
  final bool showCoordinates;
  final String engineLevel;
  final String bottomAvatarId;
  final bool isAiOperational;
  final bool quickPlay;
  final int totalTimeMinutes;
  final int incrementSeconds;
  final Map<String, bool> animationSettings;
  final Map<String, bool> soundSettings;
  final Map<String, bool> academySoundSettings;
  final String gameMode;
  final bool isRatedMode;
  final int consolidatedRating;
  final int bulletElo;
  final int blitzElo;
  final int rapidElo;
  
  final int? lastRatedGameTimestampMs;
  final int recalibrationGamesRemaining;
  final int decayIntervalsApplied;
  
  final int totalRatedGamesCount;
  final int bulletGamesClassic;
  final int bulletGames960;
  final int blitzGamesClassic;
  final int blitzGames960;
  final int rapidGamesClassic;
  final int rapidGames960;
  
  final int totalWinningStreak;
  final int bulletStreak;
  final int blitzStreak;
  final int rapidStreak;

  // Notification preferences
  final bool isNotificationsEnabled;
  final bool dailyBriefingEnabled;
  final bool streakProtectionEnabled;
  final bool weeklyDiagnosticsEnabled;
  final bool milestonesEnabled;
  final String dailyBriefingTime;
  final int streakWarningHoursBeforeReset;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;

  // Academy House Specific Settings
  final bool academyHouseAnimations;
  final bool academyHouseColorFonts;
  final bool academyHouseBoldEmphasis;
  final bool academyHouseTypingEffect;

  final double bulletDominance;
  final double blitzDominance;
  final double rapidDominance;

  final String userName;
  final String userAvatarPath;
  final String? activeRatedMatchId;
  final String? activeRatedMatchOpponentId;

  AppSettings({
    this.boardThemeId = 'classic',
    this.isSoundEnabled = true,
    this.isGameSoundEnabled = true,
    this.isAcademySoundEnabled = true,
    this.isMusicEnabled = false,
    this.isAnimationsEnabled = true,
    this.isHapticsEnabled = true,
    this.showCoordinates = true,
    this.engineLevel = 'avatar_6',
    this.bottomAvatarId = 'avatar_6',
    this.isAiOperational = true,
    this.quickPlay = false,
    this.totalTimeMinutes = 10,
    this.incrementSeconds = 0,
    this.gameMode = 'classic',
    this.isRatedMode = true,
    this.consolidatedRating = 400,
    this.bulletElo = 400,
    this.blitzElo = 400,
    this.rapidElo = 400,
    this.lastRatedGameTimestampMs,
    this.recalibrationGamesRemaining = 0,
    this.decayIntervalsApplied = 0,
    this.totalRatedGamesCount = 0,
    this.bulletGamesClassic = 0,
    this.bulletGames960 = 0,
    this.blitzGamesClassic = 0,
    this.blitzGames960 = 0,
    this.rapidGamesClassic = 0,
    this.rapidGames960 = 0,
    this.totalWinningStreak = 0,
    this.bulletStreak = 0,
    this.blitzStreak = 0,
    this.rapidStreak = 0,
    this.academyHouseAnimations = true,
    this.academyHouseColorFonts = true,
    this.academyHouseBoldEmphasis = true,
    this.academyHouseTypingEffect = true,
    this.animationSettings = const {
      'pieceMotion': true,
      'feedback': true,
      'indicators': true,
      'themeEffects': true,
      'themeAmbience': true,
      'kineticImpact': true,
    },
    this.soundSettings = const {
      'moveSounds': true,
      'captureSounds': true,
      'alertSounds': true,
    },
    this.academySoundSettings = const {
      'moveSounds': true,
      'captureSounds': true,
      'alertSounds': true,
      'outcomeSounds': true,
      'coachSounds': true,
      'ambientClicks': true,
    },
    this.bulletDominance = 0.0,
    this.blitzDominance = 0.0,
    this.rapidDominance = 0.0,
    this.userName = 'Apprentice',
    this.userAvatarPath = 'assets/persona/user_profile_0.png',
    this.activeRatedMatchId,
    this.activeRatedMatchOpponentId,
    this.isNotificationsEnabled = false,
    this.dailyBriefingEnabled = true,
    this.streakProtectionEnabled = true,
    this.weeklyDiagnosticsEnabled = true,
    this.milestonesEnabled = true,
    this.dailyBriefingTime = '09:00',
    this.streakWarningHoursBeforeReset = 4,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00',
    this.quietHoursEnd = '08:00',
  });

  AppSettings copyWith({
    String? boardThemeId,
    bool? isSoundEnabled,
    bool? isGameSoundEnabled,
    bool? isAcademySoundEnabled,
    bool? isMusicEnabled,
    bool? isAnimationsEnabled,
    bool? isHapticsEnabled,
    bool? showCoordinates,
    String? engineLevel,
    String? bottomAvatarId,
    bool? isAiOperational,
    bool? quickPlay,
    int? totalTimeMinutes,
    int? incrementSeconds,
    Map<String, bool>? animationSettings,
    Map<String, bool>? soundSettings,
    Map<String, bool>? academySoundSettings,
    String? gameMode,
    bool? isRatedMode,
    int? consolidatedRating,
    int? bulletElo,
    int? blitzElo,
    int? rapidElo,
    Object? lastRatedGameTimestampMs = const Object(),
    int? recalibrationGamesRemaining,
    int? decayIntervalsApplied,
    int? totalRatedGamesCount,
    int? bulletGamesClassic,
    int? bulletGames960,
    int? blitzGamesClassic,
    int? blitzGames960,
    int? rapidGamesClassic,
    int? rapidGames960,
    int? totalWinningStreak,
    int? bulletStreak,
    int? blitzStreak,
    int? rapidStreak,
    bool? academyHouseAnimations,
    bool? academyHouseColorFonts,
    bool? academyHouseBoldEmphasis,
    bool? academyHouseTypingEffect,
    double? bulletDominance,
    double? blitzDominance,
    double? rapidDominance,
    String? userName,
    String? userAvatarPath,
    Object? activeRatedMatchId = const Object(),
    Object? activeRatedMatchOpponentId = const Object(),
    bool? isNotificationsEnabled,
    bool? dailyBriefingEnabled,
    bool? streakProtectionEnabled,
    bool? weeklyDiagnosticsEnabled,
    bool? milestonesEnabled,
    String? dailyBriefingTime,
    int? streakWarningHoursBeforeReset,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return AppSettings(
      boardThemeId: boardThemeId ?? this.boardThemeId,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isGameSoundEnabled: isGameSoundEnabled ?? this.isGameSoundEnabled,
      isAcademySoundEnabled: isAcademySoundEnabled ?? this.isAcademySoundEnabled,
      isMusicEnabled: isMusicEnabled ?? this.isMusicEnabled,
      isAnimationsEnabled: isAnimationsEnabled ?? this.isAnimationsEnabled,
      isHapticsEnabled: isHapticsEnabled ?? this.isHapticsEnabled,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      engineLevel: engineLevel ?? this.engineLevel,
      bottomAvatarId: bottomAvatarId ?? this.bottomAvatarId,
      isAiOperational: isAiOperational ?? this.isAiOperational,
      quickPlay: quickPlay ?? this.quickPlay,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
      incrementSeconds: incrementSeconds ?? this.incrementSeconds,
      animationSettings: animationSettings ?? this.animationSettings,
      soundSettings: soundSettings ?? this.soundSettings,
      academySoundSettings: academySoundSettings ?? this.academySoundSettings,
      gameMode: gameMode ?? this.gameMode,
      isRatedMode: isRatedMode ?? this.isRatedMode,
      consolidatedRating: consolidatedRating ?? this.consolidatedRating,
      bulletElo: bulletElo ?? this.bulletElo,
      blitzElo: blitzElo ?? this.blitzElo,
      rapidElo: rapidElo ?? this.rapidElo,
      lastRatedGameTimestampMs: identical(lastRatedGameTimestampMs, const Object())
          ? this.lastRatedGameTimestampMs
          : lastRatedGameTimestampMs as int?,
      recalibrationGamesRemaining: recalibrationGamesRemaining ?? this.recalibrationGamesRemaining,
      decayIntervalsApplied: decayIntervalsApplied ?? this.decayIntervalsApplied,
      totalRatedGamesCount: totalRatedGamesCount ?? this.totalRatedGamesCount,
      bulletGamesClassic: bulletGamesClassic ?? this.bulletGamesClassic,
      bulletGames960: bulletGames960 ?? this.bulletGames960,
      blitzGamesClassic: blitzGamesClassic ?? this.blitzGamesClassic,
      blitzGames960: blitzGames960 ?? this.blitzGames960,
      rapidGamesClassic: rapidGamesClassic ?? this.rapidGamesClassic,
      rapidGames960: rapidGames960 ?? this.rapidGames960,
      totalWinningStreak: totalWinningStreak ?? this.totalWinningStreak,
      bulletStreak: bulletStreak ?? this.bulletStreak,
      blitzStreak: blitzStreak ?? this.blitzStreak,
      rapidStreak: rapidStreak ?? this.rapidStreak,
      academyHouseAnimations: academyHouseAnimations ?? this.academyHouseAnimations,
      academyHouseColorFonts: academyHouseColorFonts ?? this.academyHouseColorFonts,
      academyHouseBoldEmphasis: academyHouseBoldEmphasis ?? this.academyHouseBoldEmphasis,
      academyHouseTypingEffect: academyHouseTypingEffect ?? this.academyHouseTypingEffect,
      bulletDominance: bulletDominance ?? this.bulletDominance,
      blitzDominance: blitzDominance ?? this.blitzDominance,
      rapidDominance: rapidDominance ?? this.rapidDominance,
      userName: userName ?? this.userName,
      userAvatarPath: userAvatarPath ?? this.userAvatarPath,
      activeRatedMatchId: identical(activeRatedMatchId, const Object())
          ? this.activeRatedMatchId
          : activeRatedMatchId as String?,
      activeRatedMatchOpponentId: identical(activeRatedMatchOpponentId, const Object())
          ? this.activeRatedMatchOpponentId
          : activeRatedMatchOpponentId as String?,
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      dailyBriefingEnabled: dailyBriefingEnabled ?? this.dailyBriefingEnabled,
      streakProtectionEnabled: streakProtectionEnabled ?? this.streakProtectionEnabled,
      weeklyDiagnosticsEnabled: weeklyDiagnosticsEnabled ?? this.weeklyDiagnosticsEnabled,
      milestonesEnabled: milestonesEnabled ?? this.milestonesEnabled,
      dailyBriefingTime: dailyBriefingTime ?? this.dailyBriefingTime,
      streakWarningHoursBeforeReset: streakWarningHoursBeforeReset ?? this.streakWarningHoursBeforeReset,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }

  Map<String, dynamic> toJson() => {
    'boardThemeId': boardThemeId,
    'isSoundEnabled': isSoundEnabled,
    'isGameSoundEnabled': isGameSoundEnabled,
    'isAcademySoundEnabled': isAcademySoundEnabled,
    'isMusicEnabled': isMusicEnabled,
    'isAnimationsEnabled': isAnimationsEnabled,
    'isHapticsEnabled': isHapticsEnabled,
    'showCoordinates': showCoordinates,
    'engineLevel': engineLevel,
    'bottomAvatarId': bottomAvatarId,
    'isAiOperational': isAiOperational,
    'quickPlay': quickPlay,
    'totalTimeMinutes': totalTimeMinutes,
    'incrementSeconds': incrementSeconds,
    'gameMode': gameMode,
    'isRatedMode': isRatedMode,
    'consolidatedRating': consolidatedRating,
    'bulletElo': bulletElo,
    'blitzElo': blitzElo,
    'rapidElo': rapidElo,
    'lastRatedGameTimestampMs': lastRatedGameTimestampMs,
    'recalibrationGamesRemaining': recalibrationGamesRemaining,
    'decayIntervalsApplied': decayIntervalsApplied,
    'totalRatedGamesCount': totalRatedGamesCount,
    'bulletGamesClassic': bulletGamesClassic,
    'bulletGames960': bulletGames960,
    'blitzGamesClassic': blitzGamesClassic,
    'blitzGames960': blitzGames960,
    'rapidGamesClassic': rapidGamesClassic,
    'rapidGames960': rapidGames960,
    'totalWinningStreak': totalWinningStreak,
    'bulletStreak': bulletStreak,
    'blitzStreak': blitzStreak,
    'rapidStreak': rapidStreak,
    'animationSettings': animationSettings,
    'soundSettings': soundSettings,
    'academySoundSettings': academySoundSettings,
    'academyHouseAnimations': academyHouseAnimations,
    'academyHouseColorFonts': academyHouseColorFonts,
    'academyHouseBoldEmphasis': academyHouseBoldEmphasis,
    'academyHouseTypingEffect': academyHouseTypingEffect,
    'bulletDominance': bulletDominance,
    'blitzDominance': blitzDominance,
    'rapidDominance': rapidDominance,
    'userName': userName,
    'userAvatarPath': userAvatarPath,
    'activeRatedMatchId': activeRatedMatchId,
    'activeRatedMatchOpponentId': activeRatedMatchOpponentId,
    'isNotificationsEnabled': isNotificationsEnabled,
    'dailyBriefingEnabled': dailyBriefingEnabled,
    'streakProtectionEnabled': streakProtectionEnabled,
    'weeklyDiagnosticsEnabled': weeklyDiagnosticsEnabled,
    'milestonesEnabled': milestonesEnabled,
    'dailyBriefingTime': dailyBriefingTime,
    'streakWarningHoursBeforeReset': streakWarningHoursBeforeReset,
    'quietHoursEnabled': quietHoursEnabled,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    String level = json['engineLevel'] ?? 'avatar_6';
    if (level == 'A') {
      level = 'avatar_9';
    } else if (level == 'B') {
      level = 'avatar_8';
    } else if (level == 'C') {
      level = 'avatar_6';
    } else if (level == 'D') {
      level = 'avatar_4';
    } else if (level == 'E') {
      level = 'avatar_2';
    }

    String bottomLevel = json['bottomAvatarId'] ?? 'avatar_6';
    if (bottomLevel == 'A') {
      bottomLevel = 'avatar_9';
    } else if (bottomLevel == 'B') {
      bottomLevel = 'avatar_8';
    } else if (bottomLevel == 'C') {
      bottomLevel = 'avatar_6';
    } else if (bottomLevel == 'D') {
      bottomLevel = 'avatar_4';
    } else if (bottomLevel == 'E') {
      bottomLevel = 'avatar_2';
    }

    final legacyElo = json['userFideRating'] ?? 400;
    final legacyCount = json['ratedGamesCount'] ?? 0;
    final legacyStreak = json['currentWinningStreak'] ?? 0;

    return AppSettings(
      boardThemeId: json['boardThemeId'] ?? 'classic',
      isSoundEnabled: json['isSoundEnabled'] ?? true,
      isGameSoundEnabled: json['isGameSoundEnabled'] ?? true,
      isAcademySoundEnabled: json['isAcademySoundEnabled'] ?? true,
      isMusicEnabled: json['isMusicEnabled'] ?? false,
      isAnimationsEnabled: json['isAnimationsEnabled'] ?? true,
      isHapticsEnabled: json['isHapticsEnabled'] ?? true,
      showCoordinates: json['showCoordinates'] ?? true,
      engineLevel: level,
      bottomAvatarId: bottomLevel,
      isAiOperational: json['isAiOperational'] ?? true,
      quickPlay: json['quickPlay'] ?? false,
      totalTimeMinutes: json['totalTimeMinutes'] ?? 10,
      incrementSeconds: json['incrementSeconds'] ?? 0,
      gameMode: json['gameMode'] ?? 'classic',
      isRatedMode: json['isRatedMode'] ?? true,
      consolidatedRating: json['consolidatedRating'] ?? legacyElo,
      bulletElo: json['bulletElo'] ?? legacyElo,
      blitzElo: json['blitzElo'] ?? legacyElo,
      rapidElo: json['rapidElo'] ?? legacyElo,
      lastRatedGameTimestampMs: json['lastRatedGameTimestampMs'] as int?,
      recalibrationGamesRemaining: json['recalibrationGamesRemaining'] ?? 0,
      decayIntervalsApplied: json['decayIntervalsApplied'] ?? 0,
      totalRatedGamesCount: json['totalRatedGamesCount'] ?? legacyCount,
      bulletGamesClassic: json['bulletGamesClassic'] ?? 0,
      bulletGames960: json['bulletGames960'] ?? 0,
      blitzGamesClassic: json['blitzGamesClassic'] ?? 0,
      blitzGames960: json['blitzGames960'] ?? 0,
      rapidGamesClassic: json['rapidGamesClassic'] ?? 0,
      rapidGames960: json['rapidGames960'] ?? 0,
      totalWinningStreak: json['totalWinningStreak'] ?? legacyStreak,
      bulletStreak: json['bulletStreak'] ?? 0,
      blitzStreak: json['blitzStreak'] ?? 0,
      rapidStreak: json['rapidStreak'] ?? 0,
      academyHouseAnimations: json['academyHouseAnimations'] ?? true,
      academyHouseColorFonts: json['academyHouseColorFonts'] ?? true,
      academyHouseBoldEmphasis: json['academyHouseBoldEmphasis'] ?? true,
      academyHouseTypingEffect: json['academyHouseTypingEffect'] ?? true,
      animationSettings: json['animationSettings'] != null
          ? Map<String, bool>.from(json['animationSettings'])
          : const {
              'pieceMotion': true,
              'feedback': true,
              'indicators': true,
              'themeEffects': true,
              'themeAmbience': true,
              'kineticImpact': true,
            },
      soundSettings: json['soundSettings'] != null
          ? Map<String, bool>.from(json['soundSettings'])
          : const {
              'moveSounds': true,
              'captureSounds': true,
              'alertSounds': true,
            },
      academySoundSettings: json['academySoundSettings'] != null
          ? Map<String, bool>.from(json['academySoundSettings'])
          : const {
              'moveSounds': true,
              'captureSounds': true,
              'alertSounds': true,
              'outcomeSounds': true,
              'coachSounds': true,
              'ambientClicks': true,
            },
      bulletDominance: (json['bulletDominance'] ?? 0.0).toDouble(),
      blitzDominance: (json['blitzDominance'] ?? 0.0).toDouble(),
      rapidDominance: (json['rapidDominance'] ?? 0.0).toDouble(),
      userName: json['userName'] ?? 'Apprentice',
      userAvatarPath: json['userAvatarPath'] ?? 'assets/persona/user_profile_0.png',
      activeRatedMatchId: json['activeRatedMatchId'] as String?,
      activeRatedMatchOpponentId: json['activeRatedMatchOpponentId'] as String?,
      isNotificationsEnabled: json['isNotificationsEnabled'] ?? false,
      dailyBriefingEnabled: json['dailyBriefingEnabled'] ?? true,
      streakProtectionEnabled: json['streakProtectionEnabled'] ?? true,
      weeklyDiagnosticsEnabled: json['weeklyDiagnosticsEnabled'] ?? true,
      milestonesEnabled: json['milestonesEnabled'] ?? true,
      dailyBriefingTime: json['dailyBriefingTime'] ?? '09:00',
      streakWarningHoursBeforeReset: json['streakWarningHoursBeforeReset'] ?? 4,
      quietHoursEnabled: json['quietHoursEnabled'] ?? false,
      quietHoursStart: json['quietHoursStart'] ?? '22:00',
      quietHoursEnd: json['quietHoursEnd'] ?? '08:00',
    );
  }
}

class SettingsRepository {
  static const _fileName = 'app_settings.json';

  // In-memory cache eliminates redundant disk reads.
  AppSettings? _cache;

  // Serial update queue: each update waits for the previous to finish,
  // preventing concurrent read-modify-write races (Bug C-01).
  Future<void> _queue = Future.value();

  /// Clears the in-memory cache (call before forcing a fresh disk read,
  /// e.g. after a cloud restore).
  void clearCache() => _cache = null;

  Future<AppSettings> loadSettings({bool forceReload = false}) async {
    if (!forceReload && _cache != null) return _cache!;

    final file = await _getFile();
    if (!await file.exists()) {
      _cache = AppSettings();
      return _cache!;
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        _cache = AppSettings();
        return _cache!;
      }

      final decoded = jsonDecode(raw);
      _cache = AppSettings.fromJson(Map<String, dynamic>.from(decoded));
      return _cache!;
    } catch (e) {
      _cache = AppSettings();
      return _cache!;
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    _cache = settings;
    final file = await _getFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }

  /// Atomically reads the current settings, applies [updater], and saves.
  /// Calls are serialised so concurrent updates never clobber each other
  /// (fixes the read-then-write race condition in Bug C-01).
  Future<AppSettings> updateSettings(
    AppSettings Function(AppSettings current) updater,
  ) {
    // Chain onto the existing queue — ensures sequential execution.
    final next = _queue.then((_) async {
      final current = await loadSettings();
      final updated = updater(current);
      await saveSettings(updated);
      return updated;
    });
    // Store the new tail of the queue (discard result type for chaining).
    _queue = next.then((_) {});
    return next;
  }

  Future<File> _getFile() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return File(p.join(supportDirectory.path, _fileName));
  }
}
