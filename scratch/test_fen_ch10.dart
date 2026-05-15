// ignore_for_file: avoid_print
import 'package:chess/chess.dart' as chess_lib;


void main() {
  final fen = '4k3/8/8/8/8/8/4r3/4K3 w - - 0 1';
  final board = chess_lib.Chess();
  final success = board.load(fen);
  print('FEN: $fen | Success: $success');
}
