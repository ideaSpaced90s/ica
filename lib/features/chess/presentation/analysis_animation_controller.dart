import 'dart:async';
import 'package:flutter/material.dart';

class AnalysisAnimationController extends ChangeNotifier {
  String? blinkingSquare;
  String? movingPiece;

  // State for AnimatedPositioned overlay
  String? animatedPieceType;
  Color? animatedPieceColor;
  String? currentFromSquare;
  String? currentToSquare;
  bool isMoving = false;
  bool isVisible = true;

  Future<void> playPVSequence(
    List<String> moves, {
    required Function(String square) getPieceAt,
  }) async {
    for (final move in moves) {
      if (move.length < 4) continue;

      final from = move.substring(0, 2);
      final to = move.substring(2, 4);

      // Get piece info for the overlay
      final pieceInfo = getPieceAt(from); // Expected format "wP", "bK", etc.
      if (pieceInfo.isEmpty) continue;

      animatedPieceColor = pieceInfo.startsWith('w')
          ? Colors.white
          : Colors.black;
      animatedPieceType = pieceInfo.substring(1);
      currentFromSquare = from;
      currentToSquare = from; // Start at 'from'
      isMoving = false;

      // 1. Blinking Effect (3 times)
      blinkingSquare = from;
      for (int i = 0; i < 2; i++) {
        isVisible = false;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 140));
        isVisible = true;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 150));
      }
      blinkingSquare = null;

      // 2. Slow Move Animation
      currentToSquare = to;
      isMoving = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 420));

      await Future.delayed(const Duration(milliseconds: 120));

      // Reset for next move
      isMoving = false;
      animatedPieceType = null;
      notifyListeners();
    }
  }
}
