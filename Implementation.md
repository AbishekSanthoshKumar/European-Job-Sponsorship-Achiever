# PROJECT: EUROPEAN DREAM – Personal Job Search Operating System

You are an expert Flutter architect, product designer, UX designer, and full-stack engineer.

Build a production-quality personal application called:

EUROPEAN DREAM
Tagline: "Track every step towards your European career."

This is NOT a generic task manager.

This is a highly personalized Job Search Operating System designed for one software engineer from India whose mission is to secure a full-time visa-sponsored Software Engineer position in Europe.

The application should help me execute my job search strategy EVERY DAY, prevent missed activities, track every application and interaction, measure progress, analyze what works, and maintain historical records of my journey.

The app must work beautifully as:

1. Flutter Web Application
2. Flutter Android Application
3. Flutter iOS Application

Use a responsive architecture so the experience feels native on desktop and mobile.

---

# CORE PRODUCT PHILOSOPHY

The application should feel like a combination of:

- Notion
- Linear
- Todoist
- HubSpot CRM
- LinkedIn Job Tracker
- Duolingo streak system
- Personal analytics dashboard

But specifically designed around ONE GOAL:

"Secure a visa-sponsored Software Engineer job in Europe."

The app should make it extremely easy for me to answer:

- What should I do today?
- What did I complete today?
- Am I on track?
- How many applications have I sent?
- Which countries are producing responses?
- Which job roles are producing interviews?
- Which resume performs best?
- Which recruitment agencies are responding?
- Who should I follow up with today?
- Which applications are becoming stale?
- How consistent have I been?
- What actions are increasing my chances?
- How close am I to my monthly targets?

The system should encourage consistency without feeling childish.

---

# TECHNOLOGY STACK

Build using:

Frontend:
- Flutter
- Material 3
- Responsive design
- Clean architecture

State Management:
- Riverpod preferred

Backend:
Choose Supabase if possible because I want:
- Authentication
- PostgreSQL database
- Cloud sync
- Row-level security
- File storage
- Ability to access the same data on web and mobile

Alternative:
Firebase is acceptable if Supabase implementation becomes problematic.

Local storage:
- Offline-first support where practical
- Cached data so mobile app remains useful without internet

Architecture:
- Feature-first clean architecture
- Repository pattern
- Proper models
- Services separated from UI
- Scalable project structure

Do NOT create a static prototype.

Build a functioning application with persistent data.

---

# DESIGN DIRECTION

The design should feel:

- Premium
- Motivating
- Modern
- Minimal
- Professional
- Dark mode first
- Highly visual
- Data-driven

Avoid:
- Generic Flutter demo appearance
- Excessive rounded cards everywhere
- Too many gradients
- Cluttered dashboards
- Childish gamification

Visual inspiration:

- Linear
- Raycast
- Notion
- Stripe Dashboard
- Vercel Dashboard

Primary feeling:

"I am operating a serious mission."

The dashboard should make my European job search feel like a strategic campaign.

---

# APP STRUCTURE

Create the following primary sections:

1. Mission Control Dashboard
2. Today's Plan
3. Applications
4. Companies
5. Recruitment Agencies
6. Networking CRM
7. Job Opportunities
8. Follow-ups
9. Countries
10. Resume Manager
11. Interview Tracker
12. Portfolio / Projects
13. Analytics
14. History / Activity Timeline
15. Goals & Targets
16. Knowledge / Resources
17. Settings

Desktop:
Use sidebar navigation.

Mobile:
Use bottom navigation for primary screens and expandable menu for secondary screens.

---

# 1. MISSION CONTROL DASHBOARD

This is the most important screen.

When I open the app, I should immediately understand:

"What should I do now?"

The dashboard should contain:

## Hero Section

Display:

EUROPEAN DREAM
Primary Goal:
"Secure a visa-sponsored Software Engineer position in Europe"

Target deadline:
February 2027

Show countdown:

XX days remaining

Also show:

Current Mission Status

Examples:

ON TRACK
SLIGHTLY BEHIND
AT RISK
EXCEEDING TARGET

Calculate this based on completed activities versus targets.

---

## TODAY'S PROGRESS

Large visual progress indicator:

Today's Mission
7 / 10 Tasks Complete

Progress ring or elegant progress visualization.

Show:

Applications:
4 / 6

Recruiter Outreach:
3 / 4

Networking:
2 / 5

Interview Prep:
45 / 60 minutes

Follow-ups:
2 / 3

---

## DAILY STREAK

Display:

🔥 7 Day Consistency Streak

Also show:

Best Streak:
14 Days

Monthly Consistency:
82%

A day should count toward a streak only if a configurable minimum percentage of important tasks is completed.

---

## QUICK ACTIONS

Prominent buttons:

+ Add Application
+ Add Opportunity
+ Contact Recruiter
+ Add Follow-up
+ Complete Task
+ Log Interview
+ Add Company

---

## URGENT ITEMS

Automatically generated section:

🔴 Follow-up overdue
🟠 Application waiting for response
🟡 Interview preparation needed
🔵 New opportunity saved

Examples:

"Follow up with recruiter at Darwin Recruitment – 2 days overdue"

"Backend Engineer at Company X – Applied 14 days ago"

"Technical interview in 3 days"

---

## DAILY MOTIVATION

Do not use generic motivational quotes.

Instead show contextual messages like:

"You are 3 applications behind your weekly target."

"Great consistency. You have completed your daily target for 5 consecutive days."

"Germany is producing your highest response rate."

"You haven't applied to Poland in 8 days. Your strategy recommends 13% allocation."

This should be data-driven.

---

# 2. TODAY'S PLAN

Create a powerful daily task management system specifically for job searching.

Every day should automatically generate recommended tasks based on my strategy.

Example daily tasks:

APPLICATIONS

[ ] Apply to 3 direct company roles
[ ] Apply to 2 LinkedIn opportunities
[ ] Apply to 1 recruitment agency opportunity

NETWORKING

[ ] Message 4 recruiters
[ ] Send 2 hiring manager messages
[ ] Send 5 LinkedIn connection requests

FOLLOW-UPS

[ ] Follow up with 3 previous applications

PREPARATION

[ ] 30 minutes DSA
[ ] 30 minutes System Design

STRATEGY

[ ] Research 5 new companies
[ ] Save interesting opportunities

---

## TASK FEATURES

Every task should support:

- Title
- Category
- Priority
- Estimated duration
- Actual duration
- Due date
- Recurrence
- Notes
- Related company
- Related application
- Related person
- Related country
- Related job

Task status:

- Not Started
- In Progress
- Completed
- Skipped
- Rescheduled

When completing a task:

Allow me to optionally add:

"What did you do?"

Example:

Task:
"Contact 4 recruiters"

Completion log:

- Contacted John at Hays
- Contacted Sarah at Iduet
- Contacted recruiter at Randstad Digital
- Contacted recruiter at Computer Futures

This should automatically create historical activity records where applicable.

---

## DAILY AUTO-GENERATION

Implement a Daily Plan Generator.

It should generate tasks based on configurable weekly targets.

Example configuration:

Applications per week: 40
Recruiter messages per week: 20
LinkedIn connections per week: 25
Follow-ups per week: 12
Interview preparation: 5 hours/week
Company research: 10 companies/week

The system should intelligently distribute these across remaining days.

Example:

If Monday was missed:

Do NOT simply duplicate Monday tasks.

Redistribute intelligently across Tuesday-Sunday.

Allow the user to choose:

- Strict mode
- Flexible mode
- Catch-up mode

---

# 3. APPLICATION TRACKER

This should be one of the strongest features.

Create a full Kanban + Table + Timeline application tracking system.

Application stages:

SAVED
↓
READY TO APPLY
↓
APPLIED
↓
RECRUITER SCREEN
↓
HR INTERVIEW
↓
TECHNICAL INTERVIEW
↓
CODING ASSESSMENT
↓
SYSTEM DESIGN
↓
FINAL INTERVIEW
↓
OFFER
↓
ACCEPTED

Alternative outcomes:

REJECTED
WITHDRAWN
GHOSTED
POSITION CLOSED

---

## APPLICATION DATA MODEL

Each application should contain:

Basic Information:

- Job title
- Company
- Location
- Country
- City
- Job URL
- Source

Source options:

- LinkedIn
- Company Website
- Recruitment Agency
- Referral
- Job Board
- Recruiter Outreach
- Cold Application
- Other

---

Role Information:

- Role category
- Seniority
- Employment type
- Remote / Hybrid / Onsite
- Salary range
- Currency

---

Immigration:

VERY IMPORTANT

Fields:

Visa sponsorship explicitly mentioned?
Yes / No / Unknown

Relocation assistance?
Yes / No / Unknown

Company known to sponsor?
Yes / No / Unknown

Work authorization requirement:

- EU only
- Existing work permit required
- Sponsorship possible
- Unknown
- Explicit sponsorship

Visa notes

---

Resume:

Track which resume was used:

- Backend Resume
- Applied AI Resume
- Mobile Resume
- Data / Automation Resume
- Custom Resume

Cover letter used?
Yes / No

---

Dates:

- Date discovered
- Date saved
- Date applied
- Last activity
- Next follow-up date
- Response date
- Interview date
- Final outcome date

---

Quality Rating:

Before applying allow me to score:

Skill Match: /10
Experience Match: /10
Visa Probability: /10
Company Priority: /10
Overall Opportunity Score

Automatically calculate weighted score.

---

Notes:

Freeform notes.

---

# APPLICATION VIEWS

Create:

## Kanban View

Drag and drop applications between stages.

## Table View

Powerful filtering and sorting.

Filters:

- Country
- Role
- Status
- Resume version
- Visa sponsorship
- Source
- Date range
- Company type

## Timeline View

Visual timeline of applications and interviews.

## Calendar View

Application and interview events.

---

# 4. APPLICATION INTELLIGENCE

Automatically calculate:

- Total applications
- Applications this week
- Applications this month
- Applications by country
- Applications by role
- Applications by source
- Applications by resume
- Applications with sponsorship
- Response rate
- Interview rate
- Offer rate

Important formulas:

Response Rate:

Applications that received a response / Total applications

Interview Rate:

Applications reaching interview / Total applications

Offer Rate:

Offers / Total applications

---

# 5. APPLICATION AGING SYSTEM

Automatically detect stale applications.

Examples:

After 7 days:
"Application pending"

After 14 days:
"Consider following up"

After 21 days:
"Likely inactive – mark as ghosted or continue waiting"

Make these configurable.

Show application health:

🟢 Active
🟡 Waiting
🟠 Follow-up Due
🔴 Stale

---

# 6. COMPANY DATABASE

Create a personal target company CRM.

Each company should contain:

- Company name
- Website
- LinkedIn
- Country
- City
- Industry
- Company size
- Type

Types:

- Startup
- Scaleup
- Enterprise
- Consultancy
- Fintech
- AI Company
- Product Company
- Outsourcing
- Other

---

Visa Information:

- Known sponsor?
- Visa sponsorship likelihood
- Relocation assistance
- International hiring history

Priority:

⭐ Dream Company
🟢 High Priority
🟡 Medium Priority
🔴 Low Priority

---

Relationship status:

- Not Researched
- Researched
- Jobs Found
- Applied
- Recruiter Contacted
- Employee Contacted
- Referral Requested
- Interviewing
- Rejected
- Future Target

---

Company notes:

Why this company?

Technology stack

Potential roles

Known contacts

---

## COMPANY PIPELINE

Create:

TARGET
↓
RESEARCHING
↓
JOB FOUND
↓
APPLIED
↓
NETWORKING
↓
INTERVIEWING
↓
OFFER

---

# 7. RECRUITMENT AGENCY CRM

This is extremely important.

I want to track every recruitment agency.

Agency data:

- Agency name
- Website
- LinkedIn
- Country
- Countries served
- Specialization

Specializations:

- Software Engineering
- AI
- Data
- Backend
- Mobile
- Cloud
- General Technology

Priority:

Highest Priority
High Priority
Medium Priority
Low Priority
Ignore

Overall Match Score /10

---

Relationship tracking:

Status:

NOT CONTACTED
REGISTERED
CONTACTED
RESPONDED
CALL SCHEDULED
ACTIVE RELATIONSHIP
JOB SUBMITTED
INACTIVE

---

Contacts:

Each agency can have multiple recruiters.

For each recruiter:

- Name
- LinkedIn
- Email
- Role
- Country
- Specialization
- Date contacted
- Last response
- Relationship strength

---

Automatically show:

"Agencies not contacted yet"

"Agencies needing follow-up"

"Agencies with active conversations"

"Best-performing agencies"

Metrics:

- Applications submitted through agency
- Interviews generated
- Response rate
- Offers generated

---

# 8. NETWORKING CRM

Build a mini HubSpot specifically for job networking.

Track:

People:

- Recruiters
- Hiring Managers
- Engineers
- Employees
- Founders
- Referrers

Fields:

- Name
- Company
- Role
- LinkedIn URL
- Email
- Country
- Relationship type

Status:

Not Contacted
Connection Requested
Connected
Messaged
Responded
Conversation Active
Referral Requested
Referral Received
Inactive

---

For every person create:

Interaction Timeline:

Example:

Aug 30
Sent connection request

Sep 1
Connection accepted

Sep 2
Sent introduction message

Sep 5
Recruiter replied

Sep 8
Follow-up scheduled

---

Automatically remind me:

"You contacted Sarah 5 days ago and haven't followed up."

---

# 9. JOB OPPORTUNITY INBOX

Create a place where I can quickly save jobs without immediately applying.

Fields:

- Job title
- Company
- URL
- Country
- Source
- Date discovered
- Priority
- Quick notes

Status:

INBOX
RESEARCHING
GOOD MATCH
READY TO APPLY
APPLIED
DISCARDED

This is important because I often find jobs when browsing LinkedIn but don't have time to immediately customize and apply.

I should be able to save them quickly.

---

# 10. FOLLOW-UP CENTER

Create a dedicated Follow-up screen.

Automatically aggregate:

Applications requiring follow-up

Recruiters requiring follow-up

Hiring managers requiring follow-up

Referral requests requiring follow-up

Agency registrations requiring follow-up

---

Display:

OVERDUE
TODAY
THIS WEEK
UPCOMING

Each follow-up should have:

- Person/company
- Context
- Last interaction
- Recommended action
- Suggested message
- Follow-up date

Allow completion.

When completed:

Automatically add to history.

---

# 11. COUNTRY STRATEGY

Create a dedicated Country Intelligence screen.

Initial target countries:

Tier 1:

Germany
Netherlands
Poland
Estonia
Switzerland

Tier 2:

Spain
Portugal
Sweden

Tier 3:

Austria
Belgium
Denmark
Czech Republic
Lithuania
Latvia
Romania
Bulgaria
Slovakia
Hungary
Italy
Cyprus
Malta

---

Allow configurable target allocation.

Initial strategy:

Germany: 22%
Netherlands: 17%
Poland: 13%
Sweden: 8%
Denmark: 5%
Estonia: 5%
Portugal: 5%
Spain: 5%
Switzerland: 3%
Austria: 3%
Belgium: 2%
Czech Republic: 2%
Lithuania: 2%
Others: Remaining %

---

For each country track:

- Target application %
- Actual application %
- Applications
- Responses
- Interviews
- Offers
- Rejections
- Success rate

Show:

TARGET vs ACTUAL

Example:

Germany

Target:
22%

Actual:
18%

Status:
⬇ Under Target

Recommendation:

"You are under-investing in Germany. Apply to approximately 3 more German opportunities this week to align with your strategy."

---

# 12. ROLE STRATEGY

Initial role allocation:

Backend Engineer: 24%
Full Stack Engineer: 18%
Applied AI Engineer: 15%
Data Engineer: 10%
General Software Engineer: 10%
Automation Engineer: 8%
Mobile Engineer: 8%
Computer Vision / OCR: 4%
ML Engineer: 3%

Track:

- Applications
- Responses
- Interviews
- Conversion rate

Automatically identify:

"Backend roles are generating 2.3x more interviews than AI roles."

Recommend adjustments based on actual data.

---

# 13. RESUME MANAGER

Track resume versions.

Initial versions:

1. Backend / Software Engineer
2. Applied AI Engineer
3. Mobile Engineer
4. Data / Automation Engineer

For each resume:

- Name
- Version number
- Last updated
- File attachment
- Target roles
- Skills emphasized
- Notes

Track performance:

Applications:
42

Responses:
8

Interviews:
4

Response rate:
19%

Allow me to compare resumes.

Example:

Backend Resume
Response Rate: 14%

Applied AI Resume
Response Rate: 22%

This is important for experimentation.

---

# 14. INTERVIEW TRACKER

Track all interviews.

Stages:

Recruiter Screen
HR
Technical
Coding Assessment
System Design
Hiring Manager
Final Round

For every interview:

- Company
- Role
- Interviewer
- Date
- Duration
- Format
- Stage
- Status

Status:

Upcoming
Completed
Cancelled

---

## INTERVIEW PREPARATION

Allow preparation checklist.

Examples:

[ ] Research company
[ ] Understand product
[ ] Review job description
[ ] Prepare project explanations
[ ] Prepare STAR stories
[ ] Review DSA
[ ] Review system design
[ ] Prepare questions

---

## POST INTERVIEW REVIEW

After interview ask:

How did it go?

1–10

Questions asked:

What went well?

What could improve?

Topics I struggled with:

Create a historical interview learning database.

This will help identify patterns.

---

# 15. INTERVIEW PREPARATION SYSTEM

Create an Interview Prep module.

Categories:

DSA

Topics:

- Arrays
- Strings
- Hash Maps
- Trees
- Graphs
- Dynamic Programming
- Recursion
- Sorting

System Design:

- APIs
- Databases
- Caching
- Queues
- Scalability
- Microservices
- Authentication
- Distributed Systems

Backend:

- Node.js
- Python
- REST APIs
- PostgreSQL
- AWS

AI:

- RAG
- LLM architecture
- Embeddings
- Vector databases
- OCR
- Computer Vision

Behavioral:

- STAR stories
- Leadership
- Conflict
- Failures
- Achievements

Track time spent.

Show:

Weekly preparation:

DSA: 2h 30m
System Design: 1h 45m
Backend: 2h
AI: 1h

---

# 16. PORTFOLIO / PROJECT TRACKER

Track portfolio projects.

Current flagship project should be configurable.

For every project:

- Name
- Description
- Technologies
- GitHub URL
- Demo URL
- Status
- Progress percentage

Tasks:

[ ] Architecture
[ ] Backend
[ ] Frontend
[ ] Authentication
[ ] AI Integration
[ ] Deployment
[ ] Documentation
[ ] Demo Video

Show portfolio readiness.

---

# 17. GOALS SYSTEM

Create goals at multiple levels.

## PRIMARY GOAL

Secure a European visa-sponsored Software Engineer offer.

Deadline:
Configurable

---

## MONTHLY GOALS

Example:

September:

150 Applications
50 Recruiter Contacts
15 Hiring Manager Contacts
10 Referral Attempts
20 Agency Registrations
20 Hours Interview Prep

---

## WEEKLY GOALS

Example:

40 Applications
20 Recruiter Messages
25 Connections
12 Follow-ups
5 Hours Interview Prep

---

## DAILY GOALS

Automatically derived from weekly targets.

---

Show progress:

Applications

████████░░ 32 / 40

Recruiter Outreach

██████░░░░ 12 / 20

---

# 18. ANALYTICS DASHBOARD

This should be powerful.

Create visual analytics.

Do NOT overload with unnecessary charts.

Use charts only when useful.

---

## APPLICATION FUNNEL

Show:

Saved
↓
Applied
↓
Response
↓
Recruiter Screen
↓
Technical
↓
Final
↓
Offer

Calculate conversion rates.

---

## COUNTRY PERFORMANCE

Chart:

Applications by country

Responses by country

Interview rate by country

---

## ROLE PERFORMANCE

Compare:

Backend
AI
Full Stack
Mobile
Data

---

## SOURCE PERFORMANCE

Compare:

LinkedIn
Company Website
Recruitment Agency
Referral
Job Board
Cold Outreach

Identify best source.

---

## RESUME PERFORMANCE

Compare all resume versions.

---

## TIME ANALYTICS

Track:

Applications per week

Consistency

Streak

Hours spent

Most productive day

Most successful month

---

# 19. HISTORY / ACTIVITY TIMELINE

Create a complete chronological history.

Every meaningful action should create an activity.

Examples:

Aug 30

✓ Applied to Backend Engineer
Company: ASML

✓ Contacted Recruiter
Agency: Darwin Recruitment

✓ Completed 1 hour System Design

✓ Added new target company

Sep 1

✓ Interview scheduled
Company: Booking.com

---

Allow filtering:

- Applications
- Networking
- Interviews
- Tasks
- Agencies
- Companies
- Resume updates

This should become a complete historical record of my journey.

---

# 20. CONSISTENCY CALENDAR

Create a GitHub-style activity heatmap.

Every day should show activity intensity.

Green / neutral intensity based on:

- Tasks completed
- Applications submitted
- Networking activities
- Interview preparation

Clicking a day should show:

"What did I accomplish?"

Example:

September 12

✓ 6 applications
✓ 4 recruiter messages
✓ 1 follow-up
✓ 60 minutes DSA

Daily score:
92%

---

# 21. DAILY SCORE

Create a configurable productivity score.

Example:

Applications:
40%

Networking:
20%

Follow-ups:
15%

Interview Preparation:
15%

Research:
10%

Calculate:

Daily Mission Score:
0–100

Example:

92 / 100

Do not punish unavoidable missed days excessively.

Allow:

Rest Day

Sick Day

Emergency Day

These should not break streaks if explicitly marked.

---

# 22. WEEKLY REVIEW

Every Sunday show a Weekly Review screen.

Questions:

How did this week go?

Applications:
37 / 40

Recruiter Messages:
18 / 20

Interview Prep:
4.5 / 5 hours

---

Automatically generate insights:

"Strong week overall."

"You exceeded Netherlands application targets."

"Germany applications are below target."

"Your Applied AI resume generated the highest response rate."

"You missed follow-ups on 3 applications."

---

Allow notes:

What went well?

What should improve?

What will I focus on next week?

Store weekly reviews historically.

---

# 23. MONTHLY REVIEW

Generate a monthly report.

Include:

- Total applications
- Response rate
- Interview rate
- Networking activity
- Top countries
- Top roles
- Best source
- Best resume
- Time invested
- Consistency score
- Biggest achievement
- Biggest bottleneck

Allow export to PDF eventually.

---

# 24. SMART INSIGHTS ENGINE

Create a rule-based intelligence engine.

Do NOT claim to use AI unless actual AI APIs are integrated.

Initially use deterministic rules.

Examples:

"If applications to Germany < target percentage"

Show:

"Germany is below your planned allocation."

---

"If no applications completed for 3 days"

Show:

"Your consistency is declining. Consider reducing daily workload rather than abandoning the plan."

---

"If a resume has >20 applications"

Compare response rates.

---

"If follow-ups overdue"

Prioritize them on dashboard.

---

"If a country produces significantly better interviews"

Show:

"Poland currently has your highest interview conversion rate."

---

# 25. NOTIFICATIONS

Implement notification architecture.

Mobile notifications should eventually support:

Morning:

"Your European Dream mission is ready."

Evening:

"You have 3 tasks remaining."

Follow-up reminders:

"Follow up with recruiter tomorrow."

Interview:

"Technical interview in 2 days."

Missed activity:

"You haven't logged an application today."

Allow full notification customization.

---

# 26. QUICK CAPTURE

This is very important for mobile.

Create a floating Quick Add button.

Options:

+ Application
+ Opportunity
+ Recruiter
+ Company
+ Task
+ Interview
+ Note

Adding something should take less than 30 seconds.

Example:

I find a job on LinkedIn.

I should be able to:

Open app → Quick Add → Paste URL → Save

Later I can process details.

---

# 27. SEARCH

Global search across:

- Companies
- Applications
- People
- Agencies
- Jobs
- Tasks
- Notes

Keyboard shortcut on web:

Cmd/Ctrl + K

Create a command palette experience.

Examples:

"Add application"

"Search ASML"

"Today's tasks"

"Overdue follow-ups"

---

# 28. DATA IMPORT / EXPORT

Support:

CSV export for:

Applications
Companies
Contacts
Agencies
Tasks

Design architecture so CSV import can be added.

---

# 29. DEMO DATA

Seed the application with realistic demo data.

Countries:

Germany
Netherlands
Poland
Sweden
Denmark
Estonia
Portugal
Spain
Switzerland

Example companies:

ASML
Booking.com
Adyen
NXP
SAP
Zalando
Celonis
Spotify
Klarna
Wise
Bolt
Allegro
Docplanner

Example agencies:

Iduet
Darwin Recruitment
Lawrence Harvey
Computer Futures
Trust in SODA
Hays Technology
Randstad Digital

Create realistic sample applications.

This is important so I can immediately understand the product.

---

# 30. USER EXPERIENCE REQUIREMENTS

The app should prioritize:

1. Speed
2. Low friction
3. Clear information hierarchy
4. Motivation
5. Historical tracking

Important principle:

Every action should be possible within as few clicks as possible.

Avoid unnecessary modal dialogs.

Avoid forcing the user to fill 20 fields.

Use progressive disclosure.

Example:

When adding application:

Required:

Job Title
Company
Country

Optional fields collapsed.

---

# 31. RESPONSIVE DESIGN

## Desktop

Sidebar:

Mission Control
Today
Applications
Opportunities
Companies
Agencies
Networking
Follow-ups
Interviews
Analytics

Bottom:

Settings

---

## Mobile

Bottom Navigation:

Home
Today
Applications
Network
More

Quick Add floating button.

Mobile should NOT simply be a squeezed desktop UI.

Optimize screens individually.

---

# 32. FUTURE AI FEATURES

Do not implement expensive AI features unless architecture supports them.

Prepare placeholders for future:

AI Job Analyzer:

Paste job description.

Analyze:

- Skill match
- Missing skills
- Resume recommendation
- Application priority
- Suggested resume

AI Weekly Coach:

Analyze my weekly performance.

AI Application Assistant:

Help tailor resume.

AI Recruiter Message Generator.

AI Interview Coach.

These should be modular so they can be added later using OpenAI API.

---

# 33. DATABASE DESIGN

Design proper relational database schema.

Suggested entities:

users

daily_plans
tasks
task_completions

applications
application_events

companies
company_contacts

recruitment_agencies
agency_contacts

network_contacts
network_interactions

job_opportunities

follow_ups

interviews
interview_preparation

resumes
resume_versions

countries
country_targets

role_categories
role_targets

portfolio_projects
project_tasks

weekly_reviews
monthly_reviews

activity_history

notifications

goals

Ensure relationships are properly designed.

---

# 34. ACTIVITY EVENT SYSTEM

Implement a centralized activity logging system.

Whenever something happens:

Application created
Application status changed
Recruiter contacted
Task completed
Interview scheduled
Follow-up completed

Create activity event automatically.

This event system powers:

- History
- Analytics
- Weekly review
- Consistency tracking

---

# 35. FIRST-RUN ONBOARDING

Create onboarding.

Ask:

1. What is your primary goal?

Default:
Secure a European Software Engineering position.

2. Target deadline

3. Target countries

4. Weekly application goal

Default:
40

5. Weekly networking goal

Default:
20 recruiter messages

6. Weekly interview preparation goal

Default:
5 hours

7. Preferred roles

Allow selecting:

Backend
Software Engineer
Full Stack
AI
Data
Mobile
Automation

Then generate initial strategy.

---

# 36. PRIORITY ALGORITHM

Create an Opportunity Score.

Formula should be configurable.

Initial weights:

Skill Match:
30%

Visa Probability:
25%

Country Priority:
15%

Company Priority:
15%

Role Priority:
10%

Salary / Other:
5%

Output:

0–100 Opportunity Score.

Display:

90–100:
Exceptional Opportunity

75–89:
High Priority

60–74:
Good Opportunity

40–59:
Medium Priority

Below 40:
Low Priority

---

# 37. APPLICATION WORKFLOW

Ideal workflow:

1. Discover job
2. Quick Save
3. Analyze opportunity
4. Score opportunity
5. Select resume
6. Customize resume if needed
7. Apply
8. Log application
9. Automatically schedule follow-up
10. Track response
11. Add interview if received
12. Track interview preparation
13. Record outcome
14. Analyze conversion

Build UI around this workflow.

---

# 38. PERFORMANCE REQUIREMENTS

The app should:

- Load quickly
- Handle thousands of applications
- Work smoothly on mobile
- Support offline caching
- Avoid unnecessary rebuilds
- Have proper error handling
- Have loading states
- Have empty states
- Have optimistic updates where appropriate

---

# 39. CODE QUALITY

IMPORTANT:

Do not build everything in one giant main.dart.

Use a professional structure.

Example:

lib/

core/
  constants/
  theme/
  utils/
  services/

features/

  dashboard/
  tasks/
  applications/
  companies/
  agencies/
  networking/
  opportunities/
  followups/
  interviews/
  analytics/
  goals/
  history/

shared/

Use:

- Reusable components
- Proper domain models
- Repository abstraction
- Dependency injection through Riverpod
- Feature-based organization

---

# 40. IMPLEMENTATION APPROACH

Build this project incrementally.

PHASE 1:

Foundation:

- Flutter project setup
- Theme
- Navigation
- Responsive layout
- Supabase setup
- Authentication
- Database schema

PHASE 2:

Core MVP:

- Dashboard
- Today's tasks
- Applications
- Companies
- Basic analytics
- History

PHASE 3:

Career CRM:

- Recruitment agencies
- Networking contacts
- Follow-ups
- Job opportunity inbox

PHASE 4:

Advanced:

- Interview tracker
- Resume analytics
- Country analytics
- Weekly review
- Monthly review

PHASE 5:

Polish:

- Notifications
- Offline support
- Command palette
- Animations
- Performance optimization

---

# IMPORTANT DEVELOPMENT INSTRUCTIONS

Do NOT:

- Create only static UI mockups
- Use fake buttons
- Leave important screens non-functional
- Create a generic todo application
- Overcomplicate the first version
- Build massive forms for every action

DO:

- Build functional flows
- Use realistic seeded data
- Prioritize the core user journey
- Ensure every completed action is historically tracked
- Make the app genuinely useful daily
- Build reusable architecture
- Optimize for web AND mobile

---

# MOST IMPORTANT USER EXPERIENCE

Every morning I should open this app and immediately know:

"What do I need to do today?"

During the day:

I should be able to quickly log everything.

At night:

I should see:

"What did I accomplish?"

At the end of the week:

I should understand:

"Am I getting closer to my European job?"

After several months:

I should have a complete historical record of my journey and enough analytics to understand exactly what job-search strategies are working.

The product should feel like a personal command center for conquering my European career goal.

---

START BY:

1. Analyzing this specification
2. Proposing the database schema
3. Proposing the Flutter folder structure
4. Creating the design system
5. Building Phase 1 and Phase 2 first

Before implementing advanced features, ensure the MVP core workflow is genuinely excellent.

Do not ask unnecessary questions.

Make reasonable product decisions.

When decisions are required, optimize for:
LOW FRICTION + DAILY CONSISTENCY + LONG-TERM DATA TRACKING.