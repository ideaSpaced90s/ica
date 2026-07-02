import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kingslayer_chess/src/rust/api/cognitive.dart';
import 'package:kingslayer_chess/features/chess/data/performance_analytics_cache_repository.dart';
import 'package:kingslayer_chess/features/chess/data/performance_ledger_repository.dart';
import 'package:kingslayer_chess/features/chess/domain/models/performance_analytics_cache.dart';
import 'package:kingslayer_chess/features/chess/domain/performance_ledger_entry.dart';
import 'package:kingslayer_chess/features/chess/domain/performance_ledger_validator.dart';
import 'package:kingslayer_chess/features/chess/application/chess_provider.dart';

class PerformanceLedgerManagerState {
  final List<PerformanceLedgerEntry> entries;
  final PerformanceAnalyticsCache cache;
  final bool isInitialized;

  PerformanceLedgerManagerState({
    required this.entries,
    required this.cache,
    required this.isInitialized,
  });

  PerformanceLedgerManagerState copyWith({
    List<PerformanceLedgerEntry>? entries,
    PerformanceAnalyticsCache? cache,
    bool? isInitialized,
  }) {
    return PerformanceLedgerManagerState(
      entries: entries ?? this.entries,
      cache: cache ?? this.cache,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class PerformanceLedgerManager extends Notifier<PerformanceLedgerManagerState> {
  late final PerformanceLedgerRepository _ledgerRepo;
  late final PerformanceAnalyticsCacheRepository _cacheRepo;

  @override
  PerformanceLedgerManagerState build() {
    _ledgerRepo = ref.watch(performanceLedgerRepositoryProvider);
    _cacheRepo = ref.watch(performanceAnalyticsCacheRepositoryProvider);

    initialize();

    return PerformanceLedgerManagerState(
      entries: const [],
      cache: PerformanceAnalyticsCache.empty(),
      isInitialized: false,
    );
  }

  Future<void> initialize() async {
    final entries = await _ledgerRepo.listEntries();
    var cache = await _cacheRepo.loadCache();

    // Cache validation: if cache doesn't exist, is corrupt, or doesn't match ledger length,
    // we rebuild the cache from scratch.
    if (cache == null || cache.totalEntriesCount != entries.length) {
      debugPrint('PerformanceLedgerManager: Cache missing or mismatch. Rebuilding cache from scratch...');
      cache = await _rebuildCache(entries);
      if (!ref.mounted) return;
      await _cacheRepo.saveCache(cache);
    }

    if (!ref.mounted) return;
    state = PerformanceLedgerManagerState(
      entries: entries,
      cache: cache,
      isInitialized: true,
    );
  }

  Future<PerformanceAnalyticsCache> _rebuildCache(List<PerformanceLedgerEntry> entries) async {
    var cache = PerformanceAnalyticsCache.empty();
    // Replay games in reverse order (oldest to newest) to build up aggregates correctly
    final reversedEntries = entries.reversed.toList();
    for (final entry in reversedEntries) {
      final analysis = _analyzeEntrySync(entry);
      cache = cache.increment(entry: entry, analysis: analysis);
    }
    return cache;
  }

  SingleGameAnalysisResult _analyzeEntrySync(PerformanceLedgerEntry entry) {
    final uciGame = SavedGameUci(
      recentMoves: entry.recentMoves,
      uciMoves: entry.uciMoves,
      initialFen: entry.initialFen,
      finalFen: entry.fen,
      isChess960: entry.gameMode == 'chess960',
      isPlayerWhite: entry.isPlayerWhite,
      result: entry.result,
      whiteTimeLeftMs: entry.whiteTimeLeftMs,
      blackTimeLeftMs: entry.blackTimeLeftMs,
      ratingCategory: entry.ratingCategory,
    );
    try {
      return analyzeSingleGame(game: uciGame);
    } catch (e) {
      debugPrint('PerformanceLedgerManager: Failed to analyze single game ${entry.id}: $e');
      return const SingleGameAnalysisResult(
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
        openingName: 'Unknown / Open Line',
        reachedEndgame: false,
        isMiddlegame: false,
        decidedInMiddlegame: false,
        isAnalyzed: false,
      );
    }
  }

  Future<void> addEntry(PerformanceLedgerEntry entry) async {
    // 1. Run Validation
    final validationResult = PerformanceLedgerValidator.validate(entry, state.entries);
    if (!validationResult.isValid) {
      debugPrint('PerformanceLedgerManager WARNING: validation failed for entry ${entry.id}. Error: ${validationResult.errorMessage}. Discarding duplicate/corrupt entry.');
      return;
    }

    // 2. Perform Single Game Analysis via FFI
    final analysis = _analyzeEntrySync(entry);

    // 3. Increment Cache
    final newCache = state.cache.increment(entry: entry, analysis: analysis);

    // 4. Save to Repository (add entry inserts at index 0)
    final newEntries = await _ledgerRepo.addEntry(entry);
    await _cacheRepo.saveCache(newCache);

    // 5. Update state
    state = state.copyWith(
      entries: newEntries,
      cache: newCache,
    );
  }

  Future<void> clearAll() async {
    await _ledgerRepo.clearAll();
    await _cacheRepo.clearCache();
    state = PerformanceLedgerManagerState(
      entries: const [],
      cache: PerformanceAnalyticsCache.empty(),
      isInitialized: true,
    );
  }

  Future<void> reloadFromDisk() async {
    await initialize();
  }
}

// Dependency injection providers
final performanceAnalyticsCacheRepositoryProvider = Provider((ref) => PerformanceAnalyticsCacheRepository());

final performanceLedgerManagerProvider = NotifierProvider<PerformanceLedgerManager, PerformanceLedgerManagerState>(PerformanceLedgerManager.new);
