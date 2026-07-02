import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../scholarly_theme.dart';
import '../../services/chess_sound_service.dart';
import '../../application/chess_provider.dart';

class CountdownOverlay extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const CountdownOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  ConsumerState<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends ConsumerState<CountdownOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<String> _steps = ['3', '2', '1', 'GO!'];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 1.3)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_controller);

    _startStep();
  }

  void _startStep() {
    if (_currentIndex < _steps.length) {
      _controller.reset();
      _controller.forward();

      // Trigger police whistle SFX on each count (3, 2, 1, GO!)
      ref.read(chessSoundServiceProvider).playBattlegroundSfx(SoundEffect.policeWhistle);

      // Hold each step for 900 milliseconds
      _timer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() {
            _currentIndex++;
          });
          _startStep();
        }
      });
    } else {
      widget.onComplete();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _steps.length) {
      return const SizedBox.shrink();
    }

    final currentText = _steps[_currentIndex];
    final isGo = currentText == 'GO!';

    final textColor = isGo ? ScholarlyTheme.accentGold : Colors.white;
    final double fontSize = isGo ? 90 : 120;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Absorb all interactions so board is read-only
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Text(
                  currentText,
                  style: GoogleFonts.outfit(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    shadows: [
                      Shadow(
                        color: (isGo ? ScholarlyTheme.accentGold : ScholarlyTheme.accentBlue)
                            .withValues(alpha: 0.6),
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                      ),
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
