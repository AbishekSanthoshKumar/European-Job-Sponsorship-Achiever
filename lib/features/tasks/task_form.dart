import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/quick_add_sheet.dart';

Future<void> showTaskForm(
  BuildContext context, {
  DailyTask? existing,
  DateTime? date,
}) {
  return showFormSheet<void>(
    context,
    (_) => _TaskForm(existing: existing, date: date),
    maxWidth: 520,
  );
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({this.existing, this.date});

  final DailyTask? existing;
  final DateTime? date;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _notes = TextEditingController(text: widget.existing?.notes);

  late DateTime _date =
      widget.existing?.date ?? widget.date ?? DateTime.now();
  late TaskCategory _category =
      widget.existing?.category ?? TaskCategory.applications;
  late TaskPriority _priority =
      widget.existing?.priority ?? TaskPriority.normal;
  late int _target = widget.existing?.targetCount ?? 1;
  late int _minutes = widget.existing?.estimatedMinutes ?? 0;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _valid => _title.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return FormSheet(
      title: isEdit ? 'Edit task' : 'Add task',
      submitLabel: isEdit ? 'Save changes' : 'Add task',
      canSubmit: _valid,
      onSubmit: _submit,
      children: [
        LabeledField(
          label: 'Task',
          required: true,
          child: TextField(
            controller: _title,
            autofocus: !isEdit,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'e.g. Research 5 Berlin fintechs'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Category',
          child: ChipSelector<TaskCategory>(
            values: TaskCategory.values,
            selected: _category,
            labelBuilder: (c) => c.label,
            colorBuilder: (c) => c.color,
            onSelected: (c) => setState(() => _category = c),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Priority',
          child: ChipSelector<TaskPriority>(
            values: TaskPriority.values,
            selected: _priority,
            labelBuilder: (p) => p.label,
            colorBuilder: (p) => p.color,
            onSelected: (p) => setState(() => _priority = p),
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
        Row(
          children: [
            Expanded(
              child: LabeledField(
                label: 'Target count',
                hint: 'Above 1 enables partial progress',
                child: _Stepper(
                  value: _target,
                  min: 1,
                  max: 50,
                  onChanged: (v) => setState(() => _target = v),
                ),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: LabeledField(
                label: 'Est. minutes',
                child: _Stepper(
                  value: _minutes,
                  min: 0,
                  max: 480,
                  step: 15,
                  onChanged: (v) => setState(() => _minutes = v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Notes',
          child: TextField(controller: _notes, maxLines: 2),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_valid) return;
    final now = DateTime.now();
    final existing = widget.existing;

    final task = DailyTask(
      id: existing?.id ?? uuid.v4(),
      title: _title.text.trim(),
      date: dayOf(_date),
      category: _category,
      priority: _priority,
      status: existing?.status ?? TaskStatus.notStarted,
      targetCount: _target,
      completedCount: existing?.completedCount ?? 0,
      estimatedMinutes: _minutes,
      actualMinutes: existing?.actualMinutes ?? 0,
      notes: _notes.text.trim(),
      completionLog: existing?.completionLog ?? const [],
      isAutoGenerated: existing?.isAutoGenerated ?? false,
      recurrence: existing?.recurrence ?? '',
      completedAt: existing?.completedAt,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(tasksProvider.notifier).put(task);

    if (!mounted) return;
    Navigator.of(context).pop();
    showToast(context, existing != null ? 'Task updated' : 'Task added');
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(Corners.md),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 16),
            onPressed: value > min
                ? () => onChanged((value - step).clamp(min, max))
                : null,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            '$value',
            style: AppTheme.mono(
              size: 14,
              weight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 16),
            onPressed: value < max
                ? () => onChanged((value + step).clamp(min, max))
                : null,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
