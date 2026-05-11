import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
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
        final name = s.customName?.toLowerCase() ?? '';
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
                          Navigator.of(context).pop(); // Back to main
                        },
                        onDelete: () => notifier.deleteSavedGame(game.id),
                        onToggleFavorite: () => notifier.toggleFavorite(game.id),
                        onRename: (newName) => notifier.renameSavedGame(game.id, newName),
                        onExport: (key) => _exportToPng(context, key, game.id),
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

  Future<void> _exportToPng(BuildContext context, GlobalKey key, String id) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/kingslayer_game_$id.png';
      final file = File(path);
      await file.writeAsBytes(bytes);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Board exported to: $path'),
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
      debugPrint('Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
