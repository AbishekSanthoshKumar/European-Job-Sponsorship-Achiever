import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/countries.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/quick_add_sheet.dart';

Future<void> showContactForm(
  BuildContext context, {
  NetworkContact? existing,
  RecruitmentAgency? agency,
  Company? company,
}) {
  return showFormSheet<void>(
    context,
    (_) => _ContactForm(
      existing: existing,
      agency: agency,
      company: company,
    ),
  );
}

class _ContactForm extends ConsumerStatefulWidget {
  const _ContactForm({this.existing, this.agency, this.company});

  final NetworkContact? existing;
  final RecruitmentAgency? agency;
  final Company? company;

  @override
  ConsumerState<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<_ContactForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _company = TextEditingController(
    text: widget.existing?.companyName ??
        widget.agency?.name ??
        widget.company?.name,
  );
  late final _role = TextEditingController(text: widget.existing?.role);
  late final _linkedin =
      TextEditingController(text: widget.existing?.linkedinUrl);
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _notes = TextEditingController(text: widget.existing?.notes);

  late String _country = _initialCountry();
  late ContactType _type = widget.existing?.type ??
      (widget.agency != null ? ContactType.recruiter : ContactType.recruiter);
  late ContactStatus _status =
      widget.existing?.status ?? ContactStatus.notContacted;
  late int _strength = widget.existing?.relationshipStrength ?? 1;
  late DateTime? _contacted = widget.existing?.dateContacted;

  String _initialCountry() {
    final raw = widget.existing?.country ??
        widget.agency?.country ??
        widget.company?.country ??
        '';
    return Countries.all.contains(raw) ? raw : Countries.primary.first;
  }

  @override
  void dispose() {
    for (final c in [_name, _company, _role, _linkedin, _email, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return FormSheet(
      title: isEdit ? 'Edit contact' : 'Add contact',
      subtitle: widget.agency?.name ?? widget.company?.name,
      submitLabel: isEdit ? 'Save changes' : 'Add contact',
      canSubmit: _valid,
      onSubmit: _submit,
      children: [
        LabeledField(
          label: 'Name',
          required: true,
          child: TextField(
            controller: _name,
            autofocus: !isEdit,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Type',
          child: ChipSelector<ContactType>(
            values: ContactType.values,
            selected: _type,
            labelBuilder: (t) => t.label,
            onSelected: (t) => setState(() => _type = t),
          ),
        ),
        const SizedBox(height: Insets.lg),
        Row(
          children: [
            Expanded(
              child: LabeledField(
                label: 'Company / agency',
                child: TextField(
                  controller: _company,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: LabeledField(
                label: 'Role',
                child: TextField(
                  controller: _role,
                  decoration: const InputDecoration(
                      hintText: 'e.g. Tech Recruiter'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'LinkedIn',
          child: TextField(
            controller: _linkedin,
            keyboardType: TextInputType.url,
            decoration:
                const InputDecoration(hintText: 'https://linkedin.com/in/'),
          ),
        ),
        const SizedBox(height: Insets.lg),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: LabeledField(
                label: 'Email',
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              flex: 2,
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
          ],
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Status',
          child: AppDropdown<ContactStatus>(
            value: _status,
            items: ContactStatus.values,
            labelBuilder: (s) => s.label,
            onChanged: (v) => setState(() {
              _status = v!;
              if (v != ContactStatus.notContacted && _contacted == null) {
                _contacted = DateTime.now();
              }
            }),
          ),
        ),

        CollapsibleSection(
          title: 'Relationship',
          icon: Icons.handshake_outlined,
          children: [
            LabeledField(
              label: 'Date contacted',
              child: DateField(
                value: _contacted,
                onChanged: (d) => setState(() => _contacted = d),
              ),
            ),
            const SizedBox(height: Insets.md),
            RatingSlider(
              label: 'Relationship strength',
              value: _strength,
              onChanged: (v) => setState(() => _strength = v.clamp(1, 5)),
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

    final contact = NetworkContact(
      id: existing?.id ?? uuid.v4(),
      name: _name.text.trim(),
      companyName: _company.text.trim(),
      companyId: existing?.companyId ?? widget.company?.id,
      agencyId: existing?.agencyId ?? widget.agency?.id,
      role: _role.text.trim(),
      linkedinUrl: _linkedin.text.trim(),
      email: _email.text.trim(),
      country: _country,
      type: _type,
      status: _status,
      relationshipStrength: _strength.clamp(1, 5),
      dateContacted: _contacted,
      lastResponse: existing?.lastResponse,
      nextFollowUpDate: existing?.nextFollowUpDate,
      notes: _notes.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final notifier = ref.read(contactsProvider.notifier);
    if (existing != null) {
      await notifier.put(contact);
    } else {
      await notifier.create(contact);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showToast(context, existing != null ? 'Contact updated' : 'Contact added');
  }
}
