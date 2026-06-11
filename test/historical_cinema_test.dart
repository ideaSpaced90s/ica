import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/domain/models/historical_game.dart';
import 'package:kingslayer_chess/features/chess/domain/models/tutorial_lesson.dart' show MentorMood;
import 'package:kingslayer_chess/features/chess/application/historical_cinema_provider.dart';

void main() {
  group('Historical Games Model Tests', () {
    test('HistoricalGame.fromJson parses valid JSON structure correctly', () {
      final mockJson = {
        "id": 1,
        "category": "Open Horizons & Gambits (cat_tactical)",
        "white": "Adolf Anderssen",
        "black": "Lionel Kieseritzky",
        "year": "1851",
        "event": "The Immortal Game",
        "educationalTheme": "Full piece sacrifice for checkmate",
        "pgn": "1. e4 e5 2. f4 exf4",
        "moves": ["e4", "e5", "f4", "exf4"],
        "fens": [
          "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
          "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1",
          "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2"
        ],
        "annotations": {
          "0": {
            "commentary": "Apprentice. Let us study the famous opening moves...",
            "mood": "calm"
          },
          "2": {
            "commentary": "A bold sacrifice of the f-pawn.",
            "mood": "encouraging"
          }
        }
      };

      final game = HistoricalGame.fromJson(mockJson);

      expect(game.id, 1);
      expect(game.white, "Adolf Anderssen");
      expect(game.black, "Lionel Kieseritzky");
      expect(game.year, "1851");
      expect(game.event, "The Immortal Game");
      expect(game.educationalTheme, "Full piece sacrifice for checkmate");
      expect(game.pgn, "1. e4 e5 2. f4 exf4");
      expect(game.moves, ["e4", "e5", "f4", "exf4"]);
      expect(game.fens.length, 3);
      
      expect(game.annotations.containsKey(0), true);
      expect(game.annotations[0]!.commentary, "Apprentice. Let us study the famous opening moves...");
      expect(game.annotations[0]!.mood, MentorMood.calm);

      expect(game.annotations.containsKey(2), true);
      expect(game.annotations[2]!.commentary, "A bold sacrifice of the f-pawn.");
      expect(game.annotations[2]!.mood, MentorMood.encouraging);
    });
  });

  group('Historical Cinema State Notifier Tests', () {
    final mockGame = HistoricalGame.fromJson({
      "id": 1,
      "category": "Open Horizons",
      "white": "White Player",
      "black": "Black Player",
      "year": "1800",
      "event": "Test Event",
      "educationalTheme": "Test Theme",
      "pgn": "1. e4 e5",
      "moves": ["e4", "e5"],
      "fens": ["fen0", "fen1", "fen2"],
      "annotations": {
        "0": {"commentary": "First move comments", "mood": "calm"},
        "1": {"commentary": "Second move comments", "mood": "encouraging"}
      }
    });

    test('selectGame resets active indices and playback status', () {
      final notifier = HistoricalCinemaNotifier();
      
      // Select the game
      notifier.selectGame(mockGame);
      expect(notifier.state.activeGame, mockGame);
      expect(notifier.state.currentMoveIndex, 0);
      expect(notifier.state.isPlaying, false);

      notifier.dispose();
    });

    test('stepping forward and backward updates currentMoveIndex correctly', () {
      final notifier = HistoricalCinemaNotifier();
      notifier.selectGame(mockGame);

      notifier.nextMove();
      expect(notifier.state.currentMoveIndex, 1);

      notifier.nextMove();
      expect(notifier.state.currentMoveIndex, 2);

      // Should clamp/end on last move
      notifier.nextMove();
      expect(notifier.state.currentMoveIndex, 2);
      expect(notifier.state.isPlaying, false);

      notifier.previousMove();
      expect(notifier.state.currentMoveIndex, 1);

      notifier.jumpToMove(0);
      expect(notifier.state.currentMoveIndex, 0);

      notifier.dispose();
    });
  });
}
