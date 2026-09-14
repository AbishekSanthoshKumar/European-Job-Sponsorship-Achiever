import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/enums.dart';
import '../../core/theme/app_theme.dart';
import '../../features/applications/application_form.dart';
import '../../features/companies/company_form.dart';
import '../../features/interviews/interview_form.dart';
import '../../features/networking/contact_form.dart';
import '../../features/opportunities/opportunity_form.dart';
import '../../features/tasks/task_form.dart';

/// Bottom sheet listing the fast-capture entry points.
Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _QuickAddSheet(),
  );
}

class _QuickAddSheet extends ConsumerWidget {
  const _QuickAddSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final options = <_QuickOption>[
      _QuickOption(
        icon: Icons.bookmark_add_rounded,
        label: 'Opportunity',
        hint: 'Paste a link now, process it later',
        color: TaskCategory.research.color,
        onTap: () => showOpportunityForm(context),
      ),
      _QuickOption(
        icon: Icons.send_rounded,
        label: 'Application',
        hint: 'Log a role you have applied to',
        color: TaskCategory.applications.color,
        onTap: () => showApplicationForm(context),
      ),
      _QuickOption(
        icon: Icons.person_add_rounded,
        label: 'Contact',
        hint: 'Recruiter, hiring manager or engineer',
        color: TaskCategory.networking.color,
        onTap: () => showContactForm(context),
      ),
      _QuickOption(
        icon: Icons.domain_add_rounded,
        label: 'Company',
        hint: 'Add a new target company',
        color: TaskCategory.agencies.color,
        onTap: () => showCompanyForm(context),
      ),
      _QuickOption(
        icon: Icons.event_rounded,
        label: 'Interview',
        hint: 'Schedule an upcoming round',
        color: TaskCategory.preparation.color,
        onTap: () => showInterviewForm(context),
      ),
      _QuickOption(
        icon: Icons.check_circle_outline_rounded,
        label: 'Task',
        hint: 'Add something to today',
        color: TaskCategory.followUps.color,
        onTap: () => showTaskForm(context),
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Insets.lg, 0, Insets.lg, Insets.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  left: Insets.sm, bottom: Insets.md),
              child: Text('Quick add', style: theme.textTheme.titleMedium),
            ),
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth > 520 ? 3 : 2;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: Insets.sm,
                crossAxisSpacing: Insets.sm,
                childAspectRatio: 2.1,
                children: [
                  for (final o in options)
                    _QuickTile(
                      option: o,
                      onTap: () {
                        Navigator.of(context).pop();
                        o.onTap();
                      },
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _QuickOption {
  const _QuickOption({
    required this.icon,
    required this.label,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onTap;
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.option, required this.onTap});

  final _QuickOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(Corners.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Corners.md),
        child: Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Corners.md),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(option.icon, size: 16, color: option.color),
                  const SizedBox(width: Insets.sm),
                  Expanded(
                    child: Text(
                      option.label,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                option.hint,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared frame for the modal forms: title, scrollable body, sticky actions.
class FormSheet extends StatelessWidget {
  const FormSheet({
    super.key,
    required this.title,
    required this.children,
    required this.onSubmit,
    this.submitLabel = 'Save',
    this.subtitle,
    this.canSubmit = true,
    this.onDelete,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final VoidCallback? onDelete;
  final String submitLabel;
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.92;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.xl, Insets.sm, Insets.md, Insets.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.headlineMedium),
                        if (subtitle != null)
                          Text(subtitle!,
                              style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: theme.colorScheme.error,
                      onPressed: onDelete,
                      tooltip: 'Delete',
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
                padding: const EdgeInsets.fromLTRB(
                    Insets.xl, Insets.lg, Insets.xl, Insets.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            Divider(height: 1, color: theme.colorScheme.outline),
            Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: canSubmit ? onSubmit : null,
                      child: Text(submitLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents a form as a bottom sheet on mobile and a dialog on desktop.
Future<T?> showFormSheet<T>(
  BuildContext context,
  WidgetBuilder builder, {
  double maxWidth = 620,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 720;

  if (wide) {
    return showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: builder(context),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: builder,
  );
}

/// Snackbar helper with a consistent look and an optional undo action.
void showToast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  bool isError = false,
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              size: 16,
              color: isError ? theme.colorScheme.error : null,
            ),
            const SizedBox(width: Insets.sm),
            Expanded(child: Text(message)),
          ],
        ),
        action: actionLabel != null && onAction != null
            ? SnackBarAction(label: actionLabel, onPressed: onAction)
            : null,
        duration: const Duration(seconds: 4),
        width: MediaQuery.sizeOf(context).width >= 720 ? 460 : null,
      ),
    );
}

/// Confirmation dialog for destructive actions.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Navigates to a route from within a sheet, closing it first.
void navigateFromSheet(BuildContext context, String route) {
  Navigator.of(context).pop();
  context.go(route);
}
