import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/chess_provider.dart';
import '../../application/store_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';

class UpgradePlanSheet extends ConsumerWidget {
  const UpgradePlanSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const UpgradePlanSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeState = ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);
    final soundService = ref.read(chessSoundServiceProvider);

    final currentPlan = storeState.subscriptionPlan ?? 'monthly';
    
    // Determine which upgrades are available
    final List<_UpgradeOption> options = [];
    if (currentPlan == 'monthly') {
      options.add(const _UpgradeOption(
        id: 'sixmonth',
        title: '6-Month Plan',
        price: 21.99,
        period: '6 months',
        savingText: 'SAVE 26%',
        isPopular: false,
        color: Colors.purple,
      ));
      options.add(const _UpgradeOption(
        id: 'yearly',
        title: 'Yearly Plan',
        price: 39.99,
        period: 'year',
        savingText: 'SAVE 33%',
        isPopular: true,
        color: Color(0xFFF59E0B), // Gold/Amber
      ));
    } else if (currentPlan == 'sixmonth') {
      options.add(const _UpgradeOption(
        id: 'yearly',
        title: 'Yearly Plan',
        price: 39.99,
        period: 'year',
        savingText: 'SAVE 33%',
        isPopular: true,
        color: Color(0xFFF59E0B),
      ));
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD700),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'UPGRADE YOUR PLAN',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              Text(
                'Switch to a longer plan to save on your subscription.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: ScholarlyTheme.textMuted,
                ),
              ),
              const SizedBox(height: 24),

              if (options.isEmpty) ...[
                const SizedBox(height: 16),
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'You are already on the highest tier plan!',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // Display options
                ...options.map((opt) {
                  return _buildOptionCard(
                    context: context,
                    option: opt,
                    soundService: soundService,
                    storeNotifier: storeNotifier,
                    currentPlan: currentPlan,
                  );
                }),
              ],

              const SizedBox(height: 12),
              
              // Informative disclaimer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: ScholarlyTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Google Play automatically handles proration. You will only pay the difference for your remaining billing cycle.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: ScholarlyTheme.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required _UpgradeOption option,
    required ChessSoundService soundService,
    required StoreNotifier storeNotifier,
    required String currentPlan,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: option.isPopular ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: option.isPopular ? option.color : Colors.black12,
          width: option.isPopular ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (option.isPopular)
            Positioned(
              top: 0,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: option.color,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Text(
                  'BEST VALUE',
                  style: GoogleFonts.outfit(
                    color: Colors.black,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            option.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: option.isPopular ? Colors.white : ScholarlyTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: option.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              option.savingText,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: option.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '\$${option.price}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: option.color,
                            ),
                          ),
                          Text(
                            ' / ${option.period}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: option.isPopular ? Colors.white70 : ScholarlyTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    soundService.playSfx(SoundEffect.uiClick);
                    _showConfirmationDialog(
                      context: context,
                      option: option,
                      storeNotifier: storeNotifier,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: option.color,
                    foregroundColor: option.isPopular ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'UPGRADE',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
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

  void _showConfirmationDialog({
    required BuildContext context,
    required _UpgradeOption option,
    required StoreNotifier storeNotifier,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Confirm Upgrade',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          content: Text(
            'Do you want to upgrade to the "${option.title}" for \$${option.price}? Your current subscription plan will be terminated immediately, and Google Play will apply a prorated credit toward your new plan.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: ScholarlyTheme.textPrimary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close sheet
                storeNotifier.buySubscription(option.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: option.color,
                foregroundColor: option.isPopular ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UpgradeOption {
  final String id;
  final String title;
  final double price;
  final String period;
  final String savingText;
  final bool isPopular;
  final Color color;

  const _UpgradeOption({
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    required this.savingText,
    required this.isPopular,
    required this.color,
  });
}
