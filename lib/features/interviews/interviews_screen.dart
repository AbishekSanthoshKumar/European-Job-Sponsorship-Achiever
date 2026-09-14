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
import 'interview_form.dart';

class InterviewsScreen extends ConsumerWidget {
  const InterviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(interviewsProvider);
    final mobile = isMobile(context);

    final upcoming = all
        .where((i) => i.status == InterviewStatus.upcoming)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final past = all
        .where((i) => i.status != InterviewStatus.upcoming)
        .toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    final rated = past
        .where((i) => i.selfRating != null)
        .map((i) => i.selfRating!)
        .toList();
    final avgRating = rated.isEmpty
        ? null
        : rated.reduce((a, b) => a + b) / rated.length;

    return PageScaffold(
      title: 'Interviews',
      subtitle: '${upcoming.length} upcoming · ${past.length} completed'
          '${avgRating == null ? '' : ' · avg ${avgRating.toStringAsFixed(1)}/10'}',
      actions: [
        FilledButton.icon(
          onPressed: () => showInterviewForm(context),
          icon: const Icon(Icons.add_rounded, size: 16),
          label: Text(mobile ? '' : 'Schedule'),
        ),
      ],
      child: all.isEmpty
          ? const Padding(
              padding: EdgeInsets.only(top: Insets.xxxl),
              child: EmptyState(
                icon: Icons.event_rounded,
                title: 'No interviews yet',
                message: 'They will appear here as your applications '
                    'progress. Every one is a data point worth reviewing.',
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (upcoming.isNotEmpty) ...[
                  SectionHeader('Upcoming (${upcoming.length})'),
                  for (final i in upcoming)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Insets.sm),
                      child: _InterviewTile(interview: i),
                    ),
                  const SizedBox(height: Insets.lg),
                ],
                if (past.isNotEmpty) ...[
                  SectionHeader('History (${past.length})'),
                  for (final i in past)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Insets.sm),
                      child: _InterviewTile(interview: i),
                    ),
                ],
              ],
            ),
    );
  }
}

class _InterviewTile extends ConsumerWidget {
  const _InterviewTile({required this.interview});

  final Interview interview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final soon = interview.isUpcoming && interview.daysUntil <= 3;

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      borderColor:
          soon ? AppColors.accent.withValues(alpha: 0.45) : null,
      onTap: () => showFormSheet<void>(
        context,
        (_) => _InterviewDetail(interviewId: interview.id),
        maxWidth: 600,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_rounded,
                  size: 15, color: interview.status.color),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${interview.stage.label} · ${interview.companyName}',
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      [
                        if (interview.roleTitle.isNotEmpty)
                          interview.roleTitle,
                        interview.format.label,
                        '${interview.durationMinutes}m',
                      ].join(' · '),
                      style:
                          theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _when(interview),
                    style: AppTheme.mono(
                      size: 11,
                      weight: FontWeight.w700,
                      color: soon
                          ? AppColors.accent
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (interview.selfRating != null)
                    Text(
                      '${interview.selfRating}/10',
                      style: AppTheme.mono(
                        size: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (interview.isUpcoming) ...[
            const SizedBox(height: Insets.md),
            LabeledProgress(
              label: 'Preparation',
              value: (interview.prepProgress * 100).round(),
              target: 100,
              unit: '%',
              color: interview.prepProgress >= 0.8
                  ? AppColors.success
                  : AppColors.warning,
              compact: true,
            ),
          ],
        ],
      ),
    );
  }

  static String _when(Interview i) {
    if (!i.isUpcoming) {
      return '${i.scheduledAt.day} ${const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][i.scheduledAt.month - 1]}';
    }
    final d = i.daysUntil;
    if (d == 0) return 'Today';
    if (d == 1) return 'Tomorrow';
    if (d < 0) return 'Overdue';
    return 'in ${d}d';
  }
}

class _InterviewDetail extends ConsumerWidget {
  const _InterviewDetail({required this.interviewId});

  final String interviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final interview =
        ref.watch(interviewsProvider.notifier).byId(interviewId);
    if (interview == null) {
      return const Padding(
        padding: EdgeInsets.all(Insets.xxl),
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Interview not found',
          compact: true,
        ),
      );
    }

    final notifier = ref.read(interviewsProvider.notifier);
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
                      Text('${interview.stage.label} interview',
                          style: theme.textTheme.headlineMedium),
                      Text(
                        '${interview.companyName} · '
                        '${_fullDate(interview.scheduledAt)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  onPressed: () {
                    Navigator.of(context).pop();
                    showInterviewForm(context, existing: interview);
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
                  // prep checklist
                  SectionHeader(
                    'Preparation',
                    subtitle:
                        '${(interview.prepProgress * 100).round()}% complete',
                  ),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.md, vertical: Insets.xs),
                    child: Column(
                      children: [
                        for (final entry
                            in interview.prepChecklist.entries)
                          InkWell(
                            onTap: () {
                              final next = Map<String, bool>.from(
                                  interview.prepChecklist);
                              next[entry.key] = !entry.value;
                              notifier.put(
                                  interview.copyWith(prepChecklist: next));
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  Icon(
                                    entry.value
                                        ? Icons.check_box_rounded
                                        : Icons
                                            .check_box_outline_blank_rounded,
                                    size: 18,
                                    color: entry.value
                                        ? AppColors.success
                                        : theme
                                            .colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: Insets.md),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        decoration: entry.value
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: entry.value
                                            ? theme.colorScheme
                                                .onSurfaceVariant
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: Insets.lg),
                  const SectionHeader('Status'),
                  Wrap(
                    spacing: Insets.sm,
                    children: [
                      for (final s in InterviewStatus.values)
                        InkWell(
                          onTap: () => notifier.put(
                              interview.copyWith(status: s)),
                          borderRadius: BorderRadius.circular(Corners.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: Insets.md, vertical: 6),
                            decoration: BoxDecoration(
                              color: interview.status == s
                                  ? s.color.withValues(alpha: 0.16)
                                  : theme.colorScheme.surfaceContainer,
                              borderRadius:
                                  BorderRadius.circular(Corners.sm),
                              border: Border.all(
                                color: interview.status == s
                                    ? s.color
                                    : theme.colorScheme.outline,
                              ),
                            ),
                            child: Text(
                              s.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: interview.status == s
                                    ? s.color
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: Insets.lg),
                  const SectionHeader('Post-interview review'),
                  FilledButton.icon(
                    onPressed: () =>
                        _review(context, ref, interview),
                    icon: const Icon(Icons.rate_review_outlined, size: 16),
                    label: Text(interview.selfRating == null
                        ? 'Add review'
                        : 'Edit review'),
                  ),
                  if (interview.selfRating != null) ...[
                    const SizedBox(height: Insets.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rated ${interview.selfRating}/10',
                              style: theme.textTheme.titleSmall),
                          if (interview.whatWentWell.isNotEmpty) ...[
                            const SizedBox(height: Insets.sm),
                            _ReviewBlock(
                                label: 'What went well',
                                value: interview.whatWentWell),
                          ],
                          if (interview.whatToImprove.isNotEmpty)
                            _ReviewBlock(
                                label: 'What to improve',
                                value: interview.whatToImprove),
                          if (interview.struggledWith.isNotEmpty)
                            _ReviewBlock(
                                label: 'Struggled with',
                                value: interview.struggledWith),
                          if (interview.questionsAsked.isNotEmpty)
                            _ReviewBlock(
                                label: 'Questions asked',
                                value: interview.questionsAsked),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _review(
      BuildContext context, WidgetRef ref, Interview interview) async {
    final result = await showDialog<Interview>(
      context: context,
      builder: (_) => _ReviewDialog(interview: interview),
    );
    if (result == null) return;
    await ref.read(interviewsProvider.notifier).completeReview(result);
    if (context.mounted) showToast(context, 'Review saved');
  }

  static String _fullDate(DateTime d) =>
      '${d.day} ${const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][d.month - 1]} ${d.year}, '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _ReviewBlock extends StatelessWidget {
  const _ReviewBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: Insets.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.bodySmall?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog({required this.interview});

  final Interview interview;

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  late int _rating = widget.interview.selfRating ?? 7;
  late final _wentWell =
      TextEditingController(text: widget.interview.whatWentWell);
  late final _improve =
      TextEditingController(text: widget.interview.whatToImprove);
  late final _struggled =
      TextEditingController(text: widget.interview.struggledWith);
  late final _questions =
      TextEditingController(text: widget.interview.questionsAsked);

  @override
  void dispose() {
    for (final c in [_wentWell, _improve, _struggled, _questions]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('How did it go?', style: theme.textTheme.titleMedium),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Rating', style: theme.textTheme.bodySmall),
                  Expanded(
                    child: Slider(
                      value: _rating.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_rating',
                      onChanged: (v) =>
                          setState(() => _rating = v.round()),
                    ),
                  ),
                  Text('$_rating/10',
                      style: AppTheme.mono(
                          size: 13, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: Insets.sm),
              TextField(
                controller: _wentWell,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'What went well'),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _improve,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'What could improve'),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _struggled,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Topics I struggled with'),
              ),
              const SizedBox(height: Insets.md),
              TextField(
                controller: _questions,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Questions asked'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            widget.interview.copyWith(
              selfRating: _rating,
              whatWentWell: _wentWell.text.trim(),
              whatToImprove: _improve.text.trim(),
              struggledWith: _struggled.text.trim(),
              questionsAsked: _questions.text.trim(),
              status: InterviewStatus.completed,
            ),
          ),
          child: const Text('Save review'),
        ),
      ],
    );
  }
}
