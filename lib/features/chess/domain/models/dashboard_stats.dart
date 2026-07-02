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
}
