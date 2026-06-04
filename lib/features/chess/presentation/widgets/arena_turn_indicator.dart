import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../scholarly_theme.dart';

class ArenaTurnIndicator extends StatefulWidget {
  final bool isActive;
  final bool isWhite;

  const ArenaTurnIndicator({super.key, required this.isActive, required this.isWhite});

  @override
  State<ArenaTurnIndicator> createState() => _ArenaTurnIndicatorState();
}

class _ArenaTurnIndicatorState extends State<ArenaTurnIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();

    // Breathing glow pulse for active state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Spring bounce when gaining activation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 0.94)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 45,
      ),
    ]).animate(_bounceController);

    if (widget.isActive) {
      _bounceController.forward();
    }
  }

  @override
  void didUpdateWidget(ArenaTurnIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _bounceController.reset();
      _bounceController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeGlow = widget.isWhite
        ? ScholarlyTheme.accentBlue
        : const Color(0xFFAA8BF5); // Soft purple for black's glow

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _bounceController]),
      builder: (context, child) {
        final pulseVal = _pulseController.value;

        return ScaleTransition(
          scale: _bounceScale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: widget.isActive ? 36 : 30,
            height: widget.isActive ? 36 : 30,
            decoration: BoxDecoration(
              // Fill color: White gets a white-pearl, Black gets deep charcoal
              gradient: RadialGradient(
                colors: widget.isWhite
                    ? [Colors.white, const Color(0xFFEEEEEE)]
                    : [const Color(0xFF3A3A4A), const Color(0xFF1E1E28)],
                center: Alignment.topLeft,
                radius: 1.4,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.isActive
                    ? activeGlow.withValues(alpha: 0.65 + (pulseVal * 0.35))
                    : ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                width: widget.isActive ? 2.5 : 1.5,
              ),
              boxShadow: widget.isActive
                  ? [
                      // Inner glow
                      BoxShadow(
                        color: activeGlow.withValues(alpha: 0.30 * pulseVal),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                      // Outer halo
                      BoxShadow(
                        color: activeGlow.withValues(alpha: 0.20 * pulseVal),
                        blurRadius: 14,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: SvgPicture.asset(
                widget.isWhite ? 'assets/pieces/classic_svg/wN.svg' : 'assets/pieces/classic_svg/bN.svg',
                fit: BoxFit.contain,
                colorFilter: widget.isWhite
                    ? null // White knight keeps its natural look
                    : const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
        );
      },
    );
  }
}
