import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../scholarly_theme.dart';
import 'ambient_flow_backdrop.dart';
import '../../application/chess_provider.dart';
import '../../application/onboarding_provider.dart';
import '../../services/chess_sound_service.dart';

class NotificationPromptPage extends ConsumerStatefulWidget {
  /// When provided the page operates as a standalone full-screen route
  /// (e.g. launched from the splash screen). After the user taps either
  /// "Enable Alerts" or "Later" this callback is invoked so the caller
  /// can push the next route. When null the page operates as an overlay
  /// inside MobileNavigationShell and simply dismisses itself via the
  /// showNotificationPromptProvider state.
  final void Function(BuildContext)? onDismissed;

  const NotificationPromptPage({super.key, this.onDismissed});

  @override
  ConsumerState<NotificationPromptPage> createState() => _NotificationPromptPageState();
}

class _NotificationPromptPageState extends ConsumerState<NotificationPromptPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleEnableNotifications() async {
    debugPrint('--- _handleEnableNotifications: started ---');
    if (_isProcessing) {
      debugPrint('--- _handleEnableNotifications: already processing, return ---');
      return;
    }
    setState(() => _isProcessing = true);

    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);

    bool granted = false;
    try {
      if (Platform.isAndroid) {
        debugPrint('--- _handleEnableNotifications: checking notification status ---');
        final status = await Permission.notification.status;
        debugPrint('--- _handleEnableNotifications: notification status is $status ---');
        if (status.isGranted) {
          granted = true;
        } else if (status.isPermanentlyDenied) {
          // Permission was permanently denied — silently dismiss the prompt,
          // no dialog. The user can enable it later from device settings.
          if (mounted) {
            await OnboardingService(ref).dismissNotificationPrompt();
            if (mounted) widget.onDismissed?.call(context);
          } else {
            _isProcessing = false;
          }
          return;
        } else {
          debugPrint('--- _handleEnableNotifications: requesting permission ---');
          final result = await Permission.notification.request();
          debugPrint('--- _handleEnableNotifications: permission request result is $result ---');
          if (result.isGranted) {
            granted = true;
          }
        }
      } else {
        // Non-Android platforms (e.g. Windows/macOS)
        granted = true;
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }

    debugPrint('--- _handleEnableNotifications: granted = $granted ---');
    if (granted) {
      await ref.read(chessProvider.notifier).toggleNotifications(true);
    }

    if (mounted) {
      debugPrint('--- _handleEnableNotifications: dismissing notification prompt ---');
      await OnboardingService(ref).dismissNotificationPrompt();
      if (mounted) {
        debugPrint('--- _handleEnableNotifications: invoking onDismissed callback ---');
        widget.onDismissed?.call(context);
      }
    } else {
      debugPrint('--- _handleEnableNotifications: not mounted, setting processing false ---');
      _isProcessing = false;
    }
    debugPrint('--- _handleEnableNotifications: finished ---');
  }

  Future<void> _handleSkip() async {
    if (_isProcessing) return;
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
    await OnboardingService(ref).dismissNotificationPrompt();
    if (mounted) {
      widget.onDismissed?.call(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AmbientFlowBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildGlowCard(),
                  const Spacer(),
                  _buildActions(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: ScholarlyTheme.glassPanelDecoration(radius: 24).copyWith(
            color: Colors.white.withValues(alpha: 0.94),
            border: Border.all(
              color: ScholarlyTheme.accentBlue.withValues(
                alpha: 0.20 + 0.15 * _pulseController.value,
              ),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: ScholarlyTheme.accentBlue.withValues(
                  alpha: 0.04 + 0.04 * _pulseController.value,
                ),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnimatedBell(),
              const SizedBox(height: 14),
              PremiumGradientText(
                'NEVER MISS AN ASSIGNMENT',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              _buildBulletPoints(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBulletPoints() {
    const bullets = [
      (
        icon: Icons.menu_book_rounded,
        color: Color(0xFF2979FF),
        label: 'Daily training tasks',
        sub: 'assigned by GM Chanakya',
      ),
      (
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFFB300),
        label: 'Streak protection',
        sub: 'miss a day, lose your rank',
      ),
      (
        icon: Icons.shield_rounded,
        color: Color(0xFF7C4DFF),
        label: 'Class reminders',
        sub: 'so you never miss the daily rhythm!',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets.map((b) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: b.color.withValues(alpha: 0.12),
                ),
                child: Icon(b.icon, color: b.color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: b.label,
                        style: GoogleFonts.inter(
                          color: b.color,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' — ${b.sub}',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAnimatedBell() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glowing pulse rings
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ScholarlyTheme.accentBlue.withValues(
                alpha: 0.05 + 0.05 * _pulseController.value,
              ),
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ScholarlyTheme.accentBlue.withValues(
                alpha: 0.10 + 0.05 * _pulseController.value,
              ),
            ),
          ),
          // Bell container with rotation/tilt and scale pulse
          Transform.scale(
            scale: 1.0 + 0.05 * _pulseController.value,
            child: Transform.rotate(
              angle: 0.08 * (0.5 - _pulseController.value),
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ScholarlyTheme.accentBlueSoft,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 28,
                  color: ScholarlyTheme.accentBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleEnableNotifications,
            style: ElevatedButton.styleFrom(
              backgroundColor: ScholarlyTheme.accentBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'ENABLE ALERTS',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isProcessing ? null : _handleSkip,
          style: TextButton.styleFrom(
            foregroundColor: ScholarlyTheme.textMuted,
          ),
          child: Text(
            'LATER',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}
