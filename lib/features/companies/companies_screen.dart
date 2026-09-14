import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/countries.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/quick_add_sheet.dart';
import '../applications/application_form.dart';
import '../networking/contact_form.dart';
import 'company_form.dart';

/// Opens a URL in the browser / external app.
Future<void> openUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || url.isEmpty) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class CompaniesScreen extends ConsumerStatefulWidget {
  const CompaniesScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends ConsumerState<CompaniesScreen> {
  late final _search = TextEditingController(text: widget.initialQuery ?? '');
  late String _query = widget.initialQuery ?? '';
  String? _country;
  CompanyPriority? _priority;
  CompanyRelationship? _relationship;
  bool _sponsorsOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(companiesProvider);
    final mobile = isMobile(context);

    final filtered = all.where((c) {
      if (_query.isNotEmpty) {
        final hay = '${c.name} ${c.city} ${c.country} ${c.industry}'
            .toLowerCase();
        if (!hay.contains(_query.toLowerCase())) return false;
      }
      if (_country != null && c.country != _country) return false;
      if (_priority != null && c.priority != _priority) return false;
      if (_relationship != null && c.relationship != _relationship) {
        return false;
      }
      if (_sponsorsOnly && c.sponsorshipLikelihood < 7) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final p = b.priority.weight.compareTo(a.priority.weight);
        if (p != 0) return p;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    // country counts for the filter row, primary markets first
    final counts = <String, int>{};
    for (final c in all) {
      if (c.country.isEmpty) continue;
      counts[c.country] = (counts[c.country] ?? 0) + 1;
    }
    final countries = counts.keys.toList()
      ..sort((a, b) {
        final ap = Countries.primary.indexOf(a);
        final bp = Countries.primary.indexOf(b);
        if (ap >= 0 || bp >= 0) {
          if (ap < 0) return 1;
          if (bp < 0) return -1;
          return ap - bp;
        }
        return counts[b]!.compareTo(counts[a]!);
      });

    return PageScaffold(
      title: 'Companies',
      subtitle: '${filtered.length} of ${all.length} target companies',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        FilledButton.icon(
          onPressed: () => showCompanyForm(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(mobile ? '' : 'Add'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(mobile ? Insets.lg : Insets.xl, 0,
                mobile ? Insets.lg : Insets.xl, Insets.md),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _search,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search ${all.length} companies…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon:
                                  const Icon(Icons.close_rounded, size: 15),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: Insets.md),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(height: Insets.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Sponsors likely',
                        active: _sponsorsOnly,
                        onTap: () =>
                            setState(() => _sponsorsOnly = !_sponsorsOnly),
                      ),
                      const SizedBox(width: Insets.sm),
                      for (final p in CompanyPriority.values) ...[
                        _Chip(
                          label: p.label,
                          active: _priority == p,
                          color: p.color,
                          onTap: () => setState(
                              () => _priority = _priority == p ? null : p),
                        ),
                        const SizedBox(width: Insets.sm),
                      ],
                      Container(
                        width: 1,
                        height: 20,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: Insets.sm),
                      for (final c in countries) ...[
                        _Chip(
                          label: '${Countries.flag(c)} $c (${counts[c]})',
                          active: _country == c,
                          onTap: () => setState(
                              () => _country = _country == c ? null : c),
                        ),
                        const SizedBox(width: Insets.sm),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.domain_rounded,
                    title: 'No companies match',
                    message: 'Try clearing a filter or searching for '
                        'something else.',
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                        mobile ? Insets.lg : Insets.xl,
                        Insets.md,
                        mobile ? Insets.lg : Insets.xl,
                        96),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: Insets.sm),
                      child: _CompanyTile(company: filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Corners.sm),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Corners.sm),
          border: Border.all(
            color: active ? accent : theme.colorScheme.outline,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: active ? accent : theme.colorScheme.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CompanyTile extends ConsumerWidget {
  const _CompanyTile({required this.company});

  final Company company;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final applications = ref
        .watch(applicationsProvider)
        .where((a) =>
            a.companyId == company.id ||
            a.companyName.toLowerCase() == company.name.toLowerCase())
        .length;

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      onTap: () => _showDetail(context, ref),
      child: Row(
        children: [
          Icon(company.priority.icon, size: 16, color: company.priority.color),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (company.country.isNotEmpty)
                      '${Countries.flag(company.country)} '
                          '${company.displayLocation}',
                    if (company.industry.isNotEmpty) company.industry,
                  ].join('  ·  '),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (applications > 0) ...[
            const SizedBox(width: Insets.sm),
            StatusChip(
              label: '$applications applied',
              color: AppColors.primary,
              dense: true,
            ),
          ],
          if (company.relationship != CompanyRelationship.notResearched) ...[
            const SizedBox(width: Insets.sm),
            StatusChip(
              label: company.relationship.label,
              color: company.relationship.color,
              dense: true,
            ),
          ],
          if (company.careerUrl.isNotEmpty) ...[
            const SizedBox(width: Insets.xs),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              tooltip: 'Careers page',
              visualDensity: VisualDensity.compact,
              onPressed: () => openUrl(company.careerUrl),
            ),
          ],
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    showFormSheet<void>(
      context,
      (_) => _CompanyDetail(companyId: company.id),
      maxWidth: 600,
    );
  }
}

class _CompanyDetail extends ConsumerWidget {
  const _CompanyDetail({required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final company = ref.watch(companiesProvider.notifier).byId(companyId);
    if (company == null) {
      return const Padding(
        padding: EdgeInsets.all(Insets.xxl),
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Company not found',
          compact: true,
        ),
      );
    }

    final applications = ref
        .watch(applicationsProvider)
        .where((a) =>
            a.companyId == company.id ||
            a.companyName.toLowerCase() == company.name.toLowerCase())
        .toList();
    final contacts = ref
        .watch(contactsProvider)
        .where((c) =>
            c.companyId == company.id ||
            c.companyName.toLowerCase() == company.name.toLowerCase())
        .toList();

    final media = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Insets.xl, Insets.lg, Insets.md, Insets.md),
            child: Row(
              children: [
                Icon(company.priority.icon,
                    size: 18, color: company.priority.color),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company.name,
                          style: theme.textTheme.headlineMedium),
                      Text(
                        [
                          if (company.displayLocation.isNotEmpty)
                            company.displayLocation,
                          if (company.industry.isNotEmpty) company.industry,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showCompanyForm(context, existing: company);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Insets.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // links
                  Wrap(
                    spacing: Insets.sm,
                    runSpacing: Insets.sm,
                    children: [
                      if (company.careerUrl.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => openUrl(company.careerUrl),
                          icon: const Icon(Icons.work_outline_rounded,
                              size: 15),
                          label: const Text('Careers'),
                        ),
                      if (company.linkedinUrl.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => openUrl(company.linkedinUrl),
                          icon: const Icon(Icons.groups_outlined, size: 15),
                          label: const Text('LinkedIn'),
                        ),
                      if (company.website.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => openUrl(company.website),
                          icon: const Icon(Icons.language_rounded, size: 15),
                          label: const Text('Website'),
                        ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),

                  // relationship pipeline
                  const SectionHeader('Relationship'),
                  Wrap(
                    spacing: Insets.sm,
                    runSpacing: Insets.sm,
                    children: [
                      for (final r in CompanyRelationship.values)
                        InkWell(
                          onTap: () => ref
                              .read(companiesProvider.notifier)
                              .setRelationship(company, r),
                          borderRadius: BorderRadius.circular(Corners.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Insets.md, vertical: 6),
                            decoration: BoxDecoration(
                              color: company.relationship == r
                                  ? r.color.withValues(alpha: 0.16)
                                  : theme.colorScheme.surfaceContainer,
                              borderRadius:
                                  BorderRadius.circular(Corners.sm),
                              border: Border.all(
                                color: company.relationship == r
                                    ? r.color
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            child: Text(
                              r.label,
                              style:
                                  theme.textTheme.labelMedium?.copyWith(
                                color: company.relationship == r
                                    ? r.color
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),

                  // visa
                  const SectionHeader('Sponsorship'),
                  AppCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Known sponsor',
                                  style: theme.textTheme.bodySmall),
                            ),
                            StatusChip(
                              label: company.knownSponsor.label,
                              color: company.knownSponsor.color,
                              dense: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: Insets.md),
                        LabeledProgress(
                          label: 'Sponsorship likelihood',
                          value: company.sponsorshipLikelihood,
                          target: 10,
                          color: company.sponsorshipLikelihood >= 7
                              ? AppColors.success
                              : AppColors.accent,
                          compact: true,
                        ),
                        if (Countries.visaNotes[company.country] != null) ...[
                          const SizedBox(height: Insets.md),
                          Text(
                            Countries.visaNotes[company.country]!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(height: 1.45),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // applications
                  const SizedBox(height: Insets.lg),
                  SectionHeader(
                    'Applications (${applications.length})',
                    action: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showApplicationForm(context, company: company);
                      },
                      icon: const Icon(Icons.add_rounded, size: 15),
                      label: const Text('Apply'),
                    ),
                  ),
                  if (applications.isEmpty)
                    Text('No applications to this company yet.',
                        style: theme.textTheme.bodySmall)
                  else
                    for (final a in applications)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Insets.sm),
                        child: AppCard(
                          padding: const EdgeInsets.all(Insets.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(a.jobTitle,
                                    style: theme.textTheme.bodyMedium),
                              ),
                              StatusChip(
                                label: a.stage.label,
                                color: a.stage.color,
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                  // contacts
                  const SizedBox(height: Insets.lg),
                  SectionHeader(
                    'Contacts (${contacts.length})',
                    action: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showContactForm(context, company: company);
                      },
                      icon: const Icon(Icons.add_rounded, size: 15),
                      label: const Text('Add'),
                    ),
                  ),
                  if (contacts.isEmpty)
                    Text(
                      'No contacts yet. Finding one engineer or recruiter '
                      'here dramatically improves your odds.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    for (final c in contacts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Insets.sm),
                        child: AppCard(
                          padding: const EdgeInsets.all(Insets.md),
                          child: Row(
                            children: [
                              Icon(c.type.icon,
                                  size: 14, color: c.status.color),
                              const SizedBox(width: Insets.md),
                              Expanded(
                                child: Text(
                                  [c.name, if (c.role.isNotEmpty) c.role]
                                      .join(' · '),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              StatusChip(
                                label: c.status.label,
                                color: c.status.color,
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                  if (company.whyThisCompany.isNotEmpty) ...[
                    const SizedBox(height: Insets.lg),
                    const SectionHeader('Why this company'),
                    AppCard(
                        child: Text(company.whyThisCompany,
                            style: theme.textTheme.bodyMedium)),
                  ],
                  if (company.techStack.isNotEmpty) ...[
                    const SizedBox(height: Insets.lg),
                    const SectionHeader('Tech stack'),
                    Wrap(
                      spacing: Insets.sm,
                      runSpacing: Insets.sm,
                      children: [
                        for (final t in company.techStack)
                          StatusChip(
                              label: t,
                              color: theme.colorScheme.onSurfaceVariant,
                              dense: true),
                      ],
                    ),
                  ],
                  if (company.notes.isNotEmpty) ...[
                    const SizedBox(height: Insets.lg),
                    const SectionHeader('Notes'),
                    AppCard(
                        child: Text(company.notes,
                            style: theme.textTheme.bodyMedium)),
                  ],
                  if (company.isSeeded) ...[
                    const SizedBox(height: Insets.lg),
                    Text(
                      'Imported from your target lists'
                      '${company.sourceRefs.isEmpty ? '' : ' · '
                          '${company.sourceRefs.join(', ')}'}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 10.5),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
