import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/quick_add_sheet.dart';

Future<void> showInterviewForm(
  BuildContext context, {
  Interview? existing,
  JobApplication? application,
}) {
  return showFormSheet<void>(
    context,
    (_) => _InterviewForm(existing: existing, application: application),
  );
}

class _InterviewForm extends ConsumerStatefulWidget {
  const _InterviewForm({this.existing, this.application});

  final Interview? existing;
  final JobApplication? application;

  @override
  ConsumerState<_InterviewForm> createState() => _InterviewFormState();
}

class _InterviewFormState extends ConsumerState<_InterviewForm> {
  late final _company = TextEditingController(
    text: widget.existing?.companyName ?? widget.application?.companyName,
  );
  late final _role = TextEditingController(
    text: widget.existing?.roleTitle ?? widget.application?.jobTitle,
  );
  late final _interviewer =
      TextEditingController(text: widget.existing?.interviewerName);
  late final _notes = TextEditingController(text: widget.existing?.notes);

  late DateTime _date = widget.existing?.scheduledAt ??
      DateTime.now().add(const Duration(days: 3));
  late TimeOfDay _time = TimeOfDay.fromDateTime(
      widget.existing?.scheduledAt ??
          DateTime.now().add(const Duration(days: 3)));
  late InterviewStage _stage =
      widget.existing?.stage ?? InterviewStage.technical;
  late InterviewFormat _format =
      widget.existing?.format ?? InterviewFormat.video;
  late InterviewStatus _status =
      widget.existing?.status ?? InterviewStatus.upcoming;
  late int _duration = widget.existing?.durationMinutes ?? 60;
  late String? _applicationId =
      widget.existing?.applicationId ?? widget.application?.id;

  @override
  void dispose() {
    for (final c in [_company, _role, _interviewer, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => _company.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;
    final applications = ref.watch(applicationsProvider);

    return FormSheet(
      title: isEdit ? 'Edit interview' : 'Schedule interview',
      submitLabel: isEdit ? 'Save changes' : 'Schedule',
      canSubmit: _valid,
      onSubmit: _submit,
      children: [
        if (widget.application == null && applications.isNotEmpty) ...[
          LabeledField(
            label: 'Link to application',
            child: AppDropdown<String?>(
              value: _applicationId,
              items: <String?>[null, ...applications.map((a) => a.id)],
              labelBuilder: (id) {
                if (id == null) return 'Not linked';
                final a = applications.firstWhere((x) => x.id == id);
                return '${a.jobTitle} · ${a.companyName}';
              },
              onChanged: (v) => setState(() {
                _applicationId = v;
                if (v != null) {
                  final a = applications.firstWhere((x) => x.id == v);
                  _company.text = a.companyName;
                  _role.text = a.jobTitle;
                }
              }),
            ),
          ),
          const SizedBox(height: Insets.lg),
        ],
        LabeledField(
          label: 'Company',
          required: true,
          child: TextField(
            controller: _company,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Role',
          child: TextField(
            controller: _role,
            textCapitalization: TextCapitalization.words,
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Stage',
          child: ChipSelector<InterviewStage>(
            values: InterviewStage.values,
            selected: _stage,
            labelBuilder: (s) => s.label,
            onSelected: (s) => setState(() => _stage = s),
          ),
        ),
        const SizedBox(height: Insets.lg),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: LabeledField(
                label: 'Date',
                child: DateField(
                  value: _date,
                  clearable: false,
                  onChanged: (d) => setState(() => _date = d ?? _date),
                ),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              flex: 2,
              child: LabeledField(
                label: 'Time',
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: context, initialTime: _time);
                    if (picked != null) setState(() => _time = picked);
                  },
                  borderRadius: BorderRadius.circular(Corners.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.md, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(Corners.md),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: Insets.sm),
                        Text(_time.format(context),
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        Row(
          children: [
            Expanded(
              child: LabeledField(
                label: 'Format',
                child: AppDropdown<InterviewFormat>(
                  value: _format,
                  items: InterviewFormat.values,
                  labelBuilder: (f) => f.label,
                  onChanged: (v) => setState(() => _format = v!),
                ),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: LabeledField(
                label: 'Duration',
                child: AppDropdown<int>(
                  value: _duration,
                  items: const [30, 45, 60, 90, 120, 180],
                  labelBuilder: (m) => '$m minutes',
                  onChanged: (v) => setState(() => _duration = v!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Interviewer',
          child: TextField(
            controller: _interviewer,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Optional'),
          ),
        ),
        if (isEdit) ...[
          const SizedBox(height: Insets.lg),
          LabeledField(
            label: 'Status',
            child: ChipSelector<InterviewStatus>(
              values: InterviewStatus.values,
              selected: _status,
              labelBuilder: (s) => s.label,
              colorBuilder: (s) => s.color,
              onSelected: (s) => setState(() => _status = s),
            ),
          ),
        ],
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
    final scheduled = DateTime(
        _date.year, _date.month, _date.day, _time.hour, _time.minute);

    final app = ref.read(applicationsProvider.notifier).byId(_applicationId);

    final interview = Interview(
      id: existing?.id ?? uuid.v4(),
      applicationId: _applicationId,
      companyId: existing?.companyId ?? app?.companyId,
      companyName: _company.text.trim(),
      roleTitle: _role.text.trim(),
      interviewerName: _interviewer.text.trim(),
      scheduledAt: scheduled,
      durationMinutes: _duration,
      format: _format,
      stage: _stage,
      status: _status,
      prepChecklist: existing?.prepChecklist ??
          {for (final item in Interview.defaultPrepChecklist) item: false},
      selfRating: existing?.selfRating,
      questionsAsked: existing?.questionsAsked ?? '',
      whatWentWell: existing?.whatWentWell ?? '',
      whatToImprove: existing?.whatToImprove ?? '',
      struggledWith: existing?.struggledWith ?? '',
      notes: _notes.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(interviewsProvider.notifier);
    if (existing != null) {
      await notifier.put(interview);
    } else {
      await notifier.schedule(interview);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showToast(
        context, existing != null ? 'Interview updated' : 'Interview scheduled');
  }
}
