import 'dart:math' as math;

import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/settings.dart';

/// Score for a single day, 0-100, weighted by task category.
class DailyScore {
  const DailyScore({
    required this.date,
    required this.score,
    required this.tasksTotal,
    required this.tasksCompleted,
    required this.dayType,
    required this.byCategory,
  });

  final DateTime date;
  final double score;
  final int tasksTotal;
  final int tasksCompleted;
  final DayType dayType;

  /// Category -> 0..1 completion.
  final Map<TaskCategory, double> byCategory;

  bool get hasActivity => tasksCompleted > 0;

  /// 0-4 bucket used by the consistency heatmap.
  int get intensity {
    if (dayType.isExcused && tasksCompleted == 0) return 0;
    if (score <= 0) return 0;
    if (score < 25) return 1;
    if (score < 50) return 2;
    if (score < 80) return 3;
    return 4;
  }
}

class StreakStats {
  const StreakStats({
    required this.current,
    required this.best,
    required this.monthlyConsistency,
    required this.activeDaysThisMonth,
    required this.daysInMonthSoFar,
  });

  final int current;
  final int best;

  /// 0..1 share of days this month that met the streak threshold.
  final double monthlyConsistency;
  final int activeDaysThisMonth;
  final int daysInMonthSoFar;
}

class StreakService {
  const StreakService(this.settings);

  final AppSettings settings;

  /// Weighted completion score for one day's tasks.
  DailyScore scoreFor({
    required DateTime date,
    required List<DailyTask> tasks,
    DayLog? log,
  }) {
    final day = dayOf(date);
    final dayTasks = tasks.where((t) => dayOf(t.date) == day).toList();
    final dayType = log?.dayType ?? DayType.normal;

    if (dayTasks.isEmpty) {
      return DailyScore(
        date: day,
        score: 0,
        tasksTotal: 0,
        tasksCompleted: 0,
        dayType: dayType,
        byCategory: const {},
      );
    }

    final weights = settings.dailyScoreWeights;
    // group progress by category, then combine using the category weights
    final progressByCategory = <TaskCategory, List<double>>{};
    for (final t in dayTasks) {
      if (t.status == TaskStatus.skipped) continue;
      (progressByCategory[t.category] ??= []).add(t.progress);
    }

    var weighted = 0.0;
    var weightSum = 0.0;
    final byCategory = <TaskCategory, double>{};

    for (final entry in progressByCategory.entries) {
      final avg =
          entry.value.reduce((a, b) => a + b) / entry.value.length;
      byCategory[entry.key] = avg;
      final w = weights.weightFor(entry.key);
      weighted += avg * w;
      weightSum += w;
    }

    final score = weightSum == 0 ? 0.0 : (weighted / weightSum) * 100;

    return DailyScore(
      date: day,
      score: score.clamp(0, 100),
      tasksTotal: dayTasks.length,
      tasksCompleted:
          dayTasks.where((t) => t.status == TaskStatus.completed).length,
      dayType: dayType,
      byCategory: byCategory,
    );
  }

  /// A day counts toward the streak when it clears the threshold, or when it
  /// was explicitly marked as rest/sick/emergency.
  bool countsForStreak(DailyScore s) {
    if (s.dayType.isExcused) return true;
    return s.score >= settings.streakThreshold * 100;
  }

  StreakStats compute({
    required List<DailyTask> allTasks,
    required List<DayLog> logs,
    DateTime? asOf,
  }) {
    final today = dayOf(asOf ?? DateTime.now());
    if (allTasks.isEmpty) {
      return const StreakStats(
        current: 0,
        best: 0,
        monthlyConsistency: 0,
        activeDaysThisMonth: 0,
        daysInMonthSoFar: 1,
      );
    }

    final logByDay = {for (final l in logs) dayOf(l.date): l};
    final tasksByDay = <DateTime, List<DailyTask>>{};
    for (final t in allTasks) {
      (tasksByDay[dayOf(t.date)] ??= []).add(t);
    }

    final firstDay = tasksByDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);

    // walk every day from the first recorded day to today
    final scores = <DateTime, DailyScore>{};
    for (var d = firstDay; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
      scores[d] = scoreFor(
        date: d,
        tasks: tasksByDay[d] ?? const [],
        log: logByDay[d],
      );
    }

    // current streak walks backwards from today; today not yet qualifying
    // does not break the streak, it simply has not extended it yet
    var current = 0;
    var cursor = today;
    if (scores[today] != null && !countsForStreak(scores[today]!)) {
      cursor = today.subtract(const Duration(days: 1));
    }
    while (scores[cursor] != null && countsForStreak(scores[cursor]!)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    // best streak over the whole history
    var best = 0;
    var run = 0;
    for (var d = firstDay; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
      final s = scores[d];
      if (s != null && countsForStreak(s)) {
        run++;
        best = math.max(best, run);
      } else {
        run = 0;
      }
    }
    best = math.max(best, current);

    // consistency for the current calendar month
    final monthStart = DateTime(today.year, today.month);
    var active = 0;
    var days = 0;
    for (var d = monthStart;
        !d.isAfter(today);
        d = d.add(const Duration(days: 1))) {
      days++;
      final s = scores[d];
      if (s != null && countsForStreak(s)) active++;
    }

    return StreakStats(
      current: current,
      best: best,
      monthlyConsistency: days == 0 ? 0 : active / days,
      activeDaysThisMonth: active,
      daysInMonthSoFar: math.max(1, days),
    );
  }

  /// Daily scores for the trailing [days] window, for the heatmap.
  List<DailyScore> history({
    required List<DailyTask> allTasks,
    required List<DayLog> logs,
    int days = 182,
  }) {
    final today = dayOf(DateTime.now());
    final logByDay = {for (final l in logs) dayOf(l.date): l};
    final tasksByDay = <DateTime, List<DailyTask>>{};
    for (final t in allTasks) {
      (tasksByDay[dayOf(t.date)] ??= []).add(t);
    }

    return [
      for (var i = days - 1; i >= 0; i--)
        () {
          final d = today.subtract(Duration(days: i));
          return scoreFor(
            date: d,
            tasks: tasksByDay[d] ?? const [],
            log: logByDay[d],
          );
        }(),
    ];
  }
}
