import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../scholarly_theme.dart';
import '../../services/auth_service.dart';
import '../../services/chess_sound_service.dart';
import '../../services/play_games_sync_service.dart';
import '../../application/tutorial_provider.dart';
import '../../application/onboarding_provider.dart';
import '../../application/chess_provider.dart';

class SignInPromptDialog extends StatefulWidget {
  final String title;
  final String description;
  final VoidCallback onSignInSuccess;

  const SignInPromptDialog({
    super.key,
    required this.title,
    required this.description,
    required this.onSignInSuccess,
  });

  static void show({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onSignInSuccess,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SignInPromptDialog(
        title: title,
        description: description,
        onSignInSuccess: onSignInSuccess,
      ),
    );
  }

  @override
  State<SignInPromptDialog> createState() => _SignInPromptDialogState();
}

class _SignInPromptDialogState extends State<SignInPromptDialog> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn(WidgetRef ref) async {
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final userCredential = await authService.signInWithGoogle();

      if (userCredential != null) {
        if (!mounted) return;

        // Perform standard Google Sign-In setup/restoration
        final repo = ref.read(tutorialProgressRepositoryProvider);
        await repo.setIsGoogleSignedIn(true);
        await repo.setArenaIntroSeen(false);
        await repo.setBattlegroundIntroSeen(false);
        await repo.setPuzzlesIntroSeen(false);
        await repo.setAcademyIntroSeen(false);
        await repo.setAcademyAccessCount(0);

        ref.read(showArenaIntroProvider.notifier).state = true;
        ref.read(showBattlegroundIntroProvider.notifier).state = true;
        ref.read(showPuzzlesIntroProvider.notifier).state = true;

        // Restore Google Drive progress (timeout to ensure UI responsiveness)
        try {
          await ref
              .read(googleDriveSyncProvider.notifier)
              .restore()
              .timeout(const Duration(seconds: 4));
        } catch (e) {
          debugPrint('Google Drive restore sync timed out or failed: $e');
        }

        if (mounted) {
          Navigator.pop(context); // Close dialog
          widget.onSignInSuccess(); // Proceed with purchase
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              const Icon(
                Icons.account_circle_rounded,
                color: Colors.blueAccent,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.description,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: ScholarlyTheme.textPrimary,
                  height: 1.4,
                ),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(ScholarlyTheme.accentBlue),
                  ),
                ),
              ],
            ],
          ),
          actions: _isLoading
              ? []
              : [
                  TextButton(
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleGoogleSignIn(ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ScholarlyTheme.accentBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.login_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Sign In',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
        );
      },
    );
  }
}
