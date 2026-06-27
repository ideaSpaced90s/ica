import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/chess_provider.dart';
import '../../application/store_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import '../widgets/ambient_scaffold.dart';
import '../shared/themes/chess_theme.dart';
import '../arena/themes/theme_registry.dart';
import '../widgets/theme_preview_dialog.dart';
import '../widgets/premium_membership_card.dart';
import '../../services/auth_service.dart';
import '../widgets/sign_in_prompt_dialog.dart';

class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key});

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(storeTabProvider);
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialTab);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      ref.read(storeTabProvider.notifier).state = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);

    // Refresh checking on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      storeNotifier.verifyActiveSelections();
    });

    ref.listen<int>(storeTabProvider, (previous, next) {
      if (_tabController.index != next) {
        _tabController.animateTo(next);
      }
    });

    return AmbientScaffold(
      blob1Color: const Color(0xFFE0F2FE), // Soft cyan/blue
      blob2Color: const Color(0xFFF3E8FF), // Soft purple
      blob3Color: const Color(0xFFFEF08A), // Warm yellow/gold
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // TabBar in a beautiful container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: ScholarlyTheme.accentBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: ScholarlyTheme.textPrimary,
                  labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  unselectedLabelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                  tabs: const [
                    Tab(text: 'PLANS'),
                    Tab(text: 'BOARD THEMES'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // TabBarView content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPlansTab(context, storeState, storeNotifier),
                  _buildThemesTab(context, storeState, storeNotifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansTab(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // Subscription Status Card
        _buildSubscriptionCard(context, storeState, storeNotifier),

        const SizedBox(height: 16),

        // Plans Header
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'CHOOSE YOUR PLAN',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: ScholarlyTheme.textMuted,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Free Plan Card (Non-purchasable, display limits)
        _buildFreePlanCard(context, storeState),

        const SizedBox(height: 16),

        // Paid Plans
        ...plans.map((plan) {
          final isActive = storeState.isPremium && storeState.subscriptionPlan == plan.id;
          return _buildPaidPlanCard(context, plan, isActive, storeState, storeNotifier);
        }),

        if (storeState.isPremium) ...[
          const SizedBox(height: 24),
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                _showCancelDialog(context, storeNotifier);
              },
              child: Text(
                'CANCEL SUBSCRIPTION',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.redAccent.shade200,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThemesTab(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    final chessState = ref.watch(chessProvider);
    final chessNotifier = ref.read(chessProvider.notifier);

    // Grouping themes
    final freeThemeIds = {'classic', 'scholar', 'vector_wood', 'theme3', 'sprite_fairytale'};
    final featuredThemeIds = {
      'sprite_diamonds',
      'sprite_lightning',
      'sprite_plasma',
      'sprite_arc',
      'sprite_seasons',
    };

    final freeThemes = ThemeRegistry.allThemes.where((t) => freeThemeIds.contains(t.id)).toList();
    final premiumThemes = ThemeRegistry.allThemes.where((t) => !freeThemeIds.contains(t.id)).toList();
    
    final featuredThemes = premiumThemes.where((t) => featuredThemeIds.contains(t.id)).toList();
    final otherPremiumThemes = premiumThemes.where((t) => !featuredThemeIds.contains(t.id)).toList();

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = (screenWidth / 160).floor().clamp(2, 6);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Section: Featured Premium Themes Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'FEATURED PREMIUM THEMES',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: ScholarlyTheme.accentGold,
              ),
            ),
          ),
        ),

        // Grid for Featured Premium Themes
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final theme = featuredThemes[index];
                final isSelected = theme.id == chessState.boardThemeId;
                return _buildThemeShopCard(context, theme, false, isSelected, storeState, storeNotifier, chessNotifier, isFeatured: true);
              },
              childCount: featuredThemes.length,
            ),
          ),
        ),

        // Section: Other Premium Themes Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'PREMIUM THEMES',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: ScholarlyTheme.textMuted,
              ),
            ),
          ),
        ),

        // Grid for Other Premium Themes
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final theme = otherPremiumThemes[index];
                final isSelected = theme.id == chessState.boardThemeId;
                return _buildThemeShopCard(context, theme, false, isSelected, storeState, storeNotifier, chessNotifier);
              },
              childCount: otherPremiumThemes.length,
            ),
          ),
        ),

        // Section: Free Themes Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'FREE THEMES',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: ScholarlyTheme.textMuted,
              ),
            ),
          ),
        ),

        // Grid for Free Themes
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final theme = freeThemes[index];
                final isSelected = theme.id == chessState.boardThemeId;
                return _buildThemeShopCard(context, theme, true, isSelected, storeState, storeNotifier, chessNotifier);
              },
              childCount: freeThemes.length,
            ),
          ),
        ),

        // Spacing at the bottom
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildThemeShopCard(
    BuildContext context,
    ChessTheme theme,
    bool isFree,
    bool isSelected,
    StoreState storeState,
    StoreNotifier storeNotifier,
    dynamic chessNotifier, {
    bool isFeatured = false,
  }) {
    final bool isDirectlyPurchased = storeState.purchasedBoardThemes.contains(theme.id);
    final int allowedDays = storeNotifier.getThemeAllowedDays(theme.id, storeState.subscriptionPlan ?? 'monthly');
    final int usedDays = storeNotifier.getThemeUsedDays(theme.id);
    final int remainingDays = (allowedDays - usedDays).clamp(0, 365);
    final bool hasSubscriptionAccess = storeState.isPremium && remainingDays > 0;

    final isOwned = isFree || isDirectlyPurchased || hasSubscriptionAccess;
    final highlightThemeId = ref.watch(storeHighlightThemeIdProvider);
    final isHighlighted = theme.id == highlightThemeId;

    final String badgeText;
    final Color badgeColor;

    if (isFree) {
      badgeText = 'FREE';
      badgeColor = Colors.green.withValues(alpha: 0.85);
    } else if (isDirectlyPurchased) {
      badgeText = 'OWNED';
      badgeColor = ScholarlyTheme.accentBlue.withValues(alpha: 0.85);
    } else if (hasSubscriptionAccess) {
      badgeText = '$remainingDays ${remainingDays == 1 ? "DAY" : "DAYS"} LEFT';
      badgeColor = const Color(0xFFFFD700).withValues(alpha: 0.9); // Gold for subscription access
    } else {
      badgeText = '\$0.99';
      badgeColor = Colors.black.withValues(alpha: 0.65);
    }

    return GestureDetector(
      onTap: () {
        if (isHighlighted) {
          ref.read(storeHighlightThemeIdProvider.notifier).state = null;
        }
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        showDialog(
          context: context,
          builder: (context) => ThemePreviewDialog(
            theme: theme,
            isFree: isFree,
            isOwned: isOwned,
            isSelected: isSelected,
            storeNotifier: storeNotifier,
            chessNotifier: chessNotifier,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ScholarlyTheme.accentBlue
                : Colors.white.withValues(alpha: 0.8),
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Preview box
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.lightSquare,
                              theme.darkSquare,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.65,
                            heightFactor: 0.65,
                            child: theme.buildPiece(
                              context,
                              'N',
                              true,
                              false,
                              0.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Status badge on preview
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Featured badge on preview
                    if (isFeatured)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ScholarlyTheme.accentGold,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: ScholarlyTheme.accentGold.withValues(alpha: 0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            'FEATURED',
                            style: GoogleFonts.outfit(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                    // Locked icon overlay if not owned
                    if (!isOwned)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),

              // Theme name
              Text(
                theme.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              // Action button
              SizedBox(
                height: 28,
                child: isOwned
                    ? Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7), // Premium light green-100
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5), // green-200 border
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 14), // green-700
                            const SizedBox(width: 4),
                            Text(
                              'OWNED',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D), // green-700
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    : BeatingWidget(
                        enabled: isHighlighted,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isHighlighted) {
                              ref.read(storeHighlightThemeIdProvider.notifier).state = null;
                            }
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                            
                            final authService = ref.read(authServiceProvider);
                            if (!authService.isPlayGamesUser) {
                              SignInPromptDialog.show(
                                context: context,
                                title: 'Sign In Required',
                                description: 'To buy premium board themes and sync them to your account, please sign in with Google.',
                                onSignInSuccess: () {
                                  _showThemePurchaseConfirmation(context, theme, storeNotifier, chessNotifier);
                                },
                              );
                            } else {
                              _showThemePurchaseConfirmation(context, theme, storeNotifier, chessNotifier);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'BUY \$0.99',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemePurchaseConfirmation(
    BuildContext context,
    ChessTheme theme,
    StoreNotifier storeNotifier,
    dynamic chessNotifier,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Confirm Purchase',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
          ),
          content: Text(
            'Would you like to buy the premium theme "${theme.name}" for \$0.99? It will be unlocked permanently.',
            style: GoogleFonts.inter(fontSize: 13, color: ScholarlyTheme.textPrimary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                storeNotifier.buyTheme(theme.id);
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Buy Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFreePlanCard(BuildContext context, StoreState storeState) {
    final isPremium = storeState.isPremium;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isPremium ? 0.35 : 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium ? Colors.white.withValues(alpha: 0.4) : ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
          width: isPremium ? 1.5 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Free Plan',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isPremium ? ScholarlyTheme.textMuted : ScholarlyTheme.textPrimary,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '\$0',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isPremium ? ScholarlyTheme.textMuted : Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      ' / forever',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ScholarlyTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Basic access with daily usage limits.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: ScholarlyTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            _buildFreeFeatureRow('1 Rated / Battleground game per 24h', 
                null, isPremium),
            _buildFreeFeatureRow('3 Arena games per 24h', 
                null, isPremium),
            _buildFreeFeatureRow('5 Academy Coaching prompts per 24h', 
                null, isPremium),
            _buildFreeFeatureRow('GM Chanakya: unlimited library search', 
                null, isPremium),
            _buildFreeFeatureRow('3 Puzzles per 24h', 
                null, isPremium),
            _buildFreeFeatureRow('1st Historical Cinema game per category unlocked', 
                null, isPremium),
            _buildFreeFeatureRow('Assignment page visible (calibration locked)', 
                null, isPremium),
            _buildFreeFeatureRow('5 Free board themes (Classic, Scholar, Wood, Calligraphy, Fairytale)', 
                null, isPremium),

            if (!isPremium) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15)),
                ),
                child: Center(
                  child: Text(
                    'CURRENT ACTIVE TIER',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: ScholarlyTheme.accentBlue,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildFreeFeatureRow(String text, String? remainingSuffix, bool isPremium) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: isPremium ? Colors.grey.shade400 : Colors.grey.shade600,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isPremium ? ScholarlyTheme.textMuted : ScholarlyTheme.textPrimary,
                ),
                children: [
                  TextSpan(text: text),
                  if (remainingSuffix != null) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: remainingSuffix,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.accentBlue,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidPlanCard(
    BuildContext context,
    SubscriptionPlan plan,
    bool isActive,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    final isYearly = plan.id == 'yearly';
    final titleColor = isYearly ? Colors.white : ScholarlyTheme.textPrimary;
    final descColor = isYearly ? Colors.white.withValues(alpha: 0.65) : ScholarlyTheme.textMuted;
    final featureTextColor = isYearly ? Colors.white.withValues(alpha: 0.9) : ScholarlyTheme.textPrimary;
    final Color planAccentColor = isYearly ? const Color(0xFFF59E0B) : plan.color;

    String buttonText = 'SUBSCRIBE';
    bool isUpgrade = false;
    bool isDowngrade = false;

    if (isActive) {
      buttonText = 'CURRENT PLAN';
    } else if (storeState.isPremium) {
      final currentPlanId = storeState.subscriptionPlan;
      if (currentPlanId == 'monthly') {
        if (plan.id == 'sixmonth' || plan.id == 'yearly') {
          buttonText = 'UPGRADE';
          isUpgrade = true;
        } else {
          buttonText = 'MANAGE';
          isDowngrade = true;
        }
      } else if (currentPlanId == 'sixmonth') {
        if (plan.id == 'yearly') {
          buttonText = 'UPGRADE';
          isUpgrade = true;
        } else {
          buttonText = 'MANAGE';
          isDowngrade = true;
        }
      } else if (currentPlanId == 'yearly') {
        buttonText = 'MANAGE';
        isDowngrade = true;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        gradient: isYearly
            ? const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isYearly ? null : Colors.white.withValues(alpha: isActive ? 0.85 : 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive
              ? planAccentColor
              : (isYearly
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.8)),
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? planAccentColor.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: isActive ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (plan.isPopular)
            Positioned(
              top: 0,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: planAccentColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  'POPULAR',
                  style: GoogleFonts.outfit(
                    color: isYearly ? const Color(0xFF0F172A) : Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: titleColor,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\$${plan.price.toStringAsFixed(2)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: planAccentColor,
                          ),
                        ),
                        Text(
                          ' / ${plan.period}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isYearly ? Colors.white60 : ScholarlyTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  plan.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: descColor,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: isYearly ? Colors.white.withValues(alpha: 0.15) : ScholarlyTheme.panelStroke),
                const SizedBox(height: 12),

                // Features list
                ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: planAccentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: featureTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isActive
                        ? null
                        : () {
                            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                            if (isDowngrade) {
                              storeNotifier.openSubscriptionManagement();
                              return;
                            }
                            
                            void action() {
                              if (isUpgrade) {
                                _showUpgradeConfirmation(context, plan, storeNotifier);
                              } else {
                                storeNotifier.buySubscription(plan.id);
                              }
                            }

                            final authService = ref.read(authServiceProvider);
                            if (!authService.isPlayGamesUser) {
                              SignInPromptDialog.show(
                                context: context,
                                title: 'Sign In Required',
                                description: 'To buy premium subscriptions and sync benefits across devices, please sign in with Google.',
                                onSignInSuccess: action,
                              );
                            } else {
                              action();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.grey : planAccentColor,
                      foregroundColor: isYearly ? const Color(0xFF0F172A) : Colors.white,
                      disabledBackgroundColor: isYearly
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      disabledForegroundColor: isYearly
                          ? Colors.white.withValues(alpha: 0.4)
                          : ScholarlyTheme.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isActive ? 0 : 2,
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Membership & Subscription Header Card
  Widget _buildSubscriptionCard(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    if (storeState.isPremium && storeState.subscriptionTill != null) {
      return const PremiumMembershipCard();
    }

    // Free Tier Layout
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: ScholarlyTheme.accentBlue, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'FREE ACCOUNT',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            'ACTIVE',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All AI opponents are unlocked & free.',
                      style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted),
                    ),
                    Text(
                      'Upgrade to unlock unlimited games, puzzles & coaching.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: ScholarlyTheme.accentBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ScholarlyTheme.panelStroke,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: ScholarlyTheme.accentBlue,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Account ID: ${storeState.subscriptionAccountId}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: ScholarlyTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: storeState.subscriptionAccountId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account ID copied to clipboard!'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      color: ScholarlyTheme.accentBlue,
                      size: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }



  // Cancel Dialog
  void _showCancelDialog(BuildContext context, StoreNotifier storeNotifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Cancel Subscription',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
          ),
          content: Text(
            'To cancel your subscription, you will be redirected to Google Play Store. Your premium benefits will remain active until the end of the current billing cycle.',
            style: GoogleFonts.inter(fontSize: 13, color: ScholarlyTheme.textPrimary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep Subscription', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                storeNotifier.openSubscriptionManagement();
                Navigator.pop(context);
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Yes, Manage', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showUpgradeConfirmation(
    BuildContext context,
    SubscriptionPlan plan,
    StoreNotifier storeNotifier,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Confirm Upgrade',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
          ),
          content: Text(
            'Would you like to upgrade to the "${plan.title}" for \$${plan.price}? Your current plan will end immediately, and Google Play will apply a prorated credit toward your new plan.',
            style: GoogleFonts.inter(fontSize: 13, color: ScholarlyTheme.textPrimary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                storeNotifier.buySubscription(plan.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Upgrade Now', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String title;
  final String description;
  final double price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final Color color;

  const SubscriptionPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
    this.isPopular = false,
    required this.color,
  });
}

const List<SubscriptionPlan> plans = [
  SubscriptionPlan(
    id: 'monthly',
    title: 'Monthly Plan',
    description: 'First 3 months 15% discount, thereafter \$4.99/mo.',
    price: 4.99,
    period: 'month',
    color: ScholarlyTheme.accentBlue,
    features: [
      'Unlimited Rated & Battleground games',
      'Unlimited Arena games',
      'Unlimited Academy chip prompt raises',
      'Unlimited Puzzles',
      'Full Assignment calibration tracking',
      'All board themes included',
      'Unlimited GM Chanakya Academy coaching',
      'Full Historical Cinema access',
      'Exclusive premium profile badge',
    ],
  ),
  SubscriptionPlan(
    id: 'sixmonth',
    title: '6-Month Plan',
    description: '3-day free trial, then \$21.99 every 6 months.',
    price: 21.99,
    period: '6 months',
    color: Colors.purple,
    features: [
      'Unlimited Rated & Battleground games',
      'Unlimited Arena games',
      'Unlimited Academy chip prompt raises',
      'Unlimited Puzzles',
      'Full Assignment calibration tracking',
      'All board themes included',
      'Unlimited GM Chanakya Academy coaching',
      'Full Historical Cinema access',
      'Exclusive premium profile badge',
      'Save 26% vs Monthly rate',
    ],
  ),
  SubscriptionPlan(
    id: 'yearly',
    title: 'Yearly Plan',
    description: '7-day free trial, then \$39.99/yr.',
    price: 39.99,
    period: 'year',
    isPopular: true,
    color: Color(0xFFB45309), // Amber 700
    features: [
      'Unlimited Rated & Battleground games',
      'Unlimited Arena games',
      'Unlimited Academy chip prompt raises',
      'Unlimited Puzzles',
      'Full Assignment calibration tracking',
      'All board themes included',
      'Unlimited GM Chanakya Academy coaching',
      'Full Historical Cinema access',
      'Exclusive premium profile badge',
      'Save 33% vs Monthly rate',
    ],
  ),
];

class BeatingWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const BeatingWidget({super.key, required this.child, this.enabled = true});

  @override
  State<BeatingWidget> createState() => _BeatingWidgetState();
}

class _BeatingWidgetState extends State<BeatingWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.enabled) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BeatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ScaleTransition(
      scale: _animation,
      child: widget.child,
    );
  }
}
