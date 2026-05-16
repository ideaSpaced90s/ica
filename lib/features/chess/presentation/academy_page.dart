import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../application/chess_provider.dart';
import 'scholarly_theme.dart';
import 'widgets/commentary_history.dart';
import 'widgets/board_stage.dart';
import 'themes/theme_registry.dart';
import 'settings_page.dart';
import 'widgets/global_sidebar.dart';


class AcademyPage extends ConsumerStatefulWidget {
  final bool startInPuzzleMode;
  const AcademyPage({super.key, this.startInPuzzleMode = false});

  @override
  ConsumerState<AcademyPage> createState() => _AcademyPageState();
}

class _AcademyPageState extends ConsumerState<AcademyPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(chessProvider.notifier).initializeAcademySession();
      if (widget.startInPuzzleMode) {
        ref.read(chessProvider.notifier).startPuzzleMode();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _requestExitAcademy() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ScholarlyTheme.panelBase,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Exit Academy Mode?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: ScholarlyTheme.textPrimary,
          ),
        ),
        content: Text(
          'Do you want to exit the academy study environment and return to the main app interface?',
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
              'Exit Academy',
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
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleNewGame(BuildContext context, WidgetRef ref) async {
    final state = ref.read(chessProvider);
    final bool hasProgress = state.recentMoves.isNotEmpty;

    if (hasProgress) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ScholarlyTheme.panelBase,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'New Game?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          content: Text(
            'Start a new game? Your current game progress will be saved automatically to history.',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textPrimary,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'New Game',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Game saved to history.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: ScholarlyTheme.accentBlue,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    await ref.read(chessProvider.notifier).initializeAcademySession();
  }

  Widget _buildMoveLog(BuildContext context, ChessState state) {
    final moves = state.recentMoves;
    if (moves.isEmpty) {
      return const Center(
        child: Text(
          'Log is empty.',
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
      padding: EdgeInsets.zero,
      itemCount: pairs.length,
      itemBuilder: (context, index) {
        final pair = pairs[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}.',
                  style: GoogleFonts.jetBrainsMono(
                    color: ScholarlyTheme.accentBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  pair[0],
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
              if (pair.length > 1)
                Expanded(
                  child: Text(
                    pair[1],
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chessProvider);
    final notifier = ref.read(chessProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        await _requestExitAcademy();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: ScholarlyTheme.backgroundStart,
        drawer: const GlobalSidebar(),
        body: SafeArea(
          top: false,
          left: false, // Allow AI chat box on far left to reach edge-to-edge under notch/notification area
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top side chessboard taking exact square space, extending edge-to-edge
                const AspectRatio(
                  aspectRatio: 1.0,
                  child: BoardStage(isExpanded: true),
                ),
                const SizedBox(height: 4),
                // 2. AI Chat Box claiming all remaining vertical space directly below the board
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CompactCapturedPiecesHeader(state: state),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.white],
                                stops: [0.0, 0.20],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: state.showLog
                                ? _buildMoveLog(context, state)
                                : CommentaryHistory(state: state),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // 3. Horizontal action bar at the bottom
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                    child: state.isPuzzleMode
                        ? Row(
                            children: [
                              _CompactActionIcon(
                                icon: Icons.menu_rounded,
                                tooltip: 'Menu',
                                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                              ),
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: Icons.skip_next_rounded,
                                tooltip: 'Next Puzzle',
                                onTap: () => notifier.nextPuzzle(),
                              ),
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: Icons.refresh_rounded,
                                tooltip: 'Reset Line',
                                onTap: () => notifier.resetPuzzleLine(),
                              ),
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: Icons.flip_camera_android_outlined,
                                tooltip: 'Flip Board',
                                isActive: state.isBoardFlipped,
                                onTap: () => notifier.toggleBoardOrientation(),
                              ),
                              const SizedBox(width: 8),
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
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: state.showLog
                                    ? Icons.chat_bubble_outline_rounded
                                    : Icons.history_edu_rounded,
                                tooltip: 'Toggle Log',
                                isActive: state.showLog,
                                onTap: () => notifier.toggleLog(),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              _CompactActionIcon(
                                icon: Icons.menu_rounded,
                                tooltip: 'Menu',
                                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                              ),
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: Icons.add_box_rounded,
                                tooltip: 'New Game',
                                onTap: () => _handleNewGame(context, ref),
                              ),
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: Icons.tune_rounded,
                                tooltip: 'Settings',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsPage(isAcademyMode: true),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: Icons.undo_rounded,
                                tooltip: 'Undo',
                                isEnabled: state.canUndo,
                                onTap: state.canUndo ? () => notifier.undo() : null,
                              ),
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: Icons.redo_rounded,
                                tooltip: 'Redo',
                                isEnabled: state.canRedo,
                                onTap: state.canRedo ? () => notifier.redo() : null,
                              ),
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: Icons.flip_camera_android_outlined,
                                tooltip: 'Flip Board',
                                isActive: state.isBoardFlipped,
                                onTap: () => notifier.toggleBoardOrientation(),
                              ),
                              const SizedBox(width: 8),
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
                              const SizedBox(width: 8),
                              _CompactActionIcon(
                                icon: state.showLog
                                    ? Icons.chat_bubble_outline_rounded
                                    : Icons.history_edu_rounded,
                                tooltip: 'Toggle Log',
                                isActive: state.showLog,
                                onTap: () => notifier.toggleLog(),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
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
      width: 34,
      height: 34,
      decoration: ScholarlyTheme.modernDecoration(
        sunken: _isPressed || widget.isActive,
      ).copyWith(
        color: (widget.isActive || _isPressed)
            ? (widget.activeColor ?? ScholarlyTheme.accentBlueSoft)
            : ScholarlyTheme.panelBase,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          widget.icon,
          size: 18,
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

class _CompactCapturedPiecesHeader extends ConsumerWidget {
  final ChessState state;

  const _CompactCapturedPiecesHeader({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isPuzzleMode) {
      final p = state.currentPuzzle;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.extension_rounded, size: 14, color: ScholarlyTheme.accentBlue),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p != null ? 'PUZZLE #${p.id}' : 'PUZZLE MODE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.accentBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (p != null)
                    Text(
                      'Rating: ${p.rating} • To Move: ${state.isPlayerWhite ? "White" : "Black"}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: ScholarlyTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: state.puzzleMovesRemaining.isEmpty
                    ? Colors.green.withValues(alpha: 0.2)
                    : ScholarlyTheme.panelBase,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                state.puzzleMovesRemaining.isEmpty ? 'SOLVED' : '${(state.puzzleMovesRemaining.length / 2).ceil()} moves left',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: state.puzzleMovesRemaining.isEmpty ? Colors.greenAccent : ScholarlyTheme.textSubtle,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final whiteCaptures = state.game.capturedByWhite;
    final blackCaptures = state.game.capturedByBlack;

    if (whiteCaptures.isEmpty && blackCaptures.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelBase.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: ScholarlyTheme.accentGold),
          const SizedBox(width: 4),
          Text(
            'MATERIAL',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.accentGold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (whiteCaptures.isNotEmpty)
            _InlineCapturedGroup(pieces: whiteCaptures, isWhiteTeam: true),
          if (whiteCaptures.isNotEmpty && blackCaptures.isNotEmpty)
            const SizedBox(width: 8),
          if (blackCaptures.isNotEmpty)
            _InlineCapturedGroup(pieces: blackCaptures, isWhiteTeam: false),
        ],
      ),
    );
  }
}

class _InlineCapturedGroup extends ConsumerWidget {
  final List<chess_lib.Piece> pieces;
  final bool isWhiteTeam;

  const _InlineCapturedGroup({required this.pieces, required this.isWhiteTeam});

  int _getPieceValue(chess_lib.PieceType type) {
    if (type == chess_lib.PieceType.PAWN) return 1;
    if (type == chess_lib.PieceType.KNIGHT) return 3;
    if (type == chess_lib.PieceType.BISHOP) return 4;
    if (type == chess_lib.PieceType.ROOK) return 5;
    if (type == chess_lib.PieceType.QUEEN) return 9;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardThemeId = ref.watch(chessProvider.select((s) => s.boardThemeId));
    final theme = ThemeRegistry.getTheme(boardThemeId);

    final sortedPieces = List<chess_lib.Piece>.from(pieces)
      ..sort((a, b) => _getPieceValue(a.type).compareTo(_getPieceValue(b.type)));

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isWhiteTeam ? Colors.white : Colors.black87,
            border: Border.all(color: Colors.grey.shade400, width: 0.5),
          ),
        ),
        const SizedBox(width: 4),
        Wrap(
          spacing: -6, // Stacked tiny look
          children: sortedPieces.map((piece) {
            final type = piece.type.toString().toUpperCase();
            final isWhite = piece.color == chess_lib.Color.WHITE;
            return SizedBox(
              width: 14,
              height: 14,
              child: theme.buildPiece(context, type, isWhite, false, 0.0),
            );
          }).toList(),
        ),
      ],
    );
  }
}
