import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scholarly_theme.dart';

class ChessClock extends StatefulWidget {
  const ChessClock({
    super.key,
    required this.isActive,
    required this.timeLeft,
  });

  final bool isActive;
  final Duration timeLeft;

  @override
  State<ChessClock> createState() => _ChessClockState();
}

class _ChessClockState extends State<ChessClock>
    with SingleTickerProviderStateMixin {
  late AnimationController _urgencyController;

  @override
  void initState() {
    super.initState();
    _urgencyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _updateUrgency();
  }

  @override
  void didUpdateWidget(ChessClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateUrgency();
  }

  void _updateUrgency() {
    final isUrgent = widget.isActive && widget.timeLeft.inSeconds < 60;
    if (isUrgent) {
      if (!_urgencyController.isAnimating) {
        _urgencyController.repeat(reverse: true);
      }
    } else {
      _urgencyController.stop();
      _urgencyController.reset();
    }
  }

  @override
  void dispose() {
    _urgencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes =
        widget.timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        widget.timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
    final isUrgent = widget.isActive && widget.timeLeft.inSeconds < 60;

    Color baseColor;
    if (isUrgent) {
      baseColor = const Color(0xFFFC8181); // Soft red
    } else if (widget.isActive) {
      baseColor = ScholarlyTheme.activeClock;
    } else {
      baseColor = ScholarlyTheme.inactiveClock;
    }

    return AnimatedBuilder(
      animation: _urgencyController,
      builder: (context, _) {
        final pulseVal = _urgencyController.value;

        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          style: GoogleFonts.spaceMono(
            color: isUrgent
                ? Color.lerp(
                    const Color(0xFFFC8181),
                    const Color(0xFFFF4444),
                    pulseVal,
                  )!
                : baseColor,
            fontSize: widget.isActive ? 13 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            shadows: widget.isActive
                ? [
                    Shadow(
                      color: isUrgent
                          ? const Color(0xFFFC8181).withValues(
                              alpha: 0.5 + 0.4 * pulseVal,
                            )
                          : ScholarlyTheme.accentGold.withValues(alpha: 0.35),
                      blurRadius: isUrgent ? (6 + 6 * pulseVal) : 4,
                    ),
                  ]
                : null,
          ),
          child: Text('$minutes:$seconds'),
        );
      },
    );
  }
}
