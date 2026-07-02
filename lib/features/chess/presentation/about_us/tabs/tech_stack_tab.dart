import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../scholarly_theme.dart';
import '../../widgets/ambient_scaffold.dart';
import '../widgets/about_us_widgets.dart';

class TechStackTab extends StatelessWidget {
  const TechStackTab({super.key});

  @override
  Widget build(BuildContext context) {
    final techStackItems = [
      {
        'icon': Icons.phone_android_rounded,
        'category': 'UI FRAMEWORK',
        'technology': 'Flutter (Dart)',
        'description': 'Empowers the presentation layer with dynamic fluid layouts, customized UI canvas rendering, and smooth state updates.',
      },
      {
        'icon': Icons.bubble_chart_rounded,
        'category': 'STATE ENGINE',
        'technology': 'Riverpod',
        'description': 'Handles application state lifecycle, event dispatching, and engine process bridges with compile-time type safety.',
      },
      {
        'icon': Icons.memory_rounded,
        'category': 'LOCAL CHESS ENGINE',
        'technology': 'Arasan 25.4 (Native FFI)',
        'description': 'Runs locally via an ARMv8 optimized C++ binary (`libarasan_chess_engine.so`) interacting via non-blocking standard I/O pipes.',
      },
      {
        'icon': Icons.settings_suggest_rounded,
        'category': 'BARE-METAL CORE',
        'technology': 'Rust & Shakmaty',
        'description': 'Executes instant move generation, threat checks, and diagnostic scotomas on 64-bit CPU masks via `flutter_rust_bridge`.',
      },
      {
        'icon': Icons.font_download_rounded,
        'category': 'TYPOGRAPHY',
        'technology': 'Google Fonts',
        'description': 'Loads high-contrast typography (Outfit, Inter, JetBrains Mono, Pirata One) to secure academic visual polish.',
      },
      {
        'icon': Icons.animation_rounded,
        'category': 'MOTION FRAMEWORK',
        'technology': 'Flutter Animation System',
        'description': 'Drives 6 custom piece movement profiles, cinematic board camera drifts, landing settle bounces, and selected breathing.',
      },
      {
        'icon': Icons.storage_rounded,
        'category': 'PERSISTENCE',
        'technology': 'SharedPreferences',
        'description': 'Secures persistent client profiles, active theme parameters, audio volumes, and offline user settings.',
      },
      {
        'icon': Icons.devices_rounded,
        'category': 'PLATFORMS',
        'technology': 'Android Only',
        'description': 'Native Android compilation optimized for low-latency native execution, locked portrait orientation, and efficient thread schedules.',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: techStackItems.length,
      itemBuilder: (context, index) {
        final item = techStackItems[index];
        return AnimatedEntryCard(
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: TechChipCard(
              icon: item['icon'] as IconData,
              category: item['category'] as String,
              technology: item['technology'] as String,
              description: item['description'] as String,
              themeColor: Colors.purple,
            ),
          ),
        );
      },
    );
  }
}

class TechChipCard extends StatelessWidget {
  final IconData icon;
  final String category;
  final String technology;
  final String description;
  final Color themeColor;

  const TechChipCard({
    super.key,
    required this.icon,
    required this.category,
    required this.technology,
    required this.description,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return JuicyGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: themeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            technology,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: ScholarlyTheme.textMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
