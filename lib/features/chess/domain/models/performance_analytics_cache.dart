import '../../../../src/rust/api/cognitive.dart';
import '../performance_ledger_entry.dart';
import '../fen_parser.dart';
import 'ai_avatar.dart';
import 'dashboard_stats.dart';

class OpeningCounts {
  final int plays;
  final int wins;
  final int draws;
  final int losses;

  const OpeningCounts({
    required this.plays,
    required this.wins,
    required this.draws,
    required this.losses,
  });

  OpeningCounts copyWith({
    int? plays,
    int? wins,
    int? draws,
    int? losses,
  }) {
    return OpeningCounts(
      plays: plays ?? this.plays,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
    );
  }

  Map<String, dynamic> toJson() => {
    'plays': plays,
    'wins': wins,
    'draws': draws,
    'losses': losses,
  };

  factory OpeningCounts.fromJson(Map<String, dynamic> json) {
    return OpeningCounts(
      plays: json['plays'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
    );
  }
}

class PerformanceAnalyticsCache {
  // Scotoma running counters
  final int scotomaDiagonalRetreatsCount;
  final int scotomaHorizontalSwingsCount;
  final int scotomaKnightForksCount;
  final int scotomaTimePanicCount;
  final int scotomaMaterialGreedCount;
  final int scotomaTunnelVisionCount;
  final int scotomaPinnedPiecesCount;
  final int scotomaKingSafetyCount;
  final int scotomaTotalRatedGames;
  final int scotomaAnalyzedGames;

  // Playstyle running counters
  final double playstyleDominanceSum;
  final int playstyleGamesCount;
  final int playstyleMaxElo;
  final int playstyleWins;
  final double playstyleSpeedSum;
  final int playstyleSpeedCount;
  final int playstylePressureGamesCount;
  final int playstylePressureSavesCount;
  final int playstyleClockStableCount;

  // Endgame running counters
  final double endgameWeightedScore;
  final double endgameWeight;
  final int endgameAdvantageGames;
  final int endgameAdvantageWins;
  final int endgameDisadvantageGames;
  final int endgameDisadvantageSaves;
  final int endgameSavesCount;

  // Middlegame running counters
  final int middlegameTotal;
  final int middlegameDecided;
  final int middlegameWins;
  final int middlegameDraws;

  // Openings running counters: map of opening name to counts
  final Map<String, OpeningCounts> openings;

  // Calculated/aggregated metrics ready for presentation
  final ScotomaResult? scotomaResult;
  final TacticalPlaystyleStats? playstyleStats;
  final List<OpeningRepertoireStats> openingsStats;
  final MiddlegamePerformanceStats? middlegameStats;
  final EndgamePerformanceStats? endgameStats;

  // Metadata for cache validation
  final int totalEntriesCount;

  const PerformanceAnalyticsCache({
    this.scotomaDiagonalRetreatsCount = 0,
    this.scotomaHorizontalSwingsCount = 0,
    this.scotomaKnightForksCount = 0,
    this.scotomaTimePanicCount = 0,
    this.scotomaMaterialGreedCount = 0,
    this.scotomaTunnelVisionCount = 0,
    this.scotomaPinnedPiecesCount = 0,
    this.scotomaKingSafetyCount = 0,
    this.scotomaTotalRatedGames = 0,
    this.scotomaAnalyzedGames = 0,

    this.playstyleDominanceSum = 0.0,
    this.playstyleGamesCount = 0,
    this.playstyleMaxElo = 400,
    this.playstyleWins = 0,
    this.playstyleSpeedSum = 0.0,
    this.playstyleSpeedCount = 0,
    this.playstylePressureGamesCount = 0,
    this.playstylePressureSavesCount = 0,
    this.playstyleClockStableCount = 0,

    this.endgameWeightedScore = 0.0,
    this.endgameWeight = 0.0,
    this.endgameAdvantageGames = 0,
    this.endgameAdvantageWins = 0,
    this.endgameDisadvantageGames = 0,
    this.endgameDisadvantageSaves = 0,
    this.endgameSavesCount = 0,

    this.middlegameTotal = 0,
    this.middlegameDecided = 0,
    this.middlegameWins = 0,
    this.middlegameDraws = 0,

    this.openings = const {},

    this.scotomaResult,
    this.playstyleStats,
    this.openingsStats = const [],
    this.middlegameStats,
    this.endgameStats,
    this.totalEntriesCount = 0,
  });

  factory PerformanceAnalyticsCache.empty() => const PerformanceAnalyticsCache();

  PerformanceAnalyticsCache increment({
    required PerformanceLedgerEntry entry,
    required SingleGameAnalysisResult analysis,
  }) {
    // 1. Playstyle Aggregations
    final isLoss = entry.result == 'L';
    final isWin = entry.result == 'W';
    final isDraw = entry.result == 'D';
    final isAnalyzed = analysis.isAnalyzed;

    final newPlaystyleGames = playstyleGamesCount + 1;
    final newDomSum = playstyleDominanceSum + entry.dominance;
    final avgDom = newDomSum / newPlaystyleGames;
    final aggression = ((avgDom + 5) / 10).clamp(0.0, 1.0);

    final newMaxElo = entry.ratingSnapshot > playstyleMaxElo ? entry.ratingSnapshot : playstyleMaxElo;
    final power = ((newMaxElo - 400) / (2000 - 400)).clamp(0.0, 1.0);

    final newWinsCount = playstyleWins + (isWin ? 1 : 0);
    final intensity = newWinsCount / newPlaystyleGames;

    double newSpeedSum = playstyleSpeedSum;
    int newSpeedCount = playstyleSpeedCount;
    if (entry.whiteTimeLeftMs > 0 || entry.blackTimeLeftMs > 0) {
      final double baseTimeMs = entry.baseTimeMs > 0 ? entry.baseTimeMs.toDouble() : 600000.0;
      final playerTimeLeftMs = entry.isPlayerWhite ? entry.whiteTimeLeftMs : entry.blackTimeLeftMs;
      final ratio = playerTimeLeftMs / baseTimeMs;
      newSpeedSum += ratio.clamp(0.0, 1.0);
      newSpeedCount++;
    }
    final speed = newSpeedCount > 0 ? (newSpeedSum / newSpeedCount) : 0.7;

    final opponentAvatar = AiAvatar.getAvatarByName(entry.opponentName);
    final opponentRating = opponentAvatar?.rating ?? entry.ratingSnapshot;
    final isPressureGame = entry.dominance < 0 || opponentRating >= entry.ratingSnapshot;

    final newPressureGamesCount = playstylePressureGamesCount + (isPressureGame ? 1 : 0);
    final newPressureSavesCount = playstylePressureSavesCount + ((isPressureGame && (isWin || isDraw)) ? 1 : 0);

    final baseMs = entry.baseTimeMs > 0 ? entry.baseTimeMs.toDouble() : 600000.0;
    final playerTimeMs = entry.isPlayerWhite ? entry.whiteTimeLeftMs : entry.blackTimeLeftMs;
    final isClockStable = (playerTimeMs / baseMs) >= 0.05;
    final newClockStableCount = playstyleClockStableCount + (isClockStable ? 1 : 0);

    final pressureSaveRate = newPressureGamesCount > 0 ? (newPressureSavesCount / newPressureGamesCount) : 0.5;
    final clockStability = newClockStableCount / newPlaystyleGames;
    final composure = ((pressureSaveRate * 0.7) + (clockStability * 0.3)).clamp(0.0, 1.0);

    final newPlaystyleStats = TacticalPlaystyleStats(
      aggression: aggression,
      power: power,
      composure: composure,
      intensity: intensity,
      speed: speed,
    );

    // 2. Scotoma Aggregations
    final scotomaInc = analysis.scotomaIncidents;
    final newDiag = scotomaDiagonalRetreatsCount + ((isLoss && isAnalyzed && scotomaInc.diagonalRetreats) ? 1 : 0);
    final newHoriz = scotomaHorizontalSwingsCount + ((isLoss && isAnalyzed && scotomaInc.horizontalSwings) ? 1 : 0);
    final newKnight = scotomaKnightForksCount + ((isLoss && isAnalyzed && scotomaInc.knightForks) ? 1 : 0);
    final newTime = scotomaTimePanicCount + ((isLoss && isAnalyzed && scotomaInc.timePanic) ? 1 : 0);
    final newGreed = scotomaMaterialGreedCount + ((isLoss && isAnalyzed && scotomaInc.materialGreed) ? 1 : 0);
    final newTunnel = scotomaTunnelVisionCount + ((isLoss && isAnalyzed && scotomaInc.tunnelVision) ? 1 : 0);
    final newPinned = scotomaPinnedPiecesCount + ((isLoss && isAnalyzed && scotomaInc.pinnedPieces) ? 1 : 0);
    final newKing = scotomaKingSafetyCount + ((isLoss && isAnalyzed && scotomaInc.kingSafety) ? 1 : 0);

    final newScotomaTotal = scotomaTotalRatedGames + 1;
    final newScotomaAnalyzed = scotomaAnalyzedGames + (isAnalyzed ? 1 : 0);

    final newScotomaResult = ScotomaResult(
      diagonalRetreats: newScotomaAnalyzed > 0 ? newDiag / newScotomaAnalyzed : 0.0,
      horizontalSwings: newScotomaAnalyzed > 0 ? newHoriz / newScotomaAnalyzed : 0.0,
      knightForks: newScotomaAnalyzed > 0 ? newKnight / newScotomaAnalyzed : 0.0,
      timePanic: newScotomaAnalyzed > 0 ? newTime / newScotomaAnalyzed : 0.0,
      materialGreed: newScotomaAnalyzed > 0 ? newGreed / newScotomaAnalyzed : 0.0,
      tunnelVision: newScotomaAnalyzed > 0 ? newTunnel / newScotomaAnalyzed : 0.0,
      pinnedPieces: newScotomaAnalyzed > 0 ? newPinned / newScotomaAnalyzed : 0.0,
      kingSafety: newScotomaAnalyzed > 0 ? newKing / newScotomaAnalyzed : 0.0,
      totalRatedGames: newScotomaTotal,
      analyzedGames: newScotomaAnalyzed,
      skippedGames: newScotomaTotal - newScotomaAnalyzed,
    );

    // 3. Openings Aggregations
    final newOpeningsMap = Map<String, OpeningCounts>.from(openings);
    final opName = analysis.openingName;
    final opCounts = newOpeningsMap[opName] ?? const OpeningCounts(plays: 0, wins: 0, draws: 0, losses: 0);
    newOpeningsMap[opName] = opCounts.copyWith(
      plays: opCounts.plays + 1,
      wins: opCounts.wins + (isWin ? 1 : 0),
      draws: opCounts.draws + (isDraw ? 1 : 0),
      losses: opCounts.losses + (isLoss ? 1 : 0),
    );

    final totalPlays = newOpeningsMap.values.fold<int>(0, (sum, item) => sum + item.plays);
    final newOpeningsStats = <OpeningRepertoireStats>[];
    newOpeningsMap.forEach((name, counts) {
      final double playPercentage = totalPlays > 0 ? (counts.plays / totalPlays) * 100 : 0.0;
      final double winRate = counts.plays > 0 ? (counts.wins + 0.5 * counts.draws) / counts.plays * 100 : 0.0;
      newOpeningsStats.add(OpeningRepertoireStats(
        name: name,
        plays: counts.plays,
        wins: counts.wins,
        draws: counts.draws,
        losses: counts.losses,
        playPercentage: playPercentage,
        winRate: winRate,
      ));
    });
    newOpeningsStats.sort((a, b) => b.plays.compareTo(a.plays));

    // 4. Endgame Aggregations
    double newEndgameWeightedScore = endgameWeightedScore;
    double newEndgameWeight = endgameWeight;
    int newEndgameAdvantageGames = endgameAdvantageGames;
    int newEndgameAdvantageWins = endgameAdvantageWins;
    int newEndgameDisadvantageGames = endgameDisadvantageGames;
    int newEndgameDisadvantageSaves = endgameDisadvantageSaves;
    int newEndgameSavesCount = endgameSavesCount;

    if (entry.reachedEndgame || analysis.reachedEndgame) {
      newEndgameSavesCount++;
      final score = isWin ? 1.0 : (isDraw ? 0.5 : 0.0);
      final finalFen = entry.endgameFen ?? analysis.endgameFen ?? entry.fen;
      final balance = FenParser.calculateMaterialBalance(finalFen, entry.isPlayerWhite);

      double complexity = 1.0;
      if (balance > 0) {
        complexity = 2.0;
        newEndgameAdvantageGames++;
        if (isWin) newEndgameAdvantageWins++;
      } else if (balance < 0) {
        complexity = 1.5;
        newEndgameDisadvantageGames++;
        if (isWin || isDraw) newEndgameDisadvantageSaves++;
      } else {
        complexity = 1.0;
      }
      newEndgameWeightedScore += (score * complexity);
      newEndgameWeight += complexity;
    }

    EndgamePerformanceStats? newEndgameStats;
    if (newEndgameSavesCount > 0) {
      final double epi = newEndgameWeight > 0 ? (newEndgameWeightedScore / newEndgameWeight) * 100 : 0.0;
      final double conversionRate = newEndgameAdvantageGames > 0 ? (newEndgameAdvantageWins / newEndgameAdvantageGames) * 100 : 0.0;
      final double saveRate = newEndgameDisadvantageGames > 0 ? (newEndgameDisadvantageSaves / newEndgameDisadvantageGames) * 100 : 0.0;

      String endgameCategory = 'Provisional';
      if (newEndgameSavesCount >= 15) {
        if (epi >= 85) {
          endgameCategory = 'Endgame Grandmaster';
        } else if (epi >= 70) {
          endgameCategory = 'Endgame Specialist';
        } else if (epi >= 50) {
          endgameCategory = 'Tactician Class I';
        } else {
          endgameCategory = 'Endgame Scholar';
        }
      } else {
        if (epi >= 75) {
          endgameCategory = 'Technician (Provisional)';
        } else {
          endgameCategory = 'Apprentice (Provisional)';
        }
      }

      newEndgameStats = EndgamePerformanceStats(
        epi: epi,
        conversionRate: conversionRate,
        saveRate: saveRate,
        ratingCategory: endgameCategory,
        advantageGames: newEndgameAdvantageGames,
        advantageWins: newEndgameAdvantageWins,
        disadvantageGames: newEndgameDisadvantageGames,
        disadvantageSaves: newEndgameDisadvantageSaves,
        endgameSavesCount: newEndgameSavesCount,
      );
    }

    // 5. Middlegame Aggregations
    int newMiddlegameTotal = middlegameTotal;
    int newMiddlegameDecided = middlegameDecided;
    int newMiddlegameWins = middlegameWins;
    int newMiddlegameDraws = middlegameDraws;

    if (analysis.isMiddlegame) {
      newMiddlegameTotal++;
      if (isWin) {
        newMiddlegameWins++;
      } else if (isDraw) {
        newMiddlegameDraws++;
      }
      if (analysis.decidedInMiddlegame) {
        newMiddlegameDecided++;
      }
    }

    MiddlegamePerformanceStats? newMiddlegameStats;
    if (newMiddlegameTotal > 0) {
      final scotomaSum = newScotomaResult.diagonalRetreats +
          newScotomaResult.horizontalSwings +
          newScotomaResult.knightForks +
          newScotomaResult.timePanic +
          newScotomaResult.materialGreed +
          newScotomaResult.tunnelVision +
          newScotomaResult.pinnedPieces +
          newScotomaResult.kingSafety;
      final avgScotoma = scotomaSum / 8.0;
      final mpi = (98.0 - (avgScotoma * 60.0)).clamp(50.0, 98.0);

      final decidedPercentage = (newMiddlegameDecided / newMiddlegameTotal) * 100.0;
      final winRate = ((newMiddlegameWins + 0.5 * newMiddlegameDraws) / newMiddlegameTotal) * 100.0;

      String archetype = 'Positional';
      String description = 'You prefer slow, strategic maneuvers, improving piece placement, and grinding down your opponent.';

      if (newPlaystyleStats.aggression >= 0.65) {
        archetype = 'Attacker';
        description = 'You launch direct attacks, look for pawn storms, and push pieces forward to target the opponent king.';
      } else if (newPlaystyleStats.intensity >= 0.65) {
        archetype = 'Tactician';
        description = 'You thrive in chaotic, double-edged middlegames where quick calculation and sharp shots dominate.';
      } else if (newPlaystyleStats.aggression <= 0.42) {
        archetype = 'Defender';
        description = 'You prioritize absolute safety, build solid defensive walls, and wait for your opponent to overreach.';
      }

      newMiddlegameStats = MiddlegamePerformanceStats(
        mpi: mpi,
        archetype: archetype,
        description: description,
        decidedPercentage: decidedPercentage,
        winRate: winRate,
        totalMiddlegames: newMiddlegameTotal,
      );
    }

    return PerformanceAnalyticsCache(
      scotomaDiagonalRetreatsCount: newDiag,
      scotomaHorizontalSwingsCount: newHoriz,
      scotomaKnightForksCount: newKnight,
      scotomaTimePanicCount: newTime,
      scotomaMaterialGreedCount: newGreed,
      scotomaTunnelVisionCount: newTunnel,
      scotomaPinnedPiecesCount: newPinned,
      scotomaKingSafetyCount: newKing,
      scotomaTotalRatedGames: newScotomaTotal,
      scotomaAnalyzedGames: newScotomaAnalyzed,

      playstyleDominanceSum: newDomSum,
      playstyleGamesCount: newPlaystyleGames,
      playstyleMaxElo: newMaxElo,
      playstyleWins: newWinsCount,
      playstyleSpeedSum: newSpeedSum,
      playstyleSpeedCount: newSpeedCount,
      playstylePressureGamesCount: newPressureGamesCount,
      playstylePressureSavesCount: newPressureSavesCount,
      playstyleClockStableCount: newClockStableCount,

      endgameWeightedScore: newEndgameWeightedScore,
      endgameWeight: newEndgameWeight,
      endgameAdvantageGames: newEndgameAdvantageGames,
      endgameAdvantageWins: newEndgameAdvantageWins,
      endgameDisadvantageGames: newEndgameDisadvantageGames,
      endgameDisadvantageSaves: newEndgameDisadvantageSaves,
      endgameSavesCount: newEndgameSavesCount,

      middlegameTotal: newMiddlegameTotal,
      middlegameDecided: newMiddlegameDecided,
      middlegameWins: newMiddlegameWins,
      middlegameDraws: newMiddlegameDraws,

      openings: newOpeningsMap,

      scotomaResult: newScotomaResult,
      playstyleStats: newPlaystyleStats,
      openingsStats: newOpeningsStats,
      middlegameStats: newMiddlegameStats,
      endgameStats: newEndgameStats,
      totalEntriesCount: totalEntriesCount + 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'scotomaDiagonalRetreatsCount': scotomaDiagonalRetreatsCount,
    'scotomaHorizontalSwingsCount': scotomaHorizontalSwingsCount,
    'scotomaKnightForksCount': scotomaKnightForksCount,
    'scotomaTimePanicCount': scotomaTimePanicCount,
    'scotomaMaterialGreedCount': scotomaMaterialGreedCount,
    'scotomaTunnelVisionCount': scotomaTunnelVisionCount,
    'scotomaPinnedPiecesCount': scotomaPinnedPiecesCount,
    'scotomaKingSafetyCount': scotomaKingSafetyCount,
    'scotomaTotalRatedGames': scotomaTotalRatedGames,
    'scotomaAnalyzedGames': scotomaAnalyzedGames,

    'playstyleDominanceSum': playstyleDominanceSum,
    'playstyleGamesCount': playstyleGamesCount,
    'playstyleMaxElo': playstyleMaxElo,
    'playstyleWins': playstyleWins,
    'playstyleSpeedSum': playstyleSpeedSum,
    'playstyleSpeedCount': playstyleSpeedCount,
    'playstylePressureGamesCount': playstylePressureGamesCount,
    'playstylePressureSavesCount': playstylePressureSavesCount,
    'playstyleClockStableCount': playstyleClockStableCount,

    'endgameWeightedScore': endgameWeightedScore,
    'endgameWeight': endgameWeight,
    'endgameAdvantageGames': endgameAdvantageGames,
    'endgameAdvantageWins': endgameAdvantageWins,
    'endgameDisadvantageGames': endgameDisadvantageGames,
    'endgameDisadvantageSaves': endgameDisadvantageSaves,
    'endgameSavesCount': endgameSavesCount,

    'middlegameTotal': middlegameTotal,
    'middlegameDecided': middlegameDecided,
    'middlegameWins': middlegameWins,
    'middlegameDraws': middlegameDraws,

    'openings': openings.map((k, v) => MapEntry(k, v.toJson())),

    'scotomaResult': scotomaResult == null ? null : {
      'diagonalRetreats': scotomaResult!.diagonalRetreats,
      'horizontalSwings': scotomaResult!.horizontalSwings,
      'knightForks': scotomaResult!.knightForks,
      'timePanic': scotomaResult!.timePanic,
      'materialGreed': scotomaResult!.materialGreed,
      'tunnelVision': scotomaResult!.tunnelVision,
      'pinnedPieces': scotomaResult!.pinnedPieces,
      'kingSafety': scotomaResult!.kingSafety,
      'totalRatedGames': scotomaResult!.totalRatedGames,
      'analyzedGames': scotomaResult!.analyzedGames,
      'skippedGames': scotomaResult!.skippedGames,
    },
    'playstyleStats': playstyleStats?.toJson(),
    'openingsStats': openingsStats.map((e) => e.toJson()).toList(),
    'middlegameStats': middlegameStats?.toJson(),
    'endgameStats': endgameStats?.toJson(),
    'totalEntriesCount': totalEntriesCount,
  };

  factory PerformanceAnalyticsCache.fromJson(Map<String, dynamic> json) {
    final rawScotoma = json['scotomaResult'] as Map<String, dynamic>?;
    ScotomaResult? scotomaResult;
    if (rawScotoma != null) {
      scotomaResult = ScotomaResult(
        diagonalRetreats: (rawScotoma['diagonalRetreats'] as num?)?.toDouble() ?? 0.0,
        horizontalSwings: (rawScotoma['horizontalSwings'] as num?)?.toDouble() ?? 0.0,
        knightForks: (rawScotoma['knightForks'] as num?)?.toDouble() ?? 0.0,
        timePanic: (rawScotoma['timePanic'] as num?)?.toDouble() ?? 0.0,
        materialGreed: (rawScotoma['materialGreed'] as num?)?.toDouble() ?? 0.0,
        tunnelVision: (rawScotoma['tunnelVision'] as num?)?.toDouble() ?? 0.0,
        pinnedPieces: (rawScotoma['pinnedPieces'] as num?)?.toDouble() ?? 0.0,
        kingSafety: (rawScotoma['kingSafety'] as num?)?.toDouble() ?? 0.0,
        totalRatedGames: rawScotoma['totalRatedGames'] as int? ?? 0,
        analyzedGames: rawScotoma['analyzedGames'] as int? ?? 0,
        skippedGames: rawScotoma['skippedGames'] as int? ?? 0,
      );
    }

    final rawOpenings = json['openings'] as Map<String, dynamic>? ?? {};
    final openings = rawOpenings.map(
      (k, v) => MapEntry(k, OpeningCounts.fromJson(Map<String, dynamic>.from(v as Map))),
    );

    final rawOpeningsStats = json['openingsStats'] as List<dynamic>? ?? [];
    final openingsStats = rawOpeningsStats
        .map((e) => OpeningRepertoireStats.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return PerformanceAnalyticsCache(
      scotomaDiagonalRetreatsCount: json['scotomaDiagonalRetreatsCount'] as int? ?? 0,
      scotomaHorizontalSwingsCount: json['scotomaHorizontalSwingsCount'] as int? ?? 0,
      scotomaKnightForksCount: json['scotomaKnightForksCount'] as int? ?? 0,
      scotomaTimePanicCount: json['scotomaTimePanicCount'] as int? ?? 0,
      scotomaMaterialGreedCount: json['scotomaMaterialGreedCount'] as int? ?? 0,
      scotomaTunnelVisionCount: json['scotomaTunnelVisionCount'] as int? ?? 0,
      scotomaPinnedPiecesCount: json['scotomaPinnedPiecesCount'] as int? ?? 0,
      scotomaKingSafetyCount: json['scotomaKingSafetyCount'] as int? ?? 0,
      scotomaTotalRatedGames: json['scotomaTotalRatedGames'] as int? ?? 0,
      scotomaAnalyzedGames: json['scotomaAnalyzedGames'] as int? ?? 0,

      playstyleDominanceSum: (json['playstyleDominanceSum'] as num?)?.toDouble() ?? 0.0,
      playstyleGamesCount: json['playstyleGamesCount'] as int? ?? 0,
      playstyleMaxElo: json['playstyleMaxElo'] as int? ?? 400,
      playstyleWins: json['playstyleWins'] as int? ?? 0,
      playstyleSpeedSum: (json['playstyleSpeedSum'] as num?)?.toDouble() ?? 0.0,
      playstyleSpeedCount: json['playstyleSpeedCount'] as int? ?? 0,
      playstylePressureGamesCount: json['playstylePressureGamesCount'] as int? ?? 0,
      playstylePressureSavesCount: json['playstylePressureSavesCount'] as int? ?? 0,
      playstyleClockStableCount: json['playstyleClockStableCount'] as int? ?? 0,

      endgameWeightedScore: (json['endgameWeightedScore'] as num?)?.toDouble() ?? 0.0,
      endgameWeight: (json['endgameWeight'] as num?)?.toDouble() ?? 0.0,
      endgameAdvantageGames: json['endgameAdvantageGames'] as int? ?? 0,
      endgameAdvantageWins: json['endgameAdvantageWins'] as int? ?? 0,
      endgameDisadvantageGames: json['endgameDisadvantageGames'] as int? ?? 0,
      endgameDisadvantageSaves: json['endgameDisadvantageSaves'] as int? ?? 0,
      endgameSavesCount: json['endgameSavesCount'] as int? ?? 0,

      middlegameTotal: json['middlegameTotal'] as int? ?? 0,
      middlegameDecided: json['middlegameDecided'] as int? ?? 0,
      middlegameWins: json['middlegameWins'] as int? ?? 0,
      middlegameDraws: json['middlegameDraws'] as int? ?? 0,

      openings: openings,

      scotomaResult: scotomaResult,
      playstyleStats: json['playstyleStats'] == null
          ? null
          : TacticalPlaystyleStats.fromJson(Map<String, dynamic>.from(json['playstyleStats'] as Map)),
      openingsStats: openingsStats,
      middlegameStats: json['middlegameStats'] == null
          ? null
          : MiddlegamePerformanceStats.fromJson(Map<String, dynamic>.from(json['middlegameStats'] as Map)),
      endgameStats: json['endgameStats'] == null
          ? null
          : EndgamePerformanceStats.fromJson(Map<String, dynamic>.from(json['endgameStats'] as Map)),
      totalEntriesCount: json['totalEntriesCount'] as int? ?? 0,
    );
  }
}
