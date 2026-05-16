import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scholarly_theme.dart';
import 'widgets/global_sidebar.dart';
import 'widgets/game_controls.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: ScholarlyTheme.backgroundStart,
      drawer: const GlobalSidebar(),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    'ABOUT US',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kingslayer Chess Team',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: ScholarlyTheme.accentBlue,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 64,
                          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Coming Soon',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Our story and mission will be\navailable in the next update.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: ScholarlyTheme.textSubtle,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
          
          // Action Row
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ActionIconButton(
                  icon: Icons.menu_rounded,
                  size: 24,
                  onTap: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                Text(
                  'ABOUT',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textSubtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
