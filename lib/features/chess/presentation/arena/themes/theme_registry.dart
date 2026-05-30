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
      name: 'Wood',
      packageTheme: assets_lib.ChessThemes.classicWood,
    ),
    'vector_cyberpunk': const VectorChessTheme(
      id: 'vector_cyberpunk',
      name: 'Neon',
      packageTheme: assets_lib.ChessThemes.cyberpunkNeon,
    ),
    'vector_glass': const VectorChessTheme(
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
      ];

  static String resolveThemeId(ChessState state) {
    return state.boardThemeId;
  }
}
