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
import '../companies/companies_screen.dart' show openUrl;

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final sorted = [...projects]..sort((a, b) {
        if (a.isFlagship != b.isFlagship) return a.isFlagship ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });

    final readiness = projects.isEmpty
        ? 0.0
        : projects.map((p) => p.progress).reduce((a, b) => a + b) /
            projects.length;

    return PageScaffold(
      title: 'Portfolio',
      subtitle: projects.isEmpty
          ? 'No projects tracked yet'
          : '${projects.length} projects · '
              '${(readiness * 100).round()}% overall readiness',
      actions: [
        FilledButton.icon(
          onPressed: () => showFormSheet<void>(
            context,
            (_) => const _ProjectForm(),
            maxWidth: 560,
          ),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(isMobile(context) ? '' : 'Add project'),
        ),
      ],
      child: projects.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: Insets.xxxl),
              child: EmptyState(
                icon: Icons.code_rounded,
                title: 'No projects yet',
                message:
                    'A single strong, deployed project with a clear README '
                    'does more for a European application than three '
                    'half-finished ones.',
                action: FilledButton.icon(
                  onPressed: () => showFormSheet<void>(
                    context,
                    (_) => const _ProjectForm(),
                    maxWidth: 560,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add your first project'),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in sorted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.sm),
                    child: _ProjectCard(project: p),
                  ),
              ],
            ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});

  final PortfolioProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notifier = ref.read(projectsProvider.notifier);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (project.isFlagship) ...[
                const Icon(Icons.star_rounded,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: Insets.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.name, style: theme.textTheme.titleMedium),
                    if (project.description.isNotEmpty)
                      Text(
                        project.description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              StatusChip(
                label: project.status.label,
                color: project.status.color,
                dense: true,
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 17),
                visualDensity: VisualDensity.compact,
                onPressed: () => showFormSheet<void>(
                  context,
                  (_) => _ProjectForm(existing: project),
                  maxWidth: 560,
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          LabeledProgress(
            label: 'Completion',
            value: (project.progress * 100).round(),
            target: 100,
            unit: '%',
            color: project.status.color,
            compact: true,
          ),
          const SizedBox(height: Insets.md),

          // checklist
          Wrap(
            spacing: Insets.sm,
            runSpacing: Insets.sm,
            children: [
              for (final entry in project.tasks.entries)
                InkWell(
                  onTap: () {
                    final next = Map<String, bool>.from(project.tasks);
                    next[entry.key] = !entry.value;
                    notifier.put(project.copyWith(tasks: next));
                  },
                  borderRadius: BorderRadius.circular(Corners.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.sm, vertical: 5),
                    decoration: BoxDecoration(
                      color: entry.value
                          ? AppColors.success.withValues(alpha: 0.12)
                          : theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(Corners.sm),
                      border: Border.all(
                        color: entry.value
                            ? AppColors.success.withValues(alpha: 0.5)
                            : theme.colorScheme.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          entry.value
                              ? Icons.check_rounded
                              : Icons.remove_rounded,
                          size: 12,
                          color: entry.value
                              ? AppColors.success
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.key,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: entry.value
                                ? AppColors.success
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          if (project.technologies.isNotEmpty) ...[
            const SizedBox(height: Insets.md),
            Wrap(
              spacing: Insets.sm,
              runSpacing: Insets.xs,
              children: [
                for (final t in project.technologies)
                  Text(
                    t,
                    style: AppTheme.mono(
                      size: 10.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],

          if (project.githubUrl.isNotEmpty ||
              project.demoUrl.isNotEmpty) ...[
            const SizedBox(height: Insets.md),
            Row(
              children: [
                if (project.githubUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => openUrl(project.githubUrl),
                    icon: const Icon(Icons.code_rounded, size: 14),
                    label: const Text('GitHub'),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                if (project.demoUrl.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => openUrl(project.demoUrl),
                    icon: const Icon(Icons.launch_rounded, size: 14),
                    label: const Text('Demo'),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectForm extends ConsumerStatefulWidget {
  const _ProjectForm({this.existing});

  final PortfolioProject? existing;

  @override
  ConsumerState<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends ConsumerState<_ProjectForm> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _description =
      TextEditingController(text: widget.existing?.description);
  late final _tech = TextEditingController(
      text: widget.existing?.technologies.join(', ') ?? '');
  late final _github =
      TextEditingController(text: widget.existing?.githubUrl);
  late final _demo = TextEditingController(text: widget.existing?.demoUrl);
  late ProjectStatus _status =
      widget.existing?.status ?? ProjectStatus.inProgress;
  late bool _flagship = widget.existing?.isFlagship ?? false;

  @override
  void dispose() {
    for (final c in [_name, _description, _tech, _github, _demo]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return FormSheet(
      title: isEdit ? 'Edit project' : 'Add project',
      submitLabel: isEdit ? 'Save changes' : 'Add project',
      canSubmit: _name.text.trim().isNotEmpty,
      onDelete: isEdit
          ? () async {
              final navigator = Navigator.of(context);
              final ok = await confirmDestructive(
                context,
                title: 'Delete project?',
                message: 'This cannot be undone.',
              );
              if (!ok) return;
              await ref
                  .read(projectsProvider.notifier)
                  .delete(widget.existing!.id);
              navigator.pop();
            }
          : null,
      onSubmit: () async {
        final navigator = Navigator.of(context);
        final now = DateTime.now();
        await ref.read(projectsProvider.notifier).put(PortfolioProject(
              id: widget.existing?.id ?? uuid.v4(),
              name: _name.text.trim(),
              description: _description.text.trim(),
              technologies: _split(_tech.text),
              githubUrl: _github.text.trim(),
              demoUrl: _demo.text.trim(),
              status: _status,
              isFlagship: _flagship,
              tasks: widget.existing?.tasks ??
                  {
                    for (final t in PortfolioProject.defaultTasks) t: false,
                  },
              notes: widget.existing?.notes ?? '',
              createdAt: widget.existing?.createdAt ?? now,
              updatedAt: now,
            ));
        navigator.pop();
      },
      children: [
        LabeledField(
          label: 'Project name',
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
          label: 'Description',
          child: TextField(controller: _description, maxLines: 2),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Status',
          child: ChipSelector<ProjectStatus>(
            values: ProjectStatus.values,
            selected: _status,
            labelBuilder: (s) => s.label,
            colorBuilder: (s) => s.color,
            onSelected: (s) => setState(() => _status = s),
          ),
        ),
        const SizedBox(height: Insets.lg),
        SwitchListTile.adaptive(
          value: _flagship,
          onChanged: (v) => setState(() => _flagship = v),
          title: Text('Flagship project',
              style: Theme.of(context).textTheme.bodyMedium),
          subtitle: Text('The one you lead with in applications',
              style: Theme.of(context).textTheme.bodySmall),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Technologies',
          hint: 'Comma separated',
          child: TextField(controller: _tech),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'GitHub URL',
          child: TextField(
            controller: _github,
            keyboardType: TextInputType.url,
          ),
        ),
        const SizedBox(height: Insets.lg),
        LabeledField(
          label: 'Demo URL',
          child: TextField(
            controller: _demo,
            keyboardType: TextInputType.url,
          ),
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
