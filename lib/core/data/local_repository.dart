import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import '../domain/settings.dart';
import 'repository.dart';

/// Offline-first store backed by a single JSON document per collection.
///
/// Collections are held in memory after [init] so reads are synchronous-fast,
/// and writes are debounced to avoid hammering storage during rapid edits.
/// This works unchanged on web (IndexedDB/localStorage), Android and iOS.
class LocalDataRepository implements DataRepository {
  LocalDataRepository({this.flushDelay = const Duration(milliseconds: 250)});

  /// How long to coalesce writes before persisting.
  final Duration flushDelay;

  late final SharedPreferences _prefs;
  bool _ready = false;

  // in-memory collections, keyed by entity id where applicable
  final _applications = <String, JobApplication>{};
  final _companies = <String, Company>{};
  final _agencies = <String, RecruitmentAgency>{};
  final _contacts = <String, NetworkContact>{};
  final _interactions = <String, ContactInteraction>{};
  final _opportunities = <String, JobOpportunity>{};
  final _tasks = <String, DailyTask>{};
  final _dayLogs = <String, DayLog>{}; // keyed by day key
  final _followUps = <String, FollowUp>{};
  final _interviews = <String, Interview>{};
  final _resumes = <String, Resume>{};
  final _prepSessions = <String, PrepSession>{};
  final _projects = <String, PortfolioProject>{};
  final _activities = <String, ActivityEvent>{};
  final _weeklyReviews = <String, WeeklyReview>{};

  AppSettings? _settings;

  final _pendingKeys = <String>{};
  Timer? _flushTimer;

  static const _kSettings = 'ed.settings';
  static const _kApplications = 'ed.applications';
  static const _kCompanies = 'ed.companies';
  static const _kAgencies = 'ed.agencies';
  static const _kContacts = 'ed.contacts';
  static const _kInteractions = 'ed.interactions';
  static const _kOpportunities = 'ed.opportunities';
  static const _kTasks = 'ed.tasks';
  static const _kDayLogs = 'ed.daylogs';
  static const _kFollowUps = 'ed.followups';
  static const _kInterviews = 'ed.interviews';
  static const _kResumes = 'ed.resumes';
  static const _kPrepSessions = 'ed.prepsessions';
  static const _kProjects = 'ed.projects';
  static const _kActivities = 'ed.activities';
  static const _kWeeklyReviews = 'ed.weeklyreviews';

  @override
  Future<void> init() async {
    if (_ready) return;
    _prefs = await SharedPreferences.getInstance();

    _loadInto(_kApplications, _applications, JobApplication.fromJson,
        (e) => e.id);
    _loadInto(_kCompanies, _companies, Company.fromJson, (e) => e.id);
    _loadInto(
        _kAgencies, _agencies, RecruitmentAgency.fromJson, (e) => e.id);
    _loadInto(_kContacts, _contacts, NetworkContact.fromJson, (e) => e.id);
    _loadInto(_kInteractions, _interactions, ContactInteraction.fromJson,
        (e) => e.id);
    _loadInto(_kOpportunities, _opportunities, JobOpportunity.fromJson,
        (e) => e.id);
    _loadInto(_kTasks, _tasks, DailyTask.fromJson, (e) => e.id);
    _loadInto(_kDayLogs, _dayLogs, DayLog.fromJson, (e) => e.dayKey);
    _loadInto(_kFollowUps, _followUps, FollowUp.fromJson, (e) => e.id);
    _loadInto(_kInterviews, _interviews, Interview.fromJson, (e) => e.id);
    _loadInto(_kResumes, _resumes, Resume.fromJson, (e) => e.id);
    _loadInto(
        _kPrepSessions, _prepSessions, PrepSession.fromJson, (e) => e.id);
    _loadInto(_kProjects, _projects, PortfolioProject.fromJson, (e) => e.id);
    _loadInto(
        _kActivities, _activities, ActivityEvent.fromJson, (e) => e.id);
    _loadInto(_kWeeklyReviews, _weeklyReviews, WeeklyReview.fromJson,
        (e) => e.id);

    final rawSettings = _prefs.getString(_kSettings);
    if (rawSettings != null) {
      try {
        _settings = AppSettings.fromJson(
          jsonDecode(rawSettings) as Map<String, Object?>,
        );
      } catch (_) {
        _settings = AppSettings.initial();
      }
    }

    _ready = true;
  }

  void _loadInto<T>(
    String key,
    Map<String, T> target,
    T Function(Map<String, Object?>) fromJson,
    String Function(T) idOf,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List;
      for (final item in list) {
        try {
          final entity = fromJson((item as Map).cast<String, Object?>());
          target[idOf(entity)] = entity;
        } catch (_) {
          // skip a single corrupt record rather than losing the collection
        }
      }
    } catch (_) {
      // unreadable collection — start empty rather than crashing on launch
    }
  }

  void _markDirty(String key) {
    _pendingKeys.add(key);
    _flushTimer?.cancel();
    _flushTimer = Timer(flushDelay, flush);
  }

  /// Writes any pending collections immediately.
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_pendingKeys.isEmpty) return;
    final keys = Set<String>.from(_pendingKeys);
    _pendingKeys.clear();

    for (final key in keys) {
      final payload = switch (key) {
        _kSettings => jsonEncode(
            (_settings ?? AppSettings.initial()).toJson()),
        _kApplications => _encode(_applications.values, (e) => e.toJson()),
        _kCompanies => _encode(_companies.values, (e) => e.toJson()),
        _kAgencies => _encode(_agencies.values, (e) => e.toJson()),
        _kContacts => _encode(_contacts.values, (e) => e.toJson()),
        _kInteractions => _encode(_interactions.values, (e) => e.toJson()),
        _kOpportunities => _encode(_opportunities.values, (e) => e.toJson()),
        _kTasks => _encode(_tasks.values, (e) => e.toJson()),
        _kDayLogs => _encode(_dayLogs.values, (e) => e.toJson()),
        _kFollowUps => _encode(_followUps.values, (e) => e.toJson()),
        _kInterviews => _encode(_interviews.values, (e) => e.toJson()),
        _kResumes => _encode(_resumes.values, (e) => e.toJson()),
        _kPrepSessions => _encode(_prepSessions.values, (e) => e.toJson()),
        _kProjects => _encode(_projects.values, (e) => e.toJson()),
        _kActivities => _encode(_activities.values, (e) => e.toJson()),
        _kWeeklyReviews => _encode(_weeklyReviews.values, (e) => e.toJson()),
        _ => null,
      };
      if (payload != null) await _prefs.setString(key, payload);
    }
  }

  String _encode<T>(Iterable<T> items, Map<String, Object?> Function(T) toJson) =>
      jsonEncode(items.map(toJson).toList());

  void _ensureReady() {
    if (!_ready) {
      throw StateError('LocalDataRepository.init() must be awaited first.');
    }
  }

  // -- settings ------------------------------------------------------------

  @override
  Future<AppSettings> loadSettings() async {
    _ensureReady();
    return _settings ??= AppSettings.initial();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _ensureReady();
    _settings = settings;
    _markDirty(_kSettings);
  }

  // -- applications --------------------------------------------------------

  @override
  Future<List<JobApplication>> getApplications() async {
    _ensureReady();
    return _applications.values.toList();
  }

  @override
  Future<void> upsertApplication(JobApplication application) async {
    _ensureReady();
    _applications[application.id] = application;
    _markDirty(_kApplications);
  }

  @override
  Future<void> deleteApplication(String id) async {
    _ensureReady();
    _applications.remove(id);
    _markDirty(_kApplications);
  }

  // -- companies -----------------------------------------------------------

  @override
  Future<List<Company>> getCompanies() async {
    _ensureReady();
    return _companies.values.toList();
  }

  @override
  Future<void> upsertCompany(Company company) async {
    _ensureReady();
    _companies[company.id] = company;
    _markDirty(_kCompanies);
  }

  @override
  Future<void> upsertCompanies(List<Company> companies) async {
    _ensureReady();
    for (final c in companies) {
      _companies[c.id] = c;
    }
    _markDirty(_kCompanies);
  }

  @override
  Future<void> deleteCompany(String id) async {
    _ensureReady();
    _companies.remove(id);
    _markDirty(_kCompanies);
  }

  // -- agencies ------------------------------------------------------------

  @override
  Future<List<RecruitmentAgency>> getAgencies() async {
    _ensureReady();
    return _agencies.values.toList();
  }

  @override
  Future<void> upsertAgency(RecruitmentAgency agency) async {
    _ensureReady();
    _agencies[agency.id] = agency;
    _markDirty(_kAgencies);
  }

  @override
  Future<void> upsertAgencies(List<RecruitmentAgency> agencies) async {
    _ensureReady();
    for (final a in agencies) {
      _agencies[a.id] = a;
    }
    _markDirty(_kAgencies);
  }

  @override
  Future<void> deleteAgency(String id) async {
    _ensureReady();
    _agencies.remove(id);
    _markDirty(_kAgencies);
  }

  // -- networking ----------------------------------------------------------

  @override
  Future<List<NetworkContact>> getContacts() async {
    _ensureReady();
    return _contacts.values.toList();
  }

  @override
  Future<void> upsertContact(NetworkContact contact) async {
    _ensureReady();
    _contacts[contact.id] = contact;
    _markDirty(_kContacts);
  }

  @override
  Future<void> deleteContact(String id) async {
    _ensureReady();
    _contacts.remove(id);
    _interactions.removeWhere((_, v) => v.contactId == id);
    _markDirty(_kContacts);
    _markDirty(_kInteractions);
  }

  @override
  Future<List<ContactInteraction>> getInteractions() async {
    _ensureReady();
    return _interactions.values.toList();
  }

  @override
  Future<void> upsertInteraction(ContactInteraction interaction) async {
    _ensureReady();
    _interactions[interaction.id] = interaction;
    _markDirty(_kInteractions);
  }

  @override
  Future<void> deleteInteraction(String id) async {
    _ensureReady();
    _interactions.remove(id);
    _markDirty(_kInteractions);
  }

  // -- opportunities -------------------------------------------------------

  @override
  Future<List<JobOpportunity>> getOpportunities() async {
    _ensureReady();
    return _opportunities.values.toList();
  }

  @override
  Future<void> upsertOpportunity(JobOpportunity opportunity) async {
    _ensureReady();
    _opportunities[opportunity.id] = opportunity;
    _markDirty(_kOpportunities);
  }

  @override
  Future<void> deleteOpportunity(String id) async {
    _ensureReady();
    _opportunities.remove(id);
    _markDirty(_kOpportunities);
  }

  // -- tasks ---------------------------------------------------------------

  @override
  Future<List<DailyTask>> getTasks() async {
    _ensureReady();
    return _tasks.values.toList();
  }

  @override
  Future<void> upsertTask(DailyTask task) async {
    _ensureReady();
    _tasks[task.id] = task;
    _markDirty(_kTasks);
  }

  @override
  Future<void> upsertTasks(List<DailyTask> tasks) async {
    _ensureReady();
    for (final t in tasks) {
      _tasks[t.id] = t;
    }
    _markDirty(_kTasks);
  }

  @override
  Future<void> deleteTask(String id) async {
    _ensureReady();
    _tasks.remove(id);
    _markDirty(_kTasks);
  }

  @override
  Future<List<DayLog>> getDayLogs() async {
    _ensureReady();
    return _dayLogs.values.toList();
  }

  @override
  Future<void> upsertDayLog(DayLog log) async {
    _ensureReady();
    _dayLogs[log.dayKey] = log;
    _markDirty(_kDayLogs);
  }

  // -- follow-ups ----------------------------------------------------------

  @override
  Future<List<FollowUp>> getFollowUps() async {
    _ensureReady();
    return _followUps.values.toList();
  }

  @override
  Future<void> upsertFollowUp(FollowUp followUp) async {
    _ensureReady();
    _followUps[followUp.id] = followUp;
    _markDirty(_kFollowUps);
  }

  @override
  Future<void> deleteFollowUp(String id) async {
    _ensureReady();
    _followUps.remove(id);
    _markDirty(_kFollowUps);
  }

  // -- interviews ----------------------------------------------------------

  @override
  Future<List<Interview>> getInterviews() async {
    _ensureReady();
    return _interviews.values.toList();
  }

  @override
  Future<void> upsertInterview(Interview interview) async {
    _ensureReady();
    _interviews[interview.id] = interview;
    _markDirty(_kInterviews);
  }

  @override
  Future<void> deleteInterview(String id) async {
    _ensureReady();
    _interviews.remove(id);
    _markDirty(_kInterviews);
  }

  // -- resumes -------------------------------------------------------------

  @override
  Future<List<Resume>> getResumes() async {
    _ensureReady();
    return _resumes.values.toList();
  }

  @override
  Future<void> upsertResume(Resume resume) async {
    _ensureReady();
    _resumes[resume.id] = resume;
    _markDirty(_kResumes);
  }

  @override
  Future<void> deleteResume(String id) async {
    _ensureReady();
    _resumes.remove(id);
    _markDirty(_kResumes);
  }

  // -- preparation ---------------------------------------------------------

  @override
  Future<List<PrepSession>> getPrepSessions() async {
    _ensureReady();
    return _prepSessions.values.toList();
  }

  @override
  Future<void> upsertPrepSession(PrepSession session) async {
    _ensureReady();
    _prepSessions[session.id] = session;
    _markDirty(_kPrepSessions);
  }

  @override
  Future<void> deletePrepSession(String id) async {
    _ensureReady();
    _prepSessions.remove(id);
    _markDirty(_kPrepSessions);
  }

  // -- portfolio -----------------------------------------------------------

  @override
  Future<List<PortfolioProject>> getProjects() async {
    _ensureReady();
    return _projects.values.toList();
  }

  @override
  Future<void> upsertProject(PortfolioProject project) async {
    _ensureReady();
    _projects[project.id] = project;
    _markDirty(_kProjects);
  }

  @override
  Future<void> deleteProject(String id) async {
    _ensureReady();
    _projects.remove(id);
    _markDirty(_kProjects);
  }

  // -- activity ------------------------------------------------------------

  @override
  Future<List<ActivityEvent>> getActivities() async {
    _ensureReady();
    return _activities.values.toList();
  }

  @override
  Future<void> addActivity(ActivityEvent event) async {
    _ensureReady();
    _activities[event.id] = event;
    _markDirty(_kActivities);
  }

  @override
  Future<void> deleteActivity(String id) async {
    _ensureReady();
    _activities.remove(id);
    _markDirty(_kActivities);
  }

  // -- reviews -------------------------------------------------------------

  @override
  Future<List<WeeklyReview>> getWeeklyReviews() async {
    _ensureReady();
    return _weeklyReviews.values.toList();
  }

  @override
  Future<void> upsertWeeklyReview(WeeklyReview review) async {
    _ensureReady();
    _weeklyReviews[review.id] = review;
    _markDirty(_kWeeklyReviews);
  }

  // -- maintenance ---------------------------------------------------------

  @override
  Future<void> clearAll() async {
    _ensureReady();
    _applications.clear();
    _companies.clear();
    _agencies.clear();
    _contacts.clear();
    _interactions.clear();
    _opportunities.clear();
    _tasks.clear();
    _dayLogs.clear();
    _followUps.clear();
    _interviews.clear();
    _resumes.clear();
    _prepSessions.clear();
    _projects.clear();
    _activities.clear();
    _weeklyReviews.clear();
    _settings = AppSettings.initial();

    for (final key in const [
      _kApplications,
      _kCompanies,
      _kAgencies,
      _kContacts,
      _kInteractions,
      _kOpportunities,
      _kTasks,
      _kDayLogs,
      _kFollowUps,
      _kInterviews,
      _kResumes,
      _kPrepSessions,
      _kProjects,
      _kActivities,
      _kWeeklyReviews,
      _kSettings,
    ]) {
      await _prefs.remove(key);
    }
    _pendingKeys.clear();
  }
}
