import 'dart:math';

class Chess960Position {
  final String fen;
  final String castlingRights;

  const Chess960Position({
    required this.fen,
    required this.castlingRights,
  });
}

class Chess960Generator {
  static final _random = Random();

  /// Generates a rule-compliant randomized Fischer Random (Chess 960) starting position.
  static Chess960Position generateRandomPosition() {
    final rank1 = List<String?>.filled(8, null);

    // 1. Place Bishops on opposite colored squares.
    // Light squares: indices 1, 3, 5, 7.
    // Dark squares: indices 0, 2, 4, 6.
    final lightBishopIndex = 1 + 2 * _random.nextInt(4);
    final darkBishopIndex = 2 * _random.nextInt(4);
    rank1[lightBishopIndex] = 'B';
    rank1[darkBishopIndex] = 'B';

    // 2. Place the Queen on one of the remaining 6 slots.
    _placeInEmptySlot(rank1, 'Q', _random.nextInt(6));

    // 3. Place the two Knights on two of the remaining 5 slots.
    final n1Slot = _random.nextInt(5);
    _placeInEmptySlot(rank1, 'N', n1Slot);
    final n2Slot = _random.nextInt(4);
    _placeInEmptySlot(rank1, 'N', n2Slot);

    // 4. Place remaining pieces: Rook, King, Rook in the remaining 3 empty slots.
    // This strictly guarantees the King is between the two Rooks.
    final emptyIndices = <int>[];
    for (int i = 0; i < 8; i++) {
      if (rank1[i] == null) {
        emptyIndices.add(i);
      }
    }
    rank1[emptyIndices[0]] = 'R';
    rank1[emptyIndices[1]] = 'K';
    rank1[emptyIndices[2]] = 'R';

    final whitePieces = rank1.map((p) => p!).join('');
    final blackPieces = whitePieces.toLowerCase();

    // Find the files of the two rooks for explicit rights tracking if needed.
    final r1FileChar = String.fromCharCode('A'.codeUnitAt(0) + emptyIndices[0]);
    final r2FileChar = String.fromCharCode('A'.codeUnitAt(0) + emptyIndices[2]);
    final castlingRights = '$r1FileChar$r2FileChar${r1FileChar.toLowerCase()}${r2FileChar.toLowerCase()}';

    // Standard initial FEN string using 'KQkq' to maintain compatibility with standard FEN parsers.
    // Stockfish with UCI_Chess960=true automatically identifies actual castling files from the King/Rook layout.
    final fen = '$blackPieces/pppppppp/8/8/8/8/PPPPPPPP/$whitePieces w KQkq - 0 1';

    return Chess960Position(
      fen: fen,
      castlingRights: castlingRights,
    );
  }

  static void _placeInEmptySlot(List<String?> array, String piece, int targetEmptySlot) {
    int emptyCount = 0;
    for (int i = 0; i < array.length; i++) {
      if (array[i] == null) {
        if (emptyCount == targetEmptySlot) {
          array[i] = piece;
          return;
        }
        emptyCount++;
      }
    }
  }
}
