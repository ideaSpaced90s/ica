import 'package:flutter/material.dart';

class ScholarlyTheme {
  // Win98 Palette
  static const Color backgroundStart = Color(0xFF008080); // Classic Teal
  static const Color backgroundEnd = Color(0xFF008080);
  static const Color panelBase = Color(0xFFC0C0C0); // Classic Grey
  static const Color panelGlass = Color(0xFFC0C0C0);
  static const Color panelStroke = Color(0xFF808080);
  static const Color boardFrame = Color(0xFF808080);
  static const Color accentGold = Color(0xFF000080); // Classic Navy for title bars
  static const Color accentBlue = Color(0xFF008080);
  static const Color accentBlueSoft = Color(0xFF00FFFF);
  static const Color lightSquare = Color(0xFFC0C0C0);
  static const Color darkSquare = Color(0xFF808080);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textMuted = Color(0xFF404040);
  static const Color textSubtle = Color(0xFF808080);
  static const Color activeClock = Color(0xFF000080);
  static const Color inactiveClock = Color(0xFF808080);
  static const Color moveHint = Color(0xAA000080);
  static const Color selectedGlow = Color(0x99000080);

  // Win98 is all about square boxes
  static const double radiusLarge = 0;
  static const double radiusMedium = 0;
  static const double radiusSmall = 0;

  static LinearGradient get backgroundGradient => const LinearGradient(
    colors: [backgroundStart, backgroundEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get glassGradient => const LinearGradient(
    colors: [panelBase, panelBase],
  );

  static List<BoxShadow> get cardShadow => [];
  static List<BoxShadow> get boardShadow => [];

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: false, // Old school!
      scaffoldBackgroundColor: backgroundStart,
      primaryColor: const Color(0xFF000080),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'Tahoma', // Common Win98 font
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 13, height: 1.2, fontFamily: 'Tahoma'),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 11, height: 1.2, fontFamily: 'Tahoma'),
      ),
    );
  }

  // Win98 Bevel Decoration
  static BoxDecoration win98Decoration({bool sunken = false}) {
    return BoxDecoration(
      color: panelBase,
      border: Border(
        top: BorderSide(color: sunken ? const Color(0xFF808080) : Colors.white, width: 2),
        left: BorderSide(color: sunken ? const Color(0xFF808080) : Colors.white, width: 2),
        right: BorderSide(color: sunken ? Colors.white : const Color(0xFF808080), width: 2),
        bottom: BorderSide(color: sunken ? Colors.white : const Color(0xFF808080), width: 2),
      ),
    );
  }
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
    this.padding = const EdgeInsets.all(12),
    this.borderRadius,
    this.strokeColor,
    this.sunken = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ScholarlyTheme.win98Decoration(sunken: sunken),
      child: child,
    );
  }
}

