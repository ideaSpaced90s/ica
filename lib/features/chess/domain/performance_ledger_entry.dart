class PerformanceLedgerEntry {
  final String id;
  final DateTime timestamp;
  final String ratingCategory; // 'bullet', 'blitz', 'rapid'
  final String gameMode;       // 'classic', 'chess960'
  final String result;         // 'W', 'L', 'D'
  final double dominance;
  final String opponentName;
  final int ratingSnapshot;
  final String fen;
  final List<String> recentMoves;
  final bool isPlayerWhite;
  final int whiteTimeLeftMs;
  final int blackTimeLeftMs;

  const PerformanceLedgerEntry({
    required this.id,
    required this.timestamp,
    required this.ratingCategory,
    required this.gameMode,
    required this.result,
    required this.dominance,
    required this.opponentName,
    required this.ratingSnapshot,
    required this.fen,
    required this.recentMoves,
    required this.isPlayerWhite,
    required this.whiteTimeLeftMs,
    required this.blackTimeLeftMs,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'ratingCategory': ratingCategory,
    'gameMode': gameMode,
    'result': result,
    'dominance': dominance,
    'opponentName': opponentName,
    'ratingSnapshot': ratingSnapshot,
    'fen': fen,
    'recentMoves': recentMoves,
    'isPlayerWhite': isPlayerWhite,
    'whiteTimeLeftMs': whiteTimeLeftMs,
    'blackTimeLeftMs': blackTimeLeftMs,
  };

  factory PerformanceLedgerEntry.fromJson(Map<String, dynamic> json) {
    return PerformanceLedgerEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ratingCategory: json['ratingCategory'] as String,
      gameMode: json['gameMode'] as String? ?? 'classic',
      result: json['result'] as String,
      dominance: (json['dominance'] as num).toDouble(),
      opponentName: json['opponentName'] as String? ?? 'Opponent',
      ratingSnapshot: json['ratingSnapshot'] as int? ?? 1200,
      fen: json['fen'] as String? ?? '',
      recentMoves: (json['recentMoves'] as List<dynamic>? ?? const [])
          .map((move) => move.toString())
          .toList(),
      isPlayerWhite: json['isPlayerWhite'] as bool? ?? true,
      whiteTimeLeftMs: json['whiteTimeLeftMs'] as int? ?? 600000,
      blackTimeLeftMs: json['blackTimeLeftMs'] as int? ?? 600000,
    );
  }
}
