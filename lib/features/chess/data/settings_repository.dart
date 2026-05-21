import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppSettings {
  final String boardThemeId;
  final bool isSoundEnabled;
  final bool isMusicEnabled;
  final bool isAnimationsEnabled;
  final bool isHapticsEnabled;
  final bool showCoordinates;
  final String engineLevel;
  final String bottomAvatarId;
  final bool isAiOperational;
  final int totalTimeMinutes;
  final int incrementSeconds;
  final Map<String, bool> animationSettings;
  final String gameMode;
  final bool isRatedMode;
  final int consolidatedRating;
  final int bulletElo;
  final int blitzElo;
  final int rapidElo;
  
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

  AppSettings({
    this.boardThemeId = 'classic',
    this.isSoundEnabled = true,
    this.isMusicEnabled = false,
    this.isAnimationsEnabled = true,
    this.isHapticsEnabled = true,
    this.showCoordinates = true,
    this.engineLevel = 'avatar_6',
    this.bottomAvatarId = 'avatar_6',
    this.isAiOperational = true,
    this.totalTimeMinutes = 10,
    this.incrementSeconds = 0,
    this.gameMode = 'classic',
    this.isRatedMode = true,
    this.consolidatedRating = 1200,
    this.bulletElo = 1200,
    this.blitzElo = 1200,
    this.rapidElo = 1200,
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
    this.bulletDominance = 0.0,
    this.blitzDominance = 0.0,
    this.rapidDominance = 0.0,
    this.userName = 'Apprentice',
    this.userAvatarPath = 'assets/persona/user_profile_0.png',
  });

  AppSettings copyWith({
    String? boardThemeId,
    bool? isSoundEnabled,
    bool? isMusicEnabled,
    bool? isAnimationsEnabled,
    bool? isHapticsEnabled,
    bool? showCoordinates,
    String? engineLevel,
    String? bottomAvatarId,
    bool? isAiOperational,
    int? totalTimeMinutes,
    int? incrementSeconds,
    Map<String, bool>? animationSettings,
    String? gameMode,
    bool? isRatedMode,
    int? consolidatedRating,
    int? bulletElo,
    int? blitzElo,
    int? rapidElo,
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
  }) {
    return AppSettings(
      boardThemeId: boardThemeId ?? this.boardThemeId,
      isSoundEnabled: isSoundEnabled ?? this.isSoundEnabled,
      isMusicEnabled: isMusicEnabled ?? this.isMusicEnabled,
      isAnimationsEnabled: isAnimationsEnabled ?? this.isAnimationsEnabled,
      isHapticsEnabled: isHapticsEnabled ?? this.isHapticsEnabled,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      engineLevel: engineLevel ?? this.engineLevel,
      bottomAvatarId: bottomAvatarId ?? this.bottomAvatarId,
      isAiOperational: isAiOperational ?? this.isAiOperational,
      totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
      incrementSeconds: incrementSeconds ?? this.incrementSeconds,
      animationSettings: animationSettings ?? this.animationSettings,
      gameMode: gameMode ?? this.gameMode,
      isRatedMode: isRatedMode ?? this.isRatedMode,
      consolidatedRating: consolidatedRating ?? this.consolidatedRating,
      bulletElo: bulletElo ?? this.bulletElo,
      blitzElo: blitzElo ?? this.blitzElo,
      rapidElo: rapidElo ?? this.rapidElo,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'boardThemeId': boardThemeId,
    'isSoundEnabled': isSoundEnabled,
    'isMusicEnabled': isMusicEnabled,
    'isAnimationsEnabled': isAnimationsEnabled,
    'isHapticsEnabled': isHapticsEnabled,
    'showCoordinates': showCoordinates,
    'engineLevel': engineLevel,
    'bottomAvatarId': bottomAvatarId,
    'isAiOperational': isAiOperational,
    'totalTimeMinutes': totalTimeMinutes,
    'incrementSeconds': incrementSeconds,
    'gameMode': gameMode,
    'isRatedMode': isRatedMode,
    'consolidatedRating': consolidatedRating,
    'bulletElo': bulletElo,
    'blitzElo': blitzElo,
    'rapidElo': rapidElo,
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
    'academyHouseAnimations': academyHouseAnimations,
    'academyHouseColorFonts': academyHouseColorFonts,
    'academyHouseBoldEmphasis': academyHouseBoldEmphasis,
    'academyHouseTypingEffect': academyHouseTypingEffect,
    'bulletDominance': bulletDominance,
    'blitzDominance': blitzDominance,
    'rapidDominance': rapidDominance,
    'userName': userName,
    'userAvatarPath': userAvatarPath,
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

    final legacyElo = json['userFideRating'] ?? 1200;
    final legacyCount = json['ratedGamesCount'] ?? 0;
    final legacyStreak = json['currentWinningStreak'] ?? 0;

    return AppSettings(
      boardThemeId: json['boardThemeId'] ?? 'classic',
      isSoundEnabled: json['isSoundEnabled'] ?? true,
      isMusicEnabled: json['isMusicEnabled'] ?? false,
      isAnimationsEnabled: json['isAnimationsEnabled'] ?? true,
      isHapticsEnabled: json['isHapticsEnabled'] ?? true,
      showCoordinates: json['showCoordinates'] ?? true,
      engineLevel: level,
      bottomAvatarId: bottomLevel,
      isAiOperational: json['isAiOperational'] ?? true,
      totalTimeMinutes: json['totalTimeMinutes'] ?? 10,
      incrementSeconds: json['incrementSeconds'] ?? 0,
      gameMode: json['gameMode'] ?? 'classic',
      isRatedMode: json['isRatedMode'] ?? true,
      consolidatedRating: json['consolidatedRating'] ?? legacyElo,
      bulletElo: json['bulletElo'] ?? legacyElo,
      blitzElo: json['blitzElo'] ?? legacyElo,
      rapidElo: json['rapidElo'] ?? legacyElo,
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
      bulletDominance: (json['bulletDominance'] ?? 0.0).toDouble(),
      blitzDominance: (json['blitzDominance'] ?? 0.0).toDouble(),
      rapidDominance: (json['rapidDominance'] ?? 0.0).toDouble(),
      userName: json['userName'] ?? 'Apprentice',
      userAvatarPath: json['userAvatarPath'] ?? 'assets/persona/user_profile_0.png',
    );
  }
}

class SettingsRepository {
  static const _fileName = 'app_settings.json';

  Future<AppSettings> loadSettings() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return AppSettings();
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return AppSettings();
      }

      final decoded = jsonDecode(raw);
      return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      return AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    final file = await _getFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(settings.toJson()), flush: true);
  }

  Future<File> _getFile() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return File(p.join(supportDirectory.path, _fileName));
  }
}
