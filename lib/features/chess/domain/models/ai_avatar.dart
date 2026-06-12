import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget buildAvatarImage(String imagePath, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (imagePath.endsWith('.svg')) {
    return SvgPicture.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
    );
  } else {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

class AiAvatar {
  final String id;
  final String name;
  final String title;
  final String fideRatingRange;
  final String playingStyle;
  final int skillLevel;
  final int depth;
  final IconData icon;
  final Color color;
  final String imagePath;

  const AiAvatar({
    required this.id,
    required this.name,
    required this.title,
    required this.fideRatingRange,
    required this.playingStyle,
    required this.skillLevel,
    required this.depth,
    required this.icon,
    required this.color,
    required this.imagePath,
  });

  int get rating {
    final cleanRange = fideRatingRange.replaceAll('+', '').split('-');
    if (cleanRange.isNotEmpty) {
      final low = int.tryParse(cleanRange[0].trim()) ?? 1500;
      final high = cleanRange.length > 1 ? int.tryParse(cleanRange[1].trim()) ?? low : low;
      return ((low + high) / 2).round();
    }
    return 1500;
  }

  static const List<AiAvatar> avatars = [
    AiAvatar(
      id: 'avatar_0',
      name: 'Sparky',
      title: 'The Absolute Beginner',
      fideRatingRange: '400 - 500',
      playingStyle: 'Absolute beginner who randomly pushes pieces and blunders frequently — has no idea what\'s happening on the board.',
      skillLevel: 0,
      depth: 1,
      icon: Icons.child_care_rounded,
      color: Color(0xFFA1887F), // Soft Earth
      imagePath: 'assets/persona_vector/sparky.svg',
    ),
    AiAvatar(
      id: 'avatar_1',
      name: 'Pawnzy',
      title: 'The Novice',
      fideRatingRange: '600 - 750',
      playingStyle: 'Erratic novice obsessed with pawn promotions. Plays only pawns hoping one will queen.',
      skillLevel: 1,
      depth: 1,
      icon: Icons.cruelty_free_rounded,
      color: Color(0xFF81C784), // Soft green
      imagePath: 'assets/persona_vector/pawnzy.svg',
    ),
    AiAvatar(
      id: 'avatar_2',
      name: 'Coward',
      title: 'Extreme Defender',
      fideRatingRange: '800 - 900',
      playingStyle: 'Extreme defender who retreats pieces at the first sign of danger and plays extremely passive.',
      skillLevel: 2,
      depth: 2,
      icon: Icons.shield_rounded,
      color: Color(0xFF90CAF9), // Pale blue
      imagePath: 'assets/persona_vector/coward.svg',
    ),
    AiAvatar(
      id: 'avatar_3',
      name: 'Rookie',
      title: 'Casual Woodpusher',
      fideRatingRange: '900 - 1000',
      playingStyle: 'Captures undefended pieces immediately with zero recapture risk assessment.',
      skillLevel: 3,
      depth: 3,
      icon: Icons.castle_rounded,
      color: Color(0xFF64B5F6), // Light blue
      imagePath: 'assets/persona_vector/rook-ie.svg',
    ),
    AiAvatar(
      id: 'avatar_4',
      name: 'Scholar',
      title: 'Tactical Trickster',
      fideRatingRange: '1000 - 1100',
      playingStyle: 'Always goes for cheap tactical tricks like the Scholar\'s Mate and quick attacks.',
      skillLevel: 4,
      depth: 3,
      icon: Icons.school_rounded,
      color: Color(0xFFFFF59D), // Yellow
      imagePath: 'assets/persona_vector/scholar.svg',
    ),
    AiAvatar(
      id: 'avatar_5',
      name: 'Molly',
      title: 'Introvert Defender',
      fideRatingRange: '1100 - 1200',
      playingStyle: 'Ultra-conservative and introverted. Locks opponents behind iron pawn walls and plays closed files only.',
      skillLevel: 5,
      depth: 4,
      icon: Icons.security_rounded,
      color: Color(0xFF90A4AE), // Muted blue-grey
      imagePath: 'assets/persona_vector/molly.svg',
    ),
    AiAvatar(
      id: 'avatar_6',
      name: 'Berserker',
      title: 'Reckless Attacker',
      fideRatingRange: '1200 - 1350',
      playingStyle: 'Highly aggressive and reckless attacker who sacrifices units early to attack the opponent\'s king.',
      skillLevel: 6,
      depth: 4,
      icon: Icons.sports_martial_arts,
      color: Color(0xFFFFCC80), // Orange
      imagePath: 'assets/persona_vector/berserker.svg',
    ),
    AiAvatar(
      id: 'avatar_7',
      name: 'Blaire',
      title: 'Tactical Blitzer',
      fideRatingRange: '1350 - 1500',
      playingStyle: 'Highly tactical rapid attacker targeting the king, but leaves loose, exploitable positions.',
      skillLevel: 7,
      depth: 5,
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFB74D), // Soft orange
      imagePath: 'assets/persona_vector/blaire.svg',
    ),
    AiAvatar(
      id: 'avatar_8',
      name: 'Python',
      title: 'Positional Squeezer',
      fideRatingRange: '1500 - 1600',
      playingStyle: 'Squeezes the opponent slowly. Loves closed positions, subtle maneuvers, and positional pressure.',
      skillLevel: 8,
      depth: 6,
      icon: Icons.all_out_rounded,
      color: Color(0xFFC5E1A5), // Olive green
      imagePath: 'assets/persona_vector/python.svg',
    ),
    AiAvatar(
      id: 'avatar_9',
      name: 'Gambit',
      title: 'Dynamic Trickster',
      fideRatingRange: '1600 - 1700',
      playingStyle: 'Chaos lover. Makes wild material sacrifices to create unpredictable imbalances.',
      skillLevel: 9,
      depth: 7,
      icon: Icons.casino_rounded,
      color: Color(0xFFBA68C8), // Muted purple
      imagePath: 'assets/persona_vector/gambit.svg',
    ),
    AiAvatar(
      id: 'avatar_10',
      name: 'Trapper',
      title: 'Opening Trap Specialist',
      fideRatingRange: '1700 - 1800',
      playingStyle: 'Lays subtle traps. Prefers tricky opening lines, gambits, and poisoned pawns.',
      skillLevel: 10,
      depth: 8,
      icon: Icons.catching_pokemon,
      color: Color(0xFFCE93D8), // Purple
      imagePath: 'assets/persona_vector/trapper.svg',
    ),
    AiAvatar(
      id: 'avatar_11',
      name: 'Assassin',
      title: 'Relentless Hunter',
      fideRatingRange: '1800 - 1900',
      playingStyle: 'Relentlessly attacks the king, sacrificing pieces to open the center and force the king into open space.',
      skillLevel: 11,
      depth: 9,
      icon: Icons.gps_fixed_rounded,
      color: Color(0xFFEF9A9A), // Deep Red
      imagePath: 'assets/persona_vector/assassin.svg',
    ),
    AiAvatar(
      id: 'avatar_12',
      name: 'Vala',
      title: 'Seasoned Tactician',
      fideRatingRange: '1900 - 2000',
      playingStyle: 'Sharp tactical vision. Punishes uncoordinated opponent pieces immediately.',
      skillLevel: 12,
      depth: 10,
      icon: Icons.track_changes_rounded,
      color: Color(0xFF4DB6AC), // Teal
      imagePath: 'assets/persona_vector/vala.svg',
    ),
    AiAvatar(
      id: 'avatar_13',
      name: 'Magician',
      title: 'Creative Attacker',
      fideRatingRange: '2000 - 2150',
      playingStyle: 'Plays imaginative, Tal-like attacking chess. Finds brilliant sacrifices with huge compensation.',
      skillLevel: 13,
      depth: 12,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFF48FB1), // Magenta
      imagePath: 'assets/persona_vector/magician.svg',
    ),
    AiAvatar(
      id: 'avatar_14',
      name: 'Sentinel',
      title: 'Candidate Master',
      fideRatingRange: '2150 - 2300',
      playingStyle: 'Positional trap specialist. Plays human-like moves to lull opponents, then springs subtle positional traps.',
      skillLevel: 14,
      depth: 14,
      icon: Icons.gpp_good_rounded,
      color: Color(0xFF7986CB), // Indigo
      imagePath: 'assets/persona_vector/sentinel.svg',
    ),
    AiAvatar(
      id: 'avatar_15',
      name: 'Murphy',
      title: 'Sea Storm Strategist',
      fideRatingRange: '2300 - 2450',
      playingStyle: 'Opens lines early to welcome opponent pieces, then unleashes rapid coordinated sea-storm attacks.',
      skillLevel: 16,
      depth: 15,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE57373), // Red soft
      imagePath: 'assets/persona_vector/im_murphy.svg',
    ),
    AiAvatar(
      id: 'avatar_16',
      name: 'Titan',
      title: 'Grandmaster',
      fideRatingRange: '2450 - 2600',
      playingStyle: 'Grandmaster-level precision with constant tactical and positional pressure.',
      skillLevel: 18,
      depth: 18,
      icon: Icons.psychology_rounded,
      color: Color(0xFFFFD54F), // Amber
      imagePath: 'assets/persona_vector/gm_titan.svg',
    ),
    AiAvatar(
      id: 'avatar_17',
      name: 'Alien',
      title: 'Algorithmic Entity',
      fideRatingRange: '2600 - 2750',
      playingStyle: 'AlphaZero-style bot. Plays bizarre, unintuitive moves that are incredibly strong positionally.',
      skillLevel: 18,
      depth: 19,
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFA5D6A7), // Neon Green
      imagePath: 'assets/persona_vector/alien.svg',
    ),
    AiAvatar(
      id: 'avatar_18',
      name: 'Champ',
      title: 'Universal Legend',
      fideRatingRange: '2750 - 2900',
      playingStyle: 'Complete universal player. Flawless endgame technique and flawless openings.',
      skillLevel: 18,
      depth: 20,
      icon: Icons.public_rounded,
      color: Color(0xFFFFE082), // Gold
      imagePath: 'assets/persona_vector/champ.svg',
    ),
    AiAvatar(
      id: 'avatar_19',
      name: 'King',
      title: 'The Ultimate Apex',
      fideRatingRange: '2850 - 3200+',
      playingStyle: 'A near-perfect computational killing machine. Banned from tournaments for not being organic. No story of defeat exists.',
      skillLevel: 20,
      depth: 22,
      icon: Icons.diamond_rounded,
      color: Color(0xFFE0E0E0), // Platinum / White
      imagePath: 'assets/persona_vector/king.svg',
    ),
  ];

  static AiAvatar getAvatar(String id) {
    return avatars.firstWhere((a) => a.id == id, orElse: () => avatars[12]); // Default to Vala
  }

  static AiAvatar getBestMatch(int rating) {
    AiAvatar best = avatars[0];
    int minDiff = (rating - best.rating).abs();

    for (final avatar in avatars) {
      final diff = (rating - avatar.rating).abs();
      if (diff < minDiff) {
        minDiff = diff;
        best = avatar;
      }
    }
    return best;
  }
}
