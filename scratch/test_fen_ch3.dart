// ignore_for_file: avoid_print
import 'package:chess/chess.dart' as chess_lib;


void main() {
  final fen = 'r3k2r/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  final board = chess_lib.Chess();
  final success = board.load(fen);
  print('FEN: $fen | Success: $success');
}
