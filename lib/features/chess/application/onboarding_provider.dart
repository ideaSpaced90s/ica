import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tutorial_provider.dart';
import '../presentation/mobile_navigation_shell.dart';

// Global keys for dashboard guided tour spotlight targets
final drawerMenuButtonKey = GlobalKey(debugLabel: 'drawerMenuButtonKey');
final profileCardKey = GlobalKey(debugLabel: 'profileCardKey');
final arenaGridKey = GlobalKey(debugLabel: 'arenaGridKey');

// Global keys for app tour spotlight targets (page-level content areas)
final arenaPageKey = GlobalKey(debugLabel: 'arenaPageKey');
final academyPageKey = GlobalKey(debugLabel: 'academyPageKey');
final puzzlePageKey = GlobalKey(debugLabel: 'puzzlePageKey');
final analysisPageKey = GlobalKey(debugLabel: 'analysisPageKey');

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

/// State notifier for the Dashboard Spotlight Tour steps (0 = Profile, 1 = Arena, 2 = Menu, null = done).
class DashboardTourStepNotifier extends StateNotifier<int?> {
  DashboardTourStepNotifier() : super(null);

  void startTour() {
    state = 0;
  }

  void nextStep() {
    if (state == null) return;
    if (state! < 2) {
      state = state! + 1;
    } else {
      state = null; // Tour finished
    }
  }

  void skipTour() {
    state = null;
  }
}

final dashboardTourStepProvider = StateNotifierProvider<DashboardTourStepNotifier, int?>((ref) {
  return DashboardTourStepNotifier();
});

/// State notifier for the App Feature Tour (Arena, Academy, Puzzles, Analysis Lab, Navigation).
/// Steps: 0 = Arena, 1 = Academy, 2 = Puzzles, 3 = Analysis Lab, 4 = Navigation. null = not active.
class AppTourStepNotifier extends StateNotifier<int?> {
  AppTourStepNotifier() : super(null);

  void startTour() {
    state = 0;
  }

  void nextStep(WidgetRef ref) {
    if (state == null) return;
    if (state! < 4) {
      state = state! + 1;
    } else {
      // App Tour complete — hand off to Dashboard Tour
      state = null;
      ref.read(dashboardTourStepProvider.notifier).startTour();
    }
  }

  void skipTour(WidgetRef ref) {
    state = null;
    // Skipping App Tour also launches Dashboard Tour
    ref.read(dashboardTourStepProvider.notifier).startTour();
  }

  void cancelTour() {
    state = null;
  }
}

final appTourStepProvider = StateNotifierProvider<AppTourStepNotifier, int?>((ref) {
  return AppTourStepNotifier();
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
      // Milestone 3: Onboarding complete — launch App Tour, then Dashboard Tour
      ref.read(isOnboardingProvider.notifier).state = false;

      // Save welcome guide completed in SharedPreferences
      final repo = ref.read(tutorialProgressRepositoryProvider);
      repo.setWelcomeGuideSeen(true);

      // Navigate to Arena (first App Tour stop)
      ref.read(mobileNavIndexProvider.notifier).state = 1;

      // Start App Tour
      ref.read(appTourStepProvider.notifier).startTour();
    }
  }
}
