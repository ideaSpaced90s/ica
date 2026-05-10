import 'dart:math';
import 'package:flutter/material.dart';

class WalnutBoardPainter extends CustomPainter {
  final bool isLight;
  final Color baseColor;

  WalnutBoardPainter({required this.isLight, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()..color = baseColor;
    canvas.drawRect(rect, paint);

    // Subtle Wood Grain effect using low-opacity lines/noise
    final Random random = Random(isLight ? 42 : 24);
    final grainPaint = Paint()
      ..color = (isLight ? Colors.black : Colors.white).withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw wavy grain lines
    for (int i = 0; i < 6; i++) {
      final path = Path();
      final startY = random.nextDouble() * size.height;
      path.moveTo(0, startY);
      
      for (double x = 0; x <= size.width; x += 10) {
          final dy = sin((x / size.width) * 2 * pi) * 2.0;
          path.lineTo(x, startY + dy + (random.nextDouble() * 2));
      }
      canvas.drawPath(path, grainPaint);
    }
  }

  @override
  bool shouldRepaint(WalnutBoardPainter oldDelegate) => false;
}

class WalnutFrameDecoration extends StatelessWidget {
  final Widget child;
  const WalnutFrameDecoration({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          // Outer shadow for the board depth
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(5, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            child,
            // Inner shadow for depth
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple Inset Shadow Trick
class InsetShadowOverlay extends StatelessWidget {
  const InsetShadowOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1.5),
        ),
      ),
    );
  }
}
