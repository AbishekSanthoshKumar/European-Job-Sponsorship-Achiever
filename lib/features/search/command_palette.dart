import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/destinations.dart';
import '../applications/application_form.dart';
import '../companies/company_form.dart';
import '../interviews/interview_form.dart';
import '../networking/contact_form.dart';
import '../opportunities/opportunity_form.dart';

Future<void> showCommandPalette(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => const _CommandPalette(),
  );
}

/// A search result or an action the palette can run.
class _Entry {
  const _Entry({
    required this.label,
    required this.icon,
    required this.onRun,
    this.detail = '',
    this.group = '',
    this.color,
    this.score = 0,
  });

  final String label;
  final String detail;
  final String group;
  final IconData icon;
  final Color? color;
  final void Function(BuildContext context) onRun;

  /// Higher sorts first.
  final int score;
}

class _CommandPalette extends ConsumerStatefulWidget {
  const _CommandPalette();

  @override
  ConsumerState<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends ConsumerState<_CommandPalette> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  String _query = '';
  int _highlighted = 0;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _buildEntries();
    final safeIndex = entries.isEmpty
        ? 0
        : _highlighted.clamp(0, entries.length - 1);

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 96, left: 16, right: 16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 480),
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () {
              if (entries.isEmpty) return;
              setState(() =>
                  _highlighted = (safeIndex + 1) % entries.length);
            },
            const SingleActivator(LogicalKeyboardKey.arrowUp): () {
              if (entries.isEmpty) return;
              setState(() => _highlighted =
                  (safeIndex - 1 + entries.length) % entries.length);
            },
            const SingleActivator(LogicalKeyboardKey.enter): () {
              if (entries.isEmpty) return;
              _run(entries[safeIndex]);
            },
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.of(context).pop(),
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // search field
              Padding(
                padding: const EdgeInsets.all(Insets.md),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText:
                        'Search applications, companies, people, agencies…',
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 18),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                  ),
                  onChanged: (v) => setState(() {
                    _query = v;
                    _highlighted = 0;
                  }),
                ),
              ),
              Divider(height: 1, color: theme.colorScheme.outline),

              Flexible(
                child: entries.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(Insets.xxl),
                        child: Text(
                          'No matches for "$_query"',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                            vertical: Insets.sm),
                        itemCount: entries.length,
                        itemBuilder: (context, i) {
                          final e = entries[i];
                          final showGroup = i == 0 ||
                              entries[i - 1].group != e.group;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showGroup && e.group.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      Insets.lg, Insets.sm, Insets.lg, 4),
                                  child: Text(
                                    e.group.toUpperCase(),
                                    style: theme.textTheme.labelSmall
                                        ?.copyWith(
                                      letterSpacing: 1,
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              _PaletteRow(
                                entry: e,
                                highlighted: i == safeIndex,
                                onTap: () => _run(e),
                                onHover: () =>
                                    setState(() => _highlighted = i),
                              ),
                            ],
                          );
                        },
                      ),
              ),

              Divider(height: 1, color: theme.colorScheme.outline),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: Insets.lg, vertical: Insets.sm),
                child: Row(
                  children: [
                    _Hint(label: '↑↓', text: 'Navigate'),
                    const SizedBox(width: Insets.lg),
                    _Hint(label: '↵', text: 'Open'),
                    const SizedBox(width: Insets.lg),
                    _Hint(label: 'esc', text: 'Close'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _run(_Entry entry) {
    Navigator.of(context).pop();
    entry.onRun(context);
  }

  List<_Entry> _buildEntries() {
    final q = _query.trim().toLowerCase();
    final out = <_Entry>[];

    // -- actions -----------------------------------------------------------
    final actions = <_Entry>[
      _Entry(
        label: 'Add application',
        icon: Icons.send_rounded,
        group: 'Actions',
        onRun: showApplicationForm,
      ),
      _Entry(
        label: 'Save opportunity',
        icon: Icons.bookmark_add_rounded,
        group: 'Actions',
        onRun: showOpportunityForm,
      ),
      _Entry(
        label: 'Add contact',
        icon: Icons.person_add_rounded,
        group: 'Actions',
        onRun: showContactForm,
      ),
      _Entry(
        label: 'Add company',
        icon: Icons.domain_add_rounded,
        group: 'Actions',
        onRun: showCompanyForm,
      ),
      _Entry(
        label: 'Schedule interview',
        icon: Icons.event_rounded,
        group: 'Actions',
        onRun: showInterviewForm,
      ),
    ];

    for (final a in actions) {
      if (q.isEmpty || a.label.toLowerCase().contains(q)) out.add(a);
    }

    // -- navigation --------------------------------------------------------
    for (final d in appDestinations) {
      if (q.isNotEmpty && !d.label.toLowerCase().contains(q)) continue;
      out.add(_Entry(
        label: d.label,
        icon: d.icon,
        group: 'Go to',
        onRun: (context) => context.go(d.route),
      ));
    }

    if (q.isEmpty) return out.take(14).toList();

    // -- records -----------------------------------------------------------
    final matches = <_Entry>[];

    for (final a in ref.read(applicationsProvider)) {
      if (!'${a.jobTitle} ${a.companyName} ${a.country}'
          .toLowerCase()
          .contains(q)) {
        continue;
      }
      matches.add(_Entry(
        label: a.jobTitle,
        detail: '${a.companyName} · ${a.country} · ${a.stage.label}',
        icon: Icons.send_rounded,
        color: a.stage.color,
        group: 'Applications',
        score: a.jobTitle.toLowerCase().startsWith(q) ? 2 : 1,
        onRun: (context) => context.go('/applications'),
      ));
    }

    for (final c in ref.read(companiesProvider)) {
      if (!c.name.toLowerCase().contains(q)) continue;
      matches.add(_Entry(
        label: c.name,
        detail: [
          if (c.displayLocation.isNotEmpty) c.displayLocation,
          if (c.industry.isNotEmpty) c.industry,
        ].join(' · '),
        icon: Icons.domain_rounded,
        color: c.priority.color,
        group: 'Companies',
        score: (c.name.toLowerCase().startsWith(q) ? 2 : 1) +
            c.priority.weight,
        onRun: (context) => context.go('/companies?q=${Uri.encodeComponent(c.name)}'),
      ));
    }

    for (final a in ref.read(agenciesProvider)) {
      if (!a.name.toLowerCase().contains(q)) continue;
      matches.add(_Entry(
        label: a.name,
        detail: [
          if (a.country.isNotEmpty) a.country,
          a.specialization.label,
        ].join(' · '),
        icon: Icons.business_center_rounded,
        color: a.status.color,
        group: 'Agencies',
        score: a.name.toLowerCase().startsWith(q) ? 2 : 1,
        onRun: (context) =>
            context.go('/agencies?q=${Uri.encodeComponent(a.name)}'),
      ));
    }

    for (final c in ref.read(contactsProvider)) {
      if (!'${c.name} ${c.companyName}'.toLowerCase().contains(q)) continue;
      matches.add(_Entry(
        label: c.name,
        detail: [
          if (c.role.isNotEmpty) c.role,
          if (c.companyName.isNotEmpty) c.companyName,
        ].join(' · '),
        icon: c.type.icon,
        color: c.status.color,
        group: 'People',
        score: c.name.toLowerCase().startsWith(q) ? 2 : 1,
        onRun: (context) => context.go('/network'),
      ));
    }

    for (final o in ref.read(opportunitiesProvider)) {
      if (!'${o.jobTitle} ${o.companyName}'.toLowerCase().contains(q)) {
        continue;
      }
      matches.add(_Entry(
        label: o.jobTitle,
        detail: [o.companyName, o.status.label]
            .where((s) => s.isNotEmpty)
            .join(' · '),
        icon: Icons.bookmark_rounded,
        color: o.status.color,
        group: 'Opportunities',
        onRun: (context) => context.go('/opportunities'),
      ));
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    out.addAll(matches.take(30));

    return out.take(40).toList();
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.entry,
    required this.highlighted,
    required this.onTap,
    required this.onHover,
  });

  final _Entry entry;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => onHover(),
      child: Material(
        color: highlighted
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Insets.lg, vertical: 9),
            child: Row(
              children: [
                Icon(
                  entry.icon,
                  size: 16,
                  color: entry.color ?? theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              highlighted ? FontWeight.w600 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (entry.detail.isNotEmpty)
                        Text(
                          entry.detail,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (highlighted)
                  Icon(Icons.subdirectory_arrow_left_rounded,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Text(label,
              style: AppTheme.mono(
                  size: 9, color: theme.colorScheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 5),
        Text(text,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5)),
      ],
    );
  }
}
