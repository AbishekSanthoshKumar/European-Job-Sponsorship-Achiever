import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/countries.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/quick_add_sheet.dart';
import '../companies/companies_screen.dart' show openUrl;
import '../networking/contact_form.dart';

/// Tabs split the "who can place me" list from the "where do I look" list.
enum _Tab { agencies, jobBoards, government }

class AgenciesScreen extends ConsumerStatefulWidget {
  const AgenciesScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<AgenciesScreen> createState() => _AgenciesScreenState();
}

class _AgenciesScreenState extends ConsumerState<AgenciesScreen> {
  late final _search = TextEditingController(text: widget.initialQuery ?? '');
  late String _query = widget.initialQuery ?? '';
  _Tab _tab = _Tab.agencies;
  String? _country;
  AgencyStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Pure predicate so tab counts can be computed without touching state.
  static bool _matchesTab(RecruitmentAgency a, _Tab tab) => switch (tab) {
        _Tab.agencies => !a.isJobBoard,
        _Tab.jobBoards =>
          a.specialization == AgencySpecialization.jobBoard ||
              a.specialization == AgencySpecialization.recruiterDatabase,
        _Tab.government =>
          a.specialization == AgencySpecialization.governmentPortal,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(agenciesProvider);
    final mobile = isMobile(context);

    final inTab = all.where((a) => _matchesTab(a, _tab)).toList();
    final filtered = inTab.where((a) {
      if (_query.isNotEmpty &&
          !'${a.name} ${a.country} ${a.notes}'
              .toLowerCase()
              .contains(_query.toLowerCase())) {
        return false;
      }
      if (_country != null && a.country != _country) return false;
      if (_status != null && a.status != _status) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final p = b.priority.weight.compareTo(a.priority.weight);
        if (p != 0) return p;
        final s = b.matchScore.compareTo(a.matchScore);
        if (s != 0) return s;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final counts = <String, int>{};
    for (final a in inTab) {
      if (a.country.isEmpty) continue;
      counts[a.country] = (counts[a.country] ?? 0) + 1;
    }
    final countries = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    final notContacted =
        all.where((a) => !a.isJobBoard && a.status == AgencyStatus.notContacted);

    return PageScaffold(
      title: 'Agencies & sources',
      subtitle: '${all.length} imported · '
          '${notContacted.length} agencies not contacted',
      scrollable: false,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(mobile ? Insets.lg : Insets.xl, 0,
                mobile ? Insets.lg : Insets.xl, Insets.md),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final t in _Tab.values) ...[
                        _TabChip(
                          label: switch (t) {
                            _Tab.agencies => 'Recruitment agencies',
                            _Tab.jobBoards => 'Job boards & tools',
                            _Tab.government => 'Government portals',
                          },
                          count:
                              all.where((a) => _matchesTab(a, t)).length,
                          active: _tab == t,
                          onTap: () => setState(() {
                            _tab = t;
                            _country = null;
                            _status = null;
                          }),
                        ),
                        const SizedBox(width: Insets.sm),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: Insets.md),
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _search,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: Insets.md),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(height: Insets.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_tab == _Tab.agencies)
                        for (final s in [
                          AgencyStatus.notContacted,
                          AgencyStatus.contacted,
                          AgencyStatus.responded,
                          AgencyStatus.activeRelationship,
                        ]) ...[
                          _FilterPill(
                            label: s.label,
                            active: _status == s,
                            color: s.color,
                            onTap: () => setState(
                                () => _status = _status == s ? null : s),
                          ),
                          const SizedBox(width: Insets.sm),
                        ],
                      for (final c in countries) ...[
                        _FilterPill(
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
                ? const EmptyState(
                    icon: Icons.business_center_rounded,
                    title: 'Nothing here',
                    message: 'Try a different filter.',
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
                      child: _AgencyTile(agency: filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Corners.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.md, vertical: Insets.sm),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Corners.md),
          border: Border.all(
            color: active
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: AppTheme.mono(
                size: 10,
                weight: FontWeight.w700,
                color: active
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
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
            const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Corners.sm),
          border: Border.all(
              color: active ? accent : theme.colorScheme.outline),
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

class _AgencyTile extends ConsumerWidget {
  const _AgencyTile({required this.agency});

  final RecruitmentAgency agency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      onTap: () => showFormSheet<void>(
        context,
        (_) => _AgencyDetail(agencyId: agency.id),
        maxWidth: 560,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: agency.priority.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agency.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (agency.country.isNotEmpty)
                      '${Countries.flag(agency.country)} ${agency.country}',
                    agency.specialization.label,
                    if (agency.notes.isNotEmpty) agency.notes,
                  ].join('  ·  '),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (agency.tags.contains('offer-received-here')) ...[
            const SizedBox(width: Insets.sm),
            const Tooltip(
              message: 'Someone received an offer through this source',
              child: Icon(Icons.emoji_events_rounded,
                  size: 15, color: AppColors.accent),
            ),
          ],
          const SizedBox(width: Insets.sm),
          StatusChip(
            label: agency.status.label,
            color: agency.status.color,
            dense: true,
          ),
          if (agency.website.isNotEmpty) ...[
            const SizedBox(width: Insets.xs),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              visualDensity: VisualDensity.compact,
              tooltip: 'Open',
              onPressed: () => openUrl(agency.website),
            ),
          ],
        ],
      ),
    );
  }
}

class _AgencyDetail extends ConsumerWidget {
  const _AgencyDetail({required this.agencyId});

  final String agencyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final agency = ref.watch(agenciesProvider.notifier).byId(agencyId);
    if (agency == null) {
      return const Padding(
        padding: EdgeInsets.all(Insets.xxl),
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Not found',
          compact: true,
        ),
      );
    }

    final contacts = ref
        .watch(contactsProvider)
        .where((c) => c.agencyId == agency.id)
        .toList();
    final applications = ref
        .watch(applicationsProvider)
        .where((a) => a.agencyId == agency.id)
        .toList();
    final interviews = applications
        .where((a) => a.stage.isInterview || a.interviewDate != null)
        .length;

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agency.name,
                          style: theme.textTheme.headlineMedium),
                      Text(
                        [
                          if (agency.country.isNotEmpty) agency.country,
                          agency.specialization.label,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
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
                  if (agency.website.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => openUrl(agency.website),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text('Open site'),
                    ),
                  const SizedBox(height: Insets.lg),

                  const SectionHeader('Relationship status'),
                  Wrap(
                    spacing: Insets.sm,
                    runSpacing: Insets.sm,
                    children: [
                      for (final s in AgencyStatus.values)
                        InkWell(
                          onTap: () => ref
                              .read(agenciesProvider.notifier)
                              .setStatus(agency, s),
                          borderRadius: BorderRadius.circular(Corners.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Insets.md, vertical: 6),
                            decoration: BoxDecoration(
                              color: agency.status == s
                                  ? s.color.withValues(alpha: 0.16)
                                  : theme.colorScheme.surfaceContainer,
                              borderRadius:
                                  BorderRadius.circular(Corners.sm),
                              border: Border.all(
                                color: agency.status == s
                                    ? s.color
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            child: Text(
                              s.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: agency.status == s
                                    ? s.color
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: Insets.lg),
                  const SectionHeader('Performance'),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Submitted',
                          value: '${applications.length}',
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: StatTile(
                          label: 'Interviews',
                          value: '$interviews',
                          color: interviews > 0 ? AppColors.accent : null,
                        ),
                      ),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: StatTile(
                          label: 'Match',
                          value: '${agency.matchScore}/10',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: Insets.lg),
                  SectionHeader(
                    'Recruiters (${contacts.length})',
                    action: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showContactForm(context, agency: agency);
                      },
                      icon: const Icon(Icons.add_rounded, size: 15),
                      label: const Text('Add'),
                    ),
                  ),
                  if (contacts.isEmpty)
                    Text(
                      'No named recruiters yet. Agencies respond far better '
                      'when you contact a specific person.',
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
                                child: Text(c.name,
                                    style: theme.textTheme.bodyMedium),
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

                  if (agency.notes.isNotEmpty) ...[
                    const SizedBox(height: Insets.lg),
                    const SectionHeader('Notes'),
                    AppCard(
                        child: Text(agency.notes,
                            style: theme.textTheme.bodyMedium)),
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
