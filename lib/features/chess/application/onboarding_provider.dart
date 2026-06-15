import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/tutorial_constants.dart';
import '../presentation/mobile_navigation_shell.dart';
import 'tutorial_provider.dart';

/// Provider tracking whether the user is currently in the active onboarding tutorial flow.
final isOnboardingProvider = StateProvider<bool>((ref) => false);

/// Provider tracking the active target chapter during onboarding.
final onboardingTargetChapterProvider = StateProvider<int>((ref) => 1);

/// Provider tracking whether the chapter selection screen should be visible.
final showChapterSelectionProvider = StateProvider<bool>((ref) => true);

/// Provider tracking whether the welcome guide dialog should be displayed.
final showWelcomeDialogProvider = StateProvider<bool>((ref) {
  final repo = ref.watch(tutorialProgressRepositoryProvider);
  return !repo.hasSeenWelcomeGuide();
});

/// Providers tracking whether the page welcome intros should be displayed.
final showArenaIntroProvider = StateProvider<bool>((ref) {
  final repo = ref.watch(tutorialProgressRepositoryProvider);
  return !repo.hasSeenArenaIntro();
});

final showBattlegroundIntroProvider = StateProvider<bool>((ref) {
  final repo = ref.watch(tutorialProgressRepositoryProvider);
  return !repo.hasSeenBattlegroundIntro();
});

final showPuzzlesIntroProvider = StateProvider<bool>((ref) {
  final repo = ref.watch(tutorialProgressRepositoryProvider);
  return !repo.hasSeenPuzzlesIntro();
});

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
  final WidgetRef ref;

  OnboardingService(this.ref);

  void startGuidedTour(GuidedTutorialLevel level) {
    ref.read(isOnboardingProvider.notifier).state = true;
    ref.read(showWelcomeDialogProvider.notifier).state = false;
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
