class FenParser {
  /// Returns the counts of each piece type for White and Black.
  /// Map keys: 'Q', 'q', 'R', 'r', 'B', 'b', 'N', 'n', 'P', 'p'
  static Map<String, int> countPieces(String fen) {
    final Map<String, int> counts = {
      'Q': 0, 'q': 0,
      'R': 0, 'r': 0,
      'B': 0, 'b': 0,
      'N': 0, 'n': 0,
      'P': 0, 'p': 0,
    };
    
    final parts = fen.trim().split(' ');
    if (parts.isEmpty) return counts;
    final placement = parts[0];
    
    for (int i = 0; i < placement.length; i++) {
      final char = placement[i];
      if (counts.containsKey(char)) {
        counts[char] = counts[char]! + 1;
      }
    }
    return counts;
  }

  /// Calculates total non-pawn material points on the board.
  /// Queen = 9, Rook = 5, Bishop = 3, Knight = 3
  static int calculateNonPawnMaterial(String fen) {
    final counts = countPieces(fen);
    final qCount = (counts['Q'] ?? 0) + (counts['q'] ?? 0);
    final rCount = (counts['R'] ?? 0) + (counts['r'] ?? 0);
    final bCount = (counts['B'] ?? 0) + (counts['b'] ?? 0);
    final nCount = (counts['N'] ?? 0) + (counts['n'] ?? 0);
    return (qCount * 9) + (rCount * 5) + (bCount * 3) + (nCount * 3);
  }

  /// Checks if the board state matches the endgame phase criteria.
  /// Endgame threshold: M_non_pawn <= 12
  static bool isEndgame(String fen) {
    return calculateNonPawnMaterial(fen) <= 12;
  }

  /// Calculates the material balance for the player.
  /// Positive values represent an advantage; negative values represent a disadvantage.
  static int calculateMaterialBalance(String fen, bool isPlayerWhite) {
    final counts = countPieces(fen);
    
    final myQ = isPlayerWhite ? (counts['Q'] ?? 0) : (counts['q'] ?? 0);
    final myR = isPlayerWhite ? (counts['R'] ?? 0) : (counts['r'] ?? 0);
    final myB = isPlayerWhite ? (counts['B'] ?? 0) : (counts['b'] ?? 0);
    final myN = isPlayerWhite ? (counts['N'] ?? 0) : (counts['n'] ?? 0);
    final myP = isPlayerWhite ? (counts['P'] ?? 0) : (counts['p'] ?? 0);

    final oppQ = isPlayerWhite ? (counts['q'] ?? 0) : (counts['Q'] ?? 0);
    final oppR = isPlayerWhite ? (counts['r'] ?? 0) : (counts['R'] ?? 0);
    final oppB = isPlayerWhite ? (counts['b'] ?? 0) : (counts['B'] ?? 0);
    final oppN = isPlayerWhite ? (counts['n'] ?? 0) : (counts['N'] ?? 0);
    final oppP = isPlayerWhite ? (counts['p'] ?? 0) : (counts['P'] ?? 0);

    final myVal = (myQ * 9) + (myR * 5) + (myB * 3) + (myN * 3) + myP;
    final oppVal = (oppQ * 9) + (oppR * 5) + (oppB * 3) + (oppN * 3) + oppP;

    return myVal - oppVal;
  }
}
