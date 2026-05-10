import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/chess_provider.dart';
import '../../data/saved_game.dart';
import '../scholarly_theme.dart';

class CommentaryHistory extends StatefulWidget {
  const CommentaryHistory({super.key, required this.state});

  final ChessState state;

  @override
  State<CommentaryHistory> createState() => _CommentaryHistoryState();
}

class _CommentaryHistoryState extends State<CommentaryHistory> {
  late final Ticker _ticker;
  int _pulse = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((_) {
      if (!mounted) return;
      setState(() {
        _pulse = (_pulse + 1) % 4;
      });
    })..start();
  }

  @override
  void didUpdateWidget(CommentaryHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state.commentaryHistory.length != oldWidget.state.commentaryHistory.length ||
        (widget.state.commentaryHistory.isNotEmpty && 
         widget.state.commentaryHistory.last.text != oldWidget.state.commentaryHistory.last.text)) {
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
    super.dispose();
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final history = state.commentaryHistory;
    
    return Container(
      decoration: ScholarlyTheme.win98Decoration(sunken: true).copyWith(
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(8),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _buildContent(state, history),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ChessState state, List<CommentaryEntry> history) {
    if (state.startupError != null || state.commentaryError != null) {
      return Text(
        state.startupError ?? state.commentaryError!,
        style: GoogleFonts.vt323(color: Colors.red, fontSize: 16),
      );
    }

    if (state.isCommentaryEngineLoading && history.isEmpty) {
      return Center(
        child: Text(
          'Initializing Kingslayer AI...',
          style: GoogleFonts.vt323(
            color: Colors.black,
            fontSize: 18,
          ),
        ),
      );
    }

    if (history.isEmpty && !state.isCommentaryLoading) {
      return Text(
        'KINGSLAYER awaits your opening gambit.',
        style: GoogleFonts.vt323(color: Colors.black54, fontSize: 18),
      );
    }

    final dots = '■' * _pulse; 

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: history.length + (state.isCommentaryLoading && !state.isCommentaryStreaming ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == history.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'KINGSLAYER is thinking $dots',
              style: GoogleFonts.vt323(
                color: Colors.black87,
                fontSize: 16,
              ),
            ),
          );
        }

        final entry = history[index];
        final isLast = index == history.length - 1;
        final isStreaming = isLast && state.isCommentaryStreaming;
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '[${_formatTime(entry.timestamp)}] ',
                  style: GoogleFonts.vt323(
                    color: Colors.black45,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: entry.text,
                  style: GoogleFonts.vt323(
                    color: Colors.black,
                    fontSize: 18,
                    height: 1.1,
                  ),
                ),
                if (!entry.isComplete && !isStreaming)
                   TextSpan(
                    text: ' ■', 
                    style: GoogleFonts.vt323(
                      color: Colors.black,
                      fontSize: 18,
                    ),
                  ),
                if (isStreaming)
                  TextSpan(
                    text: ' |', 
                    style: GoogleFonts.vt323(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

