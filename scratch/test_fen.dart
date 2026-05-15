// ignore_for_file: avoid_print
import 'package:chess/chess.dart' as chess_lib;


void main() {
  final fens = [
    '3k4/8/8/8/3R4/8/8/3K4 w - - 0 1',
    'k7/8/8/8/3R4/8/8/7K w - - 0 1',
    '8/8/8/8/3R4/8/8/8 w - - 0 1',
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
  ];

  for (final fen in fens) {
    final board = chess_lib.Chess();
    final success = board.load(fen);
    print('FEN: $fen | Success: $success');
    if (success) {
      print('Board:\n${board.ascii}');
    }
  }
}
