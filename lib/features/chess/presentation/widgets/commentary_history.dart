import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../data/saved_game.dart';
import '../../services/chess_sound_service.dart';
import '../scholarly_theme.dart';

class CommentaryHistory extends ConsumerStatefulWidget {
  const CommentaryHistory({super.key, required this.state, this.physics, this.controller});

  final ChessState state;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  @override
  ConsumerState<CommentaryHistory> createState() => _CommentaryHistoryState();
}

class _CommentaryHistoryState extends ConsumerState<CommentaryHistory> {
  late final Ticker _ticker;
  int _pulse = 0;
  late final ScrollController _scrollController;
  String _selectedMode = 'classic';


  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _ticker = Ticker((elapsed) {
      if (!mounted) return;
      setState(() {
        _pulse = ((elapsed.inMilliseconds ~/ 300) % 4);
      });
    })..start();
  }

  @override
  void didUpdateWidget(CommentaryHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    final history = widget.state.commentaryHistory;
    final oldHistory = oldWidget.state.commentaryHistory;

    if (history.length > 1 && (history.length != oldHistory.length ||
        widget.state.isCommentaryStreaming ||
        widget.state.isCommentaryLoading ||
        (history.isNotEmpty && oldHistory.isNotEmpty && history.last.text != oldHistory.last.text))) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (widget.state.isCommentaryStreaming || widget.state.isCommentaryLoading) {
          _scrollController.jumpTo(maxScroll);
        } else {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    if (widget.controller == null) {
      _scrollController.dispose();
    }

    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final history = state.commentaryHistory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SelectionArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: _buildContent(state, history),
            ),
          ),
        ),
        const Divider(height: 1, color: ScholarlyTheme.panelStroke),
        _buildInput(context),
      ],
    );
  }

  Widget _buildInput(BuildContext context) {
    final state = widget.state;
    final bool isBusy = state.isCommentaryLoading || state.isCommentaryStreaming || state.isWaitingForSideChoice || state.isAcademyBlunderActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: ScholarlyTheme.backgroundStart.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _buildPromptButton('Analyze', Icons.analytics_rounded, isBusy)),
              const SizedBox(width: 4),
              Expanded(child: _buildPromptButton('Why', Icons.psychology_rounded, isBusy)),
              const SizedBox(width: 4),
              Expanded(child: _buildPromptButton('Candidates', Icons.alt_route_rounded, isBusy)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildPromptButton('Tactics', Icons.flash_on_rounded, isBusy)),
              const SizedBox(width: 4),
              Expanded(child: _buildPromptButton('Plan', Icons.explore_rounded, isBusy)),
              const SizedBox(width: 4),
              Expanded(child: _buildPromptButton('Defend', Icons.shield_rounded, isBusy)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptButton(String label, IconData icon, bool isBusy) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : () => _handlePromptTap(label),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isBusy 
                ? ScholarlyTheme.panelStroke.withValues(alpha: 0.2)
                : ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
            border: Border.all(
              color: isBusy
                  ? ScholarlyTheme.panelStroke.withValues(alpha: 0.3)
                  : ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isBusy
                    ? ScholarlyTheme.textSubtle
                    : ScholarlyTheme.accentBlue,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isBusy
                        ? ScholarlyTheme.textSubtle
                        : ScholarlyTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const Map<String, String> _chipPresets = {
    'Analyze':    'Let me survey the board as it stands, Apprentice. ',
    'Why':        "Your opponent's last move was no accident, Apprentice. ",
    'Candidates': 'I shall lay before you the most worthy paths forward, Apprentice. ',
    'Tactics':    'The board harbours hidden danger — let me expose it, Apprentice. ',
    'Plan':       'A true master acts on a plan, not on instinct alone, Apprentice. ',
    'Defend':     'When under pressure, the wise first consolidate, Apprentice. ',
  };

  void _handlePromptTap(String label) {
    final preset = _chipPresets[label];
    ref.read(chessProvider.notifier).sendUserQuery(label, titlePrefix: preset);
    FocusScope.of(context).unfocus();
  }


  Widget _buildContent(ChessState state, List<CommentaryEntry> history) {
    if (state.startupError != null || state.commentaryError != null) {
      return Center(
        child: Text(
          state.startupError ?? state.commentaryError!,
          style: GoogleFonts.inter(
            color: Colors.red.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.isCommentaryEngineLoading && history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ScholarlyTheme.accentBlue,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Initializing GM Chanakya...',
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: widget.physics,
      padding: EdgeInsets.zero,
      itemCount: history.length,
      itemBuilder: (context, index) {
        final entry = history[index];
        final isLast = index == history.length - 1;
        final isStreaming = isLast && state.isCommentaryStreaming;

        if (entry.isUser) {
          return _buildUserBubble(entry);
        }

        return _buildAiBubble(entry, isStreaming);
      },
    );
  }

  Widget _buildUserBubble(CommentaryEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'YOU • ${_formatTime(entry.timestamp)}',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: ScholarlyTheme.textSubtle,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              entry.text,
              style: GoogleFonts.inter(
                color: ScholarlyTheme.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(CommentaryEntry entry, bool isStreaming) {
    final bool isThinking = entry.text.isEmpty && !entry.isComplete;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.transparent,
            backgroundImage: const AssetImage('assets/persona/gm_chanakya.png'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GM CHANAKYA • ${_formatTime(entry.timestamp)}',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.backgroundStart,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    border: Border.all(
                      color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
                    ),
                  ),
                  child: isThinking
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'GM Chanakya is writing',
                              style: GoogleFonts.fraunces(
                                color: ScholarlyTheme.textMuted,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(3, (index) {
                                final isActive = _pulse >= index + 1;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1.5),
                                  width: 4,
                                  height: isActive ? 6 : 4,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? ScholarlyTheme.accentBlue
                                        : ScholarlyTheme.textMuted
                                            .withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  ..._parseAcademyRichText(entry.text, widget.state),
                                  if (!entry.isComplete && !isStreaming)
                                    TextSpan(
                                      text: ' ${'.' * ((_pulse % 3) + 1)}',
                                      style: GoogleFonts.fraunces(
                                        color: ScholarlyTheme.accentBlue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  if (isStreaming)
                                    TextSpan(
                                      text: _pulse % 2 == 0 ? ' ┃' : '  ',
                                      style: GoogleFonts.fraunces(
                                        color: ScholarlyTheme.accentBlue,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (widget.state.isWaitingForSideChoice &&
                                widget.state.commentaryHistory.indexOf(entry) ==
                                    widget.state.commentaryHistory.length - 1) ...[
                              const SizedBox(height: 12),
                              _buildModeTabs(),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildSideSelectionButton(
                                      context: context,
                                      label: "WHITE",
                                      isWhite: true,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildSideSelectionButton(
                                      context: context,
                                      label: "BLACK",
                                      isWhite: false,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (widget.state.isAcademyBlunderActive &&
                                entry.isComplete &&
                                widget.state.commentaryHistory.indexOf(entry) ==
                                    widget.state.commentaryHistory.length - 1) ...[
                              const SizedBox(height: 12),
                              _buildContinueButton(),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(chessProvider.notifier).continueAfterBlunder();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: ScholarlyTheme.accentBlue,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'CONTINUE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeTabs() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ScholarlyTheme.panelStroke.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTabButton(
              label: 'CLASSIC',
              isActive: _selectedMode == 'classic',
              onTap: () {
                setState(() {
                  _selectedMode = 'classic';
                });
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              },
            ),
          ),
          Expanded(
            child: _buildModeTabButton(
              label: 'CHESS 960',
              isActive: _selectedMode == 'chess960',
              onTap: () {
                setState(() {
                  _selectedMode = 'chess960';
                });
                ref.read(chessSoundServiceProvider).playSfx(SoundEffect.uiClick);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? ScholarlyTheme.accentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : ScholarlyTheme.textMuted,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSideSelectionButton({
    required BuildContext context,
    required String label,
    required bool isWhite,
  }) {
    final activeColor = isWhite ? Colors.white : Colors.grey.shade900;
    final textColor = isWhite ? Colors.black87 : Colors.white;
    final strokeColor = isWhite ? const Color(0xFFD4AF37) : ScholarlyTheme.accentBlue;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(chessProvider.notifier).selectAcademySide(isWhite, gameMode: _selectedMode);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: activeColor,
            border: Border.all(
              color: strokeColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: strokeColor.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _parseAcademyRichText(String text, ChessState state) {
    final List<InlineSpan> spans = [];
    final regExp = RegExp(
      r'\*\*(.*?)\*\*|'
      r'\b(Apprentice|Defender of Humanity|Kingslayer|Chanakya)\b|'
      r'\b(King|Queen|Rook|Bishop|Knight|Pawn)s?\b|'
      r'\b(Consider|Observe|Strategy|Warning|Tactics|Recommended|Crucial|Focus|Analyze)\b|'
      r'\b([a-h][1-8]-?[a-h][1-8]|[a-h][1-8])\b|'
      r'\b([NBRQK]?[a-h]?[1-8]?x?[a-h][1-8](?:=[NBRQK])?[+#]?|O-O(?:-O)?)\b',
      caseSensitive: false,
    );

    int lastIndex = 0;
    final baseStyle = GoogleFonts.fraunces(
      color: ScholarlyTheme.textPrimary,
      fontSize: 14,
      height: 1.5,
    );

    for (final match in regExp.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: baseStyle,
        ));
      }

      if (match.group(1) != null) {
        // Markdown Bold - Check if it's actually a move hidden in bold
        final content = match.group(1)!;
        final moveRegex = RegExp(
          r'^([a-h][1-8]-?[a-h][1-8]|[a-h][1-8]|[NBRQK]?[a-h]?[1-8]?x?[a-h][1-8](?:=[NBRQK])?[+#]?|O-O(?:-O)?)$',
          caseSensitive: false,
        );

        final blunderMatch = RegExp(
          r'^(.+?):\s+(Pawn|Knight|Bishop|Rook|Queen|King)\s+([a-h][1-8]-[a-h][1-8])$',
          caseSensitive: false,
        ).firstMatch(content);

        if (blunderMatch != null) {
          final userName = blunderMatch.group(1)!;
          final pieceName = blunderMatch.group(2)!;
          final moveNotation = blunderMatch.group(3)!;

          // 1. User Name + Colon
          spans.add(TextSpan(
            text: '$userName: ',
            style: baseStyle.copyWith(
              color: const Color(0xFFD4AF37), // Academy Gold
              fontWeight: FontWeight.bold,
            ),
          ));

          // 2. Piece Name (Red and Bold)
          spans.add(TextSpan(
            text: '$pieceName ',
            style: baseStyle.copyWith(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ));

          // 3. Move notation in red and boxed
          spans.addAll(_buildSplitNotationSpans(moveNotation, baseStyle, state, isRed: true));
        } else if (moveRegex.hasMatch(content)) {
          spans.addAll(_buildSplitNotationSpans(content, baseStyle, state));
        } else {
          spans.add(TextSpan(
            text: content,
            style: baseStyle.copyWith(
              fontWeight: state.academyHouseBoldEmphasis
                  ? FontWeight.w800
                  : FontWeight.bold,
            ),
          ));
        }
      } else if (match.group(2) != null) {
        // Personas/Titles
        final name = match.group(2)!;
        Color color = ScholarlyTheme.accentBlue;
        if (name.toLowerCase().contains('apprentice')) {
          color = const Color(0xFFD4AF37); // Academy Gold
        }
        if (name.toLowerCase().contains('kingslayer')) color = Colors.redAccent;

        spans.add(TextSpan(
          text: name,
          style: baseStyle.copyWith(
            color: state.academyHouseColorFonts
                ? color
                : ScholarlyTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(3) != null) {
        // Piece Name
        spans.add(TextSpan(
          text: match.group(0),
          style: baseStyle.copyWith(
            color: state.academyHouseColorFonts
                ? ScholarlyTheme.accentBlue
                : ScholarlyTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              ref.read(chessProvider.notifier).triggerAcademyAnimation();
            },
        ));
      } else if (match.group(4) != null) {
        // Instructions/Keywords
        final word = match.group(4)!;
        Color color = Colors.indigo;
        final lWord = word.toLowerCase();
        if (lWord.contains('warning')) color = Colors.amber.shade700;
        if (lWord.contains('strategy')) color = Colors.teal;
        if (lWord.contains('tactics')) color = Colors.pink;
        if (lWord.contains('crucial') || lWord.contains('focus')) {
          color = Colors.deepOrange;
        }
        if (lWord.contains('analyze') || lWord.contains('observe')) {
          color = Colors.deepPurple;
        }

        spans.add(TextSpan(
          text: word,
          style: baseStyle.copyWith(
            color: state.academyHouseColorFonts ? color : ScholarlyTheme.textPrimary,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(5) != null || match.group(6) != null) {
        // Square or Move (Notation Chips)
        final notation = match.group(0)!;
        spans.addAll(_buildSplitNotationSpans(notation, baseStyle, state));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: baseStyle,
      ));
    }

    return spans;
  }

  List<InlineSpan> _buildSplitNotationSpans(
    String notation,
    TextStyle baseStyle,
    ChessState state, {
    bool isRed = false,
  }) {
    final List<InlineSpan> spans = [];
    final themeColor = isRed ? Colors.redAccent : ScholarlyTheme.accentBlue;

    if (notation.contains('-')) {
      final parts = notation.split('-');
      // First square chip
      spans.add(_buildSingleNotationChip(parts[0], parts[0], state, isRed: isRed));
      // Hyphen
      spans.add(TextSpan(
        text: '-',
        style: baseStyle.copyWith(
          color: themeColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      // Second square chip (targets the actual destination square)
      spans.add(_buildSingleNotationChip(parts[1], parts[1], state, isRed: isRed));
    } else {
      // Single notation chip
      String? targetSquare;
      final squareMatches = RegExp(r'[a-h][1-8]').allMatches(notation);
      if (squareMatches.isNotEmpty) {
        targetSquare = squareMatches.last.group(0);
      }
      spans.add(_buildSingleNotationChip(notation, targetSquare, state, isRed: isRed));
    }
    return spans;
  }

  WidgetSpan _buildSingleNotationChip(
    String label,
    String? targetSquare,
    ChessState state, {
    bool isRed = false,
  }) {
    final themeColor = isRed ? Colors.redAccent : ScholarlyTheme.accentBlue;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: GestureDetector(
        onTap: targetSquare == null
            ? null
            : () {
                ref.read(chessProvider.notifier).glowSquare(targetSquare);
                ref.read(chessProvider.notifier).triggerAcademyAnimation();
              },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.firaCode(
              color: themeColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
