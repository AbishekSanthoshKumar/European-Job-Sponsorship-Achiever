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
import 'application_detail.dart';
import 'application_form.dart';

enum _View { kanban, table, timeline }

/// Filter state kept local to the screen.
class _Filters {
  const _Filters({
    this.query = '',
    this.country,
    this.role,
    this.source,
    this.resumeId,
    this.sponsorshipOnly = false,
    this.activeOnly = false,
  });

  final String query;
  final String? country;
  final String? role;
  final ApplicationSource? source;
  final String? resumeId;
  final bool sponsorshipOnly;
  final bool activeOnly;

  bool get isEmpty =>
      query.isEmpty &&
      country == null &&
      role == null &&
      source == null &&
      resumeId == null &&
      !sponsorshipOnly &&
      !activeOnly;

  _Filters copyWith({
    String? query,
    Object? country = _sentinel,
    Object? role = _sentinel,
    Object? source = _sentinel,
    Object? resumeId = _sentinel,
    bool? sponsorshipOnly,
    bool? activeOnly,
  }) =>
      _Filters(
        query: query ?? this.query,
        country: country == _sentinel ? this.country : country as String?,
        role: role == _sentinel ? this.role : role as String?,
        source: source == _sentinel
            ? this.source
            : source as ApplicationSource?,
        resumeId:
            resumeId == _sentinel ? this.resumeId : resumeId as String?,
        sponsorshipOnly: sponsorshipOnly ?? this.sponsorshipOnly,
        activeOnly: activeOnly ?? this.activeOnly,
      );

  bool matches(JobApplication a) {
    if (query.isNotEmpty) {
      final haystack =
          '${a.jobTitle} ${a.companyName} ${a.country} ${a.city} ${a.notes}'
              .toLowerCase();
      if (!haystack.contains(query.toLowerCase())) return false;
    }
    if (country != null && a.country != country) return false;
    if (role != null && a.roleCategory != role) return false;
    if (source != null && a.source != source) return false;
    if (resumeId != null && a.resumeId != resumeId) return false;
    if (sponsorshipOnly) {
      final ok = a.workAuthRequirement ==
              WorkAuthRequirement.explicitSponsorship ||
          a.workAuthRequirement == WorkAuthRequirement.sponsorshipPossible ||
          a.visaSponsorshipMentioned == TriState.yes;
      if (!ok) return false;
    }
    if (activeOnly && !a.stage.isActive) return false;
    return true;
  }
}

const _sentinel = Object();

class ApplicationsScreen extends ConsumerStatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ConsumerState<ApplicationsScreen> createState() =>
      _ApplicationsScreenState();
}

class _ApplicationsScreenState extends ConsumerState<ApplicationsScreen> {
  _View _view = _View.kanban;
  _Filters _filters = const _Filters();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(applicationsProvider);
    final metrics = ref.watch(metricsProvider);
    final filtered = all.where(_filters.matches).toList();
    final mobile = isMobile(context);

    // kanban is unusable on a phone; fall back to the list
    final effectiveView =
        mobile && _view == _View.kanban ? _View.table : _view;

    return PageScaffold(
      title: 'Applications',
      subtitle: '${metrics.total} sent · '
          '${(metrics.responseRate * 100).toStringAsFixed(0)}% response rate',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        if (!mobile)
          SegmentedButton<_View>(
            segments: const [
              ButtonSegment(
                value: _View.kanban,
                icon: Icon(Icons.view_kanban_outlined, size: 16),
                tooltip: 'Board',
              ),
              ButtonSegment(
                value: _View.table,
                icon: Icon(Icons.table_rows_outlined, size: 16),
                tooltip: 'Table',
              ),
              ButtonSegment(
                value: _View.timeline,
                icon: Icon(Icons.timeline_outlined, size: 16),
                tooltip: 'Timeline',
              ),
            ],
            selected: {_view},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _view = s.first),
          ),
        const SizedBox(width: Insets.sm),
        FilledButton.icon(
          onPressed: () => showApplicationForm(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(mobile ? '' : 'Add'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilterBar(
            filters: _filters,
            controller: _searchController,
            applications: all,
            onChanged: (f) => setState(() => _filters = f),
            showViewToggle: mobile,
            view: effectiveView,
            onViewChanged: (v) => setState(() => _view = v),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _EmptyApplications(hasFilters: !_filters.isEmpty)
                : switch (effectiveView) {
                    _View.kanban => _KanbanView(applications: filtered),
                    _View.table => _TableView(applications: filtered),
                    _View.timeline => _TimelineView(applications: filtered),
                  },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.filters,
    required this.controller,
    required this.applications,
    required this.onChanged,
    required this.showViewToggle,
    required this.view,
    required this.onViewChanged,
  });

  final _Filters filters;
  final TextEditingController controller;
  final List<JobApplication> applications;
  final ValueChanged<_Filters> onChanged;
  final bool showViewToggle;
  final _View view;
  final ValueChanged<_View> onViewChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mobile = isMobile(context);
    final countries = applications.map((a) => a.country).toSet().toList()
      ..sort();
    final roles = applications
        .map((a) => a.roleCategory)
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Container(
      padding: EdgeInsets.fromLTRB(
          mobile ? Insets.lg : Insets.xl, 0, mobile ? Insets.lg : Insets.xl,
          Insets.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: controller,
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search applications…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 16),
                      suffixIcon: filters.query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 15),
                              onPressed: () {
                                controller.clear();
                                onChanged(filters.copyWith(query: ''));
                              },
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: Insets.md, vertical: 0),
                    ),
                    onChanged: (v) => onChanged(filters.copyWith(query: v)),
                  ),
                ),
              ),
              if (showViewToggle) ...[
                const SizedBox(width: Insets.sm),
                IconButton(
                  icon: Icon(
                    view == _View.timeline
                        ? Icons.timeline_rounded
                        : Icons.table_rows_rounded,
                    size: 18,
                  ),
                  onPressed: () => onViewChanged(
                    view == _View.table ? _View.timeline : _View.table,
                  ),
                  tooltip: 'Switch view',
                ),
              ],
            ],
          ),
          const SizedBox(height: Insets.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: filters.country ?? 'Country',
                  active: filters.country != null,
                  onTap: () => _pick<String>(
                    context,
                    'Country',
                    countries,
                    (c) => Countries.withFlag(c),
                    filters.country,
                    (v) => onChanged(filters.copyWith(country: v)),
                  ),
                ),
                const SizedBox(width: Insets.sm),
                _FilterChip(
                  label: filters.role ?? 'Role',
                  active: filters.role != null,
                  onTap: () => _pick<String>(
                    context,
                    'Role',
                    roles,
                    (r) => r,
                    filters.role,
                    (v) => onChanged(filters.copyWith(role: v)),
                  ),
                ),
                const SizedBox(width: Insets.sm),
                _FilterChip(
                  label: filters.source?.label ?? 'Source',
                  active: filters.source != null,
                  onTap: () => _pick<ApplicationSource>(
                    context,
                    'Source',
                    ApplicationSource.values,
                    (s) => s.label,
                    filters.source,
                    (v) => onChanged(filters.copyWith(source: v)),
                  ),
                ),
                const SizedBox(width: Insets.sm),
                _FilterChip(
                  label: 'Sponsorship',
                  active: filters.sponsorshipOnly,
                  onTap: () => onChanged(filters.copyWith(
                      sponsorshipOnly: !filters.sponsorshipOnly)),
                ),
                const SizedBox(width: Insets.sm),
                _FilterChip(
                  label: 'Active only',
                  active: filters.activeOnly,
                  onTap: () => onChanged(
                      filters.copyWith(activeOnly: !filters.activeOnly)),
                ),
                if (!filters.isEmpty) ...[
                  const SizedBox(width: Insets.sm),
                  TextButton(
                    onPressed: () {
                      controller.clear();
                      onChanged(const _Filters());
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick<T>(
    BuildContext context,
    String title,
    List<T> options,
    String Function(T) labelOf,
    T? current,
    ValueChanged<T?> onPicked,
  ) async {
    if (options.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text('All',
                  style: Theme.of(context).textTheme.bodyMedium),
              trailing: current == null
                  ? const Icon(Icons.check_rounded, size: 16)
                  : null,
              onTap: () {
                onPicked(null);
                Navigator.of(sheetContext).pop();
              },
            ),
            for (final o in options)
              ListTile(
                title: Text(labelOf(o),
                    style: Theme.of(context).textTheme.bodyMedium),
                trailing: current == o
                    ? const Icon(Icons.check_rounded, size: 16)
                    : null,
                onTap: () {
                  onPicked(o);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Corners.sm),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(Corners.sm),
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
            const SizedBox(width: 3),
            Icon(
              active ? Icons.close_rounded : Icons.expand_more_rounded,
              size: 13,
              color: active
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyApplications extends StatelessWidget {
  const _EmptyApplications({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: hasFilters ? Icons.filter_alt_off_rounded : Icons.send_rounded,
      title: hasFilters ? 'No matches' : 'No applications yet',
      message: hasFilters
          ? 'Try relaxing or clearing your filters.'
          : 'Log your first application to start tracking the pipeline.',
      action: hasFilters
          ? null
          : FilledButton.icon(
              onPressed: () => showApplicationForm(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add application'),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kanban
// ---------------------------------------------------------------------------

class _KanbanView extends ConsumerWidget {
  const _KanbanView({required this.applications});

  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // only show stages that are in the active pipeline plus any closed
    // stage that actually holds cards
    final stages = <ApplicationStage>[
      ...ApplicationStage.pipeline,
      ...ApplicationStage.outcomes
          .where((s) => applications.any((a) => a.stage == s)),
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
          Insets.xl, Insets.lg, Insets.xl, Insets.xl),
      itemCount: stages.length,
      itemBuilder: (context, i) {
        final stage = stages[i];
        final cards =
            applications.where((a) => a.stage == stage).toList()
              ..sort((a, b) => (b.dateApplied ?? b.createdAt)
                  .compareTo(a.dateApplied ?? a.createdAt));
        return _KanbanColumn(stage: stage, applications: cards);
      },
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  const _KanbanColumn({required this.stage, required this.applications});

  final ApplicationStage stage;
  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return DragTarget<JobApplication>(
      onWillAcceptWithDetails: (details) => details.data.stage != stage,
      onAcceptWithDetails: (details) {
        ref
            .read(applicationsProvider.notifier)
            .moveToStage(details.data, stage);
        showToast(context, '${details.data.jobTitle} → ${stage.label}');
      },
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return Container(
          width: 272,
          margin: const EdgeInsets.only(right: Insets.md),
          decoration: BoxDecoration(
            color: hovering
                ? stage.color.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Corners.lg),
            border: Border.all(
              color: hovering ? stage.color : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.sm, Insets.sm, Insets.sm, Insets.md),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: stage.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Text(
                        stage.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${applications.length}',
                      style: AppTheme.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: applications.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: Insets.sm),
                    child: _DraggableCard(application: applications[i]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final card = _ApplicationCard(application: application);
    return Draggable<JobApplication>(
      data: application,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 256, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

class _ApplicationCard extends ConsumerWidget {
  const _ApplicationCard({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final scoring = ref.watch(scoringProvider);
    final company =
        ref.watch(companyByIdProvider)[application.companyId];
    final score = scoring.score(application, company: company);
    final health = application.health(
      waitingAfter: settings.agingWaitingDays,
      followUpAfter: settings.agingFollowUpDays,
      staleAfter: settings.agingStaleDays,
    );

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      onTap: () => showApplicationDetail(context, application.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  application.jobTitle,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Insets.sm),
              Text(
                score.round().toString(),
                style: AppTheme.mono(
                  size: 12,
                  weight: FontWeight.w700,
                  color: _scoreColor(score),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            application.companyName,
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Insets.sm),
          Row(
            children: [
              Text(
                Countries.flag(application.country),
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  application.city.isNotEmpty
                      ? application.city
                      : application.country,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (application.stage.hasApplied &&
                  health != ApplicationHealth.closed)
                Tooltip(
                  message: health.label,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: health.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          if (application.workAuthRequirement !=
              WorkAuthRequirement.unknown) ...[
            const SizedBox(height: Insets.sm),
            StatusChip(
              label: _shortVisa(application.workAuthRequirement),
              color: application.workAuthRequirement.color,
              dense: true,
            ),
          ],
        ],
      ),
    );
  }

  static Color _scoreColor(double score) {
    if (score >= 75) return AppColors.success;
    if (score >= 60) return AppColors.accent;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

  static String _shortVisa(WorkAuthRequirement w) => switch (w) {
        WorkAuthRequirement.explicitSponsorship => 'Sponsors',
        WorkAuthRequirement.sponsorshipPossible => 'Maybe sponsors',
        WorkAuthRequirement.existingPermit => 'Permit needed',
        WorkAuthRequirement.euOnly => 'EU only',
        WorkAuthRequirement.unknown => 'Unknown',
      };
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

class _TableView extends ConsumerWidget {
  const _TableView({required this.applications});

  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mobile = isMobile(context);
    final sorted = [...applications]..sort((a, b) =>
        (b.dateApplied ?? b.createdAt)
            .compareTo(a.dateApplied ?? a.createdAt));

    if (mobile) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            Insets.lg, Insets.md, Insets.lg, 96),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => const SizedBox(height: Insets.sm),
        itemBuilder: (context, i) =>
            _ApplicationListTile(application: sorted[i]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          Insets.xl, Insets.md, Insets.xl, Insets.xxl),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < sorted.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outline),
              _ApplicationRow(application: sorted[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ApplicationRow extends ConsumerWidget {
  const _ApplicationRow({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final scoring = ref.watch(scoringProvider);
    final company = ref.watch(companyByIdProvider)[application.companyId];
    final score = scoring.score(application, company: company);
    final health = application.health(
      waitingAfter: settings.agingWaitingDays,
      followUpAfter: settings.agingFollowUpDays,
      staleAfter: settings.agingStaleDays,
    );

    return InkWell(
      onTap: () => showApplicationDetail(context, application.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Insets.lg, vertical: Insets.md),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              child: Text(
                score.round().toString(),
                style: AppTheme.mono(
                  size: 13,
                  weight: FontWeight.w700,
                  color: _ApplicationCard._scoreColor(score),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.jobTitle,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    application.companyName,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Text(Countries.flag(application.country),
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      application.country,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                application.roleCategory,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 150,
              child: StatusChip(
                label: application.stage.label,
                color: application.stage.color,
                dense: true,
              ),
            ),
            SizedBox(
              width: 92,
              child: application.stage.hasApplied
                  ? Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: health.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${application.daysSinceApplied ?? 0}d',
                          style: AppTheme.mono(
                            size: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationListTile extends ConsumerWidget {
  const _ApplicationListTile({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final health = application.health(
      waitingAfter: settings.agingWaitingDays,
      followUpAfter: settings.agingFollowUpDays,
      staleAfter: settings.agingStaleDays,
    );

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      onTap: () => showApplicationDetail(context, application.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  application.jobTitle,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusChip(
                label: application.stage.label,
                color: application.stage.color,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(Countries.flag(application.country),
                  style: const TextStyle(fontSize: 11)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${application.companyName} · ${application.country}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (application.stage.hasApplied) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: health.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '${application.daysSinceApplied ?? 0}d',
                  style: AppTheme.mono(
                    size: 10,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline
// ---------------------------------------------------------------------------

class _TimelineView extends ConsumerWidget {
  const _TimelineView({required this.applications});

  final List<JobApplication> applications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final mobile = isMobile(context);

    // group by the day they were applied (or saved)
    final byDay = <DateTime, List<JobApplication>>{};
    for (final a in applications) {
      final d = dayOf(a.dateApplied ?? a.dateSaved ?? a.createdAt);
      (byDay[d] ??= []).add(a);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(mobile ? Insets.lg : Insets.xl, Insets.md,
          mobile ? Insets.lg : Insets.xl, 96),
      itemCount: days.length,
      itemBuilder: (context, i) {
        final day = days[i];
        final items = byDay[day]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  top: Insets.md, bottom: Insets.sm),
              child: Row(
                children: [
                  Text(
                    _formatDay(day),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Container(
                        height: 1, color: theme.colorScheme.outline),
                  ),
                  const SizedBox(width: Insets.sm),
                  Text(
                    '${items.length}',
                    style: AppTheme.mono(
                      size: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final a in items)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: _ApplicationListTile(application: a),
              ),
          ],
        );
      },
    );
  }

  static String _formatDay(DateTime d) {
    final today = dayOf(DateTime.now());
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.day} ${const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][d.month - 1]} ${d.year}';
  }
}
