import 'package:chess/chess.dart' as chess_lib;

class ChessGame {
  final chess_lib.Chess _chess;
  static const List<String> files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const List<String> ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

  ChessGame({String? fen})
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
    return _chess.move(move);
  }

  List<chess_lib.Move> generateMoves({String? square}) {
    return _chess.generate_moves({'square': square});
  }

  List<String> legalDestinations(String fromSquare) {
    final destinations = <String>[];
    for (final file in files) {
      for (final rank in ranks) {
        final target = '$file$rank';
        final next = ChessGame(fen: fen);
        final moveMade = next.makeMove({
          'from': fromSquare,
          'to': target,
          'promotion': 'q',
        });
        if (moveMade) {
          destinations.add(target);
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
    // chess package uses a flat list of 128 elements (redundant board)
    // we need to map it to a flat list of 64 or 8x8
    final result = List<chess_lib.Color?>.filled(64, null);
    // Logic to extract standard 64 squares if needed,
    // but the chess package piece representation might be better accessed via get()
    return result;
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
