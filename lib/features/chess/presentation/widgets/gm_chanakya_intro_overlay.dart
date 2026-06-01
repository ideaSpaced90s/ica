import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../scholarly_theme.dart';
import '../../services/chess_sound_service.dart';
import '../../application/chess_provider.dart';

class GMChanakyaIntroOverlay extends ConsumerStatefulWidget {
  final String text;
  final String pageTitle;
  final VoidCallback onDismiss;

  const GMChanakyaIntroOverlay({
    super.key,
    required this.text,
    required this.pageTitle,
    required this.onDismiss,
  });

  @override
  ConsumerState<GMChanakyaIntroOverlay> createState() => _GMChanakyaIntroOverlayState();
}

class _GMChanakyaIntroOverlayState extends ConsumerState<GMChanakyaIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  String _displayedText = '';
  int _charIndex = 0;
  bool _isTyping = true;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Play Chanakya intro sound on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chessSoundServiceProvider).playSfx(SoundEffect.chanakyaNotify);
    });

    _startTyping();
  }

  void _startTyping() {
    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_charIndex < widget.text.length) {
        setState(() {
          _charIndex++;
          _displayedText = widget.text.substring(0, _charIndex);
        });

        // Subtly play writing sound every 3rd character
        if (_charIndex % 3 == 0) {
          ref.read(chessSoundServiceProvider).playWriting();
        }
      } else {
        setState(() {
          _isTyping = false;
        });
        timer.cancel();
      }
    });
  }

  void _skipTypewriter() {
    if (!_isTyping) return;
    _typewriterTimer?.cancel();
    ref.read(chessSoundServiceProvider).playSfx(SoundEffect.click);
    setState(() {
      _charIndex = widget.text.length;
      _displayedText = widget.text;
      _isTyping = false;
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Blurred Darkened Backdrop
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: Colors.black.withValues(alpha: 0.65),
              ),
            ),
          ),

          // Central Card Info
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: GestureDetector(
                onTap: _isTyping ? _skipTypewriter : null,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  decoration: ScholarlyTheme.glassPanelDecoration(radius: 24).copyWith(
                    color: Colors.white.withValues(alpha: 0.96),
                    border: Border.all(
                      color: ScholarlyTheme.accentBlue.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              image: DecorationImage(
                                image: AssetImage('assets/persona/gm_chanakya.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'GM CHANAKYA',
                                  style: GoogleFonts.outfit(
                                    color: ScholarlyTheme.accentBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Supreme Chess Mentor',
                                  style: GoogleFonts.inter(
                                    color: ScholarlyTheme.textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ScholarlyTheme.accentBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ScholarlyTheme.accentBlue.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              widget.pageTitle,
                              style: GoogleFonts.jetBrainsMono(
                                color: ScholarlyTheme.accentBlue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFFE2E8F0), height: 1),
                      const SizedBox(height: 18),

                      // Speech Bubble / Message Content
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  color: ScholarlyTheme.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w500,
                                  height: 1.55,
                                ),
                                children: [
                                  ..._buildHighlightedText(_displayedText),
                                  if (_isTyping)
                                    const TextSpan(
                                      text: ' |',
                                      style: TextStyle(
                                        color: ScholarlyTheme.accentBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (_isTyping) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Tap card to skip typing...',
                                style: GoogleFonts.inter(
                                  color: ScholarlyTheme.textSubtle,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Action Button (Only fully interactive when typing ends)
                      AnimatedOpacity(
                        opacity: _isTyping ? 0.3 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _isTyping ? null : widget.onDismiss,
                              child: AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final scale = _isTyping ? 1.0 : (1.0 + 0.08 * _pulseController.value);
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isTyping ? Colors.grey : ScholarlyTheme.accentBlue,
                                        boxShadow: _isTyping
                                            ? []
                                            : [
                                                BoxShadow(
                                                  color: ScholarlyTheme.accentBlue.withValues(
                                                    alpha: 0.35 + 0.35 * _pulseController.value,
                                                  ),
                                                  blurRadius: 12 + 8 * _pulseController.value,
                                                  spreadRadius: 2 * _pulseController.value,
                                                ),
                                              ],
                                      ),
                                      child: const Icon(
                                        Icons.thumb_up_alt_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isTyping ? 'Read the instructions first' : 'TAP TO BEGIN',
                              style: GoogleFonts.inter(
                                color: _isTyping ? ScholarlyTheme.textMuted : ScholarlyTheme.accentBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildHighlightedText(String text) {
    final List<InlineSpan> spans = [];
    final words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final cleanWord = word.replaceAll(RegExp(r'[.,!?:;🕉️\(\)]'), '').toLowerCase();

      Color? highlightColor;
      FontWeight fontWeight = FontWeight.normal;

      if (['apprentice', 'strategist', 'strategists', 'warrior', 'tactician'].contains(cleanWord)) {
        highlightColor = const Color(0xFFD97706); // Warm Amber
        fontWeight = FontWeight.bold;
      } else if (['chamber', 'crucible', 'arena', 'battleground', 'puzzles', 'sanctuary', 'prescription'].contains(cleanWord)) {
        highlightColor = const Color(0xFF2563EB); // Royal Blue
        fontWeight = FontWeight.bold;
      } else if (['intuition', 'calculation', 'calculate', 'theory', 'theories', 'sight'].contains(cleanWord)) {
        highlightColor = const Color(0xFF7C3AED); // Purple
        fontWeight = FontWeight.bold;
      } else if (['defeat', 'crucible', 'fire', 'stakes', 'pressure', 'blunders', 'hesitation', 'blindness'].contains(cleanWord)) {
        highlightColor = const Color(0xFFDC2626); // Crimson Red
        fontWeight = FontWeight.bold;
      } else if (['victory', 'mastery', 'understanding', 'instincts', 'resilience', 'conditioning', 'discipline'].contains(cleanWord)) {
        highlightColor = const Color(0xFF059669); // Emerald Green
        fontWeight = FontWeight.bold;
      }

      if (highlightColor != null) {
        spans.add(TextSpan(
          text: word,
          style: TextStyle(
            color: highlightColor,
            fontWeight: fontWeight,
          ),
        ));
      } else {
        spans.add(TextSpan(text: word));
      }

      if (i < words.length - 1) {
        spans.add(const TextSpan(text: ' '));
      }
    }
    return spans;
  }
}
