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
import 'opportunity_form.dart';

/// The inbox for jobs found while browsing, before they become applications.
class OpportunitiesScreen extends ConsumerStatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  ConsumerState<OpportunitiesScreen> createState() =>
      _OpportunitiesScreenState();
}

class _OpportunitiesScreenState
    extends ConsumerState<OpportunitiesScreen> {
  OpportunityStatus? _status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = ref.watch(opportunitiesProvider);
    final mobile = isMobile(context);

    final visible = all
        .where((o) =>
            _status == null
                ? o.status != OpportunityStatus.discarded
                : o.status == _status)
        .toList()
      ..sort((a, b) {
        final p = b.priority.weight.compareTo(a.priority.weight);
        if (p != 0) return p;
        return b.dateDiscovered.compareTo(a.dateDiscovered);
      });

    final counts = <OpportunityStatus, int>{};
    for (final o in all) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }
    final inboxCount = counts[OpportunityStatus.inbox] ?? 0;

    return PageScaffold(
      title: 'Opportunities',
      subtitle: '$inboxCount waiting to be processed',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        FilledButton.icon(
          onPressed: () => showOpportunityForm(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(mobile ? '' : 'Save'),
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
                  bottom: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusPill(
                    label: 'Open',
                    active: _status == null,
                    onTap: () => setState(() => _status = null),
                  ),
                  const SizedBox(width: Insets.sm),
                  for (final s in OpportunityStatus.values) ...[
                    _StatusPill(
                      label: '${s.label} (${counts[s] ?? 0})',
                      active: _status == s,
                      color: s.color,
                      onTap: () => setState(
                          () => _status = _status == s ? null : s),
                    ),
                    const SizedBox(width: Insets.sm),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: visible.isEmpty
                ? EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: all.isEmpty
                        ? 'Inbox is empty'
                        : 'Nothing in this bucket',
                    message: all.isEmpty
                        ? 'When you spot a role while browsing, save it here '
                            'in seconds and process it later.'
                        : 'Try another filter.',
                    action: all.isEmpty
                        ? FilledButton.icon(
                            onPressed: () => showOpportunityForm(context),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Save an opportunity'),
                          )
                        : null,
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                        mobile ? Insets.lg : Insets.xl,
                        Insets.md,
                        mobile ? Insets.lg : Insets.xl,
                        96),
                    itemCount: visible.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: Insets.sm),
                      child: _OpportunityTile(opportunity: visible[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
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
          border:
              Border.all(color: active ? accent : theme.colorScheme.outline),
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

class _OpportunityTile extends ConsumerWidget {
  const _OpportunityTile({required this.opportunity});

  final JobOpportunity opportunity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(opportunitiesProvider.notifier);
    final stale = opportunity.ageInDays >= 14 &&
        opportunity.status == OpportunityStatus.inbox;

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      onTap: () => showOpportunityForm(context, existing: opportunity),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  opportunity.jobTitle,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StatusChip(
                label: opportunity.status.label,
                color: opportunity.status.color,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              if (opportunity.country.isNotEmpty) ...[
                Text(Countries.flag(opportunity.country),
                    style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  [
                    if (opportunity.companyName.isNotEmpty)
                      opportunity.companyName,
                    opportunity.source.label,
                    opportunity.ageInDays == 0
                        ? 'today'
                        : '${opportunity.ageInDays}d ago',
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: stale ? AppColors.warning : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (opportunity.notes.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              opportunity.notes,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: Insets.sm),
          Row(
            children: [
              if (opportunity.url.isNotEmpty)
                TextButton.icon(
                  onPressed: () => openUrl(opportunity.url),
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text('Open'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.sm, vertical: 0),
                  ),
                ),
              const Spacer(),
              if (opportunity.status != OpportunityStatus.applied &&
                  opportunity.status != OpportunityStatus.discarded) ...[
                TextButton(
                  onPressed: () async {
                    await notifier.put(opportunity.copyWith(
                        status: OpportunityStatus.discarded));
                    if (context.mounted) {
                      showToast(context, 'Discarded',
                          actionLabel: 'Undo',
                          onAction: () => notifier.put(opportunity));
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Discard'),
                ),
                const SizedBox(width: Insets.sm),
                FilledButton(
                  onPressed: () async {
                    await notifier.convert(opportunity);
                    if (context.mounted) {
                      showToast(context,
                          'Moved to applications as "Ready to apply"');
                    }
                  },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.md, vertical: Insets.sm),
                  ),
                  child: const Text('Convert'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
