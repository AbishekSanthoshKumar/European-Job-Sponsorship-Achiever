import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/quick_add_sheet.dart';

/// Aggregates everything waiting on a nudge from you.
class FollowUpsScreen extends ConsumerWidget {
  const FollowUpsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buckets = ref.watch(followUpBucketsProvider);
    final settings = ref.watch(settingsProvider);
    final contacts = ref.watch(contactsProvider);
    final mobile = isMobile(context);

    final quietContacts = contacts
        .where((c) => c.needsNudge(afterDays: settings.contactNudgeDays))
        .toList()
      ..sort((a, b) =>
          (b.daysSinceContacted ?? 0).compareTo(a.daysSinceContacted ?? 0));

    final sections = <(String, List<FollowUp>, Color)>[
      ('Overdue', buckets.overdue, AppColors.danger),
      ('Today', buckets.today, AppColors.warning),
      ('This week', buckets.thisWeek, AppColors.info),
      ('Upcoming', buckets.upcoming, AppColors.textSecondary),
    ];

    final isEmpty = buckets.total == 0 && quietContacts.isEmpty;

    return PageScaffold(
      title: 'Follow-ups',
      subtitle: buckets.actionableCount == 0
          ? 'Nothing needs chasing right now'
          : '${buckets.actionableCount} need action today',
      child: isEmpty
          ? const Padding(
              padding: EdgeInsets.only(top: Insets.xxxl),
              child: EmptyState(
                icon: Icons.check_circle_outline_rounded,
                title: 'All clear',
                message:
                    'Follow-ups are created automatically when you log an '
                    'application, and when a contact goes quiet.',
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (title, items, color) in sections)
                  if (items.isNotEmpty) ...[
                    SectionHeader(
                      '$title (${items.length})',
                      action: Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ),
                    for (final f in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Insets.sm),
                        child: _FollowUpTile(followUp: f, accent: color),
                      ),
                    const SizedBox(height: Insets.lg),
                  ],

                if (quietContacts.isNotEmpty) ...[
                  SectionHeader('Contacts gone quiet (${quietContacts.length})',
                      subtitle:
                          'Reached out, no reply after ${settings.contactNudgeDays} days'),
                  for (final c in quietContacts.take(10))
                    Padding(
                      padding: const EdgeInsets.only(bottom: Insets.sm),
                      child: AppCard(
                        padding: const EdgeInsets.all(Insets.md),
                        child: Row(
                          children: [
                            Icon(c.type.icon,
                                size: 15, color: AppColors.warning),
                            const SizedBox(width: Insets.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(c.name,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium),
                                  Text(
                                    '${c.daysSinceContacted} days since you '
                                    'reached out'
                                    '${c.companyName.isEmpty ? '' : ' · ${c.companyName}'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(contactsProvider.notifier)
                                  .logInteraction(
                                    contact: c,
                                    summary: 'Sent a follow-up message',
                                  ),
                              style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact),
                              child: const Text('Nudged'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],

                SizedBox(height: mobile ? Insets.xxl : Insets.lg),
              ],
            ),
    );
  }
}

class _FollowUpTile extends ConsumerWidget {
  const _FollowUpTile({required this.followUp, required this.accent});

  final FollowUp followUp;
  final Color accent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(followUpsProvider.notifier);

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      borderColor: followUp.isOverdue
          ? AppColors.danger.withValues(alpha: 0.4)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(followUp.type.icon, size: 15, color: accent),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      followUp.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (followUp.context.isNotEmpty)
                      Text(
                        followUp.context,
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Text(
                _dueLabel(followUp),
                style: AppTheme.mono(
                  size: 11,
                  weight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
          if (followUp.recommendedAction.isNotEmpty) ...[
            const SizedBox(height: Insets.sm),
            Text(
              followUp.recommendedAction,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
            ),
          ],
          const SizedBox(height: Insets.sm),
          Row(
            children: [
              if (followUp.suggestedMessage.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                        ClipboardData(text: followUp.suggestedMessage));
                    if (context.mounted) {
                      showToast(context, 'Message copied');
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Copy message'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.sm),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => notifier.snooze(followUp, 3),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Snooze 3d'),
              ),
              const SizedBox(width: Insets.sm),
              FilledButton(
                onPressed: () async {
                  await notifier.complete(followUp);
                  if (context.mounted) {
                    showToast(context, 'Follow-up completed');
                  }
                },
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Insets.md, vertical: Insets.sm),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _dueLabel(FollowUp f) {
    final days = f.daysUntilDue;
    if (days < 0) return '${days.abs()}d late';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'in ${days}d';
  }
}
