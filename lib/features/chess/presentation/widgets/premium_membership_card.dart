import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../application/chess_provider.dart';
import '../../application/store_provider.dart';
import '../../services/chess_sound_service.dart';
import 'upgrade_plan_sheet.dart';

class PremiumMembershipCard extends ConsumerWidget {
  const PremiumMembershipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeState = ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);
    final dateFormat = DateFormat('MMM d, yyyy');

    if (!storeState.isPremium || storeState.subscriptionTill == null) {
      return const SizedBox.shrink();
    }

    final rawPlan = storeState.subscriptionPlan ?? 'Premium';
    final planName = (rawPlan == 'sixmonth' ? '6-Month' : rawPlan).toUpperCase();
    final expiryStr = dateFormat.format(storeState.subscriptionTill!);
    final daysLeft = storeState.subscriptionTill!.difference(DateTime.now()).inDays.clamp(0, 365);
    final accountId = storeState.subscriptionAccountId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.65), // Bright premium gold
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Crown / Diamond Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD700), // Pure Gold
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // Plan Name & Active Badge in one single line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  '$planName SUBSCRIBER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'ACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Expiry and remaining days
          Text(
            'Renews: $expiryStr ($daysLeft days left)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFFFD700).withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (accountId != null && accountId.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: Color(0xFFFFD700),
                    size: 15,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Account ID: $accountId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          const Divider(
            color: Color(0xFF334155),
            thickness: 1,
            indent: 20,
            endIndent: 20,
          ),
          const SizedBox(height: 12),

          // Perks row
          Column(
            children: [
              _buildPerkRow('✓ Premium themes with limited play days'),
              const SizedBox(height: 6),
              _buildPerkRow('✓ Full game engine, analytics & academy access'),
              const SizedBox(height: 6),
              _buildPerkRow('✓ Unlimited rated & arena matchmaking'),
            ],
          ),
          const SizedBox(height: 24),

          // UPGRADE PLAN button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                if (rawPlan == 'yearly') {
                  storeNotifier.openSubscriptionManagement();
                } else {
                  UpgradePlanSheet.show(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD700),
                foregroundColor: const Color(0xFF0F172A),
                elevation: 2,
                shadowColor: const Color(0xFFFFD700).withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                rawPlan == 'yearly' ? 'MANAGE SUBSCRIPTION' : 'UPGRADE PLAN',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerkRow(String perk) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            perk,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    );
  }
}
