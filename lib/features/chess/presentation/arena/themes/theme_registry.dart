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
      name: 'Classic Wood',
      packageTheme: assets_lib.ChessThemes.classicWood,
    ),
    'vector_cyberpunk': const VectorChessTheme(
      id: 'vector_cyberpunk',
      name: 'Cyberpunk Neon',
      packageTheme: assets_lib.ChessThemes.cyberpunkNeon,
    ),
    'vector_glass': const VectorChessTheme(
      id: 'vector_glass',
      name: 'Glass Morphic',
      packageTheme: assets_lib.ChessThemes.glassMorphic,
    ),
    'vector_ice': const VectorChessTheme(
      id: 'vector_ice',
      name: 'Ice & Glacier',
      packageTheme: assets_lib.ChessThemes.iceGlacier,
    ),
    'vector_royal': const VectorChessTheme(
      id: 'vector_royal',
      name: 'Royal Gold & Velvet',
      packageTheme: assets_lib.ChessThemes.royalGoldVelvet,
    ),
    'vector_camo': const VectorChessTheme(
      id: 'vector_camo',
      name: 'Midnight Camo',
      packageTheme: assets_lib.ChessThemes.midnightCamo,
    ),
    'vector_autumn': const VectorChessTheme(
      id: 'vector_autumn',
      name: 'Animal Friends',
      packageTheme: assets_lib.ChessThemes.animalFriends,
    ),
    'vector_championship': const VectorChessTheme(
      id: 'vector_championship',
      name: 'Championship Classic',
      packageTheme: assets_lib.ChessThemes.championshipClassic,
    ),
    'vector_anime': const VectorChessTheme(
      id: 'vector_anime',
      name: 'Anime Ink',
      packageTheme: assets_lib.ChessThemes.animeInk,
    ),
    'vector_holographic': const VectorChessTheme(
      id: 'vector_holographic',
      name: 'Pink World',
      packageTheme: assets_lib.ChessThemes.holographicGlow,
    ),
    'vector_egyptian': const VectorChessTheme(
      id: 'vector_egyptian',
      name: 'Egyptian Sand',
      packageTheme: assets_lib.ChessThemes.egyptianSand,
    ),
    'vector_abyss': const VectorChessTheme(
      id: 'vector_abyss',
      name: 'Underwater Abyss',
      packageTheme: assets_lib.ChessThemes.underwaterAbyss,
    ),
    'vector_steel': const VectorChessTheme(
      id: 'vector_steel',
      name: 'Fairytale Castle',
      packageTheme: assets_lib.ChessThemes.fairytaleCastle,
    ),
  };

  static ChessTheme getTheme(String id) {
    return _themes[id] ?? _themes['classic']!;
  }

  static List<ChessTheme> get allThemes => [
        _themes['classic']!,
        _themes['theme2']!,
        _themes['theme3']!,
        _themes['theme4']!,
        _themes['theme5']!,
        _themes['theme7']!,
        _themes['theme8']!,
        _themes['theme9']!,
        _themes['theme10']!,
        _themes['scholar']!,
        
        // 13 Vector-based themes from chess_assets package
        _themes['vector_wood']!,
        _themes['vector_cyberpunk']!,
        _themes['vector_glass']!,
        _themes['vector_ice']!,
        _themes['vector_royal']!,
        _themes['vector_camo']!,
        _themes['vector_championship']!,
        _themes['vector_anime']!,
        _themes['vector_holographic']!,
        _themes['vector_egyptian']!,
        _themes['vector_abyss']!,
        _themes['vector_steel']!,
        _themes['vector_autumn']!,
      ];

  static String resolveThemeId(ChessState state) {
    return state.boardThemeId;
  }
}
