import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'dart:math';

import '../../application/chess_provider.dart';
import '../../application/tutorial_provider.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import '../widgets/commentary_history.dart';
import '../widgets/gm_chanakya_intro_overlay.dart';
import 'academy_board.dart';
import 'widgets/tactics_playback_controls.dart';
import 'widgets/academy_pendulum_indicator.dart';
import 'themes/academy_scholar_theme.dart';
import '../widgets/ambient_scaffold.dart';
import '../mobile_navigation_shell.dart';
import 'dart:ui';
import '../../application/store_provider.dart';
import '../widgets/premium_nudge_overlay.dart';


class AcademyPage extends ConsumerStatefulWidget {
  const AcademyPage({super.key});

  @override
  ConsumerState<AcademyPage> createState() => _AcademyPageState();
}

class _AcademyPageState extends ConsumerState<AcademyPage> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final AnimationController _slideController;
  late final ScrollController _chatScrollController;
  bool _showAcademyIntro = false;

  void _checkShowAcademyIntro() {
    final repo = ref.read(tutorialProgressRepositoryProvider);
    _showAcademyIntro =
        !repo.shouldPersistIntroSeen() || !repo.hasSeenAcademyIntro();
  }

  @override
  void initState() {
    super.initState();
    _chatScrollController = ScrollController();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
    // Listener to handle panel collapse: ensure the commentary list scrolls to the latest message.
    _slideController.addListener(() {
      setState(() {});
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

    _checkShowAcademyIntro();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(chessProvider.notifier).initializeAcademySession();
      if (mounted) {
        ref.read(backButtonOverridesProvider.notifier).update((map) => {
          ...map,
          3: _handleBackPress,
        });
      }
    });
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _slideController.dispose();
    ref.read(backButtonOverridesProvider.notifier).update((map) {
      final newMap = Map<int, Future<bool> Function()>.from(map);
      newMap.remove(3);
      return newMap;
    });
    super.dispose();
  }

  Future<bool> _handleBackPress() async {
    if (_slideController.value > 0.0) {
      _slideController.reverse();
      return true;
    }
    return false;
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
    
    final whiteCaptures = state.game.capturedByWhite;
    final blackCaptures = state.game.capturedByBlack;
    
    final userCapturedList = state.isPlayerWhite ? whiteCaptures : blackCaptures;
    final userLostList = state.isPlayerWhite ? blackCaptures : whiteCaptures;

    int getPieceValue(chess_lib.PieceType type) {
      if (type == chess_lib.PieceType.PAWN) return 1;
      if (type == chess_lib.PieceType.KNIGHT) return 3;
      if (type == chess_lib.PieceType.BISHOP) return 3;
      if (type == chess_lib.PieceType.ROOK) return 5;
      if (type == chess_lib.PieceType.QUEEN) return 9;
      return 0;
    }

    final capturedPoints = userCapturedList.fold<int>(0, (sum, p) => sum + getPieceValue(p.type));
    final lostPoints = userLostList.fold<int>(0, (sum, p) => sum + getPieceValue(p.type));
    final netBalance = capturedPoints - lostPoints;

    final List<List<String>> pairs = [];
    for (int i = 0; i < moves.length; i += 2) {
      pairs.add([moves[i], if (i + 1 < moves.length) moves[i + 1]]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. FIXED: MATERIAL DOMINANCE DASHBOARD
        JuicyGlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHITE CAPTURED',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildLargeCapturedGroup(context, whiteCaptures, true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BLACK CAPTURED',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: ScholarlyTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildLargeCapturedGroup(context, blackCaptures, false),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 16, color: ScholarlyTheme.panelStroke),
              _buildMaterialBalanceGauge(netBalance),
            ],
          ),
        ),
        
        const SizedBox(height: 12),

        // 2. FIXED: LIVE GAME ANALYTICS ROW
        _buildAnalyticsGrid(state),

        const SizedBox(height: 16),

        // 3. FIXED: MOVE HISTORY TIMELINE HEADER
        Row(
          children: [
            const Icon(Icons.history_edu_rounded, size: 14, color: ScholarlyTheme.accentBlue),
            const SizedBox(width: 6),
            Text(
              'MOVE HISTORY TIMELINE',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // 4. SCROLLABLE: MOVE LOG CONTAINER
        Expanded(
          child: moves.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  child: Text(
                    'Log is empty. Start playing to log moves.',
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  physics: physics,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: List.generate(pairs.length, (index) {
                        final pair = pairs[index];
                        final whiteMoveIndex = 2 * index;
                        final blackMoveIndex = 2 * index + 1;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 26,
                                child: Text(
                                  '${index + 1}.',
                                  style: GoogleFonts.jetBrainsMono(
                                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _buildMoveChip(whiteMoveIndex, pair[0], state),
                              const SizedBox(width: 8),
                              if (pair.length > 1)
                                _buildMoveChip(blackMoveIndex, pair[1], state)
                              else
                                const Expanded(child: SizedBox()),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
        ),
        
        // 5. FLOATING REVIEW PANEL AT THE BOTTOM
        if (state.viewingMoveIndex != null) ...[
          const SizedBox(height: 8),
          _buildReviewNavigation(state),
        ],
      ],
    );
  }

  Widget _buildLargeCapturedGroup(BuildContext context, List<chess_lib.Piece> pieces, bool isWhiteTeam) {
    const theme = AcademyScholarTheme();
    
    int getPieceValue(chess_lib.PieceType type) {
      if (type == chess_lib.PieceType.PAWN) return 1;
      if (type == chess_lib.PieceType.KNIGHT) return 3;
      if (type == chess_lib.PieceType.BISHOP) return 3;
      if (type == chess_lib.PieceType.ROOK) return 5;
      if (type == chess_lib.PieceType.QUEEN) return 9;
      return 0;
    }

    final sortedPieces = List<chess_lib.Piece>.from(pieces)
      ..sort((a, b) => getPieceValue(a.type).compareTo(getPieceValue(b.type)));

    if (sortedPieces.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Text(
          'No captures yet',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: ScholarlyTheme.textSubtle,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: sortedPieces.map((piece) {
        final type = piece.type.toString().toUpperCase();
        final isWhitePiece = piece.color == chess_lib.Color.WHITE;
        
        final Color cardBg = isWhitePiece ? const Color(0xFF475569) : Colors.white;
        final Color borderCol = isWhitePiece ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.12);

        return Tooltip(
          message: '${isWhitePiece ? "White" : "Black"} ${type.toLowerCase()}',
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: cardBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: borderCol,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: theme.buildPiece(context, type, isWhitePiece, false, 0.0),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMaterialBalanceGauge(int netBalance) {
    final isWhiteAhead = netBalance > 0;
    final absBalance = netBalance.abs();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MATERIAL ADVANTAGE',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              netBalance == 0 ? 'EVEN' : '${isWhiteAhead ? "White" : "Black"} +$absBalance',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: netBalance == 0
                    ? ScholarlyTheme.textMuted
                    : isWhiteAhead
                        ? Colors.green.shade700
                        : Colors.redAccent.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final mid = width / 2;
              final fraction = (absBalance / 15.0).clamp(0.0, 1.0);
              final barWidth = mid * fraction;
              
              return Stack(
                children: [
                  Positioned(
                    left: mid - 1,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: ScholarlyTheme.textMuted.withValues(alpha: 0.4),
                    ),
                  ),
                  if (netBalance != 0)
                    Positioned(
                      left: isWhiteAhead ? mid : mid - barWidth,
                      width: barWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isWhiteAhead ? Colors.green : Colors.redAccent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsGrid(ChessState state) {
    final moves = state.recentMoves;
    
    final totalCaptured = state.game.capturedByWhite.length + state.game.capturedByBlack.length;
    final remainingPieces = 32 - totalCaptured;
    String phase = 'Opening';
    Color phaseColor = Colors.teal;
    if (remainingPieces <= 10) {
      phase = 'Endgame';
      phaseColor = Colors.deepOrange;
    } else if (remainingPieces <= 22) {
      phase = 'Middlegame';
      phaseColor = Colors.indigo;
    }

    final capturesCount = moves.where((m) => m.contains('x')).length;
    final checksCount = moves.where((m) => m.contains('+') || m.contains('#')).length;

    return Row(
      children: [
        Expanded(child: _buildMiniStatCard('PHASE', phase, Icons.hourglass_empty_rounded, phaseColor)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStatCard('CAPTURES', '$capturesCount', Icons.gavel_rounded, Colors.purple)),
        const SizedBox(width: 8),
        Expanded(child: _buildMiniStatCard('CHECKS', '$checksCount', Icons.warning_amber_rounded, Colors.amber.shade800)),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 11, color: accentColor),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textMuted,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: ScholarlyTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveChip(int moveIndex, String label, ChessState state) {
    final int activeIndex = state.viewingMoveIndex ?? (state.recentMoves.length - 1);
    final bool isSelected = activeIndex == moveIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(chessProvider.notifier).jumpToMove(moveIndex);
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? ScholarlyTheme.accentBlue.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? ScholarlyTheme.accentBlue.withValues(alpha: 0.4)
                    : ScholarlyTheme.panelStroke.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewNavigation(ChessState state) {
    final int currentIndex = state.viewingMoveIndex ?? (state.recentMoves.length - 1);
    final bool hasPrev = currentIndex >= 0;
    final bool hasNext = state.viewingMoveIndex != null && currentIndex < state.recentMoves.length - 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Reviewing Move ${currentIndex + 1}/${state.recentMoves.length}',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: ScholarlyTheme.accentBlue,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 20),
                color: ScholarlyTheme.accentBlue,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: hasPrev ? () => ref.read(chessProvider.notifier).jumpToMove(currentIndex - 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 20),
                color: ScholarlyTheme.accentBlue,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: hasNext ? () => ref.read(chessProvider.notifier).jumpToMove(currentIndex + 1) : null,
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ScholarlyTheme.accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                onPressed: () => ref.read(chessProvider.notifier).jumpToMove(-1),
                child: Text(
                  'LIVE',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _lerp(double start, double end, double t) => start + (end - start) * t;

  Widget _buildVerticalActionBar(BuildContext context, ChessState state, ChessNotifier notifier) {
    final isPlayerTurn = state.isPlayerWhite == (state.game.turn == chess_lib.Color.WHITE);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: state.activeTacticIndex != null
          ? const KeyedSubtree(
              key: ValueKey('tactics_playback'),
              child: TacticsPlaybackControls(axis: Axis.vertical),
            )
          : Container(
              key: const ValueKey('normal_vertical_action_bar'),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AcademyPendulumIndicator(
                    isFrozen: state.isTacticsModeActive && !isPlayerTurn,
                    isActive: !state.isTacticsModeActive && !state.game.gameOver && !isPlayerTurn,
                    isChanakya: true,
                  ),
                  const SizedBox(height: 12),
                  _PremiumActionIcon(
                    icon: Icons.add_box_rounded,
                    tooltip: 'New Game',
                    baseColor: const Color(0xFF10B981),
                    isEnabled: !state.isTacticsModeActive,
                    onTap: !state.isTacticsModeActive ? () => _handleNewGame(context, ref) : null,
                  ),
                  const SizedBox(height: 12),
                  _PremiumActionIcon(
                    icon: Icons.undo_rounded,
                    tooltip: 'Undo',
                    baseColor: const Color(0xFFF59E0B),
                    isEnabled: !state.isTacticsModeActive && state.isAcademyBlunderActive,
                    isBlinking: !state.isTacticsModeActive && state.isAcademyBlunderActive,
                    onTap: (!state.isTacticsModeActive && state.isAcademyBlunderActive) ? () => notifier.undo() : null,
                  ),
                  const SizedBox(height: 12),
                  _PremiumActionIcon(
                    icon: state.showLog
                        ? Icons.chat_bubble_outline_rounded
                        : Icons.history_edu_rounded,
                    tooltip: 'Toggle Log',
                    baseColor: const Color(0xFF3B82F6),
                    isEnabled: !state.isTacticsModeActive,
                    isActive: state.showLog,
                    onTap: !state.isTacticsModeActive ? () => notifier.toggleLog() : null,
                  ),
                  const SizedBox(height: 12),
                  AcademyPendulumIndicator(
                    isFrozen: state.isTacticsModeActive && isPlayerTurn,
                    isActive: !state.isTacticsModeActive && !state.game.gameOver && isPlayerTurn,
                    isChanakya: false,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHorizontalActionBar(BuildContext context, ChessState state, ChessNotifier notifier, {bool isDocked = false}) {
    final isPlayerTurn = state.isPlayerWhite == (state.game.turn == chess_lib.Color.WHITE);
    
    Widget content = AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: state.activeTacticIndex != null
          ? KeyedSubtree(
              key: const ValueKey('tactics_playback_horizontal'),
              child: TacticsPlaybackControls(
                axis: Axis.horizontal,
                isFlat: isDocked,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AcademyPendulumIndicator(
                  isFrozen: state.isTacticsModeActive && !isPlayerTurn,
                  isActive: !state.isTacticsModeActive && !state.game.gameOver && !isPlayerTurn,
                  isChanakya: true,
                ),
                const SizedBox(width: 12),
                _PremiumActionIcon(
                  icon: Icons.add_box_rounded,
                  tooltip: 'New Game',
                  baseColor: const Color(0xFF10B981),
                  isEnabled: !state.isTacticsModeActive,
                  isFlat: isDocked,
                  onTap: !state.isTacticsModeActive ? () => _handleNewGame(context, ref) : null,
                ),
                const SizedBox(width: 12),
                _PremiumActionIcon(
                  icon: Icons.undo_rounded,
                  tooltip: 'Undo',
                  baseColor: const Color(0xFFF59E0B),
                  isEnabled: !state.isTacticsModeActive && state.isAcademyBlunderActive,
                  isBlinking: !state.isTacticsModeActive && state.isAcademyBlunderActive,
                  isFlat: isDocked,
                  onTap: (!state.isTacticsModeActive && state.isAcademyBlunderActive) ? () => notifier.undo() : null,
                ),
                const SizedBox(width: 12),
                _PremiumActionIcon(
                  icon: state.showLog
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.history_edu_rounded,
                  tooltip: 'Toggle Log',
                  baseColor: const Color(0xFF3B82F6),
                  isEnabled: !state.isTacticsModeActive,
                  isActive: state.showLog,
                  isFlat: isDocked,
                  onTap: !state.isTacticsModeActive ? () => notifier.toggleLog() : null,
                ),
                const SizedBox(width: 12),
                AcademyPendulumIndicator(
                  isFrozen: state.isTacticsModeActive && isPlayerTurn,
                  isActive: !state.isTacticsModeActive && !state.game.gameOver && isPlayerTurn,
                  isChanakya: false,
                ),
                const SizedBox(width: 12),
                _PremiumActionIcon(
                  imagePath: 'assets/persona/gm_chanakya.png',
                  tooltip: 'Consult GM Chanakya',
                  baseColor: ScholarlyTheme.accentGold,
                  isFlat: isDocked,
                  onTap: () => _slideController.forward(),
                ),
              ],
            ),
    );

    if (isDocked) {
      return Container(
        decoration: BoxDecoration(
          color: ScholarlyTheme.panelBase,
          border: Border(top: BorderSide(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.15))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: content,
            ),
          ),
        ),
      );
    } else {
      return Container(
        key: const ValueKey('normal_horizontal_action_bar'),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: content,
        ),
      );
    }
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ChessState state,
    ChessNotifier notifier,
    BoxConstraints constraints,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column (Board and vertical action icons next to it)
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: LayoutBuilder(
                builder: (context, boardConstraints) {
                  final double paddingValue = 16.0;
                  final double actionWidth = 46.0;
                  
                  final double maxBoardWidth = boardConstraints.maxWidth - paddingValue - actionWidth;
                  final double boardSize = max(0.0, min(maxBoardWidth, boardConstraints.maxHeight));
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: const AcademyBoard(alignment: Alignment.center),
                      ),
                      SizedBox(width: paddingValue),
                      Container(
                        width: actionWidth,
                        alignment: Alignment.center,
                        child: _buildVerticalActionBar(context, state, notifier),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),

        // Vertical separator line
        Container(
          width: 1.0,
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
        ),

        // Right Column (Commentary, Log)
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 24.0, 24.0, 24.0),
            child: JuicyGlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
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
                            isExpanded: true,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlidingCommentaryPanel(
    BuildContext context,
    ChessState state,
    double factor,
  ) {
    if (factor == 0.0) {
      return const SizedBox.shrink();
    }

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
        if (velocity < -300 || _slideController.value > 0.5) {
          _slideController.forward();
        } else {
          _slideController.reverse();
        }
      },
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 48), // spacer to balance the close button on the right
                Expanded(
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ScholarlyTheme.textMuted.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _slideController.animateTo(0.0, duration: const Duration(milliseconds: 300)),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.textMuted.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: ScholarlyTheme.textMuted,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            if (state.showLog && (state.game.capturedByWhite.isNotEmpty || state.game.capturedByBlack.isNotEmpty)) ...[
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
        padding: EdgeInsets.fromLTRB(factor > 0.8 ? 0 : 10, 6, factor > 0.8 ? 0 : 10, factor > 0.8 ? 0 : 6),
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
                    ? Padding(
                        padding: EdgeInsets.symmetric(horizontal: factor > 0.8 ? 10.0 : 0.0),
                        child: _buildMoveLog(
                          context,
                          state,
                          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        ),
                      )
                    : CommentaryHistory(
                        state: state,
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        controller: _chatScrollController,
                        isExpanded: factor > 0.8,
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

    final storeState = ref.watch(storeProvider);
    final storeNotifier = ref.read(storeProvider.notifier);
    final isPremium = storeState.isPremium;
    final isLimitReached = !isPremium && !storeNotifier.canUseChipPrompt() && !(state.recentMoves.isNotEmpty && !state.game.gameOver);

    if (isLimitReached) {
      return const PremiumNudgeOverlay(
        isFullScreen: true,
        title: 'Daily Academy Limit Reached',
        description: 'You have used your 5 free AI chipsets for today. Upgrade to unlock unlimited coaching.',
      );
    }

    ref.listen<int>(mobileNavIndexProvider, (previous, current) {
      if (previous == 3 && current != 3) {
        final repo = ref.read(tutorialProgressRepositoryProvider);
        if (!repo.shouldPersistIntroSeen()) {
          setState(() {
            _showAcademyIntro = true;
          });
        }
      }
    });

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.size.width > mediaQuery.size.height;
    final isKeyboardOpen = mediaQuery.viewInsets.bottom > 0;

    return AmbientScaffold(
        scaffoldKey: _scaffoldKey,
        extendBody: true,
        blob1Color: const Color(0xFFDBEAFE),
        blob2Color: const Color(0xFFD1FAE5),
        blob3Color: const Color(0xFFFEF3C7),
        bottomNavigationBar: null,
        body: SafeArea(
          top: false,
          left: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isLandscapeLayout = constraints.maxWidth > constraints.maxHeight;
                    if (isLandscapeLayout) {
                      return _buildLandscapeLayout(context, state, notifier, constraints);
                    }                    final totalWidth = constraints.maxWidth;
                    final totalHeight = constraints.maxHeight;

                    final double paddingValue = 6.0;
                    final double actionWidth = 46.0;
                    final double boardMargin = 8.0;

                    return AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        final factor = _slideController.value;
                        final bool isCollapsed = factor < 0.5;

                        // Collapsed layout sizes
                        final double boardSizeCollapsed = totalWidth - (boardMargin * 2);
                        final double boardAreaHeightCollapsed = totalHeight - 56.0;

                        // Expanded layout sizes
                        final double boardSizeExpanded = totalWidth - paddingValue - actionWidth - (boardMargin * 2);
                        final double boardAreaHeightExpanded = boardSizeExpanded + 24.0;

                        final double currentTop = _lerp(totalHeight - 56.0, boardAreaHeightExpanded, factor);
                        final double currentHeight = _lerp(56.0, totalHeight - boardAreaHeightExpanded, factor);

                        return Stack(
                          children: [
                            // 1. CHESSBOARD LAYER (no blur overlay, height fixed to boardAreaHeightCollapsed to prevent overflow)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: boardAreaHeightCollapsed,
                              child: ClipRect(
                                child: Stack(
                                  children: [
                                    if (isCollapsed)
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: boardMargin),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Spacer(),
                                            SizedBox(
                                              width: boardSizeCollapsed,
                                              height: boardSizeCollapsed,
                                              child: const AcademyBoard(alignment: Alignment.center),
                                            ),
                                            const Spacer(),
                                          ],
                                        ),
                                      )
                                    else
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: boardMargin, vertical: 12.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              width: boardSizeExpanded,
                                              height: boardSizeExpanded,
                                              child: const AcademyBoard(alignment: Alignment.center),
                                            ),
                                            SizedBox(width: paddingValue),
                                            Container(
                                              width: actionWidth,
                                              height: boardSizeExpanded,
                                              alignment: Alignment.center,
                                              child: _buildVerticalActionBar(context, state, notifier),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // 2. SLIDING COMMENTARY HISTORY LAYER
                            Positioned(
                              top: currentTop,
                              left: 0,
                              right: 0,
                              height: currentHeight,
                              child: _buildSlidingCommentaryPanel(context, state, factor),
                            ),
                            // 3. Floating Action Bar
                            if (factor == 0.0 && !isLandscape && !isKeyboardOpen)
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: _buildHorizontalActionBar(context, state, notifier, isDocked: false),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
                if (_showAcademyIntro)
                  GMChanakyaIntroOverlay(
                    pageTitle: 'ACADEMY',
                    text: 'Welcome to the Academy, ${state.userName}. I tune lessons to your play, rating, and scotoma report so each session targets what you need most.',
                    onDismiss: () async {
                      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
                      setState(() {
                        _showAcademyIntro = false;
                      });
                      final repo = ref.read(tutorialProgressRepositoryProvider);
                      if (repo.shouldPersistIntroSeen()) {
                        await repo.setAcademyIntroSeen(true);
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      );
  }
}

class _PremiumActionIcon extends StatefulWidget {
  const _PremiumActionIcon({
    this.icon,
    this.imagePath,
    required this.onTap,
    required this.baseColor,
    this.tooltip,
    this.isEnabled = true,
    this.isActive = false,
    this.isBlinking = false,
    this.isFlat = false,
  });

  final IconData? icon;
  final String? imagePath;
  final VoidCallback? onTap;
  final Color baseColor;
  final String? tooltip;
  final bool isEnabled;
  final bool isActive;
  final bool isBlinking;
  final bool isFlat;

  @override
  State<_PremiumActionIcon> createState() => _PremiumActionIconState();
}

class _PremiumActionIconState extends State<_PremiumActionIcon>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
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
  void didUpdateWidget(covariant _PremiumActionIcon oldWidget) {
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
    final themeColor = widget.isBlinking ? Colors.redAccent : widget.baseColor;
    final hsl = HSLColor.fromColor(themeColor);
    final darker = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0)).toColor();

    return MouseRegion(
      onEnter: widget.isEnabled ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.isEnabled ? (_) => setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTapDown: widget.isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: widget.isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isEnabled ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _blinkAnimation,
          builder: (context, child) {
            final opacity = widget.isBlinking ? _blinkAnimation.value : 1.0;

            final Color iconColor = widget.isFlat
                ? (!widget.isEnabled
                    ? ScholarlyTheme.textMuted.withValues(alpha: 0.35)
                    : widget.isBlinking
                        ? Colors.redAccent.withValues(alpha: 0.3 + 0.7 * opacity)
                        : widget.isActive
                            ? ScholarlyTheme.accentBlue
                            : _isHovered || _isPressed
                                ? widget.baseColor
                                : ScholarlyTheme.textMuted)
                : (!widget.isEnabled
                    ? ScholarlyTheme.textSubtle
                    : Colors.white);

            final double scale = _isPressed
                ? 0.92
                : _isHovered
                    ? 1.12
                    : 1.0;

            final container = AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 38,
              height: 38,
              transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: widget.isFlat
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: !widget.isEnabled
                            ? const [Color(0xFFE2E8F0), Color(0xFFCBD5E1)]
                            : [themeColor, darker],
                      ),
                color: widget.isFlat ? Colors.transparent : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isFlat
                      ? Colors.transparent
                      : (!widget.isEnabled
                          ? const Color(0xFFE2E8F0)
                          : themeColor.withValues(alpha: 0.6)),
                  width: widget.isFlat ? 0.0 : 1.5,
                ),
                boxShadow: widget.isFlat
                    ? null
                    : [
                        if (widget.isEnabled)
                          BoxShadow(
                            color: themeColor.withValues(
                              alpha: widget.isBlinking
                                  ? 0.35 * opacity
                                  : (_isPressed ? 0.5 : 0.22),
                            ),
                            blurRadius: _isHovered ? 12.0 : (widget.isBlinking ? 12.0 * opacity : 6.0),
                            spreadRadius: _isHovered ? 1.0 : 0.0,
                            offset: const Offset(0, 2),
                          ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  children: [
                    if (widget.isEnabled && !widget.isFlat)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.08),
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.25, 0.55, 1.0],
                            ),
                          ),
                        ),
                      ),
                    Center(
                      child: widget.imagePath != null
                          ? Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: AssetImage(widget.imagePath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                          : Icon(
                              widget.icon ?? Icons.help,
                              color: iconColor,
                              size: 20,
                            ),
                    ),
                  ],
                ),
              ),
            );

            return widget.tooltip != null
                ? Tooltip(
                    message: widget.tooltip!,
                    decoration: BoxDecoration(
                      color: ScholarlyTheme.backgroundDark.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    child: container,
                  )
                : container;
          },
        ),
      ),
    );
  }
}

class _BlinkingUpwardArrow extends StatefulWidget {
  const _BlinkingUpwardArrow({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BlinkingUpwardArrow> createState() => _BlinkingUpwardArrowState();
}

class _BlinkingUpwardArrowState extends State<_BlinkingUpwardArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = ScholarlyTheme.accentBlue;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _animation,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.20),
            shape: BoxShape.circle,
            border: Border.all(
              color: themeColor.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.25),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.keyboard_arrow_up_rounded,
              color: themeColor,
              size: 24,
            ),
          ),
        ),
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

    final whiteMajors = whiteCaptures.where((p) => p.type != chess_lib.PieceType.PAWN).toList();
    final whitePawns = whiteCaptures.where((p) => p.type == chess_lib.PieceType.PAWN).toList();
    final blackMajors = blackCaptures.where((p) => p.type != chess_lib.PieceType.PAWN).toList();
    final blackPawns = blackCaptures.where((p) => p.type == chess_lib.PieceType.PAWN).toList();

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: whiteMajors.isNotEmpty
                          ? _InlineCapturedGroup(pieces: whiteMajors, isWhiteTeam: true)
                          : const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: blackMajors.isNotEmpty
                          ? _InlineCapturedGroup(pieces: blackMajors, isWhiteTeam: false)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
              if (whitePawns.isNotEmpty || blackPawns.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: whitePawns.isNotEmpty
                            ? _InlineCapturedGroup(pieces: whitePawns, isWhiteTeam: true)
                            : const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: blackPawns.isNotEmpty
                            ? _InlineCapturedGroup(pieces: blackPawns, isWhiteTeam: false)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ],
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

Future<bool?> showAcademyExitDialog(BuildContext context, {required bool hasActiveMatch}) async {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: ScholarlyTheme.panelBase,
      surfaceTintColor: ScholarlyTheme.accentGold,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: ScholarlyTheme.accentGold.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      title: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage('assets/persona/gm_chanakya.png'),
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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exit Academy?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: ScholarlyTheme.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasActiveMatch
                ? 'If you leave the current match without finishing, it will not be counted in your attendance.'
                : 'Do you want to exit the academy study environment and return to the main app interface?',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textPrimary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            hasActiveMatch ? 'STAY & PLAY' : 'STAY',
            style: GoogleFonts.inter(
              color: ScholarlyTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: ScholarlyTheme.accentGold,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('EXIT'),
        ),
      ],
    ),
  );
}

