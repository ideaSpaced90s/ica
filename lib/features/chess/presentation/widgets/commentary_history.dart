import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../data/saved_game.dart';
import '../scholarly_theme.dart';

class CommentaryHistory extends ConsumerStatefulWidget {
  const CommentaryHistory({super.key, required this.state});

  final ChessState state;

  @override
  ConsumerState<CommentaryHistory> createState() => _CommentaryHistoryState();
}

class _CommentaryHistoryState extends ConsumerState<CommentaryHistory> {
  late final Ticker _ticker;
  int _pulse = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    if (widget.state.commentaryHistory.length !=
            oldWidget.state.commentaryHistory.length ||
        (widget.state.commentaryHistory.isNotEmpty &&
            widget.state.commentaryHistory.last.text !=
                oldWidget.state.commentaryHistory.last.text)) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    _textController.dispose();
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: ScholarlyTheme.backgroundStart.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: (_) => _handleSend(),
              style: GoogleFonts.inter(
                fontSize: 13,
                color: ScholarlyTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Ask GM Bard...',
                hintStyle: GoogleFonts.inter(
                  color: ScholarlyTheme.textSubtle,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          IconButton(
            onPressed: _handleSend,
            icon: Icon(
              Icons.send_rounded,
              size: 18,
              color: ScholarlyTheme.accentBlue,
            ),
            tooltip: 'Send Message',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(chessProvider.notifier).sendUserQuery(text);
    _textController.clear();
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
              'Initializing GM Bard...',
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
            backgroundImage: const AssetImage('assets/persona/gm_bard.png'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GM BARD • ${_formatTime(entry.timestamp)}',
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
                              'GM Bard is writing',
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
                      : Text.rich(
                          TextSpan(
                            children: [
                              ..._parseAcademyRichText(entry.text, widget.state),
                              if (!entry.isComplete && !isStreaming)
                                TextSpan(
                                  text: ' •••',
                                  style: GoogleFonts.fraunces(
                                    color: ScholarlyTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              if (isStreaming)
                                TextSpan(
                                  text: ' ┃',
                                  style: GoogleFonts.fraunces(
                                    color: ScholarlyTheme.accentBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _parseAcademyRichText(String text, ChessState state) {
    final List<InlineSpan> spans = [];
    final regExp = RegExp(
      r'\*\*(.*?)\*\*|\b(Apprentice|Defender of Humanity|Kingslayer|Bard)\b|\b(King|Queen|Rook|Bishop|Knight|Pawn)s?\b|\b([a-h][1-8])\b|\b([NBRQK]?[a-h]?[1-8]?x?[a-h][1-8](?:=[NBRQK])?[+#]?|O-O(?:-O)?)\b',
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
        // Markdown Bold
        spans.add(TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(
            fontWeight: state.academyHouseBoldEmphasis ? FontWeight.w800 : FontWeight.bold,
          ),
        ));
      } else if (match.group(2) != null) {
        // Personas/Titles
        final name = match.group(2)!;
        Color color = ScholarlyTheme.accentBlue;
        if (name.toLowerCase().contains('apprentice')) color = const Color(0xFFD4AF37); // Academy Gold
        if (name.toLowerCase().contains('kingslayer')) color = Colors.redAccent;

        spans.add(TextSpan(
          text: name,
          style: baseStyle.copyWith(
            color: state.academyHouseColorFonts ? color : ScholarlyTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(3) != null) {
        // Piece Name
        spans.add(TextSpan(
          text: match.group(0),
          style: baseStyle.copyWith(
            color: state.academyHouseColorFonts ? ScholarlyTheme.accentBlue : ScholarlyTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ));
      } else if (match.group(4) != null || match.group(5) != null) {
        // Square or Move (Notation Chips)
        final notation = match.group(0)!;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              notation,
              style: GoogleFonts.jetBrainsMono(
                color: ScholarlyTheme.accentBlue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
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
}
