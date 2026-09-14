import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/countries.dart';
import '../../core/providers/app_providers.dart';
import '../../core/services/metrics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(metricsProvider);
    final resumes = ref.watch(resumesProvider);
    final insights = ref.watch(insightsProvider);
    final wide = !isMobile(context);

    if (metrics.totalSaved == 0) {
      return const PageScaffold(
        title: 'Analytics',
        child: Padding(
          padding: EdgeInsets.only(top: Insets.xxxl),
          child: EmptyState(
            icon: Icons.insights_rounded,
            title: 'No data yet',
            message: 'Analytics unlock as you log applications. Every one '
                'sharpens the picture of what is actually working.',
          ),
        ),
      );
    }

    return PageScaffold(
      title: 'Analytics',
      subtitle: '${metrics.total} applications analysed',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // headline numbers
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth > 900 ? 5 : (c.maxWidth > 560 ? 3 : 2);
            final tiles = [
              StatTile(
                label: 'Applications',
                value: '${metrics.total}',
                sublabel: '${metrics.thisWeek} this week',
                icon: Icons.send_rounded,
              ),
              StatTile(
                label: 'Response rate',
                value: '${(metrics.responseRate * 100).toStringAsFixed(1)}%',
                sublabel: '${metrics.responses} responses',
                color: AppColors.success,
                icon: Icons.reply_rounded,
              ),
              StatTile(
                label: 'Interview rate',
                value: '${(metrics.interviewRate * 100).toStringAsFixed(1)}%',
                sublabel: '${metrics.interviews} interviews',
                color: AppColors.accent,
                icon: Icons.event_rounded,
              ),
              StatTile(
                label: 'Offers',
                value: '${metrics.offers}',
                sublabel:
                    '${(metrics.offerRate * 100).toStringAsFixed(1)}% rate',
                color: metrics.offers > 0 ? AppColors.success : null,
                icon: Icons.emoji_events_rounded,
              ),
              StatTile(
                label: 'With sponsorship',
                value: '${metrics.withSponsorship}',
                sublabel: metrics.total == 0
                    ? ''
                    : '${(metrics.withSponsorship / metrics.total * 100).round()}% of total',
                icon: Icons.flight_takeoff_rounded,
              ),
            ];
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Insets.sm,
              crossAxisSpacing: Insets.sm,
              childAspectRatio: 1.75,
              children: tiles,
            );
          }),
          const SizedBox(height: Insets.lg),

          // funnel
          _FunnelCard(funnel: metrics.funnel),
          const SizedBox(height: Insets.lg),

          // volume over time
          _VolumeCard(counts: metrics.dailyCounts(30)),
          const SizedBox(height: Insets.lg),

          if (wide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SegmentCard(
                      title: 'By country',
                      segments: metrics.byCountry,
                      flagged: true,
                    ),
                  ),
                  const SizedBox(width: Insets.lg),
                  Expanded(
                    child: _SegmentCard(
                      title: 'By role',
                      segments: metrics.byRole,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _SegmentCard(
                title: 'By country',
                segments: metrics.byCountry,
                flagged: true),
            const SizedBox(height: Insets.lg),
            _SegmentCard(title: 'By role', segments: metrics.byRole),
          ],
          const SizedBox(height: Insets.lg),

          if (wide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SegmentCard(
                        title: 'By source', segments: metrics.bySource),
                  ),
                  const SizedBox(width: Insets.lg),
                  Expanded(
                    child: _SegmentCard(
                      title: 'By resume',
                      segments: {
                        for (final e in metrics.byResume.entries)
                          (resumes
                                      .where((r) => r.id == e.key)
                                      .firstOrNull
                                      ?.name ??
                                  'Unspecified'):
                              e.value,
                      },
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _SegmentCard(title: 'By source', segments: metrics.bySource),
            const SizedBox(height: Insets.lg),
            _SegmentCard(
              title: 'By resume',
              segments: {
                for (final e in metrics.byResume.entries)
                  (resumes.where((r) => r.id == e.key).firstOrNull?.name ??
                          'Unspecified'):
                      e.value,
              },
            ),
          ],

          if (insights.isNotEmpty) ...[
            const SizedBox(height: Insets.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('What the data says'),
                  for (final i in insights)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Insets.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child:
                                Icon(i.icon, size: 14, color: i.color),
                          ),
                          const SizedBox(width: Insets.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(i.message,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                if (i.detail.isNotEmpty)
                                  Text(i.detail,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(height: 1.45)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({required this.funnel});

  final List<FunnelStep> funnel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final max = funnel.isEmpty
        ? 1
        : funnel.map((f) => f.count).reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader('Application funnel',
              subtitle: 'Conversion at each stage'),
          for (var i = 0; i < funnel.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.md),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(funnel[i].label,
                        style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius:
                                BorderRadius.circular(Corners.sm),
                          ),
                        ),
                        LayoutBuilder(builder: (context, c) {
                          final ratio =
                              max == 0 ? 0.0 : funnel[i].count / max;
                          return Container(
                            height: 22,
                            width: (c.maxWidth * ratio).clamp(0.0, c.maxWidth),
                            decoration: BoxDecoration(
                              color: AppColors.series[
                                  i % AppColors.series.length],
                              borderRadius:
                                  BorderRadius.circular(Corners.sm),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: Insets.md),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${funnel[i].count}',
                      textAlign: TextAlign.end,
                      style: AppTheme.mono(
                        size: 12,
                        weight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      i == 0 || funnel[i - 1].count == 0
                          ? ''
                          : '${(funnel[i].count / funnel[i - 1].count * 100).round()}%',
                      textAlign: TextAlign.end,
                      style: AppTheme.mono(
                        size: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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

class _VolumeCard extends StatelessWidget {
  const _VolumeCard({required this.counts});

  final Map<DateTime, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = counts.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    final maxY = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b)
            .toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader('Applications per day',
              subtitle: 'Last 30 days · $total total'),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                maxY: maxY < 1 ? 1 : maxY * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY / 3).clamp(1, 999),
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: theme.colorScheme.outline,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: (maxY / 3).clamp(1, 999),
                      getTitlesWidget: (v, meta) => Text(
                        v.toInt().toString(),
                        style: AppTheme.mono(
                          size: 9,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      interval: 7,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        final d = entries[i].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: AppTheme.mono(
                              size: 9,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        theme.colorScheme.surfaceContainerHigh,
                    getTooltipItem: (group, gi, rod, ri) {
                      final d = entries[group.x].key;
                      return BarTooltipItem(
                        '${d.day}/${d.month}\n${rod.toY.toInt()} '
                        'application${rod.toY == 1 ? '' : 's'}',
                        theme.textTheme.bodySmall ?? const TextStyle(),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < entries.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].value.toDouble(),
                          color: entries[i].value == 0
                              ? theme.colorScheme.surfaceContainerHigh
                              : AppColors.primary,
                          width: 6,
                          borderRadius:
                              const BorderRadius.vertical(
                                  top: Radius.circular(2)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.title,
    required this.segments,
    this.flagged = false,
  });

  final String title;
  final Map<String, SegmentStats> segments;
  final bool flagged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = segments.values.toList()
      ..sort((a, b) => b.applications.compareTo(a.applications));

    if (rows.isEmpty) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title),
            Text('No data yet.', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    final max = rows.first.applications;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                width: 38,
                child: Text('APPS',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontSize: 9, letterSpacing: 0.6)),
              ),
              SizedBox(
                width: 44,
                child: Text('RESP',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontSize: 9, letterSpacing: 0.6)),
              ),
              SizedBox(
                width: 44,
                child: Text('INT',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(fontSize: 9, letterSpacing: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: Insets.sm),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flagged
                              ? '${Countries.flag(rows[i].label)} ${rows[i].label}'
                              : rows[i].label,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        LayoutBuilder(builder: (context, c) {
                          final ratio =
                              max == 0 ? 0.0 : rows[i].applications / max;
                          return Stack(
                            children: [
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                height: 4,
                                width: (c.maxWidth * ratio)
                                    .clamp(0.0, c.maxWidth),
                                decoration: BoxDecoration(
                                  color: AppColors.series[
                                      i % AppColors.series.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: Insets.sm),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${rows[i].applications}',
                      textAlign: TextAlign.end,
                      style: AppTheme.mono(
                        size: 11,
                        weight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      rows[i].applications == 0
                          ? '—'
                          : '${(rows[i].responseRate * 100).round()}%',
                      textAlign: TextAlign.end,
                      style: AppTheme.mono(
                        size: 11,
                        color: rows[i].responseRate > 0
                            ? AppColors.success
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      rows[i].applications == 0
                          ? '—'
                          : '${(rows[i].interviewRate * 100).round()}%',
                      textAlign: TextAlign.end,
                      style: AppTheme.mono(
                        size: 11,
                        color: rows[i].interviewRate > 0
                            ? AppColors.accent
                            : theme.colorScheme.onSurfaceVariant,
                      ),
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
