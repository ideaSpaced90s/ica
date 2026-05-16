import 'package:flutter/material.dart';
import '../scholarly_theme.dart';
import '../chess_clock.dart';

class ArenaTimeDisplay extends StatelessWidget {
  final bool isActive;
  final Duration timeLeft;

  const ArenaTimeDisplay({super.key, required this.isActive, required this.timeLeft});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ScholarlyTheme.modernDecoration(sunken: !isActive).copyWith(
        color: isActive
            ? ScholarlyTheme.panelBase
            : ScholarlyTheme.backgroundEnd,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? ScholarlyTheme.accentBlue
              : ScholarlyTheme.panelStroke,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive ? ScholarlyTheme.cardShadow : [],
      ),
      child: ChessClock(isActive: isActive, timeLeft: timeLeft),
    );
  }
}
