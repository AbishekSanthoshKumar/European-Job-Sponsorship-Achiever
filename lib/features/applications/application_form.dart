import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/countries.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/scoring_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/quick_add_sheet.dart';

/// Opens the add/edit application form.
///
/// Only Job title, Company and Country are required — everything else is
/// behind collapsible sections so logging an application stays fast.
Future<void> showApplicationForm(
  BuildContext context, {
  JobApplication? existing,
  Company? company,
  ApplicationStage? initialStage,
}) {
  return showFormSheet<void>(
    context,
    (_) => _ApplicationForm(
      existing: existing,
      company: company,
      initialStage: initialStage,
    ),
  );
}

class _ApplicationForm extends ConsumerStatefulWidget {
  const _ApplicationForm({this.existing, this.company, this.initialStage});

  final JobApplication? existing;
  final Company? company;
  final ApplicationStage? initialStage;

  @override
  ConsumerState<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends ConsumerState<_ApplicationForm> {
  late final _title = TextEditingController(text: widget.existing?.jobTitle);
  late final _company = TextEditingController(
      text: widget.existing?.companyName ?? widget.company?.name);
  late final _city = TextEditingController(
      text: widget.existing?.city ?? widget.company?.city);
  late final _url = TextEditingController(text: widget.existing?.jobUrl);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late final _visaNotes = TextEditingController(text: widget.existing?.visaNotes);
  late final _salaryMin = TextEditingController(
      text: widget.existing?.salaryMin?.toString() ?? '');
  late final _salaryMax = TextEditingController(
      text: widget.existing?.salaryMax?.toString() ?? '');

  late String _country =
      widget.existing?.country ?? widget.company?.country ?? Countries.primary.first;
  late String _role = widget.existing?.roleCategory ?? Roles.all.first;
  late ApplicationStage _stage =
      widget.existing?.stage ?? widget.initialStage ?? ApplicationStage.applied;
  late ApplicationSource _source =
      widget.existing?.source ?? ApplicationSource.linkedIn;
  late Seniority _seniority = widget.existing?.seniority ?? Seniority.mid;
  late WorkMode _workMode = widget.existing?.workMode ?? WorkMode.unknown;
  late EmploymentType _employment =
      widget.existing?.employmentType ?? EmploymentType.fullTime;

  late WorkAuthRequirement _workAuth =
      widget.existing?.workAuthRequirement ?? WorkAuthRequirement.unknown;
  late TriState _visaMentioned =
      widget.existing?.visaSponsorshipMentioned ?? TriState.unknown;
  late TriState _relocation =
      widget.existing?.relocationAssistance ?? TriState.unknown;

  late String? _resumeId = widget.existing?.resumeId;
  late bool _coverLetter = widget.existing?.coverLetterUsed ?? false;

  late DateTime? _dateApplied = widget.existing?.dateApplied ??
      ((widget.initialStage ?? ApplicationStage.applied).hasApplied
          ? DateTime.now()
          : null);

  late int _skill = widget.existing?.skillMatch ?? 7;
  late int _experience = widget.existing?.experienceMatch ?? 6;
  late int _visaProb = widget.existing?.visaProbability ?? 5;
  late int _companyPriority = widget.existing?.companyPriorityScore ?? 6;

  String? _companyId;

  @override
  void initState() {
    super.initState();
    _companyId = widget.existing?.companyId ?? widget.company?.id;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _company,
      _city,
      _url,
      _notes,
      _visaNotes,
      _salaryMin,
      _salaryMax,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _valid =>
      _title.text.trim().isNotEmpty && _company.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resumes = ref.watch(resumesProvider);
    final isEdit = widget.existing != null;

    // live opportunity score preview
    final preview = _buildApplication(previewOnly: true);
    final scoring = ref.watch(scoringProvider);
    final score = scoring.score(preview);
    final tier = OpportunityTier.of(score);

    return FormSheet(
      title: isEdit ? 'Edit application' : 'Log application',
      subtitle: isEdit
          ? widget.existing!.companyName
          : 'Job title, company and country are all you need',
      submitLabel: isEdit ? 'Save changes' : 'Add application',
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
            decoration: const InputDecoration(
                hintText: 'e.g. Senior Backend Engineer'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: Insets.lg),

        LabeledField(
          label: 'Company',
          required: true,
          child: _CompanyAutocomplete(
            controller: _company,
            onSelected: (c) {
              setState(() {
                _companyId = c?.id;
                if (c != null) {
                  if (c.country.isNotEmpty) _country = _normaliseCountry(c.country);
                  if (c.city.isNotEmpty) _city.text = c.city;
                  _companyPriority = (c.priority.score * 10).round();
                  _visaProb = c.sponsorshipLikelihood;
                }
              });
            },
          ),
        ),
        const SizedBox(height: Insets.lg),

        Row(
          children: [
            Expanded(
              flex: 3,
              child: LabeledField(
                label: 'Country',
                required: true,
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
                  decoration: const InputDecoration(hintText: 'Optional'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Insets.lg),

        LabeledField(
          label: 'Stage',
          child: ChipSelector<ApplicationStage>(
            values: const [
              ApplicationStage.saved,
              ApplicationStage.readyToApply,
              ApplicationStage.applied,
              ApplicationStage.recruiterScreen,
              ApplicationStage.technicalInterview,
              ApplicationStage.offer,
            ],
            selected: _stage,
            labelBuilder: (s) => s.label,
            colorBuilder: (s) => s.color,
            onSelected: (s) => setState(() {
              _stage = s;
              if (s.hasApplied && _dateApplied == null) {
                _dateApplied = DateTime.now();
              }
            }),
          ),
        ),
        const SizedBox(height: Insets.lg),

        // live score preview
        Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            color: _tierColor(tier).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(Corners.md),
            border:
                Border.all(color: _tierColor(tier).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Text(
                score.toStringAsFixed(0),
                style: AppTheme.mono(
                  size: 22,
                  weight: FontWeight.w700,
                  color: _tierColor(tier),
                ),
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tier.label,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: _tierColor(tier))),
                    Text(
                      'Opportunity score — adjust the ratings below to refine',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.sm),

        CollapsibleSection(
          title: 'Role & source',
          icon: Icons.work_outline_rounded,
          children: [
            LabeledField(
              label: 'Role category',
              child: AppDropdown<String>(
                value: Roles.all.contains(_role) ? _role : Roles.all.last,
                items: Roles.all,
                labelBuilder: (r) => r,
                onChanged: (v) => setState(() => _role = v!),
              ),
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Source',
              child: AppDropdown<ApplicationSource>(
                value: _source,
                items: ApplicationSource.values,
                labelBuilder: (s) => s.label,
                onChanged: (v) => setState(() => _source = v!),
              ),
            ),
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Seniority',
                    child: AppDropdown<Seniority>(
                      value: _seniority,
                      items: Seniority.values,
                      labelBuilder: (s) => s.label,
                      onChanged: (v) => setState(() => _seniority = v!),
                    ),
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: LabeledField(
                    label: 'Work mode',
                    child: AppDropdown<WorkMode>(
                      value: _workMode,
                      items: WorkMode.values,
                      labelBuilder: (s) => s.label,
                      onChanged: (v) => setState(() => _workMode = v!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Employment type',
              child: AppDropdown<EmploymentType>(
                value: _employment,
                items: EmploymentType.values,
                labelBuilder: (s) => s.label,
                onChanged: (v) => setState(() => _employment = v!),
              ),
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Job URL',
              child: TextField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(hintText: 'https://'),
              ),
            ),
          ],
        ),

        CollapsibleSection(
          title: 'Visa & sponsorship',
          icon: Icons.flight_takeoff_rounded,
          initiallyExpanded: true,
          children: [
            LabeledField(
              label: 'Work authorisation requirement',
              child: AppDropdown<WorkAuthRequirement>(
                value: _workAuth,
                items: WorkAuthRequirement.values,
                labelBuilder: (s) => s.label,
                onChanged: (v) => setState(() {
                  _workAuth = v!;
                  // keep the manual rating aligned with the explicit field
                  _visaProb = (v.visaScore * 10).round();
                }),
              ),
            ),
            const SizedBox(height: Insets.md),
            LabeledField(
              label: 'Sponsorship mentioned in the posting',
              child: ChipSelector<TriState>(
                values: TriState.values,
                selected: _visaMentioned,
                labelBuilder: (t) => t.label,
                colorBuilder: (t) => t.color,
                onSelected: (t) => setState(() => _visaMentioned = t),
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
            LabeledField(
              label: 'Visa notes',
              child: TextField(
                controller: _visaNotes,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'What did the posting say about sponsorship?',
                ),
              ),
            ),
          ],
        ),

        CollapsibleSection(
          title: 'Resume & scoring',
          icon: Icons.description_outlined,
          children: [
            LabeledField(
              label: 'Resume used',
              child: AppDropdown<String?>(
                value: _resumeId,
                items: <String?>[null, ...resumes.map((r) => r.id)],
                labelBuilder: (id) => id == null
                    ? 'Not specified'
                    : resumes
                        .firstWhere((r) => r.id == id,
                            orElse: () => resumes.first)
                        .name,
                onChanged: (v) => setState(() => _resumeId = v),
              ),
            ),
            const SizedBox(height: Insets.sm),
            SwitchListTile.adaptive(
              value: _coverLetter,
              onChanged: (v) => setState(() => _coverLetter = v),
              title: Text('Cover letter used',
                  style: theme.textTheme.bodyMedium),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            const SizedBox(height: Insets.sm),
            RatingSlider(
              label: 'Skill match',
              value: _skill,
              onChanged: (v) => setState(() => _skill = v),
            ),
            RatingSlider(
              label: 'Experience match',
              value: _experience,
              onChanged: (v) => setState(() => _experience = v),
            ),
            RatingSlider(
              label: 'Visa probability',
              value: _visaProb,
              onChanged: (v) => setState(() => _visaProb = v),
            ),
            RatingSlider(
              label: 'Company priority',
              value: _companyPriority,
              onChanged: (v) => setState(() => _companyPriority = v),
            ),
          ],
        ),

        CollapsibleSection(
          title: 'Dates & salary',
          icon: Icons.calendar_today_rounded,
          children: [
            LabeledField(
              label: 'Date applied',
              child: DateField(
                value: _dateApplied,
                onChanged: (d) => setState(() => _dateApplied = d),
              ),
            ),
            const SizedBox(height: Insets.md),
            Row(
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Salary min',
                    child: TextField(
                      controller: _salaryMin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '60000'),
                    ),
                  ),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: LabeledField(
                    label: 'Salary max',
                    child: TextField(
                      controller: _salaryMax,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '80000'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: Insets.sm),
        LabeledField(
          label: 'Notes',
          child: TextField(
            controller: _notes,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Anything worth remembering about this role',
            ),
          ),
        ),
      ],
    );
  }

  static String _normaliseCountry(String raw) =>
      Countries.all.contains(raw) ? raw : Countries.primary.first;

  JobApplication _buildApplication({bool previewOnly = false}) {
    final now = DateTime.now();
    final existing = widget.existing;

    return JobApplication(
      id: existing?.id ?? uuid.v4(),
      jobTitle: _title.text.trim(),
      companyName: _company.text.trim(),
      companyId: _companyId,
      country: _country,
      city: _city.text.trim(),
      jobUrl: _url.text.trim(),
      source: _source,
      roleCategory: _role,
      seniority: _seniority,
      employmentType: _employment,
      workMode: _workMode,
      salaryMin: int.tryParse(_salaryMin.text.trim()),
      salaryMax: int.tryParse(_salaryMax.text.trim()),
      stage: _stage,
      visaSponsorshipMentioned: _visaMentioned,
      relocationAssistance: _relocation,
      workAuthRequirement: _workAuth,
      visaNotes: _visaNotes.text.trim(),
      resumeId: _resumeId,
      coverLetterUsed: _coverLetter,
      dateDiscovered: existing?.dateDiscovered ?? now,
      dateSaved: existing?.dateSaved ?? now,
      dateApplied: _dateApplied,
      lastActivity: previewOnly ? existing?.lastActivity : now,
      responseDate: existing?.responseDate,
      interviewDate: existing?.interviewDate,
      outcomeDate: existing?.outcomeDate,
      skillMatch: _skill,
      experienceMatch: _experience,
      visaProbability: _visaProb,
      companyPriorityScore: _companyPriority,
      notes: _notes.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _submit() async {
    if (!_valid) return;
    final app = _buildApplication();
    final notifier = ref.read(applicationsProvider.notifier);
    final isEdit = widget.existing != null;

    if (isEdit) {
      // route through moveToStage so history and follow-ups stay consistent
      if (widget.existing!.stage != _stage) {
        await notifier.put(app.copyWith(stage: widget.existing!.stage));
        await notifier.moveToStage(
          notifier.byId(app.id) ?? app,
          _stage,
        );
      } else {
        await notifier.put(app);
      }
    } else {
      await notifier.create(app);
    }

    // adding an application advances the linked company's relationship
    final companyId = _companyId;
    if (companyId != null && _stage.hasApplied) {
      final companies = ref.read(companiesProvider.notifier);
      final company = companies.byId(companyId);
      if (company != null &&
          company.relationship.index < CompanyRelationship.applied.index) {
        await companies.setRelationship(company, CompanyRelationship.applied);
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    showToast(
      context,
      isEdit ? 'Application updated' : 'Logged ${app.jobTitle}',
    );
  }
}

/// Company field that suggests from the seeded target database.
class _CompanyAutocomplete extends ConsumerWidget {
  const _CompanyAutocomplete({
    required this.controller,
    required this.onSelected,
  });

  final TextEditingController controller;
  final ValueChanged<Company?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companies = ref.watch(companiesProvider);

    return RawAutocomplete<Company>(
      textEditingController: controller,
      focusNode: FocusNode(),
      optionsBuilder: (value) {
        final q = value.text.trim().toLowerCase();
        if (q.length < 2) return const Iterable<Company>.empty();
        final matches = companies
            .where((c) => c.name.toLowerCase().contains(q))
            .toList()
          ..sort((a, b) {
            // prefix matches first, then priority
            final ap = a.name.toLowerCase().startsWith(q) ? 0 : 1;
            final bp = b.name.toLowerCase().startsWith(q) ? 0 : 1;
            if (ap != bp) return ap - bp;
            return b.priority.weight.compareTo(a.priority.weight);
          });
        return matches.take(8);
      },
      displayStringForOption: (c) => c.name,
      onSelected: onSelected,
      fieldViewBuilder: (context, textController, focusNode, onSubmit) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Start typing — your target list will suggest',
          ),
          onChanged: (_) {
            onSelected(null);
            (context as Element).markNeedsBuild();
          },
        );
      },
      optionsViewBuilder: (context, onSelect, options) {
        final theme = Theme.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(Corners.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 520),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final c = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    onTap: () => onSelect(c),
                    title: Text(c.name, style: theme.textTheme.bodyMedium),
                    subtitle: Text(
                      [
                        if (c.city.isNotEmpty) c.city,
                        if (c.country.isNotEmpty) c.country,
                        if (c.industry.isNotEmpty) c.industry,
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(
                      c.priority.icon,
                      size: 14,
                      color: c.priority.color,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Colour for an opportunity tier badge.
Color _tierColor(OpportunityTier tier) => switch (tier) {
      OpportunityTier.exceptional || OpportunityTier.high => AppColors.success,
      OpportunityTier.good => AppColors.accent,
      OpportunityTier.medium => AppColors.warning,
      OpportunityTier.low => AppColors.danger,
    };
