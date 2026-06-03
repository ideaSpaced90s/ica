import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/ambient_scaffold.dart';
import '../scholarly_theme.dart';
import '../../application/study_lab_provider.dart';
import '../../application/chess_provider.dart';
import '../../application/analysis_engine_controller.dart';
import '../../services/chess_sound_service.dart';
import 'analysis_board.dart';
import 'position_setup_page.dart';
import 'workspace_page.dart';

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({super.key});

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(chessProvider.notifier).loadSavedGames());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyLabProvider);
    final notifier = ref.read(studyLabProvider.notifier);

    // Listen to FEN changes to restart the engine
    ref.listen<String>(studyLabProvider.select((s) => s.activeFen), (previous, next) {
      ref.read(analysisEngineControllerProvider.notifier).setFen(next);
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: const Color(0xFFF3E8FF),
        blob2Color: const Color(0xFFDBEAFE),
        blob3Color: const Color(0xFFFEF3C7),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 800;
              final double paddingHorizontal = isWide ? 16.0 : 12.0;
              final double boardSize = math.min(
                constraints.maxWidth - (paddingHorizontal * 2) - 36,
                constraints.maxHeight * 0.48,
              );

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),
                    // Board Editor setup indicator in Guessing Mode
                    if (state.isGuessingMode)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GUESS THE MOVE TRAINING',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: ScholarlyTheme.accentBlue),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: ScholarlyTheme.accentBlue, borderRadius: BorderRadius.circular(4)),
                              child: Text(
                                '${state.guessedNodes.length} CORRECT',
                                style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Chessboard & Unified Control Panel grouped together
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildBoardWithEval(context, state, notifier, boardSize),
                          _buildUnifiedControlPanel(context, state, notifier, boardSize),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Engine Outputs
                    Expanded(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: _buildEnginePanel(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Action/Settings Bar at the bottom
                    _buildActionBar(context, state, notifier),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
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

  Widget _buildEnginePanel(BuildContext context) {
    final engineState = ref.watch(analysisEngineControllerProvider);
    if (!engineState.isEngineOn) return const SizedBox.shrink();

    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bolt, size: 14, color: Colors.orangeAccent),
                  const SizedBox(width: 4),
                  Text(
                    'ENGINE - Depth ${engineState.currentDepth}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ScholarlyTheme.textMuted,
                    ),
                  ),
                ],
              ),
              if (engineState.isAnalyzing)
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.orangeAccent),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (engineState.topLines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Calculating...',
                style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: ScholarlyTheme.textMuted),
              ),
            )
          else
            ...engineState.topLines.map((line) {
              final evalText = line.isMate && line.mateIn != null
                  ? 'M${line.mateIn}'
                  : '${line.eval > 0 ? "+" : ""}${line.eval.toStringAsFixed(2)}';

              final movesText = line.moves.take(4).join(' ');

              return GestureDetector(
                onTap: () {
                  if (line.moves.isNotEmpty) {
                    final firstMove = line.moves.first;
                    if (firstMove.length >= 4) {
                      final from = firstMove.substring(0, 2);
                      final to = firstMove.substring(2, 4);
                      final promo = firstMove.length > 4 ? firstMove[4] : '';
                      ref.read(studyLabProvider.notifier).makeMove(from, to, promo);
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        alignment: Alignment.center,
                        child: Text(
                          '#${line.pvIndex}',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          movesText,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: ScholarlyTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        evalText,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: line.eval >= 0 ? Colors.green : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildUnifiedControlPanel(
    BuildContext context,
    StudyLabState state,
    StudyLabNotifier notifier,
    double boardSize,
  ) {
    final engineState = ref.watch(analysisEngineControllerProvider);
    final activeIndex = state.currentNodeIndex;
    final bool hasActiveNode = activeIndex != null && activeIndex < state.nodes.length;
    final activeNode = hasActiveNode ? state.nodes[activeIndex] : null;

    final double contentWidth = boardSize + 36 - 16; // Subtract horizontal card padding (8 * 2 = 16)

    return SizedBox(
      width: boardSize + 36, // Match Chessboard + EvalBar width exactly
      child: JuicyGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        borderRadius: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: VCR Navigation Controls
            FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: contentWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CompactBoxButton(
                      tooltip: 'Go to Start',
                      activeColor: const Color(0xFF29B6F6), // Vibrant Cyan/Blue
                      onTap: state.currentNodeIndex != null
                          ? () {
                              notifier.selectNode(null);
                              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                            }
                          : null,
                      child: const Icon(Icons.first_page_rounded),
                    ),
                    _CompactBoxButton(
                      tooltip: 'Undo Move',
                      activeColor: const Color(0xFF69F0AE), // Vibrant Green
                      onTap: state.canUndo
                          ? () {
                              notifier.undo();
                              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                            }
                          : null,
                      child: const Icon(Icons.chevron_left_rounded),
                    ),
                    _CompactBoxButton(
                      tooltip: 'Redo Move',
                      activeColor: const Color(0xFF69F0AE), // Vibrant Green
                      onTap: state.canRedo
                          ? () {
                              notifier.redo();
                              ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                            }
                          : null,
                      child: const Icon(Icons.chevron_right_rounded),
                    ),
                    _CompactBoxButton(
                      tooltip: 'Go to End',
                      activeColor: const Color(0xFF29B6F6), // Vibrant Cyan/Blue
                      onTap: state.canRedo
                          ? () {
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
                      child: const Icon(Icons.last_page_rounded),
                    ),
                    Container(width: 1.5, height: 20, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
                    _CompactBoxButton(
                      tooltip: 'Flip Board',
                      activeColor: const Color(0xFFD500F9), // Vibrant Purple
                      isActive: state.isBoardFlipped,
                      onTap: () {
                        notifier.flipBoard();
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiNavigate);
                      },
                      child: const Icon(Icons.flip_camera_android_rounded),
                    ),
                    _CompactBoxButton(
                      tooltip: 'Toggle Engine',
                      activeColor: const Color(0xFFFFD740), // Vibrant Amber
                      isActive: engineState.isEngineOn,
                      onTap: () {
                        ref.read(analysisEngineControllerProvider.notifier).toggleEngine(!engineState.isEngineOn, state.activeFen);
                        ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiToggle);
                      },
                      child: const Icon(Icons.bolt_rounded),
                    ),
                    _CompactBoxButton(
                      tooltip: 'Reset Position',
                      activeColor: const Color(0xFFFF5252), // Vibrant Red
                      onTap: state.nodes.isNotEmpty
                          ? () {
                              _showResetConfirmation(context, notifier);
                            }
                          : null,
                      child: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Divider
            Container(height: 1, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3)),
            const SizedBox(height: 6),
            // Row 2: Annotations Toolbar
            Opacity(
              opacity: hasActiveNode ? 1.0 : 0.4,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: contentWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ...MoveAnnotation.values.where((a) => a != MoveAnnotation.none).map((ann) {
                        final isApplied = activeNode?.annotation == ann;
                        final color = _getChipColor(ann);

                        return _CompactBoxButton(
                          tooltip: ann.name.toUpperCase(),
                          activeColor: color,
                          isActive: isApplied,
                          onTap: hasActiveNode
                              ? () {
                                  notifier.setAnnotation(
                                    activeNode!.index,
                                    isApplied ? MoveAnnotation.none : ann,
                                  );
                                }
                              : null,
                          child: Text(_getGlyph(ann)),
                        );
                      }),
                      Container(width: 1.5, height: 20, color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5)),
                      _CompactBoxButton(
                        tooltip: 'Add move comment',
                        activeColor: ScholarlyTheme.accentBlue,
                        isActive: activeNode?.comment.isNotEmpty == true,
                        onTap: hasActiveNode ? () => _showCommentDialog(context, activeNode!, notifier) : null,
                        child: Icon(
                          activeNode?.comment.isNotEmpty == true ? Icons.comment : Icons.comment_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getChipColor(MoveAnnotation a) {
    switch (a) {
      case MoveAnnotation.brilliant:
        return const Color(0xFF00E5FF); // Cyan
      case MoveAnnotation.good:
        return const Color(0xFF00E676); // Green
      case MoveAnnotation.interesting:
        return const Color(0xFF7C4DFF); // Purple/Blue
      case MoveAnnotation.dubious:
        return const Color(0xFFFFEA00); // Yellow
      case MoveAnnotation.mistake:
        return const Color(0xFFFF9100); // Orange
      case MoveAnnotation.blunder:
        return const Color(0xFFFF1744); // Red
      case MoveAnnotation.none:
        return Colors.grey;
    }
  }

  String _getGlyph(MoveAnnotation a) {
    switch (a) {
      case MoveAnnotation.brilliant: return '!!';
      case MoveAnnotation.good: return '!';
      case MoveAnnotation.interesting: return '!?';
      case MoveAnnotation.dubious: return '?!';
      case MoveAnnotation.mistake: return '?';
      case MoveAnnotation.blunder: return '??';
      case MoveAnnotation.none: return '';
    }
  }

  void _showCommentDialog(BuildContext context, StudyLabMoveNode node, StudyLabNotifier notifier) {
    final controller = TextEditingController(text: node.comment);
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
            'Edit Move Comment',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: GoogleFonts.inter(color: ScholarlyTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your thoughts or positional analysis...',
              hintStyle: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
              filled: true,
              fillColor: ScholarlyTheme.panelBase,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ScholarlyTheme.panelStroke),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: ScholarlyTheme.accentBlue),
              ),
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
              onPressed: () {
                notifier.updateComment(controller.text);
                Navigator.pop(context);
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

  Widget _buildActionBar(BuildContext context, StudyLabState state, StudyLabNotifier notifier) {
    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      borderRadius: 16,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.schema_rounded, color: ScholarlyTheme.accentBlue, size: 26),
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkspacePage(initialTabIndex: 0)),
                );
              },
              tooltip: 'Move Tree Flow',
            ),
            IconButton(
              icon: const Icon(Icons.import_export_rounded, color: Colors.teal, size: 28),
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkspacePage(initialTabIndex: 1)),
                );
              },
              tooltip: 'Import / Export PGN',
            ),
            IconButton(
              icon: const Icon(Icons.library_books_rounded, color: ScholarlyTheme.realGold, size: 26),
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkspacePage(initialTabIndex: 2)),
                );
              },
              tooltip: 'Game Library',
            ),
            IconButton(
              icon: const Icon(Icons.sports_esports_rounded, color: Colors.purpleAccent, size: 26),
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkspacePage(initialTabIndex: 3)),
                );
              },
              tooltip: 'Sparring',
            ),
            IconButton(
              icon: const Icon(Icons.analytics_rounded, color: Colors.redAccent, size: 26),
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkspacePage(initialTabIndex: 4)),
                );
              },
              tooltip: 'Full Game Report',
            ),
            IconButton(
              icon: const Icon(Icons.grid_on_rounded, color: Colors.blueAccent, size: 26),
              onPressed: () {
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PositionSetupPage()),
                );
              },
              tooltip: 'Position Editor',
            ),
          ],
        ),
      ),
    );
  }

  // Workspace pages refactored to workspace_page.dart

}

class _CompactBoxButton extends StatefulWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isActive;
  final Color activeColor;

  const _CompactBoxButton({
    required this.child,
    required this.tooltip,
    this.onTap,
    this.isActive = false,
    required this.activeColor,
  });

  @override
  State<_CompactBoxButton> createState() => _CompactBoxButtonState();
}

class _CompactBoxButtonState extends State<_CompactBoxButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onTap != null;

    // Colorful icon/text when enabled, faded when disabled
    final Color color = isEnabled
        ? widget.activeColor
        : ScholarlyTheme.textMuted.withValues(alpha: 0.35);

    // Box background color
    final Color bgColor = widget.isActive
        ? widget.activeColor.withValues(alpha: 0.2)
        : isEnabled
            ? Colors.black.withValues(alpha: 0.03) // Very subtle default box background
            : Colors.transparent;

    // Box border color
    final Color borderColor = widget.isActive
        ? widget.activeColor
        : isEnabled
            ? ScholarlyTheme.panelStroke.withValues(alpha: 0.5)
            : ScholarlyTheme.panelStroke.withValues(alpha: 0.2);

    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => _controller.forward() : null,
        onTapUp: isEnabled ? (_) => _controller.reverse() : null,
        onTapCancel: isEnabled ? () => _controller.reverse() : null,
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: widget.isActive ? 1.5 : 1.0,
              ),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: widget.activeColor.withValues(alpha: 0.2),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: IconTheme(
                data: IconThemeData(
                  size: 18,
                  color: color,
                ),
                child: DefaultTextStyle(
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
