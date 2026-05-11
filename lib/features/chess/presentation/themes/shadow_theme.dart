import 'package:flutter/material.dart';
import 'chess_theme.dart';
import '../widgets/high_contrast_piece.dart';

class ShadowTheme extends ChessTheme {
  const ShadowTheme() : super(id: 'theme10', name: 'Shadow');

  @override
  Color get lightSquare => const Color(0xFF1C1C1C);

  @override
  Color get darkSquare => const Color(0xFF000000);

  @override
  Color get lightCoordinateColor => Colors.white.withValues(alpha: 0.7);

  @override
  Color get darkCoordinateColor => Colors.white.withValues(alpha: 0.7);

  @override
  Color get frameColor => const Color(0xFF000000);

  @override
  Widget buildBackground(BuildContext context, bool animationsEnabled) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildCheckEffect(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  CustomPainter? getSquarePainter(bool isLight, double animationValue) {
    return null;
  }

  @override
  Border? getSquareBorder(bool isSelected, bool isDragHover) {
    return Border.all(color: const Color(0xFF2A2A2A), width: 1.0);
  }

  @override
  Widget buildPiece(
    BuildContext context,
    String type,
    bool isWhite,
    bool isHighlighted,
    double animationValue,
  ) {
    return HighContrastPiece(
      type: type.toUpperCase(),
      isWhite: isWhite,
      isHighlighted: isHighlighted,
    );
  }

  @override
  Widget buildMoveHint(BuildContext context, bool isEnemy) {
    return Center(
      child: Container(
        width: isEnemy ? 40 : 14,
        height: isEnemy ? 40 : 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isEnemy 
              ? Colors.transparent 
              : Colors.white.withValues(alpha: 0.45),
          border: isEnemy 
              ? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2.5)
              : null,
        ),
      ),
    );
  }

  @override
  Widget buildSelectionEffect(BuildContext context, double animationValue) {
    return const ShadowSelectionPulse();
  }

  @override
  Widget buildLastMoveHighlight(BuildContext context, double opacity) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withValues(alpha: opacity),
      ),
    );
  }
}

class ShadowSelectionPulse extends StatefulWidget {
  const ShadowSelectionPulse({super.key});

  @override
  State<ShadowSelectionPulse> createState() => _ShadowSelectionPulseState();
}

class _ShadowSelectionPulseState extends State<ShadowSelectionPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2 + 0.3 * _controller.value),
              width: 2.0 + 2.0 * _controller.value,
            ),
          ),
        );
      },
    );
  }
}

