class CommentaryEntry {
  const CommentaryEntry({
    required this.text,
    required this.timestamp,
    this.isComplete = true,
  });

  final String text;
  final DateTime timestamp;
  final bool isComplete;

  CommentaryEntry copyWith({
    String? text,
    DateTime? timestamp,
    bool? isComplete,
  }) {
    return CommentaryEntry(
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  factory CommentaryEntry.fromJson(Map<String, dynamic> json) {
    return CommentaryEntry(
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isComplete: json['isComplete'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isComplete': isComplete,
    };
  }
}

class SavedGameEntry {
  const SavedGameEntry({
    required this.id,
    required this.savedAt,
    required this.fen,
    required this.recentMoves,
    required this.isPlayerWhite,
    required this.isBoardFlipped,
    required this.whiteTimeLeftMs,
    required this.blackTimeLeftMs,
    required this.clockStarted,
    required this.activeClockSide,
    this.lastMove,
    this.commentaryHistory = const [],
  });

  final String id;
  final DateTime savedAt;
  final String fen;
  final List<String> recentMoves;
  final bool isPlayerWhite;
  final bool isBoardFlipped;
  final int whiteTimeLeftMs;
  final int blackTimeLeftMs;
  final bool clockStarted;
  final String? activeClockSide;
  final String? lastMove;
  final List<CommentaryEntry> commentaryHistory;

  SavedGameEntry copyWith({
    String? id,
    DateTime? savedAt,
    String? fen,
    List<String>? recentMoves,
    bool? isPlayerWhite,
    bool? isBoardFlipped,
    int? whiteTimeLeftMs,
    int? blackTimeLeftMs,
    bool? clockStarted,
    Object? activeClockSide = _sentinel,
    Object? lastMove = _sentinel,
    List<CommentaryEntry>? commentaryHistory,
  }) {
    return SavedGameEntry(
      id: id ?? this.id,
      savedAt: savedAt ?? this.savedAt,
      fen: fen ?? this.fen,
      recentMoves: recentMoves ?? this.recentMoves,
      isPlayerWhite: isPlayerWhite ?? this.isPlayerWhite,
      isBoardFlipped: isBoardFlipped ?? this.isBoardFlipped,
      whiteTimeLeftMs: whiteTimeLeftMs ?? this.whiteTimeLeftMs,
      blackTimeLeftMs: blackTimeLeftMs ?? this.blackTimeLeftMs,
      clockStarted: clockStarted ?? this.clockStarted,
      activeClockSide: identical(activeClockSide, _sentinel)
          ? this.activeClockSide
          : activeClockSide as String?,
      lastMove: identical(lastMove, _sentinel) ? this.lastMove : lastMove as String?,
      commentaryHistory: commentaryHistory ?? this.commentaryHistory,
    );
  }

  factory SavedGameEntry.fromJson(Map<String, dynamic> json) {
    return SavedGameEntry(
      id: json['id'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      fen: json['fen'] as String,
      recentMoves: (json['recentMoves'] as List<dynamic>? ?? const [])
          .map((move) => move.toString())
          .toList(),
      isPlayerWhite: json['isPlayerWhite'] as bool? ?? true,
      isBoardFlipped: json['isBoardFlipped'] as bool? ?? false,
      whiteTimeLeftMs: json['whiteTimeLeftMs'] as int? ?? 600000,
      blackTimeLeftMs: json['blackTimeLeftMs'] as int? ?? 600000,
      clockStarted: json['clockStarted'] as bool? ?? false,
      activeClockSide: json['activeClockSide'] as String?,
      lastMove: json['lastMove'] as String?,
      commentaryHistory: (json['commentaryHistory'] as List<dynamic>? ?? const [])
          .map((e) => CommentaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'savedAt': savedAt.toIso8601String(),
      'fen': fen,
      'recentMoves': recentMoves,
      'isPlayerWhite': isPlayerWhite,
      'isBoardFlipped': isBoardFlipped,
      'whiteTimeLeftMs': whiteTimeLeftMs,
      'blackTimeLeftMs': blackTimeLeftMs,
      'clockStarted': clockStarted,
      'activeClockSide': activeClockSide,
      'lastMove': lastMove,
      'commentaryHistory': commentaryHistory.map((e) => e.toJson()).toList(),
    };
  }
}

const _sentinel = Object();
