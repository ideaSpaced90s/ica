import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScholarlyTheme {
  // Modern Office App Palette
  static const Color backgroundStart = Color(0xFFF8F9FA); // Clean off-white
  static const Color backgroundEnd = Color(0xFFE9ECEF);
  static const Color panelBase = Color(0xFFFFFFFF); // Clean white for panels
  static const Color panelGlass = Color(0xFFFFFFFF);
  static const Color panelStroke = Color(0xFFDEE2E6); // Subtle border
  static const Color boardFrame = Color(0xFFCED4DA);
  static const Color accentGold = Color(0xFF0056B3); // Professional Cobalt Blue (kept for compatibility)
  static const Color accentCobalt = Color(0xFF0056B3); // Cobalt Blue
  static const Color realGold = Color(0xFFF59E0B); // Real warm gold
  static const Color accentBlue = Color(0xFF0D6EFD); // Primary Blue
  static const Color accentBlueSoft = Color(0xFFE7F1FF); // Soft Blue Background
  static const Color accentYellow = Color(0xFFFFD700); // Gold/Yellow for hints
  static const Color accentYellowSoft = Color(
    0xFFFFF9E6,
  ); // Soft Yellow Background

  // Glass utilities
  static Color get glassWhite => Colors.white.withValues(alpha: 0.40);
  static Color get glassBorder => Colors.white.withValues(alpha: 0.55);
  static const double glassBlur = 12.0;

  // Kept original board colors as requested
  static const Color lightSquare = Color(0xFFC0C0C0);
  static const Color darkSquare = Color(0xFF808080);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textMuted = Color(0xFF64748B);

  // Constants
  static const Color shadowColor = Color(0xFF0F172A);
  static const double shadowOffset = 4.0;
  static const double insetOffset = 2.0;

  static const Color textSubtle = Color(0xFFADB5BD);
  static const Color activeClock = Color(0xFF0056B3);
  static const Color inactiveClock = Color(0xFF6C757D);
  static const Color moveHint = Color(0x330D6EFD); // Light blue hint
  static const Color selectedGlow = Color(0x660D6EFD);

  // Modern rounded shapes
  static const double radiusLarge = 24.0;
  static const double radiusMedium = 16.0;
  static const double radiusSmall = 8.0;

  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [backgroundStart, backgroundEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get glassGradient =>
      const LinearGradient(colors: [panelBase, panelBase]);

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  static List<BoxShadow> get boardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundStart,
      primaryColor: accentBlue,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineSmall: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textMuted,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  // Modern Card Decoration
  static BoxDecoration modernDecoration({bool sunken = false}) {
    if (sunken) {
      return BoxDecoration(
        color: panelBase,
        border: Border.all(color: panelStroke, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(insetOffset, insetOffset),
            spreadRadius: -1,
          ),
        ],
      );
    }

    return BoxDecoration(
      color: panelBase,
      border: Border.all(color: panelStroke, width: 1),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(shadowOffset, shadowOffset),
        ),
      ],
    );
  }

  static BoxDecoration glassPanelDecoration({double radius = radiusMedium}) => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.40),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration gradientCard({double radius = 28}) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [
        Color(0xFF0D6EFD), // accentBlue
        Color(0xFF5B21B6), // deep indigo
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0D6EFD).withValues(alpha: 0.35),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: 2,
      ),
    ],
  );
}

class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? strokeColor;
  final bool sunken;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.strokeColor,
    this.sunken = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ScholarlyTheme.modernDecoration(sunken: sunken).copyWith(
        borderRadius:
            borderRadius ?? BorderRadius.circular(ScholarlyTheme.radiusMedium),
        border: strokeColor != null ? Border.all(color: strokeColor!) : null,
      ),
      child: child,
    );
  }
}
