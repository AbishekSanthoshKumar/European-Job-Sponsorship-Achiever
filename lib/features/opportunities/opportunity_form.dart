import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/countries.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/quick_add_sheet.dart';

/// The fastest capture path: paste a link, save, process later.
Future<void> showOpportunityForm(
  BuildContext context, {
  JobOpportunity? existing,
}) {
  return showFormSheet<void>(
    context,
    (_) => _OpportunityForm(existing: existing),
    maxWidth: 540,
  );
}

class _OpportunityForm extends ConsumerStatefulWidget {
  const _OpportunityForm({this.existing});

  final JobOpportunity? existing;

  @override
  ConsumerState<_OpportunityForm> createState() => _OpportunityFormState();
}

class _OpportunityFormState extends ConsumerState<_OpportunityForm> {
  late final _title = TextEditingController(text: widget.existing?.jobTitle);
  late final _company =
      TextEditingController(text: widget.existing?.companyName);
  late final _url = TextEditingController(text: widget.existing?.url);
  late final _notes = TextEditingController(text: widget.existing?.notes);

  late String _country = widget.existing?.country ?? Countries.primary.first;
  late ApplicationSource _source =
      widget.existing?.source ?? ApplicationSource.linkedIn;
  late TaskPriority _priority = widget.existing?.priority ?? TaskPriority.normal;
  late OpportunityStatus _status =
      widget.existing?.status ?? OpportunityStatus.inbox;

  @override
  void dispose() {
    for (final c in [_title, _company, _url, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => _title.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return FormSheet(
      title: isEdit ? 'Edit opportunity' : 'Save opportunity',
      subtitle: isEdit ? null : 'Capture it now, decide later',
      submitLabel: isEdit ? 'Save changes' : 'Save to inbox',
      canSubmit: _valid,
      onSubmit: _submit,
      children: [
        LabeledField(
          label: 'Job title',
          required: true,
          child: TextField(
            controller: _title,
            autofocus: !isEdit,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(hintText: 'e.g. Backend Engineer'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Company',
          child: TextField(
            controller: _company,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Optional'),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Link',
          child: TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(hintText: 'https://'),
          ),
        ),
        const SizedBox(height: Insets.lg),
        Row(
          children: [
            Expanded(
              child: LabeledField(
                label: 'Country',
                child: AppDropdown<String>(
                  value: _country,
                  items: Countries.all,
                  labelBuilder: Countries.withFlag,
                  onChanged: (v) => setState(() => _country = v!),
                ),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: LabeledField(
                label: 'Source',
                child: AppDropdown<ApplicationSource>(
                  value: _source,
                  items: ApplicationSource.values,
                  labelBuilder: (s) => s.label,
                  onChanged: (v) => setState(() => _source = v!),
                ),
              ),
            ),
          ],
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
        if (isEdit) ...[
          const SizedBox(height: Insets.lg),
          LabeledField(
            label: 'Status',
            child: ChipSelector<OpportunityStatus>(
              values: OpportunityStatus.values,
              selected: _status,
              labelBuilder: (s) => s.label,
              colorBuilder: (s) => s.color,
              onSelected: (s) => setState(() => _status = s),
            ),
          ),
        ],
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Quick notes',
          child: TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Why did this catch your eye?',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_valid) return;
    final now = DateTime.now();
    final existing = widget.existing;

    final opp = JobOpportunity(
      id: existing?.id ?? uuid.v4(),
      jobTitle: _title.text.trim(),
      companyName: _company.text.trim(),
      companyId: existing?.companyId,
      url: _url.text.trim(),
      country: _country,
      source: _source,
      dateDiscovered: existing?.dateDiscovered ?? now,
      priority: _priority,
      status: _status,
      notes: _notes.text.trim(),
      convertedApplicationId: existing?.convertedApplicationId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(opportunitiesProvider.notifier);
    if (existing != null) {
      await notifier.put(opp);
    } else {
      await notifier.create(opp);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showToast(context, existing != null ? 'Opportunity updated' : 'Saved to inbox');
  }
}
