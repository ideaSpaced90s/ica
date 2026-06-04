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
      pieceSetAsset: 'assets/pieces/rootpieces/ideaspaceclassicchesssprite2.png',
    ),
    BoardTheme(
      id: 'theme2',
      name: 'Forest',
      lightSquare: Color(0xFFE6D3A3),
      darkSquare: Color(0xFF4F7942),
      frameColor: Color(0xFF2E4D23),
      pieceSetAsset: 'assets/pieces/rootpieces/ideaspaceclassicchesssprite2.png',
    ),
    BoardTheme(
      id: 'theme3',
      name: 'Calligraphy',
      lightSquare: Color(0xFFF5F5DC), // Rice Paper
      darkSquare: Color(0xFFD6D3D1), // Faded Ink Wash
      frameColor: Color(0xFF2C2C2C), // Dark Ink Frame
      pieceSetAsset: 'assets/pieces/rootpieces/ideaspaceclassicchesssprite2.png',
    ),
    BoardTheme(
      id: 'theme4',
      name: 'Platinum Metallic',
      lightSquare: Color(0xFFD1D5DB), // Brushed Steel
      darkSquare: Color(0xFF374151), // Gunmetal
      frameColor: Color(0xFF1F2933), // Cool Dark Grey
      pieceSetAsset: 'assets/pieces/rootpieces/ideaspaceclassicchesssprite2.png',
    ),
    BoardTheme(
      id: 'theme5',
      name: 'Steampunk',
      lightSquare: Color(0xFF8D6E63),
      darkSquare: Color(0xFF4E342E),
      frameColor: Color(0xFF3E2723),
      pieceSetAsset: 'assets/pieces/rootpieces/ideaspaceclassicchesssprite2.png',
    ),

    BoardTheme(
      id: 'theme10',
      name: 'Shadow High-Contrast',
      lightSquare: Color(0xFF3C3C3C),
      darkSquare: Color(0xFF000000),
      frameColor: Color(0xFF000000),
      pieceSetAsset: 'assets/pieces/rootpieces/ideaspaceclassicchesssprite2.png',
    ),
    BoardTheme(
      id: 'scholar',
      name: 'Scholar',
      lightSquare: Color(0xFFFDF6E2), // Cream
      darkSquare: Color(0xFF7BCBFC), // Sky Blue
      frameColor: Color(0xFF0F172A), // Darker Slate/Navy Frame
      pieceSetAsset: 'assets/board/sample2.png',
    ),
    BoardTheme(
      id: 'sprite_arc',
      name: 'Arc',
      lightSquare: Color(0xFFE4DAC3),
      darkSquare: Color(0xFF1C343A),
      frameColor: Color(0xFFC3A555),
      pieceSetAsset: 'assets/pieces/arc-webP/light_king_0.webp',
    ),
  ];

  factory BoardTheme.fromId(String id) {
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => allThemes.first,
    );
  }
}
