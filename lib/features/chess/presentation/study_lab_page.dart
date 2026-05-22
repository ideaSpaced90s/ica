import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;


import 'widgets/ambient_scaffold.dart';
import 'scholarly_theme.dart';
import 'themes/theme_registry.dart';
import '../application/study_lab_provider.dart';
import '../application/chess_provider.dart';
import '../services/chess_sound_service.dart';
import '../application/onboarding_provider.dart';

class StudyLabPage extends ConsumerStatefulWidget {
  const StudyLabPage({super.key});

  @override
  ConsumerState<StudyLabPage> createState() => _StudyLabPageState();
}

class _StudyLabPageState extends ConsumerState<StudyLabPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  final TextEditingController _pgnController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  int _lastSelectedNodeIndex = -999;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
              key: analysisPageKey,
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
              _buildRawPgnTab(context, state, notifier),
            ],
          ),
        ),
      ],
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



// Custom study board supporting tap selections, drag-and-drop, pawn promotions, and coordinates
class StudyLabChessBoard extends ConsumerStatefulWidget {
  final StudyLabState state;
  final StudyLabNotifier notifier;
  final double boardSize;

  const StudyLabChessBoard({
    super.key,
    required this.state,
    required this.notifier,
    required this.boardSize,
  });

  @override
  ConsumerState<StudyLabChessBoard> createState() => _StudyLabChessBoardState();
}

class _StudyLabChessBoardState extends ConsumerState<StudyLabChessBoard> {
  String? _selectedSquare;
  List<String> _legalTargets = const [];
  String? _pendingPromoFrom;
  String? _pendingPromoTo;

  @override
  void didUpdateWidget(StudyLabChessBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.activeFen != widget.state.activeFen) {
      _selectedSquare = null;
      _legalTargets = const [];
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedSquare = null;
      _legalTargets = const [];
    });
  }

  String _getSquareName(int row, int col, bool isFlipped) {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    final fileIndex = isFlipped ? 7 - col : col;
    final rankIndex = isFlipped ? 7 - row : row;
    return '${files[fileIndex]}${ranks[rankIndex]}';
  }

  Widget _buildCoordinatesForSquare(int row, int col, bool isLight, bool isFlipped) {
    final showFile = isFlipped ? row == 0 : row == 7;
    final showRank = isFlipped ? col == 7 : col == 0;

    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    const ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

    final fileIndex = isFlipped ? 7 - col : col;
    final rankIndex = isFlipped ? 7 - row : row;

    final color = isLight ? ScholarlyTheme.textMuted : Colors.white.withValues(alpha: 0.7);

    return Stack(
      children: [
        if (showFile)
          Positioned(
            bottom: 2,
            right: 4,
            child: Text(
              files[fileIndex],
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        if (showRank)
          Positioned(
            top: 2,
            left: 4,
            child: Text(
              ranks[rankIndex],
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
      ],
    );
  }

  void _handleSquareTap(String squareName, chess_lib.Chess chess) {
    if (_selectedSquare != null && _legalTargets.contains(squareName)) {
      _handleMove(_selectedSquare!, squareName, chess);
    } else {
      final piece = chess.get(squareName);
      if (piece != null) {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiTap);
        setState(() {
          _selectedSquare = squareName;
          _legalTargets = chess.generate_moves({'square': squareName})
              .map((m) => chess_lib.Chess.algebraic(m.to))
              .toList();
        });
      } else {
        _clearSelection();
      }
    }
  }

  void _handleMove(String from, String to, chess_lib.Chess chess) {
    final piece = chess.get(from);
    final isPawn = piece?.type == chess_lib.PieceType.PAWN;
    final isWhite = piece?.color == chess_lib.Color.WHITE;
    final isPromo = isPawn && ((isWhite && to.endsWith('8')) || (!isWhite && to.endsWith('1')));

    if (isPromo) {
      setState(() {
        _pendingPromoFrom = from;
        _pendingPromoTo = to;
      });
    } else {
      final isCapture = chess.get(to) != null;
      widget.notifier.makeMove(from, to);
      
      if (isCapture) {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.capture);
      } else {
        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.move);
      }
      ref.read(chessHapticsServiceProvider).selection();
      _clearSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chessState = ref.watch(chessProvider);
    final themeId = ThemeRegistry.resolveThemeId(chessState);
    final theme = ThemeRegistry.getTheme(themeId);

    final chess = chess_lib.Chess.fromFEN(widget.state.activeFen);
    final squareSize = widget.boardSize / 8;

    String? lastMoveFrom;
    String? lastMoveTo;
    if (widget.state.currentNodeIndex != null && widget.state.currentNodeIndex! < widget.state.nodes.length) {
      final activeNode = widget.state.nodes[widget.state.currentNodeIndex!];
      if (activeNode.uci.length >= 4) {
        lastMoveFrom = activeNode.uci.substring(0, 2);
        lastMoveTo = activeNode.uci.substring(2, 4);
      }
    }

    return Container(
      width: widget.boardSize,
      height: widget.boardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: ScholarlyTheme.boardShadow,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background board frame / theme
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: theme.buildBackground(context, true),
          ),
          
          // Grid layer
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 64,
              itemBuilder: (context, index) {
                final row = index ~/ 8;
                final col = index % 8;
                final isLight = (row + col) % 2 == 0;
                final squareName = _getSquareName(row, col, widget.state.isBoardFlipped);

                final isSelected = _selectedSquare == squareName;
                final isTarget = _legalTargets.contains(squareName);
                final isLastStart = lastMoveFrom == squareName;
                final isLastEnd = lastMoveTo == squareName;

                final piece = chess.get(squareName);
                
                String? pieceCode;
                if (piece != null) {
                  final colorPrefix = piece.color == chess_lib.Color.WHITE ? 'w' : 'b';
                  final typeStr = piece.type.toString().toUpperCase();
                  pieceCode = '$colorPrefix$typeStr';
                }

                return DragTarget<String>(
                  onWillAcceptWithDetails: (details) => _legalTargets.contains(squareName),
                  onAcceptWithDetails: (details) {
                    _handleMove(details.data, squareName, chess);
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isDragHover = candidateData.isNotEmpty;

                    Widget squareChild = Stack(
                      children: [
                        // Custom painter if theme defined
                        if (theme.getSquarePainter(isLight, 0) != null)
                          CustomPaint(
                            painter: theme.getSquarePainter(isLight, 0.0),
                            size: Size.infinite,
                          ),
                          
                        // Sibling last played move highlights
                        if (isLastStart || isLastEnd)
                          Container(
                            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.12),
                            decoration: isLastEnd ? BoxDecoration(
                              border: Border.all(color: ScholarlyTheme.accentBlue.withValues(alpha: 0.5), width: 1.5),
                            ) : null,
                          ),

                        // Selection glowing overlay
                        if (isSelected)
                          Container(
                            color: ScholarlyTheme.selectedGlow.withValues(alpha: 0.2),
                          ),

                        // Drag hover highlighted square
                        if (isDragHover)
                          Container(
                            color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.35),
                          ),

                        // Render piece inside the square
                        if (pieceCode != null)
                          Center(
                            child: Draggable<String>(
                              data: squareName,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: squareSize * 1.2,
                                  height: squareSize * 1.2,
                                  child: theme.buildPiece(context, pieceCode.substring(1), pieceCode.startsWith('w'), false, 0),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.35,
                                child: theme.buildPiece(context, pieceCode.substring(1), pieceCode.startsWith('w'), false, 0),
                              ),
                              child: GestureDetector(
                                onTap: () => _handleSquareTap(squareName, chess),
                                child: theme.buildPiece(
                                  context, 
                                  pieceCode.substring(1), 
                                  pieceCode.startsWith('w'), 
                                  isSelected, 
                                  0
                                ),
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _handleSquareTap(squareName, chess),
                            child: const SizedBox.expand(),
                          ),

                        // Interactive target dot indicators
                        if (isTarget)
                          Center(
                            child: Container(
                              width: pieceCode != null ? 22 : 12,
                              height: pieceCode != null ? 22 : 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: pieceCode != null 
                                    ? Colors.transparent 
                                    : ScholarlyTheme.accentBlue.withValues(alpha: 0.5),
                                border: pieceCode != null 
                                    ? Border.all(color: ScholarlyTheme.accentBlue, width: 2.2) 
                                    : null,
                              ),
                            ),
                          ),

                        // Board coordinate labeling
                        _buildCoordinatesForSquare(row, col, isLight, widget.state.isBoardFlipped),
                      ],
                    );

                    return Container(
                      decoration: BoxDecoration(
                        color: isLight ? theme.lightSquare : theme.darkSquare,
                      ),
                      child: squareChild,
                    );
                  },
                );
              },
            ),
          ),

          // Glowing Promotion Overlay over the grid board
          if (_pendingPromoFrom != null && _pendingPromoTo != null) ...[
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1.5),
                      boxShadow: ScholarlyTheme.cardShadow,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CHOOSE ASCENSION',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1.5,
                            color: ScholarlyTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: ['Q', 'N', 'R', 'B'].map((type) {
                            final isWhite = chess.get(_pendingPromoFrom!)?.color == chess_lib.Color.WHITE;
                            return GestureDetector(
                              onTap: () {
                                widget.notifier.makeMove(
                                  _pendingPromoFrom!,
                                  _pendingPromoTo!,
                                  type.toLowerCase(),
                                );
                                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.pieceLand);
                                setState(() {
                                  _pendingPromoFrom = null;
                                  _pendingPromoTo = null;
                                  _selectedSquare = null;
                                  _legalTargets = const [];
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: ScholarlyTheme.panelStroke, width: 1.2),
                                  boxShadow: ScholarlyTheme.cardShadow,
                                ),
                                padding: const EdgeInsets.all(6),
                                child: theme.buildPiece(context, type, isWhite, false, 0),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
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
