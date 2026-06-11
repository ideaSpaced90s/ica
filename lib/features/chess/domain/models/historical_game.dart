import 'tutorial_lesson.dart' show MentorMood;

class HistoricalAnnotation {
  final String commentary;
  final MentorMood mood;

  const HistoricalAnnotation({
    required this.commentary,
    required this.mood,
  });

  factory HistoricalAnnotation.fromJson(Map<String, dynamic> json) {
    final moodStr = json['mood'] as String? ?? 'calm';
    MentorMood mood;
    switch (moodStr) {
      case 'encouraging':
        mood = MentorMood.encouraging;
        break;
      case 'correction':
        mood = MentorMood.correction;
        break;
      case 'celebration':
        mood = MentorMood.celebration;
        break;
      case 'calm':
      default:
        mood = MentorMood.calm;
        break;
    }
    return HistoricalAnnotation(
      commentary: json['commentary'] as String? ?? '',
      mood: mood,
    );
  }
}

class HistoricalGame {
  final int id;
  final String category;
  final String white;
  final String black;
  final String year;
  final String event;
  final String educationalTheme;
  final String pgn;
  final List<String> moves;
  final List<String> fens;
  final Map<int, HistoricalAnnotation> annotations;

  const HistoricalGame({
    required this.id,
    required this.category,
    required this.white,
    required this.black,
    required this.year,
    required this.event,
    required this.educationalTheme,
    required this.pgn,
    required this.moves,
    required this.fens,
    required this.annotations,
  });

  factory HistoricalGame.fromJson(Map<String, dynamic> json) {
    final rawAnnotations = json['annotations'] as Map<String, dynamic>? ?? {};
    final parsedAnnotations = <int, HistoricalAnnotation>{};
    rawAnnotations.forEach((key, value) {
      final idx = int.tryParse(key);
      if (idx != null && value is Map<String, dynamic>) {
        parsedAnnotations[idx] = HistoricalAnnotation.fromJson(value);
      }
    });

    return HistoricalGame(
      id: json['id'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      white: json['white'] as String? ?? '',
      black: json['black'] as String? ?? '',
      year: json['year'] as String? ?? '',
      event: json['event'] as String? ?? '',
      educationalTheme: json['educationalTheme'] as String? ?? '',
      pgn: json['pgn'] as String? ?? '',
      moves: List<String>.from(json['moves'] as List? ?? []),
      fens: List<String>.from(json['fens'] as List? ?? []),
      annotations: parsedAnnotations,
    );
  }
}
