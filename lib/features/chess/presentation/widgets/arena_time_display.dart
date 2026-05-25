import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../scholarly_theme.dart';
import '../chess_clock.dart';
import '../../application/game_clock_provider.dart';

class ArenaTimeDisplay extends ConsumerWidget {
  final bool isWhite;
  final bool isActive;

  const ArenaTimeDisplay({
    super.key,
    required this.isWhite,
    required this.isActive,
  });

  Color _getBorderColor(Duration timeLeft) {
    if (!isActive) return ScholarlyTheme.panelStroke.withValues(alpha: 0.4);
    if (timeLeft.inSeconds < 60) return const Color(0xFFFC8181); // urgent red
    return ScholarlyTheme.accentBlue;
  }

  Color _getGlowColor(Duration timeLeft) {
    if (!isActive) return Colors.transparent;
    if (timeLeft.inSeconds < 60) {
      return const Color(0xFFFC8181).withValues(alpha: 0.2);
    }
    return ScholarlyTheme.accentBlue.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeLeft = ref.watch(gameClockProvider.select(
      (s) => isWhite ? s.whiteTimeLeft : s.blackTimeLeft,
    ));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getGlowColor(timeLeft),
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
                color: _getBorderColor(timeLeft),
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
