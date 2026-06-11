import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/application/onboarding_provider.dart';
import 'package:kingslayer_chess/features/chess/data/tutorial_lessons.dart';
import 'package:kingslayer_chess/features/chess/domain/models/tutorial_constants.dart';
import 'package:kingslayer_chess/features/chess/domain/models/tutorial_lesson.dart';

void main() {
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

  test('total chapter count is 52 (Practice Challenges and Graduation Match removed)', () {
    expect(kTutorialChapterCount, 52);
    expect(TutorialLessonsDatabase.lessons.length, 52);
  });

  test('final chapter is Steinitz\'s Majority (chapter 52)', () {
    final lastLesson = TutorialLessonsDatabase.lessons.last;
    expect(lastLesson.chapterId, 52);
    expect(lastLesson.title, "Steinitz's Majority");
  });
}
