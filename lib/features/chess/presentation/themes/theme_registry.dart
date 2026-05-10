import '../themes/chess_theme.dart';
import '../themes/classic_theme.dart';
import '../themes/forest_theme.dart';
import '../themes/ink_theme.dart';
import '../themes/platinum_theme.dart';
import '../themes/steampunk_theme.dart';
import '../themes/matrix_theme.dart';
import '../themes/slate_theme.dart';
import '../themes/walnut_theme.dart';
import '../themes/toy_theme.dart';
import '../themes/shadow_theme.dart';

class ThemeRegistry {
  static final Map<String, ChessTheme> _themes = {
    'classic': const ClassicTheme(),
    'theme2': const ForestTheme(),
    'theme3': const InkTheme(),
    'theme4': const PlatinumTheme(),
    'theme5': const SteampunkTheme(),
    'theme6': const MatrixTheme(),
    'theme7': const SlateTheme(),
    'theme8': const WalnutTheme(),
    'theme9': const ToyTheme(),
    'theme10': const ShadowTheme(),
  };

  static ChessTheme getTheme(String id) {
    return _themes[id] ?? _themes['classic']!;
  }
}
