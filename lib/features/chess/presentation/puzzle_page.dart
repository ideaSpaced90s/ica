import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'widgets/board_stage.dart';
import 'widgets/ambient_scaffold.dart';
import 'dashboard_page.dart';
import 'dart:ui';

class PuzzlePage extends ConsumerStatefulWidget {
  const PuzzlePage({super.key});

  @override
  ConsumerState<PuzzlePage> createState() => _PuzzlePageState();
}

class _PuzzlePageState extends ConsumerState<PuzzlePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(chessProvider.notifier).startPuzzleMode(silent: true);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _requestExitPuzzle() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Exit Puzzle Mode?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
        content: Text(
          'Do you want to exit the puzzle environment and return to the dashboard?',
          style: GoogleFonts.inter(
            color: ScholarlyTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Stay',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Exit Puzzles',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      exitToDashboardWithSidebar(context, ref);
    }
  }

  Widget _buildMoveLog(BuildContext context, ChessState state) {
    final moves = state.recentMoves;
    if (moves.isEmpty) {
      return const Center(
        child: Text(
          'No moves yet.',
          style: TextStyle(
            color: ScholarlyTheme.textMuted,
            fontSize: 13,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final List<List<String>> pairs = [];
    for (int i = 0; i < moves.length; i += 2) {
      pairs.add([moves[i], if (i + 1 < moves.length) moves[i + 1]]);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: pairs.length,
      itemBuilder: (context, index) {
        final pair = pairs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${index + 1}.',
                  style: GoogleFonts.jetBrainsMono(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    pair[0],
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (pair.length > 1)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pair[1],
                      style: GoogleFonts.inter(
                        color: ScholarlyTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ChessState state,
    ChessNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Board
        const AspectRatio(
          aspectRatio: 1.0,
          child: BoardStage(isExpanded: true),
        ),
        
        // 2. Puzzle Info & Move Log
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PuzzleStatusHeader(state: state),
                const SizedBox(height: 12),
                Expanded(
                  child: JuicyGlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          child: Text(
                            'MOVE SEQUENCE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: ScholarlyTheme.textSubtle,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const Divider(color: ScholarlyTheme.panelStroke),
                        Expanded(
                          child: _buildMoveLog(context, state),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: JuicyGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            borderRadius: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CompactActionIcon(
                  icon: Icons.skip_next_rounded,
                  tooltip: 'Next Puzzle',
                  onTap: () => notifier.nextPuzzle(silent: true),
                ),
                _CompactActionIcon(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Reset',
                  onTap: () => notifier.resetPuzzleLine(),
                ),
                _CompactActionIcon(
                  icon: Icons.flip_camera_android_outlined,
                  tooltip: 'Flip',
                  isActive: state.isBoardFlipped,
                  onTap: () => notifier.toggleBoardOrientation(),
                ),
                _CompactActionIcon(
                  icon: state.isBulbGlowing
                      ? Icons.lightbulb_rounded
                      : Icons.lightbulb_outline_rounded,
                  tooltip: 'Hint',
                  isEnabled: !state.isHintLoading,
                  isActive: state.isBulbGlowing,
                  activeColor: ScholarlyTheme.accentYellowSoft,
                  activeIconColor: ScholarlyTheme.accentYellow,
                  onTap: () => notifier.requestHint(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ChessState state,
    ChessNotifier notifier,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT COLUMN (Chessboard Area) - taking 55% of the space
        Expanded(
          flex: 11,
          child: const Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: BoardStage(isExpanded: true),
            ),
          ),
        ),

        // VERTICAL SEPARATOR
        Container(
          width: 1.5,
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
        ),

        // RIGHT COLUMN (Sidebar Area) - taking 45% of the space
        Expanded(
          flex: 9,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Puzzle Status Header
                _PuzzleStatusHeader(state: state),
                const SizedBox(height: 12),

                // 2. Move Log
                Expanded(
                  child: JuicyGlassCard(
                    borderRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          child: Text(
                            'MOVE SEQUENCE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: ScholarlyTheme.textSubtle,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const Divider(color: ScholarlyTheme.panelStroke),
                        Expanded(
                          child: _buildMoveLog(context, state),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Actions Row
                JuicyGlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderRadius: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CompactActionIcon(
                        icon: Icons.skip_next_rounded,
                        tooltip: 'Next Puzzle',
                        onTap: () => notifier.nextPuzzle(silent: true),
                      ),
                      _CompactActionIcon(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Reset',
                        onTap: () => notifier.resetPuzzleLine(),
                      ),
                      _CompactActionIcon(
                        icon: Icons.flip_camera_android_outlined,
                        tooltip: 'Flip',
                        isActive: state.isBoardFlipped,
                        onTap: () => notifier.toggleBoardOrientation(),
                      ),
                      _CompactActionIcon(
                        icon: state.isBulbGlowing
                            ? Icons.lightbulb_rounded
                            : Icons.lightbulb_outline_rounded,
                        tooltip: 'Hint',
                        isEnabled: !state.isHintLoading,
                        isActive: state.isBulbGlowing,
                        activeColor: ScholarlyTheme.accentYellowSoft,
                        activeIconColor: ScholarlyTheme.accentYellow,
                        onTap: () => notifier.requestHint(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);
    final isLandscape = MediaQuery.of(context).size.width > MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        await _requestExitPuzzle();
      },
      child: AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: const Color(0xFFF0F9FF), // Very light blue
        blob2Color: const Color(0xFFFDF2F8), // Very light pink
        blob3Color: const Color(0xFFFFFBEB), // Very light amber
        body: SafeArea(
          top: false,
          child: isLandscape
              ? _buildLandscapeLayout(context, state, notifier)
              : _buildPortraitLayout(context, state, notifier),
        ),
      ),
    );
  }
}

class _PuzzleStatusHeader extends ConsumerWidget {
  final ChessState state;

  const _PuzzleStatusHeader({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = state.currentPuzzle;
    final bool isSolved = state.puzzleMovesRemaining.isEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSolved 
                ? Colors.green.withValues(alpha: 0.1) 
                : ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSolved 
                  ? Colors.greenAccent.withValues(alpha: 0.3) 
                  : ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSolved ? Colors.greenAccent : ScholarlyTheme.accentBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isSolved ? Colors.greenAccent : ScholarlyTheme.accentBlue).withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  isSolved ? Icons.check_rounded : Icons.extension_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSolved
                          ? 'SOLVED'
                          : (p != null
                              ? 'PUZZLE #${p.id}'
                              : (state.commentaryError != null
                                  ? 'ERROR'
                                  : 'LOADING...')),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSolved
                            ? Colors.green.shade700
                            : (state.commentaryError != null
                                ? Colors.redAccent
                                : ScholarlyTheme.textPrimary),
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (state.commentaryError != null && p == null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.commentaryError!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => ref
                                .read(chessProvider.notifier)
                                .nextPuzzle(silent: true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                'RETRY',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (p != null)
                      Text(
                        'Rating: ${p.rating} • ${state.isPlayerWhite ? "White" : "Black"} to move',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: ScholarlyTheme.textSubtle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isSolved && p != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(state.puzzleMovesRemaining.length / 2).ceil()} LEFT',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.accentBlue,
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

class _CompactActionIcon extends StatefulWidget {
  const _CompactActionIcon({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.isEnabled = true,
    this.isActive = false,
    this.activeColor,
    this.activeIconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isEnabled;
  final bool isActive;
  final Color? activeColor;
  final Color? activeIconColor;

  @override
  State<_CompactActionIcon> createState() => _CompactActionIconState();
}

class _CompactActionIconState extends State<_CompactActionIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: (widget.isActive || _isPressed)
            ? (widget.activeColor?.withValues(alpha: 0.2) ?? ScholarlyTheme.accentBlue.withValues(alpha: 0.15))
            : Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (widget.isActive || _isPressed)
              ? (widget.activeIconColor ?? ScholarlyTheme.accentBlue).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          widget.icon,
          size: 22,
          color: widget.isEnabled
              ? (widget.isActive
                    ? (widget.activeIconColor ?? ScholarlyTheme.accentBlue)
                    : ScholarlyTheme.textPrimary)
              : ScholarlyTheme.textSubtle,
        ),
      ),
    );

    final wrappedContent = widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: content)
        : content;

    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isEnabled ? widget.onTap : null,
      child: wrappedContent,
    );
  }
}
