import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../data/saved_game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import '../services/chess_sound_service.dart';
import 'scholarly_theme.dart';
import 'widgets/history_card.dart';
import 'widgets/game_controls.dart';
import 'widgets/global_sidebar.dart';
import 'widgets/ambient_scaffold.dart';
import 'dashboard_page.dart';

enum HistoryFilter { all, favorites, rated, unrated }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  HistoryFilter _currentFilter = HistoryFilter.all;


  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chessProvider.notifier).loadSavedGames());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    var filteredSaves = state.savedGames;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredSaves = filteredSaves.where((s) {
        final shortId = s.id.length >= 4 ? s.id.substring(0, 4) : s.id;
        final name = (s.customName != null && s.customName!.isNotEmpty)
            ? s.customName!.toLowerCase()
            : 'untitled$shortId';
        final date = s.savedAt.toString().toLowerCase();
        return name.contains(query) || date.contains(query);
      }).toList();
    }

    // Tab filtering
    switch (_currentFilter) {
      case HistoryFilter.favorites:
        filteredSaves = filteredSaves.where((s) => s.isFavorite).toList();
        break;
      case HistoryFilter.rated:
        filteredSaves = filteredSaves.where((s) => s.isRatedMode).toList();
        break;
      case HistoryFilter.unrated:
        filteredSaves = filteredSaves.where((s) => !s.isRatedMode).toList();
        break;
      case HistoryFilter.all:
        // Already assigned
        break;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        exitToDashboardWithSidebar(context, ref);
      },
      child: AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        drawer: const GlobalSidebar(),
        blob1Color: const Color(0xFFCCFBF1), // Soft Teal
        blob2Color: const Color(0xFFDBEAFE), // Soft Blue
        blob3Color: const Color(0xFFFCE7F3), // Soft Pink
        body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'HISTORY',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ),
                // Integrated Glass Header: Search + Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: JuicyGlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildSearchBar()),
                            if (state.savedGames.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_sweep_rounded,
                                  color: Colors.redAccent,
                                  size: 24,
                                ),
                                tooltip: 'Clear All',
                                onPressed: () {
                                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                  _confirmClearAll(context, notifier);
                                },
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildFilterTab('All', HistoryFilter.all),
                              const SizedBox(width: 8),
                              _buildFilterTab('Favorites', HistoryFilter.favorites),
                              const SizedBox(width: 8),
                              _buildFilterTab('Rated', HistoryFilter.rated),
                              const SizedBox(width: 8),
                              _buildFilterTab('Unrated', HistoryFilter.unrated),
                              const SizedBox(width: 16),
                              Text(
                                  '${filteredSaves.length} matches',
                                  style: GoogleFonts.inter(
                                    color: ScholarlyTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Scrollable List
                Expanded(
                  child: state.isSavedGamesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredSaves.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 64,
                                    color: ScholarlyTheme.panelStroke,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No games found',
                                    style: GoogleFonts.inter(
                                      color: ScholarlyTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                              itemCount: filteredSaves.length,
                              itemBuilder: (context, index) {
                                final game = filteredSaves[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: HistoryCard(
                                    game: game,
                                    onTap: () {
                                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                      notifier.loadSavedGame(game);
                                      Navigator.of(context).popUntil(
                                        (route) => route.isFirst,
                                      );
                                    },
                                    onDelete: () {
                                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                      notifier.deleteSavedGame(game.id);
                                    },
                                    onToggleFavorite: () {
                                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                      notifier.toggleFavorite(game.id);
                                    },
                                    onRename: (newName) {
                                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                      notifier.renameSavedGame(
                                        game.id,
                                        newName,
                                      );
                                    },
                                    onExport: () {
                                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                      _showExportOptions(context, game);
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),

          // Floating 3-bar drawer menu button (fixed at top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: ActionIconButton(
              icon: Icons.menu_rounded,
              size: 24,
              shouldBlink: !state.hasBlinkedMenu,
              onBlinkComplete: () => notifier.markMenuAsBlinked(),
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
        ],
      ),
    ), // End of AmbientScaffold
   ); // End of PopScope
  }

  Widget _buildFilterTab(String label, HistoryFilter filter) {
    final isSelected = _currentFilter == filter;
    Color activeColor = ScholarlyTheme.accentBlue;
    if (filter == HistoryFilter.rated) activeColor = ScholarlyTheme.realGold; // Real gold from theme
    if (filter == HistoryFilter.unrated) activeColor = const Color(0xFF0D9488); // Modern teal

    return GestureDetector(
      onTap: () {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        setState(() => _currentFilter = filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? activeColor : ScholarlyTheme.textPrimary.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(
          color: ScholarlyTheme.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or date...',
          hintStyle: GoogleFonts.inter(
            color: ScholarlyTheme.textMuted,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ScholarlyTheme.textMuted,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    ChessNotifier notifier,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        title: Text('Clear All History?'),
        content: Text('This will permanently delete all saved games.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ScholarlyTheme.textMuted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notifier.clearAllHistory();
    }
  }

  String _generatePgn(SavedGameEntry game) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('yyyy.MM.dd').format(game.savedAt);
    final shortId = game.id.length >= 4 ? game.id.substring(0, 4) : game.id;
    final title = game.customName?.isNotEmpty == true
        ? game.customName!
        : 'untitled$shortId';

    buffer.writeln('[Event "$title"]');
    buffer.writeln('[Site "Kingslayer Chess App"]');
    buffer.writeln('[Date "$dateStr"]');
    buffer.writeln('[Round "1"]');
    buffer.writeln('[White "${game.isPlayerWhite ? "Player" : "Stockfish"}"]');
    buffer.writeln('[Black "${game.isPlayerWhite ? "Stockfish" : "Player"}"]');
    buffer.writeln('[Result "*"]');
    if (game.gameMode == 'chess960') {
      buffer.writeln('[Variant "Chess960"]');
      buffer.writeln('[FEN "${game.fen}"]');
      buffer.writeln('[SetUp "1"]');
    }
    buffer.writeln();

    for (int i = 0; i < game.recentMoves.length; i++) {
      if (i % 2 == 0) {
        buffer.write('${(i ~/ 2) + 1}. ');
      }
      buffer.write('${game.recentMoves[i]} ');
    }
    buffer.write('*');
    return buffer.toString();
  }

  Future<void> _exportToPgnFile(
    BuildContext context,
    SavedGameEntry game,
    String pgnText,
  ) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/kingslayer_game_${game.id}.pgn';
      final file = File(path);
      await file.writeAsString(pgnText);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PGN saved to: $path'),
            backgroundColor: ScholarlyTheme.accentBlue,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('PGN Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PGN Export failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _sharePgnFile(
    BuildContext context,
    SavedGameEntry game,
    String pgnText,
  ) async {
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/kingslayer_game_${game.id}.pgn';
      final file = File(path);
      await file.writeAsString(pgnText);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Here is my chess game notation from Kingslayer!',
          subject: 'Kingslayer Chess Game',
        ),
      );
    } catch (e) {
      debugPrint('PGN Share failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PGN Share failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showExportOptions(BuildContext context, SavedGameEntry game) {
    final pgnText = _generatePgn(game);

    showModalBottomSheet(
      context: context,
      backgroundColor: ScholarlyTheme.panelBase,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.import_export_rounded,
                  color: ScholarlyTheme.accentBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Export / Share Game',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: ScholarlyTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Portable Game Notation (PGN)',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 180),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ScholarlyTheme.backgroundStart,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ScholarlyTheme.panelStroke),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SelectableText(
                  pgnText,
                  style: GoogleFonts.jetBrainsMono(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ScholarlyTheme.accentBlueSoft,
                      foregroundColor: ScholarlyTheme.accentBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.save_alt_rounded, size: 18),
                    label: const Text('Save .PGN'),
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      Navigator.pop(context);
                      _exportToPgnFile(context, game, pgnText);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ScholarlyTheme.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share .PGN'),
                    onPressed: () {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      Navigator.pop(context);
                      _sharePgnFile(context, game, pgnText);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
