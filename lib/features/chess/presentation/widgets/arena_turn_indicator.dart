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
                  ? Colors.greenAccent.shade700.withValues(alpha: 0.8 + (_pulseController.value * 0.2))
                  : ScholarlyTheme.panelStroke,
              width: widget.isActive ? 2.5 : 1,
            ),
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: Colors.greenAccent.shade700.withValues(alpha: 0.4 * _pulseController.value),
                      blurRadius: 10 * _pulseController.value,
                      spreadRadius: 3 * _pulseController.value,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              widget.isWhite ? '♘' : '♞',
              style: TextStyle(
                fontSize: 20,
                height: 1,
                color: widget.isWhite ? Colors.black87 : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
