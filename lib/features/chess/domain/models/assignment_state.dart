enum DailyTaskType {
  arena,
  puzzle,
  tutorial,
  historicalArchive,
  attendance,
  analysis,
}

class DailyTask {
  final String title;
  final String description;
  final DailyTaskType taskType;
  final String targetId;
  final int targetValue;
  final int currentValue;
  final bool isCompleted;

  const DailyTask({
    required this.title,
    required this.description,
    required this.taskType,
    required this.targetId,
    required this.targetValue,
    this.currentValue = 0,
    this.isCompleted = false,
  });

  DailyTask copyWith({
    String? title,
    String? description,
    DailyTaskType? taskType,
    String? targetId,
    int? targetValue,
    int? currentValue,
    bool? isCompleted,
  }) {
    return DailyTask(
      title: title ?? this.title,
      description: description ?? this.description,
      taskType: taskType ?? this.taskType,
      targetId: targetId ?? this.targetId,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'taskType': taskType.name,
    'targetId': targetId,
    'targetValue': targetValue,
    'currentValue': currentValue,
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
      currentValue: json['currentValue'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class MonthlySeasonHistory {
  final String monthId; // e.g. "2026-06"
  final int wins;
  final int draws;
  final int losses;
  final int lp;
  final String rank;
  final int assignmentsCompleted;

  const MonthlySeasonHistory({
    required this.monthId,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.lp,
    required this.rank,
    required this.assignmentsCompleted,
  });

  Map<String, dynamic> toJson() => {
    'monthId': monthId,
    'wins': wins,
    'draws': draws,
    'losses': losses,
    'lp': lp,
    'rank': rank,
    'assignmentsCompleted': assignmentsCompleted,
  };

  factory MonthlySeasonHistory.fromJson(Map<String, dynamic> json) {
    return MonthlySeasonHistory(
      monthId: json['monthId'] as String,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
      lp: json['lp'] as int,
      rank: json['rank'] as String,
      assignmentsCompleted: json['assignmentsCompleted'] as int? ?? 0,
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
  final int newlyCompletedTaskIndex;
  final Set<int> assignedCinemaIds;

  // Monthly Form Factor / LP Stats
  final int monthlyWins;
  final int monthlyDraws;
  final int monthlyLosses;
  final int monthlyAssignmentsCompleted;
  final int currentMonthLp;
  final String formFactorRank;

  // Island Archipelago Progression
  final int currentIslandIndex;
  final Set<int> landedIslandIndices;
  final int? landfallPendingIndex;
  final Map<int, List<int>> islandStepProgress;

  // Seasonal History
  final List<MonthlySeasonHistory> seasonHistory;

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
    this.newlyCompletedTaskIndex = -1,
    this.assignedCinemaIds = const {},
    this.monthlyWins = 0,
    this.monthlyDraws = 0,
    this.monthlyLosses = 0,
    this.monthlyAssignmentsCompleted = 0,
    this.currentMonthLp = 0,
    this.formFactorRank = 'Bronze',
    this.currentIslandIndex = 0,
    this.landedIslandIndices = const {},
    this.landfallPendingIndex,
    this.islandStepProgress = const {},
    this.seasonHistory = const [],
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
    int? newlyCompletedTaskIndex,
    Set<int>? assignedCinemaIds,
    int? monthlyWins,
    int? monthlyDraws,
    int? monthlyLosses,
    int? monthlyAssignmentsCompleted,
    int? currentMonthLp,
    String? formFactorRank,
    int? currentIslandIndex,
    Set<int>? landedIslandIndices,
    Object? landfallPendingIndex = const Object(),
    Map<int, List<int>>? islandStepProgress,
    List<MonthlySeasonHistory>? seasonHistory,
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
      newlyCompletedTaskIndex: newlyCompletedTaskIndex ?? this.newlyCompletedTaskIndex,
      assignedCinemaIds: assignedCinemaIds ?? this.assignedCinemaIds,
      monthlyWins: monthlyWins ?? this.monthlyWins,
      monthlyDraws: monthlyDraws ?? this.monthlyDraws,
      monthlyLosses: monthlyLosses ?? this.monthlyLosses,
      monthlyAssignmentsCompleted: monthlyAssignmentsCompleted ?? this.monthlyAssignmentsCompleted,
      currentMonthLp: currentMonthLp ?? this.currentMonthLp,
      formFactorRank: formFactorRank ?? this.formFactorRank,
      currentIslandIndex: currentIslandIndex ?? this.currentIslandIndex,
      landedIslandIndices: landedIslandIndices ?? this.landedIslandIndices,
      landfallPendingIndex: landfallPendingIndex == const Object()
          ? this.landfallPendingIndex
          : landfallPendingIndex as int?,
      islandStepProgress: islandStepProgress ?? this.islandStepProgress,
      seasonHistory: seasonHistory ?? this.seasonHistory,
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
    'newlyCompletedTaskIndex': newlyCompletedTaskIndex,
    'assignedCinemaIds': assignedCinemaIds.toList(),
    'monthlyWins': monthlyWins,
    'monthlyDraws': monthlyDraws,
    'monthlyLosses': monthlyLosses,
    'monthlyAssignmentsCompleted': monthlyAssignmentsCompleted,
    'currentMonthLp': currentMonthLp,
    'formFactorRank': formFactorRank,
    'currentIslandIndex': currentIslandIndex,
    'landedIslandIndices': landedIslandIndices.toList(),
    'landfallPendingIndex': landfallPendingIndex,
    'islandStepProgress': islandStepProgress.map((k, v) => MapEntry(k.toString(), v)),
    'seasonHistory': seasonHistory.map((e) => e.toJson()).toList(),
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
      newlyCompletedTaskIndex: json['newlyCompletedTaskIndex'] as int? ?? -1,
      assignedCinemaIds: Set<int>.from(json['assignedCinemaIds'] as List<dynamic>? ?? []),
      monthlyWins: json['monthlyWins'] as int? ?? 0,
      monthlyDraws: json['monthlyDraws'] as int? ?? 0,
      monthlyLosses: json['monthlyLosses'] as int? ?? 0,
      monthlyAssignmentsCompleted: json['monthlyAssignmentsCompleted'] as int? ?? 0,
      currentMonthLp: json['currentMonthLp'] as int? ?? 0,
      formFactorRank: json['formFactorRank'] as String? ?? 'Bronze',
      currentIslandIndex: json['currentIslandIndex'] as int? ?? 0,
      landedIslandIndices: Set<int>.from(json['landedIslandIndices'] as List<dynamic>? ?? []),
      landfallPendingIndex: json['landfallPendingIndex'] as int?,
      islandStepProgress: (json['islandStepProgress'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k.toString()), List<int>.from(v as List)),
          ) ??
          const {},
      seasonHistory: (json['seasonHistory'] as List<dynamic>? ?? [])
          .map((e) => MonthlySeasonHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
