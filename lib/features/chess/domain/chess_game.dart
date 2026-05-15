import 'package:flutter/foundation.dart';
import 'package:kingslayer_chess/src/rust/api/moves.dart';
import 'package:kingslayer_chess/src/rust/api/history.dart';
import 'package:kingslayer_chess/src/rust/api/state.dart';
import 'package:kingslayer_chess/src/rust/api/status.dart';
import 'package:chess/chess.dart' as chess_lib;

class ChessGame {
  final chess_lib.Chess _chess;
  final bool isChess960;
  static const List<String> files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const List<String> ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

  ChessGame({String? fen, this.isChess960 = false})
    : _chess = chess_lib.Chess.fromFEN(fen ?? chess_lib.Chess.DEFAULT_POSITION);

  String get fen => _chess.fen;
  GameTerminationStatus? _cachedStatus;
  String _cachedStatusFen = '';

  GameTerminationStatus _getStatus() {
    final currentFen = fen;
    if (_cachedStatus != null && _cachedStatusFen == currentFen) {
      return _cachedStatus!;
    }
    try {
      final stopwatchRust = Stopwatch()..start();
      final status = evaluateGameStatus(
        fen: currentFen,
        isChess960: isChess960,
      );
      stopwatchRust.stop();

      final dartGameOver = _chess.game_over;
      if (dartGameOver || status.isGameOver) {
        debugPrint(
          'Unified Status Engine Benchmark:\n'
          '  Rust evaluation: ${stopwatchRust.elapsedMicroseconds} μs\n'
          '  Parity: GameOver(Dart: $dartGameOver | Rust: ${status.isGameOver})',
        );
      }

      _cachedStatusFen = currentFen;
      _cachedStatus = status;
      return status;
    } catch (e) {
      debugPrint('Rust Status Engine Error: $e');
      return GameTerminationStatus(
        isGameOver: _chess.game_over,
        isCheck: _chess.in_check,
        isCheckmate: _chess.in_checkmate,
        isStalemate: _chess.in_stalemate,
        isInsufficientMaterial: _chess.insufficient_material,
      );
    }
  }

  bool get gameOver => _getStatus().isGameOver;
  bool get inCheck => _getStatus().isCheck;
  bool get inCheckmate => _getStatus().isCheckmate;
  bool get inDraw => _chess.in_draw;
  bool get inStalemate => _getStatus().isStalemate;

  List<dynamic> get history => _chess.history;
  chess_lib.Color get turn => _chess.turn;
  String get turnColor => _chess.turn == chess_lib.Color.WHITE ? 'w' : 'b';

  bool makeMove(dynamic move) {
    String? fromStr;
    String? toStr;
    String promoStr = '';

    if (move is Map) {
      fromStr = move['from'] as String?;
      toStr = move['to'] as String?;
      promoStr = move['promotion']?.toString() ?? '';
    } else if (move is String && move.length >= 4) {
      fromStr = move.substring(0, 2);
      toStr = move.substring(2, 4);
      if (move.length > 4) {
        promoStr = move.substring(4);
      }
    }

    if (fromStr != null && toStr != null) {
      try {
        final stopwatchRust = Stopwatch()..start();
        final resultingFenRust = validateAndApplyMove(
          currentFen: fen,
          fromStr: fromStr,
          toStr: toStr,
          promotionStr: promoStr,
          isChess960: isChess960,
        );
        stopwatchRust.stop();

        if (resultingFenRust != null) {
          debugPrint(
            'State Validation Engine Benchmark:\n'
            '  Rust evaluation: ${stopwatchRust.elapsedMicroseconds} μs\n'
            '  Post-Move Parity FEN: $resultingFenRust',
          );
        }
      } catch (e) {
        debugPrint('Rust State Engine Error: $e');
      }
    }

    if (isChess960 && move is Map) {
      final from = move['from'] as String?;
      final to = move['to'] as String?;
      if (from != null && to != null) {
        final p = getPiece(from);
        if (p != null && p.type == chess_lib.PieceType.KING) {
          final isWhite = p.color == chess_lib.Color.WHITE;
          final myRank = isWhite ? '1' : '8';

          final targetPiece = getPiece(to);
          final isTargetFriendlyRook =
              targetPiece != null &&
              targetPiece.type == chess_lib.PieceType.ROOK &&
              targetPiece.color == p.color;

          final fromFileIdx = files.indexOf(from[0]);
          final toFileIdx = files.indexOf(to[0]);
          final isStandardCastleDest =
              (to == 'g$myRank' || to == 'c$myRank') && from != to;

          if (isTargetFriendlyRook || isStandardCastleDest) {
            int rookFileIdx = -1;
            if (isTargetFriendlyRook) {
              rookFileIdx = toFileIdx;
            } else {
              if (to[0] == 'g' || toFileIdx > fromFileIdx) {
                for (int f = fromFileIdx + 1; f < 8; f++) {
                  final rp = getPiece('${files[f]}$myRank');
                  if (rp != null &&
                      rp.type == chess_lib.PieceType.ROOK &&
                      rp.color == p.color) {
                    rookFileIdx = f;
                    break;
                  }
                }
              } else {
                for (int f = 0; f < fromFileIdx; f++) {
                  final rp = getPiece('${files[f]}$myRank');
                  if (rp != null &&
                      rp.type == chess_lib.PieceType.ROOK &&
                      rp.color == p.color) {
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

              final resultingFen =
                  '$newPlacement $newTurn $newRights $newEnPassant $halfmove $fullmove';
              _chess.load(resultingFen);
              return true;
            }
          }
        }
      }
    }
    return _chess.move(move);
  }

  chess_lib.Move? findMoveBySan(String san) {
    // Remove common punctuation Bard might add
    final cleanSan = san.replaceAll(RegExp(r'[.?!]'), '').trim();
    if (cleanSan.isEmpty) return null;

    final moves = _chess.generate_moves();
    for (final m in moves) {
      if (_chess.move_to_san(m) == cleanSan) {
        return m;
      }
    }
    return null;
  }

  List<chess_lib.Move> generateMoves({String? square}) {
    return _chess.generate_moves({'square': square});
  }

  List<String> legalDestinations(String fromSquare) {
    // Run pure Dart engine
    final stopwatchDart = Stopwatch()..start();
    final moves = _chess.generate_moves({'square': fromSquare});
    final destinations = moves
        .map((m) => chess_lib.Chess.algebraic(m.to))
        .toList();

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
              if (rp != null &&
                  rp.type == chess_lib.PieceType.ROOK &&
                  rp.color == p.color) {
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
    stopwatchDart.stop();

    // Run native Rust Bitboard engine
    final stopwatchRust = Stopwatch()..start();
    List<String> destinationsRust = [];
    try {
      destinationsRust = getLegalDestinations(
        fen: fen,
        square: fromSquare,
        isChess960: isChess960,
      );
    } catch (e) {
      debugPrint('Rust Legal Destinations Error: $e');
    }
    stopwatchRust.stop();

    // Log side-by-side evaluation comparison if any options were generated
    if (destinations.isNotEmpty || destinationsRust.isNotEmpty) {
      debugPrint(
        'Legal Moves Benchmark ($fromSquare):\n'
        '  Dart evaluation: ${stopwatchDart.elapsedMicroseconds} μs\n'
        '  Rust evaluation: ${stopwatchRust.elapsedMicroseconds} μs\n'
        '  Parity Check: Dart: ${destinations.length} moves | Rust: ${destinationsRust.length} moves',
      );
    }

    // Prefer Rust destinations natively if populated, falling back safely
    return destinationsRust.isNotEmpty ? destinationsRust : destinations;
  }

  List<String> moveHistoryLabels() {
    final stopwatchDart = Stopwatch()..start();
    final tempGame = chess_lib.Chess.fromFEN(chess_lib.Chess.DEFAULT_POSITION);
    final labels = <String>[];
    for (final h in _chess.history) {
      final move = h.move;
      labels.add(tempGame.move_to_san(move));
      tempGame.move(move);
    }
    stopwatchDart.stop();

    // Run bare-metal native Rust SAN generator
    final stopwatchRust = Stopwatch()..start();
    List<String> labelsRust = [];
    try {
      final uciMoves = _chess.history.map((h) {
        final m = h.move;
        final from = chess_lib.Chess.algebraic(m.from);
        final to = chess_lib.Chess.algebraic(m.to);
        final promotion = m.promotion != null
            ? m.promotion.toString().split('.').last.toLowerCase()[0]
            : '';
        return '$from$to$promotion';
      }).toList();

      labelsRust = getSanHistory(
        initialFen: chess_lib.Chess.DEFAULT_POSITION,
        uciMoves: uciMoves,
        isChess960: isChess960,
      );
    } catch (e) {
      debugPrint('Rust SAN History Tape Error: $e');
    }
    stopwatchRust.stop();

    if (_chess.history.isNotEmpty) {
      debugPrint(
        'SAN History Tape Benchmark (Moves: ${_chess.history.length}):\n'
        '  Dart tape assembly: ${stopwatchDart.elapsedMicroseconds} μs\n'
        '  Rust tape assembly: ${stopwatchRust.elapsedMicroseconds} μs\n'
        '  Parity Check: Dart: ${labels.length} labels | Rust: ${labelsRust.length} labels',
      );
    }

    return labelsRust.isNotEmpty && labelsRust.length == labels.length
        ? labelsRust
        : labels;
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
        .where(
          (h) =>
              h.move.color == chess_lib.Color.WHITE && h.move.captured != null,
        )
        .map((h) => chess_lib.Piece(h.move.captured!, chess_lib.Color.BLACK))
        .toList();
  }

  List<chess_lib.Piece> get capturedByBlack {
    return _chess.history
        .where(
          (h) =>
              h.move.color == chess_lib.Color.BLACK && h.move.captured != null,
        )
        .map((h) => chess_lib.Piece(h.move.captured!, chess_lib.Color.WHITE))
        .toList();
  }
}
