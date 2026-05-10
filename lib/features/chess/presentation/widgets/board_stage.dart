import 'package:flutter/material.dart';
import '../chess_board.dart';

class BoardStage extends StatelessWidget {
  const BoardStage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: ChessBoard(),
    );
  }
}
