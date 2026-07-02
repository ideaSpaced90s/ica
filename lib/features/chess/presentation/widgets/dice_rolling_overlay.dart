import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/chess_sound_service.dart';
import '../../application/chess_provider.dart';

class DiceRollingOverlay extends ConsumerStatefulWidget {
  final bool isWhite;
  final VoidCallback onComplete;

  const DiceRollingOverlay({
    super.key,
    required this.isWhite,
    required this.onComplete,
  });

  @override
  ConsumerState<DiceRollingOverlay> createState() => _DiceRollingOverlayState();
}

class _DiceRollingOverlayState extends ConsumerState<DiceRollingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    // Play dice shuffling sound (gated inside playBattlegroundSfx)
    ref.read(chessSoundServiceProvider).playBattlegroundSfx(SoundEffect.dice);

    _rotationAnimation = Tween<double>(begin: 0, end: 8 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.decelerate),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.1), weight: 20),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward().then((_) {
      setState(() => _isFinished = true);
      Future.delayed(const Duration(milliseconds: 800), widget.onComplete);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDice(),
                      const SizedBox(height: 32),
                      _buildStatusText(),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDice() {
    return Transform.rotate(
      angle: _rotationAnimation.value,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: _getDiceColor(),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _getDiceColor().withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(color: Colors.white24, width: 2),
        ),
        child: Center(
          child: Icon(
            Icons.casino_rounded,
            size: 64,
            color: _getIconColor(),
          ),
        ),
      ),
    );
  }

  Color _getDiceColor() {
    if (_isFinished) {
      return widget.isWhite ? Colors.white : Colors.black;
    }
    // Smooth pulsing instead of flickering for sensitive users
    final pulse = (math.sin(_controller.value * math.pi * 6) + 1) / 2;
    return Color.lerp(Colors.black87, Colors.white, pulse)!;
  }

  Color _getIconColor() {
    if (_isFinished) {
      return widget.isWhite ? Colors.black : Colors.white;
    }
    final pulse = (math.sin(_controller.value * math.pi * 6) + 1) / 2;
    return Color.lerp(Colors.white, Colors.black87, pulse)!;
  }

  Widget _buildStatusText() {
    String text = "SHUFFLING...";
    if (_isFinished) {
      text = widget.isWhite ? "YOU PLAY AS WHITE" : "YOU PLAY AS BLACK";
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _controller.value > 0.1 ? 1.0 : 0.0,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
          shadows: [
            const Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
          ],
        ),
      ),
    );
  }
}
