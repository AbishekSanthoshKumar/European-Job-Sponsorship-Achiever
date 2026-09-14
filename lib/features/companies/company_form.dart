import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/countries.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/quick_add_sheet.dart';

Future<void> showCompanyForm(BuildContext context, {Company? existing}) {
  return showFormSheet<void>(
    context,
    (_) => _CompanyForm(existing: existing),
  );
}

class _CompanyForm extends ConsumerStatefulWidget {
  const _CompanyForm({this.existing});

  final Company? existing;

  @override
  ConsumerState<_CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends ConsumerState<_CompanyForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _website = TextEditingController(text: widget.existing?.website);
  late final _career = TextEditingController(text: widget.existing?.careerUrl);
  late final _linkedin =
      TextEditingController(text: widget.existing?.linkedinUrl);
  late final _city = TextEditingController(text: widget.existing?.city);
  late final _industry = TextEditingController(text: widget.existing?.industry);
  late final _size = TextEditingController(text: widget.existing?.companySize);
  late final _why =
      TextEditingController(text: widget.existing?.whyThisCompany);
  late final _stack = TextEditingController(
      text: widget.existing?.techStack.join(', ') ?? '');
  late final _roles = TextEditingController(
      text: widget.existing?.potentialRoles.join(', ') ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes);

  late String _country = widget.existing?.country.isNotEmpty == true &&
          Countries.all.contains(widget.existing!.country)
      ? widget.existing!.country
      : Countries.primary.first;
  late CompanyType _type = widget.existing?.type ?? CompanyType.productCompany;
  late CompanyPriority _priority =
      widget.existing?.priority ?? CompanyPriority.medium;
  late CompanyRelationship _relationship =
      widget.existing?.relationship ?? CompanyRelationship.notResearched;
  late TriState _knownSponsor =
      widget.existing?.knownSponsor ?? TriState.unknown;
  late TriState _relocation =
      widget.existing?.relocationAssistance ?? TriState.unknown;
  late int _sponsorLikelihood = widget.existing?.sponsorshipLikelihood ?? 5;

  @override
  void dispose() {
    for (final c in [
      _name,
      _website,
      _career,
      _linkedin,
      _city,
      _industry,
      _size,
      _why,
      _stack,
      _roles,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return FormSheet(
      title: isEdit ? 'Edit company' : 'Add company',
      subtitle: isEdit ? widget.existing!.displayLocation : null,
      submitLabel: isEdit ? 'Save changes' : 'Add to targets',
      canSubmit: _valid,
      onSubmit: _submit,
      children: [
        LabeledField(
          label: 'Company name',
          required: true,
          child: TextField(
            controller: _name,
            autofocus: !isEdit,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Insets.lg),
        Row(
          children: [
            Expanded(
              flex: 3,
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
              flex: 2,
              child: LabeledField(
                label: 'City',
                child: TextField(
                  controller: _city,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Priority',
          child: ChipSelector<CompanyPriority>(
            values: CompanyPriority.values,
            selected: _priority,
            labelBuilder: (p) => p.label,
            colorBuilder: (p) => p.color,
            onSelected: (p) => setState(() => _priority = p),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Relationship',
          child: AppDropdown<CompanyRelationship>(
            value: _relationship,
            items: CompanyRelationship.values,
            labelBuilder: (r) => r.label,
            onChanged: (v) => setState(() => _relationship = v!),
          ),
        ),

        CollapsibleSection(
          title: 'Links',
          icon: Icons.link_rounded,
          initiallyExpanded: !isEdit,
          children: [
            LabeledField(
              label: 'Careers page',
              child: TextField(
                controller: _career,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'https://'),
              ),
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Website',
              child: TextField(
                controller: _website,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'https://'),
              ),
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'LinkedIn',
              child: TextField(
                controller: _linkedin,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                    hintText: 'https://linkedin.com/company/'),
              ),
            ),
          ],
        ),

        CollapsibleSection(
          title: 'Visa & sponsorship',
          icon: Icons.flight_takeoff_rounded,
          children: [
            LabeledField(
              label: 'Known sponsor',
              child: ChipSelector<TriState>(
                values: TriState.values,
                selected: _knownSponsor,
                labelBuilder: (t) => t.label,
                colorBuilder: (t) => t.color,
                onSelected: (t) => setState(() => _knownSponsor = t),
              ),
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Relocation assistance',
              child: ChipSelector<TriState>(
                values: TriState.values,
                selected: _relocation,
                labelBuilder: (t) => t.label,
                colorBuilder: (t) => t.color,
                onSelected: (t) => setState(() => _relocation = t),
              ),
            ),
            const SizedBox(height: Insets.md),
            RatingSlider(
              label: 'Sponsorship likelihood',
              value: _sponsorLikelihood,
              onChanged: (v) => setState(() => _sponsorLikelihood = v),
            ),
          ],
        ),

        CollapsibleSection(
          title: 'Profile & notes',
          icon: Icons.notes_rounded,
          children: [
            LabeledField(
              label: 'Industry',
              child: TextField(controller: _industry),
            ),
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Type',
                    child: AppDropdown<CompanyType>(
                      value: _type,
                      items: CompanyType.values,
                      labelBuilder: (t) => t.label,
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: LabeledField(
                    label: 'Size',
                    child: TextField(
                      controller: _size,
                      decoration:
                          const InputDecoration(hintText: 'e.g. 500-1000'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Why this company?',
              child: TextField(controller: _why, maxLines: 2),
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Tech stack',
              hint: 'Comma separated',
              child: TextField(
                controller: _stack,
                decoration:
                    const InputDecoration(hintText: 'Python, AWS, React'),
              ),
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Potential roles',
              hint: 'Comma separated',
              child: TextField(controller: _roles),
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Notes',
              child: TextField(controller: _notes, maxLines: 3),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_valid) return;
    final now = DateTime.now();
    final existing = widget.existing;

    final company = Company(
      id: existing?.id ?? uuid.v4(),
      name: _name.text.trim(),
      website: _website.text.trim(),
      linkedinUrl: _linkedin.text.trim(),
      careerUrl: _career.text.trim(),
      country: _country,
      city: _city.text.trim(),
      industry: _industry.text.trim(),
      companySize: _size.text.trim(),
      type: _type,
      knownSponsor: _knownSponsor,
      sponsorshipLikelihood: _sponsorLikelihood,
      relocationAssistance: _relocation,
      internationalHiringHistory: existing?.internationalHiringHistory ?? '',
      priority: _priority,
      relationship: _relationship,
      whyThisCompany: _why.text.trim(),
      techStack: _split(_stack.text),
      potentialRoles: _split(_roles.text),
      notes: _notes.text.trim(),
      tags: existing?.tags ?? const [],
      isSeeded: existing?.isSeeded ?? false,
      sourceRefs: existing?.sourceRefs ?? const [],
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(companiesProvider.notifier);
    if (existing != null) {
      await notifier.put(company);
    } else {
      await notifier.create(company);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showToast(context, existing != null ? 'Company updated' : 'Company added');
  }

  static List<String> _split(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
