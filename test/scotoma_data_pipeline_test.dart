import 'package:flutter_test/flutter_test.dart';
import 'package:kingslayer_chess/features/chess/application/battleground_provider.dart';
import 'package:kingslayer_chess/features/chess/domain/performance_ledger_entry.dart';
import 'package:kingslayer_chess/features/chess/presentation/widgets/scotoma_card.dart';

PerformanceLedgerEntry _entry({
  String source = PerformanceLedgerEntry.ratedBattlegroundSource,
  String result = 'W',
}) {
  return PerformanceLedgerEntry(
    id: '$source-$result',
    timestamp: DateTime(2026, 6, 7),
    source: source,
    ratingCategory: 'blitz',
    gameMode: 'classic',
    result: result,
    dominance: 0,
    opponentName: 'Test Opponent',
    ratingSnapshot: 1200,
    fen: '',
    recentMoves: const ['e4'],
    isPlayerWhite: true,
    whiteTimeLeftMs: 60_000,
    blackTimeLeftMs: 60_000,
  );
}

void main() {
  test('Scotoma selector includes only completed rated Battleground games', () {
    final selected = selectScotomaLedgerEntries([
      _entry(result: 'W'),
      _entry(result: 'L'),
      _entry(result: 'D'),
      _entry(result: ''),
      _entry(source: 'casualArena'),
      _entry(source: 'academy'),
    ]);

    expect(selected.map((entry) => entry.result), ['W', 'L', 'D']);
    expect(
      selected.every(
        (entry) =>
            entry.source == PerformanceLedgerEntry.ratedBattlegroundSource,
      ),
      isTrue,
    );
  });

  test('legacy ledger JSON defaults to rated Battleground source', () {
    final json = _entry().toJson()
      ..remove('source')
      ..remove('uciMoves')
      ..remove('initialFen');

    final migrated = PerformanceLedgerEntry.fromJson(json);

    expect(migrated.source, PerformanceLedgerEntry.ratedBattlegroundSource);
    expect(migrated.uciMoves, isEmpty);
    expect(migrated.initialFen, isNull);
  });

  test('24-game evidence threshold and summary are exact', () {
    expect(hasScotomaDiagnosis(peakRate: 4 / 24, analyzedGames: 24), isTrue);
    expect(hasScotomaDiagnosis(peakRate: 3 / 24, analyzedGames: 24), isFalse);
    expect(
      scotomaAnalysisSummary(
        analyzedGames: 22,
        totalRatedGames: 24,
        skippedGames: 2,
      ),
      'Analyzed 22 of 24 rated Battleground games (2 skipped).',
    );
  });
}
