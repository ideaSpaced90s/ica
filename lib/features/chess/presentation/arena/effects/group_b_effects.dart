import 'package:flutter/material.dart';

class DefaultSelectionRing extends StatelessWidget {
  final Color color;
  const DefaultSelectionRing({super.key, this.color = const Color(0xFFD4AF37)});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3.0),
        ),
      ),
    );
  }
}

class GroupBSelectionPulse extends StatefulWidget {
  final Color color;
  const GroupBSelectionPulse({super.key, required this.color});

  @override
  State<GroupBSelectionPulse> createState() => _GroupBSelectionPulseState();
}

class _GroupBSelectionPulseState extends State<GroupBSelectionPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.color.withValues(alpha: _opacityAnimation.value),
                width: 2.0,
              ),
            ),
          ),
        );
      },
    );
  }
}

class GroupBCaptureFlash extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;
  const GroupBCaptureFlash({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<GroupBCaptureFlash> createState() => _GroupBCaptureFlashState();
}

class _GroupBCaptureFlashState extends State<GroupBCaptureFlash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.18).chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.18, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: _FlashPainter(
            center: widget.position,
            opacity: _opacityAnimation.value,
          ),
        );
      },
    );
  }
}

class _FlashPainter extends CustomPainter {
  final Offset center;
  final double opacity;

  _FlashPainter({required this.center, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;
    final rect = Rect.fromCenter(
      center: center,
      width: squareSize,
      height: squareSize,
    );
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _FlashPainter oldDelegate) {
    return oldDelegate.opacity != opacity || oldDelegate.center != center;
  }
}
