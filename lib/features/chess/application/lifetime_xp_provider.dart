import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/lifetime_xp_repository.dart';
import '../domain/models/lifetime_xp_state.dart';
import '../services/cloud_sync_service.dart';

class LifetimeXpNotifier extends Notifier<LifetimeXpState> {
  late final LifetimeXpRepository _repository;

  @override
  LifetimeXpState build() {
    _repository = ref.watch(lifetimeXpRepositoryProvider);
    _init();
    return const LifetimeXpState();
  }

  Future<void> _init() async {
    final loaded = await _repository.loadLifetimeXp();
    if (!ref.mounted) return;
    state = loaded;
  }

  Future<void> addXp(int amount, String eventKey) async {
    if (amount <= 0) return;

    final updatedLog = Map<String, int>.from(state.xpEventLog);
    // Aggregate or create new event entry
    updatedLog[eventKey] = (updatedLog[eventKey] ?? 0) + amount;

    state = state.copyWith(
      totalXp: state.totalXp + amount,
      xpEventLog: updatedLog,
    );
    await _saveState();
  }

  Future<void> addLandfall(int islandIndex, String islandName) async {
    final nameLower = islandName.toLowerCase();
    if (state.islandLandfalls.contains(nameLower)) return;

    final updatedLandfalls = Set<String>.from(state.islandLandfalls)..add(nameLower);
    final updatedLog = Map<String, int>.from(state.xpEventLog);
    final eventKey = 'landfall_$nameLower';
    updatedLog[eventKey] = 300;

    state = state.copyWith(
      totalXp: state.totalXp + 300,
      xpEventLog: updatedLog,
      islandLandfalls: updatedLandfalls,
    );
    await _saveState();
  }

  Future<void> _saveState() async {
    await _repository.saveLifetimeXp(state);
    if (!ref.mounted) return;
    ref.read(cloudSyncProvider.notifier).backup(silent: true);
  }

  /// Reloads Lifetime XP state from disk.
  /// Called after a cloud restore so medals/XP are immediately visible
  /// without requiring an app restart (Bug C-02 fix).
  Future<void> reloadFromDisk() => _init();

  /// Wipes all lifetime XP, event log, and island landfalls.
  /// Called by the Reset Progress flow.
  Future<void> resetAll() async {
    state = const LifetimeXpState();
    await _repository.saveLifetimeXp(state);
  }

  // Getters for Level details
  int get currentLevel {
    final xp = state.totalXp;
    if (xp < 600) return 1;
    if (xp < 1500) return 2;
    if (xp < 3000) return 3;
    if (xp < 6000) return 4;
    if (xp < 12000) return 5;
    if (xp < 25000) return 6;
    if (xp < 50000) return 7;
    return 8;
  }

  String get currentLevelTitle {
    switch (currentLevel) {
      case 1:
        return 'Pawn';
      case 2:
        return 'Squire';
      case 3:
        return 'Scout';
      case 4:
        return 'Sentinel';
      case 5:
        return 'Inquisitor';
      case 6:
        return 'Warlord';
      case 7:
        return 'Grandmaster';
      case 8:
        return 'Kingslayer';
      default:
        return 'Pawn';
    }
  }

  int get xpForCurrentLevelStart {
    switch (currentLevel) {
      case 1: return 0;
      case 2: return 600;
      case 3: return 1500;
      case 4: return 3000;
      case 5: return 6000;
      case 6: return 12000;
      case 7: return 25000;
      case 8: return 50000;
      default: return 0;
    }
  }

  int get xpForNextLevelStart {
    switch (currentLevel) {
      case 1: return 600;
      case 2: return 1500;
      case 3: return 3000;
      case 4: return 6000;
      case 5: return 12000;
      case 6: return 25000;
      case 7: return 50000;
      case 8: return 100000; // soft cap threshold
      default: return 600;
    }
  }

  int get winsXp {
    int sum = 0;
    state.xpEventLog.forEach((k, v) {
      if (k.startsWith('Defeated') || k.startsWith('landfall')) {
        sum += v;
      }
    });
    return sum;
  }

  int get puzzlesXp {
    int sum = 0;
    state.xpEventLog.forEach((k, v) {
      if (k.startsWith('Solved Puzzle')) {
        sum += v;
      }
    });
    return sum;
  }

  int get cinemaXp {
    int sum = 0;
    state.xpEventLog.forEach((k, v) {
      if (k.startsWith('Cinema Game Studied')) {
        sum += v;
      }
    });
    return sum;
  }

  int get reviewsXp {
    int sum = 0;
    state.xpEventLog.forEach((k, v) {
      if (k.startsWith('Weekly Review Completed')) {
        sum += v;
      }
    });
    return sum;
  }
}

final lifetimeXpRepositoryProvider = Provider((ref) => LifetimeXpRepository());

final lifetimeXpProvider =
    NotifierProvider<LifetimeXpNotifier, LifetimeXpState>(LifetimeXpNotifier.new);
