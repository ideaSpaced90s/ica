import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../application/puzzles_provider.dart';

class PressureCookerTimer extends ConsumerStatefulWidget {
  const PressureCookerTimer({super.key});

  @override
  ConsumerState<PressureCookerTimer> createState() => _PressureCookerTimerState();
}

class _PressureCookerTimerState extends ConsumerState<PressureCookerTimer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _lastPuzzleId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onTimeOut();
      }
    });

    _startTimer();
  }

  void _startTimer() {
    _controller.reset();
    _controller.forward();
  }

  void _onTimeOut() {
    if (!mounted) return;
    // Auto-advance to the next puzzle (silently)
    ref.read(puzzlesProvider.notifier).nextPrescriptionPuzzle(silent: true);
  }

  @override
  void didUpdateWidget(covariant PressureCookerTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndResetIfNeeded();
  }

  void _checkAndResetIfNeeded() {
    final currentPuzzleId = ref.read(puzzlesProvider).currentPuzzle?.id;
    if (currentPuzzleId != _lastPuzzleId) {
      _lastPuzzleId = currentPuzzleId;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Also check during build in case state changed
    final currentPuzzleId = ref.watch(puzzlesProvider.select((s) => s.currentPuzzle?.id));
    if (currentPuzzleId != _lastPuzzleId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _lastPuzzleId = currentPuzzleId;
            _startTimer();
          });
        }
      });
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = 1.0 - _controller.value;
        final secondsLeft = (15 * progress).ceil();
        
        // Color shifts from Amber to Crimson as time runs out
        final timerColor = Color.lerp(
          const Color(0xFFEF4444), // Red
          const Color(0xFFF59E0B), // Amber
          progress,
        ) ?? const Color(0xFFF59E0B);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: timerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: timerColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2,
                  backgroundColor: timerColor.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PRESSURE COOKER',
                    style: GoogleFonts.outfit(
                      color: timerColor,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Solve or auto-advance in ${secondsLeft}s',
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
