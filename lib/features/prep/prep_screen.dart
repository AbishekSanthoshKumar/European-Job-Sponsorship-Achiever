import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/metrics_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/quick_add_sheet.dart';

class PrepScreen extends ConsumerWidget {
  const PrepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final sessions = ref.watch(prepProvider);
    final notifier = ref.read(prepProvider.notifier);

    final weekStart = startOfWeek(DateTime.now());
    final weekMinutes = notifier.minutesByCategory(from: weekStart);
    final totalWeek = weekMinutes.values.fold(0, (a, b) => a + b);
    final allTime = notifier.minutesByCategory();

    final recent = [...sessions]
      ..sort((a, b) => b.date.compareTo(a.date));

    return PageScaffold(
      title: 'Interview prep',
      subtitle: '${_fmt(totalWeek)} this week of '
          '${_fmt(settings.weeklyPrepMinutes)} target',
      actions: [
        FilledButton.icon(
          onPressed: () => showFormSheet<void>(
            context,
            (_) => const _LogPrepForm(),
            maxWidth: 480,
          ),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(isMobile(context) ? '' : 'Log session'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('This week'),
                LabeledProgress(
                  label: 'Total preparation',
                  value: totalWeek / 60,
                  target: settings.weeklyPrepMinutes / 60,
                  unit: 'h',
                  color: TaskCategory.preparation.color,
                ),
                const SizedBox(height: Insets.lg),
                for (final c in PrepCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.md),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: Insets.md),
                        Expanded(
                          child: Text(c.label,
                              style: theme.textTheme.bodyMedium),
                        ),
                        Text(
                          _fmt(weekMinutes[c] ?? 0),
                          style: AppTheme.mono(
                            size: 12,
                            weight: FontWeight.w600,
                            color: (weekMinutes[c] ?? 0) > 0
                                ? c.color
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: Insets.md),
                        SizedBox(
                          width: 64,
                          child: Text(
                            'all: ${_fmt(allTime[c] ?? 0)}',
                            textAlign: TextAlign.end,
                            style: AppTheme.mono(
                              size: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          // topic reference per category
          const SectionHeader('Topics'),
          for (final c in PrepCategory.values)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: AppCard(
                padding: const EdgeInsets.all(Insets.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: c.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: Insets.sm),
                        Text(c.label, style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: Insets.sm),
                    Wrap(
                      spacing: Insets.sm,
                      runSpacing: Insets.xs,
                      children: [
                        for (final t in c.topics)
                          StatusChip(
                            label: t,
                            color: theme.colorScheme.onSurfaceVariant,
                            dense: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (recent.isNotEmpty) ...[
            const SizedBox(height: Insets.lg),
            SectionHeader('Recent sessions (${recent.length})'),
            for (final s in recent.take(20))
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.category.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.topic.isEmpty ? s.category.label : s.topic,
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '${s.category.label} · '
                              '${s.date.day}/${s.date.month}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _fmt(s.minutes),
                        style: AppTheme.mono(
                          size: 12,
                          weight: FontWeight.w600,
                          color: s.category.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  static String _fmt(int minutes) {
    if (minutes == 0) return '0m';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _LogPrepForm extends ConsumerStatefulWidget {
  const _LogPrepForm();

  @override
  ConsumerState<_LogPrepForm> createState() => _LogPrepFormState();
}

class _LogPrepFormState extends ConsumerState<_LogPrepForm> {
  PrepCategory _category = PrepCategory.dsa;
  String _topic = '';
  int _minutes = 30;
  DateTime _date = DateTime.now();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: 'Log preparation',
      submitLabel: 'Log session',
      onSubmit: () async {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        await ref.read(prepProvider.notifier).log(PrepSession(
              id: uuid.v4(),
              category: _category,
              date: _date,
              minutes: _minutes,
              topic: _topic,
              notes: _notes.text.trim(),
            ));
        navigator.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('Logged $_minutes minutes of '
                  '${_category.label}')));
      },
      children: [
        LabeledField(
          label: 'Category',
          child: ChipSelector<PrepCategory>(
            values: PrepCategory.values,
            selected: _category,
            labelBuilder: (c) => c.label,
            colorBuilder: (c) => c.color,
            onSelected: (c) => setState(() {
              _category = c;
              _topic = '';
            }),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Topic',
          child: Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final t in _category.topics)
                InkWell(
                  onTap: () =>
                      setState(() => _topic = _topic == t ? '' : t),
                  borderRadius: BorderRadius.circular(Corners.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.md, vertical: 6),
                    decoration: BoxDecoration(
                      color: _topic == t
                          ? _category.color.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(Corners.sm),
                      border: Border.all(
                        color: _topic == t
                            ? _category.color
                            : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: Text(
                      t,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(
                            color: _topic == t
                                ? _category.color
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Minutes',
          child: Row(
            children: [
              for (final m in const [15, 30, 45, 60, 90, 120])
                Padding(
                  padding: const EdgeInsets.only(right: Insets.sm),
                  child: InkWell(
                    onTap: () => setState(() => _minutes = m),
                    borderRadius: BorderRadius.circular(Corners.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Insets.md, vertical: 7),
                      decoration: BoxDecoration(
                        color: _minutes == m
                            ? _category.color.withValues(alpha: 0.15)
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainer,
                        borderRadius: BorderRadius.circular(Corners.sm),
                        border: Border.all(
                          color: _minutes == m
                              ? _category.color
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        '$m',
                        style: AppTheme.mono(
                          size: 12,
                          weight: FontWeight.w700,
                          color: _minutes == m
                              ? _category.color
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Date',
          child: DateField(
            value: _date,
            clearable: false,
            onChanged: (d) => setState(() => _date = d ?? _date),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Notes',
          child: TextField(controller: _notes, maxLines: 2),
        ),
      ],
    );
  }
}
