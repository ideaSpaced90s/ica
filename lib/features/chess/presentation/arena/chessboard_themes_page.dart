import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../application/store_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import '../mobile_navigation_shell.dart';
import 'themes/theme_registry.dart';
import '../shared/themes/chess_theme.dart';
import '../widgets/ambient_scaffold.dart';

class ChessboardThemesPage extends ConsumerWidget {
  const ChessboardThemesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);
    ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);

    // Group definitions based on user preferences
    final groupAIds = ['classic', 'scholar', 'vector_glass', 'vector_championship'];
    final groupDIds = ['theme2', 'theme3', 'theme5', 'vector_egyptian', 'theme4', 'theme10'];
    final groupCIds = ['sprite_plasma', 'sprite_lightning', 'sprite_diamonds', 'sprite_arc', 'sprite_fairytale'];

    final themesA = ThemeRegistry.allThemes.where((t) => groupAIds.contains(t.id) && storeNotifier.isBoardThemePurchased(t.id)).toList();
    final themesC = ThemeRegistry.allThemes.where((t) => groupCIds.contains(t.id) && storeNotifier.isBoardThemePurchased(t.id)).toList();
    final themesD = ThemeRegistry.allThemes.where((t) => groupDIds.contains(t.id) && storeNotifier.isBoardThemePurchased(t.id)).toList();
    
    // Group B contains all remaining themes
    final themesB = ThemeRegistry.allThemes.where((t) => 
      !groupAIds.contains(t.id) &&
      !groupCIds.contains(t.id) &&
      !groupDIds.contains(t.id) &&
      storeNotifier.isBoardThemePurchased(t.id)
    ).toList();

    return AmbientScaffold(
      blob1Color: const Color(0xFFFAE8FF),
      blob2Color: const Color(0xFFE0E7FF),
      blob3Color: const Color(0xFFD1FAE5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Safe area top padding
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 24),
          ),

          // Premium Header with Back Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: ScholarlyTheme.textPrimary),
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BOARD THEMES',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Group A
          ..._buildGroupSlivers(
            context: context,
            ref: ref,
            themes: themesA,
            selectedThemeId: state.boardThemeId,
            notifier: notifier,
            showDivider: false,
          ),

          // Group B
          ..._buildGroupSlivers(
            context: context,
            ref: ref,
            themes: themesB,
            selectedThemeId: state.boardThemeId,
            notifier: notifier,
            showDivider: true,
          ),

          // Group D
          ..._buildGroupSlivers(
            context: context,
            ref: ref,
            themes: themesD,
            selectedThemeId: state.boardThemeId,
            notifier: notifier,
            showDivider: true,
          ),

          // Group C
          ..._buildGroupSlivers(
            context: context,
            ref: ref,
            themes: themesC,
            selectedThemeId: state.boardThemeId,
            notifier: notifier,
            showDivider: true,
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupSlivers({
    required BuildContext context,
    required WidgetRef ref,
    required List<ChessTheme> themes,
    required String selectedThemeId,
    required dynamic notifier,
    required bool showDivider,
  }) {
    if (themes.isEmpty) return const [];

    return [
      if (showDivider)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Divider(
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
              thickness: 1.0,
            ),
          ),
        ),

      // Sliver Grid displaying themes in a gallery
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (MediaQuery.of(context).size.width / 130).floor().clamp(3, 10),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final theme = themes[index];
              final isSelected = theme.id == selectedThemeId;

              return _buildThemeCard(context, ref, theme, isSelected, notifier);
            },
            childCount: themes.length,
          ),
        ),
      ),
    ];
  }

  Widget _buildThemeCard(
    BuildContext context,
    WidgetRef ref,
    ChessTheme theme,
    bool isSelected,
    dynamic notifier,
  ) {
    final isOwned = ref.watch(storeProvider.notifier).isBoardThemePurchased(theme.id);

    return GestureDetector(
      onTap: () {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        
        if (isOwned) {
          notifier.setBoardTheme(theme.id);
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          // Switch to Store tab, set store tab index to 1 (Themes Tab), and set highlight theme
          ref.read(mobileNavIndexProvider.notifier).state = 11;
          ref.read(storeTabProvider.notifier).state = 1;
          ref.read(storeHighlightThemeIdProvider.notifier).state = theme.id;
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? ScholarlyTheme.accentBlue
                : Colors.white.withValues(alpha: 0.65),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: Container(color: theme.lightSquare)),
                                    Expanded(child: Container(color: theme.darkSquare)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(child: Container(color: theme.darkSquare)),
                                    Expanded(child: Container(color: theme.lightSquare)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.50,
                            heightFactor: 0.50,
                            child: theme.buildPiece(
                              context,
                              'N',
                              true,
                              false,
                              0.0,
                            ),
                          ),
                        ),
                        if (!isOwned)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.lock_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        if (isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                theme.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
