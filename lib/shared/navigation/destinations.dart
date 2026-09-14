import 'package:flutter/material.dart';

/// One navigable section of the app.
class AppDestination {
  const AppDestination({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.shortLabel,
    this.primary = false,
  });

  final String route;
  final String label;

  /// Shorter label for the mobile bottom bar.
  final String? shortLabel;
  final IconData icon;
  final IconData selectedIcon;

  /// Shown in the mobile bottom navigation bar.
  final bool primary;

  String get mobileLabel => shortLabel ?? label;
}

/// Sidebar order on desktop. The first five `primary` entries also form the
/// mobile bottom bar (with "More" replacing the fifth).
const appDestinations = <AppDestination>[
  AppDestination(
    route: '/',
    label: 'Mission Control',
    shortLabel: 'Home',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    primary: true,
  ),
  AppDestination(
    route: '/today',
    label: 'Today',
    icon: Icons.today_outlined,
    selectedIcon: Icons.today_rounded,
    primary: true,
  ),
  AppDestination(
    route: '/applications',
    label: 'Applications',
    shortLabel: 'Apps',
    icon: Icons.send_outlined,
    selectedIcon: Icons.send_rounded,
    primary: true,
  ),
  AppDestination(
    route: '/opportunities',
    label: 'Opportunities',
    icon: Icons.bookmark_border_rounded,
    selectedIcon: Icons.bookmark_rounded,
  ),
  AppDestination(
    route: '/companies',
    label: 'Companies',
    icon: Icons.domain_outlined,
    selectedIcon: Icons.domain_rounded,
  ),
  AppDestination(
    route: '/agencies',
    label: 'Agencies',
    icon: Icons.business_center_outlined,
    selectedIcon: Icons.business_center_rounded,
  ),
  AppDestination(
    route: '/network',
    label: 'Networking',
    shortLabel: 'Network',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
    primary: true,
  ),
  AppDestination(
    route: '/followups',
    label: 'Follow-ups',
    icon: Icons.reply_outlined,
    selectedIcon: Icons.reply_rounded,
  ),
  AppDestination(
    route: '/interviews',
    label: 'Interviews',
    icon: Icons.event_outlined,
    selectedIcon: Icons.event_rounded,
  ),
  AppDestination(
    route: '/countries',
    label: 'Countries',
    icon: Icons.public_outlined,
    selectedIcon: Icons.public_rounded,
  ),
  AppDestination(
    route: '/resumes',
    label: 'Resumes',
    icon: Icons.description_outlined,
    selectedIcon: Icons.description_rounded,
  ),
  AppDestination(
    route: '/prep',
    label: 'Interview Prep',
    shortLabel: 'Prep',
    icon: Icons.school_outlined,
    selectedIcon: Icons.school_rounded,
  ),
  AppDestination(
    route: '/portfolio',
    label: 'Portfolio',
    icon: Icons.code_outlined,
    selectedIcon: Icons.code_rounded,
  ),
  AppDestination(
    route: '/analytics',
    label: 'Analytics',
    icon: Icons.insights_outlined,
    selectedIcon: Icons.insights_rounded,
  ),
  AppDestination(
    route: '/goals',
    label: 'Goals & Targets',
    shortLabel: 'Goals',
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag_rounded,
  ),
  AppDestination(
    route: '/history',
    label: 'History',
    icon: Icons.history_rounded,
    selectedIcon: Icons.history_rounded,
  ),
  AppDestination(
    route: '/resources',
    label: 'Resources',
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
  ),
  AppDestination(
    route: '/settings',
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
  ),
];

/// Grouping used to break up the desktop sidebar.
const sidebarGroups = <(String, List<String>)>[
  ('', ['/', '/today']),
  ('Pipeline', ['/applications', '/opportunities', '/followups', '/interviews']),
  ('Targets', ['/companies', '/agencies', '/network', '/countries']),
  ('Assets', ['/resumes', '/prep', '/portfolio']),
  ('Review', ['/analytics', '/goals', '/history', '/resources']),
];

AppDestination destinationFor(String route) => appDestinations.firstWhere(
      (d) => d.route == route,
      orElse: () => appDestinations.first,
    );

List<AppDestination> get primaryDestinations =>
    appDestinations.where((d) => d.primary).toList();
