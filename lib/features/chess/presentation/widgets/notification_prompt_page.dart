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
  const NotificationPromptPage({super.key});

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
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);

    bool granted = false;
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isGranted) {
        granted = true;
      } else {
        final result = await Permission.notification.request();
        if (result.isGranted) {
          granted = true;
        } else if (status.isPermanentlyDenied) {
          if (mounted) {
            final openSettings = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: ScholarlyTheme.panelBase,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1),
                ),
                title: Text(
                  'Notifications Needed',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                content: Text(
                  'To receive chess lessons briefings and protection alerts for your training streak, please enable notifications in your device settings.',
                  style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('CANCEL', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue),
                    child: Text('OPEN SETTINGS', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
            if (openSettings == true) {
              await openAppSettings();
            }
          }
        }
      }
    } else {
      // Non-Android platforms (e.g. Windows/macOS)
      granted = true;
    }

    if (granted) {
      await ref.read(chessProvider.notifier).toggleNotifications(true);
    }

    if (mounted) {
      await OnboardingService(ref).dismissNotificationPrompt();
    }
  }

  Future<void> _handleSkip() async {
    if (_isProcessing) return;
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
    await OnboardingService(ref).dismissNotificationPrompt();
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAnimatedBell(),
              const SizedBox(height: 24),
              PremiumGradientText(
                'NEVER MISS A TACTIC',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'To build a strong chess foundation, consistency is key. We send gentle reminders for your daily custom training tasks, tournament alerts, and streak protection to keep your momentum alive. Enable notifications to keep your progress on track.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedBell() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background soft glowing pulse rings
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ScholarlyTheme.accentBlue.withValues(
                alpha: 0.05 + 0.05 * _pulseController.value,
              ),
            ),
          ),
          Container(
            width: 64,
            height: 64,
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
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ScholarlyTheme.accentBlueSoft,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  size: 36,
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
