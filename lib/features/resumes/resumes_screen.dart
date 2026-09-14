import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/quick_add_sheet.dart';

/// Compares resume variants by the response rate they actually produce.
class ResumesScreen extends ConsumerWidget {
  const ResumesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final resumes = ref.watch(resumesProvider);
    final metrics = ref.watch(metricsProvider);
    final stats = metrics.byResume;

    // best performer needs a meaningful sample before it is called out
    final eligible = resumes
        .where((r) => (stats[r.id]?.applications ?? 0) >= 20)
        .toList()
      ..sort((a, b) => (stats[b.id]?.responseRate ?? 0)
          .compareTo(stats[a.id]?.responseRate ?? 0));

    return PageScaffold(
      title: 'Resumes',
      subtitle: '${resumes.length} versions · '
          '${metrics.total} applications tracked',
      actions: [
        FilledButton.icon(
          onPressed: () => showFormSheet<void>(
            context,
            (_) => const _ResumeForm(),
            maxWidth: 520,
          ),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(isMobile(context) ? '' : 'Add'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (eligible.length >= 2)
            AppCard(
              borderColor: AppColors.success.withValues(alpha: 0.4),
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded,
                      size: 16, color: AppColors.success),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Text(
                      '${eligible.first.name} is your best performer at '
                      '${((stats[eligible.first.id]?.responseRate ?? 0) * 100).toStringAsFixed(0)}% '
                      'response rate, versus '
                      '${((stats[eligible.last.id]?.responseRate ?? 0) * 100).toStringAsFixed(0)}% '
                      'for ${eligible.last.name}.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            )
          else
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.science_outlined,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Text(
                      'Send at least 20 applications with two different '
                      'resumes before comparing. Below that, the difference '
                      'is noise.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Insets.lg),

          for (final r in resumes)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: _ResumeCard(
                resume: r,
                applications: stats[r.id]?.applications ?? 0,
                responses: stats[r.id]?.responses ?? 0,
                interviews: stats[r.id]?.interviews ?? 0,
              ),
            ),

          if (resumes.isEmpty)
            const EmptyState(
              icon: Icons.description_rounded,
              title: 'No resumes yet',
              message: 'Track each version so you can see which one actually '
                  'gets replies.',
            ),
        ],
      ),
    );
  }
}

class _ResumeCard extends ConsumerWidget {
  const _ResumeCard({
    required this.resume,
    required this.applications,
    required this.responses,
    required this.interviews,
  });

  final Resume resume;
  final int applications;
  final int responses;
  final int interviews;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rate = applications == 0 ? 0.0 : responses / applications;
    final enough = applications >= 20;

    return AppCard(
      onTap: () => showFormSheet<void>(
        context,
        (_) => _ResumeForm(existing: resume),
        maxWidth: 520,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(resume.name, style: theme.textTheme.titleMedium),
                    Text(
                      'v${resume.versionNumber} · updated '
                      '${_date(resume.lastUpdated)}',
                      style:
                          theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    applications == 0
                        ? '—'
                        : '${(rate * 100).toStringAsFixed(0)}%',
                    style: AppTheme.mono(
                      size: 18,
                      weight: FontWeight.w700,
                      color: !enough
                          ? theme.colorScheme.onSurfaceVariant
                          : rate >= 0.15
                              ? AppColors.success
                              : rate >= 0.07
                                  ? AppColors.accent
                                  : AppColors.warning,
                    ),
                  ),
                  Text('response rate',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          Row(
            children: [
              _Stat(label: 'Applications', value: '$applications'),
              _Stat(label: 'Responses', value: '$responses'),
              _Stat(label: 'Interviews', value: '$interviews'),
            ],
          ),
          if (resume.targetRoles.isNotEmpty) ...[
            const SizedBox(height: Insets.md),
            Wrap(
              spacing: Insets.sm,
              runSpacing: Insets.xs,
              children: [
                for (final role in resume.targetRoles)
                  StatusChip(
                    label: role,
                    color: theme.colorScheme.onSurfaceVariant,
                    dense: true,
                  ),
              ],
            ),
          ],
          if (!enough && applications > 0) ...[
            const SizedBox(height: Insets.sm),
            Text(
              '${20 - applications} more applications before this rate is '
              'statistically meaningful.',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.day} ${const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][d.month - 1]} ${d.year}';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTheme.mono(
              size: 14,
              weight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ResumeForm extends ConsumerStatefulWidget {
  const _ResumeForm({this.existing});

  final Resume? existing;

  @override
  ConsumerState<_ResumeForm> createState() => _ResumeFormState();
}

class _ResumeFormState extends ConsumerState<_ResumeForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _roles = TextEditingController(
      text: widget.existing?.targetRoles.join(', ') ?? '');
  late final _skills = TextEditingController(
      text: widget.existing?.skillsEmphasized.join(', ') ?? '');
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late final _path = TextEditingController(text: widget.existing?.filePath);
  late int _version = widget.existing?.versionNumber ?? 1;

  @override
  void dispose() {
    for (final c in [_name, _roles, _skills, _notes, _path]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return FormSheet(
      title: isEdit ? 'Edit resume' : 'Add resume',
      submitLabel: isEdit ? 'Save changes' : 'Add resume',
      canSubmit: _name.text.trim().isNotEmpty,
      onDelete: isEdit
          ? () async {
              final navigator = Navigator.of(context);
              final ok = await confirmDestructive(
                context,
                title: 'Delete resume?',
                message: 'Applications that used it keep their history but '
                    'lose the link.',
              );
              if (!ok) return;
              await ref
                  .read(resumesProvider.notifier)
                  .delete(widget.existing!.id);
              navigator.pop();
            }
          : null,
      onSubmit: () async {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        final now = DateTime.now();
        await ref.read(resumesProvider.notifier).put(Resume(
              id: widget.existing?.id ?? uuid.v4(),
              name: _name.text.trim(),
              versionNumber: _version,
              filePath: _path.text.trim(),
              targetRoles: _split(_roles.text),
              skillsEmphasized: _split(_skills.text),
              notes: _notes.text.trim(),
              lastUpdated: now,
              createdAt: widget.existing?.createdAt ?? now,
            ));
        if (isEdit) {
          await ref.read(activityProvider.notifier).log(
                type: ActivityType.resumeUpdated,
                title: 'Updated ${_name.text.trim()}',
              );
        }
        navigator.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text(isEdit ? 'Resume updated' : 'Resume added')));
      },
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
          label: 'Target roles',
          hint: 'Comma separated',
          child: TextField(
            controller: _roles,
            decoration: const InputDecoration(
                hintText: 'Backend Engineer, Full Stack Engineer'),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Skills emphasised',
          hint: 'Comma separated',
          child: TextField(
            controller: _skills,
            decoration:
                const InputDecoration(hintText: 'Python, AWS, PostgreSQL'),
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Version',
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, size: 16),
                onPressed: _version > 1
                    ? () => setState(() => _version--)
                    : null,
              ),
              Text('v$_version',
                  style: AppTheme.mono(size: 14, weight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add_rounded, size: 16),
                onPressed: () => setState(() => _version++),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'File reference',
          hint: 'Path or link to the document',
          child: TextField(controller: _path),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Notes',
          child: TextField(controller: _notes, maxLines: 3),
        ),
      ],
    );
  }

  static List<String> _split(String raw) => raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
}
