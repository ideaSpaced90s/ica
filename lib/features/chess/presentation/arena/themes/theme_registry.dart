import 'package:flutter/material.dart';
import 'package:chess_assets/chess_assets.dart' as assets_lib;
import '../../shared/themes/chess_theme.dart';
import 'classic_theme.dart';
import 'forest_theme.dart';
import 'ink_theme.dart';
import 'platinum_theme.dart';
import 'steampunk_theme.dart';
import 'slate_theme.dart';
import 'walnut_theme.dart';
import 'toy_theme.dart';
import 'shadow_theme.dart';
import 'scholar_theme.dart';
import 'vector_chess_theme.dart';
import 'bnw_theme.dart';
import 'sprite_chess_theme.dart';
import '../../../application/chess_provider.dart';

class ThemeRegistry {
  static final Map<String, ChessTheme> _themes = {
    'classic': const ClassicTheme(),
    'theme2': const ForestTheme(),
    'theme3': const InkTheme(),
    'theme4': const PlatinumTheme(),
    'theme5': const SteampunkTheme(),
    'theme7': const SlateTheme(),
    'theme8': const WalnutTheme(),
    'theme9': const ToyTheme(),
    'theme10': const ShadowTheme(),
    'scholar': const ScholarTheme(),
    
    // 13 Vector-based themes from chess_assets package
    'vector_wood': const VectorChessTheme(
      id: 'vector_wood',
      name: 'Wood',
      packageTheme: assets_lib.ChessThemes.classicWood,
    ),
    'vector_cyberpunk': const VectorChessTheme(
      id: 'vector_cyberpunk',
      name: 'Neon',
      packageTheme: assets_lib.ChessThemes.cyberpunkNeon,
    ),
    'vector_glass': const BnwChessTheme(
      id: 'vector_glass',
      name: 'bnw',
      packageTheme: assets_lib.ChessThemes.glassMorphic,
    ),
    'vector_ice': const VectorChessTheme(
      id: 'vector_ice',
      name: 'Glacier',
      packageTheme: assets_lib.ChessThemes.iceGlacier,
    ),
    'vector_royal': const VectorChessTheme(
      id: 'vector_royal',
      name: 'Gold',
      packageTheme: assets_lib.ChessThemes.royalGoldVelvet,
    ),
    'vector_camo': const VectorChessTheme(
      id: 'vector_camo',
      name: 'Midnight',
      packageTheme: assets_lib.ChessThemes.midnightCamo,
    ),
    'vector_championship': const VectorChessTheme(
      id: 'vector_championship',
      name: 'Champions',
      packageTheme: assets_lib.ChessThemes.championshipClassic,
    ),
    'vector_sakura': const VectorChessTheme(
      id: 'vector_sakura',
      name: 'Sakura',
      packageTheme: assets_lib.ChessThemes.sakuraZen,
    ),
    'vector_holographic': const VectorChessTheme(
      id: 'vector_holographic',
      name: 'Pinkworld',
      packageTheme: assets_lib.ChessThemes.holographicGlow,
    ),
    'vector_egyptian': const VectorChessTheme(
      id: 'vector_egyptian',
      name: 'Sand',
      packageTheme: assets_lib.ChessThemes.egyptianSand,
    ),
    'vector_steel': const VectorChessTheme(
      id: 'vector_steel',
      name: 'Castleworld',
      packageTheme: assets_lib.ChessThemes.fairytaleCastle,
    ),
    'sprite_bubblegum': const SpriteChessTheme(
      id: 'sprite_bubblegum',
      name: 'Bubblegum',
      individualPiecesFolder: 'assets/pieces/bubblegum',
      boardImagePath: 'assets/board/bubblegum.png',
      lightSquare: Color(0xFFF0E6FF),
      darkSquare: Color(0xFF7C3AED),
      frameColor: Color(0xFF4C1D95),
    ),
    'sprite_copper': const SpriteChessTheme(
      id: 'sprite_copper',
      name: 'Copper',
      individualPiecesFolder: 'assets/pieces/copper',
      boardImagePath: 'assets/board/copper.png',
      lightSquare: Color(0xFFFFF0E8),
      darkSquare: Color(0xFFB87333),
      frameColor: Color(0xFF7C4A1A),
    ),
    'sprite_plasma': const SpriteChessTheme(
      id: 'sprite_plasma',
      name: 'Plasma',
      individualPiecesFolder: 'assets/pieces/energy-webP',
      pieceExtension: 'webp',
      boardImagePath: 'assets/board/plasma.png',
      lightSquare: Color(0xFF0D1117),
      darkSquare: Color(0xFF0D2440),
      frameColor: Color(0xFF00BFFF),
    ),
    'sprite_overgrown': const SpriteChessTheme(
      id: 'sprite_overgrown',
      name: 'Overgrown',
      individualPiecesFolder: 'assets/pieces/forrest',
      boardImagePath: 'assets/board/overgrown.png',
      lightSquare: Color(0xFFE8F5E9),
      darkSquare: Color(0xFF2E7D32),
      frameColor: Color(0xFF1B5E20),
    ),
    'sprite_goldsilver': const SpriteChessTheme(
      id: 'sprite_goldsilver',
      name: 'Silver & Gold',
      individualPiecesFolder: 'assets/pieces/goldnsilver',
      boardImagePath: 'assets/board/goldsilver.png',
      lightSquare: Color(0xFFF8F8F0),
      darkSquare: Color(0xFF1C1C1C),
      frameColor: Color(0xFF8B6914),
    ),
    'sprite_marble': const SpriteChessTheme(
      id: 'sprite_marble',
      name: 'Marble',
      individualPiecesFolder: 'assets/pieces/marble',
      boardImagePath: 'assets/board/marble.png',
      lightSquare: Color(0xFFF5F5F0),
      darkSquare: Color(0xFF1A1A1A),
      frameColor: Color(0xFFC9A84C),
    ),
    'sprite_desert': const SpriteChessTheme(
      id: 'sprite_desert',
      name: 'Desert',
      individualPiecesFolder: 'assets/pieces/sandmud',
      boardImagePath: 'assets/board/desert.png',
      lightSquare: Color(0xFFF5DEB3),
      darkSquare: Color(0xFF8B6914),
      frameColor: Color(0xFF5C3A1E),
    ),
    'sprite_ivory': const SpriteChessTheme(
      id: 'sprite_ivory',
      name: 'Ivory',
      individualPiecesFolder: 'assets/pieces/silky',
      boardImagePath: 'assets/board/ivory.png',
      lightSquare: Color(0xFFFAF6F0),
      darkSquare: Color(0xFF2C2C2C),
      frameColor: Color(0xFFA09080),
    ),
    'sprite_seasons': const SpriteChessTheme(
      id: 'sprite_seasons',
      name: 'Seasons',
      individualPiecesFolder: 'assets/pieces/summernautumn',
      boardImagePath: 'assets/board/seasons.png',
      lightSquare: Color(0xFFFEFAE0),
      darkSquare: Color(0xFF6B4F2A),
      frameColor: Color(0xFF3D2B1F),
    ),
    'sprite_timber': const SpriteChessTheme(
      id: 'sprite_timber',
      name: 'Timber',
      individualPiecesFolder: 'assets/pieces/woodyy',
      boardImagePath: 'assets/board/timber.png',
      lightSquare: Color(0xFFFAEBD7),
      darkSquare: Color(0xFF5C3317),
      frameColor: Color(0xFF3B1F0A),
    ),
    'sprite_lightning': const SpriteChessTheme(
      id: 'sprite_lightning',
      name: 'Lightning',
      individualPiecesFolder: 'assets/pieces/lightening-webP',
      pieceExtension: 'webp',
      boardImagePath: 'assets/board/lightning.png',
      lightSquare: Color(0xFFE2F1FF),
      darkSquare: Color(0xFF0A1128),
      frameColor: Color(0xFF00E5FF),
    ),
    'sprite_diamonds': const SpriteChessTheme(
      id: 'sprite_diamonds',
      name: 'Diamonds',
      individualPiecesFolder: 'assets/pieces/diamonds-webP',
      pieceExtension: 'webp',
      boardImagePath: 'assets/board/diamonds.png',
      lightSquare: Color(0xFFE0F7FA),
      darkSquare: Color(0xFF006064),
      frameColor: Color(0xFF80DEEA),
    ),
    'sprite_royal': const SpriteChessTheme(
      id: 'sprite_royal',
      name: 'Royal',
      individualPiecesFolder: 'assets/pieces/royal',
      boardImagePath: 'assets/board/royal.png',
      lightSquare: Color(0xFFFFF8E1),
      darkSquare: Color(0xFF4A148C),
      frameColor: Color(0xFFD4AF37),
    ),
    'sprite_fairytale': const SpriteChessTheme(
      id: 'sprite_fairytale',
      name: 'Fairytale',
      individualPiecesFolder: 'assets/pieces/fairytale_castle',
      boardImagePath: 'assets/board/fairytale.png',
      lightSquare: Color(0xFFE7DEC9),
      darkSquare: Color(0xFF5C5346),
      frameColor: Color(0xFF3E3930),
    ),
  };

  static ChessTheme getTheme(String id) {
    return _themes[id] ?? _themes['classic']!;
  }

  static List<ChessTheme> get allThemes => [
        _themes['classic']!, // 1x1
        _themes['scholar']!, // 2x1
        _themes['vector_ice']!,
        _themes['theme4']!,
        _themes['vector_championship']!,
        _themes['theme7']!,
        _themes['vector_wood']!,
        _themes['theme10']!,
        _themes['vector_holographic']!,
        _themes['theme2']!,
        _themes['vector_camo']!,
        _themes['theme8']!,
        _themes['vector_cyberpunk']!,
        _themes['theme3']!,
        _themes['vector_egyptian']!,
        _themes['theme5']!,
        _themes['vector_glass']!,
        _themes['theme9']!,
        _themes['vector_royal']!,
        _themes['vector_sakura']!,
        _themes['vector_steel']!, // 3x7
        _themes['sprite_bubblegum']!,
        _themes['sprite_copper']!,
        _themes['sprite_plasma']!,
        _themes['sprite_overgrown']!,
        _themes['sprite_goldsilver']!,
        _themes['sprite_marble']!,
        _themes['sprite_desert']!,
        _themes['sprite_ivory']!,
        _themes['sprite_seasons']!,
        _themes['sprite_timber']!,
        _themes['sprite_lightning']!,
        _themes['sprite_diamonds']!,
        _themes['sprite_royal']!,
        _themes['sprite_fairytale']!,
      ];

  static String resolveThemeId(ChessState state) {
    return state.boardThemeId;
  }
}
