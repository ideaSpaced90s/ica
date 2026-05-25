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

enum GuidedTutorialLevel {
  basic(1),
  intermediate(10),
  advanced(24);

  final int startChapter;

  const GuidedTutorialLevel(this.startChapter);
}

class GuidedTutorialFlow {
  static const int firstChapter = 1;
  static const int lastChapter = kTutorialChapterCount;

  static List<int> pathFor(GuidedTutorialLevel level) {
    return List.generate(
      lastChapter - level.startChapter + 1,
      (index) => level.startChapter + index,
    );
  }

  static int startChapterFor(GuidedTutorialLevel level) => level.startChapter;

  static int? nextChapterAfter(int currentChapterId) {
    final nextChapter = currentChapterId + 1;
    if (nextChapter > lastChapter) return null;
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
    ref.read(onboardingTargetChapterProvider.notifier).state =
        GuidedTutorialFlow.startChapterFor(level);
    ref.read(showChapterSelectionProvider.notifier).state = true;
    ref.read(mobileNavIndexProvider.notifier).state = 6;
  }

  void advanceGuidedTutorial(int currentChapterId) {
    final nextChapter = GuidedTutorialFlow.nextChapterAfter(currentChapterId);
    if (nextChapter != null) {
      ref.read(onboardingTargetChapterProvider.notifier).state = nextChapter;
      ref.read(showChapterSelectionProvider.notifier).state = true;
      return;
    }

    endGuidedTour(markWelcomeSeen: true);
  }

  void endGuidedTour({bool markWelcomeSeen = true}) {
    ref.read(isOnboardingProvider.notifier).state = false;
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
