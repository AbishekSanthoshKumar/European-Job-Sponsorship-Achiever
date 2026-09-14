import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/countries.dart';
import '../../core/domain/enums.dart';
import '../../core/domain/models.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/navigation/app_shell.dart';
import '../../shared/widgets/app_card.dart';
import '../companies/companies_screen.dart' show openUrl;

/// The playbook: where to look, in the order that works, plus the
/// government portals, local boards and recruiter databases imported from
/// your reference material.
class ResourcesScreen extends ConsumerWidget {
  const ResourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final agencies = ref.watch(agenciesProvider);

    List<RecruitmentAgency> of(AgencySpecialization s) =>
        agencies.where((a) => a.specialization == s).toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final government = of(AgencySpecialization.governmentPortal);
    final boards = of(AgencySpecialization.jobBoard);
    final databases = of(AgencySpecialization.recruiterDatabase);
    final offerSources =
        agencies.where((a) => a.tags.contains('offer-received-here')).toList();

    return PageScaffold(
      title: 'Resources',
      subtitle: 'Where to look, in priority order',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // strategy summary drawn from the reference material
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('The search order that works',
                    icon: Icons.route_rounded),
                for (final (n, title, body) in _playbook)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Insets.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(Corners.sm),
                          ),
                          child: Text(
                            '$n',
                            style: AppTheme.mono(
                              size: 10,
                              weight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: Insets.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: theme.textTheme.titleSmall),
                              Text(
                                body,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),

          if (offerSources.isNotEmpty) ...[
            _ResourceSection(
              title: 'Sources with a track record',
              subtitle: 'Your notes record offers coming through these',
              items: offerSources,
              accent: AppColors.accent,
            ),
            const SizedBox(height: Insets.lg),
          ],

          _ResourceSection(
            title: 'Government portals',
            subtitle: 'Official, reliable, and usually free of reposts',
            items: government,
            accent: AppColors.success,
          ),
          const SizedBox(height: Insets.lg),

          _ResourceSection(
            title: 'Local job boards',
            subtitle: 'Where domestic candidates actually look',
            items: boards,
            accent: AppColors.info,
          ),
          const SizedBox(height: Insets.lg),

          _ResourceSection(
            title: 'Recruiter databases',
            subtitle: 'Find the person, not just the posting',
            items: databases,
            accent: AppColors.purple,
          ),
        ],
      ),
    );
  }

  /// Distilled from the reference material supplied with the project.
  static const _playbook = <(int, String, String)>[
    (
      1,
      'Company career pages first',
      'Most European companies publish vacancies on their own site before '
          'anywhere else. Fewer applicants, better ATS handling, and you '
          'reach the role before it is crowded. Your Companies list holds '
          'the career-page link for each target.',
    ),
    (
      2,
      'Government portals',
      'Make it in Germany, UWV/Werk.nl, AMS, VDAB, Work in Denmark and the '
          'rest are the most reliable listings in each market, and they '
          'reflect real, funded roles.',
    ),
    (
      3,
      'Local job boards',
      'StepStone, Nationale Vacaturebank, Jobat, karriere.at and their '
          'peers carry roles that never reach the international boards.',
    ),
    (
      4,
      'Recruiter databases, then network',
      'Recruiters know about roles well before they go live. Find them via '
          'Apollo, RocketReach, Hunter, SignalHire or Sales Navigator, then '
          'reach out with something specific. Most candidates never do this, '
          'which is exactly why it works.',
    ),
    (
      5,
      'Visa-sponsor filters last',
      'Sponsor-specific boards are useful, but treat them as a supplement. '
          'The best roles are usually found earlier in this list.',
    ),
  ];
}

class _ResourceSection extends StatelessWidget {
  const _ResourceSection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final List<RecruitmentAgency> items;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('$title (${items.length})', subtitle: subtitle),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0)
                  Divider(height: 1, color: theme.colorScheme.outline),
                InkWell(
                  onTap: items[i].website.isEmpty
                      ? null
                      : () => openUrl(items[i].website),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Insets.lg, vertical: Insets.md),
                    child: Row(
                      children: [
                        if (items[i].country.isNotEmpty) ...[
                          Text(Countries.flag(items[i].country),
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: Insets.md),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(items[i].name,
                                  style: theme.textTheme.bodyMedium),
                              if (items[i].notes.isNotEmpty)
                                Text(
                                  items[i].notes,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (items[i].website.isNotEmpty)
                          Icon(Icons.open_in_new_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
