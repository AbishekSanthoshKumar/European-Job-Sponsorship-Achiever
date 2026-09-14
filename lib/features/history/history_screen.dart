import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/streak_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/quick_add_sheet.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String? _group;

  @override
  Widget build(BuildContext context) {
    final activities = ref.watch(activityTimelineProvider);
    final streak = ref.watch(streakStatsProvider);
    final heatmap = ref.watch(heatmapProvider);

    final groups = <String>{for (final a in activities) a.type.group}.toList()
      ..sort();

    final filtered = _group == null
        ? activities
        : activities.where((a) => a.type.group == _group).toList();

    // group by day for the timeline
    final byDay = <DateTime, List<ActivityEvent>>{};
    for (final a in filtered) {
      (byDay[dayOf(a.timestamp)] ??= []).add(a);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return PageScaffold(
      title: 'History',
      subtitle: '${activities.length} recorded actions · '
          '${streak.current} day streak',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeatmapCard(scores: heatmap),
          const SizedBox(height: Insets.lg),

          if (groups.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _GroupPill(
                    label: 'All',
                    active: _group == null,
                    onTap: () => setState(() => _group = null),
                  ),
                  const SizedBox(width: Insets.sm),
                  for (final g in groups) ...[
                    _GroupPill(
                      label: g,
                      active: _group == g,
                      onTap: () =>
                          setState(() => _group = _group == g ? null : g),
                    ),
                    const SizedBox(width: Insets.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),
          ],

          if (filtered.isEmpty)
            const EmptyState(
              icon: Icons.history_rounded,
              title: 'Nothing recorded yet',
              message: 'Every application, message, interview and completed '
                  'task lands here automatically.',
            )
          else
            for (final day in days) ...[
              _DayHeader(date: day, count: byDay[day]!.length),
              for (final a in byDay[day]!)
                _ActivityRow(activity: a),
              const SizedBox(height: Insets.lg),
            ],
        ],
      ),
    );
  }
}

class _GroupPill extends StatelessWidget {
  const _GroupPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Corners.sm),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Corners.sm),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date, required this.count});

  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Insets.sm, bottom: Insets.sm),
      child: Row(
        children: [
          Text(
            _label(date),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Container(height: 1, color: theme.colorScheme.outline),
          ),
          const SizedBox(width: Insets.md),
          Text(
            '$count',
            style: AppTheme.mono(
              size: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _label(DateTime d) {
    final today = dayOf(DateTime.now());
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day} ${const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][d.month - 1]} ${d.year}';
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final ActivityEvent activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(activity.type.icon,
                size: 14, color: activity.type.color),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: theme.textTheme.bodyMedium),
                if (activity.subtitle.isNotEmpty)
                  Text(
                    activity.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
              ],
            ),
          ),
          Text(
            '${activity.timestamp.hour.toString().padLeft(2, '0')}:'
            '${activity.timestamp.minute.toString().padLeft(2, '0')}',
            style: AppTheme.mono(
              size: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// GitHub-style consistency heatmap.
class _HeatmapCard extends ConsumerWidget {
  const _HeatmapCard({required this.scores});

  final List<DailyScore> scores;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final ramp = dark ? AppColors.heat : AppColors.heatLight;

    // build week columns, Monday at the top
    final weeks = <List<DailyScore?>>[];
    var current = List<DailyScore?>.filled(7, null);
    for (final s in scores) {
      final weekday = s.date.weekday - 1; // 0 = Monday
      current[weekday] = s;
      if (weekday == 6) {
        weeks.add(current);
        current = List<DailyScore?>.filled(7, null);
      }
    }
    if (current.any((e) => e != null)) weeks.add(current);

    final activeDays = scores.where((s) => s.hasActivity).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Consistency',
            subtitle: '$activeDays active days in the last '
                '${scores.length} days',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final week in weeks)
                  Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: Column(
                      children: [
                        for (final day in week)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: _HeatCell(score: day, ramp: ramp),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: [
              Text('Less',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
              const SizedBox(width: 5),
              for (final c in ramp)
                Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              const SizedBox(width: 2),
              Text('More',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatCell extends ConsumerWidget {
  const _HeatCell({required this.score, required this.ramp});

  final DailyScore? score;
  final List<Color> ramp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (score == null) {
      return const SizedBox(width: 11, height: 11);
    }
    final s = score!;

    return Tooltip(
      message: '${s.date.day}/${s.date.month} · '
          '${s.score.round()}% · ${s.tasksCompleted}/${s.tasksTotal} tasks'
          '${s.dayType.isExcused ? ' · ${s.dayType.label}' : ''}',
      child: InkWell(
        onTap: () => _showDay(context, ref, s),
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: s.dayType.isExcused && s.intensity == 0
                ? theme.colorScheme.surfaceContainerHigh
                : ramp[s.intensity],
            borderRadius: BorderRadius.circular(2),
            border: s.dayType.isExcused
                ? Border.all(color: AppColors.info, width: 1)
                : null,
          ),
        ),
      ),
    );
  }

  void _showDay(BuildContext context, WidgetRef ref, DailyScore s) {
    showFormSheet<void>(
      context,
      (_) => _DayDetail(date: s.date),
      maxWidth: 480,
    );
  }
}

class _DayDetail extends ConsumerWidget {
  const _DayDetail({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tasks = ref
        .watch(tasksProvider)
        .where((t) => dayOf(t.date) == date)
        .toList();
    final activities = ref
        .watch(activityTimelineProvider)
        .where((a) => dayOf(a.timestamp) == date)
        .toList();
    final log = ref.watch(dayLogsProvider.notifier).forDay(date);
    final score = ref.watch(streakServiceProvider).scoreFor(
          date: date,
          tasks: ref.watch(tasksProvider),
          log: log,
        );

    return Padding(
      padding: const EdgeInsets.all(Insets.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${date.day} ${const [
                        'January', 'February', 'March', 'April', 'May',
                        'June', 'July', 'August', 'September', 'October',
                        'November', 'December'
                      ][date.month - 1]} ${date.year}',
                      style: theme.textTheme.headlineMedium,
                    ),
                    Text(
                      'Daily score ${score.score.round()}%'
                      '${log.dayType.isExcused ? ' · ${log.dayType.label}' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: Insets.lg),

          if (tasks.isEmpty && activities.isEmpty)
            Text('Nothing recorded on this day.',
                style: theme.textTheme.bodySmall)
          else ...[
            if (activities.isNotEmpty) ...[
              const SectionHeader('What you accomplished'),
              for (final a in activities)
                Padding(
                  padding: const EdgeInsets.only(bottom: Insets.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(a.type.icon, size: 13, color: a.type.color),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: Text(a.title,
                            style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: Insets.md),
            ],
            if (tasks.isNotEmpty) ...[
              SectionHeader(
                'Tasks (${tasks.where((t) => t.status.isDone).length}'
                '/${tasks.length})',
              ),
              for (final t in tasks)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Icon(
                        t.status.isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: t.status.isDone
                            ? AppColors.success
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: Text(
                          t.title,
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: t.status.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ],
      ),
    );
  }
}
