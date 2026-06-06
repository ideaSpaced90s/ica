enum DailyTaskType {
  arena,
  puzzle,
  tutorial,
}

class DailyTask {
  final String title;
  final String description;
  final DailyTaskType taskType;
  final String targetId;
  final int targetValue;
  final bool isCompleted;

  const DailyTask({
    required this.title,
    required this.description,
    required this.taskType,
    required this.targetId,
    required this.targetValue,
    this.isCompleted = false,
  });

  DailyTask copyWith({
    String? title,
    String? description,
    DailyTaskType? taskType,
    String? targetId,
    int? targetValue,
    bool? isCompleted,
  }) {
    return DailyTask(
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      targetId: targetId ?? this.targetId,
      targetValue: targetValue ?? this.targetValue,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'taskType': taskType.name,
    'targetId': targetId,
    'targetValue': targetValue,
    'isCompleted': isCompleted,
  };

  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      title: json['title'] as String,
      description: json['description'] as String,
      taskType: DailyTaskType.values.firstWhere(
        (e) => e.name == json['taskType'],
        orElse: () => DailyTaskType.arena,
      ),
      targetId: json['targetId'] as String,
      targetValue: json['targetValue'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class AssignmentState {
  final int calibrationGamesPlayed;
  final bool isCalibrated;
  final int goalElo;
  final int startElo;
  final DateTime? goalDeadline;
  final List<DailyTask> dailyTasks;
  final DateTime lastResetDate;
  final Map<String, bool> historyLog;
  final bool weeklyReviewSubmitted;
  final String? submittedGameId;
  final String? weeklyReport;
  final String wisdomMessage;

  const AssignmentState({
    this.calibrationGamesPlayed = 0,
    this.isCalibrated = false,
    this.goalElo = 0,
    this.startElo = 0,
    this.goalDeadline,
    this.dailyTasks = const [],
    required this.lastResetDate,
    this.historyLog = const {},
    this.weeklyReviewSubmitted = false,
    this.submittedGameId,
    this.weeklyReport,
    this.wisdomMessage = '',
  });

  AssignmentState copyWith({
    int? calibrationGamesPlayed,
    bool? isCalibrated,
    int? goalElo,
    int? startElo,
    DateTime? goalDeadline,
    List<DailyTask>? dailyTasks,
    DateTime? lastResetDate,
    Map<String, bool>? historyLog,
    bool? weeklyReviewSubmitted,
    String? submittedGameId,
    String? weeklyReport,
    String? wisdomMessage,
  }) {
    return AssignmentState(
      calibrationGamesPlayed: calibrationGamesPlayed ?? this.calibrationGamesPlayed,
      isCalibrated: isCalibrated ?? this.isCalibrated,
      goalElo: goalElo ?? this.goalElo,
      startElo: startElo ?? this.startElo,
      goalDeadline: goalDeadline ?? this.goalDeadline,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      historyLog: historyLog ?? this.historyLog,
      weeklyReviewSubmitted: weeklyReviewSubmitted ?? this.weeklyReviewSubmitted,
      submittedGameId: submittedGameId ?? this.submittedGameId,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      wisdomMessage: wisdomMessage ?? this.wisdomMessage,
    );
  }

  Map<String, dynamic> toJson() => {
    'calibrationGamesPlayed': calibrationGamesPlayed,
    'isCalibrated': isCalibrated,
    'goalElo': goalElo,
    'startElo': startElo,
    'goalDeadline': goalDeadline?.toIso8601String(),
    'dailyTasks': dailyTasks.map((e) => e.toJson()).toList(),
    'lastResetDate': lastResetDate.toIso8601String(),
    'historyLog': historyLog,
    'weeklyReviewSubmitted': weeklyReviewSubmitted,
    'submittedGameId': submittedGameId,
    'weeklyReport': weeklyReport,
    'wisdomMessage': wisdomMessage,
  };

  factory AssignmentState.fromJson(Map<String, dynamic> json) {
    return AssignmentState(
      calibrationGamesPlayed: json['calibrationGamesPlayed'] as int? ?? 0,
      isCalibrated: json['isCalibrated'] as bool? ?? false,
      goalElo: json['goalElo'] as int? ?? 0,
      startElo: json['startElo'] as int? ?? 0,
      goalDeadline: json['goalDeadline'] != null ? DateTime.parse(json['goalDeadline'] as String) : null,
      dailyTasks: (json['dailyTasks'] as List<dynamic>? ?? [])
          .map((e) => DailyTask.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastResetDate: json['lastResetDate'] != null ? DateTime.parse(json['lastResetDate'] as String) : DateTime.now(),
      historyLog: Map<String, bool>.from(json['historyLog'] ?? {}),
      weeklyReviewSubmitted: json['weeklyReviewSubmitted'] as bool? ?? false,
      submittedGameId: json['submittedGameId'] as String?,
      weeklyReport: json['weeklyReport'] as String?,
      wisdomMessage: json['wisdomMessage'] as String? ?? '',
    );
  }
}
