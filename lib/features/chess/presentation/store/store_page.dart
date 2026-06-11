import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../application/chess_provider.dart';
import '../../application/store_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import '../widgets/ambient_scaffold.dart';
import '../arena/themes/theme_registry.dart';
import '../widgets/theme_preview_dialog.dart';

class StorePage extends ConsumerStatefulWidget {
  const StorePage({super.key});

  @override
  ConsumerState<StorePage> createState() => _StorePageState();
}

class _StorePageState extends ConsumerState<StorePage> {
  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);

    // Refresh checking on enter
    WidgetsBinding.instance.addPostFrameCallback((_) {
      storeNotifier.verifyActiveSelections();
    });

    return DefaultTabController(
      length: 2,
      child: AmbientScaffold(
        blob1Color: const Color(0xFFE0F2FE), // Soft cyan/blue
        blob2Color: const Color(0xFFF3E8FF), // Soft purple
        blob3Color: const Color(0xFFFEF08A), // Warm yellow/gold
        body: SafeArea(
          child: Column(
            children: [
              // Top App Bar/Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KINGSLAYER STORE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Subscriptions and Chessboard Customizations',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ScholarlyTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

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
                  children: [
                    _buildPlansTab(context, storeState, storeNotifier),
                    _buildThemesTab(context, storeState, storeNotifier),
                  ],
                ),
              ),
            ],
          ),
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
      ],
    );
  }

  Widget _buildFreePlanCard(BuildContext context, StoreState storeState) {
    final isPremium = storeState.isPremium;
    final usage = storeState.freeTierUsage;

    // Remaining counts
    final ratedRemaining = (1 - usage.ratedGamesPlayed).clamp(0, 1);
    final arenaRemaining = (3 - usage.arenaGamesPlayed).clamp(0, 3);
    final promptsRemaining = (5 - usage.chipPromptsUsed).clamp(0, 5);
    final puzzlesRemaining = (3 - usage.puzzlesSolved).clamp(0, 3);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isPremium ? 0.35 : 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade400,
          width: isPremium ? 1.5 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
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
                      '₹0',
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

            // Daily limits and features with their remaining counters (if not premium)
            _buildFreeFeatureRow('1 Rated / Battleground game per 24h', 
                isPremium ? null : '($ratedRemaining left)', isPremium),
            _buildFreeFeatureRow('3 Arena games per 24h', 
                isPremium ? null : '($arenaRemaining left)', isPremium),
            _buildFreeFeatureRow('5 Chip prompts in Academy per 24h', 
                isPremium ? null : '($promptsRemaining left)', isPremium),
            _buildFreeFeatureRow('GM Chanakya: unlimited library search', 
                null, isPremium),
            _buildFreeFeatureRow('3 Puzzles per 24h', 
                isPremium ? null : '($puzzlesRemaining left)', isPremium),
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
                  color: Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'CURRENT BASIC TIER',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: Colors.grey.shade700,
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
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isActive ? 0.85 : 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isActive ? plan.color : Colors.white.withValues(alpha: 0.8),
          width: isActive ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isActive ? 0.06 : 0.02),
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
                  color: plan.color,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  'POPULAR',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
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
                        color: ScholarlyTheme.textPrimary,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '₹${plan.price.toStringAsFixed(0)}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: plan.color,
                          ),
                        ),
                        Text(
                          ' / ${plan.period}',
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
                  plan.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Features list
                ...plan.features.map((feature) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: plan.color,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: ScholarlyTheme.textPrimary,
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
                            _showSimulationCheckout(context, plan, storeNotifier);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.grey : plan.color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withValues(alpha: 0.1),
                      disabledForegroundColor: ScholarlyTheme.textMuted,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isActive ? 0 : 2,
                    ),
                    child: Text(
                      isActive ? 'CURRENT PLAN' : 'SUBSCRIBE',
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

  Widget _buildThemesTab(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    final chessState = ref.watch(chessProvider);
    final chessNotifier = ref.read(chessProvider.notifier);

    // Grouping themes
    final freeThemeIds = {'classic', 'scholar', 'vector_wood', 'theme3', 'sprite_fairytale'};

    final freeThemes = ThemeRegistry.allThemes.where((t) => freeThemeIds.contains(t.id)).toList();
    final premiumThemes = ThemeRegistry.allThemes.where((t) => !freeThemeIds.contains(t.id)).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Intro Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15)),
              ),
              child: Text(
                '🎨 Free themes are always available. Premium themes can be purchased individually or unlocked entirely with any Premium Subscription plan!',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: ScholarlyTheme.textPrimary,
                  height: 1.4,
                ),
              ),
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
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

        // Section: Premium Themes Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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

        // Grid for Premium Themes
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final theme = premiumThemes[index];
                final isSelected = theme.id == chessState.boardThemeId;
                return _buildThemeShopCard(context, theme, false, isSelected, storeState, storeNotifier, chessNotifier);
              },
              childCount: premiumThemes.length,
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
    dynamic theme, // ChessTheme
    bool isFree,
    bool isSelected,
    StoreState storeState,
    StoreNotifier storeNotifier,
    dynamic chessNotifier,
  ) {
    final isOwned = isFree || storeState.isPremium || storeState.purchasedBoardThemes.contains(theme.id);

    return GestureDetector(
      onTap: () {
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
                          color: isFree
                              ? Colors.green.withValues(alpha: 0.85)
                              : (isOwned
                                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.85)
                                  : Colors.black.withValues(alpha: 0.65)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isFree ? 'FREE' : (isOwned ? 'OWNED' : '₹49'),
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                    if (isSelected) {
                      // Do nothing
                    } else if (isOwned) {
                      chessNotifier.setBoardTheme(theme.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎨 Applied ${theme.name} theme!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: ScholarlyTheme.accentBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    } else {
                      _showThemePurchaseConfirmation(context, theme, storeNotifier, chessNotifier);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? Colors.grey.shade400
                        : (isOwned ? ScholarlyTheme.accentBlue : Colors.amber.shade700),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isSelected ? 'APPLIED' : (isOwned ? 'APPLY' : 'BUY ₹49'),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
    dynamic theme,
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
            'Would you like to buy the premium theme "${theme.name}" for ₹49 (Simulated)? It will be unlocked permanently.',
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
                storeNotifier.purchaseBoardTheme(theme.id);
                chessNotifier.setBoardTheme(theme.id);
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚡ Purchased and applied ${theme.name} theme!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
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

  // Membership & Subscription Header Card
  Widget _buildSubscriptionCard(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');

    if (storeState.isPremium && storeState.subscriptionTill != null) {
      final rawPlan = storeState.subscriptionPlan ?? 'Premium';
      final planName = (rawPlan == 'sixmonth' ? '6-Month' : rawPlan).toUpperCase();
      final expiryStr = dateFormat.format(storeState.subscriptionTill!);
      final daysLeft = storeState.subscriptionTill!.difference(DateTime.now()).inDays;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Sleek Dark Steel
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.cyan.withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_rounded, color: Colors.cyan, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        '$planName SUBSCRIBER',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.cyan,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.greenAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Renews till: $expiryStr ($daysLeft days left)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '✓ All app features and themes unlocked',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                _showCancelDialog(context, storeNotifier);
              },
              child: Text(
                'CANCEL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ),
      );
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
      child: Row(
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
                Text(
                  'FREE ACCOUNT',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
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
    );
  }

  // Simulation Checkout Bottom Sheet
  void _showSimulationCheckout(
    BuildContext context,
    SubscriptionPlan plan,
    StoreNotifier storeNotifier,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Secure Simulation Pay',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: plan.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: plan.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.title,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: ScholarlyTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Includes all features & premium themes',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ScholarlyTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${plan.price.toStringAsFixed(0)}',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: plan.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mock Card Details
              Text(
                'CREDIT CARD DETAILS (SIMULATED)',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: ScholarlyTheme.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.credit_card_rounded, color: ScholarlyTheme.textMuted, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          '••••  ••••  ••••  4242',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '12/29',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 14,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              Text(
                '💡 This is a simulated store page. Clicking "Pay" will charge ₹0.00 and immediately grant full Kingslayer Premium status for the selected duration.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.amber[850],
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  storeNotifier.simulateUSDSubscription(plan.id);
                  Navigator.pop(context);
                  
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('⚡ Subscribed to ${plan.title} successfully!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: plan.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'PAY ₹${plan.price.toStringAsFixed(0)}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
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
            'Are you sure you want to cancel your simulated subscription? You will lose access to premium AI coaching limits immediately.',
            style: GoogleFonts.inter(fontSize: 13, color: ScholarlyTheme.textPrimary, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Keep Subscription', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                storeNotifier.cancelSubscription();
                Navigator.pop(context);
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Subscription cancelled successfully.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Yes, Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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
    description: 'Perfect for short-term learners.',
    price: 199.00,
    period: 'month',
    color: ScholarlyTheme.accentBlue,
    features: [
      'Unlimited Rated & Battleground games',
      'Unlimited Arena games',
      'Unlimited Academy chip prompt raises',
      'Unlimited Puzzles',
      'Full Assignment calibration tracking',
      'All board themes included',
      '50 Cloud AI prompts/day',
      'Exclusive premium profile badge',
    ],
  ),
  SubscriptionPlan(
    id: 'sixmonth',
    title: '6-Month Plan',
    description: 'Great balance of value & commitment.',
    price: 999.00,
    period: '6 months',
    color: Colors.purple,
    features: [
      'Unlimited Rated & Battleground games',
      'Unlimited Arena games',
      'Unlimited Academy chip prompt raises',
      'Unlimited Puzzles',
      'Full Assignment calibration tracking',
      'All board themes included',
      '50 Cloud AI prompts/day',
      'Exclusive premium profile badge',
      'Save 16% vs Monthly rate',
    ],
  ),
  SubscriptionPlan(
    id: 'yearly',
    title: 'Yearly Plan',
    description: 'Best value for serious scholars.',
    price: 1699.00,
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
      '50 Cloud AI prompts/day',
      'Exclusive premium profile badge',
      'Save 29% vs Monthly rate',
    ],
  ),
];
