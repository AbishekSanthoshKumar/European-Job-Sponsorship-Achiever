import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/settings.dart';

/// Monday-based start of the week containing [d].
DateTime startOfWeek(DateTime d) {
  final day = dayOf(d);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month);

/// A generic count/rate row used by every performance breakdown.
class SegmentStats {
  SegmentStats(this.label);

  final String label;
  int applications = 0;
  int responses = 0;
  int interviews = 0;
  int offers = 0;
  int rejections = 0;

  double get responseRate =>
      applications == 0 ? 0 : responses / applications;
  double get interviewRate =>
      applications == 0 ? 0 : interviews / applications;
  double get offerRate => applications == 0 ? 0 : offers / applications;

  void record(JobApplication a) {
    // a closed application still counts if its dateApplied proves it was sent
    if (!a.stage.hasApplied && a.dateApplied == null) return;
    applications++;
    // A closed application can still have progressed before closing, so the
    // recorded milestones are inferred from dates as well as current stage.
    if (a.stage.isResponse || a.responseDate != null) responses++;
    if (a.stage.isInterview || a.interviewDate != null) interviews++;
    if (a.stage.isOffer) offers++;
    if (a.stage == ApplicationStage.rejected) rejections++;
  }
}

/// Aggregate metrics over the whole application set.
class ApplicationMetrics {
  ApplicationMetrics(this.applications, this.settings);

  final List<JobApplication> applications;
  final AppSettings settings;

  /// Applications that actually went out.
  ///
  /// A closed stage (rejected / ghosted / withdrawn / position closed) sits
  /// outside the ordered pipeline, so stage alone cannot say whether it was
  /// sent — the recorded `dateApplied` is the ground truth. Counting these
  /// matters: dropping rejections from the denominator would inflate every
  /// rate on the analytics screen.
  List<JobApplication> get submitted => applications
      .where((a) => a.stage.hasApplied || a.dateApplied != null)
      .toList();

  int get total => submitted.length;

  int get totalSaved => applications.length;

  int countSince(DateTime from) => submitted
      .where((a) => (a.dateApplied ?? a.createdAt).isAfter(from))
      .length;

  int get thisWeek => countSince(startOfWeek(DateTime.now()));
  int get thisMonth => countSince(startOfMonth(DateTime.now()));
  int get today => submitted
      .where((a) =>
          a.dateApplied != null && dayOf(a.dateApplied!) == dayOf(DateTime.now()))
      .length;

  int get responses => submitted
      .where((a) => a.stage.isResponse || a.responseDate != null)
      .length;

  int get interviews => submitted
      .where((a) => a.stage.isInterview || a.interviewDate != null)
      .length;

  int get offers => submitted.where((a) => a.stage.isOffer).length;

  int get rejections =>
      submitted.where((a) => a.stage == ApplicationStage.rejected).length;

  int get ghosted =>
      submitted.where((a) => a.stage == ApplicationStage.ghosted).length;

  int get withSponsorship => submitted
      .where((a) =>
          a.workAuthRequirement == WorkAuthRequirement.explicitSponsorship ||
          a.workAuthRequirement == WorkAuthRequirement.sponsorshipPossible ||
          a.visaSponsorshipMentioned == TriState.yes)
      .length;

  double get responseRate => total == 0 ? 0 : responses / total;
  double get interviewRate => total == 0 ? 0 : interviews / total;
  double get offerRate => total == 0 ? 0 : offers / total;

  /// Applications still awaiting any outcome.
  List<JobApplication> get active =>
      submitted.where((a) => a.stage.isActive).toList();

  List<JobApplication> get stale => active
      .where((a) =>
          a.health(
            waitingAfter: settings.agingWaitingDays,
            followUpAfter: settings.agingFollowUpDays,
            staleAfter: settings.agingStaleDays,
          ) ==
          ApplicationHealth.stale)
      .toList();

  List<JobApplication> get needingFollowUp => active
      .where((a) =>
          a.health(
            waitingAfter: settings.agingWaitingDays,
            followUpAfter: settings.agingFollowUpDays,
            staleAfter: settings.agingStaleDays,
          ) ==
          ApplicationHealth.followUpDue)
      .toList();

  /// Count per pipeline stage, including stages with zero.
  Map<ApplicationStage, int> get byStage {
    final map = {for (final s in ApplicationStage.values) s: 0};
    for (final a in applications) {
      map[a.stage] = (map[a.stage] ?? 0) + 1;
    }
    return map;
  }

  Map<String, SegmentStats> _segment(String Function(JobApplication) key) {
    final map = <String, SegmentStats>{};
    for (final a in submitted) {
      final k = key(a);
      if (k.isEmpty) continue;
      (map[k] ??= SegmentStats(k)).record(a);
    }
    return map;
  }

  Map<String, SegmentStats> get byCountry => _segment((a) => a.country);
  Map<String, SegmentStats> get byRole => _segment((a) => a.roleCategory);
  Map<String, SegmentStats> get bySource => _segment((a) => a.source.label);
  Map<String, SegmentStats> get byResume => _segment((a) => a.resumeId ?? '');

  /// Funnel counts for the analytics view. Each level counts applications
  /// that reached *at least* that stage.
  List<FunnelStep> get funnel {
    int atLeast(ApplicationStage s) => applications
        .where((a) => _reached(a, s))
        .length;

    return [
      FunnelStep('Saved', applications.length),
      FunnelStep('Applied', atLeast(ApplicationStage.applied)),
      FunnelStep('Response', atLeast(ApplicationStage.recruiterScreen)),
      FunnelStep('Interview', atLeast(ApplicationStage.hrInterview)),
      FunnelStep('Technical', atLeast(ApplicationStage.technicalInterview)),
      FunnelStep('Final', atLeast(ApplicationStage.finalInterview)),
      FunnelStep('Offer', atLeast(ApplicationStage.offer)),
    ];
  }

  /// True when the application is at, or has passed through, [s].
  /// Closed applications retain the milestones their dates prove.
  static bool _reached(JobApplication a, ApplicationStage s) {
    if (!a.stage.isClosed) return a.stage.order >= s.order;
    // Reconstruct progress for closed applications from recorded dates.
    if (s.order <= ApplicationStage.applied.order) {
      return a.dateApplied != null;
    }
    if (s.order <= ApplicationStage.recruiterScreen.order) {
      return a.responseDate != null || a.interviewDate != null;
    }
    if (s.order <= ApplicationStage.hrInterview.order) {
      return a.interviewDate != null;
    }
    return false;
  }

  /// Applications submitted per day over the trailing [days] window.
  Map<DateTime, int> dailyCounts(int days) {
    final today = dayOf(DateTime.now());
    final out = <DateTime, int>{};
    for (var i = days - 1; i >= 0; i--) {
      out[today.subtract(Duration(days: i))] = 0;
    }
    for (final a in submitted) {
      final d = dayOf(a.dateApplied ?? a.createdAt);
      if (out.containsKey(d)) out[d] = out[d]! + 1;
    }
    return out;
  }

  /// Target vs actual allocation per country, sorted by target descending.
  List<CountryAllocation> countryAllocation() {
    final actual = byCountry;
    final totalApps = total;
    final out = <CountryAllocation>[];

    for (final t in settings.activeCountries) {
      final stats = actual[t.country];
      final count = stats?.applications ?? 0;
      out.add(CountryAllocation(
        country: t.country,
        targetPercent: t.targetPercent,
        actualPercent: totalApps == 0 ? 0 : (count / totalApps) * 100,
        applications: count,
        responses: stats?.responses ?? 0,
        interviews: stats?.interviews ?? 0,
        offers: stats?.offers ?? 0,
        tier: t.tier,
      ));
    }

    // countries applied to that are not in the strategy
    for (final entry in actual.entries) {
      final known = settings.activeCountries
          .any((c) => c.country.toLowerCase() == entry.key.toLowerCase());
      if (known) continue;
      out.add(CountryAllocation(
        country: entry.key,
        targetPercent: 0,
        actualPercent:
            totalApps == 0 ? 0 : (entry.value.applications / totalApps) * 100,
        applications: entry.value.applications,
        responses: entry.value.responses,
        interviews: entry.value.interviews,
        offers: entry.value.offers,
        tier: 4,
      ));
    }

    out.sort((a, b) => b.targetPercent.compareTo(a.targetPercent));
    return out;
  }

  /// How many more applications this country needs to hit its share,
  /// assuming the current total stays put. Negative means over-invested.
  static int gapToTarget(CountryAllocation a, int totalApps) {
    final want = (a.targetPercent / 100) * totalApps;
    return (want - a.applications).round();
  }
}

class FunnelStep {
  const FunnelStep(this.label, this.count);
  final String label;
  final int count;
}

class CountryAllocation {
  const CountryAllocation({
    required this.country,
    required this.targetPercent,
    required this.actualPercent,
    required this.applications,
    required this.responses,
    required this.interviews,
    required this.offers,
    this.tier = 1,
  });

  final String country;
  final double targetPercent;
  final double actualPercent;
  final int applications;
  final int responses;
  final int interviews;
  final int offers;
  final int tier;

  double get delta => actualPercent - targetPercent;

  /// Within 2 percentage points counts as on target.
  bool get isUnder => delta < -2;
  bool get isOver => delta > 2;
  bool get isOnTarget => !isUnder && !isOver;

  double get responseRate =>
      applications == 0 ? 0 : responses / applications;
  double get interviewRate =>
      applications == 0 ? 0 : interviews / applications;
}
