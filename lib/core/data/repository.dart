import '../domain/models.dart';
import '../domain/settings.dart';

/// Backend-agnostic contract for the whole data layer.
///
/// The app talks only to this interface, so swapping the local store for
/// Supabase is a matter of providing a second implementation and changing
/// one provider override — no feature code changes.
abstract class DataRepository {
  Future<void> init();

  // -- settings ------------------------------------------------------------
  Future<AppSettings> loadSettings();
  Future<void> saveSettings(AppSettings settings);

  // -- applications --------------------------------------------------------
  Future<List<JobApplication>> getApplications();
  Future<void> upsertApplication(JobApplication application);
  Future<void> deleteApplication(String id);

  // -- companies -----------------------------------------------------------
  Future<List<Company>> getCompanies();
  Future<void> upsertCompany(Company company);
  Future<void> upsertCompanies(List<Company> companies);
  Future<void> deleteCompany(String id);

  // -- agencies ------------------------------------------------------------
  Future<List<RecruitmentAgency>> getAgencies();
  Future<void> upsertAgency(RecruitmentAgency agency);
  Future<void> upsertAgencies(List<RecruitmentAgency> agencies);
  Future<void> deleteAgency(String id);

  // -- networking ----------------------------------------------------------
  Future<List<NetworkContact>> getContacts();
  Future<void> upsertContact(NetworkContact contact);
  Future<void> deleteContact(String id);

  Future<List<ContactInteraction>> getInteractions();
  Future<void> upsertInteraction(ContactInteraction interaction);
  Future<void> deleteInteraction(String id);

  // -- opportunities -------------------------------------------------------
  Future<List<JobOpportunity>> getOpportunities();
  Future<void> upsertOpportunity(JobOpportunity opportunity);
  Future<void> deleteOpportunity(String id);

  // -- tasks & days --------------------------------------------------------
  Future<List<DailyTask>> getTasks();
  Future<void> upsertTask(DailyTask task);
  Future<void> upsertTasks(List<DailyTask> tasks);
  Future<void> deleteTask(String id);

  Future<List<DayLog>> getDayLogs();
  Future<void> upsertDayLog(DayLog log);

  // -- follow-ups ----------------------------------------------------------
  Future<List<FollowUp>> getFollowUps();
  Future<void> upsertFollowUp(FollowUp followUp);
  Future<void> deleteFollowUp(String id);

  // -- interviews ----------------------------------------------------------
  Future<List<Interview>> getInterviews();
  Future<void> upsertInterview(Interview interview);
  Future<void> deleteInterview(String id);

  // -- resumes -------------------------------------------------------------
  Future<List<Resume>> getResumes();
  Future<void> upsertResume(Resume resume);
  Future<void> deleteResume(String id);

  // -- preparation ---------------------------------------------------------
  Future<List<PrepSession>> getPrepSessions();
  Future<void> upsertPrepSession(PrepSession session);
  Future<void> deletePrepSession(String id);

  // -- portfolio -----------------------------------------------------------
  Future<List<PortfolioProject>> getProjects();
  Future<void> upsertProject(PortfolioProject project);
  Future<void> deleteProject(String id);

  // -- activity ------------------------------------------------------------
  Future<List<ActivityEvent>> getActivities();
  Future<void> addActivity(ActivityEvent event);
  Future<void> deleteActivity(String id);

  // -- reviews -------------------------------------------------------------
  Future<List<WeeklyReview>> getWeeklyReviews();
  Future<void> upsertWeeklyReview(WeeklyReview review);

  // -- maintenance ---------------------------------------------------------
  /// Wipes user data. Seeded reference lists are restored on next launch.
  Future<void> clearAll();
}
