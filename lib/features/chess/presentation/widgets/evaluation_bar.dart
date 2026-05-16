import 'package:flutter/material.dart';
import '../scholarly_theme.dart';

class EvaluationBar extends StatelessWidget {
  final double fillFraction;

  const EvaluationBar({super.key, required this.fillFraction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 32,
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelStroke,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 4,
              height: 32 * fillFraction,
              decoration: BoxDecoration(
                color: fillFraction > 0.65 
                    ? Colors.greenAccent.shade700 
                    : (fillFraction < 0.35 ? Colors.redAccent : ScholarlyTheme.accentBlue),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
