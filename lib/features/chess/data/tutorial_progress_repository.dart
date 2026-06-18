import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/tutorial_constants.dart';
import '../domain/models/tutorial_progress.dart';

class TutorialProgressRepository {
  static const String _kVersion = 'tutorial_data_version';
  static const String _kCompleted = 'tutorial_completed_chapters';
  static const String _kUnlocked = 'tutorial_unlocked_chapters';
  static const String _kStars = 'tutorial_stars';
  static const String _kXp = 'tutorial_total_xp';
  static const String _kActiveChapter = 'tutorial_active_chapter';
  static const String _kActiveStep = 'tutorial_active_step';
  static const String _kActiveFen = 'tutorial_active_fen';
  static const String _kSettings = 'tutorial_settings';
  static const String _kWelcomeSeen = 'tutorial_welcome_guide_seen';
  static const String _kNotificationPromptSeen = 'tutorial_notification_prompt_seen';
  static const String _kIsGoogleSignedIn = 'user_is_google_signed_in';
  static const String _kArenaIntroSeen = 'intro_seen_arena';
  static const String _kBattlegroundIntroSeen = 'intro_seen_battleground';
  static const String _kPuzzlesIntroSeen = 'intro_seen_puzzles';
  static const String _kAcademyIntroSeen = 'intro_seen_academy';
  static const String _kAcademyAccessCount = 'academy_access_count';

  final SharedPreferences _prefs;

  TutorialProgressRepository(this._prefs);

  Future<TutorialProgress> loadProgress() async {
    try {
      final storedVersion = _prefs.getInt(_kVersion) ?? 0;

      final completedList = _prefs.getStringList(_kCompleted) ?? [];
      final completed = completedList.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();

      final unlockedList = _prefs.getStringList(_kUnlocked) ?? List.generate(kTutorialChapterCount, (i) => (i + 1).toString());
      final unlocked = unlockedList.map((e) => int.tryParse(e) ?? 0).where((e) => e > 0).toSet();

      final starsString = _prefs.getString(_kStars);
      Map<int, int> stars = {};
      if (starsString != null && starsString.isNotEmpty) {
        final decoded = jsonDecode(starsString) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          final k = int.tryParse(key);
          final v = value as int?;
          if (k != null && v != null) {
            stars[k] = v;
          }
        });
      }

      final totalXp = _prefs.getInt(_kXp) ?? 0;
      final activeChapter = _prefs.getInt(_kActiveChapter);
      final activeStep = _prefs.getInt(_kActiveStep);
      final activeFen = _prefs.getString(_kActiveFen);

      TutorialSettings settings = const TutorialSettings();
      final settingsString = _prefs.getString(_kSettings);
      if (settingsString != null && settingsString.isNotEmpty) {
        settings = TutorialSettings.fromJson(jsonDecode(settingsString) as Map<String, dynamic>);
      }

      TutorialProgress progress = TutorialProgress(
        completedChapters: completed,
        unlockedChapters: unlocked.isEmpty ? {1} : unlocked,
        stars: stars,
        totalXp: totalXp,
        currentRank: TutorialRank.fromXp(totalXp),
        activeChapterIndex: activeChapter,
        activeStepIndex: activeStep,
        activeFenSnapshot: activeFen,
        tutorialDataVersion: storedVersion > 0 ? storedVersion : kTutorialDataVersion,
        settings: settings,
      );

      // Perform non-breaking structural migration if saved layout version is outdated
      if (storedVersion < kTutorialDataVersion) {
        progress = _migrate(storedVersion, kTutorialDataVersion, progress);
        await saveProgress(progress);
      }

      return progress;
    } catch (e) {
      debugPrint('Error loading tutorial progress: $e');
      return const TutorialProgress();
    }
  }

  Future<void> saveProgress(TutorialProgress p) async {
    try {
      await _prefs.setInt(_kVersion, kTutorialDataVersion);
      await _prefs.setStringList(_kCompleted, p.completedChapters.map((e) => e.toString()).toList());
      await _prefs.setStringList(_kUnlocked, p.unlockedChapters.map((e) => e.toString()).toList());
      
      final starsMapString = p.stars.map((key, value) => MapEntry(key.toString(), value));
      await _prefs.setString(_kStars, jsonEncode(starsMapString));
      
      await _prefs.setInt(_kXp, p.totalXp);
      
      if (p.activeChapterIndex != null) {
        await _prefs.setInt(_kActiveChapter, p.activeChapterIndex!);
      } else {
        await _prefs.remove(_kActiveChapter);
      }

      if (p.activeStepIndex != null) {
        await _prefs.setInt(_kActiveStep, p.activeStepIndex!);
      } else {
        await _prefs.remove(_kActiveStep);
      }

      if (p.activeFenSnapshot != null) {
        await _prefs.setString(_kActiveFen, p.activeFenSnapshot!);
      } else {
        await _prefs.remove(_kActiveFen);
      }

      await _prefs.setString(_kSettings, jsonEncode(p.settings.toJson()));
    } catch (e) {
      debugPrint('Error saving tutorial progress: $e');
    }
  }

  /// Fire-and-forget runtime state checkpoint update invoked per successful action.
  Future<void> saveActiveSession({
    required int chapterIndex,
    required int stepIndex,
    required String fenSnapshot,
  }) async {
    try {
      await _prefs.setInt(_kActiveChapter, chapterIndex);
      await _prefs.setInt(_kActiveStep, stepIndex);
      await _prefs.setString(_kActiveFen, fenSnapshot);
    } catch (e) {
      debugPrint('Error autosaving tutorial session: $e');
    }
  }

  Future<void> clearActiveSession() async {
    try {
      await _prefs.remove(_kActiveChapter);
      await _prefs.remove(_kActiveStep);
      await _prefs.remove(_kActiveFen);
    } catch (e) {
      debugPrint('Error clearing tutorial session: $e');
    }
  }

  Future<void> resetAllProgress() async {
    try {
      final keys = _prefs.getKeys().where((k) => k.startsWith('tutorial_')).toList();
      for (final k in keys) {
        await _prefs.remove(k);
      }
      // Re-establish version anchor
      await _prefs.setInt(_kVersion, kTutorialDataVersion);
      await _prefs.setStringList(_kUnlocked, List.generate(kTutorialChapterCount, (i) => (i + 1).toString()));
    } catch (e) {
      debugPrint('Error resetting tutorial progress: $e');
    }
  }

  TutorialProgress _migrate(int fromVersion, int toVersion, TutorialProgress p) {
    // If layout structures have shifted fundamentally, invalidate the active mid-lesson
    // checkpoint so players restart the active lesson gracefully rather than crashing.
    // Completed metrics and structural unlocks remain entirely undisturbed.
    return p.copyWith(
      tutorialDataVersion: toVersion,
      clearActiveSession: true,
    );
  }

  bool getIsGoogleSignedIn() {
    return _prefs.getBool(_kIsGoogleSignedIn) ?? false;
  }

  bool shouldPersistIntroSeen() {
    return getIsGoogleSignedIn();
  }

  Future<void> setIsGoogleSignedIn(bool value) async {
    await _prefs.setBool(_kIsGoogleSignedIn, value);
  }

  bool hasSeenWelcomeGuide() {
    return _prefs.getBool(_kWelcomeSeen) ?? false;
  }

  Future<void> setWelcomeGuideSeen(bool value) async {
    await _prefs.setBool(_kWelcomeSeen, value);
  }

  bool hasSeenArenaIntro() {
    return _prefs.getBool(_kArenaIntroSeen) ?? false;
  }

  Future<void> setArenaIntroSeen(bool value) async {
    await _prefs.setBool(_kArenaIntroSeen, value);
  }

  bool hasSeenBattlegroundIntro() {
    return _prefs.getBool(_kBattlegroundIntroSeen) ?? false;
  }

  Future<void> setBattlegroundIntroSeen(bool value) async {
    await _prefs.setBool(_kBattlegroundIntroSeen, value);
  }

  bool hasSeenPuzzlesIntro() {
    return _prefs.getBool(_kPuzzlesIntroSeen) ?? false;
  }

  Future<void> setPuzzlesIntroSeen(bool value) async {
    await _prefs.setBool(_kPuzzlesIntroSeen, value);
  }

  bool hasSeenAcademyIntro() {
    return _prefs.getBool(_kAcademyIntroSeen) ?? false;
  }

  Future<void> setAcademyIntroSeen(bool value) async {
    await _prefs.setBool(_kAcademyIntroSeen, value);
  }

  int getAcademyAccessCount() {
    return _prefs.getInt(_kAcademyAccessCount) ?? 0;
  }

  Future<void> setAcademyAccessCount(int value) async {
    await _prefs.setInt(_kAcademyAccessCount, value);
  }

  bool hasPromptedNotification() {
    return _prefs.getBool(_kNotificationPromptSeen) ?? false;
  }

  Future<void> setPromptedNotification(bool value) async {
    await _prefs.setBool(_kNotificationPromptSeen, value);
  }
}
