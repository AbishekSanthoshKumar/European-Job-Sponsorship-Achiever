import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/local_repository.dart';
import '../data/repository.dart';
import '../data/supabase_repository.dart';
import '../config/app_config.dart';
import '../data/seed_loader.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../domain/settings.dart';
import '../services/insights_engine.dart';
import '../services/metrics_service.dart';
import '../services/plan_generator.dart';
import '../services/scoring_service.dart';
import '../services/streak_service.dart';

const uuid = Uuid();

/// Overridden in main() with the initialised instance.
/// Swap this override for a SupabaseDataRepository to move to the cloud.
final repositoryProvider = Provider<DataRepository>(
  (ref) => throw UnimplementedError('repositoryProvider must be overridden'),
);

// ===========================================================================
// Settings
// ===========================================================================

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._repo, AppSettings initial) : super(initial);

  final DataRepository _repo;

  Future<void> update(AppSettings next) async {
    state = next;
    await _repo.saveSettings(next);
  }

  Future<void> patch(AppSettings Function(AppSettings) fn) => update(fn(state));
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  throw UnimplementedError('settingsProvider must be overridden');
});

// ===========================================================================
// Generic collection notifier
// ===========================================================================

/// Holds a list in memory and writes through to the repository.
/// Every mutation replaces the list instance so Riverpod rebuilds reliably.
abstract class CollectionNotifier<T> extends StateNotifier<List<T>> {
  CollectionNotifier(this.ref, List<T> initial) : super(initial);

  final Ref ref;

  DataRepository get repo => ref.read(repositoryProvider);

  String idOf(T item);

  Future<void> persist(T item);
  Future<void> remove(String id);

  Future<void> put(T item) async {
    final id = idOf(item);
    final next = [...state];
    final i = next.indexWhere((e) => idOf(e) == id);
    if (i >= 0) {
      next[i] = item;
    } else {
      next.add(item);
    }
    state = next;
    await persist(item);
  }

  Future<void> putAll(List<T> items) async {
    final byId = {for (final e in state) idOf(e): e};
    for (final item in items) {
      byId[idOf(item)] = item;
    }
    state = byId.values.toList();
    for (final item in items) {
      await persist(item);
    }
  }

  Future<void> delete(String id) async {
    state = state.where((e) => idOf(e) != id).toList();
    await remove(id);
  }

  T? byId(String? id) {
    if (id == null) return null;
    for (final e in state) {
      if (idOf(e) == id) return e;
    }
    return null;
  }
}

// ===========================================================================
// Activity log — every meaningful action lands here
// ===========================================================================

class ActivityNotifier extends CollectionNotifier<ActivityEvent> {
  ActivityNotifier(super.ref, super.initial);

  @override
  String idOf(ActivityEvent item) => item.id;

  @override
  Future<void> persist(ActivityEvent item) => repo.addActivity(item);

  @override
  Future<void> remove(String id) => repo.deleteActivity(id);

  Future<void> log({
    required ActivityType type,
    required String title,
    String subtitle = '',
    String? applicationId,
    String? companyId,
    String? contactId,
    String? agencyId,
    String? interviewId,
    String? taskId,
    String country = '',
    Map<String, Object?> metadata = const {},
    DateTime? at,
  }) => put(
    ActivityEvent(
      id: uuid.v4(),
      type: type,
      timestamp: at ?? DateTime.now(),
      title: title,
      subtitle: subtitle,
      applicationId: applicationId,
      companyId: companyId,
      contactId: contactId,
      agencyId: agencyId,
      interviewId: interviewId,
      taskId: taskId,
      country: country,
      metadata: metadata,
    ),
  );
}

final activityProvider =
    StateNotifierProvider<ActivityNotifier, List<ActivityEvent>>((ref) {
      throw UnimplementedError('activityProvider must be overridden');
    });

/// Activities newest first.
final activityTimelineProvider = Provider<List<ActivityEvent>>((ref) {
  final items = [...ref.watch(activityProvider)];
  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items;
});

// ===========================================================================
// Applications
// ===========================================================================

class ApplicationsNotifier extends CollectionNotifier<JobApplication> {
  ApplicationsNotifier(super.ref, super.initial);

  @override
  String idOf(JobApplication item) => item.id;

  @override
  Future<void> persist(JobApplication item) => repo.upsertApplication(item);

  @override
  Future<void> remove(String id) => repo.deleteApplication(id);

  ActivityNotifier get _activity => ref.read(activityProvider.notifier);

  Future<JobApplication> create(JobApplication app) async {
    await put(app);
    await _activity.log(
      type: app.stage.hasApplied
          ? ActivityType.applicationSubmitted
          : ActivityType.applicationCreated,
      title: app.stage.hasApplied
          ? 'Applied to ${app.jobTitle}'
          : 'Saved ${app.jobTitle}',
      subtitle: app.companyName,
      applicationId: app.id,
      companyId: app.companyId,
      country: app.country,
    );
    if (app.stage.hasApplied) {
      await _scheduleFollowUp(app);
    }
    return app;
  }

  /// Moves an application to a new stage, stamping the relevant date and
  /// writing the history entry.
  Future<void> moveToStage(JobApplication app, ApplicationStage stage) async {
    if (app.stage == stage) return;
    final now = DateTime.now();

    var next = app.copyWith(stage: stage, lastActivity: now, updatedAt: now);

    if (stage.hasApplied && app.dateApplied == null) {
      next = next.copyWith(dateApplied: now);
    }
    if (stage.isResponse && app.responseDate == null) {
      next = next.copyWith(responseDate: now);
    }
    if (stage.isInterview && app.interviewDate == null) {
      next = next.copyWith(interviewDate: now);
    }
    if (stage.isClosed || stage == ApplicationStage.accepted) {
      next = next.copyWith(outcomeDate: now);
    }

    await put(next);

    await _activity.log(
      type: stage == ApplicationStage.offer
          ? ActivityType.offerReceived
          : (stage.hasApplied && !app.stage.hasApplied
                ? ActivityType.applicationSubmitted
                : ActivityType.applicationStageChanged),
      title: '${next.jobTitle} → ${stage.label}',
      subtitle: next.companyName,
      applicationId: next.id,
      companyId: next.companyId,
      country: next.country,
      metadata: {'from': app.stage.id, 'to': stage.id},
    );

    // applying schedules the first follow-up automatically
    if (stage.hasApplied && !app.stage.hasApplied) {
      await _scheduleFollowUp(next);
    }
    // a reply or a closed outcome makes any pending follow-up moot
    if (stage.isResponse || stage.isClosed) {
      await ref
          .read(followUpsProvider.notifier)
          .completeForApplication(next.id);
    }
  }

  Future<void> _scheduleFollowUp(JobApplication app) async {
    final settings = ref.read(settingsProvider);
    final due = dayOf(
      app.dateApplied ?? DateTime.now(),
    ).add(Duration(days: settings.followUpAfterDays));
    final now = DateTime.now();

    await ref
        .read(followUpsProvider.notifier)
        .put(
          FollowUp(
            id: uuid.v4(),
            title: 'Follow up: ${app.jobTitle}',
            dueDate: due,
            type: FollowUpType.application,
            context: '${app.companyName} · ${app.country}',
            recommendedAction:
                'Send a short note to confirm your application is being '
                'reviewed and restate your interest.',
            suggestedMessage: _suggestedMessage(app),
            applicationId: app.id,
            companyId: app.companyId,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  static String _suggestedMessage(JobApplication app) =>
      'Hello,\n\nI applied for the ${app.jobTitle} role at '
      '${app.companyName} and wanted to check whether my application is '
      'still under consideration. I am very interested in the position '
      'and happy to share anything further that would help.\n\n'
      'Thank you for your time.';
}

final applicationsProvider =
    StateNotifierProvider<ApplicationsNotifier, List<JobApplication>>((ref) {
      throw UnimplementedError('applicationsProvider must be overridden');
    });

// ===========================================================================
// Companies
// ===========================================================================

class CompaniesNotifier extends CollectionNotifier<Company> {
  CompaniesNotifier(super.ref, super.initial);

  @override
  String idOf(Company item) => item.id;

  @override
  Future<void> persist(Company item) => repo.upsertCompany(item);

  @override
  Future<void> remove(String id) => repo.deleteCompany(id);

  @override
  Future<void> putAll(List<Company> items) async {
    final byId = {for (final e in state) e.id: e};
    for (final item in items) {
      byId[item.id] = item;
    }
    state = byId.values.toList();
    await repo.upsertCompanies(items);
  }

  Future<void> create(Company company) async {
    await put(company);
    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.companyAdded,
          title: 'Added target company',
          subtitle: company.name,
          companyId: company.id,
          country: company.country,
        );
  }

  Future<void> setRelationship(
    Company company,
    CompanyRelationship relationship,
  ) async {
    if (company.relationship == relationship) return;
    await put(company.copyWith(relationship: relationship));
    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.companyStatusChanged,
          title: '${company.name} → ${relationship.label}',
          companyId: company.id,
          country: company.country,
        );
  }
}

final companiesProvider =
    StateNotifierProvider<CompaniesNotifier, List<Company>>((ref) {
      throw UnimplementedError('companiesProvider must be overridden');
    });

/// Fast lookup by id for detail screens and joins.
final companyByIdProvider = Provider<Map<String, Company>>(
  (ref) => {for (final c in ref.watch(companiesProvider)) c.id: c},
);

// ===========================================================================
// Agencies
// ===========================================================================

class AgenciesNotifier extends CollectionNotifier<RecruitmentAgency> {
  AgenciesNotifier(super.ref, super.initial);

  @override
  String idOf(RecruitmentAgency item) => item.id;

  @override
  Future<void> persist(RecruitmentAgency item) => repo.upsertAgency(item);

  @override
  Future<void> remove(String id) => repo.deleteAgency(id);

  @override
  Future<void> putAll(List<RecruitmentAgency> items) async {
    final byId = {for (final e in state) e.id: e};
    for (final item in items) {
      byId[item.id] = item;
    }
    state = byId.values.toList();
    await repo.upsertAgencies(items);
  }

  Future<void> setStatus(RecruitmentAgency agency, AgencyStatus status) async {
    if (agency.status == status) return;
    final now = DateTime.now();
    var next = agency.copyWith(status: status, updatedAt: now);

    if (status == AgencyStatus.contacted && agency.dateContacted == null) {
      next = next.copyWith(dateContacted: now);
    }
    if (status == AgencyStatus.registered && agency.dateRegistered == null) {
      next = next.copyWith(dateRegistered: now);
    }
    if (status == AgencyStatus.responded) {
      next = next.copyWith(lastResponse: now);
    }

    await put(next);
    await ref
        .read(activityProvider.notifier)
        .log(
          type: status == AgencyStatus.contacted
              ? ActivityType.agencyContacted
              : ActivityType.agencyStatusChanged,
          title: '${agency.name} → ${status.label}',
          subtitle: agency.country,
          agencyId: agency.id,
          country: agency.country,
        );
  }
}

final agenciesProvider =
    StateNotifierProvider<AgenciesNotifier, List<RecruitmentAgency>>((ref) {
      throw UnimplementedError('agenciesProvider must be overridden');
    });

// ===========================================================================
// Networking
// ===========================================================================

class ContactsNotifier extends CollectionNotifier<NetworkContact> {
  ContactsNotifier(super.ref, super.initial);

  @override
  String idOf(NetworkContact item) => item.id;

  @override
  Future<void> persist(NetworkContact item) => repo.upsertContact(item);

  @override
  Future<void> remove(String id) => repo.deleteContact(id);

  Future<void> create(NetworkContact contact) async {
    await put(contact);
    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.contactAdded,
          title: 'Added contact ${contact.name}',
          subtitle: [
            contact.role,
            contact.companyName,
          ].where((s) => s.isNotEmpty).join(' · '),
          contactId: contact.id,
          country: contact.country,
        );
  }

  /// Records an interaction and advances the contact's status.
  Future<void> logInteraction({
    required NetworkContact contact,
    required String summary,
    String channel = 'LinkedIn',
    bool inbound = false,
    ContactStatus? newStatus,
    DateTime? at,
  }) async {
    final when = at ?? DateTime.now();

    await ref
        .read(interactionsProvider.notifier)
        .put(
          ContactInteraction(
            id: uuid.v4(),
            contactId: contact.id,
            date: when,
            summary: summary,
            channel: channel,
            inbound: inbound,
          ),
        );

    var next = contact.copyWith(
      status: newStatus ?? contact.status,
      updatedAt: when,
    );
    if (inbound) {
      next = next.copyWith(lastResponse: when);
      if (newStatus == null &&
          contact.status.index < ContactStatus.responded.index) {
        next = next.copyWith(status: ContactStatus.responded);
      }
    } else if (contact.dateContacted == null) {
      next = next.copyWith(dateContacted: when);
    }

    await put(next);

    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.contactInteraction,
          title: inbound
              ? '${contact.name} replied'
              : 'Contacted ${contact.name}',
          subtitle: summary,
          contactId: contact.id,
          country: contact.country,
          at: when,
        );
  }
}

final contactsProvider =
    StateNotifierProvider<ContactsNotifier, List<NetworkContact>>((ref) {
      throw UnimplementedError('contactsProvider must be overridden');
    });

class InteractionsNotifier extends CollectionNotifier<ContactInteraction> {
  InteractionsNotifier(super.ref, super.initial);

  @override
  String idOf(ContactInteraction item) => item.id;

  @override
  Future<void> persist(ContactInteraction item) => repo.upsertInteraction(item);

  @override
  Future<void> remove(String id) => repo.deleteInteraction(id);

  List<ContactInteraction> forContact(String contactId) {
    final items = state.where((i) => i.contactId == contactId).toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }
}

final interactionsProvider =
    StateNotifierProvider<InteractionsNotifier, List<ContactInteraction>>((
      ref,
    ) {
      throw UnimplementedError('interactionsProvider must be overridden');
    });

// ===========================================================================
// Opportunities
// ===========================================================================

class OpportunitiesNotifier extends CollectionNotifier<JobOpportunity> {
  OpportunitiesNotifier(super.ref, super.initial);

  @override
  String idOf(JobOpportunity item) => item.id;

  @override
  Future<void> persist(JobOpportunity item) => repo.upsertOpportunity(item);

  @override
  Future<void> remove(String id) => repo.deleteOpportunity(id);

  Future<void> create(JobOpportunity opportunity) async {
    await put(opportunity);
    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.opportunitySaved,
          title: 'Saved ${opportunity.jobTitle}',
          subtitle: opportunity.companyName,
          country: opportunity.country,
        );
  }

  /// Promotes an inbox item into a real application.
  Future<JobApplication> convert(JobOpportunity opp) async {
    final now = DateTime.now();
    final app = JobApplication(
      id: uuid.v4(),
      jobTitle: opp.jobTitle,
      companyName: opp.companyName,
      companyId: opp.companyId,
      country: opp.country,
      city: opp.city,
      jobUrl: opp.url,
      source: opp.source,
      stage: ApplicationStage.readyToApply,
      dateDiscovered: opp.dateDiscovered,
      dateSaved: now,
      notes: opp.notes,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(applicationsProvider.notifier).create(app);
    await put(
      opp.copyWith(
        status: OpportunityStatus.applied,
        convertedApplicationId: app.id,
      ),
    );
    return app;
  }
}

final opportunitiesProvider =
    StateNotifierProvider<OpportunitiesNotifier, List<JobOpportunity>>((ref) {
      throw UnimplementedError('opportunitiesProvider must be overridden');
    });

// ===========================================================================
// Tasks & day logs
// ===========================================================================

class TasksNotifier extends CollectionNotifier<DailyTask> {
  TasksNotifier(super.ref, super.initial);

  @override
  String idOf(DailyTask item) => item.id;

  @override
  Future<void> persist(DailyTask item) => repo.upsertTask(item);

  @override
  Future<void> remove(String id) => repo.deleteTask(id);

  @override
  Future<void> putAll(List<DailyTask> items) async {
    final byId = {for (final e in state) e.id: e};
    for (final item in items) {
      byId[item.id] = item;
    }
    state = byId.values.toList();
    await repo.upsertTasks(items);
  }

  List<DailyTask> forDay(DateTime date) {
    final d = dayOf(date);
    final items = state.where((t) => dayOf(t.date) == d).toList();
    items.sort((a, b) {
      final p = b.priority.weight.compareTo(a.priority.weight);
      if (p != 0) return p;
      return a.category.index.compareTo(b.category.index);
    });
    return items;
  }

  /// Marks a task complete, optionally recording what was actually done.
  Future<void> complete(
    DailyTask task, {
    List<String> log = const [],
    int? actualMinutes,
  }) async {
    final now = DateTime.now();
    final next = task.copyWith(
      status: TaskStatus.completed,
      completedCount: task.targetCount,
      completionLog: [...task.completionLog, ...log],
      actualMinutes: actualMinutes ?? task.actualMinutes,
      completedAt: now,
      updatedAt: now,
    );
    await put(next);

    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.taskCompleted,
          title: task.title,
          subtitle: log.isEmpty ? task.category.label : log.join(' · '),
          taskId: task.id,
          at: now,
        );

    if (task.recurrence.startsWith('follow_up:')) {
      final followUpId = task.recurrence.substring('follow_up:'.length);
      final followUp = ref.read(followUpsProvider.notifier).byId(followUpId);
      if (followUp != null && !followUp.isCompleted) {
        await ref
            .read(followUpsProvider.notifier)
            .complete(followUp, note: log.join('\n'));
      }
    }
  }

  /// Increments partial progress on a quantified task.
  Future<void> increment(DailyTask task, [int by = 1]) async {
    final done = (task.completedCount + by).clamp(0, task.targetCount);
    final isDone = done >= task.targetCount;
    final now = DateTime.now();

    final next = task.copyWith(
      completedCount: done,
      status: isDone
          ? TaskStatus.completed
          : (done > 0 ? TaskStatus.inProgress : TaskStatus.notStarted),
      completedAt: isDone ? now : null,
      updatedAt: now,
    );
    await put(next);

    if (isDone) {
      await ref
          .read(activityProvider.notifier)
          .log(
            type: ActivityType.taskCompleted,
            title: task.title,
            subtitle: task.category.label,
            taskId: task.id,
            at: now,
          );
    }
  }

  Future<void> setStatus(DailyTask task, TaskStatus status) async {
    final now = DateTime.now();
    await put(
      task.copyWith(
        status: status,
        completedCount: status == TaskStatus.completed
            ? task.targetCount
            : task.completedCount,
        completedAt: status == TaskStatus.completed ? now : null,
        updatedAt: now,
      ),
    );
  }

  /// Builds today's plan if it has not been generated yet.
  Future<List<DailyTask>> ensurePlanFor(DateTime date) async {
    final day = dayOf(date);
    final existing = forDay(day);
    final logs = ref.read(dayLogsProvider);
    final log = logs.where((l) => dayOf(l.date) == day).firstOrNull;

    if (log?.planGenerated == true || existing.isNotEmpty) {
      if (!_needsPlanRefresh(existing)) return existing;
      final stale = existing
          .where((t) => t.isAutoGenerated && t.status != TaskStatus.completed)
          .toList();
      for (final task in stale) {
        await delete(task.id);
      }
      await ref
          .read(dayLogsProvider.notifier)
          .put((log ?? DayLog(date: day)).copyWith(planGenerated: false));
    }

    final settings = ref.read(settingsProvider);
    final weekStart = startOfWeek(day);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekTasks = state
        .where(
          (t) =>
              !dayOf(t.date).isBefore(weekStart) &&
              dayOf(t.date).isBefore(weekEnd),
        )
        .toList();

    final generated = PlanGenerator(settings).generate(
      date: day,
      weekTasks: weekTasks,
      weekLogs: logs,
      context: PlanContext(
        applications: ref.read(applicationsProvider),
        opportunities: ref.read(opportunitiesProvider),
        companies: ref.read(companiesProvider),
        agencies: ref.read(agenciesProvider),
        followUps: ref.read(followUpsProvider),
      ),
    );

    if (generated.isNotEmpty) await putAll(generated);

    await ref
        .read(dayLogsProvider.notifier)
        .put((log ?? DayLog(date: day)).copyWith(planGenerated: true));

    return forDay(day);
  }

  bool _needsPlanRefresh(List<DailyTask> tasks) {
    final generated = tasks.where(
      (t) => t.isAutoGenerated && t.status != TaskStatus.completed,
    );
    for (final task in generated) {
      if (task.recurrence == 'applications' && task.targetCount > 4) {
        return true;
      }
      if (task.recurrence == 'recruiter_messages' && task.targetCount > 5) {
        return true;
      }
      if (task.recurrence == 'connections' && task.targetCount > 8) {
        return true;
      }
      if (task.recurrence == 'hiring_managers' && task.targetCount > 2) {
        return true;
      }
      if (task.recurrence == 'follow_ups' && task.targetCount > 4) {
        return true;
      }
      if (task.recurrence == 'research' && task.targetCount > 2) {
        return true;
      }
      if (task.recurrence == 'agencies' && task.targetCount > 1) {
        return true;
      }
      if (task.recurrence == 'preparation' && task.estimatedMinutes > 60) {
        return true;
      }
    }
    return false;
  }

  /// Discards the auto-generated tasks for a day and rebuilds them.
  Future<void> regenerate(DateTime date) async {
    final day = dayOf(date);
    final auto = forDay(day)
        .where((t) => t.isAutoGenerated && t.status != TaskStatus.completed)
        .toList();
    for (final t in auto) {
      await delete(t.id);
    }
    final logs = ref.read(dayLogsProvider);
    final log = logs.where((l) => dayOf(l.date) == day).firstOrNull;
    await ref
        .read(dayLogsProvider.notifier)
        .put((log ?? DayLog(date: day)).copyWith(planGenerated: false));
    await ensurePlanFor(day);
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<DailyTask>>((
  ref,
) {
  throw UnimplementedError('tasksProvider must be overridden');
});

class DayLogsNotifier extends CollectionNotifier<DayLog> {
  DayLogsNotifier(super.ref, super.initial);

  @override
  String idOf(DayLog item) => item.dayKey;

  @override
  Future<void> persist(DayLog item) => repo.upsertDayLog(item);

  @override
  Future<void> remove(String id) async {
    // day logs are never individually deleted
  }

  DayLog forDay(DateTime date) {
    final d = dayOf(date);
    return state.where((l) => dayOf(l.date) == d).firstOrNull ??
        DayLog(date: d);
  }

  Future<void> setDayType(DateTime date, DayType type) async {
    final log = forDay(date);
    await put(log.copyWith(dayType: type));
  }
}

final dayLogsProvider = StateNotifierProvider<DayLogsNotifier, List<DayLog>>((
  ref,
) {
  throw UnimplementedError('dayLogsProvider must be overridden');
});

/// Today's tasks, sorted.
final todayTasksProvider = Provider<List<DailyTask>>((ref) {
  final all = ref.watch(tasksProvider);
  final today = dayOf(DateTime.now());
  final items = all.where((t) => dayOf(t.date) == today).toList();
  items.sort((a, b) {
    final done = (a.status.isDone ? 1 : 0).compareTo(b.status.isDone ? 1 : 0);
    if (done != 0) return done;
    final p = b.priority.weight.compareTo(a.priority.weight);
    if (p != 0) return p;
    return a.category.index.compareTo(b.category.index);
  });
  return items;
});

// ===========================================================================
// Follow-ups
// ===========================================================================

class FollowUpsNotifier extends CollectionNotifier<FollowUp> {
  FollowUpsNotifier(super.ref, super.initial);

  @override
  String idOf(FollowUp item) => item.id;

  @override
  Future<void> persist(FollowUp item) => repo.upsertFollowUp(item);

  @override
  Future<void> remove(String id) => repo.deleteFollowUp(id);

  Future<void> complete(FollowUp followUp, {String note = ''}) async {
    final now = DateTime.now();
    await put(
      followUp.copyWith(
        isCompleted: true,
        completedAt: now,
        notes: note.isEmpty ? followUp.notes : note,
        updatedAt: now,
      ),
    );

    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.followUpCompleted,
          title: 'Followed up: ${followUp.title}',
          subtitle: followUp.context,
          applicationId: followUp.applicationId,
          contactId: followUp.contactId,
          agencyId: followUp.agencyId,
          companyId: followUp.companyId,
          at: now,
        );

    // touch the linked application so aging restarts
    final appId = followUp.applicationId;
    if (appId != null) {
      final apps = ref.read(applicationsProvider.notifier);
      final app = apps.byId(appId);
      if (app != null) {
        await apps.put(app.copyWith(lastActivity: now, updatedAt: now));
      }
    }
  }

  /// Silently closes outstanding follow-ups for an application that has
  /// since moved on.
  Future<void> completeForApplication(String applicationId) async {
    final open = state
        .where((f) => f.applicationId == applicationId && !f.isCompleted)
        .toList();
    final now = DateTime.now();
    for (final f in open) {
      await put(
        f.copyWith(isCompleted: true, completedAt: now, updatedAt: now),
      );
    }
  }

  Future<void> snooze(FollowUp followUp, int days) => put(
    followUp.copyWith(
      dueDate: dayOf(DateTime.now()).add(Duration(days: days)),
      updatedAt: DateTime.now(),
    ),
  );
}

final followUpsProvider =
    StateNotifierProvider<FollowUpsNotifier, List<FollowUp>>((ref) {
      throw UnimplementedError('followUpsProvider must be overridden');
    });

/// Open follow-ups grouped into overdue / today / this week / upcoming.
class FollowUpBuckets {
  const FollowUpBuckets({
    required this.overdue,
    required this.today,
    required this.thisWeek,
    required this.upcoming,
  });

  final List<FollowUp> overdue;
  final List<FollowUp> today;
  final List<FollowUp> thisWeek;
  final List<FollowUp> upcoming;

  int get actionableCount => overdue.length + today.length;
  int get total =>
      overdue.length + today.length + thisWeek.length + upcoming.length;
}

final followUpBucketsProvider = Provider<FollowUpBuckets>((ref) {
  final open =
      ref.watch(followUpsProvider).where((f) => !f.isCompleted).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  return FollowUpBuckets(
    overdue: open.where((f) => f.isOverdue).toList(),
    today: open.where((f) => f.isDueToday).toList(),
    thisWeek: open.where((f) => f.isDueThisWeek).toList(),
    upcoming: open.where((f) => f.daysUntilDue > 7).toList(),
  );
});

// ===========================================================================
// Interviews
// ===========================================================================

class InterviewsNotifier extends CollectionNotifier<Interview> {
  InterviewsNotifier(super.ref, super.initial);

  @override
  String idOf(Interview item) => item.id;

  @override
  Future<void> persist(Interview item) => repo.upsertInterview(item);

  @override
  Future<void> remove(String id) => repo.deleteInterview(id);

  Future<void> schedule(Interview interview) async {
    await put(interview);
    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.interviewScheduled,
          title: '${interview.stage.label} scheduled',
          subtitle: '${interview.companyName} · ${interview.roleTitle}',
          interviewId: interview.id,
          applicationId: interview.applicationId,
          companyId: interview.companyId,
        );

    // keep the linked application's stage in step
    final appId = interview.applicationId;
    if (appId != null) {
      final apps = ref.read(applicationsProvider.notifier);
      final app = apps.byId(appId);
      final target = interview.stage.applicationStage;
      if (app != null && app.stage.order < target.order) {
        await apps.moveToStage(app, target);
      }
    }
  }

  Future<void> completeReview(Interview interview) async {
    await put(
      interview.copyWith(
        status: InterviewStatus.completed,
        updatedAt: DateTime.now(),
      ),
    );
    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.interviewCompleted,
          title: '${interview.stage.label} completed',
          subtitle: interview.selfRating != null
              ? '${interview.companyName} · rated ${interview.selfRating}/10'
              : interview.companyName,
          interviewId: interview.id,
          applicationId: interview.applicationId,
        );
  }
}

final interviewsProvider =
    StateNotifierProvider<InterviewsNotifier, List<Interview>>((ref) {
      throw UnimplementedError('interviewsProvider must be overridden');
    });

final upcomingInterviewsProvider = Provider<List<Interview>>((ref) {
  final items =
      ref
          .watch(interviewsProvider)
          .where((i) => i.status == InterviewStatus.upcoming)
          .toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return items;
});

// ===========================================================================
// Resumes, prep, portfolio, reviews
// ===========================================================================

class ResumesNotifier extends CollectionNotifier<Resume> {
  ResumesNotifier(super.ref, super.initial);

  @override
  String idOf(Resume item) => item.id;

  @override
  Future<void> persist(Resume item) => repo.upsertResume(item);

  @override
  Future<void> remove(String id) => repo.deleteResume(id);
}

final resumesProvider = StateNotifierProvider<ResumesNotifier, List<Resume>>((
  ref,
) {
  throw UnimplementedError('resumesProvider must be overridden');
});

class PrepNotifier extends CollectionNotifier<PrepSession> {
  PrepNotifier(super.ref, super.initial);

  @override
  String idOf(PrepSession item) => item.id;

  @override
  Future<void> persist(PrepSession item) => repo.upsertPrepSession(item);

  @override
  Future<void> remove(String id) => repo.deletePrepSession(id);

  Future<void> log(PrepSession session) async {
    await put(session);
    await ref
        .read(activityProvider.notifier)
        .log(
          type: ActivityType.prepLogged,
          title: '${session.minutes} min ${session.category.label}',
          subtitle: session.topic,
          at: session.date,
        );
  }

  /// Minutes per category within a date range.
  Map<PrepCategory, int> minutesByCategory({DateTime? from, DateTime? to}) {
    final out = {for (final c in PrepCategory.values) c: 0};
    for (final s in state) {
      if (from != null && s.date.isBefore(from)) continue;
      if (to != null && s.date.isAfter(to)) continue;
      out[s.category] = (out[s.category] ?? 0) + s.minutes;
    }
    return out;
  }
}

final prepProvider = StateNotifierProvider<PrepNotifier, List<PrepSession>>((
  ref,
) {
  throw UnimplementedError('prepProvider must be overridden');
});

class ProjectsNotifier extends CollectionNotifier<PortfolioProject> {
  ProjectsNotifier(super.ref, super.initial);

  @override
  String idOf(PortfolioProject item) => item.id;

  @override
  Future<void> persist(PortfolioProject item) => repo.upsertProject(item);

  @override
  Future<void> remove(String id) => repo.deleteProject(id);
}

final projectsProvider =
    StateNotifierProvider<ProjectsNotifier, List<PortfolioProject>>((ref) {
      throw UnimplementedError('projectsProvider must be overridden');
    });

class WeeklyReviewsNotifier extends CollectionNotifier<WeeklyReview> {
  WeeklyReviewsNotifier(super.ref, super.initial);

  @override
  String idOf(WeeklyReview item) => item.id;

  @override
  Future<void> persist(WeeklyReview item) => repo.upsertWeeklyReview(item);

  @override
  Future<void> remove(String id) async {}

  WeeklyReview? forWeek(DateTime weekStart) {
    final w = dayOf(weekStart);
    return state.where((r) => dayOf(r.weekStart) == w).firstOrNull;
  }
}

final weeklyReviewsProvider =
    StateNotifierProvider<WeeklyReviewsNotifier, List<WeeklyReview>>((ref) {
      throw UnimplementedError('weeklyReviewsProvider must be overridden');
    });

// ===========================================================================
// Derived analytics
// ===========================================================================

final metricsProvider = Provider<ApplicationMetrics>((ref) {
  return ApplicationMetrics(
    ref.watch(applicationsProvider),
    ref.watch(settingsProvider),
  );
});

final scoringProvider = Provider<ScoringService>(
  (ref) => ScoringService(ref.watch(settingsProvider)),
);

final streakServiceProvider = Provider<StreakService>(
  (ref) => StreakService(ref.watch(settingsProvider)),
);

final streakStatsProvider = Provider<StreakStats>((ref) {
  return ref
      .watch(streakServiceProvider)
      .compute(
        allTasks: ref.watch(tasksProvider),
        logs: ref.watch(dayLogsProvider),
      );
});

final todayScoreProvider = Provider<DailyScore>((ref) {
  final today = dayOf(DateTime.now());
  return ref
      .watch(streakServiceProvider)
      .scoreFor(
        date: today,
        tasks: ref.watch(tasksProvider),
        log: ref
            .watch(dayLogsProvider)
            .where((l) => dayOf(l.date) == today)
            .firstOrNull,
      );
});

final heatmapProvider = Provider<List<DailyScore>>((ref) {
  return ref
      .watch(streakServiceProvider)
      .history(
        allTasks: ref.watch(tasksProvider),
        logs: ref.watch(dayLogsProvider),
      );
});

final missionStatusProvider = Provider<MissionStatus>((ref) {
  return MissionStatus.evaluate(
    metrics: ref.watch(metricsProvider),
    streak: ref.watch(streakStatsProvider),
    settings: ref.watch(settingsProvider),
  );
});

final insightsProvider = Provider<List<Insight>>((ref) {
  return InsightsEngine(
    settings: ref.watch(settingsProvider),
    applications: ref.watch(applicationsProvider),
    tasks: ref.watch(tasksProvider),
    followUps: ref.watch(followUpsProvider),
    contacts: ref.watch(contactsProvider),
    agencies: ref.watch(agenciesProvider),
    resumes: ref.watch(resumesProvider),
    interviews: ref.watch(interviewsProvider),
    streak: ref.watch(streakStatsProvider),
  ).generate();
});

final countryAllocationProvider = Provider<List<CountryAllocation>>(
  (ref) => ref.watch(metricsProvider).countryAllocation(),
);

// ===========================================================================
// Bootstrap
// ===========================================================================

/// Loads every collection once and produces the provider overrides used to
/// build the app. Keeping this in one place means the UI never deals with
/// loading states for the core data.
class AppBootstrap {
  const AppBootstrap._(this.overrides, this.seedResult);

  final List<Override> overrides;
  final SeedResult? seedResult;

  static Future<AppBootstrap> load({
    AppConfig config = const AppConfig(
      supabaseUrl: '',
      supabasePublishableKey: '',
    ),
  }) async {
    final DataRepository repo = config.hasSupabase
        ? SupabaseDataRepository(config)
        : LocalDataRepository();
    await repo.init();

    final settings = await repo.loadSettings();

    // first launch: import the curated target database
    SeedResult? seedResult;
    if ((await repo.getCompanies()).isEmpty) {
      try {
        seedResult = await SeedLoader(repo).seed();
      } catch (e, st) {
        debugPrint('Seed import failed: $e\n$st');
      }
    }

    // the four resume variants the strategy is built around
    if ((await repo.getResumes()).isEmpty) {
      final now = DateTime.now();
      for (final (i, spec) in _defaultResumes.indexed) {
        await repo.upsertResume(
          Resume(
            id: 'resume_${i + 1}',
            name: spec.$1,
            targetRoles: spec.$2,
            skillsEmphasized: spec.$3,
            lastUpdated: now,
            createdAt: now,
          ),
        );
      }
    }

    final results = await Future.wait([
      repo.getApplications(),
      repo.getCompanies(),
      repo.getAgencies(),
      repo.getContacts(),
      repo.getInteractions(),
      repo.getOpportunities(),
      repo.getTasks(),
      repo.getDayLogs(),
      repo.getFollowUps(),
      repo.getInterviews(),
      repo.getResumes(),
      repo.getPrepSessions(),
      repo.getProjects(),
      repo.getActivities(),
      repo.getWeeklyReviews(),
    ]);

    return AppBootstrap._([
      repositoryProvider.overrideWithValue(repo),
      settingsProvider.overrideWith((ref) => SettingsNotifier(repo, settings)),
      applicationsProvider.overrideWith(
        (ref) => ApplicationsNotifier(ref, results[0] as List<JobApplication>),
      ),
      companiesProvider.overrideWith(
        (ref) => CompaniesNotifier(ref, results[1] as List<Company>),
      ),
      agenciesProvider.overrideWith(
        (ref) => AgenciesNotifier(ref, results[2] as List<RecruitmentAgency>),
      ),
      contactsProvider.overrideWith(
        (ref) => ContactsNotifier(ref, results[3] as List<NetworkContact>),
      ),
      interactionsProvider.overrideWith(
        (ref) =>
            InteractionsNotifier(ref, results[4] as List<ContactInteraction>),
      ),
      opportunitiesProvider.overrideWith(
        (ref) => OpportunitiesNotifier(ref, results[5] as List<JobOpportunity>),
      ),
      tasksProvider.overrideWith(
        (ref) => TasksNotifier(ref, results[6] as List<DailyTask>),
      ),
      dayLogsProvider.overrideWith(
        (ref) => DayLogsNotifier(ref, results[7] as List<DayLog>),
      ),
      followUpsProvider.overrideWith(
        (ref) => FollowUpsNotifier(ref, results[8] as List<FollowUp>),
      ),
      interviewsProvider.overrideWith(
        (ref) => InterviewsNotifier(ref, results[9] as List<Interview>),
      ),
      resumesProvider.overrideWith(
        (ref) => ResumesNotifier(ref, results[10] as List<Resume>),
      ),
      prepProvider.overrideWith(
        (ref) => PrepNotifier(ref, results[11] as List<PrepSession>),
      ),
      projectsProvider.overrideWith(
        (ref) => ProjectsNotifier(ref, results[12] as List<PortfolioProject>),
      ),
      activityProvider.overrideWith(
        (ref) => ActivityNotifier(ref, results[13] as List<ActivityEvent>),
      ),
      weeklyReviewsProvider.overrideWith(
        (ref) => WeeklyReviewsNotifier(ref, results[14] as List<WeeklyReview>),
      ),
    ], seedResult);
  }
}

/// (name, target roles, skills emphasised) for the starting resume set.
const _defaultResumes = <(String, List<String>, List<String>)>[
  (
    'Backend / Software Engineer',
    ['Backend Engineer', 'Software Engineer', 'Full Stack Engineer'],
    ['Node.js', 'Python', 'REST APIs', 'PostgreSQL', 'AWS', 'Microservices'],
  ),
  (
    'Applied AI Engineer',
    ['Applied AI Engineer', 'ML Engineer', 'Computer Vision / OCR'],
    ['RAG', 'LLMs', 'Embeddings', 'Vector databases', 'OCR', 'PyTorch'],
  ),
  (
    'Mobile Engineer',
    ['Mobile Engineer'],
    ['Flutter', 'Dart', 'Android', 'iOS', 'REST APIs', 'CI/CD'],
  ),
  (
    'Data / Automation Engineer',
    ['Data Engineer', 'Automation Engineer'],
    ['Python', 'ETL', 'SQL', 'Airflow', 'Pandas', 'Automation'],
  ),
];
