import 'package:flutter/animation.dart';

/// Lightweight, per-piece motion identity configuration.
/// All values are dimensionless modifiers consumed by the animation pipeline.
class PieceMotionProfile {
  final Duration moveDuration;
  final Curve moveCurve;

  const PieceMotionProfile({
    required this.moveDuration,
    required this.moveCurve,
  });

  /// ♟ Pawn
  static const PieceMotionProfile pawn = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 200),
    moveCurve: Curves.easeOutCubic,
  );

  /// ♞ Knight
  static const PieceMotionProfile knight = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 200),
    moveCurve: Curves.easeOutBack,
  );

  /// ♝ Bishop
  static const PieceMotionProfile bishop = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 200),
    moveCurve: Curves.easeOut,
  );

  /// ♜ Rook
  static const PieceMotionProfile rook = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 200),
    moveCurve: Curves.easeInOutCubic,
  );

  /// ♛ Queen
  static const PieceMotionProfile queen = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 200),
    moveCurve: Curves.easeOutCubic,
  );

  /// ♚ King
  static const PieceMotionProfile king = PieceMotionProfile(
    moveDuration: Duration(milliseconds: 200),
    moveCurve: Curves.easeInOutQuart,
  );

  /// Returns the motion profile for a given piece code (e.g. 'wK', 'bN', 'P').
  static PieceMotionProfile forCode(String code) {
    final type = code.length > 1
        ? code.substring(1).toUpperCase()
        : code.toUpperCase();
    switch (type) {
      case 'K':
        return king;
      case 'Q':
        return queen;
      case 'R':
        return rook;
      case 'B':
        return bishop;
      case 'N':
        return knight;
      case 'P':
        return pawn;
      default:
        return pawn;
    }
  }
}
