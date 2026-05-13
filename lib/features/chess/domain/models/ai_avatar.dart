import 'package:flutter/material.dart';

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
  });

  static const List<AiAvatar> avatars = [
    AiAvatar(
      id: 'avatar_0',
      name: 'Sparky',
      title: 'The Absolute Beginner',
      fideRatingRange: '400 - 500',
      playingStyle: 'Just discovering the game. Focuses purely on basic piece movement, frequently leaving pieces unprotected and missing immediate threats.',
      skillLevel: 0,
      depth: 1,
      icon: Icons.child_care_rounded,
      color: Color(0xFFA1887F), // Soft Earth
    ),
    AiAvatar(
      id: 'avatar_1',
      name: 'Pawnzy',
      title: 'The Novice',
      fideRatingRange: '800 - 950',
      playingStyle: 'Highly erratic. Moves pawns blindly and frequently overlooks standard one-move tactical captures.',
      skillLevel: 0,
      depth: 1,
      icon: Icons.cruelty_free_rounded,
      color: Color(0xFF81C784), // Soft green
    ),
    AiAvatar(
      id: 'avatar_2',
      name: 'Rook-ie',
      title: 'The Casual Woodpusher',
      fideRatingRange: '950 - 1050',
      playingStyle: 'Loves capturing undefended pieces instantly without calculating potential recapture risks or structural damage.',
      skillLevel: 1,
      depth: 2,
      icon: Icons.castle_rounded,
      color: Color(0xFF64B5F6), // Soft blue
    ),
    AiAvatar(
      id: 'avatar_3',
      name: 'Stonewall',
      title: 'The Steadfast Defender',
      fideRatingRange: '1100 - 1250',
      playingStyle: 'Ultra-conservative closed formations. Strongly avoids taking early tactical risks, seeking solid, locked pawn chains.',
      skillLevel: 3,
      depth: 3,
      icon: Icons.shield_rounded,
      color: Color(0xFF90A4AE), // Muted blue-grey
    ),
    AiAvatar(
      id: 'avatar_4',
      name: 'Blitzer',
      title: 'The Aggressive Attacker',
      fideRatingRange: '1300 - 1450',
      playingStyle: 'Develops minor pieces rapidly targeting early king assaults. High tactical aggression but leaves exploitable gaps.',
      skillLevel: 5,
      depth: 5,
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFB74D), // Soft orange
    ),
    AiAvatar(
      id: 'avatar_5',
      name: 'Gambit',
      title: 'The Dynamic Trickster',
      fideRatingRange: '1500 - 1650',
      playingStyle: 'Thrives in chaotic, imbalanced positions. Frequently trades material early or sacrifices pawns to open active attack vectors.',
      skillLevel: 8,
      depth: 8,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFBA68C8), // Muted purple
    ),
    AiAvatar(
      id: 'avatar_6',
      name: 'Vanguard',
      title: 'The Seasoned Tactician',
      fideRatingRange: '1700 - 1850',
      playingStyle: 'Sharp tactical vision. Immediately punishes uncoordinated pieces and accurately calculates standard combination lines.',
      skillLevel: 11,
      depth: 10,
      icon: Icons.track_changes_rounded,
      color: Color(0xFF4DB6AC), // Teal
    ),
    AiAvatar(
      id: 'avatar_7',
      name: 'Sentinel',
      title: 'The Candidate Master',
      fideRatingRange: '1900 - 2100',
      playingStyle: 'Superb prophylactic control. Methodically restricts opponent counterplay while establishing dominant positional outposts.',
      skillLevel: 14,
      depth: 12,
      icon: Icons.gpp_good_rounded,
      color: Color(0xFF7986CB), // Indigo
    ),
    AiAvatar(
      id: 'avatar_8',
      name: 'Morphy',
      title: 'The Master Strategist',
      fideRatingRange: '2200 - 2400',
      playingStyle: 'Classical elegance. Achieves rapid piece coordination, controls open lines, and unleashes precise, devastating sacrifices.',
      skillLevel: 17,
      depth: 15,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE57373), // Red soft
    ),
    AiAvatar(
      id: 'avatar_9',
      name: 'Titan',
      title: 'The Grandmaster',
      fideRatingRange: '2500 - 2700',
      playingStyle: 'Relentless positional pressure. Leverages deep calculation to squeeze micro-advantages and transition into flawless endgames.',
      skillLevel: 19,
      depth: 18,
      icon: Icons.psychology_rounded,
      color: Color(0xFFFFD54F), // Amber
    ),
    AiAvatar(
      id: 'avatar_10',
      name: 'Kingslayer',
      title: 'The Ultimate Apex',
      fideRatingRange: '2850 - 3200+',
      playingStyle: 'Full throttle Stockfish 18 engine representation. Maximizes objective evaluations with absolutely stable, inhuman accuracy.',
      skillLevel: 20,
      depth: 22,
      icon: Icons.diamond_rounded,
      color: Color(0xFFE0E0E0), // Platinum / White
    ),
  ];

  static AiAvatar getAvatar(String id) {
    return avatars.firstWhere((a) => a.id == id, orElse: () => avatars[6]); // Default to Vanguard
  }
}
