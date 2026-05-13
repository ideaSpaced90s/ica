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
    this.animationSettings = const {
      'pieceMotion': true,
      'feedback': true,
      'indicators': true,
      'themeEffects': true,
      'themeAmbience': true,
      'kineticImpact': true,
    },
  });

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
    'animationSettings': animationSettings,
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
