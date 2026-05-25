import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../widgets/ambient_scaffold.dart';
import '../scholarly_theme.dart';
import '../../application/study_lab_provider.dart';
import '../../application/chess_provider.dart';
import '../../services/chess_sound_service.dart';
import 'analysis_board.dart';

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({super.key});

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final TextEditingController _pgnController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  int _lastSelectedNodeIndex = -999;
  String _libraryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(chessProvider.notifier).loadSavedGames());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pgnController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  int _getMoveNumberFromFen(String fen) {
    final parts = fen.split(' ');
    if (parts.length >= 6) {
      return int.tryParse(parts[5]) ?? 1;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyLabProvider);
    final notifier = ref.read(studyLabProvider.notifier);

    // Synchronize comments text area on active move node selection
    final activeNode = state.currentNodeIndex != null && state.currentNodeIndex! < state.nodes.length
        ? state.nodes[state.currentNodeIndex!]
        : null;
    final currentComment = activeNode?.comment ?? '';
    if (state.currentNodeIndex != _lastSelectedNodeIndex) {
      _lastSelectedNodeIndex = state.currentNodeIndex ?? -1;
      _commentController.text = currentComment;
    }

    // Synchronize raw PGN text area when moves are played on the board
    final pgnText = notifier.exportToPgn();
    if (_pgnController.text != pgnText && !FocusScope.of(context).hasFocus) {
      _pgnController.text = pgnText;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: const Color(0xFFF3E8FF), // Soft Purple
        blob2Color: const Color(0xFFDBEAFE), // Soft Blue
        blob3Color: const Color(0xFFFEF3C7), // Soft Amber
        body: Stack(
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth > 800;

                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: isWide ? 16 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),

                        // Wide Screen vs Mobile Portrait Layout
                        Expanded(
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left Column: Board + VCR Controls
                                    Expanded(
                                      flex: 5,
                                      child: LayoutBuilder(
                                        builder: (context, leftConstraints) {
                                          final maxBoardSize = math.min(
                                            leftConstraints.maxWidth,
                                            leftConstraints.maxHeight - 80,
                                          ).clamp(200.0, 1000.0);

                                          return Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              _buildBoardWithEval(context, state, notifier, maxBoardSize),
                                              const SizedBox(height: 12),
                                              _buildVcrControls(context, state, notifier),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    // Right Column: Tabbed Workspace
                                    Expanded(
                                      flex: 5,
                                      child: _buildWorkspaceTabsCard(context, state, notifier),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    // Top Area: Board + VCR
                                    Center(
                                      child: SizedBox(
                                        width: constraints.maxWidth - (isWide ? 32 : 24),
                                        child: Column(
                                          children: [
                                            _buildBoardWithEval(context, state, notifier, constraints.maxWidth - (isWide ? 32 : 24)),
                                            const SizedBox(height: 8),
                                            _buildVcrControls(context, state, notifier),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Bottom Area: Workspace tabs
                                    Expanded(
                                      child: _buildWorkspaceTabsCard(context, state, notifier),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoardWithEval(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
    double maxWidth,
  ) {
    return Center(
      child: StudyLabChessBoard(
        state: state,
        notifier: notifier,
        boardSize: maxWidth,
      ),
    );
  }

  // Navigation controller bar below the board
  Widget _buildVcrControls(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      borderRadius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _VcrButton(
            icon: Icons.first_page_rounded,
            tooltip: 'Go to Start',
            onTap: state.currentNodeIndex != null
                ? () {
                    notifier.selectNode(null);
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                  }
                : null,
          ),
          _VcrButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Undo Move',
            onTap: state.canUndo
                ? () {
                    notifier.undo();
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                  }
                : null,
          ),
          _VcrButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Redo Move',
            onTap: state.canRedo
                ? () {
                    notifier.redo();
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                  }
                : null,
          ),
          _VcrButton(
            icon: Icons.last_page_rounded,
            tooltip: 'Go to End',
            onTap: state.canRedo
                ? () {
                    // Navigate down the first child line recursively to the end
                    int? current = state.currentNodeIndex;
                    while (true) {
                      final children = current == null
                          ? state.nodes.where((n) => n.parentIndex == null).toList()
                          : state.nodes[current].childIndices.map((idx) => state.nodes[idx]).toList();
                      if (children.isEmpty) break;
                      current = children.first.index;
                    }
                    notifier.selectNode(current);
                    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                  }
                : null,
          ),
          _VcrButton(
            icon: Icons.flip_camera_android_rounded,
            tooltip: 'Flip Board',
            isActive: state.isBoardFlipped,
            onTap: () {
              notifier.flipBoard();
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
            },
          ),
          _VcrButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Reset Position',
            onTap: state.nodes.isNotEmpty
                ? () {
                    _showResetConfirmation(context, notifier);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // Shows confirmation modal before wiping out study notes and moves
  void _showResetConfirmation(BuildContext context, StudyLabNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Reset Analysis Board?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: ScholarlyTheme.textPrimary),
        ),
        content: Text(
          'This will clear all moves, custom variations, and move annotations. Do you want to continue?',
          style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: ScholarlyTheme.textMuted)),
          ),
          FilledButton(
            onPressed: () {
              notifier.clearBoard();
              Navigator.pop(context);
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Clear Everything', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Creates the premium tabbed workspace cards displaying moves, annotations, and PGN texts
  Widget _buildWorkspaceTabsCard(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    return Column(
      children: [
        // Tabs row
        JuicyGlassCard(
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3)),
            ),
            labelColor: ScholarlyTheme.accentBlue,
            unselectedLabelColor: ScholarlyTheme.textPrimary.withValues(alpha: 0.7),
            labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Move Tree'),
              Tab(text: 'Game Library'),
              Tab(text: 'Raw PGN'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Tabs content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMoveTreeTab(context, state, notifier),
              _buildSavedGamesTab(context, state, notifier),
              _buildRawPgnTab(context, state, notifier),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavedGamesTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    final chessState = ref.watch(chessProvider);
    final eligibleGames = chessState.savedGames.where((s) => s.recentMoves.isNotEmpty).toList();

    var filteredGames = eligibleGames;
    if (_libraryFilter == 'Arena') {
      filteredGames = eligibleGames.where((g) => !g.isRatedMode).toList();
    } else if (_libraryFilter == 'Battleground') {
      filteredGames = eligibleGames.where((g) => g.isRatedMode).toList();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Chips Row
          JuicyGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLibraryFilterChip('All', _libraryFilter == 'All'),
                _buildLibraryFilterChip('Arena', _libraryFilter == 'Arena'),
                _buildLibraryFilterChip('Battleground', _libraryFilter == 'Battleground'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Games List Box
          JuicyGlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.library_books_rounded, size: 14, color: ScholarlyTheme.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      'AVAILABLE GAMES (${filteredGames.length})',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.accentBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                filteredGames.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          'No eligible saved games found in this category.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredGames.length,
                        separatorBuilder: (context, index) => Divider(
                          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4),
                          height: 16,
                        ),
                        itemBuilder: (context, index) {
                          final game = filteredGames[index];
                          final shortId = game.id.length >= 4 ? game.id.substring(0, 4) : game.id;
                          final name = game.customName?.isNotEmpty == true ? game.customName! : 'Game #$shortId';
                          final formattedDate = DateFormat('MMM d, h:mm a').format(game.savedAt);

                          return Row(
                            children: [
                              // Icon for game type
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: game.isRatedMode
                                      ? ScholarlyTheme.accentBlue.withValues(alpha: 0.1)
                                      : ScholarlyTheme.realGold.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  game.isRatedMode ? Icons.emoji_events_rounded : Icons.sports_esports_rounded,
                                  color: game.isRatedMode ? ScholarlyTheme.accentBlue : ScholarlyTheme.realGold,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Game info details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.inter(
                                        color: ScholarlyTheme.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Text(
                                          '$formattedDate • ${game.recentMoves.length} moves',
                                          style: GoogleFonts.inter(
                                            color: ScholarlyTheme.textMuted,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (game.isLockedForAnalysis) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.lock_rounded, size: 8, color: Colors.redAccent),
                                                const SizedBox(width: 2),
                                                Text(
                                                  'LOCKED',
                                                  style: GoogleFonts.inter(
                                                    color: Colors.redAccent,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Action button to load/pull
                              ElevatedButton(
                                onPressed: () async {
                                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                                  
                                  // 1. Pull/load into study lab
                                  notifier.loadGameEntry(game);
                                  
                                  // 2. Lock if Arena game and not locked
                                  bool lockedNow = false;
                                  if (!game.isRatedMode && !game.isLockedForAnalysis) {
                                    await ref.read(chessProvider.notifier).lockGameForAnalysis(game.id);
                                    lockedNow = true;
                                  }

                                  // 3. Switch back to Move Tree tab (index 0)
                                  _tabController.animateTo(0);

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          lockedNow 
                                              ? 'Arena game loaded and locked from replay.'
                                              : 'Saved game loaded for analysis.',
                                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: ScholarlyTheme.accentBlue,
                                        behavior: SnackBarBehavior.floating,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ScholarlyTheme.accentBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  'PULL',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryFilterChip(String label, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
          setState(() {
            _libraryFilter = label;
          });
        }
      },
      selectedColor: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 11,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: isSelected ? ScholarlyTheme.accentBlue : Colors.transparent),
      backgroundColor: Colors.transparent,
    );
  }

  // Tab 1: Structured recursive move tree visualizer, annotations textarea, and GM Chanakya handoff button
  Widget _buildMoveTreeTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    final List<Widget> moveChips = [];
    _buildMoveTreeChips(state, notifier, null, moveChips, 0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Move Tree Box
          JuicyGlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schema_rounded, size: 14, color: ScholarlyTheme.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      'STUDY LAB FLOW',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.accentBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (state.commentary != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          state.commentary!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.accentBlue,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                moveChips.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Text(
                          'No moves played yet. Play some moves on the board to build a variation tree!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 2,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: moveChips,
                      ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Move Comments / Annotation Box
          JuicyGlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_note_rounded, size: 14, color: ScholarlyTheme.accentGold),
                    const SizedBox(width: 4),
                    Text(
                      'MOVE ANNOTATION',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.accentGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (state.currentNodeIndex != null)
                      TextButton.icon(
                        onPressed: () {
                          notifier.deleteCurrentNode();
                          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                        },
                        icon: const Icon(Icons.delete_sweep_rounded, size: 13, color: Colors.redAccent),
                        label: Text(
                          'Delete Branch',
                          style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                state.currentNodeIndex == null
                    ? Text(
                        'Select a move in the flow above to add study notes.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: ScholarlyTheme.textMuted,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _commentController,
                            maxLines: 3,
                            style: GoogleFonts.inter(fontSize: 13, color: ScholarlyTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Add tactical themes, coach recommendations or memory cues...',
                              hintStyle: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textSubtle),
                              filled: true,
                              fillColor: Colors.white24,
                              contentPadding: const EdgeInsets.all(10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: ScholarlyTheme.panelStroke),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: ScholarlyTheme.accentBlue),
                              ),
                            ),
                            onChanged: (text) {
                              notifier.updateComment(text);
                            },
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Traverses the variation node tree recursively to produce formatted interactive widgets
  void _buildMoveTreeChips(
    StudyLabState state,
    StudyLabNotifier notifier,
    int? parentIdx,
    List<Widget> chips,
    int depth,
  ) {
    final children = state.nodes.where((n) => n.parentIndex == parentIdx).toList();
    if (children.isEmpty) return;

    // First child represents the "mainline" for this local branch
    final mainNode = children.first;
    final moveNumber = _getMoveNumberFromFen(mainNode.fen);
    final isWhite = !mainNode.fen.contains(' b ');

    if (isWhite) {
      chips.add(Text(' $moveNumber.', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)));
    } else if (parentIdx == null) {
      chips.add(Text(' ${moveNumber - 1}...', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)));
    }

    final isCurrent = state.currentNodeIndex == mainNode.index;
    chips.add(
      GestureDetector(
        onTap: () {
          notifier.selectNode(mainNode.index);
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isCurrent ? ScholarlyTheme.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCurrent ? ScholarlyTheme.accentBlue : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            mainNode.san,
            style: GoogleFonts.inter(
              color: isCurrent ? Colors.white : ScholarlyTheme.textPrimary,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );

    // Build alternative side-lines played from the same position inside parentheses
    for (int i = 1; i < children.length; i++) {
      final sideNode = children[i];
      chips.add(Text(' (', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 13)));
      
      final isSideCurrent = state.currentNodeIndex == sideNode.index;
      chips.add(
        GestureDetector(
          onTap: () {
            notifier.selectNode(sideNode.index);
            ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isSideCurrent ? ScholarlyTheme.accentBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              sideNode.san,
              style: GoogleFonts.inter(
                color: isSideCurrent ? Colors.white : ScholarlyTheme.textMuted,
                fontWeight: isSideCurrent ? FontWeight.bold : FontWeight.w500,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );

      _buildSidelineRecursive(state, notifier, sideNode.index, chips);
      chips.add(Text(') ', style: GoogleFonts.inter(color: ScholarlyTheme.textSubtle, fontSize: 13)));
    }

    // Continue down the main line branch
    final nextNodes = mainNode.childIndices.map((idx) => state.nodes[idx]).toList();
    if (nextNodes.isNotEmpty) {
      _buildMoveTreeChips(state, notifier, mainNode.index, chips, depth);
    }
  }

  // Traverses simple sequential moves down a sidelist inside a parenthesis block
  void _buildSidelineRecursive(StudyLabState state, StudyLabNotifier notifier, int nodeIdx, List<Widget> chips) {
    final node = state.nodes[nodeIdx];
    if (node.childIndices.isEmpty) return;

    final nextNode = state.nodes[node.childIndices.first];
    final moveNum = _getMoveNumberFromFen(nextNode.fen);
    final isWhite = !nextNode.fen.contains(' b ');

    if (isWhite) {
      chips.add(Text(' $moveNum.', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textSubtle, fontSize: 12)));
    } else {
      chips.add(Text(' $moveNum...', style: GoogleFonts.jetBrainsMono(color: ScholarlyTheme.textSubtle, fontSize: 12)));
    }

    final isCurrent = state.currentNodeIndex == nextNode.index;
    chips.add(
      GestureDetector(
        onTap: () {
          notifier.selectNode(nextNode.index);
          ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
          decoration: BoxDecoration(
            color: isCurrent ? ScholarlyTheme.accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            nextNode.san,
            style: GoogleFonts.inter(
              color: isCurrent ? Colors.white : ScholarlyTheme.textMuted,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );

    _buildSidelineRecursive(state, notifier, nextNode.index, chips);
  }



  // Tab 3: Bi-directional Raw PGN text sync editor, clipboard copying, and load buttons
  Widget _buildRawPgnTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // PGN Text field Card
          JuicyGlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_snippet_rounded, size: 14, color: ScholarlyTheme.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      'PGN TEXT EDITOR',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ScholarlyTheme.accentBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _pgnController,
                  maxLines: 7,
                  style: GoogleFonts.jetBrainsMono(fontSize: 11, color: ScholarlyTheme.textPrimary, height: 1.4),
                  decoration: InputDecoration(
                    hintText: 'Paste a standard raw PGN tournament game here and click "LOAD PGN" to import...',
                    hintStyle: GoogleFonts.inter(fontSize: 11, color: ScholarlyTheme.textSubtle),
                    filled: true,
                    fillColor: Colors.white24,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ScholarlyTheme.panelStroke),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: ScholarlyTheme.accentBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // PGN Action Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D6EFD), Color(0xFF0056B3)],
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final text = _pgnController.text.trim();
                      if (text.isNotEmpty) {
                        notifier.importPgn(text);
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('PGN Game imported successfully!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                            backgroundColor: ScholarlyTheme.accentBlue,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.file_upload_rounded, size: 16, color: Colors.white),
                    label: Text(
                      'LOAD PGN',
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white24,
                    border: Border.all(color: ScholarlyTheme.panelStroke),
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final exported = notifier.exportToPgn();
                      Clipboard.setData(ClipboardData(text: exported));
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('PGN copied to clipboard!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                          backgroundColor: ScholarlyTheme.textPrimary,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.content_copy_rounded, size: 16, color: ScholarlyTheme.textPrimary),
                    label: Text(
                      'COPY PGN',
                      style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}





// Simple VCR controller button builder
class _VcrButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isActive;

  const _VcrButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = onTap != null;

    final color = isActive
        ? ScholarlyTheme.accentBlue
        : isEnabled
            ? ScholarlyTheme.textPrimary
            : ScholarlyTheme.textSubtle;

    final backgroundColor = isActive
        ? ScholarlyTheme.accentBlue.withValues(alpha: 0.1)
        : Colors.transparent;

    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
