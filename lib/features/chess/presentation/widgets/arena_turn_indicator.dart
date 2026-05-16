import 'package:flutter/material.dart';
import '../scholarly_theme.dart';

class ArenaTurnIndicator extends StatefulWidget {
  final bool isActive;
  final bool isWhite;

  const ArenaTurnIndicator({super.key, required this.isActive, required this.isWhite});

  @override
  State<ArenaTurnIndicator> createState() => _ArenaTurnIndicatorState();
}

class _ArenaTurnIndicatorState extends State<ArenaTurnIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.isWhite ? Colors.white : Colors.black87,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isActive
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.5 + (_pulseController.value * 0.5))
                  : ScholarlyTheme.panelStroke,
              width: widget.isActive ? 2.5 : 1,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3 * _pulseController.value),
                      blurRadius: 8 * _pulseController.value,
                      spreadRadius: 2 * _pulseController.value,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              widget.isWhite ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              size: 14,
              color: widget.isWhite ? Colors.orange : Colors.blueGrey[200],
            ),
          ),
        );
      },
    );
  }
}
