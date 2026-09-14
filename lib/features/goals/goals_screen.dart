import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/metrics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/quick_add_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final metrics = ref.watch(metricsProvider);
    final tasks = ref.watch(tasksProvider);
    final prep = ref.watch(prepProvider);
    final contacts = ref.watch(contactsProvider);
    final followUps = ref.watch(followUpsProvider);
    final streak = ref.watch(streakStatsProvider);

    final weekStart = startOfWeek(DateTime.now());
    final monthStart = startOfMonth(DateTime.now());

    int completedThisWeek(String recurrence) => tasks
        .where((t) =>
            t.recurrence == recurrence &&
            !dayOf(t.date).isBefore(weekStart))
        .fold(0, (sum, t) => sum + t.completedCount);

    final prepMinutesWeek = prep
        .where((p) => !dayOf(p.date).isBefore(weekStart))
        .fold(0, (sum, p) => sum + p.minutes);
    final prepMinutesMonth = prep
        .where((p) => !dayOf(p.date).isBefore(monthStart))
        .fold(0, (sum, p) => sum + p.minutes);

    final contactsThisWeek = contacts
        .where((c) =>
            c.dateContacted != null &&
            !dayOf(c.dateContacted!).isBefore(weekStart))
        .length;
    final followUpsThisWeek = followUps
        .where((f) =>
            f.completedAt != null &&
            !dayOf(f.completedAt!).isBefore(weekStart))
        .length;

    return PageScaffold(
      title: 'Goals & targets',
      subtitle: '${settings.daysRemaining} days until '
          '${_monthYear(settings.targetDeadline)}',
      actions: [
        TextButton.icon(
          onPressed: () => showFormSheet<void>(
            context,
            (_) => const _TargetsEditor(),
            maxWidth: 540,
          ),
          icon: const Icon(Icons.tune_rounded, size: 16),
          label: const Text('Edit targets'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // primary goal
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Primary goal',
                    icon: Icons.flag_rounded),
                Text(settings.primaryGoal,
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: Insets.md),
                Row(
                  children: [
                    Expanded(
                      child: _GoalStat(
                        label: 'Days remaining',
                        value: '${settings.daysRemaining}',
                        color: settings.daysRemaining < 90
                            ? AppColors.warning
                            : null,
                      ),
                    ),
                    Expanded(
                      child: _GoalStat(
                        label: 'Applications',
                        value: '${metrics.total}',
                      ),
                    ),
                    Expanded(
                      child: _GoalStat(
                        label: 'Interviews',
                        value: '${metrics.interviews}',
                        color: metrics.interviews > 0
                            ? AppColors.accent
                            : null,
                      ),
                    ),
                    Expanded(
                      child: _GoalStat(
                        label: 'Offers',
                        value: '${metrics.offers}',
                        color:
                            metrics.offers > 0 ? AppColors.success : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          // weekly
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('This week',
                    icon: Icons.calendar_view_week_rounded),
                LabeledProgress(
                  label: 'Applications',
                  value: metrics.thisWeek,
                  target: settings.weeklyApplications,
                  color: TaskCategory.applications.color,
                ),
                const SizedBox(height: Insets.md),
                LabeledProgress(
                  label: 'Recruiter messages',
                  value: completedThisWeek('recruiter_messages'),
                  target: settings.weeklyRecruiterMessages,
                  color: TaskCategory.networking.color,
                ),
                const SizedBox(height: Insets.md),
                LabeledProgress(
                  label: 'LinkedIn connections',
                  value: completedThisWeek('connections'),
                  target: settings.weeklyConnections,
                  color: TaskCategory.networking.color,
                ),
                const SizedBox(height: Insets.md),
                LabeledProgress(
                  label: 'Follow-ups completed',
                  value: followUpsThisWeek,
                  target: settings.weeklyFollowUps,
                  color: TaskCategory.followUps.color,
                ),
                const SizedBox(height: Insets.md),
                LabeledProgress(
                  label: 'Interview preparation',
                  value: prepMinutesWeek / 60,
                  target: settings.weeklyPrepMinutes / 60,
                  unit: 'h',
                  color: TaskCategory.preparation.color,
                ),
                const SizedBox(height: Insets.md),
                LabeledProgress(
                  label: 'Companies researched',
                  value: completedThisWeek('research'),
                  target: settings.weeklyCompanyResearch,
                  color: TaskCategory.research.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          // monthly rollup
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader('This month',
                    icon: Icons.calendar_month_rounded,
                    subtitle: _monthYear(DateTime.now())),
                LabeledProgress(
                  label: 'Applications',
                  value: metrics.thisMonth,
                  // weekly target scaled to the month
                  target: (settings.weeklyApplications * 4.35).round(),
                  color: TaskCategory.applications.color,
                ),
                const SizedBox(height: Insets.md),
                LabeledProgress(
                  label: 'New contacts',
                  value: contactsThisWeek,
                  target: settings.weeklyRecruiterMessages,
                  color: TaskCategory.networking.color,
                ),
                const SizedBox(height: Insets.md),
                LabeledProgress(
                  label: 'Interview preparation',
                  value: prepMinutesMonth / 60,
                  target: (settings.weeklyPrepMinutes * 4.35) / 60,
                  unit: 'h',
                  color: TaskCategory.preparation.color,
                ),
                const SizedBox(height: Insets.md),
                LabeledProgress(
                  label: 'Consistency',
                  value: (streak.monthlyConsistency * 100).round(),
                  target: 100,
                  unit: '%',
                  color: AppColors.accent,
                ),
              ],
            ),
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

class _GoalStat extends StatelessWidget {
  const _GoalStat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTheme.mono(
            size: 20,
            weight: FontWeight.w700,
            color: color ?? theme.colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Editor for the weekly targets that drive the daily plan generator.
class _TargetsEditor extends ConsumerStatefulWidget {
  const _TargetsEditor();

  @override
  ConsumerState<_TargetsEditor> createState() => _TargetsEditorState();
}

class _TargetsEditorState extends ConsumerState<_TargetsEditor> {
  late int _applications;
  late int _recruiters;
  late int _connections;
  late int _followUps;
  late int _prepMinutes;
  late int _research;
  late int _hiringManagers;
  late int _agencies;
  late PlanMode _planMode;
  late double _streakThreshold;
  late DateTime _deadline;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _applications = s.weeklyApplications;
    _recruiters = s.weeklyRecruiterMessages;
    _connections = s.weeklyConnections;
    _followUps = s.weeklyFollowUps;
    _prepMinutes = s.weeklyPrepMinutes;
    _research = s.weeklyCompanyResearch;
    _hiringManagers = s.weeklyHiringManagerMessages;
    _agencies = s.weeklyAgencyRegistrations;
    _planMode = s.planMode;
    _streakThreshold = s.streakThreshold;
    _deadline = s.targetDeadline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final daily = (_applications / 7).ceil();

    return FormSheet(
      title: 'Weekly targets',
      subtitle: 'These drive your daily plan',
      submitLabel: 'Save targets',
      onSubmit: () async {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        await ref.read(settingsProvider.notifier).patch((s) => s.copyWith(
              weeklyApplications: _applications,
              weeklyRecruiterMessages: _recruiters,
              weeklyConnections: _connections,
              weeklyFollowUps: _followUps,
              weeklyPrepMinutes: _prepMinutes,
              weeklyCompanyResearch: _research,
              weeklyHiringManagerMessages: _hiringManagers,
              weeklyAgencyRegistrations: _agencies,
              planMode: _planMode,
              streakThreshold: _streakThreshold,
              targetDeadline: _deadline,
            ));
        navigator.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(
              content: Text('Targets updated — regenerate today\'s plan '
                  'to apply them')));
      },
      children: [
        LabeledField(
          label: 'Target deadline',
          child: DateField(
            value: _deadline,
            clearable: false,
            firstDate: DateTime.now(),
            onChanged: (d) => setState(() => _deadline = d ?? _deadline),
          ),
        ),
        const SizedBox(height: Insets.lg),

        _NumberRow(
          label: 'Applications',
          value: _applications,
          max: 200,
          step: 5,
          hint: '≈ $daily per day',
          onChanged: (v) => setState(() => _applications = v),
        ),
        _NumberRow(
          label: 'Recruiter messages',
          value: _recruiters,
          max: 100,
          step: 5,
          onChanged: (v) => setState(() => _recruiters = v),
        ),
        _NumberRow(
          label: 'LinkedIn connections',
          value: _connections,
          max: 100,
          step: 5,
          onChanged: (v) => setState(() => _connections = v),
        ),
        _NumberRow(
          label: 'Hiring manager messages',
          value: _hiringManagers,
          max: 30,
          onChanged: (v) => setState(() => _hiringManagers = v),
        ),
        _NumberRow(
          label: 'Follow-ups',
          value: _followUps,
          max: 60,
          step: 2,
          onChanged: (v) => setState(() => _followUps = v),
        ),
        _NumberRow(
          label: 'Companies to research',
          value: _research,
          max: 60,
          step: 2,
          onChanged: (v) => setState(() => _research = v),
        ),
        _NumberRow(
          label: 'Agency registrations',
          value: _agencies,
          max: 30,
          onChanged: (v) => setState(() => _agencies = v),
        ),
        _NumberRow(
          label: 'Prep minutes',
          value: _prepMinutes,
          max: 1200,
          step: 30,
          hint: '${(_prepMinutes / 60).toStringAsFixed(1)} hours per week',
          onChanged: (v) => setState(() => _prepMinutes = v),
        ),

        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Plan mode',
          hint: _planMode.description,
          child: ChipSelector<PlanMode>(
            values: PlanMode.values,
            selected: _planMode,
            labelBuilder: (m) => m.label,
            onSelected: (m) => setState(() => _planMode = m),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Streak threshold',
          hint: 'A day counts toward your streak at '
              '${(_streakThreshold * 100).round()}% of the daily plan',
          child: Slider(
            value: _streakThreshold,
            min: 0.2,
            max: 1.0,
            divisions: 16,
            label: '${(_streakThreshold * 100).round()}%',
            onChanged: (v) => setState(() => _streakThreshold = v),
          ),
        ),
        const SizedBox(height: Insets.sm),
        Text(
          'Changing targets affects newly generated plans. Use '
          '"Regenerate plan" on the Today screen to apply them immediately.',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.max = 100,
    this.step = 1,
    this.hint,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int max;
  final int step;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                if (hint != null)
                  Text(hint!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 10.5)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            onPressed:
                value > 0 ? () => onChanged((value - step).clamp(0, max)) : null,
          ),
          SizedBox(
            width: 44,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTheme.mono(
                size: 14,
                weight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            onPressed: value < max
                ? () => onChanged((value + step).clamp(0, max))
                : null,
          ),
        ],
      ),
    );
  }
}
