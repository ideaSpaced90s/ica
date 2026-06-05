import 'package:flutter/material.dart';
import 'package:chess_assets/chess_assets.dart' as assets_lib;
import '../../shared/themes/chess_theme.dart';
import 'classic_theme.dart';
import 'forest_theme.dart';
import 'ink_theme.dart';
import 'platinum_theme.dart';
import 'steampunk_theme.dart';
import 'shadow_theme.dart';
import 'scholar_theme.dart';
import 'vector_chess_theme.dart';
import 'bnw_theme.dart';
import 'sprite_chess_theme.dart';
import 'arc_theme.dart';
import 'seasons_theme.dart';
import 'lightning_theme.dart';
import 'plasma_theme.dart';
import 'overgrown_theme.dart';
import 'diamonds_sprite_theme.dart';
import 'fairytale_theme.dart';
import '../../../application/chess_provider.dart';

class ThemeRegistry {
  static final Map<String, ChessTheme> _themes = {
    'classic': const ClassicTheme(),
    'theme2': const ForestTheme(),
    'theme3': const InkTheme(),
    'theme4': const PlatinumTheme(),
    'theme5': const SteampunkTheme(),
    'theme10': const ShadowTheme(),
    'scholar': const ScholarTheme(),
    
    // 13 Vector-based themes from chess_assets package
    'vector_wood': const VectorChessTheme(
      id: 'vector_wood',
      name: 'Wood',
      packageTheme: assets_lib.ChessThemes.classicWood,
    ),
    'vector_glass': const BnwChessTheme(
      id: 'vector_glass',
      name: 'bnw',
      packageTheme: assets_lib.ChessThemes.glassMorphic,
    ),
    'vector_championship': const VectorChessTheme(
      id: 'vector_championship',
      name: 'Champions',
      packageTheme: assets_lib.ChessThemes.championshipClassic,
    ),
    'vector_egyptian': const VectorChessTheme(
      id: 'vector_egyptian',
      name: 'Sand',
      packageTheme: assets_lib.ChessThemes.egyptianSand,
    ),
    'sprite_bubblegum': const SpriteChessTheme(
      id: 'sprite_bubblegum',
      name: 'Bubblegum',
      individualPiecesFolder: 'assets/pieces/bubblegum',
      lightSquare: Color(0xFFF0E6FF),
      darkSquare: Color(0xFF7C3AED),
      frameColor: Color(0xFF4C1D95),
    ),
    'sprite_copper': const SpriteChessTheme(
      id: 'sprite_copper',
      name: 'Copper',
      individualPiecesFolder: 'assets/pieces/copper',
      lightSquare: Color(0xFFFFF0E8),
      darkSquare: Color(0xFFB87333),
      frameColor: Color(0xFF7C4A1A),
    ),
    'sprite_plasma': const PlasmaChessTheme(),
    'sprite_overgrown': const OvergrownChessTheme(),
    'sprite_goldsilver': const SpriteChessTheme(
      id: 'sprite_goldsilver',
      name: 'Silver & Gold',
      individualPiecesFolder: 'assets/pieces/goldnsilver',
      lightSquare: Color(0xFFF8F8F0),
      darkSquare: Color(0xFF1C1C1C),
      frameColor: Color(0xFF8B6914),
    ),
    'sprite_marble': const SpriteChessTheme(
      id: 'sprite_marble',
      name: 'Marble',
      individualPiecesFolder: 'assets/pieces/marble',
      lightSquare: Color(0xFFFAF9F6),
      darkSquare: Color(0xFFB4B4B4),
      frameColor: Color(0xFFC9A84C),
    ),
    'sprite_desert': const SpriteChessTheme(
      id: 'sprite_desert',
      name: 'Desert',
      individualPiecesFolder: 'assets/pieces/sandmud',
      lightSquare: Color(0xFFF5DEB3),
      darkSquare: Color(0xFF8B6914),
      frameColor: Color(0xFF5C3A1E),
    ),
    'sprite_ivory': const SpriteChessTheme(
      id: 'sprite_ivory',
      name: 'Ivory',
      individualPiecesFolder: 'assets/pieces/silky',
      lightSquare: Color(0xFFFAF6F0),
      darkSquare: Color(0xFF2C2C2C),
      frameColor: Color(0xFFA09080),
    ),
    'sprite_seasons': const SeasonsChessTheme(),
    'sprite_timber': const SpriteChessTheme(
      id: 'sprite_timber',
      name: 'Timber',
      individualPiecesFolder: 'assets/pieces/woodyy',
      lightSquare: Color(0xFFFAEBD7),
      darkSquare: Color(0xFF5C3317),
      frameColor: Color(0xFF3B1F0A),
    ),
    'sprite_lightning': const LightningChessTheme(),
    'sprite_diamonds': const DiamondsSpriteTheme(),
    'sprite_royal': const SpriteChessTheme(
      id: 'sprite_royal',
      name: 'Royal',
      individualPiecesFolder: 'assets/pieces/royal',
      lightSquare: Color(0xFFF5EFEB),
      darkSquare: Color(0xFF13223C),
      frameColor: Color(0xFFD4AF37),
    ),
    'sprite_fairytale': const FairytaleChessTheme(),
    'sprite_arc': const ArcChessTheme(),
  };

  static ChessTheme getTheme(String id) {
    return _themes[id] ?? _themes['classic']!;
  }

  static List<ChessTheme> get allThemes => [
        // Pinned Top 4 Themes
        _themes['classic']!,
        _themes['scholar']!,
        _themes['vector_glass']!, // BnW
        _themes['vector_championship']!, // Champions

        // Reshuffled / Jumbled Middle Themes
        _themes['theme2']!, // Forest
        _themes['sprite_copper']!,
        _themes['theme3']!, // Calligraphy
        _themes['sprite_overgrown']!,
        _themes['vector_wood']!, // Wood
        _themes['sprite_ivory']!,
        _themes['theme5']!, // Steampunk
        _themes['sprite_seasons']!,
        _themes['vector_egyptian']!, // Sand
        _themes['sprite_timber']!,
        _themes['theme4']!, // Platinum Metallic
        _themes['sprite_fairytale']!,
        _themes['theme10']!, // Shadow High-Contrast
        _themes['sprite_royal']!,
        _themes['sprite_bubblegum']!,
        _themes['sprite_goldsilver']!,
        _themes['sprite_marble']!,
        _themes['sprite_desert']!,

        // WebP pieces sorted towards end
        _themes['sprite_plasma']!,
        _themes['sprite_lightning']!,
        _themes['sprite_diamonds']!,

        // Arc always at the very end
        _themes['sprite_arc']!,
      ];

  static String resolveThemeId(ChessState state) {
    return state.boardThemeId;
  }
}
