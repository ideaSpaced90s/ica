import 'package:flutter/material.dart';

class BoardTheme {
  final String id;
  final String name;
  final Color lightSquare;
  final Color darkSquare;
  final Color frameColor;
  final String pieceSetAsset;

  const BoardTheme({
    required this.id,
    required this.name,
    required this.lightSquare,
    required this.darkSquare,
    required this.frameColor,
    required this.pieceSetAsset,
  });

  static const List<BoardTheme> allThemes = [
    BoardTheme(
      id: 'classic',
      name: 'Classic',
      lightSquare: Color(0xFFE8D1B5),
      darkSquare: Color(0xFFB58863),
      frameColor: Color(0xFF8B4513),
      pieceSetAsset: 'assets/board/Chess_Pieces_Sprite.png',
    ),
    BoardTheme(
      id: 'theme2',
      name: 'Forest',
      lightSquare: Color(0xFFE6D3A3),
      darkSquare: Color(0xFF4F7942),
      frameColor: Color(0xFF2E4D23),
      pieceSetAsset: 'assets/board/Chess_Pieces_Sprite.png',
    ),
    BoardTheme(
      id: 'theme3',
      name: 'Ink Calligraphy',
      lightSquare: Color(0xFFF5F5DC), // Rice Paper
      darkSquare: Color(0xFFD6D3D1), // Faded Ink Wash
      frameColor: Color(0xFF2C2C2C), // Dark Ink Frame
      pieceSetAsset: 'assets/board/Chess_Pieces_Sprite.png',
    ),
    BoardTheme(
      id: 'theme4',
      name: 'Platinum Metallic',
      lightSquare: Color(0xFFD1D5DB), // Brushed Steel
      darkSquare: Color(0xFF374151), // Gunmetal
      frameColor: Color(0xFF1F2933), // Cool Dark Grey
      pieceSetAsset: 'assets/board/Chess_Pieces_Sprite.png',
    ),
    BoardTheme(
      id: 'theme5',
      name: 'Steampunk',
      lightSquare: Color(0xFF8D6E63),
      darkSquare: Color(0xFF4E342E),
      frameColor: Color(0xFF3E2723),
      pieceSetAsset: 'assets/board/Chess_Pieces_Sprite.png',
    ),
    BoardTheme(
      id: 'theme7',
      name: 'Slate Minimal',
      lightSquare: Color(0xFFE5E7EB), // Soft neutral grey
      darkSquare: Color(0xFF374151), // Slate grey
      frameColor: Color(0xFF1F2937),
      pieceSetAsset: 'assets/board/Chess_Pieces_Sprite.png',
    ),
    BoardTheme(
      id: 'theme8',
      name: 'Walnut Wood',
      lightSquare: Color(0xFFE6C9A8), // Light Maple
      darkSquare: Color(0xFF6B4F3A), // Walnut Brown
      frameColor: Color(0xFF4A3728),
      pieceSetAsset: 'assets/board/Chess_Pieces_Sprite.png',
    ),
    BoardTheme(
      id: 'theme9',
      name: 'Cartoon Toy',
      lightSquare: Color(0xFFFFF3E0),
      darkSquare: Color(0xFFFFB74D),
      frameColor: Color(0xFFE65100),
      pieceSetAsset: 'assets/board/Chess_Pieces_Sprite.png',
    ),
    BoardTheme(
      id: 'theme10',
      name: 'Shadow High-Contrast',
      lightSquare: Color(0xFF1C1C1C),
      darkSquare: Color(0xFF000000),
      frameColor: Color(0xFF000000),
      pieceSetAsset: 'assets/board/Chess_Pieces_Sprite.png',
    ),
  ];

  factory BoardTheme.fromId(String id) {
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => allThemes.first,
    );
  }
}
