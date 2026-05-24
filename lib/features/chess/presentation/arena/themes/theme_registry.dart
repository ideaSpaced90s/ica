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
      ];

  static String resolveThemeId(ChessState state) {
    return state.boardThemeId;
  }
}
