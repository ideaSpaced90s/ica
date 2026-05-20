import 'dart:ui';
import 'package:flutter/material.dart';
import '../scholarly_theme.dart';
import '../chess_clock.dart';

class ArenaTimeDisplay extends StatelessWidget {
  final bool isActive;
  final Duration timeLeft;

  const ArenaTimeDisplay(
      {super.key, required this.isActive, required this.timeLeft});

  Color _getBorderColor() {
    if (!isActive) return ScholarlyTheme.panelStroke.withValues(alpha: 0.4);
    if (timeLeft.inSeconds < 60) return const Color(0xFFFC8181); // urgent red
    return ScholarlyTheme.accentBlue;
  }

  Color _getGlowColor() {
    if (!isActive) return Colors.transparent;
    if (timeLeft.inSeconds < 60) {
      return const Color(0xFFFC8181).withValues(alpha: 0.2);
    }
    return ScholarlyTheme.accentBlue.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getGlowColor(),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getBorderColor(),
                width: isActive ? 1.5 : 1.0,
              ),
            ),
            child: ChessClock(isActive: isActive, timeLeft: timeLeft),
          ),
        ),
      ),
    );
  }
}
