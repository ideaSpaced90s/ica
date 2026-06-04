import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../application/chess_provider.dart';
import '../../application/store_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import '../../domain/models/ai_avatar.dart';
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

    final numberFormat = NumberFormat.decimalPattern();

    return AmbientScaffold(
      blob1Color: const Color(0xFFFEF3C7), // Warm golden
      blob2Color: const Color(0xFFDBEAFE), // Soft blue
      blob3Color: const Color(0xFFF3E8FF), // Soft purple
      body: SafeArea(
        child: Column(
          children: [
            // Top Wallet & Refill Bar
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'Unlock premium personas',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildWallet(context, storeState, storeNotifier, numberFormat),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Subscription Status Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSubscriptionCard(context, storeState, storeNotifier, numberFormat),
            ),

            const SizedBox(height: 12),

            // Tabs Content
            Expanded(
              child: _buildAvatarsTab(context, storeState, storeNotifier),
            ),
          ],
        ),
      ),
    );
  }

  // Wallet indicator with simulated free refill
  Widget _buildWallet(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
    NumberFormat format,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.08),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 6),
          Text(
            format.format(storeState.goldBalance),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFB45309), // Amber 700
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              storeNotifier.addGold(500);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('💰 Refilled 500 simulated Gold coins!'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: ScholarlyTheme.accentBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: ScholarlyTheme.accentBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 12),
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
    NumberFormat format,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    if (storeState.isPremium && storeState.subscriptionTill != null) {
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
          borderRadius: BorderRadius.circular(20),
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
                        'PREMIUM MEMBER',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
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
                    'Free since: ${dateFormat.format(storeState.joinedFreeDate)}',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.white60),
                  ),
                  Text(
                    'Renews till: ${dateFormat.format(storeState.subscriptionTill!)} ($daysLeft days left)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.cyanAccent.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _purchaseSubscription(context, storeState, storeNotifier),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: Text(
                'EXTEND',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
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
        borderRadius: BorderRadius.circular(20),
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
                  'Member since: ${dateFormat.format(storeState.joinedFreeDate)}',
                  style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted),
                ),
                Text(
                  'Unlock unlimited access to all AI opponents',
                  style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.accentBlue, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _purchaseSubscription(context, storeState, storeNotifier),
            style: ElevatedButton.styleFrom(
              backgroundColor: ScholarlyTheme.accentBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 12),
                const SizedBox(width: 4),
                Text(
                  'GO PRO',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _purchaseSubscription(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    if (storeState.goldBalance < 500) {
      _showInsufficientFundsDialog(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Go Premium',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock ultimate access to Kingslayer Chess Premium:',
                style: GoogleFonts.inter(fontSize: 13, color: ScholarlyTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              _buildBulletPoint('Full 30-day Premium membership access'),
              _buildBulletPoint('Unlock vector theme customizations'),
              _buildBulletPoint('Extended depth limits on AI engines'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Price:', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text('500 Gold', style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                final success = storeNotifier.buyOrRenewPremium();
                Navigator.pop(context);
                if (success) {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('⚡ Account upgraded to Premium successfully!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
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

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12, color: ScholarlyTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showInsufficientFundsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Insufficient Gold',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.redAccent),
        ),
        content: Text(
          'You need more Gold to purchase this item. Tap the "+" button next to your wallet to refill simulated Gold for testing!',
          style: GoogleFonts.inter(fontSize: 13, color: ScholarlyTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
          ),
        ],
      ),
    );
  }



  // --- AVATARS TAB ---
  Widget _buildAvatarsTab(
    BuildContext context,
    StoreState storeState,
    StoreNotifier storeNotifier,
  ) {
    final avatars = AiAvatar.avatars;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.65, // Taller cards to fit avatar details
        ),
        itemCount: avatars.length,
        itemBuilder: (context, index) {
          final avatar = avatars[index];
          final isFree = avatar.id == 'avatar_0' || avatar.id == 'avatar_6';
          final isUnlocked = storeNotifier.isAvatarUnlocked(avatar.id);
          final expiry = storeState.purchasedAvatars[avatar.id];

          return StoreAvatarCard(
            avatar: avatar,
            isFree: isFree,
            isUnlocked: isUnlocked,
            expiry: expiry,
            onBuyOrRenew: () {
              if (storeState.goldBalance < 150) {
                _showInsufficientFundsDialog(context);
                return;
              }
              final success = storeNotifier.purchaseOrRenewAvatar(avatar.id, 150);
              if (success) {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🤖 Avatar ${avatar.name} unlocked for selection!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}



// Flippable Card Widget adapted for Store AI opponent avatars
class StoreAvatarCard extends StatefulWidget {
  final AiAvatar avatar;
  final bool isFree;
  final bool isUnlocked;
  final DateTime? expiry;
  final VoidCallback onBuyOrRenew;

  const StoreAvatarCard({
    super.key,
    required this.avatar,
    required this.isFree,
    required this.isUnlocked,
    this.expiry,
    required this.onBuyOrRenew,
  });

  @override
  State<StoreAvatarCard> createState() => _StoreAvatarCardState();
}

class _StoreAvatarCardState extends State<StoreAvatarCard> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    final container = ProviderScope.containerOf(context, listen: false);
    container.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, child) {
          final angle = _flipController.value * math.pi;
          final isFront = angle < math.pi / 2;

          Widget cardContent = isFront
              ? _buildFront()
              : Transform(
                  transform: Matrix4.identity()..rotateY(math.pi),
                  alignment: Alignment.center,
                  child: _buildBack(),
                );

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            alignment: Alignment.center,
            child: cardContent,
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isUnlocked ? widget.avatar.color : Colors.white.withValues(alpha: 0.6),
          width: widget.isUnlocked ? 2.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.avatar.color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Portrait
            Image.asset(
              widget.avatar.imagePath,
              fit: BoxFit.cover,
            ),

            // Locked Translucent Overlay
            if (!widget.isUnlocked)
              Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: Align(
                  alignment: const Alignment(0, -0.2),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30),
                    ),
                    child: const Icon(Icons.lock_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),

            // Top Status Badge Overlay
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.avatar.fideRatingRange,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.jetBrainsMono(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: _buildStatusBadge(),
                  ),
                ],
              ),
            ),

            // Bottom Name / Buy Action Banner
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.avatar.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(widget.avatar.icon, color: widget.avatar.color, size: 14),
                      ],
                    ),
                    Text(
                      widget.avatar.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    String text = 'LOCKED';
    Color color = Colors.redAccent;
    
    if (widget.isFree) {
      text = 'FREE';
      color = Colors.green;
    } else if (widget.isUnlocked) {
      if (widget.expiry != null) {
        final diff = widget.expiry!.difference(DateTime.now());
        text = '${diff.inDays}d LEFT';
      } else {
        text = 'UNLOCKED';
      }
      color = ScholarlyTheme.accentBlue;
    } else if (widget.expiry != null && widget.expiry!.isBefore(DateTime.now())) {
      text = 'EXPIRED';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 7.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    if (widget.isFree) {
      return Text(
        'Tap to see details',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 8, color: Colors.white38, fontStyle: FontStyle.italic),
      );
    }

    final String label = widget.isUnlocked ? 'RENEW (150 G)' : 'BUY FOR 150 GOLD';
    final Color buttonColor = widget.isUnlocked ? Colors.green : ScholarlyTheme.accentBlue;

    return ElevatedButton(
      onPressed: () {
        // Prevent click from flipping card
        widget.onBuyOrRenew();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.avatar.color,
          width: widget.isUnlocked ? 2.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: AssetImage(widget.avatar.imagePath),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.avatar.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),

          Text(
            'SPECIFICATIONS',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: widget.avatar.color,
            ),
          ),
          const SizedBox(height: 4),

          _buildSpecLine('FIDE Rating', widget.avatar.fideRatingRange),
          _buildSpecLine('Skill Lvl', '${widget.avatar.skillLevel}/20'),
          _buildSpecLine('Search Depth', '${widget.avatar.depth} moves'),

          const SizedBox(height: 8),
          Text(
            'PLAYING STYLE',
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: widget.avatar.color,
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                widget.avatar.playingStyle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  height: 1.3,
                  color: ScholarlyTheme.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Tap to flip',
              style: GoogleFonts.inter(fontSize: 8, color: ScholarlyTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 9, color: ScholarlyTheme.textMuted),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
