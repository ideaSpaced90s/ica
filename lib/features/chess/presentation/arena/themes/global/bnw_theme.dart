import 'vector_chess_theme.dart';
import '../../../shared/themes/animation_group.dart';

class BnwChessTheme extends VectorChessTheme {
  const BnwChessTheme({
    required super.id,
    required super.name,
    required super.packageTheme,
  });

  @override
  AnimationGroup get animationGroup => AnimationGroup.a;
}
