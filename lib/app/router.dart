import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/agencies/agencies_screen.dart';
import '../features/analytics/analytics_screen.dart';
import '../features/applications/applications_screen.dart';
import '../features/companies/companies_screen.dart';
import '../features/countries/countries_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/followups/followups_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/history/history_screen.dart';
import '../features/interviews/interviews_screen.dart';
import '../features/networking/networking_screen.dart';
import '../features/opportunities/opportunities_screen.dart';
import '../features/portfolio/portfolio_screen.dart';
import '../features/prep/prep_screen.dart';
import '../features/resources/resources_screen.dart';
import '../features/resumes/resumes_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tasks/today_screen.dart';
import '../shared/navigation/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(
        location: state.uri.path,
        child: child,
      ),
      routes: [
        _page('/', const DashboardScreen()),
        _page('/today', const TodayScreen()),
        _page('/applications', const ApplicationsScreen()),
        _page('/opportunities', const OpportunitiesScreen()),
        GoRoute(
          path: '/companies',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: CompaniesScreen(
              initialQuery: state.uri.queryParameters['q'],
            ),
          ),
        ),
        GoRoute(
          path: '/agencies',
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: AgenciesScreen(
              initialQuery: state.uri.queryParameters['q'],
            ),
          ),
        ),
        _page('/network', const NetworkingScreen()),
        _page('/followups', const FollowUpsScreen()),
        _page('/interviews', const InterviewsScreen()),
        _page('/countries', const CountriesScreen()),
        _page('/resumes', const ResumesScreen()),
        _page('/prep', const PrepScreen()),
        _page('/portfolio', const PortfolioScreen()),
        _page('/analytics', const AnalyticsScreen()),
        _page('/goals', const GoalsScreen()),
        _page('/history', const HistoryScreen()),
        _page('/resources', const ResourcesScreen()),
        _page('/settings', const SettingsScreen()),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 32),
          const SizedBox(height: 12),
          Text('No screen at ${state.uri.path}'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to Mission Control'),
          ),
        ],
      ),
    ),
  ),
);

/// Shell children keep their scroll position and skip transitions, which
/// makes desktop navigation feel instant.
GoRoute _page(String path, Widget child) => GoRoute(
      path: path,
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: child),
    );
