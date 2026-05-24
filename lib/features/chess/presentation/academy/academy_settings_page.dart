import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scholarly_theme.dart';
import '../widgets/ambient_scaffold.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';

/// The settings page for Academy Mode, managing local Academy audio preferences.
class AcademySettingsPage extends ConsumerWidget {
  const AcademySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    return AmbientScaffold(
      blob1Color: const Color(0xFFF1F5F9), // Soft parchment
      blob2Color: const Color(0xFFFEF3C7), // Warm amber glow
      blob3Color: const Color(0xFFECFDF5), // Scholar emerald
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Space
              SliverToBoxAdapter(
                child: SizedBox(height: MediaQuery.of(context).padding.top + 24),
              ),

              // Back Button & Page Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: ScholarlyTheme.textPrimary,
                        ),
                        onPressed: () {
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ACADEMY SETTINGS',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: ScholarlyTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Settings Sections List
              SliverList(
                delegate: SliverChildListDelegate([
                  // SOUNDS CATEGORY
                  _SettingsCategory(
                    title: 'SOUNDS',
                    children: [
                      _SettingsTile(
                        label: 'Academy Sound Engine',
                        description: 'Configure movements, checks, outcomes & AI voice cues',
                        icon: Icons.tune_rounded,
                        onTap: () => _showAcademySoundSettingsOverlay(context, ref),
                        enabled: state.isAcademySoundEnabled,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: ScholarlyTheme.textMuted,
                        ),
                      ),
                      _SettingsSwitchTile(
                        label: 'Academy Sounds',
                        description: 'Enable or disable all Academy chessboard sounds locally',
                        icon: state.isAcademySoundEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        value: state.isAcademySoundEnabled,
                        onChanged: (v) => notifier.toggleAcademySound(),
                        enabled: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Mentorship Info Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: JuicyGlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_stories_rounded,
                                color: ScholarlyTheme.accentBlue,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Grandmaster Archives',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ScholarlyTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Personalized study plans and training drill customizations are being prepared by the collective. Local settings (e.g. piece movements and capture sounds) apply strictly inside your Academy dashboard.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.5,
                              color: ScholarlyTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 120), // Bottom spacing
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAcademySoundSettingsOverlay(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(chessProvider);
                final notifier = ref.read(chessProvider.notifier);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.85,
                          ),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Academy Sound Engine',
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: ScholarlyTheme.textMuted,
                                      ),
                                      onPressed: () => Navigator.of(context).pop(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Fine-tune your local Academy sounds',
                                  style: GoogleFonts.inter(
                                    color: ScholarlyTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _SoundToggle(
                                  icon: Icons.directions_run_rounded,
                                  label: 'Piece Movement',
                                  description: 'Taps, sliding sounds, castle clangs & promotions',
                                  value: state.academySoundSettings['moveSounds'] ?? true,
                                  onChanged: (v) => notifier.updateAcademySoundSetting('moveSounds', v),
                                  enabled: state.isAcademySoundEnabled,
                                ),
                                const SizedBox(height: 4),
                                _SoundToggle(
                                  icon: Icons.flash_on_rounded,
                                  label: 'Piece Captures',
                                  description: 'Capture sounds and arcade burst SFX',
                                  value: state.academySoundSettings['captureSounds'] ?? true,
                                  onChanged: (v) => notifier.updateAcademySoundSetting('captureSounds', v),
                                  enabled: state.isAcademySoundEnabled,
                                ),
                                const SizedBox(height: 4),
                                _SoundToggle(
                                  icon: Icons.notifications_active_rounded,
                                  label: 'Alerts & Indicators',
                                  description: 'Check alerts, piece drops & invalid move thuds',
                                  value: state.academySoundSettings['alertSounds'] ?? true,
                                  onChanged: (v) => notifier.updateAcademySoundSetting('alertSounds', v),
                                  enabled: state.isAcademySoundEnabled,
                                ),
                                const SizedBox(height: 4),
                                _SoundToggle(
                                  icon: Icons.emoji_events_rounded,
                                  label: 'Match Outcomes',
                                  description: 'Victory, defeat, draw & game over cues',
                                  value: state.academySoundSettings['outcomeSounds'] ?? true,
                                  onChanged: (v) => notifier.updateAcademySoundSetting('outcomeSounds', v),
                                  enabled: state.isAcademySoundEnabled,
                                ),
                                const SizedBox(height: 4),
                                _SoundToggle(
                                  icon: Icons.menu_book_rounded,
                                  label: 'Coach/AI Cues',
                                  description: 'GM Chanakya thinking & complete book sounds',
                                  value: state.academySoundSettings['coachSounds'] ?? true,
                                  onChanged: (v) => notifier.updateAcademySoundSetting('coachSounds', v),
                                  enabled: state.isAcademySoundEnabled,
                                ),
                                const SizedBox(height: 4),
                                _SoundToggle(
                                  icon: Icons.keyboard_rounded,
                                  label: 'Ambient Interface Clicks',
                                  description: 'Typewriter/writing clicks and subtle interaction sounds',
                                  value: state.academySoundSettings['ambientClicks'] ?? true,
                                  onChanged: (v) => notifier.updateAcademySoundSetting('ambientClicks', v),
                                  enabled: state.isAcademySoundEnabled,
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: ScholarlyTheme.accentBlue,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Done',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      transitionBuilder: (context, a1, a2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(a1.value),
          child: FadeTransition(opacity: a1, child: child),
        );
      },
    );
  }
}

class _SettingsCategory extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsCategory({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: JuicySectionHeader(
            title: title,
            color: ScholarlyTheme.accentBlue,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: JuicyGlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 24,
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends ConsumerWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool enabled;

  const _SettingsTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
    this.trailing,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const Color? effectiveAccent = null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: ListTile(
        onTap: enabled
            ? () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                onTap();
              }
            : null,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: effectiveAccent != null
                ? effectiveAccent.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: effectiveAccent != null
                  ? effectiveAccent.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: effectiveAccent ?? ScholarlyTheme.textPrimary,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: effectiveAccent ?? ScholarlyTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
        ),
        trailing: trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: ScholarlyTheme.textSubtle,
              size: 20,
            ),
      ),
    );
  }
}

class _SettingsSwitchTile extends ConsumerWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _SettingsSwitchTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: SwitchListTile(
        value: value,
        onChanged: (v) {
          if (!enabled) return;
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.switchToggle);
          onChanged(v);
        },
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: value
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: value ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
            size: 20,
          ),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
        ),
        activeThumbColor: ScholarlyTheme.accentBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

class _SoundToggle extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  const _SoundToggle({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () {
            if (!enabled) return;
            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.switchToggle);
            onChanged(!value);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: value ? ScholarlyTheme.accentBlue.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value ? ScholarlyTheme.accentBlue.withValues(alpha: 0.3) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: value ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: (v) {
                    if (!enabled) return;
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.switchToggle);
                    onChanged(v);
                  },
                  activeThumbColor: ScholarlyTheme.accentBlue,
                  activeTrackColor: ScholarlyTheme.accentBlue.withValues(
                    alpha: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
