import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/quick_add_sheet.dart';
import '../companies/companies_screen.dart' show openUrl;
import 'contact_form.dart';

class NetworkingScreen extends ConsumerStatefulWidget {
  const NetworkingScreen({super.key});

  @override
  ConsumerState<NetworkingScreen> createState() => _NetworkingScreenState();
}

class _NetworkingScreenState extends ConsumerState<NetworkingScreen> {
  final _search = TextEditingController();
  String _query = '';
  ContactType? _type;
  ContactStatus? _status;
  bool _needsNudgeOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final all = ref.watch(contactsProvider);
    final mobile = isMobile(context);

    final filtered = all.where((c) {
      if (_query.isNotEmpty &&
          !'${c.name} ${c.companyName} ${c.role}'
              .toLowerCase()
              .contains(_query.toLowerCase())) {
        return false;
      }
      if (_type != null && c.type != _type) return false;
      if (_status != null && c.status != _status) return false;
      if (_needsNudgeOnly &&
          !c.needsNudge(afterDays: settings.contactNudgeDays)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        // people awaiting a nudge float to the top
        final an = a.needsNudge(afterDays: settings.contactNudgeDays) ? 0 : 1;
        final bn = b.needsNudge(afterDays: settings.contactNudgeDays) ? 0 : 1;
        if (an != bn) return an - bn;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    final nudgeCount = all
        .where((c) => c.needsNudge(afterDays: settings.contactNudgeDays))
        .length;
    final active = all
        .where((c) =>
            c.status == ContactStatus.conversationActive ||
            c.status == ContactStatus.responded)
        .length;

    return PageScaffold(
      title: 'Networking',
      subtitle: '${all.length} contacts · $active in conversation',
      scrollable: false,
      padding: EdgeInsets.zero,
      actions: [
        FilledButton.icon(
          onPressed: () => showContactForm(context),
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
                  bottom: BorderSide(color: theme.colorScheme.outline)),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _search,
                    style: theme.textTheme.bodyMedium,
                    decoration: const InputDecoration(
                      hintText: 'Search people…',
                      prefixIcon: Icon(Icons.search_rounded, size: 16),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: Insets.md),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(height: Insets.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (nudgeCount > 0) ...[
                        _Pill(
                          label: 'Needs nudge ($nudgeCount)',
                          active: _needsNudgeOnly,
                          color: AppColors.warning,
                          onTap: () => setState(
                              () => _needsNudgeOnly = !_needsNudgeOnly),
                        ),
                        const SizedBox(width: Insets.sm),
                      ],
                      for (final t in ContactType.values) ...[
                        _Pill(
                          label: t.label,
                          active: _type == t,
                          onTap: () => setState(
                              () => _type = _type == t ? null : t),
                        ),
                        const SizedBox(width: Insets.sm),
                      ],
                      Container(
                          width: 1,
                          height: 20,
                          color: theme.colorScheme.outline),
                      const SizedBox(width: Insets.sm),
                      for (final s in ContactStatus.values) ...[
                        _Pill(
                          label: s.label,
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
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.groups_rounded,
                    title: all.isEmpty
                        ? 'No contacts yet'
                        : 'No contacts match',
                    message: all.isEmpty
                        ? 'Recruiters and engineers inside your target '
                            'companies are the highest-leverage part of this '
                            'search. Add the first one.'
                        : 'Try clearing a filter.',
                    action: all.isEmpty
                        ? FilledButton.icon(
                            onPressed: () => showContactForm(context),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Add contact'),
                          )
                        : null,
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
                      child: _ContactTile(contact: filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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

class _ContactTile extends ConsumerWidget {
  const _ContactTile({required this.contact});

  final NetworkContact contact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final needsNudge = contact.needsNudge(afterDays: settings.contactNudgeDays);

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      borderColor: needsNudge
          ? AppColors.warning.withValues(alpha: 0.45)
          : null,
      onTap: () => showFormSheet<void>(
        context,
        (_) => _ContactDetail(contactId: contact.id),
        maxWidth: 560,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: contact.status.color.withValues(alpha: 0.15),
            child: Icon(contact.type.icon,
                size: 15, color: contact.status.color),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (contact.role.isNotEmpty) contact.role,
                    if (contact.companyName.isNotEmpty) contact.companyName,
                    if (contact.country.isNotEmpty) contact.country,
                  ].join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (needsNudge) ...[
            const SizedBox(width: Insets.sm),
            StatusChip(
              label: '${contact.daysSinceContacted}d silent',
              color: AppColors.warning,
              dense: true,
            ),
          ],
          const SizedBox(width: Insets.sm),
          StatusChip(
            label: contact.status.label,
            color: contact.status.color,
            dense: true,
          ),
          if (contact.linkedinUrl.isNotEmpty) ...[
            const SizedBox(width: Insets.xs),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              visualDensity: VisualDensity.compact,
              tooltip: 'LinkedIn',
              onPressed: () => openUrl(contact.linkedinUrl),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContactDetail extends ConsumerWidget {
  const _ContactDetail({required this.contactId});

  final String contactId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contact = ref.watch(contactsProvider.notifier).byId(contactId);
    if (contact == null) {
      return const Padding(
        padding: EdgeInsets.all(Insets.xxl),
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Contact not found',
          compact: true,
        ),
      );
    }

    final interactions =
        ref.watch(interactionsProvider.notifier).forContact(contact.id);
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
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      contact.status.color.withValues(alpha: 0.15),
                  child: Icon(contact.type.icon,
                      size: 17, color: contact.status.color),
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(contact.name,
                          style: theme.textTheme.headlineMedium),
                      Text(
                        [
                          if (contact.role.isNotEmpty) contact.role,
                          if (contact.companyName.isNotEmpty)
                            contact.companyName,
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
                    showContactForm(context, existing: contact);
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
                  Wrap(
                    spacing: Insets.sm,
                    runSpacing: Insets.sm,
                    children: [
                      if (contact.linkedinUrl.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () => openUrl(contact.linkedinUrl),
                          icon: const Icon(Icons.groups_outlined, size: 15),
                          label: const Text('LinkedIn'),
                        ),
                      if (contact.email.isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: () =>
                              openUrl('mailto:${contact.email}'),
                          icon: const Icon(Icons.mail_outline_rounded,
                              size: 15),
                          label: const Text('Email'),
                        ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),

                  const SectionHeader('Status'),
                  Wrap(
                    spacing: Insets.sm,
                    runSpacing: Insets.sm,
                    children: [
                      for (final s in ContactStatus.values)
                        InkWell(
                          onTap: () => ref
                              .read(contactsProvider.notifier)
                              .put(contact.copyWith(status: s)),
                          borderRadius: BorderRadius.circular(Corners.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Insets.md, vertical: 6),
                            decoration: BoxDecoration(
                              color: contact.status == s
                                  ? s.color.withValues(alpha: 0.16)
                                  : theme.colorScheme.surfaceContainer,
                              borderRadius:
                                  BorderRadius.circular(Corners.sm),
                              border: Border.all(
                                color: contact.status == s
                                    ? s.color
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            child: Text(
                              s.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: contact.status == s
                                    ? s.color
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: Insets.lg),
                  SectionHeader(
                    'Interaction timeline',
                    action: TextButton.icon(
                      onPressed: () =>
                          _logInteraction(context, ref, contact),
                      icon: const Icon(Icons.add_rounded, size: 15),
                      label: const Text('Log'),
                    ),
                  ),
                  if (interactions.isEmpty)
                    Text(
                      'Nothing logged yet. Recording each touch makes the '
                      'follow-up reminders work.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    for (final i in interactions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Insets.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Icon(
                                i.inbound
                                    ? Icons.call_received_rounded
                                    : Icons.call_made_rounded,
                                size: 13,
                                color: i.inbound
                                    ? AppColors.success
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: Insets.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(i.summary,
                                      style: theme.textTheme.bodyMedium),
                                  Text(
                                    '${_date(i.date)} · ${i.channel}',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(fontSize: 10.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                  if (contact.notes.isNotEmpty) ...[
                    const SizedBox(height: Insets.lg),
                    const SectionHeader('Notes'),
                    AppCard(
                        child: Text(contact.notes,
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

  Future<void> _logInteraction(
      BuildContext context, WidgetRef ref, NetworkContact contact) async {
    final result = await showDialog<(String, bool)>(
      context: context,
      builder: (_) => _LogInteractionDialog(contactName: contact.name),
    );
    if (result == null) return;
    await ref.read(contactsProvider.notifier).logInteraction(
          contact: contact,
          summary: result.$1,
          inbound: result.$2,
        );
    if (context.mounted) showToast(context, 'Interaction logged');
  }

  static String _date(DateTime d) =>
      '${d.day} ${const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][d.month - 1]}';
}

class _LogInteractionDialog extends StatefulWidget {
  const _LogInteractionDialog({required this.contactName});

  final String contactName;

  @override
  State<_LogInteractionDialog> createState() =>
      _LogInteractionDialogState();
}

class _LogInteractionDialogState extends State<_LogInteractionDialog> {
  final _controller = TextEditingController();
  bool _inbound = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Log interaction',
          style: Theme.of(context).textTheme.titleMedium),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: _inbound
                    ? '${widget.contactName} replied about…'
                    : 'Sent an introduction message',
              ),
            ),
            const SizedBox(height: Insets.md),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('I reached out')),
                ButtonSegment(value: true, label: Text('They replied')),
              ],
              selected: {_inbound},
              showSelectedIcon: false,
              onSelectionChanged: (s) =>
                  setState(() => _inbound = s.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = _controller.text.trim();
            if (text.isEmpty) return;
            Navigator.of(context).pop((text, _inbound));
          },
          child: const Text('Log'),
        ),
      ],
    );
  }
}
