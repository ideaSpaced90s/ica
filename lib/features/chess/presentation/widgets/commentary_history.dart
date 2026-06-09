import 'dart:io';
import 'dart:math' as math;
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: _buildContent(state, history),
          ),
        ),
        const Divider(height: 1, color: ScholarlyTheme.panelStroke),
        _buildInput(context),
      ],
    );
  }

  Widget _buildInput(BuildContext context) {
    final state = widget.state;
    final bool isBusy = state.isCommentaryLoading ||
        state.isCommentaryStreaming ||
        state.isWaitingForSideChoice ||
        state.isAcademyBlunderActive ||
        state.isBoardInChampionsTheme;
    final bool hasHistory = state.game.history.isNotEmpty;

    if (state.isTacticsModeActive) {
      final moves = state.tacticsSequence;
      final bool hasMoves = moves.isNotEmpty;
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ScholarlyTheme.backgroundStart.withValues(alpha: 0.8),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border(
            top: BorderSide(color: ScholarlyTheme.panelStroke.withValues(alpha: 0.3)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasMoves) ...[
              Container(
                height: 36,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: moves.length,
                  itemBuilder: (context, index) {
                    final step = moves[index];
                    final isUser = step.isUserMove;
                    final text = '${step.from}${step.to}';
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUser
                            ? ScholarlyTheme.accentGold.withValues(alpha: 0.15)
                            : ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.15),
                        border: Border.all(
                          color: isUser
                              ? ScholarlyTheme.accentGold.withValues(alpha: 0.6)
                              : ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.6),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          text,
                          style: GoogleFonts.inter(
                            color: isUser ? ScholarlyTheme.accentGold : ScholarlyTheme.accentBlueSoft,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              Container(
                height: 36,
                margin: const EdgeInsets.only(bottom: 8),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Make your tactical moves on the board...',
                  style: GoogleFonts.inter(
                    color: ScholarlyTheme.textMuted,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(chessProvider.notifier).cancelTacticsMode();
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: hasMoves
                          ? [
                              BoxShadow(
                                color: ScholarlyTheme.accentGold.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: hasMoves
                          ? () {
                              ref.read(chessProvider.notifier).finishTacticsInput();
                            }
                          : null,
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: const Text('Finish'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScholarlyTheme.accentGold,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: ScholarlyTheme.panelStroke.withValues(alpha: 0.3),
                        disabledForegroundColor: ScholarlyTheme.textMuted,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: ScholarlyTheme.backgroundStart.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildPromptButton('Analyze', Icons.analytics_rounded, isBusy || _hasPromptBeenRaised('Analyze'))),
          const SizedBox(width: 4),
          Expanded(child: _buildPromptButton('Why', Icons.psychology_rounded, isBusy || !hasHistory || _hasPromptBeenRaised('Why'))),
          const SizedBox(width: 4),
          Expanded(child: _buildPromptButton('Candidates', Icons.alt_route_rounded, isBusy || _hasPromptBeenRaised('Candidates'))),
          const SizedBox(width: 4),
          Expanded(child: _buildPromptButton('Tactics', Icons.flash_on_rounded, isBusy || !hasHistory || _hasPromptBeenRaised('Tactics'))),
          const SizedBox(width: 4),
          Expanded(child: _buildPromptButton('Plan', Icons.explore_rounded, isBusy || _hasPromptBeenRaised('Plan'))),
          const SizedBox(width: 4),
          Expanded(child: _buildPromptButton('Defend', Icons.shield_rounded, isBusy || !hasHistory || _hasPromptBeenRaised('Defend'))),
        ],
      ),
    );
  }

  bool _hasPromptBeenRaised(String label) {
    final state = widget.state;
    if (label == 'Tactics') {
      for (final entry in state.commentaryHistory) {
        if (entry.isUser &&
            entry.associatedFen == state.currentBoardFen &&
            entry.text.startsWith('[TACTICS_QUERY]')) {
          return true;
        }
      }
      return false;
    }
    final fullQuestion = _fullQuestions[label] ?? label;
    for (final entry in state.commentaryHistory) {
      if (entry.isUser &&
          entry.associatedFen == state.currentBoardFen &&
          entry.text == fullQuestion) {
        return true;
      }
    }
    return false;
  }

  Widget _buildPromptButton(String label, IconData icon, bool isBusy) {
    final tooltipMsg = _tooltips[label] ?? label;
    return Tooltip(
      message: tooltipMsg,
      preferBelow: false,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : () => _handlePromptTap(label),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
            child: Icon(
              icon,
              size: 18,
              color: isBusy
                  ? ScholarlyTheme.textSubtle
                  : ScholarlyTheme.accentBlue,
            ),
          ),
        ),
      ),
    );
  }

  static const Map<String, String> _tooltips = {
    'Analyze':    'Analyze Position',
    'Why':        'Why this move?',
    'Candidates': 'Candidate Moves',
    'Tactics':    'Find Tactics',
    'Plan':       'Formulate Plan',
    'Defend':     'Defensive Ideas',
  };

  static const Map<String, List<String>> _chipPresets = {
    'Analyze': [
      'Let me survey the board as it stands, Apprentice. ',
      'Let us examine the coordinate grid and piece activity, Apprentice. ',
      'I shall cast my eye across the 64 squares, Apprentice. ',
      'Analyzing the layout of the battleground, Apprentice. ',
      'Let us look at the structure and piece alignments, Apprentice. ',
    ],
    'Why': [
      "Well, I didn't play that by accident, Apprentice. ",
      "Every move carries an intention, Apprentice. ",
      "A move is not just a change of square — it is a statement, Apprentice. ",
      "Let me explain the reasoning behind my choice, Apprentice. ",
      "You question the logic? Let me clarify it for you, Apprentice. ",
    ],
    'Candidates': [
      'I shall lay before you the most worthy paths forward, Apprentice. ',
      'Consider these candidate options, Apprentice. ',
      'The position offers a few promising avenues, Apprentice. ',
      'Here are the moves that command our attention, Apprentice. ',
      'Let us list the candidate continuations, Apprentice. ',
    ],
    'Tactics': [
      'Does the board harbour hidden danger? — let me expose it, Apprentice. ',
      'Tactics are the teeth of strategy. Let us look closer, Apprentice. ',
      'Let us see if there are any immediate tactical opportunities, Apprentice. ',
      'A sharp eye finds the hidden alignments and pins, Apprentice. ',
      'Scanning the position for threats and combinations, Apprentice. ',
    ],
    'Plan': [
      'A true master acts on a plan, not on instinct alone, Apprentice. ',
      'Without a plan, we are merely moving pieces, Apprentice. ',
      'Every strategic position requires a long-term goal, Apprentice. ',
      'Let us formulate a coherent strategy for this layout, Apprentice. ',
      'A plan gives direction to our tactical ideas, Apprentice. ',
    ],
    'Defend': [
      'When under pressure, the wise first consolidate, Apprentice. ',
      'A good shield is as valuable as a sharp sword, Apprentice. ',
      'First, we must secure our own weaknesses, Apprentice. ',
      'Let us look at how to reinforce our structure, Apprentice. ',
      'Defense is an art of patience and resilience, Apprentice. ',
    ],
  };

  static const Map<String, String> _fullQuestions = {
    'Analyze':    'Chanakya, can you analyze the current board state and summarize the position?',
    'Why':        'Why did you play that last move, Chanakya? What are your intentions?',
    'Candidates': 'Chanakya, what candidate moves do you suggest I consider from here?',
    'Tactics':    'Chanakya, are there any active tactics or tactical combinations in this position?',
    'Plan':       'What plan or structural goals should I focus on next, Chanakya?',
    'Defend':     'How should I defend my position and counter your active ideas, Chanakya?',
  };

  void _handlePromptTap(String label) {
    if (label == 'Tactics') {
      ref.read(chessProvider.notifier).enterTacticsMode();
      FocusScope.of(context).unfocus();
      return;
    }
    final fullQuestion = _fullQuestions[label] ?? label;
    final presets = _chipPresets[label];
    String preset = '';
    if (presets != null && presets.isNotEmpty) {
      preset = presets[math.Random().nextInt(presets.length)];
    }
    preset = preset.replaceAll('Apprentice', '**${widget.state.userName}**');
    ref.read(chessProvider.notifier).sendUserQuery(fullQuestion, titlePrefix: preset);
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
    final avatarPath = widget.state.userAvatarPath;
    final userName = widget.state.userName.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$userName • ${_formatTime(entry.timestamp)}',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: ScholarlyTheme.textSubtle,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.accentBlueSoft.withValues(alpha: 0.35),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.25),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    entry.text.startsWith('[TACTICS_QUERY]')
                        ? entry.text.replaceFirst('[TACTICS_QUERY]', '').trim()
                        : entry.text,
                    style: GoogleFonts.inter(
                      color: ScholarlyTheme.textPrimary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.transparent,
              backgroundImage: avatarPath.startsWith('assets/')
                  ? AssetImage(avatarPath) as ImageProvider
                  : FileImage(File(avatarPath)) as ImageProvider,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiBubble(CommentaryEntry entry, bool isStreaming) {
    final bool isThinking = !entry.isComplete;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: ScholarlyTheme.accentBlue.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage('assets/persona/gm_chanakya.png'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GM CHANAKYA • ${_formatTime(entry.timestamp)}',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: ScholarlyTheme.accentBlue.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.backgroundStart,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: ScholarlyTheme.panelStroke.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isThinking
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DottedGridLoader(),
                            SizedBox(width: 12),
                            Text(
                              'GM Chanakya is formulating counsel...',
                              style: TextStyle(
                                color: ScholarlyTheme.textMuted,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
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
                                  ..._parseAcademyRichText(
                                    _cleanTacticsText(entry.text),
                                    widget.state,
                                    entry.text,
                                    isBubbleActive: entry.associatedFen == widget.state.currentBoardFen,
                                  ),
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
                            _buildTacticCards(entry, widget.state),
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

  List<InlineSpan> _parseAcademyRichText(
    String text,
    ChessState state,
    String fullText, {
    required bool isBubbleActive,
  }) {
    final List<InlineSpan> spans = [];
    final regExp = RegExp(
      r'\*\*(.*?)\*\*|'
      r'\b(Apprentice|Defender of Humanity|Kingslayer|Chanakya)\b|'
      r'\b(King|Queen|Rook|Bishop|Knight|Pawn)s?\b|'
      r'\b(Consider|Observe|Strategy|Warning|Tactics|Recommended|Crucial|Focus|Analyze|Blunder|Mistake|Inaccuracy|Brilliant|Strong|Neutral|Attack|Defend|Defense|Threat|Danger|Outpost|Pin|Fork|Check|Checkmate|Simplify|Passed Pawn|Opposition|Scotoma|Scotoma Report|Vulnerabilities|Arena)\b|'
      r'\b([a-h][1-8]-?[a-h][1-8]|[a-h][1-8])\b|'
      r'\b([NBRQK]?[a-h]?[1-8]?x?[a-h][1-8](?:=[NBRQK])?[+#]?|O-O(?:-O)?)\b|'
      r'(\[App Icon\])',
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
          spans.addAll(_buildSplitNotationSpans(moveNotation, baseStyle, state, fullText, isBubbleActive: isBubbleActive, isRed: true));
        } else if (moveRegex.hasMatch(content)) {
          spans.addAll(_buildSplitNotationSpans(content, baseStyle, state, fullText, isBubbleActive: isBubbleActive));
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
        if (lWord.contains('warning') || lWord.contains('blunder') || lWord.contains('mistake') || lWord.contains('vulnerabilit')) {
          color = Colors.redAccent;
        } else if (lWord.contains('brilliant') || lWord.contains('strong')) {
          color = Colors.green;
        } else if (lWord.contains('inaccuracy')) {
          color = Colors.amber.shade700;
        } else if (lWord.contains('strategy') || lWord.contains('defend') || lWord.contains('defense') || lWord.contains('simplify') || lWord.contains('scotoma')) {
          color = Colors.teal;
        } else if (lWord.contains('tactics') || lWord.contains('fork') || lWord.contains('pin') || lWord.contains('threat') || lWord.contains('danger') || lWord.contains('attack') || lWord.contains('arena')) {
          color = Colors.pink;
        } else if (lWord.contains('crucial') || lWord.contains('focus') || lWord.contains('check') || lWord.contains('checkmate')) {
          color = Colors.deepOrange;
        } else if (lWord.contains('analyze') || lWord.contains('observe') || lWord.contains('outpost') || lWord.contains('passed pawn') || lWord.contains('opposition')) {
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
        spans.addAll(_buildSplitNotationSpans(notation, baseStyle, state, fullText, isBubbleActive: isBubbleActive));
      } else if (match.group(7) != null) {
        // App Icon rendering
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Image.asset(
              'assets/splash/appicon.png',
              height: 16,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.school_rounded,
                size: 16,
                color: ScholarlyTheme.accentBlue,
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

  List<InlineSpan> _buildSplitNotationSpans(
    String notation,
    TextStyle baseStyle,
    ChessState state,
    String fullText, {
    required bool isBubbleActive,
    bool isRed = false,
  }) {
    final List<InlineSpan> spans = [];
    final themeColor = isRed
        ? Colors.redAccent
        : (isBubbleActive ? ScholarlyTheme.accentBlue : Colors.grey.shade600);

    if (notation.contains('-')) {
      final parts = notation.split('-');
      // First square chip
      spans.add(_buildSingleNotationChip(parts[0], parts[0], state, fullText, isBubbleActive: isBubbleActive, isRed: isRed));
      // Hyphen
      spans.add(TextSpan(
        text: '-',
        style: baseStyle.copyWith(
          color: themeColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      // Second square chip (targets the actual destination square)
      spans.add(_buildSingleNotationChip(parts[1], parts[1], state, fullText, isBubbleActive: isBubbleActive, isRed: isRed));
    } else {
      // Single notation chip
      String? targetSquare;
      final squareMatches = RegExp(r'[a-h][1-8]').allMatches(notation);
      if (squareMatches.isNotEmpty) {
        targetSquare = squareMatches.last.group(0);
      }
      spans.add(_buildSingleNotationChip(notation, targetSquare, state, fullText, isBubbleActive: isBubbleActive, isRed: isRed));
    }
    return spans;
  }

  WidgetSpan _buildSingleNotationChip(
    String label,
    String? targetSquare,
    ChessState state,
    String fullText, {
    required bool isBubbleActive,
    bool isRed = false,
  }) {
    final themeColor = isRed
        ? Colors.redAccent
        : (isBubbleActive ? ScholarlyTheme.accentBlue : Colors.grey.shade600);

    final Color chipBgColor = isBubbleActive
        ? themeColor.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.05);
    final Color chipBorderColor = isBubbleActive
        ? themeColor.withValues(alpha: 0.3)
        : Colors.grey.withValues(alpha: 0.2);
    final Color chipTextColor = isBubbleActive
        ? themeColor
        : ScholarlyTheme.textMuted.withValues(alpha: 0.6);

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: MouseRegion(
        cursor: (targetSquare == null || !isBubbleActive) ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: (targetSquare == null || !isBubbleActive)
              ? null
              : () {
                  ref.read(chessProvider.notifier).glowSquare(targetSquare);
                  ref.read(chessProvider.notifier).showSuggestionForSquare(targetSquare, fullText);
                },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: chipBgColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: chipBorderColor,
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.firaCode(
                color: chipTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _cleanTacticsText(String text) {
    final regExp = RegExp(r'\[[A-Z_]+:\s*[^\]]*\]\r?\n?');
    var cleaned = text.replaceAll(regExp, '');
    final splitStr = "Consider these alternative";
    if (cleaned.contains(splitStr)) {
      final index = cleaned.indexOf(splitStr);
      cleaned = cleaned.substring(0, index).trim();
    }
    return cleaned;
  }

  List<ExtractedTactic> _extractTactics(String text) {
    final List<ExtractedTactic> list = [];
    final regExp = RegExp(r'\[([A-Z_]+):\s*([^\]]*)\]');
    for (final match in regExp.allMatches(text)) {
      final label = match.group(1)!;
      final movesStr = match.group(2)!.trim();
      final moves = movesStr.isEmpty ? <String>[] : movesStr.split(' ');
      
      String displayName = label;
      if (label == 'YOUR_TACTIC') {
        displayName = 'Your Tactic';
      } else if (label.startsWith('TACTIC_')) {
        final parts = label.split('_');
        if (parts.length > 1) {
          final suffix = parts[1].toLowerCase();
          final capitalized = suffix.isEmpty ? '' : '${suffix[0].toUpperCase()}${suffix.substring(1)}';
          displayName = 'Tactic $capitalized';
        }
      }
      
      list.add(ExtractedTactic(label: label, displayName: displayName, moves: moves));
    }
    return list;
  }

  int _getTacticIndex(String label) {
    switch (label) {
      case 'YOUR_TACTIC': return 0;
      case 'TACTIC_ALPHA': return 1;
      case 'TACTIC_BETA': return 2;
      case 'TACTIC_GAMMA': return 3;
      case 'TACTIC_DELTA': return 4;
      case 'TACTIC_EPSILON': return 5;
      default: return 99;
    }
  }


  Widget _buildTacticCards(CommentaryEntry entry, ChessState state) {
    final tactics = _extractTactics(entry.text);
    if (tactics.isEmpty) return const SizedBox.shrink();

    final bool isTacticValid = entry.associatedFen == state.currentBoardFen;

    // Find user's tactic
    final userTacticIndex = tactics.indexWhere((t) => t.label == 'YOUR_TACTIC');
    ExtractedTactic? userTactic;
    if (userTacticIndex != -1) {
      userTactic = tactics[userTacticIndex];
    }

    // Find alternative tactics
    final alternatives = tactics.where((t) => t.label != 'YOUR_TACTIC').toList();

    final Color userTacticColor = ScholarlyTheme.accentBlue; // Blue color

    // Colors for alternatives
    final List<Color> altColors = [
      const Color(0xFFF59E0B), // Orange/Amber
      const Color(0xFF10B981), // Emerald/Green
      const Color(0xFF8B5CF6), // Purple/Violet
      const Color(0xFFEF4444), // Rose/Red
      const Color(0xFFEC4899), // Pink
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. User's Tactic
          if (userTactic != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: _buildTacticPill(
                tactic: userTactic,
                displayName: "${state.userName}'s tactic",
                color: userTacticColor,
                state: state,
                isFullWidth: false,
                isValid: isTacticValid,
              ),
            ),
            const SizedBox(height: 8),
          ],
          
          // 2. Alternatives horizontally stacked
          if (alternatives.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: alternatives.asMap().entries.map((item) {
                final idx = item.key;
                final tactic = item.value;
                final color = altColors[idx % altColors.length];
                
                // Extract short name: "Tactic Alpha" -> "ALPHA"
                final shortName = tactic.displayName.replaceFirst('Tactic ', '').toUpperCase();
                
                return _buildTacticPill(
                  tactic: tactic,
                  displayName: shortName,
                  color: color,
                  state: state,
                  isFullWidth: false,
                  isValid: isTacticValid,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTacticPill({
    required ExtractedTactic tactic,
    required String displayName,
    required Color color,
    required ChessState state,
    required bool isFullWidth,
    required bool isValid,
  }) {
    final index = _getTacticIndex(tactic.label);
    final isCurrentPlaying = isValid && state.isBoardInChampionsTheme && state.activeTacticIndex == index;

    final displayColor = isValid ? color : Colors.grey.shade500;
    final bgColor = !isValid
        ? Colors.grey.shade900.withValues(alpha: 0.05)
        : (isCurrentPlaying ? color.withValues(alpha: 0.18) : color.withValues(alpha: 0.08));
    final borderColor = !isValid
        ? Colors.grey.shade400.withValues(alpha: 0.2)
        : (isCurrentPlaying ? color : color.withValues(alpha: 0.4));
    final textStyle = GoogleFonts.inter(
      color: isValid ? ScholarlyTheme.textPrimary : ScholarlyTheme.textMuted,
      fontWeight: FontWeight.bold,
      fontSize: 10,
      letterSpacing: 1.0,
    );

    return MouseRegion(
      cursor: isValid ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: !isValid
            ? null
            : () {
                if (isCurrentPlaying) {
                  ref.read(chessProvider.notifier).stopTacticPlayback();
                } else {
                  ref.read(chessProvider.notifier).playTactic(index, tactic.moves);
                }
              },
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isCurrentPlaying ? 1.5 : 1.0,
          ),
          boxShadow: isCurrentPlaying
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 4,
                    spreadRadius: 0.5,
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          children: [
            Text(
              displayName,
              style: textStyle,
            ),
            if (isFullWidth) const Spacer() else const SizedBox(width: 8),
            Icon(
              isCurrentPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: displayColor,
              size: 14,
            ),
          ],
        ),
      ),
    ),
  );
}
}

class ExtractedTactic {
  final String label;
  final String displayName;
  final List<String> moves;

  const ExtractedTactic({
    required this.label,
    required this.displayName,
    required this.moves,
  });
}

class DottedGridLoader extends StatefulWidget {
  const DottedGridLoader({super.key});

  @override
  State<DottedGridLoader> createState() => _DottedGridLoaderState();
}

class _DottedGridLoaderState extends State<DottedGridLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final int row = index ~/ 3;
          final int col = index % 3;
          final double delay = (row + col) / 4.0;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double t = (_controller.value - delay) % 1.0;
              final double opacity =
                  0.15 + 0.85 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
              final double scale =
                  0.5 + 0.5 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));

              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    color: ScholarlyTheme.accentBlue.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
