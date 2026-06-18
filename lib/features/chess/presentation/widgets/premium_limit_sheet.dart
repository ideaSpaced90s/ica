import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../scholarly_theme.dart';
import '../mobile_navigation_shell.dart';
import '../../services/chess_sound_service.dart';
import '../../application/chess_provider.dart';

class PremiumLimitSheet extends StatefulWidget {
  final String title;
  final String limitDescription;

  const PremiumLimitSheet({
    super.key,
    required this.title,
    required this.limitDescription,
  });

  static void show(BuildContext context, String title, String limitDescription) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (_) => PremiumLimitSheet(
        title: title,
        limitDescription: limitDescription,
      ),
    );
  }

  @override
  State<PremiumLimitSheet> createState() => _PremiumLimitSheetState();
}

class _PremiumLimitSheetState extends State<PremiumLimitSheet> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
        });
      }
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timeLeft = midnight.difference(now);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock_clock_rounded, color: Colors.amber.shade800, size: 42),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    widget.limitDescription,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: ScholarlyTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Countdown timer box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'DAILY COUNTERS RESET IN',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDuration(_timeLeft),
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.textPrimary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Buttons
                  ElevatedButton(
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      Navigator.pop(context); // Close bottom sheet
                      ref.read(mobileNavIndexProvider.notifier).state = 11; // Switch to Store tab
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScholarlyTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'UPGRADE TO PREMIUM',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Dismiss',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: ScholarlyTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
