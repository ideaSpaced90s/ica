import 'package:flutter/material.dart';
import '../animation/piece_motion_profile.dart';

abstract class ChessTheme {
  final String id;
  final String name;

  const ChessTheme({required this.id, required this.name});

  Color get lightSquare;
  Color get darkSquare;

  Color get lightCoordinateColor;
  Color get darkCoordinateColor;

  // Frame/Border color for the whole board
  Color get frameColor => Colors.transparent;

  // Background effects/overlays
  Widget buildBackground(BuildContext context, bool animationsEnabled);

  // Check state effects
  Widget buildCheckEffect(BuildContext context);

  // Individual square decoration/painter
  CustomPainter? getSquarePainter(bool isLight, double animationValue);

  // Piece rendering
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  );

  // Move hint rendering (legal moves)
  Widget buildMoveHint(BuildContext context, bool isEnemy);

  // Selection indicator (the ring/effect around the selected square)
  Widget buildSelectionEffect(BuildContext context, double animationValue);

  // Last move highlight
  Widget buildLastMoveHighlight(BuildContext context, double opacity);

  // Piece motion profile (affects animation styles)
  PieceMotionProfile getPieceMotionProfile(String pieceCode) {
    return PieceMotionProfile.forCode(pieceCode);
  }

  // Border radius for squares (if any)
  BorderRadius? get squareBorderRadius => null;

  // Border for squares (if any)
  Border? getSquareBorder(bool isSelected, bool isDragHover) => null;
}
