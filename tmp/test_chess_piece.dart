import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';

void main() {
  final game = chess.Chess();
  final piece = game.get('e2'); // White Pawn
  debugPrint('Piece color: ${piece?.color}');
  debugPrint('Piece color toString: ${piece?.color.toString()}');
  debugPrint('Piece type: ${piece?.type}');
  debugPrint('Piece type toString: ${piece?.type.toString()}');
}
