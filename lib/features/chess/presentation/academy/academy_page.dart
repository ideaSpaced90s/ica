import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;

import '../../application/chess_provider.dart';
import '../scholarly_theme.dart';
import '../widgets/commentary_history.dart';
import 'academy_board.dart';
import 'themes/academy_scholar_theme.dart';
import 'academy_settings_page.dart';
import '../widgets/ambient_scaffold.dart';
import '../dashboard_page.dart';
import 'dart:ui';


class AcademyPage extends ConsumerStatefulWidget {
  const AcademyPage({super.key});

  @override
  ConsumerState<AcademyPage> createState() => _AcademyPageState();
}

class _AcademyPageState extends ConsumerState<AcademyPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _slideController;
  late final ScrollController _chatScrollController;

  @override
  void initState() {
    super.initState();
    _chatScrollController = ScrollController();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    // Listener to handle panel collapse: ensure the commentary list scrolls to the latest message.
    _slideController.addListener(() {
      // When the panel is fully collapsed (value == 0.0), scroll to the bottom if we have multiple messages.
      if (_slideController.value == 0.0) {
        final historyLength = ref.read(chessProvider).commentaryHistory.length;
        if (historyLength > 1 && _chatScrollController.hasClients) {
          // Use a post‑frame callback to guarantee the list has been laid out before scrolling.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_chatScrollController.hasClients) {
              _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
            }
          });
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(chessProvider.notifier).initializeAcademySession();
    });
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _slideController.dispose();
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
      exitToDashboardWithSidebar(context, ref);
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
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: const AssetImage('assets/persona/gm_chanakya.png'),
        ),
        const SizedBox(width: 12),
        Text(
          'GM Chanakya',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: ScholarlyTheme.accentGold,
          ),
        ),
      ],
    ),
          content: Text(
            'Shall we commence a new game?',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textPrimary,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Stay',
                style: GoogleFonts.inter(color: ScholarlyTheme.textMuted),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: ScholarlyTheme.accentGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Begin New Duel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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

  Widget _buildMoveLog(BuildContext context, ChessState state, ScrollPhysics? physics) {
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
      physics: physics,
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

  double _lerp(double start, double end, double t) => start + (end - start) * t;

  Widget _buildBottomActionBar(BuildContext context, ChessState state, ChessNotifier notifier) {
    return JuicyGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: 20,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      builder: (context) => const AcademySettingsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _CompactActionIcon(
                icon: Icons.undo_rounded,
                tooltip: 'Undo',
                isEnabled: state.canUndo,
                isBlinking: state.isAcademyBlunderActive,
                onTap: state.canUndo ? () => notifier.undo() : null,
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
    );
  }

  Widget _buildSlidingCommentaryPanel(
    BuildContext context,
    ChessState state,
    double factor,
  ) {
    final double borderRadius = _lerp(20.0, 0.0, factor);
    final double horizontalPadding = _lerp(12.0, 0.0, factor);

    final dragHandler = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        final delta = -details.primaryDelta! / MediaQuery.of(context).size.height;
        _slideController.value = (_slideController.value + delta * 1.5).clamp(0.0, 1.0);
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -300 || _slideController.value > 0.4) {
          _slideController.forward();
        } else if (velocity > 300 || _slideController.value <= 0.4) {
          _slideController.reverse();
        }
      },
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ScholarlyTheme.textMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (state.game.capturedByWhite.isNotEmpty || state.game.capturedByBlack.isNotEmpty) ...[
              const SizedBox(height: 10),
              _CompactCapturedPiecesHeader(state: state),
            ],
          ],
        ),
      ),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: JuicyGlassCard(
        borderRadius: borderRadius,
        padding: EdgeInsets.fromLTRB(10, 6, 10, factor > 0.8 ? 24 : 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            dragHandler,
            const SizedBox(height: 6),
            Expanded(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  final stop = _lerp(0.20, 0.08, factor);
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [Colors.transparent, Colors.white],
                    stops: [0.0, stop],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: state.showLog
                    ? _buildMoveLog(
                        context,
                        state,
                        const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      )
                    : CommentaryHistory(
                        state: state,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        controller: _chatScrollController,
                      ),
              ),
            ),
          ],
        ),
      ),
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
        if (_slideController.value > 0.0) {
          _slideController.reverse();
        } else {
          await _requestExitAcademy();
        }
      },
      child: AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        blob1Color: const Color(0xFFDBEAFE),
        blob2Color: const Color(0xFFD1FAE5),
        blob3Color: const Color(0xFFFEF3C7),
        body: SafeArea(
          top: false,
          left: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final totalHeight = constraints.maxHeight;
                final boardHeight = totalWidth;
                final remainingHeight = totalHeight - boardHeight;

                return AnimatedBuilder(
                  animation: _slideController,
                  builder: (context, child) {
                    final factor = _slideController.value;

                    final bottomBarOpacity = (1.0 - factor).clamp(0.0, 1.0);
                    final bottomBarTranslation = 120.0 * factor;

                    final collapsedTop = boardHeight + 4;
                    // The collapsed panel occupies the space below the board except the bottom action bar.
                    // The action bar + padding takes roughly 82px.
                    final collapsedHeight = remainingHeight - 82;

                    final currentTop = _lerp(collapsedTop, 0.0, factor);
                    final currentHeight = _lerp(collapsedHeight, totalHeight, factor);

                    return Stack(
                      children: [
                        // 1. CHESSBOARD LAYER (with dynamic blur overlay)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: boardHeight,
                          child: ClipRect(
                            child: Stack(
                              children: [
                                const AcademyBoard(alignment: Alignment.topCenter),
                                if (factor > 0.0)
                                  Positioned.fill(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 12.0 * factor,
                                        sigmaY: 12.0 * factor,
                                      ),
                                      child: Container(
                                        color: Colors.white.withValues(
                                          alpha: 0.15 * factor,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // 2. BOTTOM ACTION BAR LAYER (fades and slides off screen)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12 - bottomBarTranslation,
                          child: Opacity(
                            opacity: bottomBarOpacity,
                            child: IgnorePointer(
                              ignoring: factor > 0.5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: _buildBottomActionBar(context, state, notifier),
                              ),
                            ),
                          ),
                        ),

                        // 3. SLIDING COMMENTARY HISTORY LAYER
                        Positioned(
                          top: currentTop,
                          left: 0,
                          right: 0,
                          height: currentHeight,
                          child: _buildSlidingCommentaryPanel(context, state, factor),
                        ),
                      ],
                    );
                  },
                );
              },
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
    this.isBlinking = false,
    this.activeColor,
    this.activeIconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool isEnabled;
  final bool isActive;
  final bool isBlinking;
  final Color? activeColor;
  final Color? activeIconColor;

  @override
  State<_CompactActionIcon> createState() => _CompactActionIconState();
}

class _CompactActionIconState extends State<_CompactActionIcon>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    if (widget.isBlinking) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _CompactActionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlinking != oldWidget.isBlinking) {
      if (widget.isBlinking) {
        _blinkController.repeat(reverse: true);
      } else {
        _blinkController.stop();
        _blinkController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: widget.isEnabled ? (_) => setState(() => _isPressed = false) : null,
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isEnabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _blinkAnimation,
        builder: (context, child) {
          final opacity = widget.isBlinking ? _blinkAnimation.value : 1.0;

          final Color bgColor = widget.isBlinking
              ? Colors.redAccent.withValues(alpha: 0.25 * opacity)
              : ((widget.isActive || _isPressed)
                  ? (widget.activeColor?.withValues(alpha: 0.3) ??
                      ScholarlyTheme.accentBlue.withValues(alpha: 0.25))
                  : Colors.white.withValues(alpha: 0.2));

          final Color borderColor = widget.isBlinking
              ? Colors.redAccent.withValues(alpha: 0.6 * opacity)
              : ((widget.isActive || _isPressed)
                  ? (widget.activeIconColor ?? ScholarlyTheme.accentBlue).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.45));

          final Color iconColor = widget.isBlinking
              ? Colors.redAccent.withValues(alpha: 0.3 + 0.7 * opacity)
              : (widget.isEnabled
                  ? (widget.isActive
                      ? (widget.activeIconColor ?? ScholarlyTheme.accentBlue)
                      : ScholarlyTheme.textPrimary)
                  : ScholarlyTheme.textSubtle);

          final container = Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
              boxShadow: widget.isBlinking
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.3 * opacity),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: 18,
                color: iconColor,
              ),
            ),
          );

          return widget.tooltip != null
              ? Tooltip(message: widget.tooltip!, child: container)
              : container;
        },
      ),
    );
  }
}

class _CompactCapturedPiecesHeader extends ConsumerWidget {
  final ChessState state;

  const _CompactCapturedPiecesHeader({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whiteCaptures = state.game.capturedByWhite;
    final blackCaptures = state.game.capturedByBlack;

    if (whiteCaptures.isEmpty && blackCaptures.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.65),
              width: 1.2,
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
    ),
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
    const theme = AcademyScholarTheme();

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
