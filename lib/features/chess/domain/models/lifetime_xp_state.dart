class LifetimeXpState {
  final int totalXp;
  final Map<String, int> xpEventLog;
  final Set<String> islandLandfalls;

  const LifetimeXpState({
    this.totalXp = 0,
    this.xpEventLog = const {},
    this.islandLandfalls = const {},
  });

  LifetimeXpState copyWith({
    int? totalXp,
    Map<String, int>? xpEventLog,
    Set<String>? islandLandfalls,
  }) {
    return LifetimeXpState(
      totalXp: totalXp ?? this.totalXp,
      xpEventLog: xpEventLog ?? this.xpEventLog,
      islandLandfalls: islandLandfalls ?? this.islandLandfalls,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalXp': totalXp,
        'xpEventLog': xpEventLog,
        'islandLandfalls': islandLandfalls.toList(),
      };

  factory LifetimeXpState.fromJson(Map<String, dynamic> json) {
    return LifetimeXpState(
      totalXp: json['totalXp'] as int? ?? 0,
      xpEventLog: Map<String, int>.from(json['xpEventLog'] ?? {}),
      islandLandfalls: Set<String>.from(json['islandLandfalls'] as List<dynamic>? ?? []),
    );
  }
}
