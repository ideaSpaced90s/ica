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
    for (final lesson in TutorialLessonsDatabase.lessons.where((l) => l.chapterId >= 24)) {
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

  test('guided tutorial paths start at the selected level and end at chapter 54', () {
    expect(GuidedTutorialFlow.pathFor(GuidedTutorialLevel.basic).first, 1);
    expect(GuidedTutorialFlow.pathFor(GuidedTutorialLevel.basic).last, kTutorialChapterCount);
    expect(GuidedTutorialFlow.pathFor(GuidedTutorialLevel.basic).length, 54);

    expect(GuidedTutorialFlow.pathFor(GuidedTutorialLevel.intermediate).first, 10);
    expect(GuidedTutorialFlow.pathFor(GuidedTutorialLevel.intermediate).last, kTutorialChapterCount);
    expect(GuidedTutorialFlow.pathFor(GuidedTutorialLevel.intermediate).length, 45);

    expect(GuidedTutorialFlow.pathFor(GuidedTutorialLevel.advanced).first, 24);
    expect(GuidedTutorialFlow.pathFor(GuidedTutorialLevel.advanced).last, kTutorialChapterCount);
    expect(GuidedTutorialFlow.pathFor(GuidedTutorialLevel.advanced).length, 31);
  });

  test('guided tutorial advances sequentially through all remaining chapters', () {
    for (var chapterId = 1; chapterId < kTutorialChapterCount; chapterId++) {
      expect(GuidedTutorialFlow.nextChapterAfter(chapterId), chapterId + 1);
      expect(GuidedTutorialFlow.isCompleteAfter(chapterId), isFalse);
    }

    expect(GuidedTutorialFlow.nextChapterAfter(kTutorialChapterCount), isNull);
    expect(GuidedTutorialFlow.isCompleteAfter(kTutorialChapterCount), isTrue);
  });
}
