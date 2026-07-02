import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/domain/models/performance_analytics_cache.dart';
import 'package:kingslayer_chess/features/chess/domain/models/dashboard_stats.dart';
import 'package:kingslayer_chess/features/chess/domain/performance_ledger_entry.dart';
import 'package:kingslayer_chess/features/chess/domain/performance_ledger_validator.dart';
import 'package:kingslayer_chess/src/rust/api/cognitive.dart';

PerformanceLedgerEntry _entry({
  required String id,
  required DateTime timestamp,
  required String result,
  required double dominance,
  required String opponentName,
  required int ratingSnapshot,
  required String fen,
  List<String> recentMoves = const ['e4'],
}) {
  return PerformanceLedgerEntry(
    id: id,
    timestamp: timestamp,
    source: PerformanceLedgerEntry.ratedBattlegroundSource,
    ratingCategory: 'rapid',
    gameMode: 'classic',
    result: result,
    dominance: dominance,
    opponentName: opponentName,
    ratingSnapshot: ratingSnapshot,
    fen: fen,
    recentMoves: recentMoves,
    isPlayerWhite: true,
    whiteTimeLeftMs: 600000,
    blackTimeLeftMs: 600000,
    reachedEndgame: false,
    baseTimeMs: 600000,
  );
}

void main() {
  group('PerformanceLedgerValidator Tests', () {
    test('Validate ID duplication and semantic duplication', () {
      final t1 = DateTime(2026, 7, 2, 12, 0, 0);
      final e1 = _entry(
        id: 'game1',
        timestamp: t1,
        result: 'W',
        dominance: 12.0,
        opponentName: 'Bot1',
        ratingSnapshot: 1500,
        fen: 'fen_final_1',
      );

      final existing = [e1];

      // 1. Direct ID duplicate
      final e2 = _entry(
        id: 'game1',
        timestamp: t1.add(const Duration(minutes: 10)),
        result: 'L',
        dominance: -5.0,
        opponentName: 'Bot2',
        ratingSnapshot: 1600,
        fen: 'fen_final_2',
      );
      final resIdDup = PerformanceLedgerValidator.validate(e2, existing);
      expect(resIdDup.isValid, isFalse);
      expect(resIdDup.errorMessage, contains('Duplicate entry ID detected'));

      // 2. Semantic duplicate (different ID, but same opponent, same FEN, similar timestamp)
      final e3 = _entry(
        id: 'game3',
        timestamp: t1.add(const Duration(seconds: 1)), // within 2 seconds
        result: 'W',
        dominance: 12.0,
        opponentName: 'Bot1',
        ratingSnapshot: 1500,
        fen: 'fen_final_1',
      );
      final resSemanticDup = PerformanceLedgerValidator.validate(e3, existing);
      expect(resSemanticDup.isValid, isFalse);
      expect(resSemanticDup.errorMessage, contains('Semantic duplicate game detected'));

      // 3. Sane game passes validation
      final e4 = _entry(
        id: 'game4',
        timestamp: t1.add(const Duration(minutes: 1)), // different timestamp
        result: 'L',
        dominance: -2.0,
        opponentName: 'Bot1',
        ratingSnapshot: 1500,
        fen: 'fen_final_1',
      );
      final resSane = PerformanceLedgerValidator.validate(e4, existing);
      expect(resSane.isValid, isTrue);
    });

    test('Validate boundary checks', () {
      final t1 = DateTime(2026, 7, 2, 12, 0, 0);

      // Dominance out of bounds
      final e1 = _entry(
        id: 'game1',
        timestamp: t1,
        result: 'W',
        dominance: 120.0, // out of bounds
        opponentName: 'Bot1',
        ratingSnapshot: 1500,
        fen: 'fen',
      );
      expect(PerformanceLedgerValidator.validate(e1, []).isValid, isFalse);

      // Rating out of bounds
      final e2 = _entry(
        id: 'game2',
        timestamp: t1,
        result: 'W',
        dominance: 12.0,
        opponentName: 'Bot1',
        ratingSnapshot: 4000, // out of bounds
        fen: 'fen',
      );
      expect(PerformanceLedgerValidator.validate(e2, []).isValid, isFalse);

      // Invalid result enum
      final e3 = _entry(
        id: 'game3',
        timestamp: t1,
        result: 'X', // invalid
        dominance: 12.0,
        opponentName: 'Bot1',
        ratingSnapshot: 1500,
        fen: 'fen',
      );
      expect(PerformanceLedgerValidator.validate(e3, []).isValid, isFalse);
    });
  });

  group('PerformanceAnalyticsCache Incremental Aggregation Tests', () {
    test('Aggregate playstyle, scotoma, and openings incrementally', () {
      var cache = PerformanceAnalyticsCache.empty();
      final t1 = DateTime(2026, 7, 2, 12, 0, 0);

      // Game 1: Win against Bot1 (Rating: 1500), Dominance: 10.0, Opening: Ruy Lopez
      final game1 = _entry(
        id: 'game1',
        timestamp: t1,
        result: 'W',
        dominance: 10.0,
        opponentName: 'Bot1',
        ratingSnapshot: 1400,
        fen: 'fen1',
        recentMoves: ['e4', 'e5', 'Nf3', 'Nc6', 'Bb5'],
      );
      const analysis1 = SingleGameAnalysisResult(
        scotomaIncidents: GameIncidents(
          diagonalRetreats: false,
          horizontalSwings: false,
          knightForks: false,
          timePanic: false,
          materialGreed: false,
          tunnelVision: false,
          pinnedPieces: false,
          kingSafety: false,
        ),
        openingName: 'Ruy Lopez',
        reachedEndgame: false,
        isMiddlegame: false,
        decidedInMiddlegame: false,
        isAnalyzed: true,
      );

      cache = cache.increment(entry: game1, analysis: analysis1);

      expect(cache.totalEntriesCount, 1);
      expect(cache.playstyleWins, 1);
      expect(cache.playstyleGamesCount, 1);
      expect(cache.playstyleMaxElo, 1400);
      expect(cache.playstyleDominanceSum, 10.0);
      expect(cache.playstyleStats?.aggression, closeTo(1.0, 0.01)); // avg dominance is 10, (10+5)/10 = 1.5 clamped to 1.0
      expect(cache.playstyleStats?.intensity, 1.0); // 1 win / 1 game
      expect(cache.openings['Ruy Lopez']?.plays, 1);
      expect(cache.openings['Ruy Lopez']?.wins, 1);

      // Game 2: Loss against Bot2 (Rating: 1600), Dominance: -6.0, Opening: Sicilian Defense
      // Loss results in scotoma check
      final game2 = _entry(
        id: 'game2',
        timestamp: t1.add(const Duration(minutes: 5)),
        result: 'L',
        dominance: -6.0,
        opponentName: 'Bot2',
        ratingSnapshot: 1500,
        fen: 'fen2',
        recentMoves: ['e4', 'c5'],
      );
      const analysis2 = SingleGameAnalysisResult(
        scotomaIncidents: GameIncidents(
          diagonalRetreats: true, // Loss incident
          horizontalSwings: false,
          knightForks: false,
          timePanic: false,
          materialGreed: false,
          tunnelVision: false,
          pinnedPieces: false,
          kingSafety: false,
        ),
        openingName: 'Sicilian Defense',
        reachedEndgame: false,
        isMiddlegame: false,
        decidedInMiddlegame: false,
        isAnalyzed: true,
      );

      cache = cache.increment(entry: game2, analysis: analysis2);

      expect(cache.totalEntriesCount, 2);
      expect(cache.playstyleWins, 1);
      expect(cache.playstyleGamesCount, 2);
      expect(cache.playstyleMaxElo, 1500); // 1500 is higher than 1400
      expect(cache.playstyleDominanceSum, 4.0); // 10.0 - 6.0
      expect(cache.playstyleStats?.intensity, 0.5); // 1 win / 2 games

      // Scotoma
      expect(cache.scotomaTotalRatedGames, 2);
      expect(cache.scotomaAnalyzedGames, 2);
      expect(cache.scotomaDiagonalRetreatsCount, 1);
      expect(cache.scotomaResult?.diagonalRetreats, 0.5); // 1 / 2

      // Openings
      expect(cache.openings['Sicilian Defense']?.plays, 1);
      expect(cache.openings['Sicilian Defense']?.losses, 1);
      expect(cache.openingsStats.length, 2);
      expect(cache.openingsStats[0].name, 'Ruy Lopez');
      expect(cache.openingsStats[1].name, 'Sicilian Defense');
    });
  });
}
