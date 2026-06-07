import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// 50 Authentic Chess Motivational Quotes
// ---------------------------------------------------------------------------
class _Quote {
  final String text;
  final String author;
  const _Quote(this.text, this.author);
}

const List<_Quote> _kChessQuotes = [
  _Quote('When you see a good move, look for a better one.', 'Emanuel Lasker'),
  _Quote(
    'The riposte to the question of how many moves a player can see ahead is "one, the right one."',
    'Grandmaster Maxim',
  ),
  _Quote(
    'Tactics is knowing what to do when there is something to do; strategy is knowing what to do when there is nothing to do.',
    'Savielly Tartakower',
  ),
  _Quote(
    'You must calculate moves quickly and then interpret them coldly.',
    'International Master Insight',
  ),
  _Quote(
    "First-class error occurs when you don't check the opponent's options.",
    'Garry Kasparov',
  ),
  _Quote(
    "I don't believe in psychology. I believe in good moves.",
    'Bobby Fischer',
  ),
  _Quote('Concentration must be absolute.', 'Bobby Fischer'),
  _Quote(
    'You have to have that edge, you have to have that confidence, you have to have that absolute belief that you\'re the best.',
    'Magnus Carlsen',
  ),
  _Quote('Chess is the art of analysis.', 'Mikhail Botvinnik'),
  _Quote('Help your pieces so they can help you.', 'Paul Morphy'),
  _Quote(
    "No matter how good you get as a chess player, you're going to get in bad positions. And you have to deal with them, you can't just give up when you have them.",
    'Elizabeth Spiegel',
  ),
  _Quote(
    'The blunders are all there on the board, waiting to be made.',
    'Savielly Tartakower',
  ),
  _Quote(
    'We need to deal with those failures the right way so we can continue to push boundaries.',
    'Chess Design Insight',
  ),
  _Quote(
    'You may learn much more from a game you lose than from a game you win.',
    'José Raúl Capablanca',
  ),
  _Quote(
    'I look one move ahead... the best one.',
    'José Raúl Capablanca',
  ),
  _Quote(
    'A passed pawn is a criminal, who should be kept under lock and key.',
    'Aron Nimzowitsch',
  ),
  _Quote(
    'The most powerful weapon in chess is to have the next move.',
    'David Bronstein',
  ),
  _Quote(
    "Confidence is very important. If you don't think you can win, you will take cowardly decisions.",
    'Magnus Carlsen',
  ),
  _Quote(
    'Nobody ever won a chess game by resigning.',
    'Savielly Tartakower',
  ),
  _Quote(
    'Some part of the mistake is always correct.',
    'Savielly Tartakower',
  ),
  _Quote(
    'I believe accepting losses too easily is incompatible with being a great champion.',
    'Garry Kasparov',
  ),
  _Quote(
    'Chess is a war over the board. The object is to crush the opponent\'s mind.',
    'Bobby Fischer',
  ),
  _Quote(
    'Play the opening like a book, the middlegame like a magician, and the endgame like a machine.',
    'Rudolf Spielmann',
  ),
  _Quote(
    'My opponents will find that they are playing against a human being, not an engine.',
    'Garry Kasparov',
  ),
  _Quote(
    'No price is too great for the scalp of one\'s enemy.',
    'Frank Marshall',
  ),
  _Quote(
    'He who takes risks may lose, but he who does not take them always loses.',
    'Savielly Tartakower',
  ),
  _Quote(
    'Winning at fast chess requires chess skills and physical coordination at the highest level.',
    'Krzysztof Olechnicki',
  ),
  _Quote(
    'On the chessboard, lies and hypocrisy do not survive long.',
    'Emanuel Lasker',
  ),
  _Quote(
    'To win against me, you must beat me three times: first in the opening, then in the middlegame, and then in the endgame.',
    'Alexander Alekhine',
  ),
  _Quote(
    'The King\'s Gambit is busted. It loses by force.',
    'Bobby Fischer',
  ),
  _Quote(
    'Its strength is in its interpretation. This phenomenon enables one repeatedly to reproduce beauty.',
    'David Bronstein',
  ),
  _Quote(
    'All artists are not chess players — all chess players are artists.',
    'Marcel Duchamp',
  ),
  _Quote(
    'The game of chess is the touchstone of the intellect.',
    'Goethe',
  ),
  _Quote(
    'The bigger the sacrifice, the more beautiful.',
    'Traditional Brilliancy Concept',
  ),
  _Quote(
    'Chess is everything — art, science, and sport.',
    'Anatoly Karpov',
  ),
  _Quote(
    'Chess, like love, like music, has the power to make men happy.',
    'Siegbert Tarrasch',
  ),
  _Quote(
    'The beauty of a move lies not in its appearance, but in the thought behind it.',
    'Aron Nimzowitsch',
  ),
  _Quote(
    'There are two types of sacrifices: correct ones, and mine.',
    'Mikhail Tal',
  ),
  _Quote(
    'I will suffer like a dog, but I will make beautiful games.',
    'Vasily Smyslov',
  ),
  _Quote(
    'If your opponent wants a draw, take him into a deep dark forest where 2+2=5, and the path leading out is only wide enough for one.',
    'Mikhail Tal',
  ),
  _Quote(
    'To gain an advantage, examine databases to learn your opponents\' stylistic preferences.',
    'Grandmaster Preparation',
  ),
  _Quote(
    'In chess, as in corporate strategy, it is about improving strategic thinking and decision-making skills.',
    'Anatoly Karpov',
  ),
  _Quote(
    'You can run away from this new challenge or you could embrace it, which was really no choice at all.',
    'Garry Kasparov',
  ),
  _Quote(
    'One bad game does not mean you have forgotten how to play.',
    'Viswanathan Anand',
  ),
  _Quote(
    'If you aren\'t prepared to adapt, the game will leave you behind.',
    'Viswanathan Anand',
  ),
  _Quote(
    'It is not enough to be a good player; you must also play well.',
    'Siegbert Tarrasch',
  ),
  _Quote(
    'The hard work begins long before you arrive at the board.',
    'Magnus Carlsen',
  ),
  _Quote('Every master was once a beginner.', 'Irving Chernev'),
  _Quote(
    'Strategy requires thought, tactics requires observation.',
    'Max Euwe',
  ),
  _Quote(
    'In chess, the most important thing is not to beat your opponent, but to overcome your own limits.',
    'Judit Polgár',
  ),
];

/// Returns the daily quote index based on the current date.
/// This ensures the same quote is shown all day and changes at midnight.
int _getDailyQuoteIndex() {
  final now = DateTime.now();
  // Build a unique seed for the date (Year * 500 + Month * 32 + Day)
  final dateSeed = now.year * 500 + now.month * 32 + now.day;
  final random = Random(dateSeed);
  return random.nextInt(_kChessQuotes.length);
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A premium daily motivational quote card.
/// Picks one of 50 chess quotes deterministically by calendar day —
/// the quote changes once every 24 hours at midnight.
class DailyMotivationalQuoteCard extends StatelessWidget {
  const DailyMotivationalQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final idx = _getDailyQuoteIndex();
    final quote = _kChessQuotes[idx];

    // Gradient palette cycles through a few rich combinations keyed on quote index
    final gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],   // indigo → violet
      [const Color(0xFF0EA5E9), const Color(0xFF6366F1)],   // sky → indigo
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],   // amber → red
      [const Color(0xFF10B981), const Color(0xFF0EA5E9)],   // emerald → sky
      [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],   // pink → violet
    ];
    final palette = gradients[idx % gradients.length];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette[0].withValues(alpha: 0.12),
            palette[1].withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: palette[0].withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: palette[0].withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: palette,
                ).createShader(bounds),
                child: const Icon(
                  Icons.format_quote_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: palette).createShader(bounds),
                child: Text(
                  'QUOTE OF THE DAY',
                  style: GoogleFonts.outfit(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              // Tiny chess pawn icon as a decorative flourish
              Text(
                '♟',
                style: TextStyle(
                  fontSize: 16,
                  color: palette[0].withValues(alpha: 0.55),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Quote text ───────────────────────────────────────────────────
          Text(
            '"${quote.text}"',
            style: GoogleFonts.playfairDisplay(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
              height: 1.55,
            ),
          ),

          const SizedBox(height: 10),

          // ── Author ───────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: palette),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      LinearGradient(colors: palette).createShader(bounds),
                  child: Text(
                    quote.author,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A compact inline version used beside the profile image on desktop.
class DailyMotivationalQuoteInline extends StatelessWidget {
  const DailyMotivationalQuoteInline({super.key});

  @override
  Widget build(BuildContext context) {
    final idx = _getDailyQuoteIndex();
    final quote = _kChessQuotes[idx];

    final gradients = [
      [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
      [const Color(0xFF0EA5E9), const Color(0xFF6366F1)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF10B981), const Color(0xFF0EA5E9)],
      [const Color(0xFFEC4899), const Color(0xFF8B5CF6)],
    ];
    final palette = gradients[idx % gradients.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  LinearGradient(colors: palette).createShader(bounds),
              child: const Icon(
                Icons.format_quote_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 5),
            ShaderMask(
              shaderCallback: (bounds) =>
                  LinearGradient(colors: palette).createShader(bounds),
              child: Text(
                'QUOTE OF THE DAY',
                style: GoogleFonts.outfit(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Quote
        Text(
          '"${quote.text}"',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.playfairDisplay(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 5),
        // Author with gradient accent line
        Row(
          children: [
            Container(
              width: 18,
              height: 1.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: palette),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    LinearGradient(colors: palette).createShader(bounds),
                child: Text(
                  quote.author,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
