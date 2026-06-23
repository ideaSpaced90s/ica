import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kingslayer_chess/src/rust/api/pgn_db.dart' as rust_pgn;
import 'package:archive/archive.dart';
import 'package:kingslayer_chess/features/chess/data/saved_game.dart';
import 'package:kingslayer_chess/main.dart' show sharedPrefs;

import '../widgets/ambient_scaffold.dart';
import '../scholarly_theme.dart';
import '../../application/study_lab_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import '../../application/historical_cinema_provider.dart';
import '../../domain/models/historical_game.dart';



class GameLibraryTab extends ConsumerStatefulWidget {
  final VoidCallback onGameLoaded;

  const GameLibraryTab({
    super.key,
    required this.onGameLoaded,
  });

  @override
  ConsumerState<GameLibraryTab> createState() => _GameLibraryTabState();
}

class _GameLibraryTabState extends ConsumerState<GameLibraryTab> {
  Future<List<rust_pgn.PgnGameRecord>>? _libraryFuture;

  int _librarySubTabIndex = 0;
  String? _selectedFolderName;
  String _searchQuery = '';
  final TextEditingController _librarySearchController = TextEditingController();
  List<GameLibraryFolder> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chessProvider.notifier).loadSavedGames();
      _refreshLibrary();
    });
  }

  @override
  void dispose() {
    _librarySearchController.dispose();
    super.dispose();
  }

  void _loadFolders() {
    try {
      final jsonStr = sharedPrefs.getString('game_library_folders');
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          setState(() {
            _folders = decoded
                .map((f) => GameLibraryFolder.fromJson(f as Map<String, dynamic>))
                .toList();
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading folders: $e');
    }
    setState(() {
      _folders = [];
    });
  }

  void _saveFolders() {
    try {
      final jsonStr = jsonEncode(_folders.map((f) => f.toJson()).toList());
      sharedPrefs.setString('game_library_folders', jsonStr);
    } catch (e) {
      debugPrint('Error saving folders: $e');
    }
  }

  void _createFolder(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_folders.any((f) => f.name.toLowerCase() == trimmed.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A folder with this name already exists!'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() {
      _folders.add(GameLibraryFolder(name: trimmed, itemIds: []));
      _saveFolders();
    });
  }

  void _renameFolder(int index, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    if (_folders.any((f) => f.name.toLowerCase() == trimmed.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A folder with this name already exists!'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() {
      final folder = _folders[index];
      _folders[index] = GameLibraryFolder(name: trimmed, itemIds: folder.itemIds);
      _saveFolders();
    });
  }

  void _deleteFolder(int index) {
    setState(() {
      _folders.removeAt(index);
      _saveFolders();
    });
  }

  void _toggleGameInFolder(String folderName, String itemId) {
    setState(() {
      final folderIndex = _folders.indexWhere((f) => f.name == folderName);
      if (folderIndex != -1) {
        final folder = _folders[folderIndex];
        final list = List<String>.from(folder.itemIds);
        if (list.contains(itemId)) {
          list.remove(itemId);
        } else {
          list.add(itemId);
        }
        _folders[folderIndex] = GameLibraryFolder(name: folder.name, itemIds: list);
        _saveFolders();
      }
    });
  }

  void _refreshLibrary() {
    if (mounted) {
      setState(() {
        _libraryFuture = ref.read(studyLabProvider.notifier).loadGamesFromLibrary();
      });
    }
  }





  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyLabProvider);
    final notifier = ref.read(studyLabProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: _buildGameLibraryOverlayTab(context, state, notifier),
    );
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: ScholarlyTheme.panelBase,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ScholarlyTheme.panelStroke),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactImportButton(BuildContext context, StudyLabNotifier notifier) {
    return _buildCompactIconButton(
      icon: Icons.file_upload_rounded,
      iconColor: ScholarlyTheme.accentBlue,
      onTap: () => _importPgnFromFile(context, notifier),
      tooltip: 'Import PGN',
    );
  }

  Widget _buildCompactExportButton(BuildContext context, StudyLabNotifier notifier) {
    return _buildCompactIconButton(
      icon: Icons.file_download_rounded,
      iconColor: Colors.teal,
      onTap: () => _showExportSelectionDialog(context, notifier),
      tooltip: 'Export PGN',
    );
  }

  Future<void> _importPgnFromFile(BuildContext context, StudyLabNotifier notifier) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pgn'],
      );
      if (result == null || result.files.single.path == null) return;

      final path = result.files.single.path!;
      final file = File(path);
      final pgnText = await file.readAsString();

      notifier.importPgn(pgnText);

      notifier.markDirty();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PGN Imported successfully! Save explicitly to add to library.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('PGN Import failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PGN Import failed: $e', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _showExportSelectionDialog(BuildContext context, StudyLabNotifier notifier) async {
    final records = await notifier.loadGamesFromLibrary();
    if (records.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved studies in library to export! Please save a study first.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final selectedIndices = <int>{};

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ScholarlyTheme.panelBase,
              title: Text(
                'Select Studies to Export',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (c, idx) => const Divider(color: ScholarlyTheme.panelStroke, height: 1),
                  itemBuilder: (c, idx) {
                    final r = records[idx];
                    final isChecked = selectedIndices.contains(idx);
                    return CheckboxListTile(
                      activeColor: ScholarlyTheme.accentBlue,
                      title: Text(
                        r.header.event,
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        'ECO: ${r.header.eco} | White: ${r.header.white} | Black: ${r.header.black}',
                        style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.textMuted),
                      ),
                      value: isChecked,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedIndices.add(idx);
                          } else {
                            selectedIndices.remove(idx);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ScholarlyTheme.accentBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: selectedIndices.isEmpty
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          final chosenRecords = selectedIndices.map((i) => records[i]).toList();
                          _performExport(context, chosenRecords);
                        },
                  child: Text(
                    'Export (${selectedIndices.length})',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performExport(BuildContext context, List<rust_pgn.PgnGameRecord> games) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
      directory ??= await getApplicationDocumentsDirectory();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      if (games.length == 1) {
        final record = games.first;
        final pgnText = rust_pgn.exportPgnWithHeaders(
          header: record.header,
          annotatedPgn: record.movesPgn,
        );

        final fileName = '${record.header.event.replaceAll(RegExp(r"[^\w\s\-]"), '_')}_$timestamp.pgn';
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(pgnText);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PGN exported to: ${file.path}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final archive = Archive();

        for (final record in games) {
          final pgnText = rust_pgn.exportPgnWithHeaders(
            header: record.header,
            annotatedPgn: record.movesPgn,
          );
          final pgnBytes = utf8.encode(pgnText);
          final safeName = '${record.header.event.replaceAll(RegExp(r"[^\w\s\-]"), '_')}.pgn';
          
          archive.addFile(
            ArchiveFile(
              safeName,
              pgnBytes.length,
              pgnBytes,
            ),
          );
        }

        final zipBytes = ZipEncoder().encode(archive);

        final zipFileName = 'ideaspace_export_$timestamp.zip';
        final file = File('${directory.path}/$zipFileName');
        await file.writeAsBytes(zipBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exported ZIP containing ${games.length} PGNs to: ${file.path}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green,
            ),
          );
        }
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

  Widget _buildGameLibraryOverlayTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    _libraryFuture ??= notifier.loadGamesFromLibrary();
    final chessState = ref.watch(chessProvider);

    return FutureBuilder<List<rust_pgn.PgnGameRecord>>(
      future: _libraryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final customRecords = snapshot.data ?? const [];

        // 1. Build unified list of GameLibraryItem
        final List<GameLibraryItem> allItems = [];

        // Add custom SQLite studies
        for (var i = 0; i < customRecords.length; i++) {
          final record = customRecords[i];
          final title = record.header.event.isNotEmpty ? record.header.event : 'Custom Study #${i + 1}';
          final moveCount = record.movesPgn.split(' ').where((m) => m.isNotEmpty && !m.contains('.')).length;
          
          final details = '${record.header.white} vs ${record.header.black} | Moves: $moveCount';
          
          DateTime date = DateTime.now();
          try {
            if (record.header.date.isNotEmpty && record.header.date != '?') {
              final dateStr = record.header.date.replaceAll('.', '-');
              date = DateTime.parse(dateStr);
            }
          } catch (_) {}

          allItems.add(GameLibraryItem(
            id: 'study_${record.index}',
            type: GameLibraryItemType.customStudy,
            title: title,
            details: details,
            date: date,
            customStudy: record,
          ));
        }

        // Add favorited Battleground games and completed Academy games
        for (final game in chessState.savedGames) {
          final isAcademy = game.isAcademyActive;
          final isFavBattleground = game.isRatedMode && game.isFavorite;

          if (isAcademy || isFavBattleground) {
            final shortId = game.id.length >= 4 ? game.id.substring(0, 4) : game.id;
            final title = game.customName != null && game.customName!.isNotEmpty
                ? game.customName!
                : (isAcademy ? 'Academy Game $shortId' : 'Battleground Game $shortId');
            
            final details = '${game.isPlayerWhite ? "White" : "Black"} | Moves: ${game.recentMoves.length}';

            allItems.add(GameLibraryItem(
              id: 'saved_${game.id}',
              type: isAcademy ? GameLibraryItemType.academy : GameLibraryItemType.battleground,
              title: title,
              details: details,
              date: game.savedAt,
              savedGame: game,
            ));
          }
        }

        // Sort items by date descending
        allItems.sort((a, b) => b.date.compareTo(a.date));

        // Filter items by search query
        List<GameLibraryItem> filteredItems = allItems;
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredItems = allItems.where((item) {
            final titleMatch = item.title.toLowerCase().contains(query);
            final detailsMatch = item.details.toLowerCase().contains(query);
            
            bool movesMatch = false;
            if (item.type == GameLibraryItemType.customStudy) {
              movesMatch = item.customStudy!.movesPgn.toLowerCase().contains(query);
            } else if (item.savedGame != null) {
              movesMatch = item.savedGame!.recentMoves.any((m) => m.toLowerCase().contains(query));
            }

            return titleMatch || detailsMatch || movesMatch;
          }).toList();
        }

        // If folder sub-tab is active
        Widget activeBody;
        if (_librarySubTabIndex == 0) {
          activeBody = _buildAllGamesList(filteredItems, notifier);
        } else if (_librarySubTabIndex == 1) {
          if (_selectedFolderName == null) {
            activeBody = _buildFoldersListView();
          } else {
            activeBody = _buildFolderDetailsView(_selectedFolderName!, filteredItems, notifier);
          }
        } else {
          activeBody = _buildLegendsListView(notifier);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                'GAME LIBRARY',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: ScholarlyTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSearchBar()),
                const SizedBox(width: 8),
                _buildCompactImportButton(context, notifier),
                const SizedBox(width: 8),
                _buildCompactExportButton(context, notifier),
              ],
            ),
            const SizedBox(height: 8),
            _buildLibrarySubTabBar(),
            const SizedBox(height: 12),
            Expanded(
              child: activeBody,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScholarlyTheme.panelStroke),
      ),
      child: TextField(
        controller: _librarySearchController,
        style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13),
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: _librarySubTabIndex == 2
              ? 'Search legends...'
              : 'Search games by name, players, moves...',
          hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: ScholarlyTheme.textMuted, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _librarySearchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: const Icon(Icons.clear_rounded, color: ScholarlyTheme.textMuted, size: 16),
                )
              : null,
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildLibrarySubTabBar() {
    return Row(
      children: [
        _buildSubTabButton(0, 'All Games', Icons.grid_view_rounded),
        const SizedBox(width: 8),
        _buildSubTabButton(1, 'Folders', Icons.folder_copy_rounded),
        const SizedBox(width: 8),
        _buildSubTabButton(2, 'Legends', Icons.star_rounded),
      ],
    );
  }

  Widget _buildSubTabButton(int index, String label, IconData icon) {
    final isActive = _librarySubTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
          setState(() {
            _librarySubTabIndex = index;
            _selectedFolderName = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15) : ScholarlyTheme.panelBase,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.panelStroke,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllGamesList(List<GameLibraryItem> items, StudyLabNotifier notifier) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty ? 'No matching games found.' : 'No games in library yet.',
          style: GoogleFonts.inter(fontSize: 12, color: ScholarlyTheme.textMuted, fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return GameLibraryItemCardWidget(
          item: item,
          notifier: notifier,
          onRefresh: _refreshLibrary,
          onOrganizeFolders: () => _showFolderSelectionDialog(context, item),
          onEditStudy: _promptEditStudyHeaders,
          ref: ref,
          onGameLoaded: widget.onGameLoaded,
        );
      },
    );
  }

  Widget _buildLegendsListView(StudyLabNotifier notifier) {
    final cinemaState = ref.watch(historicalCinemaProvider);
    final Map<String, List<HistoricalGame>> grouped = {};
    for (final game in cinemaState.games) {
      final title = "${game.white} vs ${game.black}";
      final details = "${game.event} (${game.year}) | ${game.educationalTheme}";
      
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty || 
          title.toLowerCase().contains(query) || 
          details.toLowerCase().contains(query) || 
          game.category.toLowerCase().contains(query)) {
        grouped.putIfAbsent(game.category, () => []).add(game);
      }
    }

    if (grouped.isEmpty) {
      return Center(
        child: Text(
          'No legend games found.',
          style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
        ),
      );
    }

    // Sort categories in the proper order as defined in the source
    final sortedCategories = grouped.keys.toList()
      ..sort((a, b) {
        const categoryOrder = [
          'cat_tactical',
          'cat_positional',
          'cat_dynamic',
          'cat_endgame',
          'cat_sacrifice',
          'cat_hypermodern',
          'cat_closed_systems',
          'cat_sicilian_clashes',
          'cat_initiative',
          'cat_pawn_dynamics',
          'cat_bishop_pair',
          'cat_defensive_saves',
        ];
        int idxA = categoryOrder.indexWhere((key) => a.toLowerCase().contains(key));
        int idxB = categoryOrder.indexWhere((key) => b.toLowerCase().contains(key));
        if (idxA == -1) idxA = 999;
        if (idxB == -1) idxB = 999;
        return idxA.compareTo(idxB);
      });

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final categoryName = sortedCategories[index];
        final gamesInCategory = grouped[categoryName]!;
        final metadata = _getCategoryMetadata(categoryName);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: JuicyGlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 12,
            borderColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(metadata.icon, color: metadata.color, size: 20),
                title: Text(
                  metadata.title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: metadata.color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metadata.subtitle,
                      style: GoogleFonts.inter(fontSize: 9, color: ScholarlyTheme.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${gamesInCategory.length} game${gamesInCategory.length > 1 ? "s" : ""}',
                      style: GoogleFonts.inter(fontSize: 8, color: ScholarlyTheme.textMuted, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                children: gamesInCategory.map((game) {
                  final title = "${game.white} vs ${game.black}";
                  final details = "${game.event} (${game.year}) | ${game.educationalTheme}";
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    title: Text(
                      title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11, color: ScholarlyTheme.textPrimary),
                    ),
                    subtitle: Text(
                      details,
                      style: GoogleFonts.inter(fontSize: 9, color: ScholarlyTheme.textMuted),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: ScholarlyTheme.accentBlue, size: 18),
                      onPressed: () {
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                        notifier.importPgn(game.pgn);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Loaded: $title', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                          widget.onGameLoaded();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFoldersListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FOLDERS (${_folders.length})',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.accentBlue,
                letterSpacing: 0.5,
              ),
            ),
            TextButton.icon(
              icon: const Icon(Icons.create_new_folder_outlined, size: 14),
              label: const Text('New Folder'),
              onPressed: () => _promptCreateFolder(context),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _folders.isEmpty
            ? Expanded(
                child: Center(
                  child: Text(
                    'No folders created yet.',
                    style: GoogleFonts.inter(fontSize: 12, color: ScholarlyTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            : Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _folders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final folder = _folders[index];
                    return JuicyGlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      borderRadius: 12,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.folder_rounded, color: ScholarlyTheme.accentBlue, size: 28),
                        title: Text(folder.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: ScholarlyTheme.textPrimary)),
                        subtitle: Text('${folder.itemIds.length} games', style: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textMuted)),
                        onTap: () {
                          setState(() {
                            _selectedFolderName = folder.name;
                          });
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.teal, size: 18),
                              onPressed: () => _promptRenameFolder(context, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: ScholarlyTheme.panelBase,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Text('Delete Folder?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
                                    content: Text('Are you sure you want to delete the folder "${folder.name}"? The games will not be deleted.', style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13)),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted))),
                                      FilledButton(
                                        style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                                        onPressed: () {
                                          _deleteFolder(index);
                                          Navigator.pop(ctx);
                                        },
                                        child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildFolderDetailsView(String folderName, List<GameLibraryItem> allFilteredItems, StudyLabNotifier notifier) {
    final folder = _folders.firstWhere((f) => f.name == folderName, orElse: () => GameLibraryFolder(name: folderName, itemIds: []));
    final folderItems = allFilteredItems.where((item) => folder.itemIds.contains(item.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFolderName = null;
                });
              },
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: ScholarlyTheme.accentBlue),
                  const SizedBox(width: 4),
                  Text(
                    'BACK TO FOLDERS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.accentBlue,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              'FOLDER: ${folderName.toUpperCase()}',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        folderItems.isEmpty
            ? Expanded(
                child: Center(
                  child: Text(
                    _searchQuery.isNotEmpty ? 'No matching games in this folder.' : 'No games added to this folder yet.',
                    style: GoogleFonts.inter(fontSize: 12, color: ScholarlyTheme.textMuted, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            : Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: folderItems.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = folderItems[index];
                    return GameLibraryItemCardWidget(
                      item: item,
                      notifier: notifier,
                      onRefresh: _refreshLibrary,
                      onOrganizeFolders: () => _showFolderSelectionDialog(context, item),
                      onEditStudy: _promptEditStudyHeaders,
                      ref: ref,
                      onGameLoaded: widget.onGameLoaded,
                    );
                  },
                ),
              ),
      ],
    );
  }

  void _showFolderSelectionDialog(BuildContext context, GameLibraryItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ScholarlyTheme.panelBase,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
              ),
              title: Text(
                'Organize Game',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select folders to save "${item.title}":',
                      style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    _folders.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20.0),
                            child: Text(
                              'No folders created yet.',
                              style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontStyle: FontStyle.italic, fontSize: 12),
                            ),
                          )
                        : Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _folders.length,
                              itemBuilder: (context, index) {
                                final folder = _folders[index];
                                final inFolder = folder.itemIds.contains(item.id);
                                return CheckboxListTile(
                                  title: Text(folder.name, style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13)),
                                  value: inFolder,
                                  activeColor: ScholarlyTheme.accentBlue,
                                  onChanged: (val) {
                                    _toggleGameInFolder(folder.name, item.id);
                                    setDialogState(() {});
                                  },
                                );
                              },
                            ),
                          ),
                    const Divider(color: ScholarlyTheme.panelStroke),
                    TextButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Create New Folder'),
                      onPressed: () {
                        _promptCreateFolder(context, () {
                          setDialogState(() {});
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done', style: GoogleFonts.inter(color: ScholarlyTheme.accentBlue, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _promptCreateFolder(BuildContext context, [VoidCallback? onCreated]) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
          ),
          title: Text('New Folder', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
          content: TextField(
            controller: controller,
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Folder name (e.g. Openings)',
              hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue),
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                _createFolder(controller.text.trim());
                Navigator.pop(context);
                if (onCreated != null) onCreated();
              },
              child: Text('Create', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _promptRenameFolder(BuildContext context, int index) {
    final folder = _folders[index];
    final controller = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
          ),
          title: Text('Rename Folder', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary)),
          content: TextField(
            controller: controller,
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'New folder name',
              hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ScholarlyTheme.accentBlue),
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                _renameFolder(index, controller.text.trim());
                Navigator.pop(context);
              },
              child: Text('Rename', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _promptEditStudyHeaders(BuildContext context, StudyLabNotifier notifier, int index, rust_pgn.PgnGameRecord record) {
    final eventController = TextEditingController(text: record.header.event);
    final siteController = TextEditingController(text: record.header.site);
    final dateController = TextEditingController(text: record.header.date);
    final whiteController = TextEditingController(text: record.header.white);
    final blackController = TextEditingController(text: record.header.black);
    final whiteEloController = TextEditingController(text: record.header.whiteElo?.toString() ?? '');
    final blackEloController = TextEditingController(text: record.header.blackElo?.toString() ?? '');
    final resultController = TextEditingController(text: record.header.result);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
          ),
          title: Text(
            'Edit PGN Headers',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(eventController, 'Event / Name'),
                _buildDialogField(siteController, 'Site'),
                _buildDialogField(dateController, 'Date (YYYY.MM.DD)'),
                _buildDialogField(whiteController, 'White Player'),
                _buildDialogField(whiteEloController, 'White Elo', isNumeric: true),
                _buildDialogField(blackController, 'Black Player'),
                _buildDialogField(blackEloController, 'Black Elo', isNumeric: true),
                _buildDialogField(resultController, 'Result (*, 1-0, 0-1, 1/2-1/2)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final newHeader = rust_pgn.PgnGameHeader(
                  event: eventController.text.trim().isEmpty ? 'Study' : eventController.text.trim(),
                  site: siteController.text.trim(),
                  date: dateController.text.trim(),
                  white: whiteController.text.trim(),
                  black: blackController.text.trim(),
                  whiteElo: int.tryParse(whiteEloController.text.trim()),
                  blackElo: int.tryParse(blackEloController.text.trim()),
                  result: resultController.text.trim(),
                  eco: record.header.eco,
                  opening: record.header.opening,
                );

                await notifier.updateStudyHeadersInLibrary(index, newHeader);
                if (context.mounted) {
                  Navigator.pop(context);
                  _refreshLibrary();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PGN headers updated successfully!'), backgroundColor: Colors.green),
                  );
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
          filled: true,
          fillColor: ScholarlyTheme.panelBase,
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: ScholarlyTheme.panelStroke),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: ScholarlyTheme.accentBlue),
          ),
        ),
      ),
    );
  }
}

class GameLibraryItemCardWidget extends StatefulWidget {
  final GameLibraryItem item;
  final StudyLabNotifier notifier;
  final VoidCallback onRefresh;
  final VoidCallback onOrganizeFolders;
  final void Function(BuildContext, StudyLabNotifier, int, rust_pgn.PgnGameRecord) onEditStudy;
  final WidgetRef ref;
  final VoidCallback onGameLoaded;

  const GameLibraryItemCardWidget({
    super.key,
    required this.item,
    required this.notifier,
    required this.onRefresh,
    required this.onOrganizeFolders,
    required this.onEditStudy,
    required this.ref,
    required this.onGameLoaded,
  });

  @override
  State<GameLibraryItemCardWidget> createState() => _GameLibraryItemCardWidgetState();
}

class _GameLibraryItemCardWidgetState extends State<GameLibraryItemCardWidget>
    with SingleTickerProviderStateMixin {
  bool _showDeleteBin = false;
  late AnimationController _animController;
  late Animation<double> _flipAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnimation = Tween<double>(begin: -math.pi / 2, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleDeleteBin() {
    setState(() {
      _showDeleteBin = !_showDeleteBin;
      if (_showDeleteBin) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCustomStudy = widget.item.type == GameLibraryItemType.customStudy;
    final canDelete = isCustomStudy;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (canDelete)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Release to delete study...',
                    style: GoogleFonts.inter(
                      color: Colors.redAccent, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

        Dismissible(
          key: ValueKey('library-item-${widget.item.id}'),
          direction: (canDelete && _showDeleteBin) ? DismissDirection.startToEnd : DismissDirection.none,
          confirmDismiss: (direction) async {
            final record = widget.item.customStudy!;
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: ScholarlyTheme.panelBase,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
                ),
                title: Text(
                  'Delete Study?',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
                ),
                content: Text(
                  'Are you sure you want to delete "${record.header.event}" from your library? This cannot be undone.',
                  style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                    child: Text('Delete', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              final ok = await widget.notifier.deleteStudyFromLibrary(record.index.toInt());
              if (ok) {
                widget.onRefresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Study deleted successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                return true;
              }
            }

            setState(() {
              _showDeleteBin = false;
              _animController.reverse();
            });
            return false;
          },
          child: GestureDetector(
            onLongPress: canDelete ? _toggleDeleteBin : null,
            onTap: () {
              if (_showDeleteBin) {
                _toggleDeleteBin();
              } else {
                _loadGame();
              }
            },
            child: JuicyGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              borderRadius: 12,
              borderColor: _showDeleteBin 
                  ? Colors.redAccent.withValues(alpha: 0.5) 
                  : ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
              child: Row(
                children: [
                  if (_showDeleteBin) ...[
                    const Icon(Icons.arrow_forward_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe right to delete',
                      style: GoogleFonts.inter(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildTypeBadge(),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.item.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: ScholarlyTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.item.details,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: ScholarlyTheme.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    IconButton(
                      icon: const Icon(Icons.folder_open_outlined, color: ScholarlyTheme.textMuted, size: 18),
                      tooltip: 'Organize Folders',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: widget.onOrganizeFolders,
                    ),

                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: ScholarlyTheme.accentBlue, size: 20),
                      tooltip: 'Load Game',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: _loadGame,
                    ),

                    if (isCustomStudy)
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.teal, size: 18),
                        tooltip: 'Edit Headers',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => widget.onEditStudy(
                          context,
                          widget.notifier,
                          widget.item.customStudy!.index.toInt(),
                          widget.item.customStudy!,
                        ),
                      )
                    else if (widget.item.type == GameLibraryItemType.battleground)
                      IconButton(
                        icon: const Icon(Icons.star_rounded, color: ScholarlyTheme.accentYellow, size: 20),
                        tooltip: 'Unfavorite',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          widget.ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                          widget.ref.read(chessProvider.notifier).toggleFavorite(widget.item.savedGame!.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Removed from Game Library (unfavorited).'), backgroundColor: Colors.orange),
                          );
                        },
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),

        if (_showDeleteBin)
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final angle = _flipAnimation.value;
                final opacity = _slideAnimation.value;
                final scale = 0.5 + (0.5 * _slideAnimation.value);

                return Opacity(
                  opacity: opacity,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateY(angle)
                      ..scaleByDouble(scale, scale, 1.0, 1.0),
                    alignment: Alignment.centerRight,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.redAccent, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTypeBadge() {
    Color badgeColor;
    String text;
    switch (widget.item.type) {
      case GameLibraryItemType.customStudy:
        badgeColor = Colors.teal;
        text = 'STUDY';
        break;
      case GameLibraryItemType.academy:
        badgeColor = ScholarlyTheme.accentBlue;
        text = 'ACADEMY';
        break;
      case GameLibraryItemType.battleground:
        badgeColor = ScholarlyTheme.realGold;
        text = 'BATTLE';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          color: badgeColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _loadGame() {
    widget.ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
    if (widget.item.type == GameLibraryItemType.customStudy) {
      widget.notifier.loadPgnRecord(widget.item.customStudy!, widget.item.customStudy!.index.toInt());
    } else {
      widget.notifier.loadGameEntry(widget.item.savedGame!);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.item.title}" loaded successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
        ),
      );
      widget.onGameLoaded();
    }
  }
}

enum GameLibraryItemType { customStudy, battleground, academy }

class GameLibraryItem {
  final String id;
  final GameLibraryItemType type;
  final String title;
  final String details;
  final DateTime date;
  final rust_pgn.PgnGameRecord? customStudy;
  final SavedGameEntry? savedGame;

  GameLibraryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.details,
    required this.date,
    this.customStudy,
    this.savedGame,
  });
}

class GameLibraryFolder {
  final String name;
  final List<String> itemIds;

  GameLibraryFolder({
    required this.name,
    required this.itemIds,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'itemIds': itemIds,
  };

  factory GameLibraryFolder.fromJson(Map<String, dynamic> json) {
    return GameLibraryFolder(
      name: json['name'] as String,
      itemIds: (json['itemIds'] as List<dynamic>? ?? const [])
          .map((id) => id.toString())
          .toList(),
    );
  }
}

class _CategoryMetadata {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _CategoryMetadata({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

_CategoryMetadata _getCategoryMetadata(String category) {
  final catLower = category.toLowerCase();
  if (catLower.contains("cat_tactical") || catLower.contains("horizons") || catLower.contains("horisons")) {
    return const _CategoryMetadata(
      title: "Open Horizons & Gambits",
      subtitle: "Attacking lines, piece sacrifices, and tactical calculations",
      icon: Icons.grid_on_rounded,
      color: Color(0xFF059669),
    );
  } else if (catLower.contains("cat_positional") || catLower.contains("fortress")) {
    return const _CategoryMetadata(
      title: "The Iron Fortress",
      subtitle: "Prophylaxis, pawn structures, and positional suffocation",
      icon: Icons.security_rounded,
      color: ScholarlyTheme.accentBlue,
    );
  } else if (catLower.contains("cat_dynamic") || catLower.contains("counterstrike")) {
    return const _CategoryMetadata(
      title: "The Counterstrike Collection",
      subtitle: "Sharp defense turning into instant attack and dynamics",
      icon: Icons.bolt_rounded,
      color: Color(0xFF7C3AED),
    );
  } else if (catLower.contains("cat_endgame") || catLower.contains("endgame")) {
    return const _CategoryMetadata(
      title: "The Endgame Squeeze",
      subtitle: "Technical conversions, king activity, and promotion races",
      icon: Icons.workspace_premium_rounded,
      color: ScholarlyTheme.realGold,
    );
  } else if (catLower.contains("cat_sacrifice") || catLower.contains("sacrifice")) {
    return const _CategoryMetadata(
      title: "The Art of the Sacrifice",
      subtitle: "Direct piece sacrifices, king hunts, and mating combinations",
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE11D48),
    );
  } else if (catLower.contains("cat_hypermodern") || catLower.contains("hypermodern")) {
    return const _CategoryMetadata(
      title: "Hypermodern Masterpieces",
      subtitle: "Flank control, fianchetto setups, and indirect center pressure",
      icon: Icons.radar_rounded,
      color: Color(0xFF0D9488),
    );
  } else if (catLower.contains("cat_closed_systems") || catLower.contains("closed")) {
    return const _CategoryMetadata(
      title: "Queen's Gambit & Closed Stratagems",
      subtitle: "Pawn structures, minority attacks, and tension in closed files",
      icon: Icons.lock_rounded,
      color: Color(0xFF4F46E5),
    );
  } else if (catLower.contains("cat_sicilian") || catLower.contains("sicilian")) {
    return const _CategoryMetadata(
      title: "Razor-Sharp Sicilians",
      subtitle: "Asymmetrical tactical battles and opposite-side castling storms",
      icon: Icons.offline_bolt_rounded,
      color: Color(0xFFEA580C),
    );
  } else if (catLower.contains("cat_initiative") || catLower.contains("initiative")) {
    return const _CategoryMetadata(
      title: "Mastering the Initiative",
      subtitle: "Energetic play, continuous threats, and restricting the defender",
      icon: Icons.trending_up_rounded,
      color: Color(0xFF2563EB),
    );
  } else if (catLower.contains("cat_pawn") || catLower.contains("pawn")) {
    return const _CategoryMetadata(
      title: "Pawn Structure Dynamics",
      subtitle: "Carlsbad pawn chains, isolated pawns, and passed pawn advances",
      icon: Icons.grain_rounded,
      color: Color(0xFF65A30D),
    );
  } else if (catLower.contains("cat_bishop") || catLower.contains("bishop")) {
    return const _CategoryMetadata(
      title: "The Power of the Bishop Pair",
      subtitle: "Long-range domination, knight restriction, and diagonal control",
      icon: Icons.layers_rounded,
      color: Color(0xFF7C3AED),
    );
  } else if (catLower.contains("cat_defensive") || catLower.contains("escape")) {
    return const _CategoryMetadata(
      title: "The Art of the Escape",
      subtitle: "Miraculous swindles, constructing fortresses, and saving the game",
      icon: Icons.shield_rounded,
      color: Color(0xFF475569),
    );
  }
  return const _CategoryMetadata(
    title: "Other Legend Games",
    subtitle: "Historical masterpieces",
    icon: Icons.movie_filter_rounded,
    color: ScholarlyTheme.accentBlue,
  );
}

