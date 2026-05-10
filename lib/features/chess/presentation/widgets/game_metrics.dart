import 'package:flutter/material.dart';
import '../scholarly_theme.dart';
import '../chess_clock.dart';

class MetricMiniChip extends StatelessWidget {
  const MetricMiniChip({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(color: ScholarlyTheme.textSubtle, fontSize: 7),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: ScholarlyTheme.textPrimary,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class MiniClock extends StatelessWidget {
  const MiniClock({
    super.key,
    required this.label,
    required this.isActive,
    required this.timeLeft,
  });

  final String label;
  final bool isActive;
  final Duration timeLeft;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isActive ? ScholarlyTheme.accentGold : ScholarlyTheme.textSubtle,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 4),
        ChessClock(isActive: isActive, timeLeft: timeLeft),
      ],
    );
  }
}
