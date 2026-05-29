import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../src/models.dart';
import '../themes/themes.dart';
import 'piece_paths.dart';

class ChessPieceWidget extends StatelessWidget {
  final ChessPieceType type;
  final ChessPieceColor color;
  final ChessTheme theme;
  final double size;

  const ChessPieceWidget({
    super.key,
    required this.type,
    required this.color,
    required this.theme,
    this.size = 48.0,
  });

  String _toHex(Color color) {
    return '#${(color.a * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(color.b * 255).toInt().toRadixString(16).padLeft(2, '0')}'.substring(3);
  }

  @override
  Widget build(BuildContext context) {
    String typeStr = '';
    
    switch (type) {
      case ChessPieceType.king:
        typeStr = 'king';
        break;
      case ChessPieceType.queen:
        typeStr = 'queen';
        break;
      case ChessPieceType.rook:
        typeStr = 'rook';
        break;
      case ChessPieceType.bishop:
        typeStr = 'bishop';
        break;
      case ChessPieceType.knight:
        typeStr = 'knight';
        break;
      case ChessPieceType.pawn:
        typeStr = 'pawn';
        break;
    }

    String svgContent = ChessPiecePaths.getPiecePath(typeStr, theme.name);

    String primaryColorHex;
    String secondaryColorHex;

    if (color == ChessPieceColor.white) {
      primaryColorHex = _toHex(theme.whitePiecePrimary);
      secondaryColorHex = _toHex(theme.whitePieceSecondary);
    } else {
      primaryColorHex = _toHex(theme.blackPiecePrimary);
      secondaryColorHex = _toHex(theme.blackPieceSecondary);
    }

    // prepend # since we substring'd it out above
    primaryColorHex = '#$primaryColorHex';
    secondaryColorHex = '#$secondaryColorHex';

    svgContent = svgContent
        .replaceAll('{primary}', primaryColorHex)
        .replaceAll('{secondary}', secondaryColorHex);

    final String fullSvg = '''
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45" width="100%" height="100%">
        $svgContent
      </svg>
    ''';

    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        fullSvg,
        fit: BoxFit.contain,
      ),
    );
  }
}
