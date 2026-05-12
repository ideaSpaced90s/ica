import 'package:chess/chess.dart' as chess_lib;

class ChessGame {
  final chess_lib.Chess _chess;
  final bool isChess960;
  static const List<String> files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const List<String> ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

  ChessGame({String? fen, this.isChess960 = false})
    : _chess = chess_lib.Chess.fromFEN(fen ?? chess_lib.Chess.DEFAULT_POSITION);

  String get fen => _chess.fen;
  bool get gameOver => _chess.game_over;
  bool get inCheck => _chess.in_check;
  bool get inCheckmate => _chess.in_checkmate;
  bool get inDraw => _chess.in_draw;
  bool get inStalemate => _chess.in_stalemate;

  List<dynamic> get history => _chess.history;
  chess_lib.Color get turn => _chess.turn;
  String get turnColor => _chess.turn == chess_lib.Color.WHITE ? 'w' : 'b';

  bool makeMove(dynamic move) {
    if (isChess960 && move is Map) {
      final from = move['from'] as String?;
      final to = move['to'] as String?;
      if (from != null && to != null) {
        final p = getPiece(from);
        if (p != null && p.type == chess_lib.PieceType.KING) {
          final isWhite = p.color == chess_lib.Color.WHITE;
          final myRank = isWhite ? '1' : '8';
          
          final targetPiece = getPiece(to);
          final isTargetFriendlyRook = targetPiece != null && 
              targetPiece.type == chess_lib.PieceType.ROOK && 
              targetPiece.color == p.color;
          
          final fromFileIdx = files.indexOf(from[0]);
          final toFileIdx = files.indexOf(to[0]);
          final isStandardCastleDest = (to == 'g$myRank' || to == 'c$myRank') && from != to;

          if (isTargetFriendlyRook || isStandardCastleDest) {
            int rookFileIdx = -1;
            if (isTargetFriendlyRook) {
              rookFileIdx = toFileIdx;
            } else {
              if (to[0] == 'g' || toFileIdx > fromFileIdx) {
                for (int f = fromFileIdx + 1; f < 8; f++) {
                  final rp = getPiece('${files[f]}$myRank');
                  if (rp != null && rp.type == chess_lib.PieceType.ROOK && rp.color == p.color) {
                    rookFileIdx = f;
                    break;
                  }
                }
              } else {
                for (int f = 0; f < fromFileIdx; f++) {
                  final rp = getPiece('${files[f]}$myRank');
                  if (rp != null && rp.type == chess_lib.PieceType.ROOK && rp.color == p.color) {
                    rookFileIdx = f;
                    break;
                  }
                }
              }
            }

            if (rookFileIdx != -1) {
              final isKingside = rookFileIdx > fromFileIdx;
              final kingFinalFile = isKingside ? 'g' : 'c';
              final rookFinalFile = isKingside ? 'f' : 'd';

              final fenParts = fen.split(' ');
              final ranksStr = fenParts[0].split('/');
              final rankIdx = isWhite ? 7 : 0;

              // Expand rank to 8 individual character slots
              final rankChars = List<String>.filled(8, '.');
              int fileCursor = 0;
              for (final char in ranksStr[rankIdx].split('')) {
                final code = char.codeUnitAt(0);
                if (code >= '1'.codeUnitAt(0) && code <= '8'.codeUnitAt(0)) {
                  fileCursor += int.parse(char);
                } else {
                  rankChars[fileCursor] = char;
                  fileCursor++;
                }
              }

              final kingChar = rankChars[fromFileIdx];
              final rookChar = rankChars[rookFileIdx];

              // Clear original locations
              rankChars[fromFileIdx] = '.';
              rankChars[rookFileIdx] = '.';

              // Place at target castling locations
              final kFinalIdx = files.indexOf(kingFinalFile);
              final rFinalIdx = files.indexOf(rookFinalFile);
              rankChars[kFinalIdx] = kingChar;
              rankChars[rFinalIdx] = rookChar;

              // Re-compact rank layout
              final buffer = StringBuffer();
              int emptyCount = 0;
              for (final c in rankChars) {
                if (c == '.') {
                  emptyCount++;
                } else {
                  if (emptyCount > 0) {
                    buffer.write(emptyCount);
                    emptyCount = 0;
                  }
                  buffer.write(c);
                }
              }
              if (emptyCount > 0) {
                buffer.write(emptyCount);
              }
              ranksStr[rankIdx] = buffer.toString();

              final newPlacement = ranksStr.join('/');
              final newTurn = isWhite ? 'b' : 'w';

              String newRights = fenParts[2];
              if (isWhite) {
                newRights = newRights.replaceAll(RegExp(r'[KQ]'), '');
              } else {
                newRights = newRights.replaceAll(RegExp(r'[kq]'), '');
              }
              if (newRights.isEmpty) newRights = '-';

              final newEnPassant = '-';
              final halfmove = 0;
              final fullmove = int.parse(fenParts[5]) + (isWhite ? 0 : 1);

              final resultingFen = '$newPlacement $newTurn $newRights $newEnPassant $halfmove $fullmove';
              _chess.load(resultingFen);
              return true;
            }
          }
        }
      }
    }
    return _chess.move(move);
  }

  List<chess_lib.Move> generateMoves({String? square}) {
    return _chess.generate_moves({'square': square});
  }

  List<String> legalDestinations(String fromSquare) {
    final moves = _chess.generate_moves({'square': fromSquare});
    final destinations = moves.map((m) => chess_lib.Chess.algebraic(m.to)).toList();

    if (isChess960) {
      final p = getPiece(fromSquare);
      if (p != null && p.type == chess_lib.PieceType.KING) {
        final myRank = p.color == chess_lib.Color.WHITE ? '1' : '8';
        if (fromSquare.endsWith(myRank)) {
          final fenParts = fen.split(' ');
          if (fenParts.length > 2) {
            final rights = fenParts[2];
            final isWhite = p.color == chess_lib.Color.WHITE;
            
            for (final f in files) {
              final sq = '$f$myRank';
              final rp = getPiece(sq);
              if (rp != null && rp.type == chess_lib.PieceType.ROOK && rp.color == p.color) {
                if (rights != '-') {
                  if (!destinations.contains(sq)) {
                    destinations.add(sq);
                  }
                  final standardDest = f.compareTo(fromSquare[0]) > 0 
                      ? (isWhite ? 'g1' : 'g8') 
                      : (isWhite ? 'c1' : 'c8');
                  if (!destinations.contains(standardDest)) {
                    destinations.add(standardDest);
                  }
                }
              }
            }
          }
        }
      }
    }
    return destinations;
  }

  List<String> moveHistoryLabels() {
    final tempGame = chess_lib.Chess.fromFEN(chess_lib.Chess.DEFAULT_POSITION);
    final labels = <String>[];
    for (final h in _chess.history) {
      final move = h.move;
      labels.add(tempGame.move_to_san(move));
      tempGame.move(move);
    }
    return labels;
  }

  List<chess_lib.Color?> get board {
    return List<chess_lib.Color?>.filled(64, null);
  }

  chess_lib.Piece? getPiece(String square) {
    return _chess.get(square);
  }

  bool isAttacked(String square, chess_lib.Color color) {
    final squareInt = chess_lib.Chess.SQUARES[square];
    if (squareInt == null) return false;
    return _chess.attacked(color, squareInt);
  }

  void undo() {
    _chess.undo();
  }

  void load(String fen) {
    _chess.load(fen);
  }

  List<chess_lib.Piece> get capturedByWhite {
    return _chess.history
        .where((h) => h.move.color == chess_lib.Color.WHITE && h.move.captured != null)
        .map((h) => chess_lib.Piece(h.move.captured!, chess_lib.Color.BLACK))
        .toList();
  }

  List<chess_lib.Piece> get capturedByBlack {
    return _chess.history
        .where((h) => h.move.color == chess_lib.Color.BLACK && h.move.captured != null)
        .map((h) => chess_lib.Piece(h.move.captured!, chess_lib.Color.WHITE))
        .toList();
  }
}
