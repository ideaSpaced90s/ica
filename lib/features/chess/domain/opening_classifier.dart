class OpeningClassifier {
  /// Detects the chess opening name from a list of SAN moves.
  static String detectOpening(List<String> moves, {String gameMode = 'classic'}) {
    if (gameMode == 'chess960') return 'Chess 960 Variant';
    if (moves.isEmpty) return 'Unknown / Open Line';

    // We join the first N moves (up to 10 plies / 5 full moves)
    final limit = moves.length < 10 ? moves.length : 10;
    final prefixList = moves.sublist(0, limit);
    final pgnText = prefixList.join(' ');

    if (pgnText.startsWith('e4 e5 Nf3 Nc6 Bb5')) {
      return 'Ruy Lopez';
    } else if (pgnText.startsWith('e4 c5')) {
      return 'Sicilian Defense';
    } else if (pgnText.startsWith('d4 d5 c4')) {
      return 'Queen\'s Gambit';
    } else if (pgnText.startsWith('e4 e5 Nf3 Nc6 Bc4')) {
      return 'Italian Game';
    } else if (pgnText.startsWith('e4 e6')) {
      return 'French Defense';
    } else if (pgnText.startsWith('e4 c6')) {
      return 'Caro-Kann Defense';
    } else if (pgnText.startsWith('d4 Nf6 c4 g6')) {
      return 'King\'s Indian Defense';
    } else if (pgnText.startsWith('e4 e5 Nf3 Nf6')) {
      return 'Petrov\'s Defense';
    } else if (pgnText.startsWith('d4 Nf6 c4 e6 Nf3 d5') || 
               pgnText.startsWith('d4 d5 c4 e6')) {
      return 'Queen\'s Gambit Declined';
    } else if (pgnText.startsWith('d4 Nf6 c4 e6 g3 d5')) {
      return 'Catalan Opening';
    } else if (pgnText.startsWith('d4 Nf6 c4 c5 d5')) {
      return 'Benoni Defense';
    } else if (pgnText.startsWith('e4 d6')) {
      return 'Pirc Defense';
    } else if (pgnText.startsWith('e4 g6')) {
      return 'Modern Defense';
    } else if (pgnText.startsWith('e4 d5')) {
      return 'Scandinavian Defense';
    } else if (pgnText.startsWith('Nf3')) {
      return 'Réti Opening';
    } else if (pgnText.startsWith('c4')) {
      return 'English Opening';
    } else if (pgnText.startsWith('f4')) {
      return 'Bird\'s Opening';
    } else if (pgnText.startsWith('g3')) {
      return 'King\'s Fianchetto';
    } else if (pgnText.startsWith('b3')) {
      return 'Nimzowitsch-Larsen Attack';
    } else if (pgnText.startsWith('e4 e5 Nf3 Nc6 Nc3 Nf6')) {
      return 'Four Knights Game';
    } else if (pgnText.startsWith('d4 d5')) {
      return 'Closed Game';
    } else if (pgnText.startsWith('e4 e5')) {
      return 'Open Game';
    }

    if (moves.first == 'e4') return 'King\'s Pawn Game';
    if (moves.first == 'd4') return 'Queen\'s Pawn Game';

    return 'Custom / Unclassified';
  }
}
