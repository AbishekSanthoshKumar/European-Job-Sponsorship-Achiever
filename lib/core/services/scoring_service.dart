import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/settings.dart';

/// Bucketed label for a 0-100 opportunity score.
enum OpportunityTier {
  exceptional('Exceptional Opportunity', 90),
  high('High Priority', 75),
  good('Good Opportunity', 60),
  medium('Medium Priority', 40),
  low('Low Priority', 0);

  const OpportunityTier(this.label, this.min);
  final String label;
  final int min;

  static OpportunityTier of(double score) {
    for (final t in values) {
      if (score >= t.min) return t;
    }
    return low;
  }
}

/// Computes the configurable 0-100 opportunity score for an application.
class ScoringService {
  const ScoringService(this.settings);

  final AppSettings settings;

  /// Country priority normalised against the highest allocation, so the
  /// top market scores 1.0 and unlisted countries score 0.
  double countryScore(String country) {
    final targets = settings.activeCountries;
    if (targets.isEmpty) return 0.5;
    final maxPct = targets
        .map((c) => c.targetPercent)
        .fold<double>(0, (a, b) => a > b ? a : b);
    if (maxPct <= 0) return 0.5;
    final match = targets.where(
      (c) => c.country.toLowerCase() == country.trim().toLowerCase(),
    );
    if (match.isEmpty) return 0.1;
    return (match.first.targetPercent / maxPct).clamp(0.0, 1.0);
  }

  double roleScore(String role) {
    final targets = settings.activeRoles;
    if (targets.isEmpty || role.trim().isEmpty) return 0.5;
    final maxPct = targets
        .map((r) => r.targetPercent)
        .fold<double>(0, (a, b) => a > b ? a : b);
    if (maxPct <= 0) return 0.5;
    final needle = role.trim().toLowerCase();
    for (final r in targets) {
      if (r.role.toLowerCase() == needle) {
        return (r.targetPercent / maxPct).clamp(0.0, 1.0);
      }
    }
    // partial match: "Senior Backend Engineer" -> "Backend Engineer"
    for (final r in targets) {
      if (needle.contains(r.role.toLowerCase()) ||
          r.role.toLowerCase().contains(needle)) {
        return (r.targetPercent / maxPct).clamp(0.0, 1.0) * 0.9;
      }
    }
    return 0.3;
  }

  /// Blends the explicit work-authorisation field with the manual 0-10
  /// visa-probability rating and any known-sponsor signal.
  double visaScore(JobApplication app, {Company? company}) {
    final fromRequirement = app.workAuthRequirement.visaScore;
    final fromRating = (app.visaProbability / 10).clamp(0.0, 1.0);

    var sponsorSignal = 0.5;
    final known = company?.knownSponsor ?? app.companyKnownToSponsor;
    if (known == TriState.yes) sponsorSignal = 1.0;
    if (known == TriState.no) sponsorSignal = 0.15;

    if (app.visaSponsorshipMentioned == TriState.yes) {
      sponsorSignal = (sponsorSignal + 1.0) / 2;
    } else if (app.visaSponsorshipMentioned == TriState.no) {
      sponsorSignal = sponsorSignal * 0.4;
    }

    return (fromRequirement * 0.5 + fromRating * 0.25 + sponsorSignal * 0.25)
        .clamp(0.0, 1.0);
  }

  double companyScore(JobApplication app, {Company? company}) {
    if (company != null) return company.priority.score;
    return (app.companyPriorityScore / 10).clamp(0.0, 1.0);
  }

  /// Salary is only a mild signal — presence of a stated range is itself
  /// a positive, since it correlates with transparent, structured employers.
  double salaryScore(JobApplication app) {
    final max = app.salaryMax ?? app.salaryMin;
    if (max == null || max <= 0) return 0.4;
    // 40k -> 0, 120k+ -> 1
    return ((max - 40000) / 80000).clamp(0.0, 1.0);
  }

  /// The headline 0-100 score.
  double score(JobApplication app, {Company? company}) {
    final w = settings.scoreWeights;
    final skill =
        ((app.skillMatch + app.experienceMatch) / 20).clamp(0.0, 1.0);

    final raw = skill * w.skillMatch +
        visaScore(app, company: company) * w.visaProbability +
        countryScore(app.country) * w.countryPriority +
        companyScore(app, company: company) * w.companyPriority +
        roleScore(app.roleCategory) * w.rolePriority +
        salaryScore(app) * w.salaryOther;

    final total = w.total;
    final normalised = total > 0 ? raw / total : raw;
    return (normalised * 100).clamp(0.0, 100.0);
  }

  OpportunityTier tier(JobApplication app, {Company? company}) =>
      OpportunityTier.of(score(app, company: company));

  /// Component breakdown for the score-explanation UI.
  List<ScoreComponent> breakdown(JobApplication app, {Company? company}) {
    final w = settings.scoreWeights;
    return [
      ScoreComponent(
        'Skill & experience match',
        ((app.skillMatch + app.experienceMatch) / 20).clamp(0.0, 1.0),
        w.skillMatch,
      ),
      ScoreComponent(
        'Visa probability',
        visaScore(app, company: company),
        w.visaProbability,
      ),
      ScoreComponent(
        'Country priority',
        countryScore(app.country),
        w.countryPriority,
      ),
      ScoreComponent(
        'Company priority',
        companyScore(app, company: company),
        w.companyPriority,
      ),
      ScoreComponent(
        'Role priority',
        roleScore(app.roleCategory),
        w.rolePriority,
      ),
      ScoreComponent('Salary & other', salaryScore(app), w.salaryOther),
    ];
  }
}

class ScoreComponent {
  const ScoreComponent(this.label, this.value, this.weight);

  final String label;

  /// 0-1 raw component value.
  final double value;

  /// 0-1 weight applied to it.
  final double weight;

  /// Points this component contributes to the final 0-100 score.
  double get contribution => value * weight * 100;
}
