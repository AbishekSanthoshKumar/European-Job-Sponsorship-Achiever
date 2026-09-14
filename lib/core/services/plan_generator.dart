import 'dart:math' as math;

import 'package:uuid/uuid.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/settings.dart';
import 'metrics_service.dart';

const _uuid = Uuid();

/// A weekly quota that the generator distributes across the remaining days.
class _Quota {
  const _Quota({
    required this.key,
    required this.category,
    required this.weeklyTarget,
    required this.titleFor,
    this.priority = TaskPriority.normal,
    this.minutesPerUnit = 0,
    this.isMinutes = false,
    this.dailyLimit,
  });

  final String key;
  final TaskCategory category;
  final int weeklyTarget;
  final String Function(int count) titleFor;
  final TaskPriority priority;
  final int minutesPerUnit;

  /// When true the "count" is minutes rather than a number of actions.
  final bool isMinutes;

  /// A humane ceiling for backlog recovery. Weekly targets still matter, but
  /// the generator should never turn one missed week into an impossible day.
  final int? dailyLimit;
}

class PlanContext {
  const PlanContext({
    this.applications = const [],
    this.opportunities = const [],
    this.companies = const [],
    this.agencies = const [],
    this.followUps = const [],
  });

  final List<JobApplication> applications;
  final List<JobOpportunity> opportunities;
  final List<Company> companies;
  final List<RecruitmentAgency> agencies;
  final List<FollowUp> followUps;
}

/// Builds the day's recommended task list from the weekly targets, taking
/// into account what has already been completed earlier in the week.
class PlanGenerator {
  const PlanGenerator(this.settings);

  final AppSettings settings;

  List<_Quota> get _quotas => [
    _Quota(
      key: 'applications',
      category: TaskCategory.applications,
      weeklyTarget: settings.weeklyApplications,
      priority: TaskPriority.critical,
      minutesPerUnit: 12,
      dailyLimit: 4,
      titleFor: (n) => n == 1 ? 'Apply to 1 role' : 'Apply to $n roles',
    ),
    _Quota(
      key: 'recruiter_messages',
      category: TaskCategory.networking,
      weeklyTarget: settings.weeklyRecruiterMessages,
      priority: TaskPriority.high,
      minutesPerUnit: 6,
      dailyLimit: 5,
      titleFor: (n) => n == 1 ? 'Message 1 recruiter' : 'Message $n recruiters',
    ),
    _Quota(
      key: 'connections',
      category: TaskCategory.networking,
      weeklyTarget: settings.weeklyConnections,
      minutesPerUnit: 2,
      dailyLimit: 8,
      titleFor: (n) =>
          'Send $n LinkedIn connection request'
          '${n == 1 ? '' : 's'}',
    ),
    _Quota(
      key: 'hiring_managers',
      category: TaskCategory.networking,
      weeklyTarget: settings.weeklyHiringManagerMessages,
      priority: TaskPriority.high,
      minutesPerUnit: 10,
      dailyLimit: 2,
      titleFor: (n) => 'Message $n hiring manager${n == 1 ? '' : 's'}',
    ),
    _Quota(
      key: 'follow_ups',
      category: TaskCategory.followUps,
      weeklyTarget: settings.weeklyFollowUps,
      priority: TaskPriority.high,
      minutesPerUnit: 5,
      dailyLimit: 4,
      titleFor: (n) => 'Follow up on $n application${n == 1 ? '' : 's'}',
    ),
    _Quota(
      key: 'research',
      category: TaskCategory.research,
      weeklyTarget: settings.weeklyCompanyResearch,
      minutesPerUnit: 8,
      dailyLimit: 2,
      titleFor: (n) => 'Research $n target compan${n == 1 ? 'y' : 'ies'}',
    ),
    _Quota(
      key: 'agencies',
      category: TaskCategory.agencies,
      weeklyTarget: settings.weeklyAgencyRegistrations,
      minutesPerUnit: 15,
      dailyLimit: 1,
      titleFor: (n) =>
          'Register with $n recruitment agenc${n == 1 ? 'y' : 'ies'}',
    ),
    _Quota(
      key: 'preparation',
      category: TaskCategory.preparation,
      weeklyTarget: settings.weeklyPrepMinutes,
      isMinutes: true,
      dailyLimit: 60,
      titleFor: (n) => 'Interview preparation: $n minutes',
    ),
  ];

  /// Generates the plan for [date].
  ///
  /// [weekTasks] are the already-existing tasks for the same week, used to
  /// work out what remains rather than blindly repeating the daily quota.
  List<DailyTask> generate({
    required DateTime date,
    required List<DailyTask> weekTasks,
    required List<DayLog> weekLogs,
    PlanContext context = const PlanContext(),
  }) {
    final day = dayOf(date);
    final weekStart = startOfWeek(day);
    final now = DateTime.now();

    // Days from today through Sunday, excluding days already marked as rest.
    final daysLeft = _remainingDays(day, weekStart, weekLogs);

    final out = <DailyTask>[..._followUpTasks(day, now, context.followUps)];

    final reservedByCategory = <TaskCategory, int>{};
    for (final task in out) {
      reservedByCategory[task.category] =
          (reservedByCategory[task.category] ?? 0) + task.targetCount;
    }

    for (final q in _quotas) {
      if (q.weeklyTarget <= 0) continue;

      final doneThisWeek = _completedForQuota(weekTasks, q, weekStart, day);
      final remaining = math.max(0, q.weeklyTarget - doneThisWeek);
      if (remaining == 0) continue;

      final rawTodayTarget = switch (settings.planMode) {
        // fixed share regardless of what was missed
        PlanMode.strict => (q.weeklyTarget / 7).ceil(),
        // spread what is left evenly over the days that remain
        PlanMode.flexible => (remaining / math.max(1, daysLeft)).ceil(),
        // front-load: take a larger bite now to recover the week
        PlanMode.catchUp => math.min(
          remaining,
          (remaining / math.max(1, daysLeft) * 1.5).ceil(),
        ),
      };

      final todayTarget =
          _capDailyTarget(q, rawTodayTarget) -
          (reservedByCategory[q.category] ?? 0);
      if (todayTarget <= 0) continue;

      final rounded = q.isMinutes
          // round prep to a sane 15-minute block
          ? (todayTarget / 15).ceil() * 15
          : todayTarget;

      out.addAll(
        _tasksForQuota(
          quota: q,
          count: rounded,
          day: day,
          now: now,
          context: context,
        ),
      );
    }

    return out;
  }

  int _capDailyTarget(_Quota q, int target) {
    final limit = q.dailyLimit;
    if (limit == null) return target;
    return math.min(target, limit);
  }

  List<DailyTask> _tasksForQuota({
    required _Quota quota,
    required int count,
    required DateTime day,
    required DateTime now,
    required PlanContext context,
  }) => switch (quota.key) {
    'applications' => _applicationTasks(day, now, count, context),
    'research' => _researchTasks(day, now, count, context.companies),
    'agencies' => _agencyTasks(day, now, count, context.agencies),
    _ => [
      DailyTask(
        id: _uuid.v4(),
        title: quota.titleFor(count),
        date: day,
        category: quota.category,
        priority: quota.priority,
        targetCount: quota.isMinutes ? 1 : count,
        estimatedMinutes: quota.isMinutes
            ? count
            : count * quota.minutesPerUnit,
        isAutoGenerated: true,
        recurrence: quota.key,
        createdAt: now,
        updatedAt: now,
      ),
    ],
  };

  List<DailyTask> _followUpTasks(
    DateTime day,
    DateTime now,
    List<FollowUp> followUps,
  ) {
    final due =
        followUps
            .where((f) => !f.isCompleted && !dayOf(f.dueDate).isAfter(day))
            .toList()
          ..sort((a, b) {
            final due = dayOf(a.dueDate).compareTo(dayOf(b.dueDate));
            if (due != 0) return due;
            return a.title.compareTo(b.title);
          });

    return due.take(4).map((f) {
      final overdue = day.difference(dayOf(f.dueDate)).inDays;
      final prefix = overdue > 0 ? 'Overdue follow-up' : 'Follow up';
      return DailyTask(
        id: _uuid.v4(),
        title: '$prefix: ${f.title.replaceFirst('Follow up: ', '')}',
        date: day,
        category: TaskCategory.followUps,
        priority: overdue > 0 ? TaskPriority.critical : TaskPriority.high,
        estimatedMinutes: 5,
        notes: [
          if (f.context.isNotEmpty) f.context,
          if (f.recommendedAction.isNotEmpty) f.recommendedAction,
        ].join('\n'),
        isAutoGenerated: true,
        recurrence: 'follow_up:${f.id}',
        applicationId: f.applicationId,
        contactId: f.contactId,
        agencyId: f.agencyId,
        companyId: f.companyId,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }

  List<DailyTask> _applicationTasks(
    DateTime day,
    DateTime now,
    int count,
    PlanContext context,
  ) {
    final open =
        context.opportunities
            .where(
              (o) =>
                  o.status != OpportunityStatus.applied &&
                  o.status != OpportunityStatus.discarded,
            )
            .toList()
          ..sort((a, b) {
            final ready = _opportunityReadiness(
              b,
            ).compareTo(_opportunityReadiness(a));
            if (ready != 0) return ready;
            final p = b.priority.weight.compareTo(a.priority.weight);
            if (p != 0) return p;
            return a.dateDiscovered.compareTo(b.dateDiscovered);
          });

    final tasks = <DailyTask>[];
    final usedCompanies = <String>{};
    for (final o in open.take(count)) {
      if (o.companyId != null) usedCompanies.add(o.companyId!);
      final company = o.companyName.isEmpty ? 'target company' : o.companyName;
      tasks.add(
        DailyTask(
          id: _uuid.v4(),
          title: 'Apply: ${o.jobTitle} at $company',
          date: day,
          category: TaskCategory.applications,
          priority: o.priority == TaskPriority.low
              ? TaskPriority.normal
              : o.priority,
          estimatedMinutes: 25,
          notes: [
            'Use the saved opportunity so you do not need to choose a role.',
            if (o.country.isNotEmpty) 'Market: ${o.country}',
            if (o.url.isNotEmpty) o.url,
          ].join('\n'),
          isAutoGenerated: true,
          recurrence: 'opportunity:${o.id}',
          companyId: o.companyId,
          country: o.country,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final remaining = count - tasks.length;
    if (remaining <= 0) return tasks;

    final companies =
        context.companies
            .where(
              (c) =>
                  c.relationship != CompanyRelationship.applied &&
                  c.relationship != CompanyRelationship.rejected &&
                  !usedCompanies.contains(c.id),
            )
            .toList()
          ..sort((a, b) {
            final p = b.priority.weight.compareTo(a.priority.weight);
            if (p != 0) return p;
            final sponsorship = b.sponsorshipLikelihood.compareTo(
              a.sponsorshipLikelihood,
            );
            if (sponsorship != 0) return sponsorship;
            return a.name.compareTo(b.name);
          });

    for (final c in companies.take(remaining)) {
      tasks.add(
        DailyTask(
          id: _uuid.v4(),
          title: 'Find and apply: ${c.name}',
          date: day,
          category: TaskCategory.applications,
          priority: c.priority.weight >= CompanyPriority.high.weight
              ? TaskPriority.high
              : TaskPriority.normal,
          estimatedMinutes: 25,
          notes: [
            'Open the company career page and apply to the best matching role.',
            if (c.displayLocation.isNotEmpty) c.displayLocation,
            if (c.careerUrl.isNotEmpty) c.careerUrl,
          ].join('\n'),
          isAutoGenerated: true,
          recurrence: 'company_application:${c.id}',
          companyId: c.id,
          country: c.country,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return tasks.isNotEmpty
        ? tasks
        : [
            DailyTask(
              id: _uuid.v4(),
              title:
                  'Apply to $count pre-selected role${count == 1 ? '' : 's'}',
              date: day,
              category: TaskCategory.applications,
              priority: TaskPriority.critical,
              targetCount: count,
              estimatedMinutes: count * 12,
              notes: 'Add opportunities first for named daily suggestions.',
              isAutoGenerated: true,
              recurrence: 'applications',
              createdAt: now,
              updatedAt: now,
            ),
          ];
  }

  List<DailyTask> _researchTasks(
    DateTime day,
    DateTime now,
    int count,
    List<Company> companies,
  ) {
    final targets =
        companies
            .where(
              (c) =>
                  c.relationship == CompanyRelationship.notResearched ||
                  c.relationship == CompanyRelationship.futureTarget,
            )
            .toList()
          ..sort((a, b) {
            final p = b.priority.weight.compareTo(a.priority.weight);
            if (p != 0) return p;
            return b.sponsorshipLikelihood.compareTo(a.sponsorshipLikelihood);
          });

    if (targets.isEmpty) {
      return [
        DailyTask(
          id: _uuid.v4(),
          title: 'Research $count target compan${count == 1 ? 'y' : 'ies'}',
          date: day,
          category: TaskCategory.research,
          targetCount: count,
          estimatedMinutes: count * 8,
          isAutoGenerated: true,
          recurrence: 'research',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }

    return targets.take(count).map((c) {
      return DailyTask(
        id: _uuid.v4(),
        title: 'Research: ${c.name}',
        date: day,
        category: TaskCategory.research,
        estimatedMinutes: 12,
        notes: [
          'Check visa sponsorship signals, open roles, and one hiring contact.',
          if (c.displayLocation.isNotEmpty) c.displayLocation,
          if (c.website.isNotEmpty) c.website,
        ].join('\n'),
        isAutoGenerated: true,
        recurrence: 'company_research:${c.id}',
        companyId: c.id,
        country: c.country,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }

  List<DailyTask> _agencyTasks(
    DateTime day,
    DateTime now,
    int count,
    List<RecruitmentAgency> agencies,
  ) {
    final targets =
        agencies.where((a) => a.status == AgencyStatus.notContacted).toList()
          ..sort((a, b) {
            final p = b.priority.weight.compareTo(a.priority.weight);
            if (p != 0) return p;
            return b.matchScore.compareTo(a.matchScore);
          });

    if (targets.isEmpty) {
      return [
        DailyTask(
          id: _uuid.v4(),
          title:
              'Register with $count recruitment agenc${count == 1 ? 'y' : 'ies'}',
          date: day,
          category: TaskCategory.agencies,
          targetCount: count,
          estimatedMinutes: count * 15,
          isAutoGenerated: true,
          recurrence: 'agencies',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }

    return targets.take(count).map((a) {
      return DailyTask(
        id: _uuid.v4(),
        title: 'Register/contact: ${a.name}',
        date: day,
        category: TaskCategory.agencies,
        estimatedMinutes: 15,
        notes: [
          'Send your profile or register, then set the next follow-up date.',
          if (a.country.isNotEmpty) a.country,
          if (a.website.isNotEmpty) a.website,
        ].join('\n'),
        isAutoGenerated: true,
        recurrence: 'agency:${a.id}',
        agencyId: a.id,
        country: a.country,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }

  int _opportunityReadiness(JobOpportunity o) => switch (o.status) {
    OpportunityStatus.readyToApply => 4,
    OpportunityStatus.goodMatch => 3,
    OpportunityStatus.researching => 2,
    OpportunityStatus.inbox => 1,
    OpportunityStatus.applied || OpportunityStatus.discarded => 0,
  };

  /// Days remaining in the week including [day] itself, minus excused days.
  int _remainingDays(DateTime day, DateTime weekStart, List<DayLog> logs) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    if (day.isAfter(weekEnd)) return 1;

    var count = 0;
    for (var d = day; !d.isAfter(weekEnd); d = d.add(const Duration(days: 1))) {
      final log = logs.where((l) => dayOf(l.date) == dayOf(d));
      // a future rest day contributes no capacity
      if (log.isNotEmpty && log.first.dayType.isExcused && d != day) continue;
      count++;
    }
    return math.max(1, count);
  }

  /// How much of this quota has already been completed earlier this week.
  /// Only days strictly before [today] count, so regenerating today's plan
  /// does not subtract work logged against today's own tasks.
  int _completedForQuota(
    List<DailyTask> weekTasks,
    _Quota q,
    DateTime weekStart,
    DateTime today,
  ) {
    var sum = 0;
    for (final t in weekTasks) {
      if (t.recurrence != q.key) continue;
      final d = dayOf(t.date);
      if (d.isBefore(weekStart) || !d.isBefore(today)) continue;
      if (q.isMinutes) {
        sum += t.actualMinutes;
      } else {
        sum += t.status == TaskStatus.completed && t.completedCount == 0
            ? t.targetCount
            : t.completedCount;
      }
    }
    return sum;
  }

  /// Country nudge: which market is furthest below its allocation, so the
  /// day's application task can name it.
  static String? suggestedCountry(List<CountryAllocation> allocation) {
    final under =
        allocation.where((a) => a.isUnder && a.targetPercent > 0).toList()
          ..sort((a, b) => a.delta.compareTo(b.delta));
    return under.isEmpty ? null : under.first.country;
  }
}
