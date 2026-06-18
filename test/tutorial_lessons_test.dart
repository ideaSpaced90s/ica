import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kingslayer_chess/features/chess/application/onboarding_provider.dart';
import 'package:kingslayer_chess/features/chess/application/tutorial_provider.dart';
import 'package:kingslayer_chess/features/chess/data/tutorial_lessons.dart';
import 'package:kingslayer_chess/features/chess/data/tutorial_progress_repository.dart';
import 'package:kingslayer_chess/features/chess/domain/models/tutorial_constants.dart';
import 'package:kingslayer_chess/features/chess/domain/models/tutorial_lesson.dart';
import 'package:kingslayer_chess/features/chess/domain/models/tutorial_progress.dart';
import 'package:kingslayer_chess/features/chess/application/chess_provider.dart';
import 'package:kingslayer_chess/features/chess/presentation/mobile_navigation_shell.dart';
import 'package:kingslayer_chess/features/chess/services/chess_sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      return '.';
    },
  );

  test('tutorial chapters are sequential and complete', () {
    final lessons = TutorialLessonsDatabase.lessons;

    expect(lessons.length, kTutorialChapterCount);
    for (var i = 0; i < lessons.length; i++) {
      expect(lessons[i].chapterId, i + 1);
      expect(lessons[i].steps, isNotEmpty);
    }
  });

  test('all tutorial setup FENs are loadable', () {
    for (final lesson in TutorialLessonsDatabase.lessons) {
      final board = chess_lib.Chess();
      expect(board.load(lesson.setupFen), isTrue, reason: 'Chapter ${lesson.chapterId}');
    }
  });

  test('advanced chapter scripted and expected moves are legal in sequence', () {
    // Group 5 onward (ch 30+) are scripted openings and tactics — validate move legality
    for (final lesson in TutorialLessonsDatabase.lessons.where((l) => l.chapterId >= 30)) {
      final board = chess_lib.Chess();
      expect(board.load(lesson.setupFen), isTrue, reason: 'Chapter ${lesson.chapterId}');

      for (final step in lesson.steps) {
        if (step.resetToFen != null) {
          expect(board.load(step.resetToFen!), isTrue, reason: 'Chapter ${lesson.chapterId} reset');
        }

        final move = step.scriptedMove ??
            (step.type == TutorialStepType.awaitMove ? step.expectedMove : null);
        if (move == null) continue;

        final from = move.substring(0, 2);
        final to = move.substring(2, 4);
        final promotion = move.length > 4 ? move.substring(4, 5) : 'q';

        final result = board.move({
          'from': from,
          'to': to,
          'promotion': promotion,
        });

        expect(
          result,
          isTrue,
          reason: 'Chapter ${lesson.chapterId}: ${step.dialogue} ($move)',
        );
      }
    }
  });

  test('guided tutorial path covers Foundations only (Chapters 1–9)', () {
    final path = GuidedTutorialFlow.pathFor(GuidedTutorialLevel.foundations);
    expect(path.first, 1);
    expect(path.last, GuidedTutorialFlow.lastGuidedChapter);
    expect(path.length, 9);
  });

  test('guided tutorial advances through chapters 1–9 then stops', () {
    for (var chapterId = 1; chapterId < GuidedTutorialFlow.lastGuidedChapter; chapterId++) {
      expect(GuidedTutorialFlow.nextChapterAfter(chapterId), chapterId + 1);
      expect(GuidedTutorialFlow.isCompleteAfter(chapterId), isFalse);
    }

    // Chapter 9 is the final guided chapter
    expect(GuidedTutorialFlow.nextChapterAfter(GuidedTutorialFlow.lastGuidedChapter), isNull);
    expect(GuidedTutorialFlow.isCompleteAfter(GuidedTutorialFlow.lastGuidedChapter), isTrue);
  });

  test('total chapter count is 55 (Practice Challenges and Graduation Match removed)', () {
    expect(kTutorialChapterCount, 55);
    expect(TutorialLessonsDatabase.lessons.length, 55);
  });

  test('final chapter is Steinitz\'s Majority (chapter 55)', () {
    final lastLesson = TutorialLessonsDatabase.lessons.last;
    expect(lastLesson.chapterId, 55);
    expect(lastLesson.title, "Steinitz's Majority");
  });

  test('startGuidedTour loads Chapter 1 directly and hides selection screen', () async {
    final fakeRepo = FakeTutorialProgressRepository();
    final fakeSound = FakeChessSoundService();

    final container = ProviderContainer(
      overrides: [
        tutorialProgressRepositoryProvider.overrideWithValue(fakeRepo),
        chessSoundServiceProvider.overrideWithValue(fakeSound),
      ],
    );
    addTearDown(container.dispose);

    // Initial state expectations
    expect(container.read(isOnboardingProvider), isFalse);
    expect(container.read(showChapterSelectionProvider), isTrue);

    final widgetRef = FakeWidgetRef(container);
    OnboardingService(widgetRef).startGuidedTour(GuidedTutorialLevel.foundations);

    // Assert onboarding and navigation states
    expect(container.read(isOnboardingProvider), isTrue);
    expect(container.read(showWelcomeDialogProvider), isFalse);
    expect(container.read(onboardingTargetChapterProvider), 1);
    expect(container.read(showChapterSelectionProvider), isFalse);
    expect(container.read(mobileNavIndexProvider), 7);

    // Assert the chapter was loaded
    final tutorialState = container.read(tutorialProvider);
    expect(tutorialState.currentChapterIndex, 1);
    expect(tutorialState.isChapterComplete, isFalse);
  });
}

class FakeTutorialProgressRepository extends Fake implements TutorialProgressRepository {
  bool welcomeSeen = false;

  @override
  Future<TutorialProgress> loadProgress() async {
    return const TutorialProgress();
  }

  @override
  bool hasSeenWelcomeGuide() => welcomeSeen;

  @override
  bool getIsGoogleSignedIn() => false;

  @override
  Future<void> setWelcomeGuideSeen(bool value) async {
    welcomeSeen = value;
  }

  @override
  Future<void> saveActiveSession({
    required int chapterIndex,
    required int stepIndex,
    required String fenSnapshot,
  }) async {}

  @override
  Future<void> clearActiveSession() async {}
}

class FakeChessSoundService extends Fake implements ChessSoundService {
  @override
  void playSfx(SoundEffect effect) {}
}

class FakeWidgetRef {
  final ProviderContainer container;
  FakeWidgetRef(this.container);

  T read<T>(dynamic provider) => container.read(provider);
}
