import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../data/saved_game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'widgets/history_card.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showOnlyFavorites = false;

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

    // Favorites filter
    if (_showOnlyFavorites) {
      filteredSaves = filteredSaves.where((s) => s.isFavorite).toList();
    }

    return Scaffold(
      backgroundColor: ScholarlyTheme.backgroundStart,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            backgroundColor: ScholarlyTheme.backgroundStart,
            surfaceTintColor: ScholarlyTheme.backgroundStart,
            title: Text(
              'Game History',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: ScholarlyTheme.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (state.savedGames.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                  tooltip: 'Clear All',
                  onPressed: () => _confirmClearAll(context, notifier),
                ),
              const SizedBox(width: 8),
            ],
          ),

          // Filters and Search
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      FilterChip(
                        label: Text('Favorites'),
                        selected: _showOnlyFavorites,
                        onSelected: (val) => setState(() => _showOnlyFavorites = val),
                        selectedColor: ScholarlyTheme.accentBlueSoft,
                        checkmarkColor: ScholarlyTheme.accentBlue,
                        labelStyle: GoogleFonts.inter(
                          color: _showOnlyFavorites ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: _showOnlyFavorites ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${filteredSaves.length} games found',
                        style: GoogleFonts.inter(
                          color: ScholarlyTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // List of Games
          if (state.isSavedGamesLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredSaves.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: ScholarlyTheme.panelStroke),
                    const SizedBox(height: 16),
                    Text(
                      'No games found',
                      style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final game = filteredSaves[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: HistoryCard(
                        game: game,
                        onTap: () {
                          notifier.loadSavedGame(game);
                          Navigator.of(context).popUntil((route) => route.isFirst); // Pop both History and Settings pages to return to main dashboard
                        },
                        onDelete: () => notifier.deleteSavedGame(game.id),
                        onToggleFavorite: () => notifier.toggleFavorite(game.id),
                        onRename: (newName) => notifier.renameSavedGame(game.id, newName),
                        onExport: () => _showExportOptions(context, game),
                      ),
                    );
                  },
                  childCount: filteredSaves.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: ScholarlyTheme.modernDecoration().copyWith(
        color: ScholarlyTheme.panelBase,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name or date...',
          hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: ScholarlyTheme.textMuted, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, ChessNotifier notifier) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        title: Text('Clear All History?'),
        content: Text('This will permanently delete all saved games.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: ScholarlyTheme.textMuted)),
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
    final title = game.customName?.isNotEmpty == true ? game.customName! : 'untitled$shortId';

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

  Future<void> _exportToPgnFile(BuildContext context, SavedGameEntry game, String pgnText) async {
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
          SnackBar(content: Text('PGN Export failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _sharePgnFile(BuildContext context, SavedGameEntry game, String pgnText) async {
    try {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/kingslayer_game_${game.id}.pgn';
      final file = File(path);
      await file.writeAsString(pgnText);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Here is my chess game notation from Kingslayer!',
        subject: 'Kingslayer Chess Game',
      );
    } catch (e) {
      debugPrint('PGN Share failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PGN Share failed: $e'), backgroundColor: Colors.redAccent),
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
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.import_export_rounded, color: ScholarlyTheme.accentBlue, size: 24),
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
                  icon: const Icon(Icons.close_rounded, color: ScholarlyTheme.textMuted, size: 20),
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
