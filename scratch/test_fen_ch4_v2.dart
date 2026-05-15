// ignore_for_file: avoid_print
import 'package:chess/chess.dart' as chess_lib;


void main() {
  final fen = 'k7/8/8/8/3R4/8/8/3K4 w - - 0 1';
  final board = chess_lib.Chess();
  final success = board.load(fen);
  print('FEN: $fen | Success: $success');
}
