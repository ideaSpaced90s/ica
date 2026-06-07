import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scholarly_theme.dart';

class ChessClock extends StatefulWidget {
  const ChessClock({
    super.key,
    required this.isActive,
    required this.timeLeft,
    required this.baseTimeDuration,
  });

  final bool isActive;
  final Duration timeLeft;
  final Duration baseTimeDuration;

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
      duration: const Duration(milliseconds: 150),
    );
    _updateUrgency();
  }

  @override
  void didUpdateWidget(ChessClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateUrgency();
  }

  void _updateUrgency() {
    final totalMs = widget.baseTimeDuration.inMilliseconds;
    final isUrgent = widget.isActive && (totalMs > 0
        ? (widget.timeLeft.inMilliseconds <= totalMs * 0.1)
        : (widget.timeLeft.inSeconds < 60));

    if (isUrgent) {
      final targetDuration = const Duration(milliseconds: 150);
      if (_urgencyController.duration != targetDuration) {
        _urgencyController.duration = targetDuration;
        if (_urgencyController.isAnimating) {
          _urgencyController.repeat(reverse: true);
        }
      }
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

    final totalMs = widget.baseTimeDuration.inMilliseconds;
    final isLowTime = totalMs > 0
        ? (widget.timeLeft.inMilliseconds <= totalMs * 0.1)
        : (widget.timeLeft.inSeconds < 60);

    final isUrgent = widget.isActive && isLowTime;

    Color baseColor;
    if (isLowTime) {
      baseColor = const Color(0xFFFC8181); // Soft red
    } else if (widget.isActive) {
      baseColor = ScholarlyTheme.activeClock;
    } else {
      baseColor = ScholarlyTheme.inactiveClock;
    }

    String timeText;
    if (widget.timeLeft.inMilliseconds <= 0) {
      timeText = '0.00';
    } else if (widget.timeLeft.inMilliseconds < 10000) {
      final secs = widget.timeLeft.inSeconds;
      final hundredths = ((widget.timeLeft.inMilliseconds % 1000) ~/ 10)
          .toString()
          .padLeft(2, '0');
      timeText = '$secs.$hundredths';
    } else {
      timeText = '$minutes:$seconds';
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
                    const Color(0xFFFF0000),
                    pulseVal,
                  )!
                : baseColor,
            fontSize: widget.isActive ? 13 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            shadows: widget.isActive
                ? [
                    Shadow(
                      color: isLowTime
                          ? const Color(0xFFFC8181).withValues(
                              alpha: isUrgent ? (0.5 + 0.4 * pulseVal) : 0.5,
                            )
                          : ScholarlyTheme.accentGold.withValues(alpha: 0.35),
                      blurRadius: isUrgent ? (6 + 6 * pulseVal) : 4,
                    ),
                  ]
                : null,
          ),
          child: Text(timeText),
        );
      },
    );
  }
}
