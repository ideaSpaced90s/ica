import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../application/chess_provider.dart';
import '../services/chess_sound_service.dart';
import 'scholarly_theme.dart';
import 'widgets/ambient_scaffold.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Color?> _glowColorAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowColorAnimation = ColorTween(
      begin: ScholarlyTheme.accentBlue.withValues(alpha: 0.05),
      end: ScholarlyTheme.accentBlue.withValues(alpha: 0.35),
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _checkSystemPermissionSync();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkSystemPermissionSync() async {
    final status = await Permission.notification.status;
    final isGranted = status.isGranted;
    final state = ref.read(chessProvider);
    if (!isGranted && state.isNotificationsEnabled) {
      await ref.read(chessProvider.notifier).toggleNotifications(false);
    }
  }

  Future<bool> _requestNotificationPermission(BuildContext context) async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isGranted) return true;

      final result = await Permission.notification.request();
      if (result.isGranted) return true;

      if (context.mounted) {
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
      return false;
    }
    return true; // Windows allows notifications by default
  }

  Future<void> _selectTime(
    BuildContext context,
    String currentTimeStr,
    Function(String) onTimeSelected,
  ) async {
    final parts = currentTimeStr.split(':');
    final initialHour = parts.length == 2 ? int.tryParse(parts[0]) ?? 9 : 9;
    final initialMinute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ScholarlyTheme.accentBlue,
              onPrimary: Colors.white,
              onSurface: ScholarlyTheme.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: ScholarlyTheme.accentBlue),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      onTimeSelected('$hourStr:$minuteStr');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    if (state.isNotificationsEnabled) {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.reset();
      }
    } else {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    }
    final soundService = ref.read(chessSoundServiceProvider);

    return AmbientScaffold(
      scaffoldKey: _scaffoldKey,
      blob1Color: const Color(0xFFDBEAFE),
      blob2Color: const Color(0xFFFEF3C7),
      blob3Color: const Color(0xFFF3E8FF),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Navigation Header Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: ScholarlyTheme.textPrimary),
                  onPressed: () {
                    soundService.playSfx(SoundEffect.uiClick);
                    Navigator.pop(context);
                  },
                ),
                centerTitle: true,
                title: Text(
                  'NOTIFICATIONS',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                floating: true,
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Notification Master Enable/Disable Switch
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: state.isNotificationsEnabled ? 1.0 : _scaleAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: state.isNotificationsEnabled
                                ? []
                                : [
                                    BoxShadow(
                                      color: _glowColorAnimation.value ?? Colors.transparent,
                                      blurRadius: 14,
                                      spreadRadius: 2,
                                    ),
                                  ],
                          ),
                          child: child,
                        ),
                      );
                    },
                    child: JuicyGlassCard(
                      padding: EdgeInsets.zero,
                      borderRadius: 24,
                      child: SwitchListTile(
                        value: state.isNotificationsEnabled,
                        onChanged: (enabled) async {
                          soundService.playSfx(SoundEffect.switchToggle);
                          if (enabled) {
                            final granted = await _requestNotificationPermission(context);
                            if (granted) {
                              await notifier.toggleNotifications(true);
                            }
                          } else {
                            await notifier.toggleNotifications(false);
                          }
                        },
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: state.isNotificationsEnabled
                                ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15)
                                : ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: state.isNotificationsEnabled
                                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.25)
                                  : ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            state.isNotificationsEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_rounded,
                            color: state.isNotificationsEnabled
                                ? ScholarlyTheme.accentBlue
                                : ScholarlyTheme.accentBlue.withValues(alpha: 0.6),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Notifications',
                          style: GoogleFonts.inter(
                            color: ScholarlyTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Enable or disable all app notifications',
                          style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
                        ),
                        activeThumbColor: ScholarlyTheme.accentBlue,
                        activeTrackColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                        inactiveThumbColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.6),
                        inactiveTrackColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Settings Categories (disabled if notifications are false)
              SliverList(
                delegate: SliverChildListDelegate([
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: state.isNotificationsEnabled ? 1.0 : 0.45,
                    child: IgnorePointer(
                      ignoring: !state.isNotificationsEnabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                            child: JuicySectionHeader(
                              title: 'ALERTS & BRIEFINGS',
                              color: ScholarlyTheme.accentBlue,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: JuicyGlassCard(
                              padding: EdgeInsets.zero,
                              borderRadius: 24,
                              child: Column(
                                children: [
                                  // Daily Briefing
                                  _PreferenceSwitchTile(
                                    label: 'Daily Briefings',
                                    description: 'Receive morning briefings with new daily chess drills',
                                    icon: Icons.lightbulb_outline_rounded,
                                    value: state.dailyBriefingEnabled,
                                    onChanged: (v) => notifier.updateNotificationPreferences(
                                      dailyBriefingEnabled: v,
                                    ),
                                  ),
                                  // Streak Protection
                                  _PreferenceSwitchTile(
                                    label: 'Streak Protection',
                                    description: 'Get warnings when daily assignment completion is at risk',
                                    icon: Icons.hourglass_empty_rounded,
                                    value: state.streakProtectionEnabled,
                                    onChanged: (v) => notifier.updateNotificationPreferences(
                                      streakProtectionEnabled: v,
                                    ),
                                  ),
                                  // Weekly Diagnostics
                                  _PreferenceSwitchTile(
                                    label: 'Weekly Diagnostics',
                                    description: 'Receive GM Chanakya\'s diagnostic report on your chess',
                                    icon: Icons.insights_rounded,
                                    value: state.weeklyDiagnosticsEnabled,
                                    onChanged: (v) => notifier.updateNotificationPreferences(
                                      weeklyDiagnosticsEnabled: v,
                                    ),
                                  ),
                                  // Milestones
                                  _PreferenceSwitchTile(
                                    label: 'Milestones & Triumphs',
                                    description: 'Receive congratulations on rating gains and accomplishments',
                                    icon: Icons.emoji_events_outlined,
                                    value: state.milestonesEnabled,
                                    onChanged: (v) => notifier.updateNotificationPreferences(
                                      milestonesEnabled: v,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Custom Schedule Settings
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                            child: JuicySectionHeader(
                              title: 'SCHEDULING & DETAILS',
                              color: ScholarlyTheme.accentBlue,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: JuicyGlassCard(
                              padding: EdgeInsets.zero,
                              borderRadius: 24,
                              child: Column(
                                children: [
                                  // Briefing time picker
                                  ListTile(
                                    leading: const Icon(Icons.alarm_rounded, color: ScholarlyTheme.textPrimary),
                                    title: Text(
                                      'Morning Briefing Time',
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Current schedule: ${state.dailyBriefingTime}',
                                      style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
                                    ),
                                    trailing: const Icon(Icons.edit_calendar_rounded, color: ScholarlyTheme.textSubtle, size: 20),
                                    onTap: () {
                                      soundService.playSfx(SoundEffect.uiClick);
                                      _selectTime(context, state.dailyBriefingTime, (newTime) {
                                        notifier.updateNotificationPreferences(dailyBriefingTime: newTime);
                                      });
                                    },
                                  ),
                                  const Divider(height: 1, color: Colors.white24),
                                  // Streak protection threshold dropdown
                                  ListTile(
                                    leading: const Icon(Icons.warning_amber_rounded, color: ScholarlyTheme.textPrimary),
                                    title: Text(
                                      'Streak warning threshold',
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Warn me ${state.streakWarningHoursBeforeReset} hours before midnight reset',
                                      style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 11),
                                    ),
                                    trailing: DropdownButton<int>(
                                      value: state.streakWarningHoursBeforeReset,
                                      dropdownColor: ScholarlyTheme.panelBase,
                                      underline: const SizedBox(),
                                      items: const [
                                        DropdownMenuItem(value: 2, child: Text('2 Hours', style: TextStyle(color: ScholarlyTheme.textPrimary))),
                                        DropdownMenuItem(value: 4, child: Text('4 Hours', style: TextStyle(color: ScholarlyTheme.textPrimary))),
                                        DropdownMenuItem(value: 6, child: Text('6 Hours', style: TextStyle(color: ScholarlyTheme.textPrimary))),
                                        DropdownMenuItem(value: 8, child: Text('8 Hours', style: TextStyle(color: ScholarlyTheme.textPrimary))),
                                      ],
                                      onChanged: (hours) {
                                        if (hours != null) {
                                          soundService.playSfx(SoundEffect.uiClick);
                                          notifier.updateNotificationPreferences(streakWarningHoursBeforeReset: hours);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Quiet Hours (Do Not Disturb)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                            child: JuicySectionHeader(
                              title: 'QUIET HOURS',
                              color: ScholarlyTheme.accentBlue,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: JuicyGlassCard(
                              padding: EdgeInsets.zero,
                              borderRadius: 24,
                              child: Column(
                                children: [
                                  // Toggle quiet hours
                                  _PreferenceSwitchTile(
                                    label: 'Enable Quiet Hours',
                                    description: 'Mute alerts during a specific timeframe',
                                    icon: Icons.do_not_disturb_on_rounded,
                                    value: state.quietHoursEnabled,
                                    onChanged: (v) => notifier.updateNotificationPreferences(
                                      quietHoursEnabled: v,
                                    ),
                                  ),
                                  if (state.quietHoursEnabled) ...[
                                    const Divider(height: 1, color: Colors.white24),
                                    ListTile(
                                      leading: const Icon(Icons.nightlight_round, color: ScholarlyTheme.textPrimary),
                                      title: Text(
                                        'Start Time',
                                        style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      trailing: Text(
                                        state.quietHoursStart,
                                        style: GoogleFonts.inter(color: ScholarlyTheme.accentBlue, fontWeight: FontWeight.bold),
                                      ),
                                      onTap: () {
                                        soundService.playSfx(SoundEffect.uiClick);
                                        _selectTime(context, state.quietHoursStart, (time) {
                                          notifier.updateNotificationPreferences(quietHoursStart: time);
                                        });
                                      },
                                    ),
                                    const Divider(height: 1, color: Colors.white24),
                                    ListTile(
                                      leading: const Icon(Icons.wb_sunny_rounded, color: ScholarlyTheme.textPrimary),
                                      title: Text(
                                        'End Time',
                                        style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      trailing: Text(
                                        state.quietHoursEnd,
                                        style: GoogleFonts.inter(color: ScholarlyTheme.accentBlue, fontWeight: FontWeight.bold),
                                      ),
                                      onTap: () {
                                        soundService.playSfx(SoundEffect.uiClick);
                                        _selectTime(context, state.quietHoursEnd, (time) {
                                          notifier.updateNotificationPreferences(quietHoursEnd: time);
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitchTile extends ConsumerWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitchTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      value: value,
      onChanged: (v) {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.switchToggle);
        onChanged(v);
      },
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: value ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? ScholarlyTheme.accentBlue.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.5),
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
      activeTrackColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
