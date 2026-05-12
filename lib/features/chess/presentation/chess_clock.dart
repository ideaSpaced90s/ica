import 'package:flutter/material.dart';

import 'scholarly_theme.dart';

class ChessClock extends StatelessWidget {
  const ChessClock({super.key, required this.isActive, required this.timeLeft});

  final bool isActive;
  final Duration timeLeft;

  @override
  Widget build(BuildContext context) {
    final minutes = timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
    final activeColor = isActive
        ? ScholarlyTheme.activeClock
        : ScholarlyTheme.inactiveClock;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      style: TextStyle(
        color: activeColor,
        fontSize: isActive ? 11 : 10,
        fontWeight: FontWeight.w700,
        fontFamily: 'Courier',
        letterSpacing: 0.8,
        shadows: isActive
            ? [
                Shadow(
                  color: ScholarlyTheme.accentGold.withValues(alpha: 0.35),
                  blurRadius: 4,
                ),
              ]
            : null,
      ),
      child: Text('$minutes:$seconds'),
    );
  }
}
