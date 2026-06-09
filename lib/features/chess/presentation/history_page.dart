import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../data/saved_game.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/chess_provider.dart';
import '../application/arena_provider.dart';
import '../application/study_lab_provider.dart';
import '../services/chess_sound_service.dart';
import 'scholarly_theme.dart';
import 'widgets/history_card.dart';
import 'widgets/ambient_scaffold.dart';
import 'dashboard_page.dart';
import 'mobile_navigation_shell.dart';

enum HistoryFilterType { all, favorites }
enum HistorySubFilter { none, arena, battleground, academy }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  HistoryFilterType _currentFilter = HistoryFilterType.all;
  HistorySubFilter _allSubFilter = HistorySubFilter.none;
  HistorySubFilter _favoritesSubFilter = HistorySubFilter.none;
  bool _isSearchExpanded = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chessProvider.notifier).loadSavedGames());
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(mobileNavIndexProvider);
    if (activeTab == 6) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
    }

    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    var filteredSaves = state.savedGames;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
      final fullDateFormat = DateFormat('MMMM dd, yyyy');
      final timeFormat = DateFormat('hh:mm a');
      filteredSaves = filteredSaves.where((s) {
        final shortId = s.id.length >= 4 ? s.id.substring(0, 4) : s.id;
        final String name;
        if (s.isRatedMode) {
          name = (s.customName != null && s.customName!.isNotEmpty)
              ? s.customName!.toLowerCase()
              : 'rated game $shortId';
        } else {
          name = (s.customName != null && s.customName!.isNotEmpty && s.customName != 'Arena Game')
              ? s.customName!.toLowerCase()
              : 'unrated id: ${s.id.toLowerCase()}';
        }
        
        final formattedDate = dateFormat.format(s.savedAt).toLowerCase();
        final fullDate = fullDateFormat.format(s.savedAt).toLowerCase();
        final time12Hr = timeFormat.format(s.savedAt).toLowerCase();
        final rawDateString = s.savedAt.toString().toLowerCase();

        return name.contains(query) ||
            formattedDate.contains(query) ||
            fullDate.contains(query) ||
            time12Hr.contains(query) ||
            rawDateString.contains(query);
      }).toList();
    }

    // Tab filtering
    if (_currentFilter == HistoryFilterType.favorites) {
      filteredSaves = filteredSaves.where((s) => s.isFavorite).toList();
      if (_favoritesSubFilter == HistorySubFilter.arena) {
        filteredSaves = filteredSaves.where((s) => !s.isRatedMode && !s.isAcademyActive).toList();
      } else if (_favoritesSubFilter == HistorySubFilter.battleground) {
        filteredSaves = filteredSaves.where((s) => s.isRatedMode).toList();
      } else if (_favoritesSubFilter == HistorySubFilter.academy) {
        filteredSaves = filteredSaves.where((s) => s.isAcademyActive).toList();
      }
    } else {
      if (_allSubFilter == HistorySubFilter.arena) {
        filteredSaves = filteredSaves.where((s) => !s.isRatedMode && !s.isAcademyActive).toList();
      } else if (_allSubFilter == HistorySubFilter.battleground) {
        filteredSaves = filteredSaves.where((s) => s.isRatedMode).toList();
      } else if (_allSubFilter == HistorySubFilter.academy) {
        filteredSaves = filteredSaves.where((s) => s.isAcademyActive).toList();
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        exitToDashboardWithSidebar(context, ref);
      },
      child: AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: const Color(0xFFCCFBF1), // Soft Teal
        blob2Color: const Color(0xFFDBEAFE), // Soft Blue
        blob3Color: const Color(0xFFFCE7F3), // Soft Pink
        body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Integrated Glass Header: Search + Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: JuicyGlassCard(
                    padding: const EdgeInsets.all(12),
                    borderRadius: 20,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isSearchExpanded)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: ScholarlyTheme.textMuted,
                                  size: 22,
                                ),
                                onPressed: () {
                                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                  setState(() {
                                    _isSearchExpanded = false;
                                    _searchController.clear();
                                  });
                                },
                              ),
                              const SizedBox(width: 4),
                              Expanded(child: _buildSearchBar()),
                              if (_searchController.text.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    color: ScholarlyTheme.textMuted,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                    setState(() {
                                      _searchController.clear();
                                    });
                                  },
                                ),
                              ],
                            ],
                          )
                        else
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.search_rounded,
                                  color: ScholarlyTheme.textMuted,
                                  size: 22,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                  setState(() {
                                    _isSearchExpanded = true;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Builder(
                                        builder: (buttonContext) {
                                          String label = 'ALL';
                                          Color activeColor = ScholarlyTheme.accentBlue;
                                          if (_allSubFilter == HistorySubFilter.arena) {
                                            label = 'ARENA';
                                            activeColor = const Color(0xFF0D9488);
                                          } else if (_allSubFilter == HistorySubFilter.battleground) {
                                            label = 'BATTLEGROUND';
                                            activeColor = ScholarlyTheme.realGold;
                                          } else if (_allSubFilter == HistorySubFilter.academy) {
                                            label = 'ACADEMY';
                                            activeColor = ScholarlyTheme.accentBlue;
                                          }
                                          return _buildTabButton(
                                            label: label,
                                            isSelected: _currentFilter == HistoryFilterType.all,
                                            activeColor: activeColor,
                                            onTap: () {
                                              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                              setState(() {
                                                _currentFilter = HistoryFilterType.all;
                                                _allSubFilter = HistorySubFilter.none;
                                              });
                                              _showTabDropdown(buttonContext, true);
                                            },
                                            context: buttonContext,
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Builder(
                                        builder: (buttonContext) {
                                          String label = 'FAVOURITES';
                                          Color activeColor = const Color(0xFF10B981);
                                          if (_favoritesSubFilter == HistorySubFilter.arena) {
                                            label = 'ARENA';
                                            activeColor = const Color(0xFF0D9488);
                                          } else if (_favoritesSubFilter == HistorySubFilter.battleground) {
                                            label = 'BATTLEGROUND';
                                            activeColor = ScholarlyTheme.realGold;
                                          } else if (_favoritesSubFilter == HistorySubFilter.academy) {
                                            label = 'ACADEMY';
                                            activeColor = ScholarlyTheme.accentBlue;
                                          }
                                          return _buildTabButton(
                                            label: label,
                                            isSelected: _currentFilter == HistoryFilterType.favorites,
                                            activeColor: activeColor,
                                            onTap: () {
                                              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                              setState(() {
                                                _currentFilter = HistoryFilterType.favorites;
                                                _favoritesSubFilter = HistorySubFilter.none;
                                              });
                                              _showTabDropdown(buttonContext, false);
                                            },
                                            context: buttonContext,
                                            isPulse: true,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.savedGames.any((g) => !g.isRatedMode)) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_sweep_rounded,
                                    color: Colors.redAccent,
                                    size: 22,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Clear All',
                                  onPressed: () {
                                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                    _confirmClearAll(context, notifier);
                                  },
                                ),
                              ],
                            ],
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
                                      _currentFilter == HistoryFilterType.favorites
                                          ? Icons.star_rounded
                                          : Icons.history_rounded,
                                      size: 64,
                                      color: _currentFilter == HistoryFilterType.favorites
                                          ? ScholarlyTheme.accentYellow.withValues(alpha: 0.5)
                                          : ScholarlyTheme.panelStroke,
                                    ),
                                    const SizedBox(height: 16),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                      child: Text(
                                        _currentFilter == HistoryFilterType.favorites
                                            ? 'Add games to favorites to analyze and study'
                                            : 'No games found',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          color: ScholarlyTheme.textMuted,
                                          fontSize: _currentFilter == HistoryFilterType.favorites ? 16 : 14,
                                          fontWeight: _currentFilter == HistoryFilterType.favorites
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
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
                                    key: ValueKey(game.id),
                                    game: game,
                                    onTap: () {
                                      if (game.isRatedMode) {
                                        // Rated games do nothing when clicked
                                        return;
                                      }
                                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                      if (game.isAcademyActive) {
                                        ref.read(studyLabProvider.notifier).loadGameEntry(game);
                                        ref.read(mobileNavIndexProvider.notifier).state = 5;
                                        return;
                                      }
                                      _showArenaOptions(context, game, notifier);
                                    },
                                    onDelete: game.isAcademyActive ? () {} : () {
                                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                      notifier.deleteSavedGame(game.id);
                                    },
                                    onToggleFavorite: game.isAcademyActive ? () {} : () {
                                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                                      notifier.toggleFavorite(game.id);
                                    },
                                    onRename: game.isAcademyActive ? (_) {} : (newName) {
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
        ],
      ),
    ), // End of AmbientScaffold
   ); // End of PopScope
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
    required BuildContext context,
    bool isPulse = false,
  }) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final List<BoxShadow>? shadow;

    if (isSelected) {
      bgColor = activeColor.withValues(alpha: 0.15);
      borderColor = activeColor;
      textColor = activeColor;
      shadow = [
        BoxShadow(
          color: activeColor.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 2),
        )
      ];
    } else {
      bgColor = Colors.white.withValues(alpha: 0.35);
      borderColor = Colors.white.withValues(alpha: 0.5);
      textColor = ScholarlyTheme.textPrimary.withValues(alpha: 0.8);
      shadow = null;
    }

    final Widget tabContent = GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: 1.5,
          ),
          boxShadow: shadow,
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: textColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isPulse) {
      return FadeTransition(
        opacity: _pulseAnimation,
        child: tabContent,
      );
    }

    return tabContent;
  }

  void _showTabDropdown(BuildContext buttonContext, bool isAllTab) async {
    final RenderBox renderBox = buttonContext.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromLTWH(offset.dx, offset.dy + size.height + 4, size.width, size.height),
      Offset.zero & MediaQuery.of(buttonContext).size,
    );

    final result = await showMenu<HistorySubFilter>(
      context: buttonContext,
      position: position,
      color: ScholarlyTheme.panelBase,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ScholarlyTheme.panelStroke, width: 1.5),
      ),
      items: [
        PopupMenuItem(
          value: HistorySubFilter.none,
          child: Row(
            children: [
              const Icon(Icons.all_inclusive_rounded, size: 18, color: ScholarlyTheme.accentBlue),
              const SizedBox(width: 8),
              Text(
                isAllTab ? 'All Games' : 'All Favourites',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: HistorySubFilter.arena,
          child: Row(
            children: [
              const Icon(Icons.sports_esports_rounded, size: 18, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(
                'Arena (Unrated)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: HistorySubFilter.battleground,
          child: Row(
            children: [
              const Icon(Icons.flash_on_rounded, size: 18, color: ScholarlyTheme.realGold),
              const SizedBox(width: 8),
              Text(
                'Battleground (Rated)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: HistorySubFilter.academy,
          child: Row(
            children: [
              const Icon(Icons.school_rounded, size: 18, color: ScholarlyTheme.accentBlue),
              const SizedBox(width: 8),
              Text(
                'Academy (Learned)',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: ScholarlyTheme.textPrimary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (result != null) {
      setState(() {
        if (isAllTab) {
          _currentFilter = HistoryFilterType.all;
          _allSubFilter = result;
        } else {
          _currentFilter = HistoryFilterType.favorites;
          _favoritesSubFilter = result;
        }
      });
    }
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
        title: const Text('Clear Unrated Games?'),
        content: const Text('This will permanently delete all unrated saved games. Rated matches will be kept.'),
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
            child: const Text('Clear Unrated'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await notifier.clearUnratedHistory();
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
    buffer.writeln('[Site "IdeaSpace Chess Academy"]');
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
      final path = '${directory.path}/ideaspace_chess_academy_game_${game.id}.pgn';
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
      final path = '${directory.path}/ideaspace_chess_academy_game_${game.id}.pgn';
      final file = File(path);
      await file.writeAsString(pgnText);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'Here is my chess game notation from IdeaSpace Chess Academy!',
          subject: 'IdeaSpace Chess Academy Chess Game',
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

  void _showArenaOptions(
    BuildContext context,
    SavedGameEntry game,
    ChessNotifier notifier,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        child: JuicyGlassCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Option 1: RESUME MATCH
              InkWell(
                onTap: () {
                  ref.read(arenaProvider.notifier).loadSavedGame(game);
                  ref.read(mobileNavIndexProvider.notifier).state = 1;
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: ScholarlyTheme.accentBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RESUME MATCH',
                              style: GoogleFonts.outfit(
                                color: ScholarlyTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Resume playing this match in the Arena.',
                              style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: ScholarlyTheme.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option 2: CANCEL
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CANCEL',
                              style: GoogleFonts.outfit(
                                color: ScholarlyTheme.textMuted,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Go back to the archive list.',
                              style: GoogleFonts.inter(color: ScholarlyTheme.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: ScholarlyTheme.textMuted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
