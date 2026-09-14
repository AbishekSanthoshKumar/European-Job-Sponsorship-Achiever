import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// All enums are persisted by [id]; never persist the index, so reordering
/// or inserting values stays safe across releases.
mixin _Persisted {
  String get id;
}

T _byId<T extends _Persisted>(List<T> values, String? id, T fallback) {
  if (id == null) return fallback;
  for (final v in values) {
    if (v.id == id) return v;
  }
  return fallback;
}

// --------------------------------------------------------------------------
// Application pipeline
// --------------------------------------------------------------------------

enum ApplicationStage with _Persisted {
  saved('saved', 'Saved', 0),
  readyToApply('ready_to_apply', 'Ready to Apply', 1),
  applied('applied', 'Applied', 2),
  recruiterScreen('recruiter_screen', 'Recruiter Screen', 3),
  hrInterview('hr_interview', 'HR Interview', 4),
  technicalInterview('technical_interview', 'Technical Interview', 5),
  codingAssessment('coding_assessment', 'Coding Assessment', 6),
  systemDesign('system_design', 'System Design', 7),
  finalInterview('final_interview', 'Final Interview', 8),
  offer('offer', 'Offer', 9),
  accepted('accepted', 'Accepted', 10),
  // terminal / negative outcomes
  rejected('rejected', 'Rejected', -1),
  withdrawn('withdrawn', 'Withdrawn', -2),
  ghosted('ghosted', 'Ghosted', -3),
  positionClosed('position_closed', 'Position Closed', -4);

  const ApplicationStage(this.id, this.label, this.order);

  @override
  final String id;
  final String label;

  /// Funnel position. Negative values are closed/failed outcomes.
  final int order;

  bool get isClosed => order < 0;
  bool get isActive => !isClosed && this != accepted;

  /// Applied or beyond — i.e. the application actually went out.
  bool get hasApplied => order >= applied.order;

  /// Any employer reply counts as a response.
  bool get isResponse => order >= recruiterScreen.order;

  /// Reached a real interview round.
  bool get isInterview => order >= hrInterview.order;

  bool get isOffer => order >= offer.order;

  static const pipeline = [
    saved,
    readyToApply,
    applied,
    recruiterScreen,
    hrInterview,
    technicalInterview,
    codingAssessment,
    systemDesign,
    finalInterview,
    offer,
    accepted,
  ];

  static const outcomes = [rejected, withdrawn, ghosted, positionClosed];

  static ApplicationStage fromId(String? id) =>
      _byId(ApplicationStage.values, id, saved);

  Color get color => switch (this) {
        saved => AppColors.textTertiary,
        readyToApply => AppColors.info,
        applied => AppColors.primary,
        recruiterScreen || hrInterview => AppColors.purple,
        technicalInterview || codingAssessment || systemDesign =>
          AppColors.accent,
        finalInterview => AppColors.warning,
        offer || accepted => AppColors.success,
        rejected => AppColors.danger,
        withdrawn || ghosted || positionClosed => AppColors.textTertiary,
      };
}

enum ApplicationSource with _Persisted {
  linkedIn('linkedin', 'LinkedIn'),
  companyWebsite('company_website', 'Company Website'),
  recruitmentAgency('recruitment_agency', 'Recruitment Agency'),
  referral('referral', 'Referral'),
  jobBoard('job_board', 'Job Board'),
  recruiterOutreach('recruiter_outreach', 'Recruiter Outreach'),
  coldApplication('cold_application', 'Cold Application'),
  governmentPortal('government_portal', 'Government Portal'),
  other('other', 'Other');

  const ApplicationSource(this.id, this.label);
  @override
  final String id;
  final String label;

  static ApplicationSource fromId(String? id) =>
      _byId(ApplicationSource.values, id, other);
}

enum WorkMode with _Persisted {
  onsite('onsite', 'Onsite'),
  hybrid('hybrid', 'Hybrid'),
  remote('remote', 'Remote'),
  unknown('unknown', 'Unknown');

  const WorkMode(this.id, this.label);
  @override
  final String id;
  final String label;

  static WorkMode fromId(String? id) => _byId(WorkMode.values, id, unknown);
}

enum EmploymentType with _Persisted {
  fullTime('full_time', 'Full-time'),
  contract('contract', 'Contract'),
  internship('internship', 'Internship'),
  partTime('part_time', 'Part-time');

  const EmploymentType(this.id, this.label);
  @override
  final String id;
  final String label;

  static EmploymentType fromId(String? id) =>
      _byId(EmploymentType.values, id, fullTime);
}

enum Seniority with _Persisted {
  junior('junior', 'Junior'),
  mid('mid', 'Mid-level'),
  senior('senior', 'Senior'),
  lead('lead', 'Lead / Staff'),
  unspecified('unspecified', 'Unspecified');

  const Seniority(this.id, this.label);
  @override
  final String id;
  final String label;

  static Seniority fromId(String? id) => _byId(Seniority.values, id, mid);
}

// --------------------------------------------------------------------------
// Immigration — the decisive axis for this search
// --------------------------------------------------------------------------

enum TriState with _Persisted {
  yes('yes', 'Yes'),
  no('no', 'No'),
  unknown('unknown', 'Unknown');

  const TriState(this.id, this.label);
  @override
  final String id;
  final String label;

  static TriState fromId(String? id) => _byId(TriState.values, id, unknown);

  Color get color => switch (this) {
        yes => AppColors.success,
        no => AppColors.danger,
        unknown => AppColors.textTertiary,
      };
}

enum WorkAuthRequirement with _Persisted {
  euOnly('eu_only', 'EU nationals only'),
  existingPermit('existing_permit', 'Existing work permit required'),
  sponsorshipPossible('sponsorship_possible', 'Sponsorship possible'),
  explicitSponsorship('explicit_sponsorship', 'Explicit sponsorship offered'),
  unknown('unknown', 'Unknown');

  const WorkAuthRequirement(this.id, this.label);
  @override
  final String id;
  final String label;

  static WorkAuthRequirement fromId(String? id) =>
      _byId(WorkAuthRequirement.values, id, unknown);

  /// Used by the opportunity score — how promising this is for a non-EU applicant.
  double get visaScore => switch (this) {
        explicitSponsorship => 1.0,
        sponsorshipPossible => 0.75,
        unknown => 0.4,
        existingPermit => 0.1,
        euOnly => 0.0,
      };

  Color get color => switch (this) {
        explicitSponsorship => AppColors.success,
        sponsorshipPossible => AppColors.accent,
        unknown => AppColors.textTertiary,
        existingPermit => AppColors.warning,
        euOnly => AppColors.danger,
      };
}

// --------------------------------------------------------------------------
// Companies
// --------------------------------------------------------------------------

enum CompanyType with _Persisted {
  startup('startup', 'Startup'),
  scaleup('scaleup', 'Scaleup'),
  enterprise('enterprise', 'Enterprise'),
  consultancy('consultancy', 'Consultancy'),
  fintech('fintech', 'Fintech'),
  aiCompany('ai_company', 'AI Company'),
  productCompany('product_company', 'Product Company'),
  outsourcing('outsourcing', 'Outsourcing'),
  other('other', 'Other');

  const CompanyType(this.id, this.label);
  @override
  final String id;
  final String label;

  static CompanyType fromId(String? id) => _byId(CompanyType.values, id, other);
}

enum CompanyPriority with _Persisted {
  dream('dream', 'Dream Company', 4),
  high('high', 'High Priority', 3),
  medium('medium', 'Medium Priority', 2),
  low('low', 'Low Priority', 1);

  const CompanyPriority(this.id, this.label, this.weight);
  @override
  final String id;
  final String label;
  final int weight;

  static CompanyPriority fromId(String? id) =>
      _byId(CompanyPriority.values, id, medium);

  double get score => weight / 4.0;

  Color get color => switch (this) {
        dream => AppColors.accent,
        high => AppColors.success,
        medium => AppColors.info,
        low => AppColors.textTertiary,
      };

  IconData get icon => switch (this) {
        dream => Icons.star_rounded,
        high => Icons.keyboard_double_arrow_up_rounded,
        medium => Icons.drag_handle_rounded,
        low => Icons.keyboard_arrow_down_rounded,
      };
}

enum CompanyRelationship with _Persisted {
  notResearched('not_researched', 'Not Researched'),
  researched('researched', 'Researched'),
  jobsFound('jobs_found', 'Jobs Found'),
  applied('applied', 'Applied'),
  recruiterContacted('recruiter_contacted', 'Recruiter Contacted'),
  employeeContacted('employee_contacted', 'Employee Contacted'),
  referralRequested('referral_requested', 'Referral Requested'),
  interviewing('interviewing', 'Interviewing'),
  rejected('rejected', 'Rejected'),
  futureTarget('future_target', 'Future Target');

  const CompanyRelationship(this.id, this.label);
  @override
  final String id;
  final String label;

  static CompanyRelationship fromId(String? id) =>
      _byId(CompanyRelationship.values, id, notResearched);

  Color get color => switch (this) {
        notResearched => AppColors.textTertiary,
        researched => AppColors.info,
        jobsFound => AppColors.primary,
        applied => AppColors.primary,
        recruiterContacted || employeeContacted => AppColors.purple,
        referralRequested => AppColors.accent,
        interviewing => AppColors.warning,
        rejected => AppColors.danger,
        futureTarget => AppColors.textSecondary,
      };
}

// --------------------------------------------------------------------------
// Recruitment agencies
// --------------------------------------------------------------------------

enum AgencyStatus with _Persisted {
  notContacted('not_contacted', 'Not Contacted'),
  registered('registered', 'Registered'),
  contacted('contacted', 'Contacted'),
  responded('responded', 'Responded'),
  callScheduled('call_scheduled', 'Call Scheduled'),
  activeRelationship('active_relationship', 'Active Relationship'),
  jobSubmitted('job_submitted', 'Job Submitted'),
  inactive('inactive', 'Inactive');

  const AgencyStatus(this.id, this.label);
  @override
  final String id;
  final String label;

  static AgencyStatus fromId(String? id) =>
      _byId(AgencyStatus.values, id, notContacted);

  Color get color => switch (this) {
        notContacted => AppColors.textTertiary,
        registered => AppColors.info,
        contacted => AppColors.primary,
        responded => AppColors.purple,
        callScheduled => AppColors.accent,
        activeRelationship => AppColors.success,
        jobSubmitted => AppColors.success,
        inactive => AppColors.textTertiary,
      };
}

enum AgencyPriority with _Persisted {
  highest('highest', 'Highest Priority', 4),
  high('high', 'High Priority', 3),
  medium('medium', 'Medium Priority', 2),
  low('low', 'Low Priority', 1),
  ignore('ignore', 'Ignore', 0);

  const AgencyPriority(this.id, this.label, this.weight);
  @override
  final String id;
  final String label;
  final int weight;

  static AgencyPriority fromId(String? id) =>
      _byId(AgencyPriority.values, id, medium);

  Color get color => switch (this) {
        highest => AppColors.accent,
        high => AppColors.success,
        medium => AppColors.info,
        low => AppColors.textSecondary,
        ignore => AppColors.textTertiary,
      };
}

enum AgencySpecialization with _Persisted {
  softwareEngineering('software_engineering', 'Software Engineering'),
  ai('ai', 'AI'),
  data('data', 'Data'),
  backend('backend', 'Backend'),
  mobile('mobile', 'Mobile'),
  cloud('cloud', 'Cloud'),
  generalTechnology('general_technology', 'General Technology'),
  generalRecruitment('general_recruitment', 'General Recruitment'),
  jobBoard('job_board', 'Job Board'),
  governmentPortal('government_portal', 'Government Portal'),
  recruiterDatabase('recruiter_database', 'Recruiter Database');

  const AgencySpecialization(this.id, this.label);
  @override
  final String id;
  final String label;

  static AgencySpecialization fromId(String? id) =>
      _byId(AgencySpecialization.values, id, generalTechnology);
}

// --------------------------------------------------------------------------
// Networking
// --------------------------------------------------------------------------

enum ContactType with _Persisted {
  recruiter('recruiter', 'Recruiter'),
  hiringManager('hiring_manager', 'Hiring Manager'),
  engineer('engineer', 'Engineer'),
  employee('employee', 'Employee'),
  founder('founder', 'Founder'),
  referrer('referrer', 'Referrer'),
  other('other', 'Other');

  const ContactType(this.id, this.label);
  @override
  final String id;
  final String label;

  static ContactType fromId(String? id) => _byId(ContactType.values, id, other);

  IconData get icon => switch (this) {
        recruiter => Icons.support_agent_rounded,
        hiringManager => Icons.badge_rounded,
        engineer => Icons.terminal_rounded,
        employee => Icons.person_rounded,
        founder => Icons.rocket_launch_rounded,
        referrer => Icons.handshake_rounded,
        other => Icons.person_outline_rounded,
      };
}

enum ContactStatus with _Persisted {
  notContacted('not_contacted', 'Not Contacted'),
  connectionRequested('connection_requested', 'Connection Requested'),
  connected('connected', 'Connected'),
  messaged('messaged', 'Messaged'),
  responded('responded', 'Responded'),
  conversationActive('conversation_active', 'Conversation Active'),
  referralRequested('referral_requested', 'Referral Requested'),
  referralReceived('referral_received', 'Referral Received'),
  inactive('inactive', 'Inactive');

  const ContactStatus(this.id, this.label);
  @override
  final String id;
  final String label;

  static ContactStatus fromId(String? id) =>
      _byId(ContactStatus.values, id, notContacted);

  Color get color => switch (this) {
        notContacted => AppColors.textTertiary,
        connectionRequested => AppColors.info,
        connected => AppColors.primary,
        messaged => AppColors.primary,
        responded || conversationActive => AppColors.success,
        referralRequested => AppColors.accent,
        referralReceived => AppColors.success,
        inactive => AppColors.textTertiary,
      };
}

// --------------------------------------------------------------------------
// Opportunities
// --------------------------------------------------------------------------

enum OpportunityStatus with _Persisted {
  inbox('inbox', 'Inbox'),
  researching('researching', 'Researching'),
  goodMatch('good_match', 'Good Match'),
  readyToApply('ready_to_apply', 'Ready to Apply'),
  applied('applied', 'Applied'),
  discarded('discarded', 'Discarded');

  const OpportunityStatus(this.id, this.label);
  @override
  final String id;
  final String label;

  static OpportunityStatus fromId(String? id) =>
      _byId(OpportunityStatus.values, id, inbox);

  Color get color => switch (this) {
        inbox => AppColors.info,
        researching => AppColors.purple,
        goodMatch => AppColors.success,
        readyToApply => AppColors.accent,
        applied => AppColors.primary,
        discarded => AppColors.textTertiary,
      };
}

// --------------------------------------------------------------------------
// Tasks
// --------------------------------------------------------------------------

enum TaskCategory with _Persisted {
  applications('applications', 'Applications'),
  networking('networking', 'Networking'),
  followUps('follow_ups', 'Follow-ups'),
  preparation('preparation', 'Preparation'),
  research('research', 'Research'),
  agencies('agencies', 'Agencies'),
  portfolio('portfolio', 'Portfolio'),
  admin('admin', 'Admin');

  const TaskCategory(this.id, this.label);
  @override
  final String id;
  final String label;

  static TaskCategory fromId(String? id) =>
      _byId(TaskCategory.values, id, admin);

  Color get color => switch (this) {
        applications => AppColors.primary,
        networking => AppColors.purple,
        followUps => AppColors.warning,
        preparation => AppColors.accent,
        research => AppColors.info,
        agencies => AppColors.success,
        portfolio => const Color(0xFFF472B6),
        admin => AppColors.textSecondary,
      };

  IconData get icon => switch (this) {
        applications => Icons.send_rounded,
        networking => Icons.groups_rounded,
        followUps => Icons.reply_rounded,
        preparation => Icons.school_rounded,
        research => Icons.travel_explore_rounded,
        agencies => Icons.business_center_rounded,
        portfolio => Icons.code_rounded,
        admin => Icons.settings_rounded,
      };
}

enum TaskStatus with _Persisted {
  notStarted('not_started', 'Not Started'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  skipped('skipped', 'Skipped'),
  rescheduled('rescheduled', 'Rescheduled');

  const TaskStatus(this.id, this.label);
  @override
  final String id;
  final String label;

  static TaskStatus fromId(String? id) =>
      _byId(TaskStatus.values, id, notStarted);

  bool get isDone => this == completed;

  Color get color => switch (this) {
        notStarted => AppColors.textTertiary,
        inProgress => AppColors.info,
        completed => AppColors.success,
        skipped => AppColors.textTertiary,
        rescheduled => AppColors.warning,
      };
}

enum TaskPriority with _Persisted {
  critical('critical', 'Critical', 3),
  high('high', 'High', 2),
  normal('normal', 'Normal', 1),
  low('low', 'Low', 0);

  const TaskPriority(this.id, this.label, this.weight);
  @override
  final String id;
  final String label;
  final int weight;

  static TaskPriority fromId(String? id) =>
      _byId(TaskPriority.values, id, normal);

  Color get color => switch (this) {
        critical => AppColors.danger,
        high => AppColors.warning,
        normal => AppColors.info,
        low => AppColors.textTertiary,
      };
}

/// How the daily generator redistributes a missed workload.
enum PlanMode with _Persisted {
  strict('strict', 'Strict',
      'Fixed daily quota. Misses are not redistributed.'),
  flexible('flexible', 'Flexible',
      'Remaining weekly work is spread evenly over the days left.'),
  catchUp('catch_up', 'Catch-up',
      'Front-loads the backlog so you recover the week quickly.');

  const PlanMode(this.id, this.label, this.description);
  @override
  final String id;
  final String label;
  final String description;

  static PlanMode fromId(String? id) => _byId(PlanMode.values, id, flexible);
}

/// Days explicitly marked as rest do not break a streak.
enum DayType with _Persisted {
  normal('normal', 'Normal Day'),
  rest('rest', 'Rest Day'),
  sick('sick', 'Sick Day'),
  emergency('emergency', 'Emergency Day');

  const DayType(this.id, this.label);
  @override
  final String id;
  final String label;

  static DayType fromId(String? id) => _byId(DayType.values, id, normal);

  bool get isExcused => this != normal;
}

// --------------------------------------------------------------------------
// Interviews
// --------------------------------------------------------------------------

enum InterviewStage with _Persisted {
  recruiterScreen('recruiter_screen', 'Recruiter Screen'),
  hr('hr', 'HR'),
  technical('technical', 'Technical'),
  codingAssessment('coding_assessment', 'Coding Assessment'),
  systemDesign('system_design', 'System Design'),
  hiringManager('hiring_manager', 'Hiring Manager'),
  finalRound('final_round', 'Final Round');

  const InterviewStage(this.id, this.label);
  @override
  final String id;
  final String label;

  static InterviewStage fromId(String? id) =>
      _byId(InterviewStage.values, id, technical);

  /// The application stage an interview at this round implies.
  ApplicationStage get applicationStage => switch (this) {
        recruiterScreen => ApplicationStage.recruiterScreen,
        hr => ApplicationStage.hrInterview,
        technical => ApplicationStage.technicalInterview,
        codingAssessment => ApplicationStage.codingAssessment,
        systemDesign => ApplicationStage.systemDesign,
        hiringManager || finalRound => ApplicationStage.finalInterview,
      };
}

enum InterviewStatus with _Persisted {
  upcoming('upcoming', 'Upcoming'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  const InterviewStatus(this.id, this.label);
  @override
  final String id;
  final String label;

  static InterviewStatus fromId(String? id) =>
      _byId(InterviewStatus.values, id, upcoming);

  Color get color => switch (this) {
        upcoming => AppColors.info,
        completed => AppColors.success,
        cancelled => AppColors.textTertiary,
      };
}

enum InterviewFormat with _Persisted {
  video('video', 'Video Call'),
  phone('phone', 'Phone'),
  onsite('onsite', 'Onsite'),
  takeHome('take_home', 'Take-home'),
  liveCoding('live_coding', 'Live Coding');

  const InterviewFormat(this.id, this.label);
  @override
  final String id;
  final String label;

  static InterviewFormat fromId(String? id) =>
      _byId(InterviewFormat.values, id, video);
}

// --------------------------------------------------------------------------
// Preparation
// --------------------------------------------------------------------------

enum PrepCategory with _Persisted {
  dsa('dsa', 'DSA'),
  systemDesign('system_design', 'System Design'),
  backend('backend', 'Backend'),
  ai('ai', 'AI'),
  behavioral('behavioral', 'Behavioral');

  const PrepCategory(this.id, this.label);
  @override
  final String id;
  final String label;

  static PrepCategory fromId(String? id) => _byId(PrepCategory.values, id, dsa);

  Color get color => switch (this) {
        dsa => AppColors.primary,
        systemDesign => AppColors.purple,
        backend => AppColors.success,
        ai => AppColors.accent,
        behavioral => AppColors.info,
      };

  List<String> get topics => switch (this) {
        dsa => const [
            'Arrays',
            'Strings',
            'Hash Maps',
            'Trees',
            'Graphs',
            'Dynamic Programming',
            'Recursion',
            'Sorting',
          ],
        systemDesign => const [
            'APIs',
            'Databases',
            'Caching',
            'Queues',
            'Scalability',
            'Microservices',
            'Authentication',
            'Distributed Systems',
          ],
        backend => const [
            'Node.js',
            'Python',
            'REST APIs',
            'PostgreSQL',
            'AWS',
          ],
        ai => const [
            'RAG',
            'LLM architecture',
            'Embeddings',
            'Vector databases',
            'OCR',
            'Computer Vision',
          ],
        behavioral => const [
            'STAR stories',
            'Leadership',
            'Conflict',
            'Failures',
            'Achievements',
          ],
      };
}

// --------------------------------------------------------------------------
// Portfolio
// --------------------------------------------------------------------------

enum ProjectStatus with _Persisted {
  planning('planning', 'Planning'),
  inProgress('in_progress', 'In Progress'),
  polishing('polishing', 'Polishing'),
  shipped('shipped', 'Shipped'),
  paused('paused', 'Paused');

  const ProjectStatus(this.id, this.label);
  @override
  final String id;
  final String label;

  static ProjectStatus fromId(String? id) =>
      _byId(ProjectStatus.values, id, inProgress);

  Color get color => switch (this) {
        planning => AppColors.textSecondary,
        inProgress => AppColors.primary,
        polishing => AppColors.accent,
        shipped => AppColors.success,
        paused => AppColors.textTertiary,
      };
}

// --------------------------------------------------------------------------
// Follow-ups & activity
// --------------------------------------------------------------------------

enum FollowUpType with _Persisted {
  application('application', 'Application'),
  recruiter('recruiter', 'Recruiter'),
  hiringManager('hiring_manager', 'Hiring Manager'),
  referral('referral', 'Referral Request'),
  agencyRegistration('agency_registration', 'Agency Registration'),
  interview('interview', 'Interview'),
  other('other', 'Other');

  const FollowUpType(this.id, this.label);
  @override
  final String id;
  final String label;

  static FollowUpType fromId(String? id) =>
      _byId(FollowUpType.values, id, other);

  IconData get icon => switch (this) {
        application => Icons.send_rounded,
        recruiter => Icons.support_agent_rounded,
        hiringManager => Icons.badge_rounded,
        referral => Icons.handshake_rounded,
        agencyRegistration => Icons.how_to_reg_rounded,
        interview => Icons.event_rounded,
        other => Icons.notes_rounded,
      };
}

enum ActivityType with _Persisted {
  applicationCreated('application_created', 'Application created'),
  applicationStageChanged('application_stage_changed', 'Stage changed'),
  applicationSubmitted('application_submitted', 'Application submitted'),
  taskCompleted('task_completed', 'Task completed'),
  contactAdded('contact_added', 'Contact added'),
  contactInteraction('contact_interaction', 'Contact interaction'),
  agencyContacted('agency_contacted', 'Agency contacted'),
  agencyStatusChanged('agency_status_changed', 'Agency status changed'),
  companyAdded('company_added', 'Company added'),
  companyStatusChanged('company_status_changed', 'Company status changed'),
  interviewScheduled('interview_scheduled', 'Interview scheduled'),
  interviewCompleted('interview_completed', 'Interview completed'),
  followUpCompleted('follow_up_completed', 'Follow-up completed'),
  opportunitySaved('opportunity_saved', 'Opportunity saved'),
  prepLogged('prep_logged', 'Preparation logged'),
  resumeUpdated('resume_updated', 'Resume updated'),
  offerReceived('offer_received', 'Offer received'),
  note('note', 'Note');

  const ActivityType(this.id, this.label);
  @override
  final String id;
  final String label;

  static ActivityType fromId(String? id) => _byId(ActivityType.values, id, note);

  /// Grouping used by the History filter chips.
  String get group => switch (this) {
        applicationCreated ||
        applicationStageChanged ||
        applicationSubmitted ||
        offerReceived =>
          'Applications',
        contactAdded || contactInteraction => 'Networking',
        agencyContacted || agencyStatusChanged => 'Agencies',
        companyAdded || companyStatusChanged => 'Companies',
        interviewScheduled || interviewCompleted => 'Interviews',
        taskCompleted || prepLogged => 'Tasks',
        followUpCompleted => 'Follow-ups',
        opportunitySaved => 'Opportunities',
        resumeUpdated => 'Resumes',
        note => 'Notes',
      };

  IconData get icon => switch (this) {
        applicationCreated => Icons.note_add_rounded,
        applicationSubmitted => Icons.send_rounded,
        applicationStageChanged => Icons.swap_horiz_rounded,
        taskCompleted => Icons.check_circle_rounded,
        contactAdded => Icons.person_add_rounded,
        contactInteraction => Icons.forum_rounded,
        agencyContacted => Icons.support_agent_rounded,
        agencyStatusChanged => Icons.business_center_rounded,
        companyAdded => Icons.domain_add_rounded,
        companyStatusChanged => Icons.domain_rounded,
        interviewScheduled => Icons.event_rounded,
        interviewCompleted => Icons.event_available_rounded,
        followUpCompleted => Icons.reply_rounded,
        opportunitySaved => Icons.bookmark_add_rounded,
        prepLogged => Icons.school_rounded,
        resumeUpdated => Icons.description_rounded,
        offerReceived => Icons.celebration_rounded,
        note => Icons.notes_rounded,
      };

  Color get color => switch (this) {
        offerReceived => AppColors.accent,
        applicationSubmitted || applicationCreated => AppColors.primary,
        interviewScheduled || interviewCompleted => AppColors.warning,
        taskCompleted || prepLogged => AppColors.success,
        contactAdded || contactInteraction => AppColors.purple,
        agencyContacted || agencyStatusChanged => AppColors.success,
        _ => AppColors.textSecondary,
      };
}

/// Health of an application derived from how long it has been silent.
enum ApplicationHealth {
  active('Active', AppColors.success),
  waiting('Waiting', AppColors.accent),
  followUpDue('Follow-up Due', AppColors.warning),
  stale('Stale', AppColors.danger),
  closed('Closed', AppColors.textTertiary);

  const ApplicationHealth(this.label, this.color);
  final String label;
  final Color color;
}
