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
      imagePath: 'assets/persona/sparky.png',
    ),
    AiAvatar(
      id: 'avatar_1',
      name: 'Pawnzy',
      title: 'The Novice',
      fideRatingRange: '800 - 950',
      playingStyle: 'Erratic novice obsessed with pawn promotions. Nerdy in all the wrong ways — plays only pawns hoping one will queen.',
      skillLevel: 1,
      depth: 2,
      icon: Icons.cruelty_free_rounded,
      color: Color(0xFF81C784), // Soft green
      imagePath: 'assets/persona/pawnzy.png',
    ),
    AiAvatar(
      id: 'avatar_2',
      name: 'Rook-ie',
      title: 'The Casual Woodpusher',
      fideRatingRange: '950 - 1050',
      playingStyle: 'High-school level bully who captures undefended pieces immediately with zero recapture risk assessment.',
      skillLevel: 2,
      depth: 3,
      icon: Icons.castle_rounded,
      color: Color(0xFF64B5F6), // Soft blue
      imagePath: 'assets/persona/rook-ie.png',
    ),
    AiAvatar(
      id: 'avatar_3',
      name: 'Molly',
      title: 'The Introvert Defender',
      fideRatingRange: '1100 - 1250',
      playingStyle: 'Ultra-conservative and introverted bot. Locks opponents behind iron pawn walls, plays closed files only, and rarely speaks.',
      skillLevel: 4,
      depth: 4,
      icon: Icons.shield_rounded,
      color: Color(0xFF90A4AE), // Muted blue-grey
      imagePath: 'assets/persona/molly.png',
    ),
    AiAvatar(
      id: 'avatar_4',
      name: 'Blaire',
      title: 'The Tactical Blitzer',
      fideRatingRange: '1300 - 1450',
      playingStyle: 'Highly tactical rapid attacker targeting the king, but leaves loose, exploitable positions.',
      skillLevel: 6,
      depth: 5,
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFB74D), // Soft orange
      imagePath: 'assets/persona/blaire.png',
    ),
    AiAvatar(
      id: 'avatar_5',
      name: 'Gambit',
      title: 'The Dynamic Trickster',
      fideRatingRange: '1500 - 1650',
      playingStyle: 'Chaos lover known more for looks than chess. Makes wild material sacrifices to create unpredictable imbalances.',
      skillLevel: 8,
      depth: 7,
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFFBA68C8), // Muted purple
      imagePath: 'assets/persona/gambit.png',
    ),
    AiAvatar(
      id: 'avatar_6',
      name: 'Vala',
      title: 'The Seasoned Tactician',
      fideRatingRange: '1700 - 1850',
      playingStyle: 'Sharp tactical vision with forward-facing energy. Punishes uncoordinated opponent pieces immediately.',
      skillLevel: 11,
      depth: 10,
      icon: Icons.track_changes_rounded,
      color: Color(0xFF4DB6AC), // Teal
      imagePath: 'assets/persona/vala.png',
    ),
    AiAvatar(
      id: 'avatar_7',
      name: 'Sentinel',
      title: 'The Candidate Master',
      fideRatingRange: '1900 - 2100',
      playingStyle: 'Positional trap specialist. Plays human-like moves to lull opponents, then springs subtle positional traps.',
      skillLevel: 14,
      depth: 12,
      icon: Icons.gpp_good_rounded,
      color: Color(0xFF7986CB), // Indigo
      imagePath: 'assets/persona/sentinel.png',
    ),
    AiAvatar(
      id: 'avatar_8',
      name: 'Murphy',
      title: 'The Sea Storm Strategist',
      fideRatingRange: '2200 - 2400',
      playingStyle: 'Sea-storm strategist. Opens lines early to welcome opponent pieces, then unleashes rapid coordinated sea-storm attacks.',
      skillLevel: 16,
      depth: 15,
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFE57373), // Red soft
      imagePath: 'assets/persona/im_murphy.png',
    ),
    AiAvatar(
      id: 'avatar_9',
      name: 'Titan',
      title: 'The Grandmaster',
      fideRatingRange: '2500 - 2700',
      playingStyle: 'First bot to overthrow a human grandmaster. Grandmaster-level precision with constant tactical/positional pressure.',
      skillLevel: 18,
      depth: 18,
      icon: Icons.psychology_rounded,
      color: Color(0xFFFFD54F), // Amber
      imagePath: 'assets/persona/gm_titan.png',
    ),
    AiAvatar(
      id: 'avatar_10',
      name: 'Kingslayer',
      title: 'The Ultimate Apex',
      fideRatingRange: '2850 - 3200+',
      playingStyle: 'A near-perfect computational killing machine. Banned from tournaments for not being organic. No story of defeat exists.',
      skillLevel: 20,
      depth: 22,
      icon: Icons.diamond_rounded,
      color: Color(0xFFE0E0E0), // Platinum / White
      imagePath: 'assets/persona/gm_kingslayer.png',
    ),
  ];

  static AiAvatar getAvatar(String id) {
    return avatars.firstWhere((a) => a.id == id, orElse: () => avatars[6]); // Default to Vala
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
