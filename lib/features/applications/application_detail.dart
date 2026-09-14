import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/countries.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/scoring_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/quick_add_sheet.dart';
import '../interviews/interview_form.dart';
import 'application_form.dart';

Future<void> showApplicationDetail(BuildContext context, String id) {
  return showFormSheet<void>(
    context,
    (_) => _ApplicationDetail(id: id),
    maxWidth: 680,
  );
}

class _ApplicationDetail extends ConsumerWidget {
  const _ApplicationDetail({required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final app = ref.watch(applicationsProvider.notifier).byId(id);

    if (app == null) {
      return const Padding(
        padding: EdgeInsets.all(Insets.xxl),
        child: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Application not found',
          compact: true,
        ),
      );
    }

    final settings = ref.watch(settingsProvider);
    final scoring = ref.watch(scoringProvider);
    final company = ref.watch(companyByIdProvider)[app.companyId];
    final score = scoring.score(app, company: company);
    final breakdown = scoring.breakdown(app, company: company);
    final health = app.health(
      waitingAfter: settings.agingWaitingDays,
      followUpAfter: settings.agingFollowUpDays,
      staleAfter: settings.agingStaleDays,
    );
    final interviews = ref
        .watch(interviewsProvider)
        .where((i) => i.applicationId == app.id)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final activities = ref
        .watch(activityTimelineProvider)
        .where((e) => e.applicationId == app.id)
        .toList();

    final media = MediaQuery.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Insets.xl, Insets.lg, Insets.md, Insets.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.jobTitle,
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(Countries.flag(app.country),
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              [
                                app.companyName,
                                if (app.city.isNotEmpty) app.city,
                                app.country,
                              ].join(' · '),
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  tooltip: 'Edit',
                  onPressed: () {
                    Navigator.of(context).pop();
                    showApplicationForm(context, existing: app);
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
                  // score + health
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreCard(
                          score: score,
                          breakdown: breakdown,
                        ),
                      ),
                      const SizedBox(width: Insets.md),
                      Expanded(
                        child: _HealthCard(
                            application: app, health: health),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.lg),

                  // stage control
                  const SectionHeader('Stage'),
                  _StagePicker(application: app),
                  const SizedBox(height: Insets.lg),

                  // key facts
                  const SectionHeader('Details'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.lg, vertical: Insets.sm),
                    child: Column(
                      children: [
                        _DetailRow(
                            label: 'Role', value: app.roleCategory),
                        _DetailRow(
                            label: 'Source', value: app.source.label),
                        _DetailRow(
                            label: 'Seniority', value: app.seniority.label),
                        _DetailRow(
                            label: 'Work mode', value: app.workMode.label),
                        if (app.salaryMin != null || app.salaryMax != null)
                          _DetailRow(
                            label: 'Salary',
                            value: _salary(app),
                          ),
                        _DetailRow(
                          label: 'Work authorisation',
                          value: app.workAuthRequirement.label,
                          valueColor: app.workAuthRequirement.color,
                        ),
                        _DetailRow(
                          label: 'Sponsorship mentioned',
                          value: app.visaSponsorshipMentioned.label,
                          valueColor: app.visaSponsorshipMentioned.color,
                        ),
                        _DetailRow(
                          label: 'Relocation',
                          value: app.relocationAssistance.label,
                          valueColor: app.relocationAssistance.color,
                        ),
                        if (app.resumeId != null)
                          _DetailRow(
                            label: 'Resume',
                            value: ref
                                    .watch(resumesProvider)
                                    .where((r) => r.id == app.resumeId)
                                    .firstOrNull
                                    ?.name ??
                                'Unknown',
                          ),
                        _DetailRow(
                          label: 'Cover letter',
                          value: app.coverLetterUsed ? 'Yes' : 'No',
                        ),
                      ],
                    ),
                  ),

                  if (app.jobUrl.isNotEmpty) ...[
                    const SizedBox(height: Insets.md),
                    OutlinedButton.icon(
                      onPressed: () => _open(app.jobUrl),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text('Open job posting'),
                    ),
                  ],

                  // dates
                  const SizedBox(height: Insets.lg),
                  const SectionHeader('Dates'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.lg, vertical: Insets.sm),
                    child: Column(
                      children: [
                        _DetailRow(
                            label: 'Discovered',
                            value: _date(app.dateDiscovered)),
                        if (app.dateApplied != null)
                          _DetailRow(
                              label: 'Applied',
                              value: _date(app.dateApplied!)),
                        if (app.responseDate != null)
                          _DetailRow(
                              label: 'First response',
                              value: _date(app.responseDate!)),
                        if (app.interviewDate != null)
                          _DetailRow(
                              label: 'Interview',
                              value: _date(app.interviewDate!)),
                        if (app.outcomeDate != null)
                          _DetailRow(
                              label: 'Outcome',
                              value: _date(app.outcomeDate!)),
                      ],
                    ),
                  ),

                  // interviews
                  const SizedBox(height: Insets.lg),
                  SectionHeader(
                    'Interviews',
                    action: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        showInterviewForm(context, application: app);
                      },
                      icon: const Icon(Icons.add_rounded, size: 15),
                      label: const Text('Schedule'),
                    ),
                  ),
                  if (interviews.isEmpty)
                    Text('No interviews scheduled yet.',
                        style: theme.textTheme.bodySmall)
                  else
                    for (final i in interviews)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Insets.sm),
                        child: AppCard(
                          padding: const EdgeInsets.all(Insets.md),
                          child: Row(
                            children: [
                              Icon(Icons.event_rounded,
                                  size: 15, color: i.status.color),
                              const SizedBox(width: Insets.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(i.stage.label,
                                        style: theme.textTheme.bodyMedium),
                                    Text(
                                      '${_date(i.scheduledAt)} · '
                                      '${i.format.label}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip(
                                label: i.status.label,
                                color: i.status.color,
                                dense: true,
                              ),
                            ],
                          ),
                        ),
                      ),

                  // visa notes & notes
                  if (app.visaNotes.isNotEmpty) ...[
                    const SizedBox(height: Insets.lg),
                    const SectionHeader('Visa notes'),
                    AppCard(
                      child: Text(app.visaNotes,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],
                  if (app.notes.isNotEmpty) ...[
                    const SizedBox(height: Insets.lg),
                    const SectionHeader('Notes'),
                    AppCard(
                      child: Text(app.notes,
                          style: theme.textTheme.bodyMedium),
                    ),
                  ],

                  // history
                  if (activities.isNotEmpty) ...[
                    const SizedBox(height: Insets.lg),
                    const SectionHeader('History'),
                    for (final e in activities.take(10))
                      Padding(
                        padding: const EdgeInsets.only(bottom: Insets.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(e.type.icon,
                                  size: 13, color: e.type.color),
                            ),
                            const SizedBox(width: Insets.md),
                            Expanded(
                              child: Text(e.title,
                                  style: theme.textTheme.bodySmall),
                            ),
                            Text(
                              _date(e.timestamp),
                              style: AppTheme.mono(
                                size: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),

          // footer actions
          Divider(height: 1, color: theme.colorScheme.outline),
          Padding(
            padding: const EdgeInsets.all(Insets.lg),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final ok = await confirmDestructive(
                      context,
                      title: 'Delete application?',
                      message:
                          'This removes ${app.jobTitle} at ${app.companyName} '
                          'and its history. This cannot be undone.',
                    );
                    if (!ok || !context.mounted) return;
                    await ref
                        .read(applicationsProvider.notifier)
                        .delete(app.id);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    showToast(context, 'Application deleted');
                  },
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showApplicationForm(context, existing: app);
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _salary(JobApplication a) {
    final min = a.salaryMin;
    final max = a.salaryMax;
    String fmt(int v) => '${(v / 1000).toStringAsFixed(0)}k';
    if (min != null && max != null) {
      return '${fmt(min)} – ${fmt(max)} ${a.currency}';
    }
    return '${fmt(min ?? max!)} ${a.currency}';
  }

  static String _date(DateTime d) =>
      '${d.day} ${const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][d.month - 1]} ${d.year}';

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.breakdown});

  final double score;
  final List<ScoreComponent> breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = score >= 75
        ? AppColors.success
        : score >= 60
            ? AppColors.accent
            : score >= 40
                ? AppColors.warning
                : AppColors.danger;

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OPPORTUNITY SCORE',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.sm),
          Text(
            score.toStringAsFixed(0),
            style: AppTheme.mono(
              size: 26,
              weight: FontWeight.w700,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: Insets.sm),
          for (final c in breakdown)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.label,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 10.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '+${c.contribution.toStringAsFixed(0)}',
                    style: AppTheme.mono(
                      size: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.application, required this.health});

  final JobApplication application;
  final ApplicationHealth health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = application.daysSinceApplied;

    return AppCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS',
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.sm),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                    color: health.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: Text(
                  health.label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: health.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          if (days != null)
            Text(
              'Applied $days day${days == 1 ? '' : 's'} ago',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            )
          else
            Text(
              'Not yet submitted',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          if (application.nextFollowUpDate != null) ...[
            const SizedBox(height: 3),
            Text(
              'Follow-up due '
              '${_ApplicationDetail._date(application.nextFollowUpDate!)}',
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _StagePicker extends ConsumerWidget {
  const _StagePicker({required this.application});

  final JobApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(applicationsProvider.notifier);

    return Wrap(
      spacing: Insets.sm,
      runSpacing: Insets.sm,
      children: [
        for (final stage in [
          ...ApplicationStage.pipeline,
          ...ApplicationStage.outcomes,
        ])
          InkWell(
            onTap: () => notifier.moveToStage(application, stage),
            borderRadius: BorderRadius.circular(Corners.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: Insets.md, vertical: 6),
              decoration: BoxDecoration(
                color: application.stage == stage
                    ? stage.color.withValues(alpha: 0.16)
                    : Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(Corners.sm),
                border: Border.all(
                  color: application.stage == stage
                      ? stage.color
                      : Theme.of(context).colorScheme.outline,
                  width: application.stage == stage ? 1.4 : 1,
                ),
              ),
              child: Text(
                stage.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: application.stage == stage
                          ? stage.color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: application.stage == stage
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
