import 'package:flutter/material.dart';


/// Color palette for the Slate Minimal theme.
class SlateColors {
  static const lightSquare = Color(0xFFE5E7EB);
  static const darkSquare = Color(0xFF374151);
  static const whitePiece = Color(0xFFF9FAFB);
  static const blackPiece = Color(0xFF111827);
  static const whiteOutline = Color(0xFF6B7280); // soft dark for white pieces
  static const blackHighlight = Color(0xFF9CA3AF); // soft light edge for black
  static const selectionRing = Color(0xFF60A5FA); // clean blue ring
  static const checkRed = Color(0xFFEF4444);
  static const moveHint = Color(0xFF60A5FA);
}

/// Draws clean, minimal chess piece silhouettes using smooth paths.
/// Inspired by modern icon design — no decoration, pure geometry.
class MinimalPiecePainter extends CustomPainter {
  final String type; // 'K', 'Q', 'R', 'B', 'N', 'P'
  final bool isWhite;

  MinimalPiecePainter({required this.type, required this.isWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double pad = w * 0.1;

    final bodyColor = isWhite ? SlateColors.whitePiece : SlateColors.blackPiece;
    final outlineColor = isWhite ? SlateColors.whiteOutline : SlateColors.blackHighlight;
    final outlineWidth = w * 0.045;

    // Soft drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    final bodyPaint = Paint()
      ..color = bodyColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.translate(pad, pad * 0.5);
    final drawW = w - pad * 2;
    final drawH = h - pad;

    final Path path = _buildPath(type, drawW, drawH);

    // Shadow pass
    canvas.save();
    canvas.translate(0, drawH * 0.025);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();

    // Body
    canvas.drawPath(path, bodyPaint);

    // Outline stroke
    canvas.drawPath(path, strokePaint);

    canvas.restore();
  }

  Path _buildPath(String type, double w, double h) {
    switch (type) {
      case 'K': return _kingPath(w, h);
      case 'Q': return _queenPath(w, h);
      case 'R': return _rookPath(w, h);
      case 'B': return _bishopPath(w, h);
      case 'N': return _knightPath(w, h);
      case 'P': return _pawnPath(w, h);
      default:  return _pawnPath(w, h);
    }
  }

  /// King: tall central pillar, simple balanced cross at top.
  Path _kingPath(double w, double h) {
    final Path p = Path();
    // Base
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.15, h * 0.82, w * 0.70, h * 0.18),
      topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
      bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4),
    ));
    // Neck & body
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.32, h * 0.38, w * 0.36, h * 0.46),
      topLeft: const Radius.circular(2), topRight: const Radius.circular(2),
    ));
    // Vertical cross arm
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.43, h * 0.04, w * 0.14, h * 0.36),
      topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
      bottomLeft: const Radius.circular(2), bottomRight: const Radius.circular(2),
    ));
    // Horizontal cross arm
    p.addRect(Rect.fromLTWH(w * 0.27, h * 0.14, w * 0.46, h * 0.11));
    return p;
  }

  /// Queen: tapered body, three-prong crown.
  Path _queenPath(double w, double h) {
    final Path p = Path();
    // Base
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.12, h * 0.82, w * 0.76, h * 0.18),
      topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
      bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4),
    ));
    // Body (slightly wider than king)
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.27, h * 0.35, w * 0.46, h * 0.48),
      topLeft: const Radius.circular(2), topRight: const Radius.circular(2),
    ));
    // Crown: left prong
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.12, h * 0.07, w * 0.16, h * 0.32),
      topLeft: const Radius.circular(4), topRight: const Radius.circular(4),
    ));
    // Crown: center prong (tallest)
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.42, h * 0.02, w * 0.16, h * 0.36),
      topLeft: const Radius.circular(4), topRight: const Radius.circular(4),
    ));
    // Crown: right prong
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.72, h * 0.07, w * 0.16, h * 0.32),
      topLeft: const Radius.circular(4), topRight: const Radius.circular(4),
    ));
    // Crown band connecting all prongs
    p.addRect(Rect.fromLTWH(w * 0.12, h * 0.33, w * 0.76, h * 0.08));
    return p;
  }

  /// Rook: wide flat top with two clean cuts, solid body.
  Path _rookPath(double w, double h) {
    final Path p = Path();
    // Base
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.12, h * 0.82, w * 0.76, h * 0.18),
      topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
      bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4),
    ));
    // Central body (slightly narrower)
    p.addRect(Rect.fromLTWH(w * 0.28, h * 0.36, w * 0.44, h * 0.46));
    // Full top platform
    p.addRect(Rect.fromLTWH(w * 0.12, h * 0.30, w * 0.76, h * 0.09));
    // Left battlement
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.12, h * 0.06, w * 0.20, h * 0.26),
      topLeft: const Radius.circular(2), topRight: const Radius.circular(2),
    ));
    // Right battlement
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.68, h * 0.06, w * 0.20, h * 0.26),
      topLeft: const Radius.circular(2), topRight: const Radius.circular(2),
    ));
    return p;
  }

  /// Bishop: smooth tapered mitre with a fine center incision.
  Path _bishopPath(double w, double h) {
    final Path p = Path();
    // Base
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.14, h * 0.82, w * 0.72, h * 0.18),
      topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
      bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4),
    ));
    // Tapered body (trapezoid approx using a path)
    final body = Path()
      ..moveTo(w * 0.22, h * 0.82)
      ..lineTo(w * 0.32, h * 0.40)
      ..lineTo(w * 0.68, h * 0.40)
      ..lineTo(w * 0.78, h * 0.82)
      ..close();
    p.addPath(body, Offset.zero);
    // Round mitre head
    p.addOval(Rect.fromLTWH(w * 0.33, h * 0.07, w * 0.34, h * 0.36));
    // Notch (center incision) — subtract using XOR / overlay with bg color later in stroke
    // We draw the notch as a separate subtract hint via a thin stroke line in the painter
    return p;
  }

  /// Knight: geometric angular horse-head silhouette.
  Path _knightPath(double w, double h) {
    final Path p = Path();
    // Base
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.12, h * 0.82, w * 0.76, h * 0.18),
      topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
      bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4),
    ));
    // Horse body (angular silhouette)
    final horse = Path()
      ..moveTo(w * 0.25, h * 0.82) // Bottom left
      ..lineTo(w * 0.25, h * 0.55) // Left side rise
      ..lineTo(w * 0.18, h * 0.48) // Neck left dip
      ..lineTo(w * 0.22, h * 0.30) // Head base left
      ..lineTo(w * 0.30, h * 0.14) // Mane top
      ..lineTo(w * 0.60, h * 0.08) // Snout top
      ..lineTo(w * 0.72, h * 0.18) // Nose
      ..lineTo(w * 0.58, h * 0.32) // Lower jaw
      ..lineTo(w * 0.62, h * 0.50) // Chest right
      ..lineTo(w * 0.75, h * 0.82) // Bottom right
      ..close();
    p.addPath(horse, Offset.zero);
    // Eye detail (small oval)
    p.addOval(Rect.fromLTWH(w * 0.50, h * 0.14, w * 0.10, h * 0.08));
    return p;
  }

  /// Pawn: classic round head on a small tapered base.
  Path _pawnPath(double w, double h) {
    final Path p = Path();
    // Base
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.18, h * 0.82, w * 0.64, h * 0.18),
      topLeft: const Radius.circular(3), topRight: const Radius.circular(3),
      bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4),
    ));
    // Neck
    p.addRRect(RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.38, h * 0.55, w * 0.24, h * 0.28),
    ));
    // Round head
    p.addOval(Rect.fromLTWH(w * 0.27, h * 0.17, w * 0.46, h * 0.42));
    return p;
  }

  @override
  bool shouldRepaint(covariant MinimalPiecePainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.isWhite != isWhite;
}


/// Draws the bishop's center notch as a fine line stroke on top of the body.
/// Used as a second CustomPaint pass in ChessPieceWidget for the Bishop.
class BishopNotchPainter extends CustomPainter {
  final bool isWhite;
  BishopNotchPainter({required this.isWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double pad = w * 0.1;
    final drawW = w - pad * 2;
    final drawH = h - pad;
    canvas.save();
    canvas.translate(pad, pad * 0.5);
    // Fine center incision line on the mitre
    final paint = Paint()
      ..color = (isWhite ? SlateColors.whiteOutline : SlateColors.blackHighlight).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = drawW * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(drawW * 0.50, drawH * 0.12),
      Offset(drawW * 0.50, drawH * 0.38),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Thin clean selection ring for Slate theme.
class SlateSelectionPainter extends CustomPainter {
  const SlateSelectionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SlateColors.selectionRing.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A small solid dot in the center of a square for valid move hints.
class SlateMoveHintPainter extends CustomPainter {
  final bool isEnemy;
  const SlateMoveHintPainter({this.isEnemy = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SlateColors.moveHint.withValues(alpha: isEnemy ? 0.5 : 0.55)
      ..style = isEnemy ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 2.0;
    final radius = isEnemy ? size.width * 0.44 : size.width * 0.14;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      radius,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Thin red border on the king's square when in check. Static — no flashing.
class SlateCheckBorder extends StatelessWidget {
  const SlateCheckBorder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: SlateColors.checkRed.withValues(alpha: 0.75),
          width: 2.5,
        ),
      ),
    );
  }
}

/// Quick fade + scale-down capture effect for Slate theme.
class SlateCaptureEffect extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const SlateCaptureEffect({
    super.key,
    required this.position,
    required this.onComplete,
  });

  @override
  State<SlateCaptureEffect> createState() => _SlateCaptureEffectState();
}

class _SlateCaptureEffectState extends State<SlateCaptureEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = Tween(begin: 0.7, end: 0.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween(begin: 1.0, end: 0.6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Positioned(
          left: widget.position.dx - 24,
          top: widget.position.dy - 24,
          child: Opacity(
            opacity: _fade.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
