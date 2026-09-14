import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/countries.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/metrics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/quick_add_sheet.dart';

/// Target-vs-actual allocation across the countries you are pursuing.
class CountriesScreen extends ConsumerWidget {
  const CountriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allocation = ref.watch(countryAllocationProvider);
    final metrics = ref.watch(metricsProvider);
    final companies = ref.watch(companiesProvider);
    final agencies = ref.watch(agenciesProvider);

    final companyCounts = <String, int>{};
    for (final c in companies) {
      if (c.country.isEmpty) continue;
      companyCounts[c.country] = (companyCounts[c.country] ?? 0) + 1;
    }
    final agencyCounts = <String, int>{};
    for (final a in agencies) {
      if (a.country.isEmpty) continue;
      agencyCounts[a.country] = (agencyCounts[a.country] ?? 0) + 1;
    }

    final tracked = allocation.where((a) => a.targetPercent > 0).toList();
    final others =
        allocation.where((a) => a.targetPercent == 0 && a.applications > 0);

    return PageScaffold(
      title: 'Country strategy',
      subtitle: '${metrics.total} applications across '
          '${allocation.where((a) => a.applications > 0).length} countries',
      actions: [
        TextButton.icon(
          onPressed: () => showFormSheet<void>(
            context,
            (_) => const _AllocationEditor(),
            maxWidth: 560,
          ),
          icon: const Icon(Icons.tune_rounded, size: 16),
          label: const Text('Edit targets'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (metrics.total == 0)
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.info),
                  const SizedBox(width: Insets.md),
                  Expanded(
                    child: Text(
                      'Target vs actual becomes meaningful once you have '
                      'logged applications. Your strategy is set up and '
                      'ready.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Insets.md),

          for (final a in tracked)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: _CountryCard(
                allocation: a,
                totalApplications: metrics.total,
                companies: companyCounts[a.country] ?? 0,
                agencies: agencyCounts[a.country] ?? 0,
              ),
            ),

          if (others.isNotEmpty) ...[
            const SizedBox(height: Insets.lg),
            const SectionHeader('Outside your strategy'),
            for (final a in others)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.sm),
                child: _CountryCard(
                  allocation: a,
                  totalApplications: metrics.total,
                  companies: companyCounts[a.country] ?? 0,
                  agencies: agencyCounts[a.country] ?? 0,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.allocation,
    required this.totalApplications,
    required this.companies,
    required this.agencies,
  });

  final CountryAllocation allocation;
  final int totalApplications;
  final int companies;
  final int agencies;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = allocation;
    final gap = ApplicationMetrics.gapToTarget(a, totalApplications);

    final statusColor = a.applications == 0 && a.targetPercent > 0
        ? theme.colorScheme.onSurfaceVariant
        : a.isUnder
            ? AppColors.warning
            : a.isOver
                ? AppColors.info
                : AppColors.success;

    final statusLabel = a.targetPercent == 0
        ? 'No target'
        : a.isUnder
            ? 'Under target'
            : a.isOver
                ? 'Over target'
                : 'On target';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(Countries.flag(a.country),
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.country, style: theme.textTheme.titleMedium),
                    Text(
                      '$companies compan${companies == 1 ? 'y' : 'ies'} · '
                      '$agencies source${agencies == 1 ? '' : 's'} in your list',
                      style:
                          theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              StatusChip(
                  label: statusLabel, color: statusColor, dense: true),
            ],
          ),
          const SizedBox(height: Insets.md),

          // target vs actual bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Target ${_pct(a.targetPercent)}',
                            style: theme.textTheme.bodySmall),
                        const Spacer(),
                        Text(
                          'Actual ${_pct(a.actualPercent)}',
                          style: AppTheme.mono(
                            size: 11,
                            weight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _DualBar(
                      target: a.targetPercent,
                      actual: a.actualPercent,
                      color: statusColor,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: Insets.md),
          Row(
            children: [
              _Metric(label: 'Applied', value: '${a.applications}'),
              _Metric(label: 'Responses', value: '${a.responses}'),
              _Metric(label: 'Interviews', value: '${a.interviews}'),
              _Metric(
                label: 'Interview rate',
                value: a.applications == 0
                    ? '—'
                    : '${(a.interviewRate * 100).toStringAsFixed(0)}%',
                color: a.interviewRate > 0 ? AppColors.success : null,
              ),
            ],
          ),

          if (a.targetPercent > 0 && gap != 0 && totalApplications > 0) ...[
            const SizedBox(height: Insets.md),
            Container(
              padding: const EdgeInsets.all(Insets.md),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(Corners.sm),
              ),
              child: Text(
                gap > 0
                    ? 'You are under-investing in ${a.country}. About '
                        '$gap more application${gap == 1 ? '' : 's'} would '
                        'bring you back to your ${_pct(a.targetPercent)} '
                        'allocation.'
                    : 'You are ${gap.abs()} application'
                        '${gap.abs() == 1 ? '' : 's'} above your '
                        '${a.country} allocation. That is fine if it is '
                        'converting — check the interview rate.',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
              ),
            ),
          ],

          if (Countries.visaNotes[a.country] != null) ...[
            const SizedBox(height: Insets.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flight_takeoff_rounded,
                    size: 13, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(
                    Countries.visaNotes[a.country]!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 11, height: 1.45),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _pct(double v) =>
      v == v.roundToDouble() ? '${v.round()}%' : '${v.toStringAsFixed(1)}%';
}

/// Shows the target as a marker over the actual fill.
class _DualBar extends StatelessWidget {
  const _DualBar({
    required this.target,
    required this.actual,
    required this.color,
  });

  final double target;
  final double actual;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // scale so the larger of the two fills most of the bar
    final max = (target > actual ? target : actual).clamp(1.0, 100.0) * 1.25;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      return SizedBox(
        height: 10,
        child: Stack(
          children: [
            // track
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(Corners.pill),
              ),
            ),
            // actual
            Container(
              height: 10,
              width: (actual / max * width).clamp(0.0, width),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(Corners.pill),
              ),
            ),
            // target marker
            if (target > 0)
              Positioned(
                left: (target / max * width).clamp(0.0, width - 2),
                child: Container(
                  width: 2,
                  height: 10,
                  color: theme.colorScheme.onSurface,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

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
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Editor for the percentage allocation across countries.
class _AllocationEditor extends ConsumerStatefulWidget {
  const _AllocationEditor();

  @override
  ConsumerState<_AllocationEditor> createState() =>
      _AllocationEditorState();
}

class _AllocationEditorState extends ConsumerState<_AllocationEditor> {
  late List<CountryTarget> _targets;

  @override
  void initState() {
    super.initState();
    _targets = [...ref.read(settingsProvider).countryTargets];
  }

  double get _total =>
      _targets.where((t) => t.isActive).fold(0.0, (s, t) => s + t.targetPercent);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final off = (_total - 100).abs() > 0.51;

    return FormSheet(
      title: 'Country allocation',
      subtitle: 'Percentages of your total application volume',
      submitLabel: 'Save allocation',
      onSubmit: () async {
        final navigator = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        await ref
            .read(settingsProvider.notifier)
            .patch((s) => s.copyWith(countryTargets: _targets));
        navigator.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Allocation updated')),
          );
      },
      children: [
        Container(
          padding: const EdgeInsets.all(Insets.md),
          decoration: BoxDecoration(
            color: off
                ? AppColors.warning.withValues(alpha: 0.10)
                : AppColors.success.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Corners.md),
          ),
          child: Row(
            children: [
              Icon(
                off
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                size: 16,
                color: off ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: Insets.md),
              Expanded(
                child: Text(
                  off
                      ? 'Total is ${_total.toStringAsFixed(1)}% — aim for 100%.'
                      : 'Total is ${_total.toStringAsFixed(0)}%.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        for (var i = 0; i < _targets.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: Insets.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: Checkbox(
                    value: _targets[i].isActive,
                    visualDensity: VisualDensity.compact,
                    onChanged: (v) => setState(() {
                      _targets[i] =
                          _targets[i].copyWith(isActive: v ?? false);
                    }),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(Countries.flag(_targets[i].country),
                      style: const TextStyle(fontSize: 15)),
                ),
                Expanded(
                  child: Text(
                    _targets[i].country,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _targets[i].isActive
                          ? null
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 132,
                  child: Slider(
                    value: _targets[i].targetPercent.clamp(0, 50),
                    max: 50,
                    divisions: 100,
                    onChanged: _targets[i].isActive
                        ? (v) => setState(() {
                              _targets[i] = _targets[i]
                                  .copyWith(targetPercent: v);
                            })
                        : null,
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${_targets[i].targetPercent.toStringAsFixed(
                      _targets[i].targetPercent < 1 ? 2 : 0,
                    )}%',
                    textAlign: TextAlign.end,
                    style: AppTheme.mono(
                      size: 11,
                      weight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
