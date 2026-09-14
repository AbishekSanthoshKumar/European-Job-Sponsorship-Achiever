import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/quick_add_sheet.dart';
import 'task_form.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  DateTime _date = dayOf(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).ensurePlanFor(_date);
    });
  }

  bool get _isToday => _date == dayOf(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allTasks = ref.watch(tasksProvider);
    final tasks = allTasks.where((t) => dayOf(t.date) == _date).toList()
      ..sort((a, b) {
        final done = (a.status.isDone ? 1 : 0).compareTo(
          b.status.isDone ? 1 : 0,
        );
        if (done != 0) return done;
        final p = b.priority.weight.compareTo(a.priority.weight);
        if (p != 0) return p;
        return a.category.index.compareTo(b.category.index);
      });

    final log = ref.watch(dayLogsProvider.notifier).forDay(_date);
    final score = ref
        .watch(streakServiceProvider)
        .scoreFor(date: _date, tasks: allTasks, log: log);

    final byCategory = <TaskCategory, List<DailyTask>>{};
    for (final t in tasks) {
      (byCategory[t.category] ??= []).add(t);
    }

    return PageScaffold(
      title: _isToday ? 'Today' : _formatDate(_date),
      subtitle: _dayName(_date),
      actions: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => _changeDay(-1),
          tooltip: 'Previous day',
        ),
        if (!_isToday)
          TextButton(
            onPressed: () => _goTo(dayOf(DateTime.now())),
            child: const Text('Today'),
          ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () => _changeDay(1),
          tooltip: 'Next day',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          onSelected: _onMenu,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'add',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.add_rounded, size: 18),
                title: Text('Add task'),
              ),
            ),
            const PopupMenuItem(
              value: 'regenerate',
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.refresh_rounded, size: 18),
                title: Text('Regenerate plan'),
              ),
            ),
            const PopupMenuDivider(),
            for (final type in DayType.values)
              PopupMenuItem(
                value: 'daytype:${type.id}',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    log.dayType == type
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                  ),
                  title: Text('Mark as ${type.label}'),
                ),
              ),
          ],
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DaySummary(
            tasks: tasks,
            score: score.score,
            dayType: log.dayType,
            byCategory: byCategory,
          ),
          const SizedBox(height: Insets.lg),

          if (tasks.isEmpty)
            AppCard(
              child: EmptyState(
                icon: Icons.checklist_rounded,
                title: 'No tasks for this day',
                message:
                    'Generate a plan from your weekly targets, or add a task '
                    'manually.',
                action: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          ref.read(tasksProvider.notifier).regenerate(_date),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text('Generate plan'),
                    ),
                    const SizedBox(width: Insets.md),
                    OutlinedButton(
                      onPressed: () => showTaskForm(context, date: _date),
                      child: const Text('Add task'),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final entry in byCategory.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.lg),
                child: _CategoryGroup(
                  category: entry.key,
                  tasks: entry.value,
                  onComplete: _completeTask,
                ),
              ),

          if (tasks.isNotEmpty) ...[
            const SizedBox(height: Insets.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => showTaskForm(context, date: _date),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add task'),
              ),
            ),
          ],

          if (log.dayType.isExcused) ...[
            const SizedBox(height: Insets.lg),
            AppCard(
              borderColor: AppColors.info.withValues(alpha: 0.4),
              background: AppColors.info.withValues(alpha: 0.06),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Text(
                      'Marked as ${log.dayType.label}. This day will not '
                      'break your streak.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _changeDay(int delta) => _goTo(_date.add(Duration(days: delta)));

  void _goTo(DateTime date) {
    setState(() => _date = dayOf(date));
    ref.read(tasksProvider.notifier).ensurePlanFor(_date);
  }

  Future<void> _onMenu(String value) async {
    if (value == 'add') {
      await showTaskForm(context, date: _date);
      return;
    }
    if (value == 'regenerate') {
      await ref.read(tasksProvider.notifier).regenerate(_date);
      if (mounted) showToast(context, 'Plan regenerated');
      return;
    }
    if (value.startsWith('daytype:')) {
      final id = value.substring('daytype:'.length);
      final type = DayType.fromId(id);
      await ref.read(dayLogsProvider.notifier).setDayType(_date, type);
      if (mounted) showToast(context, 'Marked as ${type.label}');
    }
  }

  Future<void> _completeTask(DailyTask task) async {
    // quantified tasks open the log sheet so the work is recorded
    final log = await showDialog<List<String>>(
      context: context,
      builder: (_) => _CompletionDialog(task: task),
    );
    if (log == null) return;
    await ref.read(tasksProvider.notifier).complete(task, log: log);
    if (mounted) showToast(context, 'Completed: ${task.title}');
  }

  static String _formatDate(DateTime d) =>
      '${d.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.month - 1]}';

  static String _dayName(DateTime d) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[d.weekday - 1];
  }
}

// ---------------------------------------------------------------------------

class _DaySummary extends ConsumerWidget {
  const _DaySummary({
    required this.tasks,
    required this.score,
    required this.dayType,
    required this.byCategory,
  });

  final List<DailyTask> tasks;
  final double score;
  final DayType dayType;
  final Map<TaskCategory, List<DailyTask>> byCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final done = tasks.where((t) => t.status.isDone).length;
    final minutes = tasks.fold<int>(0, (sum, t) => sum + t.estimatedMinutes);

    final segments = [
      for (final entry in byCategory.entries)
        RingSegment(
          weight: settings.dailyScoreWeights.weightFor(entry.key),
          progress:
              entry.value
                  .map((t) => t.progress)
                  .fold<double>(0, (a, b) => a + b) /
              entry.value.length,
          color: entry.key.color,
        ),
    ];

    return AppCard(
      child: Row(
        children: [
          if (tasks.isEmpty)
            ProgressRing(
              progress: 0,
              size: 92,
              strokeWidth: 8,
              centerTop: '0',
              centerBottom: 'SCORE',
            )
          else
            SegmentedRing(
              segments: segments,
              size: 92,
              strokeWidth: 8,
              centerTop: '${score.round()}',
              centerBottom: 'SCORE',
            ),
          const SizedBox(width: Insets.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$done of ${tasks.length} complete',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  tasks.isEmpty
                      ? 'No plan for this day'
                      : '${_formatMinutes(minutes)} of planned work · '
                            'streak threshold '
                            '${(settings.streakThreshold * 100).round()}%',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: Insets.md),
                Wrap(
                  spacing: Insets.sm,
                  runSpacing: Insets.sm,
                  children: [
                    for (final entry in byCategory.entries)
                      StatusChip(
                        label:
                            '${entry.key.label} '
                            '${entry.value.where((t) => t.status.isDone).length}'
                            '/${entry.value.length}',
                        color: entry.key.color,
                        dense: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

// ---------------------------------------------------------------------------

class _CategoryGroup extends ConsumerWidget {
  const _CategoryGroup({
    required this.category,
    required this.tasks,
    required this.onComplete,
  });

  final TaskCategory category;
  final List<DailyTask> tasks;
  final ValueChanged<DailyTask> onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final done = tasks.where((t) => t.status.isDone).length;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.lg,
              Insets.md,
              Insets.lg,
              Insets.sm,
            ),
            child: Row(
              children: [
                Icon(category.icon, size: 15, color: category.color),
                const SizedBox(width: Insets.sm),
                Text(
                  category.label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 1,
                    color: category.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '$done/${tasks.length}',
                  style: AppTheme.mono(
                    size: 11,
                    weight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.colorScheme.outline),
            _TaskRow(task: tasks[i], onComplete: onComplete),
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task, required this.onComplete});

  final DailyTask task;
  final ValueChanged<DailyTask> onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(tasksProvider.notifier);
    final isDone = task.status.isDone;
    final skipped = task.status == TaskStatus.skipped;

    return InkWell(
      onTap: () => showTaskForm(context, existing: task),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.lg,
          vertical: Insets.md,
        ),
        child: Row(
          children: [
            // checkbox
            InkWell(
              onTap: () {
                if (isDone) {
                  notifier.setStatus(task, TaskStatus.notStarted);
                } else {
                  onComplete(task);
                }
              },
              borderRadius: BorderRadius.circular(Corners.pill),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  isDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 21,
                  color: isDone
                      ? AppColors.success
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                ),
              ),
            ),
            const SizedBox(width: Insets.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: isDone || skipped
                          ? TextDecoration.lineThrough
                          : null,
                      color: isDone || skipped
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      fontWeight:
                          task.priority == TaskPriority.critical && !isDone
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                  if (task.notes.isNotEmpty && !isDone) ...[
                    const SizedBox(height: 3),
                    Text(
                      task.notes.split('\n').first,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (task.completionLog.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    for (final line in task.completionLog.take(4))
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Row(
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                line,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // partial progress stepper for quantified tasks
            if (task.isCountable && !isDone) ...[
              const SizedBox(width: Insets.sm),
              _CountStepper(task: task),
            ],

            if (task.estimatedMinutes > 0 && !task.isCountable) ...[
              const SizedBox(width: Insets.sm),
              Text(
                '${task.estimatedMinutes}m',
                style: AppTheme.mono(
                  size: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            if (task.priority == TaskPriority.critical && !isDone) ...[
              const SizedBox(width: Insets.sm),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountStepper extends ConsumerWidget {
  const _CountStepper({required this.task});

  final DailyTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(tasksProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Corners.sm),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: task.completedCount > 0
                ? () => notifier.increment(task, -1)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Icons.remove_rounded,
                size: 13,
                color: task.completedCount > 0
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          Text(
            '${task.completedCount}/${task.targetCount}',
            style: AppTheme.mono(
              size: 11,
              weight: FontWeight.w700,
              color: task.completedCount > 0
                  ? task.category.color
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          InkWell(
            onTap: () => notifier.increment(task),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(
                Icons.add_rounded,
                size: 13,
                color: task.category.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Asks "what did you do?" so completing a task leaves a real record.
class _CompletionDialog extends StatefulWidget {
  const _CompletionDialog({required this.task});

  final DailyTask task;

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  final _controller = TextEditingController();
  final _lines = <String>[];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _lines.add(text);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.task.title, style: theme.textTheme.titleMedium),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'What did you do? Optional, but it builds your history.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: Insets.md),
            for (final line in _lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(line, style: theme.textTheme.bodySmall),
                    ),
                    InkWell(
                      onTap: () => setState(() => _lines.remove(line)),
                      child: Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: Insets.sm),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _hintFor(widget.task.category),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  onPressed: _add,
                ),
              ),
              onSubmitted: (_) => _add(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // fold any un-added text into the log
            final pending = _controller.text.trim();
            Navigator.of(
              context,
            ).pop([..._lines, if (pending.isNotEmpty) pending]);
          },
          child: const Text('Complete'),
        ),
      ],
    );
  }

  static String _hintFor(TaskCategory category) => switch (category) {
    TaskCategory.applications => 'e.g. Backend Engineer at Adyen (Amsterdam)',
    TaskCategory.networking => 'e.g. Messaged Sarah at Darwin Recruitment',
    TaskCategory.followUps => 'e.g. Followed up with SAP recruiter',
    TaskCategory.preparation => 'e.g. 30 min graphs — BFS/DFS',
    TaskCategory.research => 'e.g. Researched Celonis and Personio',
    TaskCategory.agencies => 'e.g. Registered with Huxley NL',
    TaskCategory.portfolio => 'e.g. Finished auth flow',
    TaskCategory.admin => 'What did you get done?',
  };
}
