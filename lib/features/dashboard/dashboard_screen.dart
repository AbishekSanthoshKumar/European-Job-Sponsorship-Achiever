import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/domain/settings.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/insights_engine.dart';
import '../../core/services/metrics_service.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/quick_add_sheet.dart';
import '../applications/application_form.dart';
import '../companies/company_form.dart';
import '../interviews/interview_form.dart';
import '../networking/contact_form.dart';
import '../opportunities/opportunity_form.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // make sure today's plan exists before the first frame settles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).ensurePlanFor(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final metrics = ref.watch(metricsProvider);
    final streak = ref.watch(streakStatsProvider);
    final status = ref.watch(missionStatusProvider);
    final wide = !isMobile(context);

    return PageScaffold(
      title: 'Mission Control',
      subtitle: settings.primaryGoal,
      actions: [
        if (wide)
          OutlinedButton.icon(
            onPressed: () => showQuickAddSheet(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Quick add'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroPanel(status: status, settings: settings, metrics: metrics),
          const SizedBox(height: Insets.lg),

          // today + streak
          if (wide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(flex: 3, child: _TodayPanel()),
                  const SizedBox(width: Insets.lg),
                  Expanded(flex: 2, child: _StreakPanel(streak: streak)),
                ],
              ),
            )
          else ...[
            const _TodayPanel(),
            const SizedBox(height: Insets.lg),
            _StreakPanel(streak: streak),
          ],

          const SizedBox(height: Insets.lg),
          const _QuickActions(),
          const SizedBox(height: Insets.lg),

          if (wide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  Expanded(child: _UrgentPanel()),
                  SizedBox(width: Insets.lg),
                  Expanded(child: _InsightsPanel()),
                ],
              ),
            )
          else ...[
            const _UrgentPanel(),
            const SizedBox(height: Insets.lg),
            const _InsightsPanel(),
          ],

          const SizedBox(height: Insets.lg),
          const _PipelineSnapshot(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.status,
    required this.settings,
    required this.metrics,
  });

  final MissionStatus status;
  final AppSettings settings;
  final ApplicationMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = isMobile(context);
    final days = settings.daysRemaining;

    return AppCard(
      padding: EdgeInsets.all(mobile ? Insets.lg : Insets.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Insets.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(Corners.sm),
                  border:
                      Border.all(color: status.color.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: status.color,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!mobile)
                Text(
                  'Target: ${_monthYear(settings.targetDeadline)}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: Insets.lg),

          Text(
            'EUROPEAN DREAM',
            style: (mobile
                    ? theme.textTheme.displayMedium
                    : theme.textTheme.displayLarge)
                ?.copyWith(letterSpacing: -1.5),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            settings.primaryGoal,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.xl),

          Wrap(
            spacing: Insets.xxl,
            runSpacing: Insets.lg,
            children: [
              _HeroStat(
                value: '$days',
                label: 'DAYS REMAINING',
                color: days < 90 ? AppColors.warning : null,
              ),
              _HeroStat(
                value: '${metrics.total}',
                label: 'APPLICATIONS SENT',
              ),
              _HeroStat(
                value: '${metrics.responses}',
                label: 'RESPONSES',
                color: metrics.responses > 0 ? AppColors.success : null,
              ),
              _HeroStat(
                value: '${metrics.interviews}',
                label: 'INTERVIEWS',
                color: metrics.interviews > 0 ? AppColors.accent : null,
              ),
              if (metrics.offers > 0)
                _HeroStat(
                  value: '${metrics.offers}',
                  label: 'OFFERS',
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _monthYear(DateTime d) =>
      '${const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][d.month - 1]} ${d.year}';
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTheme.mono(
            size: 28,
            weight: FontWeight.w700,
            color: color ?? theme.colorScheme.onSurface,
            letterSpacing: -1,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Today
// ---------------------------------------------------------------------------

class _TodayPanel extends ConsumerWidget {
  const _TodayPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref.watch(todayTasksProvider);
    final score = ref.watch(todayScoreProvider);
    final settings = ref.watch(settingsProvider);
    final metrics = ref.watch(metricsProvider);

    final done = tasks.where((t) => t.status.isDone).length;

    // one ring segment per category present today
    final byCategory = <TaskCategory, List<DailyTask>>{};
    for (final t in tasks) {
      (byCategory[t.category] ??= []).add(t);
    }
    final segments = [
      for (final entry in byCategory.entries)
        RingSegment(
          weight: settings.dailyScoreWeights.weightFor(entry.key),
          progress: entry.value
                  .map((t) => t.progress)
                  .fold<double>(0, (a, b) => a + b) /
              entry.value.length,
          color: entry.key.color,
        ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            "Today's mission",
            icon: Icons.today_rounded,
            action: TextButton(
              onPressed: () => context.go('/today'),
              child: const Text('Open'),
            ),
          ),
          if (tasks.isEmpty)
            const EmptyState(
              icon: Icons.checklist_rounded,
              title: 'No plan yet',
              message: 'Your daily plan generates from your weekly targets.',
              compact: true,
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SegmentedRing(
                  segments: segments,
                  size: 104,
                  strokeWidth: 9,
                  centerTop: '${score.score.round()}',
                  centerBottom: 'SCORE',
                ),
                const SizedBox(width: Insets.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$done / ${tasks.length} tasks complete',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: Insets.md),
                      _MiniProgress(
                        label: 'Applications',
                        value: metrics.today,
                        target: settings.dailyApplications,
                        color: TaskCategory.applications.color,
                      ),
                      for (final entry in byCategory.entries.take(3))
                        Padding(
                          padding: const EdgeInsets.only(top: Insets.sm),
                          child: _MiniProgress(
                            label: entry.key.label,
                            value: entry.value
                                .where((t) => t.status.isDone)
                                .length,
                            target: entry.value.length,
                            color: entry.key.color,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
  });

  final String label;
  final int value;
  final int target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LabeledProgress(
      label: label,
      value: value,
      target: target,
      color: color,
      compact: true,
    );
  }
}

// ---------------------------------------------------------------------------
// Streak
// ---------------------------------------------------------------------------

class _StreakPanel extends StatelessWidget {
  const _StreakPanel({required this.streak});

  final StreakStats streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = streak.current;
    final best = streak.best;
    final consistency = streak.monthlyConsistency;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Consistency',
              icon: Icons.local_fire_department_rounded),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                current > 0 ? '🔥' : '💤',
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$current day${current == 1 ? '' : 's'}',
                      style: AppTheme.mono(
                        size: 24,
                        weight: FontWeight.w700,
                        color: current > 0
                            ? AppColors.accent
                            : theme.colorScheme.onSurfaceVariant,
                        letterSpacing: -0.8,
                      ),
                    ),
                    Text('Current streak',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.lg),
          Row(
            children: [
              Expanded(
                child: _StreakStat(
                  label: 'Best',
                  value: '$best day${best == 1 ? '' : 's'}',
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: theme.colorScheme.outline,
              ),
              Expanded(
                child: _StreakStat(
                  label: 'This month',
                  value: '${(consistency * 100).round()}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakStat extends StatelessWidget {
  const _StreakStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.mono(
            size: 14,
            weight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = <(String, IconData, Color, void Function(BuildContext))>[
      ('Application', Icons.send_rounded, TaskCategory.applications.color,
          showApplicationForm),
      ('Opportunity', Icons.bookmark_add_rounded, TaskCategory.research.color,
          showOpportunityForm),
      ('Contact', Icons.person_add_rounded, TaskCategory.networking.color,
          showContactForm),
      ('Company', Icons.domain_add_rounded, TaskCategory.agencies.color,
          showCompanyForm),
      ('Interview', Icons.event_rounded, TaskCategory.preparation.color,
          showInterviewForm),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Quick actions'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final (label, icon, color, action) in actions)
                Padding(
                  padding: const EdgeInsets.only(right: Insets.sm),
                  child: _QuickActionButton(
                    label: label,
                    icon: icon,
                    color: color,
                    onTap: () => action(context),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Corners.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Insets.md, vertical: Insets.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Corners.md),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 13, color: color),
              const SizedBox(width: 5),
              Icon(icon, size: 14, color: color),
              const SizedBox(width: Insets.sm),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Urgent items
// ---------------------------------------------------------------------------

class _UrgentPanel extends ConsumerWidget {
  const _UrgentPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buckets = ref.watch(followUpBucketsProvider);
    final interviews = ref.watch(upcomingInterviewsProvider);
    final metrics = ref.watch(metricsProvider);

    final items = <_UrgentItem>[];

    for (final f in buckets.overdue.take(3)) {
      items.add(_UrgentItem(
        color: AppColors.danger,
        title: f.title,
        detail:
            '${f.daysUntilDue.abs()} day${f.daysUntilDue.abs() == 1 ? '' : 's'} overdue',
        route: '/followups',
      ));
    }
    for (final f in buckets.today.take(2)) {
      items.add(_UrgentItem(
        color: AppColors.warning,
        title: f.title,
        detail: 'Due today',
        route: '/followups',
      ));
    }
    for (final i in interviews.where((i) => i.daysUntil <= 7).take(2)) {
      items.add(_UrgentItem(
        color: AppColors.accent,
        title: '${i.stage.label} · ${i.companyName}',
        detail: i.daysUntil == 0
            ? 'Today'
            : i.daysUntil == 1
                ? 'Tomorrow'
                : 'In ${i.daysUntil} days',
        route: '/interviews',
      ));
    }
    for (final a in metrics.stale.take(2)) {
      items.add(_UrgentItem(
        color: AppColors.danger,
        title: '${a.jobTitle} · ${a.companyName}',
        detail: 'Applied ${a.daysSinceApplied} days ago, no response',
        route: '/applications',
      ));
    }
    for (final a in metrics.needingFollowUp.take(2)) {
      items.add(_UrgentItem(
        color: AppColors.warning,
        title: '${a.jobTitle} · ${a.companyName}',
        detail: 'Applied ${a.daysSinceApplied} days ago',
        route: '/applications',
      ));
    }

    final inboxCount = ref
        .watch(opportunitiesProvider)
        .where((o) => o.status == OpportunityStatus.inbox)
        .length;
    if (inboxCount > 0) {
      items.add(_UrgentItem(
        color: AppColors.info,
        title: '$inboxCount saved opportunit'
            '${inboxCount == 1 ? 'y' : 'ies'} to process',
        detail: 'In your inbox',
        route: '/opportunities',
      ));
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Needs attention',
            icon: Icons.priority_high_rounded,
            action: items.isEmpty
                ? null
                : Text(
                    '${items.length}',
                    style: AppTheme.mono(
                      size: 12,
                      weight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
          ),
          if (items.isEmpty)
            EmptyState(
              icon: Icons.check_circle_outline_rounded,
              title: 'Nothing urgent',
              message: metrics.total == 0
                  ? 'Log your first application to start the pipeline.'
                  : 'No overdue follow-ups or stale applications.',
              compact: true,
              action: metrics.total == 0
                  ? FilledButton(
                      onPressed: () => showApplicationForm(context),
                      child: const Text('Log first application'),
                    )
                  : null,
            )
          else
            for (final item in items.take(6))
              _UrgentRow(item: item),
        ],
      ),
    );
  }
}

class _UrgentItem {
  const _UrgentItem({
    required this.color,
    required this.title,
    required this.detail,
    required this.route,
  });

  final Color color;
  final String title;
  final String detail;
  final String route;
}

class _UrgentRow extends StatelessWidget {
  const _UrgentRow({required this.item});

  final _UrgentItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(Corners.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: item.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    item.detail,
                    style:
                        theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Insights
// ---------------------------------------------------------------------------

class _InsightsPanel extends ConsumerWidget {
  const _InsightsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insights = ref.watch(insightsProvider);
    final metrics = ref.watch(metricsProvider);
    final streak = ref.watch(streakStatsProvider);
    final settings = ref.watch(settingsProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Insights', icon: Icons.auto_graph_rounded),
          Container(
            padding: const EdgeInsets.all(Insets.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(Corners.md),
            ),
            child: Text(
              InsightsEngine.motivationalHeadline(
                metrics: metrics,
                streak: streak,
                settings: settings,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
          if (insights.isNotEmpty) const SizedBox(height: Insets.md),
          for (final insight in insights.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: _InsightRow(insight: insight),
            ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final route = insight.actionRoute;

    return InkWell(
      onTap: route == null ? null : () => context.go(route),
      borderRadius: BorderRadius.circular(Corners.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(insight.icon, size: 14, color: insight.color),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.message,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (insight.detail.isNotEmpty)
                  Text(
                    insight.detail,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
              ],
            ),
          ),
          if (route != null)
            Icon(Icons.chevron_right_rounded,
                size: 15, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pipeline snapshot
// ---------------------------------------------------------------------------

class _PipelineSnapshot extends ConsumerWidget {
  const _PipelineSnapshot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final metrics = ref.watch(metricsProvider);
    final settings = ref.watch(settingsProvider);

    if (metrics.totalSaved == 0) return const SizedBox.shrink();

    final funnel = metrics.funnel;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Pipeline',
            icon: Icons.filter_alt_rounded,
            action: TextButton(
              onPressed: () => context.go('/analytics'),
              child: const Text('Analytics'),
            ),
          ),
          LayoutBuilder(builder: (context, constraints) {
            return Wrap(
              spacing: Insets.md,
              runSpacing: Insets.md,
              children: [
                for (final step in funnel)
                  SizedBox(
                    width: constraints.maxWidth > 700
                        ? (constraints.maxWidth - Insets.md * 6) / 7
                        : (constraints.maxWidth - Insets.md * 2) / 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${step.count}',
                          style: AppTheme.mono(
                            size: 18,
                            weight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          step.label,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: Insets.lg),
          Row(
            children: [
              Expanded(
                child: LabeledProgress(
                  label: 'This week',
                  value: metrics.thisWeek,
                  target: settings.weeklyApplications,
                  compact: true,
                ),
              ),
              const SizedBox(width: Insets.xl),
              Expanded(
                child: LabeledProgress(
                  label: 'Response rate',
                  value: (metrics.responseRate * 100),
                  target: 100,
                  unit: '%',
                  color: AppColors.success,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
