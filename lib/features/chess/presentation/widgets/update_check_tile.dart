import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../scholarly_theme.dart';
import '../../application/update_provider.dart';
import 'ambient_scaffold.dart';

class UpdateCheckTile extends ConsumerWidget {
  const UpdateCheckTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(updateProvider);
    final notifier = ref.read(updateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        child: JuicyGlassCard(
          padding: const EdgeInsets.all(18.0),
          borderRadius: ScholarlyTheme.radiusMedium,
          child: _buildContent(context, state, notifier),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UpdateState state,
    UpdateNotifier notifier,
  ) {
    switch (state.status) {
      case UpdateCheckStatus.checking:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(ScholarlyTheme.accentBlue),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              "Checking for updates...",
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

      case UpdateCheckStatus.upToDate:
        return Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981), // Emerald green
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "App is fully updated",
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "You are using the latest version (v${state.currentVersion})",
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => notifier.triggerManualCheck(),
              child: Text(
                "Recheck",
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.accentBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );

      case UpdateCheckStatus.updateAvailable:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.accentBlueSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PulsingDotIndicator(color: ScholarlyTheme.accentBlue),
                      const SizedBox(width: 6),
                      Text(
                        "UPDATE AVAILABLE",
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.accentBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  "v${state.currentVersion} → v${state.latestVersion}",
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "New version available!",
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Get the latest features, engine upgrades, and stability improvements.",
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textMuted,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Feedback.forTap(context);
                  notifier.startInAppDownload();
                },
                child: Text(
                  "Update Now",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        );

      case UpdateCheckStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Downloading update...",
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  "${(state.downloadProgress * 100).toInt()}%",
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.accentBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: state.downloadProgress,
                  backgroundColor: ScholarlyTheme.accentBlueSoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(ScholarlyTheme.accentBlue),
                ),
              ),
            ),
          ],
        );

      case UpdateCheckStatus.downloadCompleted:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.offline_pin_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  "Download complete!",
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "The update has been downloaded. Restart the application to finish installing.",
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textMuted,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Feedback.forTap(context);
                  notifier.completeFlexibleUpdate();
                },
                child: Text(
                  "Restart & Apply",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        );

      case UpdateCheckStatus.error:
        return Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Update check failed",
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Please check your internet connection.",
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => notifier.triggerManualCheck(),
              child: Text(
                "Retry",
                style: GoogleFonts.inter(
                  color: ScholarlyTheme.accentBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );

      case UpdateCheckStatus.idle:
        return InkWell(
          onTap: () {
            Feedback.forTap(context);
            notifier.triggerManualCheck();
          },
          borderRadius: BorderRadius.circular(ScholarlyTheme.radiusMedium),
          child: Row(
            children: [
              const Icon(
                Icons.system_update_rounded,
                color: ScholarlyTheme.accentBlue,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Check for Updates",
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Current Version: v${state.currentVersion}",
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.hasUpdateBadge)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: PulsingDotIndicator(color: Colors.redAccent),
                ),
              const Icon(
                Icons.chevron_right_rounded,
                color: ScholarlyTheme.textSubtle,
                size: 20,
              ),
            ],
          ),
        );
    }
  }
}

class PulsingDotIndicator extends StatefulWidget {
  final Color color;
  const PulsingDotIndicator({super.key, this.color = Colors.redAccent});

  @override
  State<PulsingDotIndicator> createState() => _PulsingDotIndicatorState();
}

class _PulsingDotIndicatorState extends State<PulsingDotIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_controller),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1.15).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
