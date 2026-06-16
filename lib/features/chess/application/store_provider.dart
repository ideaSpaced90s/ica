import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:kingslayer_chess/main.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'chess_provider.dart';

String _getCurrentDateKey() {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
}

class FreeTierUsage {
  final String dateKey;
  final int ratedGamesPlayed;
  final int arenaGamesPlayed;
  final int chipPromptsUsed;
  final int puzzlesSolved;

  FreeTierUsage({
    required this.dateKey,
    required this.ratedGamesPlayed,
    required this.arenaGamesPlayed,
    required this.chipPromptsUsed,
    required this.puzzlesSolved,
  });

  FreeTierUsage copyWith({
    String? dateKey,
    int? ratedGamesPlayed,
    int? arenaGamesPlayed,
    int? chipPromptsUsed,
    int? puzzlesSolved,
  }) {
    return FreeTierUsage(
      dateKey: dateKey ?? this.dateKey,
      ratedGamesPlayed: ratedGamesPlayed ?? this.ratedGamesPlayed,
      arenaGamesPlayed: arenaGamesPlayed ?? this.arenaGamesPlayed,
      chipPromptsUsed: chipPromptsUsed ?? this.chipPromptsUsed,
      puzzlesSolved: puzzlesSolved ?? this.puzzlesSolved,
    );
  }

  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'ratedGamesPlayed': ratedGamesPlayed,
        'arenaGamesPlayed': arenaGamesPlayed,
        'chipPromptsUsed': chipPromptsUsed,
        'puzzlesSolved': puzzlesSolved,
      };

  factory FreeTierUsage.fromJson(Map<String, dynamic> json) {
    return FreeTierUsage(
      dateKey: json['dateKey'] ?? '',
      ratedGamesPlayed: json['ratedGamesPlayed'] ?? 0,
      arenaGamesPlayed: json['arenaGamesPlayed'] ?? 0,
      chipPromptsUsed: json['chipPromptsUsed'] ?? 0,
      puzzlesSolved: json['puzzlesSolved'] ?? 0,
    );
  }
}

class StoreState {
  final int goldBalance;
  final bool isPremium;
  final DateTime joinedFreeDate;
  final DateTime? joinedPremiumDate;
  final DateTime? subscriptionTill;
  final Map<String, DateTime> purchasedAvatars; // avatarId -> expiry DateTime
  final String? subscriptionPlan; // 'monthly', 'sixmonth', 'yearly', or null
  final Set<String> purchasedBoardThemes;
  final FreeTierUsage freeTierUsage;

  StoreState({
    required this.goldBalance,
    required this.isPremium,
    required this.joinedFreeDate,
    this.joinedPremiumDate,
    this.subscriptionTill,
    required this.purchasedAvatars,
    this.subscriptionPlan,
    required this.purchasedBoardThemes,
    required this.freeTierUsage,
  });

  StoreState copyWith({
    int? goldBalance,
    bool? isPremium,
    DateTime? joinedFreeDate,
    DateTime? joinedPremiumDate,
    DateTime? subscriptionTill,
    Map<String, DateTime>? purchasedAvatars,
    String? subscriptionPlan,
    Set<String>? purchasedBoardThemes,
    FreeTierUsage? freeTierUsage,
  }) {
    return StoreState(
      goldBalance: goldBalance ?? this.goldBalance,
      isPremium: isPremium ?? this.isPremium,
      joinedFreeDate: joinedFreeDate ?? this.joinedFreeDate,
      joinedPremiumDate: joinedPremiumDate ?? this.joinedPremiumDate,
      subscriptionTill: subscriptionTill ?? this.subscriptionTill,
      purchasedAvatars: purchasedAvatars ?? this.purchasedAvatars,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      purchasedBoardThemes: purchasedBoardThemes ?? this.purchasedBoardThemes,
      freeTierUsage: freeTierUsage ?? this.freeTierUsage,
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
        'purchasedBoardThemes': purchasedBoardThemes.toList(),
        'freeTierUsage': freeTierUsage.toJson(),
      };

  factory StoreState.fromJson(Map<String, dynamic> json) {
    final todayStr = _getCurrentDateKey();
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
      purchasedBoardThemes: (json['purchasedBoardThemes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          {},
      freeTierUsage: json['freeTierUsage'] != null
          ? FreeTierUsage.fromJson(Map<String, dynamic>.from(json['freeTierUsage']))
          : FreeTierUsage(
              dateKey: todayStr,
              ratedGamesPlayed: 0,
              arenaGamesPlayed: 0,
              chipPromptsUsed: 0,
              puzzlesSolved: 0,
            ),
    );
  }
}

class StoreRepository {
  static const _fileName = 'store_data.json';

  Future<StoreState> loadStore() async {
    final file = await _getFile();
    final todayStr = _getCurrentDateKey();
    final defaultState = StoreState(
      goldBalance: 1000,
      isPremium: false,
      joinedFreeDate: DateTime.now().subtract(const Duration(days: 15)),
      purchasedAvatars: {},
      purchasedBoardThemes: {},
      freeTierUsage: FreeTierUsage(
        dateKey: todayStr,
        ratedGamesPlayed: 0,
        arenaGamesPlayed: 0,
        chipPromptsUsed: 0,
        puzzlesSolved: 0,
      ),
    );

    if (!await file.exists()) {
      return defaultState;
    }

    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return defaultState;
      }

      final decoded = jsonDecode(raw);
      return StoreState.fromJson(Map<String, dynamic>.from(decoded));
    } catch (e) {
      return defaultState;
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

  StoreNotifier(
    this.ref, {
    bool initializeBilling = true,
    bool loadData = true,
  }) : super(StoreState(
          goldBalance: 1000,
          isPremium: false,
          joinedFreeDate: DateTime.now().subtract(const Duration(days: 15)),
          purchasedAvatars: {},
          purchasedBoardThemes: {},
          freeTierUsage: FreeTierUsage(
            dateKey: _getCurrentDateKey(),
            ratedGamesPlayed: 0,
            arenaGamesPlayed: 0,
            chipPromptsUsed: 0,
            puzzlesSolved: 0,
          ),
        )) {
    if (loadData) {
      _loadStoreData(initializeBilling: initializeBilling);
    }
  }

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStoreData({bool initializeBilling = true}) async {
    final loaded = await _repository.loadStore();
    if (!mounted) return;
    state = loaded;
    _checkExpirationsAndSync();
    if (initializeBilling) {
      _initializeBilling();
    }
  }

  void _initializeBilling() {
    final purchaseUpdatedStream = InAppPurchase.instance.purchaseStream;
    _purchaseSubscription = purchaseUpdatedStream.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
        // Handle stream error gracefully
      },
    );
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Purchase is pending
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          // Purchase error
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          final bool valid = await _verifyPurchase(purchaseDetails);
          if (valid) {
            _grantEntitlement(purchaseDetails);
          }
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // Under local verification, check that billing information matches
    // In production, sync with secure server/Firebase logic.
    return purchaseDetails.status == PurchaseStatus.purchased || 
           purchaseDetails.status == PurchaseStatus.restored;
  }

  void _grantEntitlement(PurchaseDetails purchase) {
    final productId = purchase.productID;
    
    if (productId == 'themes') {
      final pendingThemeId = sharedPrefs.getString('pending_theme_id');
      if (pendingThemeId != null) {
        final updatedThemes = Set<String>.from(state.purchasedBoardThemes);
        updatedThemes.add(pendingThemeId);
        state = state.copyWith(purchasedBoardThemes: updatedThemes);
        _saveStoreData();
        
        // Auto-apply the theme
        ref.read(chessProvider.notifier).setBoardTheme(pendingThemeId);
      }
      sharedPrefs.remove('pending_theme_id');
      return;
    }

    if (productId.startsWith('theme_')) {
      final themeId = productId.replaceFirst('theme_', '');
      final updatedThemes = Set<String>.from(state.purchasedBoardThemes);
      updatedThemes.add(themeId);
      state = state.copyWith(purchasedBoardThemes: updatedThemes);
      _saveStoreData();
      return;
    }

    final now = DateTime.now();
    DateTime newExpiry;
    String plan = productId;

    if (productId == 'ica_saas_1') {
      final pendingPlan = sharedPrefs.getString('pending_plan_id');
      if (pendingPlan != null) {
        plan = pendingPlan;
      } else if (state.subscriptionPlan != null) {
        plan = state.subscriptionPlan!;
      } else {
        plan = 'yearly';
      }
    }

    int days = 30;
    if (plan == 'sixmonth') {
      days = 180;
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

    if (productId == 'ica_saas_1') {
      sharedPrefs.remove('pending_plan_id');
    }
  }

  Future<void> buySubscription(String planId) async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      throw StateError('Google Play Store is not available on this device.');
    }

    if (Platform.isAndroid) {
      final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({'ica_saas_1'});
      if (response.productDetails.isEmpty) {
        throw StateError('Subscription product "ica_saas_1" not found in store.');
      }

      final ProductDetails productDetails = response.productDetails.first;
      if (productDetails is GooglePlayProductDetails) {
        SubscriptionOfferDetailsWrapper? selectedOffer;
        String targetBasePlanId;
        String? targetOfferId;
        if (planId == 'yearly') {
          targetBasePlanId = 'annual-premium';
          targetOfferId = 'free-trial-7-days';
        } else if (planId == 'sixmonth') {
          targetBasePlanId = 'six-monthly-premium';
          targetOfferId = 'free-trial';
        } else if (planId == 'monthly') {
          targetBasePlanId = 'monthly-premium';
          targetOfferId = 'first3monthdiscounted';
        } else {
          throw ArgumentError('Invalid plan ID: $planId');
        }

        final offers = productDetails.productDetails.subscriptionOfferDetails;
        if (offers != null) {
          for (final offer in offers) {
            if (offer.basePlanId == targetBasePlanId && offer.offerId == targetOfferId) {
              selectedOffer = offer;
              break;
            }
          }
          if (selectedOffer == null) {
            for (final offer in offers) {
              if (offer.basePlanId == targetBasePlanId) {
                selectedOffer = offer;
                break;
              }
            }
          }
        }

        if (selectedOffer == null) {
          throw StateError('No billing plan found on Google Play for $planId ($targetBasePlanId).');
        }

        await sharedPrefs.setString('pending_plan_id', planId);

        final GooglePlayPurchaseParam purchaseParam = GooglePlayPurchaseParam(
          productDetails: productDetails,
          offerToken: selectedOffer.offerIdToken,
        );

        await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
      } else {
        throw StateError('Product details are not GooglePlayProductDetails on Android.');
      }
    } else {
      // Platform is not Android (e.g. iOS), query the planId directly
      final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({planId});
      if (response.productDetails.isEmpty) {
        throw StateError('Product "$planId" not found in store.');
      }

      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }

  Future<void> buyTheme(String themeId) async {
    const productId = 'themes';
    final bool available = await InAppPurchase.instance.isAvailable();
    if (!available) {
      throw StateError('Google Play Store is not available on this device.');
    }

    final ProductDetailsResponse response = await InAppPurchase.instance.queryProductDetails({productId});
    if (response.productDetails.isEmpty) {
      throw StateError('Theme product "$productId" not found in store.');
    }

    final ProductDetails productDetails = response.productDetails.first;

    // Save pending theme ID so we know which specific theme to unlock on successful purchase callback
    await sharedPrefs.setString('pending_theme_id', themeId);

    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    // Launch purchase as a consumable so it can be repeatedly bought for other themes
    await InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
  }

  Future<void> restorePurchases() async {
    final bool available = await InAppPurchase.instance.isAvailable();
    if (available) {
      await InAppPurchase.instance.restorePurchases();
    }
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

  // Buy or renew subscription via simulation (USD or INR based)
  void simulateUSDSubscription(String plan) {
    final now = DateTime.now();
    DateTime newExpiry;
    int days = 30;
    if (plan == 'sixmonth') {
      days = 180;
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

  // Board theme ownership checking
  bool isBoardThemePurchased(String themeId) {
    if (state.isPremium) return true;
    
    // Free themes
    const freeThemes = {'classic', 'scholar', 'vector_wood', 'theme3', 'sprite_fairytale'};
    if (freeThemes.contains(themeId)) return true;

    // Purchased premium themes
    return state.purchasedBoardThemes.contains(themeId);
  }

  // Purchase a board theme (simulated)
  void purchaseBoardTheme(String themeId) {
    final updatedThemes = Set<String>.from(state.purchasedBoardThemes);
    updatedThemes.add(themeId);
    state = state.copyWith(purchasedBoardThemes: updatedThemes);
    _saveStoreData();
  }

  // Free tier daily limit reset & check methods
  FreeTierUsage _getUpdatedUsage() {
    final today = _getCurrentDateKey();
    if (state.freeTierUsage.dateKey != today) {
      return FreeTierUsage(
        dateKey: today,
        ratedGamesPlayed: 0,
        arenaGamesPlayed: 0,
        chipPromptsUsed: 0,
        puzzlesSolved: 0,
      );
    }
    return state.freeTierUsage;
  }

  bool canPlayRatedGame() {
    if (state.isPremium) return true;
    final usage = _getUpdatedUsage();
    return usage.ratedGamesPlayed < 1;
  }

  void recordRatedGame() {
    if (state.isPremium) return;
    final usage = _getUpdatedUsage();
    state = state.copyWith(
      freeTierUsage: usage.copyWith(ratedGamesPlayed: usage.ratedGamesPlayed + 1),
    );
    _saveStoreData();
  }

  bool canPlayArenaGame() {
    if (state.isPremium) return true;
    final usage = _getUpdatedUsage();
    return usage.arenaGamesPlayed < 3;
  }

  void recordArenaGame() {
    if (state.isPremium) return;
    final usage = _getUpdatedUsage();
    state = state.copyWith(
      freeTierUsage: usage.copyWith(arenaGamesPlayed: usage.arenaGamesPlayed + 1),
    );
    _saveStoreData();
  }

  bool canUseChipPrompt() {
    if (state.isPremium) return true;
    final usage = _getUpdatedUsage();
    return usage.chipPromptsUsed < 5;
  }

  void recordChipPrompt() {
    if (state.isPremium) return;
    final usage = _getUpdatedUsage();
    state = state.copyWith(
      freeTierUsage: usage.copyWith(chipPromptsUsed: usage.chipPromptsUsed + 1),
    );
    _saveStoreData();
  }

  bool canSolvePuzzle() {
    if (state.isPremium) return true;
    final usage = _getUpdatedUsage();
    return usage.puzzlesSolved < 3;
  }

  void recordPuzzle() {
    if (state.isPremium) return;
    final usage = _getUpdatedUsage();
    state = state.copyWith(
      freeTierUsage: usage.copyWith(puzzlesSolved: usage.puzzlesSolved + 1),
    );
    _saveStoreData();
  }

  // Dynamic clean-up logic: if active theme or avatar is expired, fall back to default
  void _checkExpirationsAndSync() {
    if (!mounted) return;
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

final storeTabProvider = StateProvider<int>((ref) => 0);
final storeHighlightThemeIdProvider = StateProvider<String?>((ref) => null);
