import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../scholarly_theme.dart';
import '../../widgets/ambient_scaffold.dart';
import '../widgets/about_us_widgets.dart';

class ContactTab extends StatelessWidget {
  final ValueChanged<String> launchUrlCallback;

  const ContactTab({
    super.key,
    required this.launchUrlCallback,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      physics: const BouncingScrollPhysics(),
      children: [
        AnimatedEntryCard(
          index: 0,
          child: JuicyGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            borderRadius: 24,
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber.shade700.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.alternate_email_rounded,
                      size: 32,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'GET IN TOUCH',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: ScholarlyTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We would love to hear your feedback, suggestions, or cooperation ideas. Reach out to the IdeaSpace team directly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: ScholarlyTheme.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 24),

                _buildContactButton(
                  icon: Icons.language_rounded,
                  label: 'Official Website',
                  value: 'ideaspaceapps.store',
                  onTap: () => launchUrlCallback('https://ideaspaceapps.store'),
                  themeColor: Colors.amber.shade700,
                ),
                const SizedBox(height: 12),

                _buildContactButton(
                  icon: Icons.email_rounded,
                  label: 'Support Email',
                  value: 'apps@ideaspaceapps.store',
                  onTap: () => launchUrlCallback('mailto:apps@ideaspaceapps.store'),
                  themeColor: Colors.amber.shade700,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        AnimatedEntryCard(
          index: 1,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade700.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.amber.shade700.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 14,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'VERSION 1.0.0 (RELEASE)',
                    style: GoogleFonts.jetBrainsMono(
                      color: Colors.amber.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        AnimatedEntryCard(
          index: 2,
          child: Center(
            child: Column(
              children: [
                Text(
                  'Designed & Developed by',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: ScholarlyTheme.textSubtle,
                  ),
                ),
                const SizedBox(height: 6),
                Image.asset(
                  'assets/splash/ideaspace.png',
                  height: 16,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'The IdeaSpace Chess Academy Team',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required Color themeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: themeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textSubtle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: ScholarlyTheme.textSubtle,
            ),
          ],
        ),
      ),
    );
  }
}
