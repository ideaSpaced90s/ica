import 'package:flutter/material.dart';

class PixelColors {
  static const lightSquare = Color(0xFFE5D68A); // Toned down #F4E04D
  static const darkSquare = Color(0xFF4A76A8); // Toned down #2C6FB7
  static const whitePiece = Color(0xFFE5E7EB);
  static const blackPiece = Color(0xFFDC2626); // Deep Red
  static const blackOutline = Color(0xFF1F2937);
  static const whiteOutline = Color(0xFFF9FAFB);
}

class PixelBoardPainter extends CustomPainter {
  final bool isFlipped;

  PixelBoardPainter({required this.isFlipped});

  @override
  void paint(Canvas canvas, Size size) {
    final double squareSize = size.width / 8;
    final int pixelRatio = 8; // Number of "pixels" per square
    final double ps = squareSize / pixelRatio;

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final bool isLight = (row + col) % 2 == 0;
        final baseColor = isLight
            ? PixelColors.lightSquare
            : PixelColors.darkSquare;

        final double x = col * squareSize;
        final double y = row * squareSize;

        // Draw Square Base
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          Paint()..color = baseColor,
        );

        // Draw Tiny Pixel Texture (Subdivided Pattern)
        final texturePaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.05);
        for (int py = 0; py < pixelRatio; py++) {
          for (int px = 0; px < pixelRatio; px++) {
            if ((px + py) % 2 == 0) {
              canvas.drawRect(
                Rect.fromLTWH(x + px * ps, y + py * ps, ps, ps),
                texturePaint,
              );
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PixelPiecePainter extends CustomPainter {
  final String type;
  final bool isWhite;

  PixelPiecePainter({required this.type, required this.isWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final double padding = size.width * 0.15;
    final double drawSize = size.width - (padding * 2);
    final int gridDim = 16; // 16x16 logical grid
    final double ps = drawSize / gridDim; // Physical pixel size

    final mainColor = isWhite ? PixelColors.whitePiece : PixelColors.blackPiece;
    final outlineColor = isWhite
        ? PixelColors.blackOutline
        : PixelColors.whiteOutline;

    canvas.save();
    canvas.translate(padding, padding);

    final List<List<int>> mask = _getMask(type);

    // Draw Outline (1px logical shift in 4 directions)
    final outlinePaint = Paint()..color = outlineColor;
    for (int y = 0; y < gridDim; y++) {
      for (int x = 0; x < gridDim; x++) {
        if (mask[y][x] == 1) {
          // Surrounding 1px shadow/outline
          _drawPixel(canvas, x - 1, y, ps, outlinePaint);
          _drawPixel(canvas, x + 1, y, ps, outlinePaint);
          _drawPixel(canvas, x, y - 1, ps, outlinePaint);
          _drawPixel(canvas, x, y + 1, ps, outlinePaint);
        }
      }
    }

    // Draw Body
    final bodyPaint = Paint()..color = mainColor;
    for (int y = 0; y < gridDim; y++) {
      for (int x = 0; x < gridDim; x++) {
        if (mask[y][x] == 1) {
          _drawPixel(canvas, x, y, ps, bodyPaint);
        }
      }
    }

    canvas.restore();
  }

  void _drawPixel(Canvas canvas, int x, int y, double size, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x * size, y * size, size, size), paint);
  }

  List<List<int>> _getMask(String type) {
    // 16x16 Grid Masks (1 = pixel, 0 = empty)
    List<List<int>> grid = List.generate(16, (_) => List.filled(16, 0));

    switch (type) {
      case 'K': // King (Cross top)
        _fill(grid, 7, 7, 2, 9); // Body
        _fill(grid, 5, 11, 6, 2); // Base
        _fill(grid, 7, 2, 2, 4); // Vertical cross
        _fill(grid, 6, 3, 4, 1); // Horizontal cross
        break;
      case 'Q': // Queen (Crown)
        _fill(grid, 7, 7, 2, 9); // Body
        _fill(grid, 5, 12, 6, 2); // Base
        _fill(grid, 5, 4, 2, 3); // Pips
        _fill(grid, 7, 4, 2, 3);
        _fill(grid, 9, 4, 2, 3);
        break;
      case 'R': // Rook (Castle)
        _fill(grid, 5, 6, 6, 10); // Body
        _fill(grid, 5, 13, 6, 2); // Base
        _fill(grid, 5, 4, 1, 2); // Teeth
        _fill(grid, 7, 4, 2, 2);
        _fill(grid, 10, 4, 1, 2);
        break;
      case 'B': // Bishop (Notch)
        _fill(grid, 7, 6, 2, 9); // Body
        _fill(grid, 5, 13, 6, 2); // Base
        _fill(grid, 7, 3, 2, 3); // Head
        grid[4][8] = 0; // The Notch
        grid[5][7] = 0;
        break;
      case 'N': // Knight (Angled Horse)
        _fill(grid, 7, 8, 3, 8); // Body
        _fill(grid, 5, 13, 6, 2); // Base
        _fill(grid, 5, 5, 5, 3); // Head
        _fill(grid, 3, 6, 2, 2); // Ear
        _fill(grid, 10, 6, 2, 2); // Mane steps
        break;
      case 'P': // Pawn (Simple round head)
        _fill(grid, 7, 9, 2, 6); // Neck
        _fill(grid, 6, 13, 4, 2); // Base
        _fill(grid, 6, 5, 4, 4); // Head
        break;
    }

    return grid;
  }

  void _fill(List<List<int>> grid, int x, int y, int w, int h) {
    for (int i = y; i < y + h; i++) {
      for (int j = x; j < x + w; j++) {
        if (i >= 0 && i < 16 && j >= 0 && j < 16) {
          grid[i][j] = 1;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PixelSelectionPainter extends CustomPainter {
  final double animationValue;

  PixelSelectionPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue < 0.5) return; // Blinking logic

    final double ps = size.width / 16;
    final paint = Paint()..color = Colors.white;

    // Pixelated corners/border
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(i * ps, 0, ps, ps), paint); // Top-left
      canvas.drawRect(Rect.fromLTWH(0, i * ps, ps, ps), paint);

      canvas.drawRect(
        Rect.fromLTWH(size.width - (i + 1) * ps, 0, ps, ps),
        paint,
      ); // Top-right
      canvas.drawRect(Rect.fromLTWH(size.width - ps, i * ps, ps, ps), paint);

      canvas.drawRect(
        Rect.fromLTWH(i * ps, size.height - ps, ps, ps),
        paint,
      ); // Bottom-left
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - (i + 1) * ps, ps, ps),
        paint,
      );

      canvas.drawRect(
        Rect.fromLTWH(size.width - (i + 1) * ps, size.height - ps, ps, ps),
        paint,
      ); // Bottom-right
      canvas.drawRect(
        Rect.fromLTWH(size.width - ps, size.height - (i + 1) * ps, ps, ps),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PixelMoveHintPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double ps = size.width / 16;
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.4);

    // 2x2 logical pixel dot in center
    canvas.drawRect(Rect.fromLTWH(7 * ps, 7 * ps, 2 * ps, 2 * ps), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
