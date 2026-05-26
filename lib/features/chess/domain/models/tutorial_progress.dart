import 'tutorial_constants.dart';

class TutorialSettings {
  final bool skipAnimations;
  final bool showSubtitles;
  final int hesitationTimerSeconds;

  const TutorialSettings({
    this.skipAnimations = false,
    this.showSubtitles = true,
    this.hesitationTimerSeconds = 10,
  });

  TutorialSettings copyWith({
    bool? skipAnimations,
    bool? showSubtitles,
    int? hesitationTimerSeconds,
  }) {
    return TutorialSettings(
      skipAnimations: skipAnimations ?? this.skipAnimations,
      showSubtitles: showSubtitles ?? this.showSubtitles,
      hesitationTimerSeconds: hesitationTimerSeconds ?? this.hesitationTimerSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
    'skipAnimations': skipAnimations,
    'showSubtitles': showSubtitles,
    'hesitationTimerSeconds': hesitationTimerSeconds,
  };

  static TutorialSettings fromJson(Map<String, dynamic> json) {
    return TutorialSettings(
      skipAnimations: json['skipAnimations'] as bool? ?? false,
      showSubtitles: json['showSubtitles'] as bool? ?? true,
      hesitationTimerSeconds: json['hesitationTimerSeconds'] as int? ?? 10,
    );
  }
}

class TutorialProgress {
  final Set<int> completedChapters;
  final Set<int> unlockedChapters;

  /// Mapping of chapterId to highest earned star rating (1-3).
  final Map<int, int> stars;
  final int totalXp;
  final TutorialRank currentRank;

  /// Active lesson runtime recovery parameters for the "Resume From Step" workflow.
  final int? activeChapterIndex;
  final int? activeStepIndex;
  final String? activeFenSnapshot;

  /// System layout integrity validation sequence indicator.
  final int tutorialDataVersion;

  final TutorialSettings settings;

  const TutorialProgress({
    this.completedChapters = const {},
    this.unlockedChapters = const {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53}, // All 53 chapters unlocked
    this.stars = const {},
    this.totalXp = 0,
    this.currentRank = TutorialRank.beginner,
    this.activeChapterIndex,
    this.activeStepIndex,
    this.activeFenSnapshot,
    this.tutorialDataVersion = kTutorialDataVersion,
    this.settings = const TutorialSettings(),
  });

  bool get hasActiveSession =>
      activeChapterIndex != null &&
      activeStepIndex != null &&
      activeFenSnapshot != null;

  TutorialProgress copyWith({
    Set<int>? completedChapters,
    Set<int>? unlockedChapters,
    Map<int, int>? stars,
    int? totalXp,
    TutorialRank? currentRank,
    int? activeChapterIndex,
    int? activeStepIndex,
    String? activeFenSnapshot,
    int? tutorialDataVersion,
    TutorialSettings? settings,
    bool clearActiveSession = false,
  }) {
    return TutorialProgress(
      completedChapters: completedChapters ?? this.completedChapters,
      unlockedChapters: unlockedChapters ?? this.unlockedChapters,
      stars: stars ?? this.stars,
      totalXp: totalXp ?? this.totalXp,
      currentRank: currentRank ?? this.currentRank,
      activeChapterIndex: clearActiveSession ? null : (activeChapterIndex ?? this.activeChapterIndex),
      activeStepIndex: clearActiveSession ? null : (activeStepIndex ?? this.activeStepIndex),
      activeFenSnapshot: clearActiveSession ? null : (activeFenSnapshot ?? this.activeFenSnapshot),
      tutorialDataVersion: tutorialDataVersion ?? this.tutorialDataVersion,
      settings: settings ?? this.settings,
    );
  }
}
