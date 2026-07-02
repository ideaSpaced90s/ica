class TacticalPlaystyleStats {
  final double aggression;
  final double power;
  final double composure;
  final double intensity;
  final double speed;

  const TacticalPlaystyleStats({
    required this.aggression,
    required this.power,
    required this.composure,
    required this.intensity,
    required this.speed,
  });

  const TacticalPlaystyleStats.empty()
      : aggression = 0.5,
        power = 0.5,
        composure = 0.5,
        intensity = 0.5,
        speed = 0.7;

  Map<String, dynamic> toJson() => {
    'aggression': aggression,
    'power': power,
    'composure': composure,
    'intensity': intensity,
    'speed': speed,
  };

  factory TacticalPlaystyleStats.fromJson(Map<String, dynamic> json) {
    return TacticalPlaystyleStats(
      aggression: (json['aggression'] as num?)?.toDouble() ?? 0.5,
      power: (json['power'] as num?)?.toDouble() ?? 0.5,
      composure: (json['composure'] as num?)?.toDouble() ?? 0.5,
      intensity: (json['intensity'] as num?)?.toDouble() ?? 0.5,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.7,
    );
  }
}

class OpeningRepertoireStats {
  final String name;
  final int plays;
  final int wins;
  final int draws;
  final int losses;
  final double playPercentage;
  final double winRate;

  const OpeningRepertoireStats({
    required this.name,
    required this.plays,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.playPercentage,
    required this.winRate,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'plays': plays,
    'wins': wins,
    'draws': draws,
    'losses': losses,
    'playPercentage': playPercentage,
    'winRate': winRate,
  };

  factory OpeningRepertoireStats.fromJson(Map<String, dynamic> json) {
    return OpeningRepertoireStats(
      name: json['name'] as String? ?? 'Unknown',
      plays: json['plays'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      playPercentage: (json['playPercentage'] as num?)?.toDouble() ?? 0.0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EndgamePerformanceStats {
  final double epi;
  final double conversionRate;
  final double saveRate;
  final String ratingCategory;
  final int advantageGames;
  final int advantageWins;
  final int disadvantageGames;
  final int disadvantageSaves;
  final int endgameSavesCount;

  const EndgamePerformanceStats({
    required this.epi,
    required this.conversionRate,
    required this.saveRate,
    required this.ratingCategory,
    required this.advantageGames,
    required this.advantageWins,
    required this.disadvantageGames,
    required this.disadvantageSaves,
    required this.endgameSavesCount,
  });

  Map<String, dynamic> toJson() => {
    'epi': epi,
    'conversionRate': conversionRate,
    'saveRate': saveRate,
    'ratingCategory': ratingCategory,
    'advantageGames': advantageGames,
    'advantageWins': advantageWins,
    'disadvantageGames': disadvantageGames,
    'disadvantageSaves': disadvantageSaves,
    'endgameSavesCount': endgameSavesCount,
  };

  factory EndgamePerformanceStats.fromJson(Map<String, dynamic> json) {
    return EndgamePerformanceStats(
      epi: (json['epi'] as num?)?.toDouble() ?? 0.0,
      conversionRate: (json['conversionRate'] as num?)?.toDouble() ?? 0.0,
      saveRate: (json['saveRate'] as num?)?.toDouble() ?? 0.0,
      ratingCategory: json['ratingCategory'] as String? ?? 'Apprentice (Provisional)',
      advantageGames: json['advantageGames'] as int? ?? 0,
      advantageWins: json['advantageWins'] as int? ?? 0,
      disadvantageGames: json['disadvantageGames'] as int? ?? 0,
      disadvantageSaves: json['disadvantageSaves'] as int? ?? 0,
      endgameSavesCount: json['endgameSavesCount'] as int? ?? 0,
    );
  }
}

class MiddlegamePerformanceStats {
  final double mpi;
  final String archetype;
  final String description;
  final double decidedPercentage;
  final double winRate;
  final int totalMiddlegames;

  const MiddlegamePerformanceStats({
    required this.mpi,
    required this.archetype,
    required this.description,
    required this.decidedPercentage,
    required this.winRate,
    required this.totalMiddlegames,
  });

  Map<String, dynamic> toJson() => {
    'mpi': mpi,
    'archetype': archetype,
    'description': description,
    'decidedPercentage': decidedPercentage,
    'winRate': winRate,
    'totalMiddlegames': totalMiddlegames,
  };

  factory MiddlegamePerformanceStats.fromJson(Map<String, dynamic> json) {
    return MiddlegamePerformanceStats(
      mpi: (json['mpi'] as num?)?.toDouble() ?? 0.0,
      archetype: json['archetype'] as String? ?? 'Positional',
      description: json['description'] as String? ?? '',
      decidedPercentage: (json['decidedPercentage'] as num?)?.toDouble() ?? 0.0,
      winRate: (json['winRate'] as num?)?.toDouble() ?? 0.0,
      totalMiddlegames: json['totalMiddlegames'] as int? ?? 0,
    );
  }
}
