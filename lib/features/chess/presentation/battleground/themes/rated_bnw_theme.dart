import 'package:chess_assets/chess_assets.dart' as assets_lib;
import '../../arena/themes/bnw_theme.dart';
import 'package:flutter/material.dart';
import '../../shared/widgets/orbiting_star_animation.dart';

/// Locked BNW board theme for Battleground (Rated mode).
/// Isolated from Arena's BNW — changes here do NOT affect arena's vector_glass theme.
class RatedBnwTheme extends BnwChessTheme {
  const RatedBnwTheme()
      : super(
          id: 'rated_bnw',
          name: 'BNW',
          packageTheme: assets_lib.ChessThemes.glassMorphic,
        );

  // Premium palette for battleground only
  static const Color _selectionGold = Color(0xFFF59E0B);
  static const Color _dragHoverCyan = Color(0xFF22D3EE);

  static const Color _orbitStarAmber = Color(0xFFFCD34D);
  static const Color _moveHintCyan = Color(0xFF67E8F9);
  static const Color _moveHintRingCyan = Color(0xFF22D3EE);
  static const Color _lastMoveTeal = Color(0xFF0D9488);

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return Center(
      child: Container(
        width: isEnemy ? 38 : 12,
        height: isEnemy ? 38 : 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnemy
              ? Colors.transparent
              : _moveHintCyan.withValues(alpha: 0.85),
          border: isEnemy
              ? Border.all(color: _moveHintRingCyan, width: 2.8)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    // Boost opacity a bit for better visibility on BNW background
    return Container(
      decoration: BoxDecoration(
        color: _lastMoveTeal.withValues(alpha: opacity * 1.3),
      ),
    );
  }

  @override
  Border? getSquareBorder(bool isSelected, bool isDragHover) {
    if (isSelected) {
      return Border.all(color: _selectionGold, width: 3.0);
    }
    if (isDragHover) {
      return Border.all(color: _dragHoverCyan, width: 2.0);
    }
    return null;
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    // Warm amber orbiting star for selection effect
    return OrbitingStarAnimation(color: _orbitStarAmber, isActive: true);
  }
}

/// Constant instance used throughout the battleground.
const ratedBnwTheme = RatedBnwTheme();
