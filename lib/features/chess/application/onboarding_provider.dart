import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tutorial_provider.dart';
import '../presentation/mobile_navigation_shell.dart';

/// Provider tracking whether the user is currently in the active onboarding tutorial flow.
final isOnboardingProvider = StateProvider<bool>((ref) => false);

/// Provider tracking the active target chapter during onboarding (1, 10, or 14).
final onboardingTargetChapterProvider = StateProvider<int>((ref) => 1);

/// Provider tracking whether the chapter selection screen should be visible.
final showChapterSelectionProvider = StateProvider<bool>((ref) => true);

/// Provider tracking whether the welcome guide dialog should be displayed.
final showWelcomeDialogProvider = StateProvider<bool>((ref) {
  final repo = ref.watch(tutorialProgressRepositoryProvider);
  return !repo.hasSeenWelcomeGuide();
});

/// Service class to handle the custom onboarding skip milestones.
class OnboardingService {
  final WidgetRef ref;

  OnboardingService(this.ref);

  void skipToNextMilestone(int currentChapterId) {
    if (currentChapterId < 10) {
      // Milestone 1: Skip to Chapter 10 (Understanding Check)
      ref.read(onboardingTargetChapterProvider.notifier).state = 10;
      ref.read(showChapterSelectionProvider.notifier).state = true;
    } else if (currentChapterId < 14) {
      // Milestone 2: Skip to Chapter 14 (Kingside Castling)
      ref.read(onboardingTargetChapterProvider.notifier).state = 14;
      ref.read(showChapterSelectionProvider.notifier).state = true;
    } else {
      // Milestone 3: Onboarding complete — land directly on Dashboard
      ref.read(isOnboardingProvider.notifier).state = false;

      // Save welcome guide completed in SharedPreferences
      final repo = ref.read(tutorialProgressRepositoryProvider);
      repo.setWelcomeGuideSeen(true);

      // Navigate directly to Dashboard (tab index 0)
      ref.read(mobileNavIndexProvider.notifier).state = 0;
    }
  }
}
