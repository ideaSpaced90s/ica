import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

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

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _libraryFilter = 'All';
  bool _isWorkspaceOpen = false;
  int _workspaceTabIndex = 0; // 0 = Move Tree, 1 = Impo/Expo, 2 = Game Library
  String? _activeGameId;
  final Set<String> _pulledGameIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chessProvider.notifier).loadSavedGames());
  }

  @override
  void dispose() {
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_isWorkspaceOpen) {
          setState(() {
            _isWorkspaceOpen = false;
          });
          return;
        }
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
                        // The Chessboard section (Expanded to fill available space)
                        Expanded(
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, boardConstraints) {
                                final maxBoardSize = math.min(
                                  boardConstraints.maxWidth,
                                  boardConstraints.maxHeight - 80,
                                ).clamp(200.0, 1000.0);
                                return _buildBoardWithEval(context, state, notifier, maxBoardSize);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // VCR Controls
                        _buildVcrControls(context, state, notifier),
                        const SizedBox(height: 8),
                        // Action/Settings Bar at the bottom
                        _buildActionBar(context),
                        const SizedBox(height: 12),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Backdrop Blur Overlay for Settings/Workspace Tabs
            if (_isWorkspaceOpen)
              _buildWorkspaceOverlay(context, state, notifier),
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

  Widget _buildActionBar(BuildContext context) {
    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(
              Icons.schema_rounded,
              color: ScholarlyTheme.accentBlue,
              size: 26,
            ),
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              setState(() {
                _workspaceTabIndex = 0;
                _isWorkspaceOpen = true;
              });
            },
            tooltip: 'Move Tree Flow',
          ),
          IconButton(
            icon: const Icon(
              Icons.import_export_rounded,
              color: Colors.teal,
              size: 28,
            ),
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              setState(() {
                _workspaceTabIndex = 1;
                _isWorkspaceOpen = true;
              });
            },
            tooltip: 'Import / Export PGN',
          ),
          IconButton(
            icon: const Icon(
              Icons.library_books_rounded,
              color: ScholarlyTheme.realGold,
              size: 26,
            ),
            onPressed: () {
              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              setState(() {
                _workspaceTabIndex = 2;
                _isWorkspaceOpen = true;
              });
            },
            tooltip: 'Game Library',
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspaceOverlay(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    String title = 'WORKSPACE';
    Widget overlayBody = const SizedBox.shrink();

    switch (_workspaceTabIndex) {
      case 0:
        title = 'MOVE TREE';
        overlayBody = _buildMoveTreeOverlayTab(context, state, notifier);
        break;
      case 1:
        title = 'IMPORT / EXPORT';
        overlayBody = _buildImpoExpoOverlayTab(context, state, notifier);
        break;
      case 2:
        title = 'GAME LIBRARY';
        overlayBody = _buildGameLibraryOverlayTab(context, state, notifier);
        break;
    }

    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isWorkspaceOpen = false;
          });
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: GestureDetector(
              onTap: () {}, // Prevent tap from closing when clicking inside panel
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header Row
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.close_rounded,
                              color: ScholarlyTheme.textPrimary,
                              size: 28,
                            ),
                            onPressed: () {
                              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                              setState(() {
                                _isWorkspaceOpen = false;
                              });
                            },
                          ),
                          const Spacer(),
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              color: ScholarlyTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(width: 48), // Balancing size of close button
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Render body directly
                      Expanded(
                        child: overlayBody,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoveTreeOverlayTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    final List<Widget> moveChips = [];
    _buildMoveTreeChips(state, notifier, null, moveChips, 0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: JuicyGlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schema_rounded, size: 16, color: ScholarlyTheme.accentBlue),
                const SizedBox(width: 6),
                Text(
                  'STUDY LAB FLOW',
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
            const SizedBox(height: 12),
            moveChips.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Text(
                      'No moves played yet. Play some moves on the board to build a variation tree!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
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
    );
  }

  Widget _buildImpoExpoOverlayTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    final chessState = ref.watch(chessProvider);
    final eligibleGames = chessState.savedGames.where((s) => s.recentMoves.isNotEmpty).toList();

    // Filter out games that are already pulled
    final availableGames = eligibleGames.where((g) => !_pulledGameIds.contains(g.id)).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  title: 'IMPORT PGN',
                  subtitle: 'Select PGN File',
                  icon: Icons.file_upload_rounded,
                  color: ScholarlyTheme.accentBlue,
                  onTap: () => _importPgnFromFile(context, notifier),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionTile(
                  title: 'EXPORT PGN',
                  subtitle: 'Save to Downloads',
                  icon: Icons.file_download_rounded,
                  color: Colors.teal,
                  onTap: () => _exportPgnToDownloads(context, notifier),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          JuicyGlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.library_books_rounded, size: 14, color: ScholarlyTheme.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      'AVAILABLE SAVED GAMES (${availableGames.length})',
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
                availableGames.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          'No available saved games to pull.',
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
                        itemCount: availableGames.length,
                        separatorBuilder: (context, index) => Divider(
                          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.4),
                          height: 16,
                        ),
                        itemBuilder: (context, index) {
                          final game = availableGames[index];
                          final shortId = game.id.length >= 4 ? game.id.substring(0, 4) : game.id;
                          final name = game.customName?.isNotEmpty == true ? game.customName! : 'Game #$shortId';
                          final formattedDate = DateFormat('MMM d, h:mm a').format(game.savedAt);

                          return Row(
                            children: [
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
                              ElevatedButton(
                                onPressed: () async {
                                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);

                                  notifier.loadGameEntry(game);

                                  setState(() {
                                    _pulledGameIds.add(game.id);
                                    _activeGameId = game.id;
                                  });

                                  if (!game.isRatedMode && !game.isLockedForAnalysis) {
                                    await ref.read(chessProvider.notifier).lockGameForAnalysis(game.id);
                                  }

                                  setState(() {
                                    _workspaceTabIndex = 0;
                                  });

                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Game pulled and loaded successfully!',
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

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: JuicyGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        borderRadius: 16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: ScholarlyTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameLibraryOverlayTab(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
  ) {
    final chessState = ref.watch(chessProvider);
    final eligibleGames = chessState.savedGames.where((s) => s.recentMoves.isNotEmpty).toList();

    final pulledGames = eligibleGames.where((g) => _pulledGameIds.contains(g.id)).toList();

    var filteredGames = pulledGames;
    if (_libraryFilter == 'Arena') {
      filteredGames = pulledGames.where((g) => !g.isRatedMode).toList();
    } else if (_libraryFilter == 'Battleground') {
      filteredGames = pulledGames.where((g) => g.isRatedMode).toList();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          JuicyGlassCard(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.library_books_rounded, size: 14, color: ScholarlyTheme.accentBlue),
                    const SizedBox(width: 4),
                    Text(
                      'PULLED GAMES (${filteredGames.length})',
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
                          'No pulled games. Pull a saved game from the Impo/Expo tab first!',
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
                          final isActive = _activeGameId == game.id;

                          return Row(
                            children: [
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
                                        if (isActive) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'ACTIVE',
                                              style: GoogleFonts.inter(
                                                color: Colors.green,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                                  if (isActive) {
                                    notifier.clearBoard();
                                    setState(() {
                                      _activeGameId = null;
                                    });
                                  } else {
                                    notifier.loadGameEntry(game);
                                    setState(() {
                                      _activeGameId = game.id;
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isActive ? Colors.green : ScholarlyTheme.accentBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  isActive ? 'SAVED' : 'PULL',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () {
                                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                                  setState(() {
                                    _pulledGameIds.remove(game.id);
                                    if (isActive) {
                                      notifier.clearBoard();
                                      _activeGameId = null;
                                    }
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Game removed from Library and returned to Impo/Expo.',
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                      ),
                                      backgroundColor: Colors.redAccent,
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                                tooltip: 'Remove from Game Library',
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

  Future<void> _importPgnFromFile(BuildContext context, StudyLabNotifier notifier) async {
    try {
      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pgn'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final pgnContent = await file.readAsString();

        if (pgnContent.trim().isNotEmpty) {
          notifier.importPgn(pgnContent);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'PGN Game imported successfully!',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: ScholarlyTheme.accentBlue,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
            setState(() {
              _workspaceTabIndex = 0;
            });
          }
        } else {
          throw Exception('The selected file is empty.');
        }
      }
    } catch (e) {
      debugPrint('PGN Import failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PGN Import failed: $e', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _exportPgnToDownloads(BuildContext context, StudyLabNotifier notifier) async {
    try {
      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
      final pgnText = notifier.exportToPgn();
      if (pgnText.trim().isEmpty || pgnText == '*') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No moves to export!',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      directory ??= await getApplicationDocumentsDirectory();

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final path = '${directory.path}/kingslayer_analysis_$timestamp.pgn';
      final file = File(path);
      await file.writeAsString(pgnText);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PGN exported to: $path',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('PGN Export failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PGN Export failed: $e', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
