import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../application/chess_provider.dart';
import '../../application/store_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import '../widgets/ambient_scaffold.dart';

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

    return AmbientScaffold(
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
                          'KINGSLAYER PREMIUM',
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
                          'Supercharge your learning with Cloud AI',
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

            // Subscription Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSubscriptionCard(context, storeState, storeNotifier),
            ),

            const SizedBox(height: 16),

            // Plans Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CHOOSE YOUR PLAN',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Plans List / Scroll
            Expanded(
              child: _buildPlansList(context, storeState, storeNotifier),
            ),
          ],
        ),
      ),
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
      final planName = (storeState.subscriptionPlan ?? 'Premium').toUpperCase();
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
                          fontSize: 15,
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
                    '✓ 50 Cloud AI prompts/day unlocked',
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
                  'All 20 AI opponents are fully unlocked & free.',
                  style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted),
                ),
                Text(
                  'Upgrade to access Cloud AI coaching prompts.',
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

  // Plans List Layout
  Widget _buildPlansList(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final isActive = storeState.isPremium && storeState.subscriptionPlan == plan.id;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                              '\$${plan.price.toStringAsFixed(2)}',
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
      },
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
                    Column(
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
                          'Includes 50 Cloud AI prompts/day',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\$${plan.price.toStringAsFixed(2)}',
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
                '💡 This is a simulated store page. Clicking "Pay" will charge \$0.00 and immediately grant full Kingslayer Premium status for the selected duration.',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.amber[800],
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
                  'PAY \$${plan.price.toStringAsFixed(2)}',
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
    description: 'Perfect for casual learners.',
    price: 4.99,
    period: 'month',
    color: ScholarlyTheme.accentBlue,
    features: [
      '50 Cloud AI prompts/day in Academy',
      'All 20 AI opponents unlocked',
      'Vector theme customizations',
      'Extended search depth limit',
    ],
  ),
  SubscriptionPlan(
    id: 'quarterly',
    title: 'Quarterly Plan',
    description: 'Our most popular choice.',
    price: 12.99,
    period: '3 months',
    isPopular: true,
    color: Colors.purple,
    features: [
      '50 Cloud AI prompts/day in Academy',
      'All 20 AI opponents unlocked',
      'Vector theme customizations',
      'Extended search depth limit',
      'Save 13% vs Monthly rate',
    ],
  ),
  SubscriptionPlan(
    id: 'yearly',
    title: 'Yearly Plan',
    description: 'Best value for serious scholars.',
    price: 39.99,
    period: 'year',
    color: Color(0xFFB45309), // Amber 700
    features: [
      '50 Cloud AI prompts/day in Academy',
      'All 20 AI opponents unlocked',
      'Vector theme customizations',
      'Extended search depth limit',
      'Save 33% vs Monthly rate',
      'Exclusive premium profile badge',
    ],
  ),
];
