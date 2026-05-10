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
  final int autoPlayDelaySeconds;
  final bool showCoordinates;
  final String engineLevel;
  final bool isAiOperational;
  final int totalTimeMinutes;
  final int incrementSeconds;

  AppSettings({
    this.boardThemeId = 'classic',
    this.isSoundEnabled = true,
    this.isMusicEnabled = false,
    this.isAnimationsEnabled = true,
    this.isHapticsEnabled = true,
    this.autoPlayDelaySeconds = 3,
    this.showCoordinates = true,
    this.engineLevel = 'B',
    this.isAiOperational = true,
    this.totalTimeMinutes = 10,
    this.incrementSeconds = 0,
  });

  Map<String, dynamic> toJson() => {
        'boardThemeId': boardThemeId,
        'isSoundEnabled': isSoundEnabled,
        'isMusicEnabled': isMusicEnabled,
        'isAnimationsEnabled': isAnimationsEnabled,
        'isHapticsEnabled': isHapticsEnabled,
        'autoPlayDelaySeconds': autoPlayDelaySeconds,
        'showCoordinates': showCoordinates,
        'engineLevel': engineLevel,
        'isAiOperational': isAiOperational,
        'totalTimeMinutes': totalTimeMinutes,
        'incrementSeconds': incrementSeconds,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        boardThemeId: json['boardThemeId'] ?? 'classic',
        isSoundEnabled: json['isSoundEnabled'] ?? true,
        isMusicEnabled: json['isMusicEnabled'] ?? false,
        isAnimationsEnabled: json['isAnimationsEnabled'] ?? true,
        isHapticsEnabled: json['isHapticsEnabled'] ?? true,
        autoPlayDelaySeconds: json['autoPlayDelaySeconds'] ?? 3,
        showCoordinates: json['showCoordinates'] ?? true,
        engineLevel: json['engineLevel'] ?? 'B',
        isAiOperational: json['isAiOperational'] ?? true,
        totalTimeMinutes: json['totalTimeMinutes'] ?? 10,
        incrementSeconds: json['incrementSeconds'] ?? 0,
      );
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
