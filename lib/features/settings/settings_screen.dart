import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/seed_loader.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/quick_add_sheet.dart';

/// Controls the app-wide theme mode; overridden in main from settings.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    final companies = ref.watch(companiesProvider);
    final agencies = ref.watch(agenciesProvider);
    final applications = ref.watch(applicationsProvider);
    final contacts = ref.watch(contactsProvider);
    final tasks = ref.watch(tasksProvider);
    final activities = ref.watch(activityProvider);

    return PageScaffold(
      title: 'Settings',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // appearance
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Appearance',
                    icon: Icons.palette_outlined),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined, size: 15),
                      label: Text('Dark'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined, size: 15),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined, size: 15),
                      label: Text('System'),
                    ),
                  ],
                  selected: {themeMode},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) {
                    ref.read(themeModeProvider.notifier).state = s.first;
                    ref.read(settingsProvider.notifier).patch(
                          (v) => v.copyWith(themeMode: s.first.name),
                        );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          // application aging
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Application aging',
                    icon: Icons.hourglass_empty_rounded,
                    subtitle:
                        'When an application should be treated as going cold'),
                _NumberSetting(
                  label: 'Mark as waiting after',
                  value: settings.agingWaitingDays,
                  suffix: 'days',
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .patch((s) => s.copyWith(agingWaitingDays: v)),
                ),
                _NumberSetting(
                  label: 'Follow-up due after',
                  value: settings.agingFollowUpDays,
                  suffix: 'days',
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .patch((s) => s.copyWith(agingFollowUpDays: v)),
                ),
                _NumberSetting(
                  label: 'Consider stale after',
                  value: settings.agingStaleDays,
                  suffix: 'days',
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .patch((s) => s.copyWith(agingStaleDays: v)),
                ),
                _NumberSetting(
                  label: 'Auto-schedule follow-up after applying',
                  value: settings.followUpAfterDays,
                  suffix: 'days',
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .patch((s) => s.copyWith(followUpAfterDays: v)),
                ),
                _NumberSetting(
                  label: 'Flag a quiet contact after',
                  value: settings.contactNudgeDays,
                  suffix: 'days',
                  onChanged: (v) => ref
                      .read(settingsProvider.notifier)
                      .patch((s) => s.copyWith(contactNudgeDays: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          // data
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Your data',
                    icon: Icons.storage_rounded),
                Wrap(
                  spacing: Insets.lg,
                  runSpacing: Insets.sm,
                  children: [
                    _DataStat(
                        label: 'Companies', value: companies.length),
                    _DataStat(label: 'Agencies', value: agencies.length),
                    _DataStat(
                        label: 'Applications', value: applications.length),
                    _DataStat(label: 'Contacts', value: contacts.length),
                    _DataStat(label: 'Tasks', value: tasks.length),
                    _DataStat(
                        label: 'Activities', value: activities.length),
                  ],
                ),
                const SizedBox(height: Insets.lg),
                Text('Export to CSV',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: Insets.sm),
                Wrap(
                  spacing: Insets.sm,
                  runSpacing: Insets.sm,
                  children: [
                    _ExportButton(
                      label: 'Applications',
                      onExport: () => _exportApplications(applications),
                    ),
                    _ExportButton(
                      label: 'Companies',
                      onExport: () => _exportCompanies(companies),
                    ),
                    _ExportButton(
                      label: 'Agencies',
                      onExport: () => _exportAgencies(agencies),
                    ),
                    _ExportButton(
                      label: 'Contacts',
                      onExport: () => _exportContacts(contacts),
                    ),
                    _ExportButton(
                      label: 'Tasks',
                      onExport: () => _exportTasks(tasks),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          // target database
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Target database',
                    icon: Icons.download_rounded),
                Text(
                  'Companies, agencies, job boards and government portals '
                  'imported from your own research files. Re-importing adds '
                  'anything missing without touching records you have '
                  'edited.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
                const SizedBox(height: Insets.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final repo = ref.read(repositoryProvider);
                      try {
                        final result = await SeedLoader(repo).seed();
                        // refresh the in-memory collections
                        await ref
                            .read(companiesProvider.notifier)
                            .putAll(await repo.getCompanies());
                        await ref
                            .read(agenciesProvider.notifier)
                            .putAll(await repo.getAgencies());
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            content: Text(result.total == 0
                                ? 'Everything is already imported'
                                : 'Imported ${result.total} new records'),
                          ));
                      } catch (e) {
                        messenger
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                              SnackBar(content: Text('Import failed: $e')));
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Re-import target lists'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          // danger zone
          AppCard(
            borderColor: AppColors.danger.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Danger zone',
                    icon: Icons.warning_amber_rounded),
                Text(
                  'Deletes every application, contact, task and activity. '
                  'The imported target lists are restored afterwards.',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                ),
                const SizedBox(height: Insets.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: BorderSide(
                          color: AppColors.danger.withValues(alpha: 0.5)),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await confirmDestructive(
                        context,
                        title: 'Erase all data?',
                        message:
                            'Every application, contact, interview, task and '
                            'history entry will be permanently deleted. '
                            'This cannot be undone.',
                        confirmLabel: 'Erase everything',
                      );
                      if (!ok) return;
                      await ref.read(repositoryProvider).clearAll();
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(const SnackBar(
                          content: Text(
                              'All data erased. Restart the app to reseed.'),
                        ));
                    },
                    icon: const Icon(Icons.delete_forever_rounded, size: 16),
                    label: const Text('Erase all data'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          Center(
            child: Column(
              children: [
                Text('EUROPEAN DREAM',
                    style: theme.textTheme.labelMedium?.copyWith(
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                Text('Track every step towards your European career.',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- CSV export ----------------------------------------------------------

  static Future<void> _save(String name, List<List<Object?>> rows) async {
    final csv = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  static Future<void> _exportApplications(List<JobApplication> items) =>
      _save('european_dream_applications', [
        [
          'Job title', 'Company', 'Country', 'City', 'Role', 'Stage',
          'Source', 'Work authorisation', 'Sponsorship mentioned',
          'Date applied', 'Days since applied', 'Response date',
          'Interview date', 'Skill match', 'Visa probability', 'URL', 'Notes',
        ],
        for (final a in items)
          [
            a.jobTitle,
            a.companyName,
            a.country,
            a.city,
            a.roleCategory,
            a.stage.label,
            a.source.label,
            a.workAuthRequirement.label,
            a.visaSponsorshipMentioned.label,
            a.dateApplied?.toIso8601String() ?? '',
            a.daysSinceApplied ?? '',
            a.responseDate?.toIso8601String() ?? '',
            a.interviewDate?.toIso8601String() ?? '',
            a.skillMatch,
            a.visaProbability,
            a.jobUrl,
            a.notes,
          ],
      ]);

  static Future<void> _exportCompanies(List<Company> items) =>
      _save('european_dream_companies', [
        [
          'Name', 'Country', 'City', 'Industry', 'Type', 'Priority',
          'Relationship', 'Known sponsor', 'Sponsorship likelihood',
          'Career page', 'LinkedIn', 'Notes',
        ],
        for (final c in items)
          [
            c.name,
            c.country,
            c.city,
            c.industry,
            c.type.label,
            c.priority.label,
            c.relationship.label,
            c.knownSponsor.label,
            c.sponsorshipLikelihood,
            c.careerUrl,
            c.linkedinUrl,
            c.notes,
          ],
      ]);

  static Future<void> _exportAgencies(List<RecruitmentAgency> items) =>
      _save('european_dream_agencies', [
        [
          'Name', 'Country', 'Specialisation', 'Priority', 'Status',
          'Match score', 'Website', 'Notes',
        ],
        for (final a in items)
          [
            a.name,
            a.country,
            a.specialization.label,
            a.priority.label,
            a.status.label,
            a.matchScore,
            a.website,
            a.notes,
          ],
      ]);

  static Future<void> _exportContacts(List<NetworkContact> items) =>
      _save('european_dream_contacts', [
        [
          'Name', 'Type', 'Company', 'Role', 'Country', 'Status',
          'LinkedIn', 'Email', 'Date contacted', 'Last response', 'Notes',
        ],
        for (final c in items)
          [
            c.name,
            c.type.label,
            c.companyName,
            c.role,
            c.country,
            c.status.label,
            c.linkedinUrl,
            c.email,
            c.dateContacted?.toIso8601String() ?? '',
            c.lastResponse?.toIso8601String() ?? '',
            c.notes,
          ],
      ]);

  static Future<void> _exportTasks(List<DailyTask> items) =>
      _save('european_dream_tasks', [
        [
          'Date', 'Title', 'Category', 'Priority', 'Status',
          'Completed', 'Target', 'Minutes', 'Log',
        ],
        for (final t in items)
          [
            t.date.toIso8601String().split('T').first,
            t.title,
            t.category.label,
            t.priority.label,
            t.status.label,
            t.completedCount,
            t.targetCount,
            t.actualMinutes,
            t.completionLog.join(' | '),
          ],
      ]);
}

class _NumberSetting extends StatelessWidget {
  const _NumberSetting({
    required this.label,
    required this.value,
    required this.onChanged,
    this.suffix = '',
  });

  final String label;
  final int value;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          IconButton(
            icon: const Icon(Icons.remove_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 54,
            child: Text(
              '$value $suffix',
              textAlign: TextAlign.center,
              style: AppTheme.mono(
                size: 12,
                weight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            onPressed: value < 120 ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _DataStat extends StatelessWidget {
  const _DataStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: AppTheme.mono(
            size: 16,
            weight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ExportButton extends StatefulWidget {
  const _ExportButton({required this.label, required this.onExport});

  final String label;
  final Future<void> Function() onExport;

  @override
  State<_ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<_ExportButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy
          ? null
          : () async {
              final messenger = ScaffoldMessenger.of(context);
              setState(() => _busy = true);
              try {
                await widget.onExport();
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                      content: Text('${widget.label} exported')));
              } catch (e) {
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                      SnackBar(content: Text('Export failed: $e')));
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      icon: _busy
          ? const SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_download_outlined, size: 15),
      label: Text(widget.label),
    );
  }
}
