import 'package:flutter/foundation.dart';

import 'enums.dart';
import 'models.dart';

/// Everything configurable about the campaign: goal, targets, weights,
/// aging thresholds and the country/role allocation strategy.
@immutable
class AppSettings {
  const AppSettings({
    this.primaryGoal =
        'Secure a visa-sponsored Software Engineer position in Europe',
    required this.targetDeadline,
    this.weeklyApplications = 14,
    this.weeklyRecruiterMessages = 10,
    this.weeklyConnections = 15,
    this.weeklyFollowUps = 8,
    this.weeklyPrepMinutes = 180,
    this.weeklyCompanyResearch = 6,
    this.weeklyHiringManagerMessages = 3,
    this.weeklyAgencyRegistrations = 2,
    this.planMode = PlanMode.flexible,
    this.streakThreshold = 0.6,
    this.agingWaitingDays = 7,
    this.agingFollowUpDays = 14,
    this.agingStaleDays = 21,
    this.followUpAfterDays = 10,
    this.contactNudgeDays = 5,
    this.scoreWeights = const ScoreWeights(),
    this.dailyScoreWeights = const DailyScoreWeights(),
    this.countryTargets = const [],
    this.roleTargets = const [],
    this.onboardingComplete = false,
    this.themeMode = 'dark',
    this.notificationsEnabled = true,
    this.morningReminderHour = 8,
    this.eveningReminderHour = 20,
  });

  final String primaryGoal;
  final DateTime targetDeadline;

  // weekly targets
  final int weeklyApplications;
  final int weeklyRecruiterMessages;
  final int weeklyConnections;
  final int weeklyFollowUps;
  final int weeklyPrepMinutes;
  final int weeklyCompanyResearch;
  final int weeklyHiringManagerMessages;
  final int weeklyAgencyRegistrations;

  final PlanMode planMode;

  /// Fraction of the day's weighted tasks needed to keep a streak alive.
  final double streakThreshold;

  // application aging thresholds (days)
  final int agingWaitingDays;
  final int agingFollowUpDays;
  final int agingStaleDays;

  /// Days after applying before an automatic follow-up is scheduled.
  final int followUpAfterDays;

  /// Days of silence after which a contact is flagged for a nudge.
  final int contactNudgeDays;

  final ScoreWeights scoreWeights;
  final DailyScoreWeights dailyScoreWeights;

  final List<CountryTarget> countryTargets;
  final List<RoleTarget> roleTargets;

  final bool onboardingComplete;
  final String themeMode;
  final bool notificationsEnabled;
  final int morningReminderHour;
  final int eveningReminderHour;

  int get daysRemaining =>
      dayOf(targetDeadline).difference(dayOf(DateTime.now())).inDays;

  /// Daily application target derived from the weekly one.
  int get dailyApplications => (weeklyApplications / 7).ceil();

  List<CountryTarget> get activeCountries =>
      countryTargets.where((c) => c.isActive).toList();

  List<RoleTarget> get activeRoles =>
      roleTargets.where((r) => r.isActive).toList();

  AppSettings copyWith({
    String? primaryGoal,
    DateTime? targetDeadline,
    int? weeklyApplications,
    int? weeklyRecruiterMessages,
    int? weeklyConnections,
    int? weeklyFollowUps,
    int? weeklyPrepMinutes,
    int? weeklyCompanyResearch,
    int? weeklyHiringManagerMessages,
    int? weeklyAgencyRegistrations,
    PlanMode? planMode,
    double? streakThreshold,
    int? agingWaitingDays,
    int? agingFollowUpDays,
    int? agingStaleDays,
    int? followUpAfterDays,
    int? contactNudgeDays,
    ScoreWeights? scoreWeights,
    DailyScoreWeights? dailyScoreWeights,
    List<CountryTarget>? countryTargets,
    List<RoleTarget>? roleTargets,
    bool? onboardingComplete,
    String? themeMode,
    bool? notificationsEnabled,
    int? morningReminderHour,
    int? eveningReminderHour,
  }) => AppSettings(
    primaryGoal: primaryGoal ?? this.primaryGoal,
    targetDeadline: targetDeadline ?? this.targetDeadline,
    weeklyApplications: weeklyApplications ?? this.weeklyApplications,
    weeklyRecruiterMessages:
        weeklyRecruiterMessages ?? this.weeklyRecruiterMessages,
    weeklyConnections: weeklyConnections ?? this.weeklyConnections,
    weeklyFollowUps: weeklyFollowUps ?? this.weeklyFollowUps,
    weeklyPrepMinutes: weeklyPrepMinutes ?? this.weeklyPrepMinutes,
    weeklyCompanyResearch: weeklyCompanyResearch ?? this.weeklyCompanyResearch,
    weeklyHiringManagerMessages:
        weeklyHiringManagerMessages ?? this.weeklyHiringManagerMessages,
    weeklyAgencyRegistrations:
        weeklyAgencyRegistrations ?? this.weeklyAgencyRegistrations,
    planMode: planMode ?? this.planMode,
    streakThreshold: streakThreshold ?? this.streakThreshold,
    agingWaitingDays: agingWaitingDays ?? this.agingWaitingDays,
    agingFollowUpDays: agingFollowUpDays ?? this.agingFollowUpDays,
    agingStaleDays: agingStaleDays ?? this.agingStaleDays,
    followUpAfterDays: followUpAfterDays ?? this.followUpAfterDays,
    contactNudgeDays: contactNudgeDays ?? this.contactNudgeDays,
    scoreWeights: scoreWeights ?? this.scoreWeights,
    dailyScoreWeights: dailyScoreWeights ?? this.dailyScoreWeights,
    countryTargets: countryTargets ?? this.countryTargets,
    roleTargets: roleTargets ?? this.roleTargets,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    themeMode: themeMode ?? this.themeMode,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    morningReminderHour: morningReminderHour ?? this.morningReminderHour,
    eveningReminderHour: eveningReminderHour ?? this.eveningReminderHour,
  );

  Map<String, Object?> toJson() => {
    'primaryGoal': primaryGoal,
    'targetDeadline': targetDeadline.toIso8601String(),
    'weeklyApplications': weeklyApplications,
    'weeklyRecruiterMessages': weeklyRecruiterMessages,
    'weeklyConnections': weeklyConnections,
    'weeklyFollowUps': weeklyFollowUps,
    'weeklyPrepMinutes': weeklyPrepMinutes,
    'weeklyCompanyResearch': weeklyCompanyResearch,
    'weeklyHiringManagerMessages': weeklyHiringManagerMessages,
    'weeklyAgencyRegistrations': weeklyAgencyRegistrations,
    'planMode': planMode.id,
    'streakThreshold': streakThreshold,
    'agingWaitingDays': agingWaitingDays,
    'agingFollowUpDays': agingFollowUpDays,
    'agingStaleDays': agingStaleDays,
    'followUpAfterDays': followUpAfterDays,
    'contactNudgeDays': contactNudgeDays,
    'scoreWeights': scoreWeights.toJson(),
    'dailyScoreWeights': dailyScoreWeights.toJson(),
    'countryTargets': countryTargets.map((c) => c.toJson()).toList(),
    'roleTargets': roleTargets.map((r) => r.toJson()).toList(),
    'onboardingComplete': onboardingComplete,
    'themeMode': themeMode,
    'notificationsEnabled': notificationsEnabled,
    'morningReminderHour': morningReminderHour,
    'eveningReminderHour': eveningReminderHour,
  };

  factory AppSettings.fromJson(Map<String, Object?> j) {
    final countries =
        (j['countryTargets'] as List?)
            ?.map((e) => CountryTarget.fromJson((e as Map).cast()))
            .toList() ??
        defaultCountryTargets;
    final roles =
        (j['roleTargets'] as List?)
            ?.map((e) => RoleTarget.fromJson((e as Map).cast()))
            .toList() ??
        defaultRoleTargets;
    return AppSettings(
      primaryGoal:
          j['primaryGoal']?.toString() ??
          'Secure a visa-sponsored Software Engineer position in Europe',
      targetDeadline:
          DateTime.tryParse(j['targetDeadline']?.toString() ?? '') ??
          defaultDeadline,
      weeklyApplications: (j['weeklyApplications'] as num?)?.toInt() ?? 14,
      weeklyRecruiterMessages:
          (j['weeklyRecruiterMessages'] as num?)?.toInt() ?? 10,
      weeklyConnections: (j['weeklyConnections'] as num?)?.toInt() ?? 15,
      weeklyFollowUps: (j['weeklyFollowUps'] as num?)?.toInt() ?? 8,
      weeklyPrepMinutes: (j['weeklyPrepMinutes'] as num?)?.toInt() ?? 180,
      weeklyCompanyResearch: (j['weeklyCompanyResearch'] as num?)?.toInt() ?? 6,
      weeklyHiringManagerMessages:
          (j['weeklyHiringManagerMessages'] as num?)?.toInt() ?? 3,
      weeklyAgencyRegistrations:
          (j['weeklyAgencyRegistrations'] as num?)?.toInt() ?? 2,
      planMode: PlanMode.fromId(j['planMode'] as String?),
      streakThreshold: (j['streakThreshold'] as num?)?.toDouble() ?? 0.6,
      agingWaitingDays: (j['agingWaitingDays'] as num?)?.toInt() ?? 7,
      agingFollowUpDays: (j['agingFollowUpDays'] as num?)?.toInt() ?? 14,
      agingStaleDays: (j['agingStaleDays'] as num?)?.toInt() ?? 21,
      followUpAfterDays: (j['followUpAfterDays'] as num?)?.toInt() ?? 10,
      contactNudgeDays: (j['contactNudgeDays'] as num?)?.toInt() ?? 5,
      scoreWeights: j['scoreWeights'] == null
          ? const ScoreWeights()
          : ScoreWeights.fromJson((j['scoreWeights'] as Map).cast()),
      dailyScoreWeights: j['dailyScoreWeights'] == null
          ? const DailyScoreWeights()
          : DailyScoreWeights.fromJson((j['dailyScoreWeights'] as Map).cast()),
      countryTargets: countries,
      roleTargets: roles,
      onboardingComplete: j['onboardingComplete'] == true,
      themeMode: j['themeMode']?.toString() ?? 'dark',
      notificationsEnabled: j['notificationsEnabled'] != false,
      morningReminderHour: (j['morningReminderHour'] as num?)?.toInt() ?? 8,
      eveningReminderHour: (j['eveningReminderHour'] as num?)?.toInt() ?? 20,
    );
  }

  static DateTime get defaultDeadline => DateTime(2027, 2, 28);

  static AppSettings initial() => AppSettings(
    targetDeadline: defaultDeadline,
    countryTargets: defaultCountryTargets,
    roleTargets: defaultRoleTargets,
  );

  /// Allocation weighted heavily to Germany and the Netherlands, with a
  /// deliberate ~10% spread across the other markets so a lucky break
  /// elsewhere is not ruled out. Percentages total 100.
  static const defaultCountryTargets = <CountryTarget>[
    CountryTarget(
      country: 'Germany',
      targetPercent: 45,
      tier: 1,
      notes:
          'Primary market. Largest imported target list (782 companies), '
          'strong sponsorship culture, EU Blue Card.',
    ),
    CountryTarget(
      country: 'Netherlands',
      targetPercent: 30,
      tier: 1,
      notes:
          'Second primary market. Highly favourable 30% ruling and a '
          'well-established IND sponsor register.',
    ),
    // --- the remaining 25% keeps other doors open ---
    CountryTarget(
      country: 'Ireland',
      targetPercent: 3,
      tier: 2,
      notes: 'English-speaking; Critical Skills Employment Permit.',
    ),
    CountryTarget(
      country: 'Poland',
      targetPercent: 3,
      tier: 2,
      notes: 'Fast-growing engineering hubs, lower competition.',
    ),
    CountryTarget(
      country: 'Sweden',
      targetPercent: 2.5,
      tier: 2,
      notes: 'Straightforward work-permit process.',
    ),
    CountryTarget(
      country: 'Belgium',
      targetPercent: 2.5,
      tier: 2,
      notes: 'Single Permit; strong consultancy market.',
    ),
    CountryTarget(
      country: 'Austria',
      targetPercent: 2,
      tier: 2,
      notes: 'Red-White-Red Card for skilled workers.',
    ),
    CountryTarget(
      country: 'Switzerland',
      targetPercent: 2,
      tier: 2,
      notes: 'Highest salaries; quota-limited for non-EU.',
    ),
    CountryTarget(
      country: 'Denmark',
      targetPercent: 1.5,
      tier: 3,
      notes: 'Pay Limit / Fast-Track schemes.',
    ),
    CountryTarget(
      country: 'Spain',
      targetPercent: 1.5,
      tier: 3,
      notes: 'Growing tech scene, highly skilled worker visa.',
    ),
    CountryTarget(
      country: 'Portugal',
      targetPercent: 1.5,
      tier: 3,
      notes: 'Tech Visa programme.',
    ),
    CountryTarget(
      country: 'Estonia',
      targetPercent: 1.5,
      tier: 3,
      notes: 'Digital-first, startup visa.',
    ),
    CountryTarget(country: 'Finland', targetPercent: 1, tier: 3),
    CountryTarget(country: 'Norway', targetPercent: 0.5, tier: 3),
    CountryTarget(country: 'Czech Republic', targetPercent: 0.5, tier: 3),
    CountryTarget(country: 'Luxembourg', targetPercent: 0.5, tier: 3),
    CountryTarget(country: 'Lithuania', targetPercent: 0.25, tier: 3),
    CountryTarget(country: 'Latvia', targetPercent: 0.25, tier: 3),
    CountryTarget(country: 'Italy', targetPercent: 0.25, tier: 3),
    CountryTarget(country: 'Romania', targetPercent: 0.25, tier: 3),
    CountryTarget(country: 'Malta', targetPercent: 0.25, tier: 3),
    CountryTarget(country: 'Cyprus', targetPercent: 0.25, tier: 3),
    CountryTarget(
      country: 'United Kingdom',
      targetPercent: 0,
      tier: 3,
      isActive: false,
      notes:
          'Skilled Worker visa requires a licensed sponsor. '
          'Enable if you want to include UK targets.',
    ),
  ];

  static const defaultRoleTargets = <RoleTarget>[
    RoleTarget(role: 'Backend Engineer', targetPercent: 24),
    RoleTarget(role: 'Full Stack Engineer', targetPercent: 18),
    RoleTarget(role: 'Applied AI Engineer', targetPercent: 15),
    RoleTarget(role: 'Data Engineer', targetPercent: 10),
    RoleTarget(role: 'Software Engineer', targetPercent: 10),
    RoleTarget(role: 'Automation Engineer', targetPercent: 8),
    RoleTarget(role: 'Mobile Engineer', targetPercent: 8),
    RoleTarget(role: 'Computer Vision / OCR', targetPercent: 4),
    RoleTarget(role: 'ML Engineer', targetPercent: 3),
  ];
}

/// Weights for the 0-100 opportunity score. Must sum to 1.0.
@immutable
class ScoreWeights {
  const ScoreWeights({
    this.skillMatch = 0.30,
    this.visaProbability = 0.25,
    this.countryPriority = 0.15,
    this.companyPriority = 0.15,
    this.rolePriority = 0.10,
    this.salaryOther = 0.05,
  });

  final double skillMatch;
  final double visaProbability;
  final double countryPriority;
  final double companyPriority;
  final double rolePriority;
  final double salaryOther;

  double get total =>
      skillMatch +
      visaProbability +
      countryPriority +
      companyPriority +
      rolePriority +
      salaryOther;

  ScoreWeights copyWith({
    double? skillMatch,
    double? visaProbability,
    double? countryPriority,
    double? companyPriority,
    double? rolePriority,
    double? salaryOther,
  }) => ScoreWeights(
    skillMatch: skillMatch ?? this.skillMatch,
    visaProbability: visaProbability ?? this.visaProbability,
    countryPriority: countryPriority ?? this.countryPriority,
    companyPriority: companyPriority ?? this.companyPriority,
    rolePriority: rolePriority ?? this.rolePriority,
    salaryOther: salaryOther ?? this.salaryOther,
  );

  Map<String, Object?> toJson() => {
    'skillMatch': skillMatch,
    'visaProbability': visaProbability,
    'countryPriority': countryPriority,
    'companyPriority': companyPriority,
    'rolePriority': rolePriority,
    'salaryOther': salaryOther,
  };

  factory ScoreWeights.fromJson(Map<String, Object?> j) => ScoreWeights(
    skillMatch: (j['skillMatch'] as num?)?.toDouble() ?? 0.30,
    visaProbability: (j['visaProbability'] as num?)?.toDouble() ?? 0.25,
    countryPriority: (j['countryPriority'] as num?)?.toDouble() ?? 0.15,
    companyPriority: (j['companyPriority'] as num?)?.toDouble() ?? 0.15,
    rolePriority: (j['rolePriority'] as num?)?.toDouble() ?? 0.10,
    salaryOther: (j['salaryOther'] as num?)?.toDouble() ?? 0.05,
  );
}

/// Weights for the 0-100 daily mission score. Must sum to 1.0.
@immutable
class DailyScoreWeights {
  const DailyScoreWeights({
    this.applications = 0.40,
    this.networking = 0.20,
    this.followUps = 0.15,
    this.preparation = 0.15,
    this.research = 0.10,
  });

  final double applications;
  final double networking;
  final double followUps;
  final double preparation;
  final double research;

  double get total =>
      applications + networking + followUps + preparation + research;

  double weightFor(TaskCategory c) => switch (c) {
    TaskCategory.applications => applications,
    TaskCategory.networking => networking,
    TaskCategory.followUps => followUps,
    TaskCategory.preparation => preparation,
    TaskCategory.research => research,
    TaskCategory.agencies => networking,
    TaskCategory.portfolio => research,
    TaskCategory.admin => research,
  };

  DailyScoreWeights copyWith({
    double? applications,
    double? networking,
    double? followUps,
    double? preparation,
    double? research,
  }) => DailyScoreWeights(
    applications: applications ?? this.applications,
    networking: networking ?? this.networking,
    followUps: followUps ?? this.followUps,
    preparation: preparation ?? this.preparation,
    research: research ?? this.research,
  );

  Map<String, Object?> toJson() => {
    'applications': applications,
    'networking': networking,
    'followUps': followUps,
    'preparation': preparation,
    'research': research,
  };

  factory DailyScoreWeights.fromJson(Map<String, Object?> j) =>
      DailyScoreWeights(
        applications: (j['applications'] as num?)?.toDouble() ?? 0.40,
        networking: (j['networking'] as num?)?.toDouble() ?? 0.20,
        followUps: (j['followUps'] as num?)?.toDouble() ?? 0.15,
        preparation: (j['preparation'] as num?)?.toDouble() ?? 0.15,
        research: (j['research'] as num?)?.toDouble() ?? 0.10,
      );
}
