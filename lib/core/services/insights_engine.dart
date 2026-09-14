import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/settings.dart';
import '../theme/app_colors.dart';
import 'metrics_service.dart';
import 'streak_service.dart';

enum InsightTone { positive, neutral, warning, critical }

enum InsightKind { strategy, consistency, performance, followUp, resume, milestone }

class Insight {
  const Insight({
    required this.message,
    required this.tone,
    required this.kind,
    this.detail = '',
    this.actionLabel,
    this.actionRoute,
    this.priority = 0,
  });

  final String message;
  final String detail;
  final InsightTone tone;
  final InsightKind kind;
  final String? actionLabel;
  final String? actionRoute;

  /// Higher sorts first.
  final int priority;

  Color get color => switch (tone) {
        InsightTone.positive => AppColors.success,
        InsightTone.neutral => AppColors.info,
        InsightTone.warning => AppColors.warning,
        InsightTone.critical => AppColors.danger,
      };

  IconData get icon => switch (kind) {
        InsightKind.strategy => Icons.public_rounded,
        InsightKind.consistency => Icons.local_fire_department_rounded,
        InsightKind.performance => Icons.trending_up_rounded,
        InsightKind.followUp => Icons.reply_rounded,
        InsightKind.resume => Icons.description_rounded,
        InsightKind.milestone => Icons.emoji_events_rounded,
      };
}

/// Deterministic, rule-based analysis. No AI calls — every message here is
/// derived from the user's own numbers.
class InsightsEngine {
  const InsightsEngine({
    required this.settings,
    required this.applications,
    required this.tasks,
    required this.followUps,
    required this.contacts,
    required this.agencies,
    required this.resumes,
    required this.interviews,
    required this.streak,
  });

  final AppSettings settings;
  final List<JobApplication> applications;
  final List<DailyTask> tasks;
  final List<FollowUp> followUps;
  final List<NetworkContact> contacts;
  final List<RecruitmentAgency> agencies;
  final List<Resume> resumes;
  final List<Interview> interviews;
  final StreakStats streak;

  ApplicationMetrics get _metrics =>
      ApplicationMetrics(applications, settings);

  List<Insight> generate({int limit = 6}) {
    final out = <Insight>[
      ..._weeklyPace(),
      ..._countryAllocation(),
      ..._consistency(),
      ..._followUps(),
      ..._performance(),
      ..._resumeComparison(),
      ..._interviewsSoon(),
      ..._agencyCoverage(),
      ..._milestones(),
    ];

    out.sort((a, b) => b.priority.compareTo(a.priority));
    return out.take(limit).toList();
  }

  // -- weekly application pace ---------------------------------------------

  List<Insight> _weeklyPace() {
    final m = _metrics;
    final target = settings.weeklyApplications;
    if (target <= 0) return const [];

    final done = m.thisWeek;
    final now = DateTime.now();
    // days elapsed in the week, 1..7
    final elapsed = now.weekday;
    final expected = (target * elapsed / 7).round();
    final diff = done - expected;

    if (diff <= -3) {
      return [
        Insight(
          message: 'You are ${diff.abs()} applications behind your weekly pace.',
          detail: '$done of $target sent — about $expected expected by now.',
          tone: InsightTone.warning,
          kind: InsightKind.strategy,
          actionLabel: 'Open Today',
          actionRoute: '/today',
          priority: 85,
        ),
      ];
    }
    if (diff >= 5) {
      return [
        Insight(
          message: 'You are $diff applications ahead of your weekly pace.',
          detail: '$done of $target sent with ${7 - elapsed} days left.',
          tone: InsightTone.positive,
          kind: InsightKind.strategy,
          priority: 40,
        ),
      ];
    }
    if (done >= target) {
      return [
        Insight(
          message: 'Weekly application target reached: $done of $target.',
          tone: InsightTone.positive,
          kind: InsightKind.milestone,
          priority: 55,
        ),
      ];
    }
    return const [];
  }

  // -- country allocation vs strategy ---------------------------------------

  List<Insight> _countryAllocation() {
    final m = _metrics;
    if (m.total < 8) return const [];

    final alloc = m.countryAllocation();
    final out = <Insight>[];

    final under = alloc
        .where((a) => a.isUnder && a.targetPercent >= 5)
        .toList()
      ..sort((a, b) => a.delta.compareTo(b.delta));

    if (under.isNotEmpty) {
      final worst = under.first;
      final gap = ApplicationMetrics.gapToTarget(worst, m.total);
      out.add(Insight(
        message: '${worst.country} is below your planned allocation.',
        detail: 'Target ${worst.targetPercent.toStringAsFixed(0)}%, '
            'actual ${worst.actualPercent.toStringAsFixed(0)}%. '
            'Roughly $gap more application${gap == 1 ? '' : 's'} would '
            'realign it.',
        tone: InsightTone.warning,
        kind: InsightKind.strategy,
        actionLabel: 'Country strategy',
        actionRoute: '/countries',
        priority: 80,
      ));
    }

    final over = alloc.where((a) => a.isOver && a.applications >= 5).toList()
      ..sort((a, b) => b.delta.compareTo(a.delta));
    if (over.isNotEmpty && under.isNotEmpty) {
      final o = over.first;
      out.add(Insight(
        message: '${o.country} is above its planned share.',
        detail: '${o.actualPercent.toStringAsFixed(0)}% of applications vs a '
            '${o.targetPercent.toStringAsFixed(0)}% target.',
        tone: InsightTone.neutral,
        kind: InsightKind.strategy,
        priority: 30,
      ));
    }

    // silence detection on a primary market
    for (final a in alloc.where((c) => c.targetPercent >= 15)) {
      final last = applications
          .where((x) =>
              x.country.toLowerCase() == a.country.toLowerCase() &&
              x.dateApplied != null)
          .map((x) => x.dateApplied!)
          .fold<DateTime?>(
              null, (acc, d) => acc == null || d.isAfter(acc) ? d : acc);
      if (last == null) continue;
      final days = dayOf(DateTime.now()).difference(dayOf(last)).inDays;
      if (days >= 7) {
        out.add(Insight(
          message: "You haven't applied to ${a.country} in $days days.",
          detail: 'Your strategy allocates '
              '${a.targetPercent.toStringAsFixed(0)}% there.',
          tone: InsightTone.warning,
          kind: InsightKind.strategy,
          priority: 70,
        ));
      }
    }

    return out;
  }

  // -- consistency ----------------------------------------------------------

  List<Insight> _consistency() {
    final out = <Insight>[];

    if (streak.current >= 3) {
      out.add(Insight(
        message: 'Great consistency — ${streak.current} days in a row.',
        detail: streak.current >= streak.best && streak.best > 0
            ? 'This matches your best streak.'
            : 'Best streak: ${streak.best} days.',
        tone: InsightTone.positive,
        kind: InsightKind.consistency,
        priority: 45,
      ));
    }

    // no applications for 3+ days
    final lastApplied = applications
        .where((a) => a.dateApplied != null)
        .map((a) => a.dateApplied!)
        .fold<DateTime?>(
            null, (acc, d) => acc == null || d.isAfter(acc) ? d : acc);

    if (lastApplied != null) {
      final gap = dayOf(DateTime.now()).difference(dayOf(lastApplied)).inDays;
      if (gap >= 3) {
        out.add(Insight(
          message: 'No applications logged for $gap days.',
          detail: 'Consider reducing the daily workload rather than '
              'abandoning the plan — a smaller consistent number beats '
              'an occasional burst.',
          tone: gap >= 6 ? InsightTone.critical : InsightTone.warning,
          kind: InsightKind.consistency,
          actionLabel: 'Open Today',
          actionRoute: '/today',
          priority: 90,
        ));
      }
    }

    return out;
  }

  // -- follow-ups -----------------------------------------------------------

  List<Insight> _followUps() {
    final overdue = followUps.where((f) => f.isOverdue).toList();
    final out = <Insight>[];

    if (overdue.isNotEmpty) {
      overdue.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      final worst = overdue.first;
      out.add(Insight(
        message: overdue.length == 1
            ? '1 follow-up is overdue.'
            : '${overdue.length} follow-ups are overdue.',
        detail: '${worst.title} — ${worst.daysUntilDue.abs()} '
            'day${worst.daysUntilDue.abs() == 1 ? '' : 's'} late.',
        tone: InsightTone.critical,
        kind: InsightKind.followUp,
        actionLabel: 'Follow-up centre',
        actionRoute: '/followups',
        priority: 95,
      ));
    }

    final nudge = contacts
        .where((c) => c.needsNudge(afterDays: settings.contactNudgeDays))
        .toList();
    if (nudge.isNotEmpty) {
      final c = nudge.first;
      out.add(Insight(
        message: nudge.length == 1
            ? 'You contacted ${c.name} ${c.daysSinceContacted} days ago '
                'with no reply.'
            : '${nudge.length} contacts have gone quiet since you '
                'reached out.',
        detail: 'A short, specific nudge often revives these threads.',
        tone: InsightTone.warning,
        kind: InsightKind.followUp,
        actionLabel: 'Networking',
        actionRoute: '/network',
        priority: 65,
      ));
    }

    return out;
  }

  // -- what is actually working ---------------------------------------------

  List<Insight> _performance() {
    final m = _metrics;
    if (m.total < 10) return const [];

    final out = <Insight>[];

    // best converting country with a meaningful sample
    final countries = m.byCountry.values
        .where((s) => s.applications >= 5)
        .toList()
      ..sort((a, b) => b.interviewRate.compareTo(a.interviewRate));
    if (countries.length >= 2 && countries.first.interviewRate > 0) {
      final best = countries.first;
      out.add(Insight(
        message: '${best.label} has your highest interview conversion rate.',
        detail: '${(best.interviewRate * 100).toStringAsFixed(0)}% of '
            '${best.applications} applications reached an interview.',
        tone: InsightTone.positive,
        kind: InsightKind.performance,
        actionLabel: 'Analytics',
        actionRoute: '/analytics',
        priority: 50,
      ));
    }

    // role comparison, expressed as a multiple
    final roles = m.byRole.values.where((s) => s.applications >= 5).toList()
      ..sort((a, b) => b.interviewRate.compareTo(a.interviewRate));
    if (roles.length >= 2) {
      final best = roles.first;
      final worst = roles.last;
      if (worst.interviewRate > 0 &&
          best.interviewRate / worst.interviewRate >= 1.5) {
        final ratio = best.interviewRate / worst.interviewRate;
        out.add(Insight(
          message: '${best.label} roles are generating '
              '${ratio.toStringAsFixed(1)}x more interviews than '
              '${worst.label}.',
          detail: 'Consider shifting more of your weekly volume '
              'toward ${best.label}.',
          tone: InsightTone.neutral,
          kind: InsightKind.performance,
          priority: 48,
        ));
      }
    }

    // best source
    final sources = m.bySource.values
        .where((s) => s.applications >= 5)
        .toList()
      ..sort((a, b) => b.responseRate.compareTo(a.responseRate));
    if (sources.length >= 2 && sources.first.responseRate > 0) {
      final best = sources.first;
      out.add(Insight(
        message: '${best.label} is your best-performing source.',
        detail: '${(best.responseRate * 100).toStringAsFixed(0)}% response '
            'rate across ${best.applications} applications.',
        tone: InsightTone.positive,
        kind: InsightKind.performance,
        priority: 42,
      ));
    }

    // overall response rate health
    if (m.total >= 20 && m.responseRate < 0.05) {
      out.add(Insight(
        message: 'Your response rate is '
            '${(m.responseRate * 100).toStringAsFixed(1)}% across '
            '${m.total} applications.',
        detail: 'Below ~5% usually points at resume fit or visa filtering '
            'rather than volume. Try prioritising roles that explicitly '
            'mention sponsorship.',
        tone: InsightTone.warning,
        kind: InsightKind.performance,
        priority: 75,
      ));
    }

    return out;
  }

  // -- resume experimentation ----------------------------------------------

  List<Insight> _resumeComparison() {
    final m = _metrics;
    final byResume = m.byResume;
    if (byResume.length < 2) return const [];

    final named = <String, SegmentStats>{};
    for (final entry in byResume.entries) {
      final resume = resumes.where((r) => r.id == entry.key);
      if (resume.isEmpty) continue;
      named[resume.first.name] = entry.value;
    }

    final eligible =
        named.entries.where((e) => e.value.applications >= 20).toList();
    if (eligible.length < 2) return const [];

    eligible.sort((a, b) => b.value.responseRate.compareTo(a.value.responseRate));
    final best = eligible.first;
    final worst = eligible.last;
    if (best.value.responseRate <= worst.value.responseRate) return const [];

    return [
      Insight(
        message: 'Your ${best.key} is your strongest resume.',
        detail:
            '${(best.value.responseRate * 100).toStringAsFixed(0)}% response '
            'rate vs ${(worst.value.responseRate * 100).toStringAsFixed(0)}% '
            'for ${worst.key}.',
        tone: InsightTone.positive,
        kind: InsightKind.resume,
        actionLabel: 'Resumes',
        actionRoute: '/resumes',
        priority: 60,
      ),
    ];
  }

  // -- upcoming interviews --------------------------------------------------

  List<Insight> _interviewsSoon() {
    final upcoming = interviews
        .where((i) => i.isUpcoming && i.daysUntil <= 7 && i.daysUntil >= 0)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (upcoming.isEmpty) return const [];
    final next = upcoming.first;
    final when = switch (next.daysUntil) {
      0 => 'today',
      1 => 'tomorrow',
      final d => 'in $d days',
    };

    return [
      Insight(
        message: '${next.stage.label} at ${next.companyName} $when.',
        detail: next.prepProgress < 1
            ? 'Preparation checklist is '
                '${(next.prepProgress * 100).round()}% complete.'
            : 'Preparation checklist complete.',
        tone: next.prepProgress < 0.5
            ? InsightTone.warning
            : InsightTone.neutral,
        kind: InsightKind.milestone,
        actionLabel: 'Interviews',
        actionRoute: '/interviews',
        priority: 92,
      ),
    ];
  }

  // -- agency pipeline ------------------------------------------------------

  List<Insight> _agencyCoverage() {
    final real = agencies.where((a) => !a.isJobBoard).toList();
    if (real.isEmpty) return const [];

    final notContacted =
        real.where((a) => a.status == AgencyStatus.notContacted).toList();
    final highPriorityUntouched = notContacted
        .where((a) =>
            a.priority == AgencyPriority.highest ||
            a.priority == AgencyPriority.high)
        .toList();

    if (highPriorityUntouched.isEmpty) return const [];

    return [
      Insight(
        message: '${highPriorityUntouched.length} high-priority '
            'agenc${highPriorityUntouched.length == 1 ? 'y' : 'ies'} '
            'not contacted yet.',
        detail: 'Starting with ${highPriorityUntouched.first.name} '
            '(${highPriorityUntouched.first.country}).',
        tone: InsightTone.neutral,
        kind: InsightKind.strategy,
        actionLabel: 'Agencies',
        actionRoute: '/agencies',
        priority: 58,
      ),
    ];
  }

  // -- milestones -----------------------------------------------------------

  List<Insight> _milestones() {
    final m = _metrics;
    final out = <Insight>[];

    if (m.offers > 0) {
      out.add(Insight(
        message: m.offers == 1
            ? 'You have an offer on the table.'
            : 'You have ${m.offers} offers on the table.',
        tone: InsightTone.positive,
        kind: InsightKind.milestone,
        actionLabel: 'Applications',
        actionRoute: '/applications',
        priority: 100,
      ));
    }

    // round-number application milestones
    for (final n in const [50, 100, 200, 300, 500]) {
      if (m.total == n) {
        out.add(Insight(
          message: '$n applications sent.',
          detail: 'Response rate so far: '
              '${(m.responseRate * 100).toStringAsFixed(1)}%.',
          tone: InsightTone.positive,
          kind: InsightKind.milestone,
          priority: 62,
        ));
      }
    }

    final days = settings.daysRemaining;
    if (days > 0 && days <= 60) {
      out.add(Insight(
        message: '$days days until your target deadline.',
        detail: m.total > 0
            ? 'At your current pace you will send about '
                '${_projectedApplications(m, days)} more applications.'
            : '',
        tone: days <= 30 ? InsightTone.warning : InsightTone.neutral,
        kind: InsightKind.milestone,
        priority: 68,
      ));
    }

    return out;
  }

  int _projectedApplications(ApplicationMetrics m, int daysLeft) {
    final weekly = m.thisWeek;
    if (weekly == 0) return 0;
    return math.max(0, ((weekly / 7) * daysLeft).round());
  }

  /// Single headline message for the dashboard hero.
  static String motivationalHeadline({
    required ApplicationMetrics metrics,
    required StreakStats streak,
    required AppSettings settings,
  }) {
    if (metrics.offers > 0) {
      return 'You have an offer. Keep the pipeline warm until it is signed.';
    }
    if (metrics.interviews > 0) {
      return '${metrics.interviews} application'
          '${metrics.interviews == 1 ? ' has' : 's have'} reached an '
          'interview. The strategy is working.';
    }
    if (streak.current >= 7) {
      return '${streak.current} days of unbroken effort. This is how it '
          'compounds.';
    }
    if (metrics.thisWeek >= settings.weeklyApplications) {
      return 'Weekly target met. Every application is one more chance.';
    }
    if (metrics.total == 0) {
      return 'Your campaign starts with a single application. Open Today '
          'and take the first step.';
    }
    return '${metrics.total} applications sent. '
        '${settings.daysRemaining} days to go.';
  }
}

/// Overall mission status shown in the dashboard hero.
enum MissionStatus {
  exceeding('EXCEEDING TARGET', AppColors.success),
  onTrack('ON TRACK', AppColors.success),
  slightlyBehind('SLIGHTLY BEHIND', AppColors.warning),
  atRisk('AT RISK', AppColors.danger);

  const MissionStatus(this.label, this.color);
  final String label;
  final Color color;

  /// Compares this week's output against the expected pace, blended with
  /// consistency so a single slow day does not flip the status.
  static MissionStatus evaluate({
    required ApplicationMetrics metrics,
    required StreakStats streak,
    required AppSettings settings,
  }) {
    final target = settings.weeklyApplications;
    if (target <= 0) return onTrack;

    final elapsed = DateTime.now().weekday;
    final expected = target * elapsed / 7;
    final ratio = expected <= 0 ? 1.0 : metrics.thisWeek / expected;

    final consistency = streak.monthlyConsistency;
    final blended = ratio * 0.7 + consistency * 0.3;

    if (blended >= 1.15) return exceeding;
    if (blended >= 0.85) return onTrack;
    if (blended >= 0.55) return slightlyBehind;
    return atRisk;
  }
}
