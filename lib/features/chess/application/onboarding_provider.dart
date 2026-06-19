import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/tutorial_constants.dart';
import '../presentation/mobile_navigation_shell.dart';
import 'chess_provider.dart';
import 'tutorial_provider.dart';

import 'var_notifier.dart';

/// Provider tracking whether the user is currently in the active onboarding tutorial flow.
final isOnboardingProvider = NotifierProvider<VarNotifier<bool>, bool>(() => VarNotifier(() => false));

/// Provider tracking the active target chapter during onboarding.
final onboardingTargetChapterProvider = NotifierProvider<VarNotifier<int>, int>(() => VarNotifier(() => 1));

/// Provider tracking whether the chapter selection screen should be visible.
final showChapterSelectionProvider = NotifierProvider<VarNotifier<bool>, bool>(() => VarNotifier(() => true));

/// Provider tracking whether the notification prompt should be shown.
class ShowNotificationPrompt extends Notifier<bool> {
  static bool _dismissedInSession = false;

  @override
  bool build() {
    if (_dismissedInSession) {
      return false;
    }
    final repo = ref.watch(tutorialProgressRepositoryProvider);
    final chessState = ref.watch(chessProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;
    if (isGuest) {
      final tutorialState = ref.watch(tutorialProvider);
      final hasCompletedChapter8 = tutorialState.progress.completedChapters.contains(8);
      return !hasCompletedChapter8 && !chessState.isNotificationsEnabled;
    }
    return !repo.hasPromptedNotification() &&
        !chessState.isNotificationsEnabled;
  }

  @override
  set state(bool value) {
    if (value) {
      _dismissedInSession = false;
    } else {
      _dismissedInSession = true;
    }
    super.state = value;
  }
}
final showNotificationPromptProvider = NotifierProvider<ShowNotificationPrompt, bool>(ShowNotificationPrompt.new);

/// Provider tracking whether the welcome guide dialog should be displayed.
class ShowWelcomeDialog extends Notifier<bool> {
  static bool _dismissedInSession = false;

  @override
  bool build() {
    if (_dismissedInSession) {
      return false;
    }
    final repo = ref.watch(tutorialProgressRepositoryProvider);
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;
    if (isGuest) {
      final tutorialState = ref.watch(tutorialProvider);
      final hasCompletedChapter8 = tutorialState.progress.completedChapters.contains(8);
      return !hasCompletedChapter8;
    }
    return !repo.hasSeenWelcomeGuide();
  }

  @override
  set state(bool value) {
    if (value) {
      _dismissedInSession = false;
    } else {
      _dismissedInSession = true;
    }
    super.state = value;
  }
}
final showWelcomeDialogProvider = NotifierProvider<ShowWelcomeDialog, bool>(ShowWelcomeDialog.new);

/// Providers tracking whether the page welcome intros should be displayed.
class ShowArenaIntro extends Notifier<bool> {
  @override
  bool build() {
    final repo = ref.watch(tutorialProgressRepositoryProvider);
    return !repo.hasSeenArenaIntro();
  }
  @override
  set state(bool value) => super.state = value;
}
final showArenaIntroProvider = NotifierProvider<ShowArenaIntro, bool>(ShowArenaIntro.new);

class ShowBattlegroundIntro extends Notifier<bool> {
  @override
  bool build() {
    final repo = ref.watch(tutorialProgressRepositoryProvider);
    return !repo.hasSeenBattlegroundIntro();
  }
  @override
  set state(bool value) => super.state = value;
}
final showBattlegroundIntroProvider = NotifierProvider<ShowBattlegroundIntro, bool>(ShowBattlegroundIntro.new);

class ShowPuzzlesIntro extends Notifier<bool> {
  @override
  bool build() {
    final repo = ref.watch(tutorialProgressRepositoryProvider);
    return !repo.hasSeenPuzzlesIntro();
  }
  @override
  set state(bool value) => super.state = value;
}
final showPuzzlesIntroProvider = NotifierProvider<ShowPuzzlesIntro, bool>(ShowPuzzlesIntro.new);

/// The guided tour now only covers Group 1: Foundations (Chapters 1–9).
/// After the user completes Chapter 9, the guided tour ends with a farewell message.
enum GuidedTutorialLevel {
  /// Foundations only — Chapters 1 through 9.
  foundations(1);

  final int startChapter;

  const GuidedTutorialLevel(this.startChapter);
}

class GuidedTutorialFlow {
  static const int firstChapter = 1;

  /// The guided tour covers Foundations only: Chapters 1–9.
  static const int lastGuidedChapter = 9;

  /// Total chapters in the curriculum (used for non-guided navigation).
  static const int totalChapters = kTutorialChapterCount;

  static List<int> pathFor(GuidedTutorialLevel level) {
    return List.generate(
      lastGuidedChapter - level.startChapter + 1,
      (index) => level.startChapter + index,
    );
  }

  static int startChapterFor(GuidedTutorialLevel level) => level.startChapter;

  /// Returns the next chapter in the guided path, or null if Group 1 is complete.
  static int? nextChapterAfter(int currentChapterId) {
    final nextChapter = currentChapterId + 1;
    if (nextChapter > lastGuidedChapter) return null;
    return nextChapter;
  }

  static bool isCompleteAfter(int currentChapterId) {
    return nextChapterAfter(currentChapterId) == null;
  }
}

/// Service class to handle the guided onboarding tutorial path.
class OnboardingService {
  final dynamic ref;

  OnboardingService(this.ref);

  Future<void> dismissNotificationPrompt() async {
    final repo = ref.read(tutorialProgressRepositoryProvider);
    await repo.setPromptedNotification(true);
    ref.read(showNotificationPromptProvider.notifier).state = false;
  }

  void startGuidedTour(GuidedTutorialLevel level) {
    ref.read(isOnboardingProvider.notifier).state = true;
    ref.read(showWelcomeDialogProvider.notifier).state = false;
    final repo = ref.read(tutorialProgressRepositoryProvider);
    unawaited(repo.setWelcomeGuideSeen(true));
    final startChap = GuidedTutorialFlow.startChapterFor(level);
    ref.read(onboardingTargetChapterProvider.notifier).state = startChap;
    ref.read(tutorialProvider.notifier).loadChapter(startChap);
    ref.read(showChapterSelectionProvider.notifier).state = false;
    ref.read(mobileNavIndexProvider.notifier).state = 7;
  }

  void advanceGuidedTutorial(int currentChapterId) {
    final nextChapter = GuidedTutorialFlow.nextChapterAfter(currentChapterId);
    if (nextChapter != null) {
      ref.read(onboardingTargetChapterProvider.notifier).state = nextChapter;
      ref.read(tutorialProvider.notifier).loadChapter(nextChapter);
      ref.read(showChapterSelectionProvider.notifier).state = false;
      return;
    }

    // Group 1 (Foundations) is complete. End the guided tour.
    endGuidedTour(markWelcomeSeen: true);
  }

  void endGuidedTour({bool markWelcomeSeen = true}) {
    ref.read(isOnboardingProvider.notifier).state = false;
    ref.read(tutorialProvider.notifier).dismissCompletionOverlay();
    ref.read(showChapterSelectionProvider.notifier).state = true;

    if (markWelcomeSeen) {
      final repo = ref.read(tutorialProgressRepositoryProvider);
      unawaited(repo.setWelcomeGuideSeen(true));
    }

    ref.read(mobileNavIndexProvider.notifier).state = 0;
  }

  @Deprecated('Use advanceGuidedTutorial instead.')
  void skipToNextMilestone(int currentChapterId) {
    advanceGuidedTutorial(currentChapterId);
  }
}
