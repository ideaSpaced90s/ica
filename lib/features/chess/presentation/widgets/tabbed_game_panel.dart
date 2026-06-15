import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../application/chess_provider.dart';
import '../../domain/chess_game.dart';
import '../../domain/models/ai_avatar.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';
import 'commentary_history.dart';

class TabbedGamePanel extends ConsumerStatefulWidget {
  const TabbedGamePanel({
    super.key,
    required this.recentMoves,
    required this.viewingMoveIndex,
    required this.onMoveTap,
    required this.game,
    required this.gameMode,
    required this.isRatedMode,
    required this.engineLevel,
    required this.isPlayerWhite,
    required this.currentEvaluation,
    this.academyState,
  });

  final List<String> recentMoves;
  final int? viewingMoveIndex;
  final ValueChanged<int> onMoveTap;
  final ChessGame game;
  final String gameMode;
  final bool isRatedMode;
  final String engineLevel;
  final bool isPlayerWhite;
  final double currentEvaluation;
  final ChessState? academyState;

  @override
  ConsumerState<TabbedGamePanel> createState() => _TabbedGamePanelState();
}

class _TabbedGamePanelState extends ConsumerState<TabbedGamePanel> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Windows grey panel background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Horizontal Tabs at top (classic Windows property sheet style)
          _buildTabBar(),
          
          // Tab Content Area with classic inset border
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
              ),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final hasCoach = widget.academyState != null;
    final tabTitles = [
      if (hasCoach) 'AI Coach',
      'Move History',
      'Game Metrics',
    ];
    final tabIcons = [
      if (hasCoach) Icons.psychology_rounded,
      Icons.history_edu_rounded,
      Icons.analytics_rounded,
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
      decoration: const BoxDecoration(
        color: Color(0xFFE2E8F0), // Tab strip background
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
        border: Border(
          bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
      ),
      child: Row(
        children: List.generate(tabTitles.length, (index) {
          final isActive = _activeTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeTab != index) {
                  ref.read(chessSoundServiceProvider).playSfx(SoundEffect.tabSwipe);
                  setState(() => _activeTab = index);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : const Color(0xFFF1F5F9),
                  border: Border(
                    top: BorderSide(
                      color: isActive ? ScholarlyTheme.accentBlue : Colors.transparent,
                      width: 2.5,
                    ),
                    left: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                    right: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
                    bottom: BorderSide(
                      color: isActive ? Colors.white : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tabIcons[index],
                      size: 13,
                      color: isActive ? ScholarlyTheme.accentBlue : ScholarlyTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tabTitles[index],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? ScholarlyTheme.textPrimary : ScholarlyTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    final hasCoach = widget.academyState != null;
    final index = hasCoach ? _activeTab : _activeTab + 1;
    switch (index) {
      case 0:
        return CommentaryHistory(state: widget.academyState!);
      case 1:
        return _buildMoveHistoryTab();
      case 2:
        return _buildGameMetricsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMoveHistoryTab() {
    final moves = widget.recentMoves;

    if (moves.isEmpty) {
      return const Center(
        child: Text(
          'No moves played yet.',
          style: TextStyle(
            color: ScholarlyTheme.textMuted,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final List<List<String>> pairs = [];
    for (int i = 0; i < moves.length; i += 2) {
      pairs.add([moves[i], if (i + 1 < moves.length) moves[i + 1]]);
    }

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFFF1F5F9),
          child: Row(
            children: [
              SizedBox(
                width: 45,
                child: Text(
                  'Move',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'White',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Black',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: ScholarlyTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Move List
        Expanded(
          child: Scrollbar(
            thickness: 6,
            radius: const Radius.circular(3),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: pairs.length,
              itemBuilder: (context, index) {
                final pair = pairs[index];
                final whiteIdx = index * 2;
                final blackIdx = index * 2 + 1;

                final isWhiteViewing = widget.viewingMoveIndex == whiteIdx;
                final isBlackViewing = widget.viewingMoveIndex == blackIdx;

                return Container(
                  color: index % 2 == 0 ? Colors.transparent : const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      // Move Number
                      SizedBox(
                        width: 45,
                        child: Text(
                          '${index + 1}.',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            color: ScholarlyTheme.accentBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // White Move
                      Expanded(
                        child: GestureDetector(
                          onTap: () => widget.onMoveTap(whiteIdx),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isWhiteViewing
                                    ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isWhiteViewing
                                      ? ScholarlyTheme.accentBlue.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                pair[0],
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: isWhiteViewing ? FontWeight.bold : FontWeight.w500,
                                  color: isWhiteViewing ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Black Move
                      Expanded(
                        child: pair.length > 1
                            ? GestureDetector(
                                onTap: () => widget.onMoveTap(blackIdx),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isBlackViewing
                                          ? ScholarlyTheme.accentBlue.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: isBlackViewing
                                            ? ScholarlyTheme.accentBlue.withValues(alpha: 0.4)
                                            : Colors.transparent,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      pair[1],
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: isBlackViewing ? FontWeight.bold : FontWeight.w500,
                                        color: isBlackViewing ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Live Position Helper
        if (widget.viewingMoveIndex != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              border: Border(top: BorderSide(color: Color(0xFFDBEAFE), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 12, color: ScholarlyTheme.accentBlue),
                    const SizedBox(width: 6),
                    Text(
                      'Viewing past position',
                      style: GoogleFonts.inter(fontSize: 10, color: ScholarlyTheme.accentBlue, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => widget.onMoveTap(-1),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Live Game',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ScholarlyTheme.accentBlue,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.skip_next_rounded, size: 12, color: ScholarlyTheme.accentBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGameMetricsTab() {
    final avatar = AiAvatar.getAvatar(widget.engineLevel);
    final fen = widget.game.fen;
    final activePgn = _generateActivePgn();

    return Scrollbar(
      thickness: 6,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildMetricsSectionHeader('MATCH CONFIGURATION'),
          _buildMetricRow('Game Mode', widget.gameMode.toUpperCase(), isMonospace: true),
          _buildMetricRow('Match Type', widget.isRatedMode ? 'RATED ELO MATCH' : 'UNRATED ZEN PRACTICE'),
          _buildMetricRow('Opponent Engine', avatar.name, valueColor: ScholarlyTheme.accentBlue),
          _buildMetricRow('Engine Skill Level', 'Level ${avatar.skillLevel} (approx. ${avatar.rating} ELO)'),
          _buildMetricRow('Your Color', widget.isPlayerWhite ? 'WHITE' : 'BLACK'),
          
          const SizedBox(height: 12),
          _buildMetricsSectionHeader('GAME PROGRESS'),
          _buildMetricRow('Moves Played', '${widget.recentMoves.length}'),
          _buildMetricRow('Active Turn', widget.game.gameOver ? 'GAME OVER' : (widget.game.turnColor == 'w' ? 'WHITE' : 'BLACK')),
          _buildMetricRow('Evaluation Score', '${widget.currentEvaluation.toStringAsFixed(2)} cp'),

          const SizedBox(height: 12),
          _buildMetricsSectionHeader('BOARD FEN'),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    fen,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: ScholarlyTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  tooltip: 'Copy FEN',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: fen));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('FEN copied to clipboard!'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          _buildMetricsSectionHeader('EXPORT GAME'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: activePgn));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('PGN copied to clipboard!'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all_rounded, size: 13),
                  label: const Text('Copy PGN Notation'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600),
                    foregroundColor: ScholarlyTheme.textPrimary,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: ScholarlyTheme.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isMonospace = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: ScholarlyTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: isMonospace
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? ScholarlyTheme.textPrimary,
                  )
                : GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? ScholarlyTheme.textPrimary,
                  ),
          ),
        ],
      ),
    );
  }

  String _generateActivePgn() {
    final buffer = StringBuffer();
    final dateStr = DateFormat('yyyy.MM.dd').format(DateTime.now());
    final title = '${widget.gameMode.toUpperCase()} MATCH';

    buffer.writeln('[Event "$title"]');
    buffer.writeln('[Site "IdeaSpace Chess Academy"]');
    buffer.writeln('[Date "$dateStr"]');
    buffer.writeln('[Round "1"]');
    buffer.writeln('[White "${widget.isPlayerWhite ? "Player" : "Stockfish"}"]');
    buffer.writeln('[Black "${widget.isPlayerWhite ? "Stockfish" : "Player"}"]');
    buffer.writeln('[Result "*"]');
    if (widget.gameMode == 'chess960') {
      buffer.writeln('[Variant "Chess960"]');
      buffer.writeln('[FEN "${widget.game.fen}"]');
      buffer.writeln('[SetUp "1"]');
    }
    buffer.writeln();

    for (int i = 0; i < widget.recentMoves.length; i++) {
      if (i % 2 == 0) {
        buffer.write('${(i ~/ 2) + 1}. ');
      }
      buffer.write('${widget.recentMoves[i]} ');
    }
    buffer.write('*');
    return buffer.toString();
  }
}
