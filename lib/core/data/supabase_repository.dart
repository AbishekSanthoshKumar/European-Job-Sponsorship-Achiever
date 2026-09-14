import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../domain/models.dart';
import '../domain/settings.dart';
import 'repository.dart';

class SupabaseDataRepository implements DataRepository {
  SupabaseDataRepository(this.config);

  final AppConfig config;

  SupabaseClient get _client => Supabase.instance.client;

  bool _ready = false;

  static const _table = 'ed_records';
  static const _settings = 'settings';
  static const _settingsId = 'settings';

  static const _applications = 'applications';
  static const _companies = 'companies';
  static const _agencies = 'agencies';
  static const _contacts = 'contacts';
  static const _interactions = 'interactions';
  static const _opportunities = 'opportunities';
  static const _tasks = 'tasks';
  static const _dayLogs = 'day_logs';
  static const _followUps = 'follow_ups';
  static const _interviews = 'interviews';
  static const _resumes = 'resumes';
  static const _prepSessions = 'prep_sessions';
  static const _projects = 'projects';
  static const _activities = 'activities';
  static const _weeklyReviews = 'weekly_reviews';

  @override
  Future<void> init() async {
    if (_ready) return;
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
    _ready = true;
  }

  void _ensureReady() {
    if (!_ready) {
      throw StateError('SupabaseDataRepository.init() must be awaited first.');
    }
  }

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Supabase user session is missing.');
    }
    return id;
  }

  Future<List<T>> _list<T>(
    String collection,
    T Function(Map<String, Object?> json) fromJson,
  ) async {
    _ensureReady();
    final rows = await _client
        .from(_table)
        .select('payload')
        .eq('collection', collection)
        .order('updated_at');

    return [
      for (final row in rows)
        fromJson(((row as Map)['payload'] as Map).cast<String, Object?>()),
    ];
  }

  Future<T?> _single<T>(
    String collection,
    String id,
    T Function(Map<String, Object?> json) fromJson,
  ) async {
    _ensureReady();
    final row = await _client
        .from(_table)
        .select('payload')
        .eq('collection', collection)
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    return fromJson(((row['payload'] as Map).cast<String, Object?>()));
  }

  Future<void> _put(
    String collection,
    String id,
    Map<String, Object?> payload,
  ) async {
    _ensureReady();
    await _client.from(_table).upsert({
      'user_id': _userId,
      'collection': collection,
      'id': id,
      'payload': payload,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,collection,id');
  }

  Future<void> _putAll<T>(
    String collection,
    List<T> items,
    String Function(T item) idOf,
    Map<String, Object?> Function(T item) toJson,
  ) async {
    _ensureReady();
    if (items.isEmpty) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await _client.from(_table).upsert([
      for (final item in items)
        {
          'user_id': _userId,
          'collection': collection,
          'id': idOf(item),
          'payload': toJson(item),
          'updated_at': now,
        },
    ], onConflict: 'user_id,collection,id');
  }

  Future<void> _delete(String collection, String id) async {
    _ensureReady();
    await _client
        .from(_table)
        .delete()
        .eq('user_id', _userId)
        .eq('collection', collection)
        .eq('id', id);
  }

  @override
  Future<AppSettings> loadSettings() async =>
      await _single(_settings, _settingsId, AppSettings.fromJson) ??
      AppSettings.initial();

  @override
  Future<void> saveSettings(AppSettings settings) =>
      _put(_settings, _settingsId, settings.toJson());

  @override
  Future<List<JobApplication>> getApplications() =>
      _list(_applications, JobApplication.fromJson);

  @override
  Future<void> upsertApplication(JobApplication application) =>
      _put(_applications, application.id, application.toJson());

  @override
  Future<void> deleteApplication(String id) => _delete(_applications, id);

  @override
  Future<List<Company>> getCompanies() => _list(_companies, Company.fromJson);

  @override
  Future<void> upsertCompany(Company company) =>
      _put(_companies, company.id, company.toJson());

  @override
  Future<void> upsertCompanies(List<Company> companies) =>
      _putAll(_companies, companies, (c) => c.id, (c) => c.toJson());

  @override
  Future<void> deleteCompany(String id) => _delete(_companies, id);

  @override
  Future<List<RecruitmentAgency>> getAgencies() =>
      _list(_agencies, RecruitmentAgency.fromJson);

  @override
  Future<void> upsertAgency(RecruitmentAgency agency) =>
      _put(_agencies, agency.id, agency.toJson());

  @override
  Future<void> upsertAgencies(List<RecruitmentAgency> agencies) =>
      _putAll(_agencies, agencies, (a) => a.id, (a) => a.toJson());

  @override
  Future<void> deleteAgency(String id) => _delete(_agencies, id);

  @override
  Future<List<NetworkContact>> getContacts() =>
      _list(_contacts, NetworkContact.fromJson);

  @override
  Future<void> upsertContact(NetworkContact contact) =>
      _put(_contacts, contact.id, contact.toJson());

  @override
  Future<void> deleteContact(String id) async {
    await _delete(_contacts, id);
    final interactions = await getInteractions();
    for (final interaction in interactions.where((i) => i.contactId == id)) {
      await deleteInteraction(interaction.id);
    }
  }

  @override
  Future<List<ContactInteraction>> getInteractions() =>
      _list(_interactions, ContactInteraction.fromJson);

  @override
  Future<void> upsertInteraction(ContactInteraction interaction) =>
      _put(_interactions, interaction.id, interaction.toJson());

  @override
  Future<void> deleteInteraction(String id) => _delete(_interactions, id);

  @override
  Future<List<JobOpportunity>> getOpportunities() =>
      _list(_opportunities, JobOpportunity.fromJson);

  @override
  Future<void> upsertOpportunity(JobOpportunity opportunity) =>
      _put(_opportunities, opportunity.id, opportunity.toJson());

  @override
  Future<void> deleteOpportunity(String id) => _delete(_opportunities, id);

  @override
  Future<List<DailyTask>> getTasks() => _list(_tasks, DailyTask.fromJson);

  @override
  Future<void> upsertTask(DailyTask task) =>
      _put(_tasks, task.id, task.toJson());

  @override
  Future<void> upsertTasks(List<DailyTask> tasks) =>
      _putAll(_tasks, tasks, (t) => t.id, (t) => t.toJson());

  @override
  Future<void> deleteTask(String id) => _delete(_tasks, id);

  @override
  Future<List<DayLog>> getDayLogs() => _list(_dayLogs, DayLog.fromJson);

  @override
  Future<void> upsertDayLog(DayLog log) =>
      _put(_dayLogs, log.dayKey, log.toJson());

  @override
  Future<List<FollowUp>> getFollowUps() => _list(_followUps, FollowUp.fromJson);

  @override
  Future<void> upsertFollowUp(FollowUp followUp) =>
      _put(_followUps, followUp.id, followUp.toJson());

  @override
  Future<void> deleteFollowUp(String id) => _delete(_followUps, id);

  @override
  Future<List<Interview>> getInterviews() =>
      _list(_interviews, Interview.fromJson);

  @override
  Future<void> upsertInterview(Interview interview) =>
      _put(_interviews, interview.id, interview.toJson());

  @override
  Future<void> deleteInterview(String id) => _delete(_interviews, id);

  @override
  Future<List<Resume>> getResumes() => _list(_resumes, Resume.fromJson);

  @override
  Future<void> upsertResume(Resume resume) =>
      _put(_resumes, resume.id, resume.toJson());

  @override
  Future<void> deleteResume(String id) => _delete(_resumes, id);

  @override
  Future<List<PrepSession>> getPrepSessions() =>
      _list(_prepSessions, PrepSession.fromJson);

  @override
  Future<void> upsertPrepSession(PrepSession session) =>
      _put(_prepSessions, session.id, session.toJson());

  @override
  Future<void> deletePrepSession(String id) => _delete(_prepSessions, id);

  @override
  Future<List<PortfolioProject>> getProjects() =>
      _list(_projects, PortfolioProject.fromJson);

  @override
  Future<void> upsertProject(PortfolioProject project) =>
      _put(_projects, project.id, project.toJson());

  @override
  Future<void> deleteProject(String id) => _delete(_projects, id);

  @override
  Future<List<ActivityEvent>> getActivities() =>
      _list(_activities, ActivityEvent.fromJson);

  @override
  Future<void> addActivity(ActivityEvent event) =>
      _put(_activities, event.id, event.toJson());

  @override
  Future<void> deleteActivity(String id) => _delete(_activities, id);

  @override
  Future<List<WeeklyReview>> getWeeklyReviews() =>
      _list(_weeklyReviews, WeeklyReview.fromJson);

  @override
  Future<void> upsertWeeklyReview(WeeklyReview review) =>
      _put(_weeklyReviews, review.id, review.toJson());

  @override
  Future<void> clearAll() async {
    _ensureReady();
    for (final collection in const [
      _settings,
      _applications,
      _companies,
      _agencies,
      _contacts,
      _interactions,
      _opportunities,
      _tasks,
      _dayLogs,
      _followUps,
      _interviews,
      _resumes,
      _prepSessions,
      _projects,
      _activities,
      _weeklyReviews,
    ]) {
      await _client
          .from(_table)
          .delete()
          .eq('user_id', _userId)
          .eq('collection', collection);
    }
  }
}
