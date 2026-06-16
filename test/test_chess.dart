import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/domain/chess_game.dart';

void main() {
  test('test standard chess properties', () {
    final game = ChessGame(isChess960: false);
    game.makeMove({'from': 'e2', 'to': 'e4'});

    final history = game.moveHistoryLabels();
    expect(history.length, 1);
    expect(history.first, 'e4');
  });

  test('test Chess960 castling and history preservation', () {
    // A Chess960 FEN where the king is on b1 and rook is on h1.
    // The squares between b1 and h1 are clear.
    final fen = 'rk5r/pppppppp/8/8/8/8/PPPPPPPP/RK5R w KQkq - 0 1';
    final game = ChessGame(fen: fen, isChess960: true);

    // Make Chess960 castling move (King at b1, Rook at h1)
    final success = game.makeMove({'from': 'b1', 'to': 'h1'});
    expect(success, true);

    // Verify the move history contains 'O-O' (kingside castling)
    final history = game.moveHistoryLabels();
    expect(history.length, 1);
    expect(history.first, 'O-O');

    // Make a subsequent move to verify replay history works correctly
    final blackMove = game.makeMove({'from': 'e7', 'to': 'e5'});
    expect(blackMove, true);

    final history2 = game.moveHistoryLabels();
    expect(history2.length, 2);
    expect(history2[0], 'O-O');
    expect(history2[1], 'e5');
  });
}
