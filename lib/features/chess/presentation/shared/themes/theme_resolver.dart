import '../../shared/themes/chess_theme.dart';
import '../../academy/themes/academy_scholar_theme.dart';
import '../../academy/themes/academy_classic_theme.dart';
import '../../academy/themes/academy_bnw_theme.dart';
import '../../academy/themes/academy_forest_theme.dart';

ChessTheme resolveChessTheme(String themeId) {
  switch (themeId) {
    case 'scholar':
      return const AcademyScholarTheme();
    case 'classic':
      return const AcademyClassicTheme();
    case 'theme10':
    case 'bnw':
      return const AcademyBnwTheme();
    case 'theme2':
    case 'forest':
      return const AcademyForestTheme();
    default:
      return const AcademyClassicTheme();
  }
}
