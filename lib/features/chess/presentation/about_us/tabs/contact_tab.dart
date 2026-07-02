import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../scholarly_theme.dart';
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
        // Header Info
        AnimatedEntryCard(
          index: 0,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.indigo.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.alternate_email_rounded,
                    size: 28,
                    color: Colors.indigo,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'GET IN TOUCH',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'We would love to hear from premium members. Share feedback, feature requests, or improvements you want considered for future app updates.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: ScholarlyTheme.textMuted,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        AnimatedEntryCard(
          index: 1,
          child: _buildContactButton(
            context: context,
            icon: Icons.email_rounded,
            label: 'Support Email',
            value: 'For official support',
            copyValue: 'apps@ideaspaceapps.store',
            onTap: () => launchUrlCallback('mailto:apps@ideaspaceapps.store'),
            themeColor: Colors.amber.shade700,
            cardBgStart: Colors.amber.shade50.withValues(alpha: 0.85),
            cardBgEnd: const Color(0xFFFFFDF5),
            borderColor: Colors.amber.shade200.withValues(alpha: 0.7),
            shadowColor: Colors.amber.shade100.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 16),

        AnimatedEntryCard(
          index: 2,
          child: _buildContactButton(
            context: context,
            icon: Icons.chat_rounded,
            label: 'WhatsApp Support',
            value: 'For quick queries',
            copyValue: 'https://wa.me/message/RSJWZF2RMGAQM1',
            onTap: () => launchUrlCallback('https://wa.me/message/RSJWZF2RMGAQM1'),
            themeColor: const Color(0xFF25D366),
            cardBgStart: Colors.green.shade50.withValues(alpha: 0.85),
            cardBgEnd: const Color(0xFFF7FFF9),
            borderColor: Colors.green.shade200.withValues(alpha: 0.7),
            shadowColor: Colors.green.shade100.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 16),

        AnimatedEntryCard(
          index: 3,
          child: _buildContactButton(
            context: context,
            icon: Icons.campaign_rounded,
            label: 'WhatsApp Channel',
            value: 'Offers and updates',
            copyValue: 'https://whatsapp.com/channel/0029Vb8HC52GE56iQ4kNRY07',
            onTap: () => launchUrlCallback('https://whatsapp.com/channel/0029Vb8HC52GE56iQ4kNRY07'),
            themeColor: Colors.blue.shade700,
            cardBgStart: Colors.blue.shade50.withValues(alpha: 0.85),
            cardBgEnd: const Color(0xFFF5FAFF),
            borderColor: Colors.blue.shade200.withValues(alpha: 0.7),
            shadowColor: Colors.blue.shade100.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 24),

        AnimatedEntryCard(
          index: 4,
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
                    'VERSION 2.0.22 (RELEASE)',
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
          index: 5,
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
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required String copyValue,
    required VoidCallback onTap,
    required Color themeColor,
    required Color cardBgStart,
    required Color cardBgEnd,
    required Color borderColor,
    required Color shadowColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [cardBgStart, cardBgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: themeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: themeColor.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: ScholarlyTheme.textMuted.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 12),
                Container(
                  height: 24,
                  width: 1,
                  color: themeColor.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 12),
                Material(
                  color: Colors.transparent,
                  child: Tooltip(
                    message: 'Copy to clipboard',
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: copyValue));
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.95),
                            elevation: 4,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: themeColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            content: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: themeColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Copied to Clipboard',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        label,
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: themeColor.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.copy_all_rounded,
                          size: 18,
                          color: ScholarlyTheme.textMuted,
                        ),
                      ),
                    ),
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
