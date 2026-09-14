import 'package:flutter/foundation.dart';

import 'enums.dart';

/// Truncates a timestamp to local midnight — the canonical key for a "day".
DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? _dt(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is String) return DateTime.tryParse(v);
  return null;
}

double _d(Object? v, [double fallback = 0]) =>
    v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? fallback : fallback);

int _i(Object? v, [int fallback = 0]) =>
    v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? fallback : fallback);

bool _b(Object? v, [bool fallback = false]) =>
    v is bool ? v : (v is num ? v != 0 : fallback);

String _s(Object? v, [String fallback = '']) => v?.toString() ?? fallback;

List<String> _strList(Object? v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  if (v is String && v.isNotEmpty) {
    return v.split('|').where((e) => e.isNotEmpty).toList();
  }
  return const [];
}

// ===========================================================================
// Application
// ===========================================================================

@immutable
class JobApplication {
  const JobApplication({
    required this.id,
    required this.jobTitle,
    required this.companyName,
    required this.country,
    this.companyId,
    this.city = '',
    this.location = '',
    this.jobUrl = '',
    this.source = ApplicationSource.linkedIn,
    this.agencyId,
    this.roleCategory = '',
    this.seniority = Seniority.mid,
    this.employmentType = EmploymentType.fullTime,
    this.workMode = WorkMode.unknown,
    this.salaryMin,
    this.salaryMax,
    this.currency = 'EUR',
    this.stage = ApplicationStage.saved,
    this.visaSponsorshipMentioned = TriState.unknown,
    this.relocationAssistance = TriState.unknown,
    this.companyKnownToSponsor = TriState.unknown,
    this.workAuthRequirement = WorkAuthRequirement.unknown,
    this.visaNotes = '',
    this.resumeId,
    this.coverLetterUsed = false,
    required this.dateDiscovered,
    this.dateSaved,
    this.dateApplied,
    this.lastActivity,
    this.nextFollowUpDate,
    this.responseDate,
    this.interviewDate,
    this.outcomeDate,
    this.skillMatch = 5,
    this.experienceMatch = 5,
    this.visaProbability = 5,
    this.companyPriorityScore = 5,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String jobTitle;
  final String companyName;
  final String? companyId;
  final String country;
  final String city;
  final String location;
  final String jobUrl;
  final ApplicationSource source;
  final String? agencyId;

  final String roleCategory;
  final Seniority seniority;
  final EmploymentType employmentType;
  final WorkMode workMode;
  final int? salaryMin;
  final int? salaryMax;
  final String currency;

  final ApplicationStage stage;

  final TriState visaSponsorshipMentioned;
  final TriState relocationAssistance;
  final TriState companyKnownToSponsor;
  final WorkAuthRequirement workAuthRequirement;
  final String visaNotes;

  final String? resumeId;
  final bool coverLetterUsed;

  final DateTime dateDiscovered;
  final DateTime? dateSaved;
  final DateTime? dateApplied;
  final DateTime? lastActivity;
  final DateTime? nextFollowUpDate;
  final DateTime? responseDate;
  final DateTime? interviewDate;
  final DateTime? outcomeDate;

  /// Manual 0-10 ratings feeding the opportunity score.
  final int skillMatch;
  final int experienceMatch;
  final int visaProbability;
  final int companyPriorityScore;

  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Days since the application was submitted; null while unsent.
  int? get daysSinceApplied {
    final applied = dateApplied;
    if (applied == null) return null;
    return dayOf(DateTime.now()).difference(dayOf(applied)).inDays;
  }

  /// Days since anything at all happened on this application.
  int get daysSinceActivity {
    final last = lastActivity ?? dateApplied ?? dateSaved ?? createdAt;
    return dayOf(DateTime.now()).difference(dayOf(last)).inDays;
  }

  /// Aging health. Thresholds are configurable via [AppSettings].
  ApplicationHealth health({
    int waitingAfter = 7,
    int followUpAfter = 14,
    int staleAfter = 21,
  }) {
    if (stage.isClosed || stage == ApplicationStage.accepted) {
      return ApplicationHealth.closed;
    }
    if (!stage.hasApplied) return ApplicationHealth.active;
    // any employer response resets it to healthy
    if (stage.isResponse && daysSinceActivity < followUpAfter) {
      return ApplicationHealth.active;
    }
    final days = daysSinceApplied ?? 0;
    if (days >= staleAfter) return ApplicationHealth.stale;
    if (days >= followUpAfter) return ApplicationHealth.followUpDue;
    if (days >= waitingAfter) return ApplicationHealth.waiting;
    return ApplicationHealth.active;
  }

  JobApplication copyWith({
    String? jobTitle,
    String? companyName,
    Object? companyId = _unset,
    String? country,
    String? city,
    String? location,
    String? jobUrl,
    ApplicationSource? source,
    Object? agencyId = _unset,
    String? roleCategory,
    Seniority? seniority,
    EmploymentType? employmentType,
    WorkMode? workMode,
    Object? salaryMin = _unset,
    Object? salaryMax = _unset,
    String? currency,
    ApplicationStage? stage,
    TriState? visaSponsorshipMentioned,
    TriState? relocationAssistance,
    TriState? companyKnownToSponsor,
    WorkAuthRequirement? workAuthRequirement,
    String? visaNotes,
    Object? resumeId = _unset,
    bool? coverLetterUsed,
    DateTime? dateDiscovered,
    Object? dateSaved = _unset,
    Object? dateApplied = _unset,
    Object? lastActivity = _unset,
    Object? nextFollowUpDate = _unset,
    Object? responseDate = _unset,
    Object? interviewDate = _unset,
    Object? outcomeDate = _unset,
    int? skillMatch,
    int? experienceMatch,
    int? visaProbability,
    int? companyPriorityScore,
    String? notes,
    DateTime? updatedAt,
  }) =>
      JobApplication(
        id: id,
        jobTitle: jobTitle ?? this.jobTitle,
        companyName: companyName ?? this.companyName,
        companyId: companyId == _unset ? this.companyId : companyId as String?,
        country: country ?? this.country,
        city: city ?? this.city,
        location: location ?? this.location,
        jobUrl: jobUrl ?? this.jobUrl,
        source: source ?? this.source,
        agencyId: agencyId == _unset ? this.agencyId : agencyId as String?,
        roleCategory: roleCategory ?? this.roleCategory,
        seniority: seniority ?? this.seniority,
        employmentType: employmentType ?? this.employmentType,
        workMode: workMode ?? this.workMode,
        salaryMin: salaryMin == _unset ? this.salaryMin : salaryMin as int?,
        salaryMax: salaryMax == _unset ? this.salaryMax : salaryMax as int?,
        currency: currency ?? this.currency,
        stage: stage ?? this.stage,
        visaSponsorshipMentioned:
            visaSponsorshipMentioned ?? this.visaSponsorshipMentioned,
        relocationAssistance: relocationAssistance ?? this.relocationAssistance,
        companyKnownToSponsor:
            companyKnownToSponsor ?? this.companyKnownToSponsor,
        workAuthRequirement: workAuthRequirement ?? this.workAuthRequirement,
        visaNotes: visaNotes ?? this.visaNotes,
        resumeId: resumeId == _unset ? this.resumeId : resumeId as String?,
        coverLetterUsed: coverLetterUsed ?? this.coverLetterUsed,
        dateDiscovered: dateDiscovered ?? this.dateDiscovered,
        dateSaved: dateSaved == _unset ? this.dateSaved : dateSaved as DateTime?,
        dateApplied:
            dateApplied == _unset ? this.dateApplied : dateApplied as DateTime?,
        lastActivity: lastActivity == _unset
            ? this.lastActivity
            : lastActivity as DateTime?,
        nextFollowUpDate: nextFollowUpDate == _unset
            ? this.nextFollowUpDate
            : nextFollowUpDate as DateTime?,
        responseDate: responseDate == _unset
            ? this.responseDate
            : responseDate as DateTime?,
        interviewDate: interviewDate == _unset
            ? this.interviewDate
            : interviewDate as DateTime?,
        outcomeDate:
            outcomeDate == _unset ? this.outcomeDate : outcomeDate as DateTime?,
        skillMatch: skillMatch ?? this.skillMatch,
        experienceMatch: experienceMatch ?? this.experienceMatch,
        visaProbability: visaProbability ?? this.visaProbability,
        companyPriorityScore: companyPriorityScore ?? this.companyPriorityScore,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'jobTitle': jobTitle,
        'companyName': companyName,
        'companyId': companyId,
        'country': country,
        'city': city,
        'location': location,
        'jobUrl': jobUrl,
        'source': source.id,
        'agencyId': agencyId,
        'roleCategory': roleCategory,
        'seniority': seniority.id,
        'employmentType': employmentType.id,
        'workMode': workMode.id,
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
        'currency': currency,
        'stage': stage.id,
        'visaSponsorshipMentioned': visaSponsorshipMentioned.id,
        'relocationAssistance': relocationAssistance.id,
        'companyKnownToSponsor': companyKnownToSponsor.id,
        'workAuthRequirement': workAuthRequirement.id,
        'visaNotes': visaNotes,
        'resumeId': resumeId,
        'coverLetterUsed': coverLetterUsed,
        'dateDiscovered': dateDiscovered.toIso8601String(),
        'dateSaved': dateSaved?.toIso8601String(),
        'dateApplied': dateApplied?.toIso8601String(),
        'lastActivity': lastActivity?.toIso8601String(),
        'nextFollowUpDate': nextFollowUpDate?.toIso8601String(),
        'responseDate': responseDate?.toIso8601String(),
        'interviewDate': interviewDate?.toIso8601String(),
        'outcomeDate': outcomeDate?.toIso8601String(),
        'skillMatch': skillMatch,
        'experienceMatch': experienceMatch,
        'visaProbability': visaProbability,
        'companyPriorityScore': companyPriorityScore,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory JobApplication.fromJson(Map<String, Object?> j) => JobApplication(
        id: _s(j['id']),
        jobTitle: _s(j['jobTitle']),
        companyName: _s(j['companyName']),
        companyId: j['companyId'] as String?,
        country: _s(j['country']),
        city: _s(j['city']),
        location: _s(j['location']),
        jobUrl: _s(j['jobUrl']),
        source: ApplicationSource.fromId(j['source'] as String?),
        agencyId: j['agencyId'] as String?,
        roleCategory: _s(j['roleCategory']),
        seniority: Seniority.fromId(j['seniority'] as String?),
        employmentType: EmploymentType.fromId(j['employmentType'] as String?),
        workMode: WorkMode.fromId(j['workMode'] as String?),
        salaryMin: j['salaryMin'] == null ? null : _i(j['salaryMin']),
        salaryMax: j['salaryMax'] == null ? null : _i(j['salaryMax']),
        currency: _s(j['currency'], 'EUR'),
        stage: ApplicationStage.fromId(j['stage'] as String?),
        visaSponsorshipMentioned:
            TriState.fromId(j['visaSponsorshipMentioned'] as String?),
        relocationAssistance:
            TriState.fromId(j['relocationAssistance'] as String?),
        companyKnownToSponsor:
            TriState.fromId(j['companyKnownToSponsor'] as String?),
        workAuthRequirement:
            WorkAuthRequirement.fromId(j['workAuthRequirement'] as String?),
        visaNotes: _s(j['visaNotes']),
        resumeId: j['resumeId'] as String?,
        coverLetterUsed: _b(j['coverLetterUsed']),
        dateDiscovered: _dt(j['dateDiscovered']) ?? DateTime.now(),
        dateSaved: _dt(j['dateSaved']),
        dateApplied: _dt(j['dateApplied']),
        lastActivity: _dt(j['lastActivity']),
        nextFollowUpDate: _dt(j['nextFollowUpDate']),
        responseDate: _dt(j['responseDate']),
        interviewDate: _dt(j['interviewDate']),
        outcomeDate: _dt(j['outcomeDate']),
        skillMatch: _i(j['skillMatch'], 5),
        experienceMatch: _i(j['experienceMatch'], 5),
        visaProbability: _i(j['visaProbability'], 5),
        companyPriorityScore: _i(j['companyPriorityScore'], 5),
        notes: _s(j['notes']),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
        updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      );
}

const Object _unset = Object();

// ===========================================================================
// Company
// ===========================================================================

@immutable
class Company {
  const Company({
    required this.id,
    required this.name,
    this.website = '',
    this.linkedinUrl = '',
    this.careerUrl = '',
    this.country = '',
    this.city = '',
    this.industry = '',
    this.companySize = '',
    this.type = CompanyType.other,
    this.knownSponsor = TriState.unknown,
    this.sponsorshipLikelihood = 5,
    this.relocationAssistance = TriState.unknown,
    this.internationalHiringHistory = '',
    this.priority = CompanyPriority.medium,
    this.relationship = CompanyRelationship.notResearched,
    this.whyThisCompany = '',
    this.techStack = const [],
    this.potentialRoles = const [],
    this.notes = '',
    this.tags = const [],
    this.isSeeded = false,
    this.sourceRefs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String website;
  final String linkedinUrl;
  final String careerUrl;
  final String country;
  final String city;
  final String industry;
  final String companySize;
  final CompanyType type;

  final TriState knownSponsor;
  final int sponsorshipLikelihood; // 0-10
  final TriState relocationAssistance;
  final String internationalHiringHistory;

  final CompanyPriority priority;
  final CompanyRelationship relationship;

  final String whyThisCompany;
  final List<String> techStack;
  final List<String> potentialRoles;
  final String notes;
  final List<String> tags;

  /// True when the record came from the imported target lists rather than
  /// being typed in by hand.
  final bool isSeeded;
  final List<String> sourceRefs;

  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayLocation => [
        if (city.isNotEmpty) city,
        if (country.isNotEmpty) country,
      ].join(', ');

  Company copyWith({
    String? name,
    String? website,
    String? linkedinUrl,
    String? careerUrl,
    String? country,
    String? city,
    String? industry,
    String? companySize,
    CompanyType? type,
    TriState? knownSponsor,
    int? sponsorshipLikelihood,
    TriState? relocationAssistance,
    String? internationalHiringHistory,
    CompanyPriority? priority,
    CompanyRelationship? relationship,
    String? whyThisCompany,
    List<String>? techStack,
    List<String>? potentialRoles,
    String? notes,
    List<String>? tags,
    DateTime? updatedAt,
  }) =>
      Company(
        id: id,
        name: name ?? this.name,
        website: website ?? this.website,
        linkedinUrl: linkedinUrl ?? this.linkedinUrl,
        careerUrl: careerUrl ?? this.careerUrl,
        country: country ?? this.country,
        city: city ?? this.city,
        industry: industry ?? this.industry,
        companySize: companySize ?? this.companySize,
        type: type ?? this.type,
        knownSponsor: knownSponsor ?? this.knownSponsor,
        sponsorshipLikelihood:
            sponsorshipLikelihood ?? this.sponsorshipLikelihood,
        relocationAssistance: relocationAssistance ?? this.relocationAssistance,
        internationalHiringHistory:
            internationalHiringHistory ?? this.internationalHiringHistory,
        priority: priority ?? this.priority,
        relationship: relationship ?? this.relationship,
        whyThisCompany: whyThisCompany ?? this.whyThisCompany,
        techStack: techStack ?? this.techStack,
        potentialRoles: potentialRoles ?? this.potentialRoles,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        isSeeded: isSeeded,
        sourceRefs: sourceRefs,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'website': website,
        'linkedinUrl': linkedinUrl,
        'careerUrl': careerUrl,
        'country': country,
        'city': city,
        'industry': industry,
        'companySize': companySize,
        'type': type.id,
        'knownSponsor': knownSponsor.id,
        'sponsorshipLikelihood': sponsorshipLikelihood,
        'relocationAssistance': relocationAssistance.id,
        'internationalHiringHistory': internationalHiringHistory,
        'priority': priority.id,
        'relationship': relationship.id,
        'whyThisCompany': whyThisCompany,
        'techStack': techStack,
        'potentialRoles': potentialRoles,
        'notes': notes,
        'tags': tags,
        'isSeeded': isSeeded,
        'sourceRefs': sourceRefs,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Company.fromJson(Map<String, Object?> j) => Company(
        id: _s(j['id']),
        name: _s(j['name']),
        website: _s(j['website']),
        linkedinUrl: _s(j['linkedinUrl']),
        careerUrl: _s(j['careerUrl']),
        country: _s(j['country']),
        city: _s(j['city']),
        industry: _s(j['industry']),
        companySize: _s(j['companySize']),
        type: CompanyType.fromId(j['type'] as String?),
        knownSponsor: TriState.fromId(j['knownSponsor'] as String?),
        sponsorshipLikelihood: _i(j['sponsorshipLikelihood'], 5),
        relocationAssistance:
            TriState.fromId(j['relocationAssistance'] as String?),
        internationalHiringHistory: _s(j['internationalHiringHistory']),
        priority: CompanyPriority.fromId(j['priority'] as String?),
        relationship: CompanyRelationship.fromId(j['relationship'] as String?),
        whyThisCompany: _s(j['whyThisCompany']),
        techStack: _strList(j['techStack']),
        potentialRoles: _strList(j['potentialRoles']),
        notes: _s(j['notes']),
        tags: _strList(j['tags']),
        isSeeded: _b(j['isSeeded']),
        sourceRefs: _strList(j['sourceRefs']),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
        updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      );
}

// ===========================================================================
// Recruitment agency
// ===========================================================================

@immutable
class RecruitmentAgency {
  const RecruitmentAgency({
    required this.id,
    required this.name,
    this.website = '',
    this.linkedinUrl = '',
    this.country = '',
    this.countriesServed = const [],
    this.specialization = AgencySpecialization.generalTechnology,
    this.priority = AgencyPriority.medium,
    this.matchScore = 5,
    this.status = AgencyStatus.notContacted,
    this.dateRegistered,
    this.dateContacted,
    this.lastResponse,
    this.nextFollowUpDate,
    this.notes = '',
    this.tags = const [],
    this.isSeeded = false,
    this.sourceRefs = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String website;
  final String linkedinUrl;
  final String country;
  final List<String> countriesServed;
  final AgencySpecialization specialization;
  final AgencyPriority priority;
  final int matchScore; // 0-10
  final AgencyStatus status;
  final DateTime? dateRegistered;
  final DateTime? dateContacted;
  final DateTime? lastResponse;
  final DateTime? nextFollowUpDate;
  final String notes;
  final List<String> tags;
  final bool isSeeded;
  final List<String> sourceRefs;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isJobBoard =>
      specialization == AgencySpecialization.jobBoard ||
      specialization == AgencySpecialization.governmentPortal ||
      specialization == AgencySpecialization.recruiterDatabase;

  RecruitmentAgency copyWith({
    String? name,
    String? website,
    String? linkedinUrl,
    String? country,
    List<String>? countriesServed,
    AgencySpecialization? specialization,
    AgencyPriority? priority,
    int? matchScore,
    AgencyStatus? status,
    Object? dateRegistered = _unset,
    Object? dateContacted = _unset,
    Object? lastResponse = _unset,
    Object? nextFollowUpDate = _unset,
    String? notes,
    List<String>? tags,
    DateTime? updatedAt,
  }) =>
      RecruitmentAgency(
        id: id,
        name: name ?? this.name,
        website: website ?? this.website,
        linkedinUrl: linkedinUrl ?? this.linkedinUrl,
        country: country ?? this.country,
        countriesServed: countriesServed ?? this.countriesServed,
        specialization: specialization ?? this.specialization,
        priority: priority ?? this.priority,
        matchScore: matchScore ?? this.matchScore,
        status: status ?? this.status,
        dateRegistered: dateRegistered == _unset
            ? this.dateRegistered
            : dateRegistered as DateTime?,
        dateContacted: dateContacted == _unset
            ? this.dateContacted
            : dateContacted as DateTime?,
        lastResponse: lastResponse == _unset
            ? this.lastResponse
            : lastResponse as DateTime?,
        nextFollowUpDate: nextFollowUpDate == _unset
            ? this.nextFollowUpDate
            : nextFollowUpDate as DateTime?,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        isSeeded: isSeeded,
        sourceRefs: sourceRefs,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'website': website,
        'linkedinUrl': linkedinUrl,
        'country': country,
        'countriesServed': countriesServed,
        'specialization': specialization.id,
        'priority': priority.id,
        'matchScore': matchScore,
        'status': status.id,
        'dateRegistered': dateRegistered?.toIso8601String(),
        'dateContacted': dateContacted?.toIso8601String(),
        'lastResponse': lastResponse?.toIso8601String(),
        'nextFollowUpDate': nextFollowUpDate?.toIso8601String(),
        'notes': notes,
        'tags': tags,
        'isSeeded': isSeeded,
        'sourceRefs': sourceRefs,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RecruitmentAgency.fromJson(Map<String, Object?> j) =>
      RecruitmentAgency(
        id: _s(j['id']),
        name: _s(j['name']),
        website: _s(j['website']),
        linkedinUrl: _s(j['linkedinUrl']),
        country: _s(j['country']),
        countriesServed: _strList(j['countriesServed']),
        specialization:
            AgencySpecialization.fromId(j['specialization'] as String?),
        priority: AgencyPriority.fromId(j['priority'] as String?),
        matchScore: _i(j['matchScore'], 5),
        status: AgencyStatus.fromId(j['status'] as String?),
        dateRegistered: _dt(j['dateRegistered']),
        dateContacted: _dt(j['dateContacted']),
        lastResponse: _dt(j['lastResponse']),
        nextFollowUpDate: _dt(j['nextFollowUpDate']),
        notes: _s(j['notes']),
        tags: _strList(j['tags']),
        isSeeded: _b(j['isSeeded']),
        sourceRefs: _strList(j['sourceRefs']),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
        updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      );
}

// ===========================================================================
// Network contact + interaction
// ===========================================================================

@immutable
class NetworkContact {
  const NetworkContact({
    required this.id,
    required this.name,
    this.companyName = '',
    this.companyId,
    this.agencyId,
    this.role = '',
    this.linkedinUrl = '',
    this.email = '',
    this.phone = '',
    this.country = '',
    this.type = ContactType.recruiter,
    this.status = ContactStatus.notContacted,
    this.relationshipStrength = 1,
    this.specialization = '',
    this.dateContacted,
    this.lastResponse,
    this.nextFollowUpDate,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String companyName;
  final String? companyId;
  final String? agencyId;
  final String role;
  final String linkedinUrl;
  final String email;
  final String phone;
  final String country;
  final ContactType type;
  final ContactStatus status;

  /// 1 (cold) to 5 (strong advocate).
  final int relationshipStrength;
  final String specialization;
  final DateTime? dateContacted;
  final DateTime? lastResponse;
  final DateTime? nextFollowUpDate;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int? get daysSinceContacted {
    final c = dateContacted;
    if (c == null) return null;
    return dayOf(DateTime.now()).difference(dayOf(c)).inDays;
  }

  /// Contacted, never replied, and past the nudge window.
  bool needsNudge({int afterDays = 5}) {
    if (status == ContactStatus.notContacted ||
        status == ContactStatus.inactive) {
      return false;
    }
    if (lastResponse != null) return false;
    final d = daysSinceContacted;
    return d != null && d >= afterDays;
  }

  NetworkContact copyWith({
    String? name,
    String? companyName,
    Object? companyId = _unset,
    Object? agencyId = _unset,
    String? role,
    String? linkedinUrl,
    String? email,
    String? phone,
    String? country,
    ContactType? type,
    ContactStatus? status,
    int? relationshipStrength,
    String? specialization,
    Object? dateContacted = _unset,
    Object? lastResponse = _unset,
    Object? nextFollowUpDate = _unset,
    String? notes,
    DateTime? updatedAt,
  }) =>
      NetworkContact(
        id: id,
        name: name ?? this.name,
        companyName: companyName ?? this.companyName,
        companyId: companyId == _unset ? this.companyId : companyId as String?,
        agencyId: agencyId == _unset ? this.agencyId : agencyId as String?,
        role: role ?? this.role,
        linkedinUrl: linkedinUrl ?? this.linkedinUrl,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        country: country ?? this.country,
        type: type ?? this.type,
        status: status ?? this.status,
        relationshipStrength: relationshipStrength ?? this.relationshipStrength,
        specialization: specialization ?? this.specialization,
        dateContacted: dateContacted == _unset
            ? this.dateContacted
            : dateContacted as DateTime?,
        lastResponse: lastResponse == _unset
            ? this.lastResponse
            : lastResponse as DateTime?,
        nextFollowUpDate: nextFollowUpDate == _unset
            ? this.nextFollowUpDate
            : nextFollowUpDate as DateTime?,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'companyName': companyName,
        'companyId': companyId,
        'agencyId': agencyId,
        'role': role,
        'linkedinUrl': linkedinUrl,
        'email': email,
        'phone': phone,
        'country': country,
        'type': type.id,
        'status': status.id,
        'relationshipStrength': relationshipStrength,
        'specialization': specialization,
        'dateContacted': dateContacted?.toIso8601String(),
        'lastResponse': lastResponse?.toIso8601String(),
        'nextFollowUpDate': nextFollowUpDate?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory NetworkContact.fromJson(Map<String, Object?> j) => NetworkContact(
        id: _s(j['id']),
        name: _s(j['name']),
        companyName: _s(j['companyName']),
        companyId: j['companyId'] as String?,
        agencyId: j['agencyId'] as String?,
        role: _s(j['role']),
        linkedinUrl: _s(j['linkedinUrl']),
        email: _s(j['email']),
        phone: _s(j['phone']),
        country: _s(j['country']),
        type: ContactType.fromId(j['type'] as String?),
        status: ContactStatus.fromId(j['status'] as String?),
        relationshipStrength: _i(j['relationshipStrength'], 1),
        specialization: _s(j['specialization']),
        dateContacted: _dt(j['dateContacted']),
        lastResponse: _dt(j['lastResponse']),
        nextFollowUpDate: _dt(j['nextFollowUpDate']),
        notes: _s(j['notes']),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
        updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      );
}

@immutable
class ContactInteraction {
  const ContactInteraction({
    required this.id,
    required this.contactId,
    required this.date,
    required this.summary,
    this.channel = 'LinkedIn',
    this.inbound = false,
    this.notes = '',
  });

  final String id;
  final String contactId;
  final DateTime date;
  final String summary;
  final String channel;

  /// True when they reached out / replied to you.
  final bool inbound;
  final String notes;

  Map<String, Object?> toJson() => {
        'id': id,
        'contactId': contactId,
        'date': date.toIso8601String(),
        'summary': summary,
        'channel': channel,
        'inbound': inbound,
        'notes': notes,
      };

  factory ContactInteraction.fromJson(Map<String, Object?> j) =>
      ContactInteraction(
        id: _s(j['id']),
        contactId: _s(j['contactId']),
        date: _dt(j['date']) ?? DateTime.now(),
        summary: _s(j['summary']),
        channel: _s(j['channel'], 'LinkedIn'),
        inbound: _b(j['inbound']),
        notes: _s(j['notes']),
      );
}

// ===========================================================================
// Opportunity inbox
// ===========================================================================

@immutable
class JobOpportunity {
  const JobOpportunity({
    required this.id,
    required this.jobTitle,
    this.companyName = '',
    this.companyId,
    this.url = '',
    this.country = '',
    this.city = '',
    this.source = ApplicationSource.linkedIn,
    required this.dateDiscovered,
    this.priority = TaskPriority.normal,
    this.status = OpportunityStatus.inbox,
    this.notes = '',
    this.convertedApplicationId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String jobTitle;
  final String companyName;
  final String? companyId;
  final String url;
  final String country;
  final String city;
  final ApplicationSource source;
  final DateTime dateDiscovered;
  final TaskPriority priority;
  final OpportunityStatus status;
  final String notes;

  /// Set once the opportunity is promoted into a real application.
  final String? convertedApplicationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get ageInDays =>
      dayOf(DateTime.now()).difference(dayOf(dateDiscovered)).inDays;

  JobOpportunity copyWith({
    String? jobTitle,
    String? companyName,
    Object? companyId = _unset,
    String? url,
    String? country,
    String? city,
    ApplicationSource? source,
    DateTime? dateDiscovered,
    TaskPriority? priority,
    OpportunityStatus? status,
    String? notes,
    Object? convertedApplicationId = _unset,
    DateTime? updatedAt,
  }) =>
      JobOpportunity(
        id: id,
        jobTitle: jobTitle ?? this.jobTitle,
        companyName: companyName ?? this.companyName,
        companyId: companyId == _unset ? this.companyId : companyId as String?,
        url: url ?? this.url,
        country: country ?? this.country,
        city: city ?? this.city,
        source: source ?? this.source,
        dateDiscovered: dateDiscovered ?? this.dateDiscovered,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        convertedApplicationId: convertedApplicationId == _unset
            ? this.convertedApplicationId
            : convertedApplicationId as String?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'jobTitle': jobTitle,
        'companyName': companyName,
        'companyId': companyId,
        'url': url,
        'country': country,
        'city': city,
        'source': source.id,
        'dateDiscovered': dateDiscovered.toIso8601String(),
        'priority': priority.id,
        'status': status.id,
        'notes': notes,
        'convertedApplicationId': convertedApplicationId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory JobOpportunity.fromJson(Map<String, Object?> j) => JobOpportunity(
        id: _s(j['id']),
        jobTitle: _s(j['jobTitle']),
        companyName: _s(j['companyName']),
        companyId: j['companyId'] as String?,
        url: _s(j['url']),
        country: _s(j['country']),
        city: _s(j['city']),
        source: ApplicationSource.fromId(j['source'] as String?),
        dateDiscovered: _dt(j['dateDiscovered']) ?? DateTime.now(),
        priority: TaskPriority.fromId(j['priority'] as String?),
        status: OpportunityStatus.fromId(j['status'] as String?),
        notes: _s(j['notes']),
        convertedApplicationId: j['convertedApplicationId'] as String?,
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
        updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      );
}

// ===========================================================================
// Tasks
// ===========================================================================

@immutable
class DailyTask {
  const DailyTask({
    required this.id,
    required this.title,
    required this.date,
    this.category = TaskCategory.applications,
    this.priority = TaskPriority.normal,
    this.status = TaskStatus.notStarted,
    this.targetCount = 1,
    this.completedCount = 0,
    this.estimatedMinutes = 0,
    this.actualMinutes = 0,
    this.notes = '',
    this.completionLog = const [],
    this.isAutoGenerated = false,
    this.recurrence = '',
    this.companyId,
    this.applicationId,
    this.contactId,
    this.agencyId,
    this.country = '',
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// The day this task belongs to (local midnight).
  final DateTime date;
  final TaskCategory category;
  final TaskPriority priority;
  final TaskStatus status;

  /// Tasks are quantified ("Apply to 3 roles") so progress is partial-credit.
  final int targetCount;
  final int completedCount;
  final int estimatedMinutes;
  final int actualMinutes;
  final String notes;

  /// Free-text lines logged on completion ("Contacted John at Hays").
  final List<String> completionLog;
  final bool isAutoGenerated;
  final String recurrence;

  final String? companyId;
  final String? applicationId;
  final String? contactId;
  final String? agencyId;
  final String country;

  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get dayKey => _dayKey(date);

  double get progress {
    if (status == TaskStatus.completed) return 1;
    if (targetCount <= 0) return status.isDone ? 1 : 0;
    return (completedCount / targetCount).clamp(0.0, 1.0);
  }

  bool get isCountable => targetCount > 1;

  DailyTask copyWith({
    String? title,
    DateTime? date,
    TaskCategory? category,
    TaskPriority? priority,
    TaskStatus? status,
    int? targetCount,
    int? completedCount,
    int? estimatedMinutes,
    int? actualMinutes,
    String? notes,
    List<String>? completionLog,
    bool? isAutoGenerated,
    String? recurrence,
    Object? companyId = _unset,
    Object? applicationId = _unset,
    Object? contactId = _unset,
    Object? agencyId = _unset,
    String? country,
    Object? completedAt = _unset,
    DateTime? updatedAt,
  }) =>
      DailyTask(
        id: id,
        title: title ?? this.title,
        date: date ?? this.date,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        targetCount: targetCount ?? this.targetCount,
        completedCount: completedCount ?? this.completedCount,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
        actualMinutes: actualMinutes ?? this.actualMinutes,
        notes: notes ?? this.notes,
        completionLog: completionLog ?? this.completionLog,
        isAutoGenerated: isAutoGenerated ?? this.isAutoGenerated,
        recurrence: recurrence ?? this.recurrence,
        companyId: companyId == _unset ? this.companyId : companyId as String?,
        applicationId: applicationId == _unset
            ? this.applicationId
            : applicationId as String?,
        contactId: contactId == _unset ? this.contactId : contactId as String?,
        agencyId: agencyId == _unset ? this.agencyId : agencyId as String?,
        country: country ?? this.country,
        completedAt:
            completedAt == _unset ? this.completedAt : completedAt as DateTime?,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'date': date.toIso8601String(),
        'category': category.id,
        'priority': priority.id,
        'status': status.id,
        'targetCount': targetCount,
        'completedCount': completedCount,
        'estimatedMinutes': estimatedMinutes,
        'actualMinutes': actualMinutes,
        'notes': notes,
        'completionLog': completionLog,
        'isAutoGenerated': isAutoGenerated,
        'recurrence': recurrence,
        'companyId': companyId,
        'applicationId': applicationId,
        'contactId': contactId,
        'agencyId': agencyId,
        'country': country,
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory DailyTask.fromJson(Map<String, Object?> j) => DailyTask(
        id: _s(j['id']),
        title: _s(j['title']),
        date: _dt(j['date']) ?? DateTime.now(),
        category: TaskCategory.fromId(j['category'] as String?),
        priority: TaskPriority.fromId(j['priority'] as String?),
        status: TaskStatus.fromId(j['status'] as String?),
        targetCount: _i(j['targetCount'], 1),
        completedCount: _i(j['completedCount']),
        estimatedMinutes: _i(j['estimatedMinutes']),
        actualMinutes: _i(j['actualMinutes']),
        notes: _s(j['notes']),
        completionLog: _strList(j['completionLog']),
        isAutoGenerated: _b(j['isAutoGenerated']),
        recurrence: _s(j['recurrence']),
        companyId: j['companyId'] as String?,
        applicationId: j['applicationId'] as String?,
        contactId: j['contactId'] as String?,
        agencyId: j['agencyId'] as String?,
        country: _s(j['country']),
        completedAt: _dt(j['completedAt']),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
        updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      );
}

/// Per-day metadata: rest days, notes, the generated-plan marker.
@immutable
class DayLog {
  const DayLog({
    required this.date,
    this.dayType = DayType.normal,
    this.note = '',
    this.planGenerated = false,
  });

  final DateTime date;
  final DayType dayType;
  final String note;
  final bool planGenerated;

  String get dayKey => _dayKey(date);

  DayLog copyWith({DayType? dayType, String? note, bool? planGenerated}) =>
      DayLog(
        date: date,
        dayType: dayType ?? this.dayType,
        note: note ?? this.note,
        planGenerated: planGenerated ?? this.planGenerated,
      );

  Map<String, Object?> toJson() => {
        'date': date.toIso8601String(),
        'dayType': dayType.id,
        'note': note,
        'planGenerated': planGenerated,
      };

  factory DayLog.fromJson(Map<String, Object?> j) => DayLog(
        date: _dt(j['date']) ?? DateTime.now(),
        dayType: DayType.fromId(j['dayType'] as String?),
        note: _s(j['note']),
        planGenerated: _b(j['planGenerated']),
      );
}

// ===========================================================================
// Follow-ups
// ===========================================================================

@immutable
class FollowUp {
  const FollowUp({
    required this.id,
    required this.title,
    required this.dueDate,
    this.type = FollowUpType.application,
    this.context = '',
    this.recommendedAction = '',
    this.suggestedMessage = '',
    this.applicationId,
    this.contactId,
    this.agencyId,
    this.companyId,
    this.isCompleted = false,
    this.completedAt,
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime dueDate;
  final FollowUpType type;
  final String context;
  final String recommendedAction;
  final String suggestedMessage;
  final String? applicationId;
  final String? contactId;
  final String? agencyId;
  final String? companyId;
  final bool isCompleted;
  final DateTime? completedAt;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get daysUntilDue =>
      dayOf(dueDate).difference(dayOf(DateTime.now())).inDays;

  bool get isOverdue => !isCompleted && daysUntilDue < 0;
  bool get isDueToday => !isCompleted && daysUntilDue == 0;
  bool get isDueThisWeek =>
      !isCompleted && daysUntilDue > 0 && daysUntilDue <= 7;

  FollowUp copyWith({
    String? title,
    DateTime? dueDate,
    FollowUpType? type,
    String? context,
    String? recommendedAction,
    String? suggestedMessage,
    bool? isCompleted,
    Object? completedAt = _unset,
    String? notes,
    DateTime? updatedAt,
  }) =>
      FollowUp(
        id: id,
        title: title ?? this.title,
        dueDate: dueDate ?? this.dueDate,
        type: type ?? this.type,
        context: context ?? this.context,
        recommendedAction: recommendedAction ?? this.recommendedAction,
        suggestedMessage: suggestedMessage ?? this.suggestedMessage,
        applicationId: applicationId,
        contactId: contactId,
        agencyId: agencyId,
        companyId: companyId,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt:
            completedAt == _unset ? this.completedAt : completedAt as DateTime?,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'type': type.id,
        'context': context,
        'recommendedAction': recommendedAction,
        'suggestedMessage': suggestedMessage,
        'applicationId': applicationId,
        'contactId': contactId,
        'agencyId': agencyId,
        'companyId': companyId,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FollowUp.fromJson(Map<String, Object?> j) => FollowUp(
        id: _s(j['id']),
        title: _s(j['title']),
        dueDate: _dt(j['dueDate']) ?? DateTime.now(),
        type: FollowUpType.fromId(j['type'] as String?),
        context: _s(j['context']),
        recommendedAction: _s(j['recommendedAction']),
        suggestedMessage: _s(j['suggestedMessage']),
        applicationId: j['applicationId'] as String?,
        contactId: j['contactId'] as String?,
        agencyId: j['agencyId'] as String?,
        companyId: j['companyId'] as String?,
        isCompleted: _b(j['isCompleted']),
        completedAt: _dt(j['completedAt']),
        notes: _s(j['notes']),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
        updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      );
}

// ===========================================================================
// Interviews
// ===========================================================================

@immutable
class Interview {
  const Interview({
    required this.id,
    required this.companyName,
    required this.roleTitle,
    required this.scheduledAt,
    this.applicationId,
    this.companyId,
    this.interviewerName = '',
    this.durationMinutes = 60,
    this.format = InterviewFormat.video,
    this.stage = InterviewStage.technical,
    this.status = InterviewStatus.upcoming,
    this.prepChecklist = const {},
    this.selfRating,
    this.questionsAsked = '',
    this.whatWentWell = '',
    this.whatToImprove = '',
    this.struggledWith = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? applicationId;
  final String? companyId;
  final String companyName;
  final String roleTitle;
  final String interviewerName;
  final DateTime scheduledAt;
  final int durationMinutes;
  final InterviewFormat format;
  final InterviewStage stage;
  final InterviewStatus status;

  /// Checklist item -> done.
  final Map<String, bool> prepChecklist;

  /// Post-interview review, 1-10.
  final int? selfRating;
  final String questionsAsked;
  final String whatWentWell;
  final String whatToImprove;
  final String struggledWith;
  final String notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  int get daysUntil =>
      dayOf(scheduledAt).difference(dayOf(DateTime.now())).inDays;

  bool get isUpcoming =>
      status == InterviewStatus.upcoming && scheduledAt.isAfter(DateTime.now());

  double get prepProgress {
    if (prepChecklist.isEmpty) return 0;
    final done = prepChecklist.values.where((v) => v).length;
    return done / prepChecklist.length;
  }

  static const defaultPrepChecklist = <String>[
    'Research company',
    'Understand product',
    'Review job description',
    'Prepare project explanations',
    'Prepare STAR stories',
    'Review DSA',
    'Review system design',
    'Prepare questions',
  ];

  Interview copyWith({
    String? companyName,
    String? roleTitle,
    String? interviewerName,
    DateTime? scheduledAt,
    int? durationMinutes,
    InterviewFormat? format,
    InterviewStage? stage,
    InterviewStatus? status,
    Map<String, bool>? prepChecklist,
    Object? selfRating = _unset,
    String? questionsAsked,
    String? whatWentWell,
    String? whatToImprove,
    String? struggledWith,
    String? notes,
    DateTime? updatedAt,
  }) =>
      Interview(
        id: id,
        applicationId: applicationId,
        companyId: companyId,
        companyName: companyName ?? this.companyName,
        roleTitle: roleTitle ?? this.roleTitle,
        interviewerName: interviewerName ?? this.interviewerName,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        format: format ?? this.format,
        stage: stage ?? this.stage,
        status: status ?? this.status,
        prepChecklist: prepChecklist ?? this.prepChecklist,
        selfRating: selfRating == _unset ? this.selfRating : selfRating as int?,
        questionsAsked: questionsAsked ?? this.questionsAsked,
        whatWentWell: whatWentWell ?? this.whatWentWell,
        whatToImprove: whatToImprove ?? this.whatToImprove,
        struggledWith: struggledWith ?? this.struggledWith,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'applicationId': applicationId,
        'companyId': companyId,
        'companyName': companyName,
        'roleTitle': roleTitle,
        'interviewerName': interviewerName,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'format': format.id,
        'stage': stage.id,
        'status': status.id,
        'prepChecklist': prepChecklist,
        'selfRating': selfRating,
        'questionsAsked': questionsAsked,
        'whatWentWell': whatWentWell,
        'whatToImprove': whatToImprove,
        'struggledWith': struggledWith,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Interview.fromJson(Map<String, Object?> j) => Interview(
        id: _s(j['id']),
        applicationId: j['applicationId'] as String?,
        companyId: j['companyId'] as String?,
        companyName: _s(j['companyName']),
        roleTitle: _s(j['roleTitle']),
        interviewerName: _s(j['interviewerName']),
        scheduledAt: _dt(j['scheduledAt']) ?? DateTime.now(),
        durationMinutes: _i(j['durationMinutes'], 60),
        format: InterviewFormat.fromId(j['format'] as String?),
        stage: InterviewStage.fromId(j['stage'] as String?),
        status: InterviewStatus.fromId(j['status'] as String?),
        prepChecklist: (j['prepChecklist'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), _b(v))) ??
            const {},
        selfRating: j['selfRating'] == null ? null : _i(j['selfRating']),
        questionsAsked: _s(j['questionsAsked']),
        whatWentWell: _s(j['whatWentWell']),
        whatToImprove: _s(j['whatToImprove']),
        struggledWith: _s(j['struggledWith']),
        notes: _s(j['notes']),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
        updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      );
}

// ===========================================================================
// Resume
// ===========================================================================

@immutable
class Resume {
  const Resume({
    required this.id,
    required this.name,
    this.versionNumber = 1,
    this.filePath = '',
    this.targetRoles = const [],
    this.skillsEmphasized = const [],
    this.notes = '',
    this.isActive = true,
    required this.lastUpdated,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int versionNumber;
  final String filePath;
  final List<String> targetRoles;
  final List<String> skillsEmphasized;
  final String notes;
  final bool isActive;
  final DateTime lastUpdated;
  final DateTime createdAt;

  Resume copyWith({
    String? name,
    int? versionNumber,
    String? filePath,
    List<String>? targetRoles,
    List<String>? skillsEmphasized,
    String? notes,
    bool? isActive,
    DateTime? lastUpdated,
  }) =>
      Resume(
        id: id,
        name: name ?? this.name,
        versionNumber: versionNumber ?? this.versionNumber,
        filePath: filePath ?? this.filePath,
        targetRoles: targetRoles ?? this.targetRoles,
        skillsEmphasized: skillsEmphasized ?? this.skillsEmphasized,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
        lastUpdated: lastUpdated ?? DateTime.now(),
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'versionNumber': versionNumber,
        'filePath': filePath,
        'targetRoles': targetRoles,
        'skillsEmphasized': skillsEmphasized,
        'notes': notes,
        'isActive': isActive,
        'lastUpdated': lastUpdated.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Resume.fromJson(Map<String, Object?> j) => Resume(
        id: _s(j['id']),
        name: _s(j['name']),
        versionNumber: _i(j['versionNumber'], 1),
        filePath: _s(j['filePath']),
        targetRoles: _strList(j['targetRoles']),
        skillsEmphasized: _strList(j['skillsEmphasized']),
        notes: _s(j['notes']),
        isActive: _b(j['isActive'], true),
        lastUpdated: _dt(j['lastUpdated']) ?? DateTime.now(),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
      );
}

// ===========================================================================
// Preparation session
// ===========================================================================

@immutable
class PrepSession {
  const PrepSession({
    required this.id,
    required this.category,
    required this.date,
    required this.minutes,
    this.topic = '',
    this.notes = '',
  });

  final String id;
  final PrepCategory category;
  final DateTime date;
  final int minutes;
  final String topic;
  final String notes;

  Map<String, Object?> toJson() => {
        'id': id,
        'category': category.id,
        'date': date.toIso8601String(),
        'minutes': minutes,
        'topic': topic,
        'notes': notes,
      };

  factory PrepSession.fromJson(Map<String, Object?> j) => PrepSession(
        id: _s(j['id']),
        category: PrepCategory.fromId(j['category'] as String?),
        date: _dt(j['date']) ?? DateTime.now(),
        minutes: _i(j['minutes']),
        topic: _s(j['topic']),
        notes: _s(j['notes']),
      );
}

// ===========================================================================
// Portfolio project
// ===========================================================================

@immutable
class PortfolioProject {
  const PortfolioProject({
    required this.id,
    required this.name,
    this.description = '',
    this.technologies = const [],
    this.githubUrl = '',
    this.demoUrl = '',
    this.status = ProjectStatus.inProgress,
    this.isFlagship = false,
    this.tasks = const {},
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String description;
  final List<String> technologies;
  final String githubUrl;
  final String demoUrl;
  final ProjectStatus status;
  final bool isFlagship;

  /// Checklist item -> done.
  final Map<String, bool> tasks;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress {
    if (tasks.isEmpty) return status == ProjectStatus.shipped ? 1 : 0;
    return tasks.values.where((v) => v).length / tasks.length;
  }

  static const defaultTasks = <String>[
    'Architecture',
    'Backend',
    'Frontend',
    'Authentication',
    'AI Integration',
    'Deployment',
    'Documentation',
    'Demo Video',
  ];

  PortfolioProject copyWith({
    String? name,
    String? description,
    List<String>? technologies,
    String? githubUrl,
    String? demoUrl,
    ProjectStatus? status,
    bool? isFlagship,
    Map<String, bool>? tasks,
    String? notes,
    DateTime? updatedAt,
  }) =>
      PortfolioProject(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        technologies: technologies ?? this.technologies,
        githubUrl: githubUrl ?? this.githubUrl,
        demoUrl: demoUrl ?? this.demoUrl,
        status: status ?? this.status,
        isFlagship: isFlagship ?? this.isFlagship,
        tasks: tasks ?? this.tasks,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'technologies': technologies,
        'githubUrl': githubUrl,
        'demoUrl': demoUrl,
        'status': status.id,
        'isFlagship': isFlagship,
        'tasks': tasks,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory PortfolioProject.fromJson(Map<String, Object?> j) => PortfolioProject(
        id: _s(j['id']),
        name: _s(j['name']),
        description: _s(j['description']),
        technologies: _strList(j['technologies']),
        githubUrl: _s(j['githubUrl']),
        demoUrl: _s(j['demoUrl']),
        status: ProjectStatus.fromId(j['status'] as String?),
        isFlagship: _b(j['isFlagship']),
        tasks: (j['tasks'] as Map?)
                ?.map((k, v) => MapEntry(k.toString(), _b(v))) ??
            const {},
        notes: _s(j['notes']),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
        updatedAt: _dt(j['updatedAt']) ?? DateTime.now(),
      );
}

// ===========================================================================
// Activity history
// ===========================================================================

@immutable
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    this.subtitle = '',
    this.applicationId,
    this.companyId,
    this.contactId,
    this.agencyId,
    this.interviewId,
    this.taskId,
    this.country = '',
    this.metadata = const {},
  });

  final String id;
  final ActivityType type;
  final DateTime timestamp;
  final String title;
  final String subtitle;
  final String? applicationId;
  final String? companyId;
  final String? contactId;
  final String? agencyId;
  final String? interviewId;
  final String? taskId;
  final String country;
  final Map<String, Object?> metadata;

  String get dayKey => _dayKey(timestamp);

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.id,
        'timestamp': timestamp.toIso8601String(),
        'title': title,
        'subtitle': subtitle,
        'applicationId': applicationId,
        'companyId': companyId,
        'contactId': contactId,
        'agencyId': agencyId,
        'interviewId': interviewId,
        'taskId': taskId,
        'country': country,
        'metadata': metadata,
      };

  factory ActivityEvent.fromJson(Map<String, Object?> j) => ActivityEvent(
        id: _s(j['id']),
        type: ActivityType.fromId(j['type'] as String?),
        timestamp: _dt(j['timestamp']) ?? DateTime.now(),
        title: _s(j['title']),
        subtitle: _s(j['subtitle']),
        applicationId: j['applicationId'] as String?,
        companyId: j['companyId'] as String?,
        contactId: j['contactId'] as String?,
        agencyId: j['agencyId'] as String?,
        interviewId: j['interviewId'] as String?,
        taskId: j['taskId'] as String?,
        country: _s(j['country']),
        metadata: (j['metadata'] as Map?)?.cast<String, Object?>() ?? const {},
      );
}

// ===========================================================================
// Reviews
// ===========================================================================

@immutable
class WeeklyReview {
  const WeeklyReview({
    required this.id,
    required this.weekStart,
    this.whatWentWell = '',
    this.whatToImprove = '',
    this.nextWeekFocus = '',
    this.applicationsCount = 0,
    this.applicationsTarget = 0,
    this.recruiterMessages = 0,
    this.recruiterTarget = 0,
    this.prepMinutes = 0,
    this.prepTargetMinutes = 0,
    this.insights = const [],
    required this.createdAt,
  });

  final String id;
  final DateTime weekStart;
  final String whatWentWell;
  final String whatToImprove;
  final String nextWeekFocus;
  final int applicationsCount;
  final int applicationsTarget;
  final int recruiterMessages;
  final int recruiterTarget;
  final int prepMinutes;
  final int prepTargetMinutes;
  final List<String> insights;
  final DateTime createdAt;

  WeeklyReview copyWith({
    String? whatWentWell,
    String? whatToImprove,
    String? nextWeekFocus,
  }) =>
      WeeklyReview(
        id: id,
        weekStart: weekStart,
        whatWentWell: whatWentWell ?? this.whatWentWell,
        whatToImprove: whatToImprove ?? this.whatToImprove,
        nextWeekFocus: nextWeekFocus ?? this.nextWeekFocus,
        applicationsCount: applicationsCount,
        applicationsTarget: applicationsTarget,
        recruiterMessages: recruiterMessages,
        recruiterTarget: recruiterTarget,
        prepMinutes: prepMinutes,
        prepTargetMinutes: prepTargetMinutes,
        insights: insights,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'weekStart': weekStart.toIso8601String(),
        'whatWentWell': whatWentWell,
        'whatToImprove': whatToImprove,
        'nextWeekFocus': nextWeekFocus,
        'applicationsCount': applicationsCount,
        'applicationsTarget': applicationsTarget,
        'recruiterMessages': recruiterMessages,
        'recruiterTarget': recruiterTarget,
        'prepMinutes': prepMinutes,
        'prepTargetMinutes': prepTargetMinutes,
        'insights': insights,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WeeklyReview.fromJson(Map<String, Object?> j) => WeeklyReview(
        id: _s(j['id']),
        weekStart: _dt(j['weekStart']) ?? DateTime.now(),
        whatWentWell: _s(j['whatWentWell']),
        whatToImprove: _s(j['whatToImprove']),
        nextWeekFocus: _s(j['nextWeekFocus']),
        applicationsCount: _i(j['applicationsCount']),
        applicationsTarget: _i(j['applicationsTarget']),
        recruiterMessages: _i(j['recruiterMessages']),
        recruiterTarget: _i(j['recruiterTarget']),
        prepMinutes: _i(j['prepMinutes']),
        prepTargetMinutes: _i(j['prepTargetMinutes']),
        insights: _strList(j['insights']),
        createdAt: _dt(j['createdAt']) ?? DateTime.now(),
      );
}

// ===========================================================================
// Strategy targets
// ===========================================================================

@immutable
class CountryTarget {
  const CountryTarget({
    required this.country,
    required this.targetPercent,
    this.tier = 1,
    this.notes = '',
    this.isActive = true,
  });

  final String country;
  final double targetPercent;
  final int tier;
  final String notes;
  final bool isActive;

  CountryTarget copyWith({
    double? targetPercent,
    int? tier,
    String? notes,
    bool? isActive,
  }) =>
      CountryTarget(
        country: country,
        targetPercent: targetPercent ?? this.targetPercent,
        tier: tier ?? this.tier,
        notes: notes ?? this.notes,
        isActive: isActive ?? this.isActive,
      );

  Map<String, Object?> toJson() => {
        'country': country,
        'targetPercent': targetPercent,
        'tier': tier,
        'notes': notes,
        'isActive': isActive,
      };

  factory CountryTarget.fromJson(Map<String, Object?> j) => CountryTarget(
        country: _s(j['country']),
        targetPercent: _d(j['targetPercent']),
        tier: _i(j['tier'], 1),
        notes: _s(j['notes']),
        isActive: _b(j['isActive'], true),
      );
}

@immutable
class RoleTarget {
  const RoleTarget({
    required this.role,
    required this.targetPercent,
    this.isActive = true,
  });

  final String role;
  final double targetPercent;
  final bool isActive;

  RoleTarget copyWith({double? targetPercent, bool? isActive}) => RoleTarget(
        role: role,
        targetPercent: targetPercent ?? this.targetPercent,
        isActive: isActive ?? this.isActive,
      );

  Map<String, Object?> toJson() => {
        'role': role,
        'targetPercent': targetPercent,
        'isActive': isActive,
      };

  factory RoleTarget.fromJson(Map<String, Object?> j) => RoleTarget(
        role: _s(j['role']),
        targetPercent: _d(j['targetPercent']),
        isActive: _b(j['isActive'], true),
      );
}
