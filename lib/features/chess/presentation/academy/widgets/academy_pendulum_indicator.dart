import 'package:flutter/material.dart';
import '../../scholarly_theme.dart';

class AcademyPendulumIndicator extends StatefulWidget {
  final bool isActive;
  final bool isChanakya;

  const AcademyPendulumIndicator({
    super.key,
    required this.isActive,
    required this.isChanakya,
  });

  @override
  State<AcademyPendulumIndicator> createState() => _AcademyPendulumIndicatorState();
}

class _AcademyPendulumIndicatorState extends State<AcademyPendulumIndicator>
    with TickerProviderStateMixin {
  late AnimationController _swingController;
  late AnimationController _fadeController;
  late Animation<double> _swingAnimation;

  @override
  void initState() {
    super.initState();

    // Pendulum swing animation (slows down at the peaks)
    _swingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _swingAnimation = Tween<double>(begin: -0.38, end: 0.38).animate(
      CurvedAnimation(
        parent: _swingController,
        curve: Curves.easeInOutSine,
      ),
    );

    // Fade animation controller for turn transitions
    _fadeController = AnimationController(
      vsync: this,
      value: widget.isActive ? 1.0 : 0.0,
    );

    if (widget.isActive) {
      _swingController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AcademyPendulumIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        // Swing active
        _swingController.repeat(reverse: true);
        // Turn indicator immediately comes when active
        _fadeController.animateTo(1.0, duration: const Duration(milliseconds: 50));
      } else {
        // Turn indicator vanishes gradually
        _fadeController.animateTo(0.0, duration: const Duration(milliseconds: 800)).then((_) {
          if (!mounted) return;
          if (!widget.isActive) {
            _swingController.stop();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _swingController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.isChanakya
        ? ScholarlyTheme.accentGold
        : ScholarlyTheme.accentBlue;

    return AnimatedBuilder(
      animation: Listenable.merge([_swingAnimation, _fadeController]),
      builder: (context, child) {
        final opacity = _fadeController.value;
        if (opacity == 0.0) {
          return const SizedBox(width: 32, height: 36);
        }

        return Opacity(
          opacity: opacity,
          child: SizedBox(
            width: 32,
            height: 36,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Pivot point
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
                // Swinging arm & bob
                Transform.rotate(
                  angle: _swingAnimation.value,
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rod
                      Container(
                        width: 1.5,
                        height: 20,
                        color: baseColor.withValues(alpha: 0.45),
                      ),
                      // Bob
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: baseColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: baseColor.withValues(alpha: 0.75),
                              blurRadius: 6,
                              spreadRadius: 1.5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
