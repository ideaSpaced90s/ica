import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'chess_provider.dart';

class StoreState {
  final int goldBalance;
  final bool isPremium;
  final DateTime joinedFreeDate;
  final DateTime? joinedPremiumDate;
  final DateTime? subscriptionTill;
  final Map<String, DateTime> purchasedAvatars; // avatarId -> expiry DateTime
  final String? subscriptionPlan; // 'monthly', 'quarterly', 'yearly', or null

  StoreState({
    required this.goldBalance,
    required this.isPremium,
    required this.joinedFreeDate,
    this.joinedPremiumDate,
    this.subscriptionTill,
    required this.purchasedAvatars,
    this.subscriptionPlan,
  });

  StoreState copyWith({
    int? goldBalance,
    bool? isPremium,
    DateTime? joinedFreeDate,
    DateTime? joinedPremiumDate,
    DateTime? subscriptionTill,
    Map<String, DateTime>? purchasedAvatars,
    String? subscriptionPlan,
  }) {
    return StoreState(
      goldBalance: goldBalance ?? this.goldBalance,
      isPremium: isPremium ?? this.isPremium,
      joinedFreeDate: joinedFreeDate ?? this.joinedFreeDate,
      joinedPremiumDate: joinedPremiumDate ?? this.joinedPremiumDate,
      subscriptionTill: subscriptionTill ?? this.subscriptionTill,
      purchasedAvatars: purchasedAvatars ?? this.purchasedAvatars,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }

  Map<String, dynamic> toJson() => {
        'goldBalance': goldBalance,
        'isPremium': isPremium,
        'joinedFreeDate': joinedFreeDate.toIso8601String(),
        'joinedPremiumDate': joinedPremiumDate?.toIso8601String(),
        'subscriptionTill': subscriptionTill?.toIso8601String(),
        'purchasedAvatars': purchasedAvatars.map((k, v) => MapEntry(k, v.toIso8601String())),
        'subscriptionPlan': subscriptionPlan,
      };

  factory StoreState.fromJson(Map<String, dynamic> json) {
    return StoreState(
      goldBalance: json['goldBalance'] ?? 1000,
      isPremium: json['isPremium'] ?? false,
      joinedFreeDate: json['joinedFreeDate'] != null
          ? DateTime.parse(json['joinedFreeDate'])
          : DateTime.now().subtract(const Duration(days: 15)),
      joinedPremiumDate: json['joinedPremiumDate'] != null ? DateTime.parse(json['joinedPremiumDate']) : null,
      subscriptionTill: json['subscriptionTill'] != null ? DateTime.parse(json['subscriptionTill']) : null,
      purchasedAvatars: (json['purchasedAvatars'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, DateTime.parse(v)),
          ) ??
          {},
      subscriptionPlan: json['subscriptionPlan'],
    );
  }
}

class StoreRepository {
  static const _fileName = 'store_data.json';

  Future<StoreState> loadStore() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return StoreState(
        goldBalance: 1000,
        isPremium: false,
        joinedFreeDate: DateTime.now().subtract(const Duration(days: 15)),
        purchasedAvatars: {},
      );
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return StoreState(
          goldBalance: 1000,
          isPremium: false,
          joinedFreeDate: DateTime.now().subtract(const Duration(days: 15)),
          purchasedAvatars: {},
        );
      }

      final decoded = jsonDecode(raw);
      return StoreState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      return StoreState(
        goldBalance: 1000,
        isPremium: false,
        joinedFreeDate: DateTime.now().subtract(const Duration(days: 15)),
        purchasedAvatars: {},
      );
    }
  }

  Future<void> saveStore(StoreState state) async {
    final file = await _getFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(state.toJson()), flush: true);
  }

  Future<File> _getFile() async {
    final supportDirectory = await getApplicationSupportDirectory();
    return File(p.join(supportDirectory.path, _fileName));
  }
}

final storeProvider = StateNotifierProvider<StoreNotifier, StoreState>((ref) {
  return StoreNotifier(ref);
});

class StoreNotifier extends StateNotifier<StoreState> {
  final Ref ref;
  final StoreRepository _repository = StoreRepository();

  StoreNotifier(this.ref)
      : super(StoreState(
          goldBalance: 1000,
          isPremium: false,
          joinedFreeDate: DateTime.now().subtract(const Duration(days: 15)),
          purchasedAvatars: {},
        )) {
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    final loaded = await _repository.loadStore();
    state = loaded;
    _checkExpirationsAndSync();
  }

  Future<void> _saveStoreData() async {
    await _repository.saveStore(state);
  }

  // Refill Gold for testing
  void addGold(int amount) {
    state = state.copyWith(goldBalance: state.goldBalance + amount);
    _saveStoreData();
  }

  // Deduct gold utility
  bool _deductGold(int amount) {
    if (state.goldBalance >= amount) {
      state = state.copyWith(goldBalance: state.goldBalance - amount);
      _saveStoreData();
      return true;
    }
    return false;
  }

  // Buy or renew subscription via simulation (USD-based)
  void simulateUSDSubscription(String plan) {
    final now = DateTime.now();
    DateTime newExpiry;
    int days = 30;
    if (plan == 'quarterly') {
      days = 90;
    } else if (plan == 'yearly') {
      days = 365;
    }

    if (state.isPremium && state.subscriptionTill != null && state.subscriptionTill!.isAfter(now)) {
      newExpiry = state.subscriptionTill!.add(Duration(days: days));
    } else {
      newExpiry = now.add(Duration(days: days));
    }

    state = state.copyWith(
      isPremium: true,
      joinedPremiumDate: state.joinedPremiumDate ?? now,
      subscriptionTill: newExpiry,
      subscriptionPlan: plan,
    );
    _saveStoreData();
  }

  // Cancel subscription simulation
  void cancelSubscription() {
    state = state.copyWith(
      isPremium: false,
      subscriptionTill: null,
      subscriptionPlan: null,
    );
    _saveStoreData();
  }



  // Buy or renew an AI Opponent Avatar
  bool purchaseOrRenewAvatar(String avatarId, int price) {
    if (_deductGold(price)) {
      final now = DateTime.now();
      DateTime newExpiry;

      final currentExpiry = state.purchasedAvatars[avatarId];
      if (currentExpiry != null && currentExpiry.isAfter(now)) {
        newExpiry = currentExpiry.add(const Duration(days: 7));
      } else {
        newExpiry = now.add(const Duration(days: 7));
      }

      final updatedAvatars = Map<String, DateTime>.from(state.purchasedAvatars);
      updatedAvatars[avatarId] = newExpiry;

      state = state.copyWith(purchasedAvatars: updatedAvatars);
      _saveStoreData();
      return true;
    }
    return false;
  }

  // Check if an avatar is unlocked
  bool isAvatarUnlocked(String avatarId) {
    // All avatars are unlocked for now (store bypassed)
    return true;
  }

  // Dynamic clean-up logic: if active theme or avatar is expired, fall back to default
  void _checkExpirationsAndSync() {
    final chessState = ref.read(chessProvider);
    final chessNotifier = ref.read(chessProvider.notifier);

    // Verify Opponent Avatar
    if (!isAvatarUnlocked(chessState.engineLevel)) {
      chessNotifier.setEngineLevel('avatar_6'); // default engine level
    }

    // Verify Player Avatar
    if (!isAvatarUnlocked(chessState.bottomAvatarId)) {
      chessNotifier.setBottomAvatarId('avatar_6'); // default player engine level
    }

    // Update Premium status in case subscription is expired
    if (state.isPremium && state.subscriptionTill != null && state.subscriptionTill!.isBefore(DateTime.now())) {
      state = state.copyWith(isPremium: false);
      _saveStoreData();
    }
  }

  // Run a check called from settings/arena pages to verify everything is in order
  void verifyActiveSelections() {
    _checkExpirationsAndSync();
  }
}
