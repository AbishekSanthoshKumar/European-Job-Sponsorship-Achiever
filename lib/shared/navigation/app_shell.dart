import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/search/command_palette.dart';
import '../widgets/quick_add_sheet.dart';
import 'destinations.dart';

/// Breakpoint above which the sidebar replaces bottom navigation.
const kDesktopBreakpoint = 1000.0;
const kTabletBreakpoint = 680.0;

bool isDesktop(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

bool isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kTabletBreakpoint;

/// Responsive frame: sidebar on desktop, rail on tablet, bottom bar on mobile.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= kDesktopBreakpoint) {
      return _DesktopShell(location: location, child: child);
    }
    if (width >= kTabletBreakpoint) {
      return _TabletShell(location: location, child: child);
    }
    return _MobileShell(location: location, child: child);
  }
}

// ---------------------------------------------------------------------------
// Desktop
// ---------------------------------------------------------------------------

class _DesktopShell extends ConsumerWidget {
  const _DesktopShell({required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            const _OpenPaletteIntent(),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            const _OpenPaletteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenPaletteIntent: CallbackAction<_OpenPaletteIntent>(
            onInvoke: (_) {
              showCommandPalette(context);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                _Sidebar(location: location),
                Container(width: 1, color: theme.colorScheme.outline),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenPaletteIntent extends Intent {
  const _OpenPaletteIntent();
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final buckets = ref.watch(followUpBucketsProvider);
    final settings = ref.watch(settingsProvider);

    return Container(
      width: 236,
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // brand
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Insets.lg, Insets.xl, Insets.lg, Insets.md),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDim],
                    ),
                    borderRadius: BorderRadius.circular(Corners.sm),
                  ),
                  child: const Icon(Icons.travel_explore_rounded,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EUROPEAN DREAM',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                      Text(
                        '${settings.daysRemaining} days left',
                        style: AppTheme.mono(
                          size: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // search trigger
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.md),
            child: InkWell(
              onTap: () => showCommandPalette(context),
              borderRadius: BorderRadius.circular(Corners.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Insets.md, vertical: Insets.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(Corners.md),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        size: 15, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: Insets.sm),
                    Expanded(
                      child: Text('Search',
                          style: theme.textTheme.bodySmall),
                    ),
                    Text('⌘K',
                        style: AppTheme.mono(
                          size: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Insets.md),

          // navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
              children: [
                for (final (title, routes) in sidebarGroups) ...[
                  if (title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          Insets.md, Insets.md, Insets.md, Insets.xs),
                      child: Text(
                        title.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  for (final route in routes)
                    _SidebarItem(
                      destination: destinationFor(route),
                      selected: _isSelected(route),
                      badge: route == '/followups'
                          ? buckets.actionableCount
                          : 0,
                    ),
                ],
              ],
            ),
          ),

          Container(height: 1, color: theme.colorScheme.outline),
          Padding(
            padding: const EdgeInsets.all(Insets.sm),
            child: _SidebarItem(
              destination: destinationFor('/settings'),
              selected: _isSelected('/settings'),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSelected(String route) {
    if (route == '/') return location == '/';
    return location == route || location.startsWith('$route/');
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.selected,
    this.badge = 0,
  });

  final AppDestination destination;
  final bool selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.xs, vertical: 1),
      child: Material(
        color: selected
            ? theme.colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Corners.md),
        child: InkWell(
          onTap: () => context.go(destination.route),
          borderRadius: BorderRadius.circular(Corners.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Insets.md, vertical: 9),
            child: Row(
              children: [
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 17,
                  color: color,
                ),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Text(
                    destination.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(Corners.pill),
                    ),
                    child: Text(
                      '$badge',
                      style: AppTheme.mono(
                        size: 10,
                        weight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tablet — navigation rail
// ---------------------------------------------------------------------------

class _TabletShell extends ConsumerWidget {
  const _TabletShell({required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final railItems = appDestinations
        .where((d) => d.route != '/settings')
        .take(10)
        .toList();
    var index = railItems.indexWhere((d) => d.route == location);
    if (index < 0) index = 0;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => context.go(railItems[i].route),
            labelType: NavigationRailLabelType.all,
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
            leading: Padding(
              padding: const EdgeInsets.only(top: Insets.lg, bottom: Insets.sm),
              child: IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => showCommandPalette(context),
                tooltip: 'Search',
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: Insets.lg),
                  child: IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.go('/settings'),
                    tooltip: 'Settings',
                  ),
                ),
              ),
            ),
            destinations: [
              for (final d in railItems)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.mobileLabel),
                ),
            ],
          ),
          Container(width: 1, color: theme.colorScheme.outline),
          Expanded(child: child),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQuickAddSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile — bottom bar + More sheet
// ---------------------------------------------------------------------------

class _MobileShell extends ConsumerWidget {
  const _MobileShell({required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = primaryDestinations;
    final buckets = ref.watch(followUpBucketsProvider);

    var index = primary.indexWhere((d) => d.route == location);
    final isMore = index < 0;
    if (index < 0) index = primary.length; // the "More" tab

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQuickAddSheet(context),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          if (i == primary.length) {
            _showMoreSheet(context, ref);
          } else {
            context.go(primary[i].route);
          }
        },
        destinations: [
          for (final d in primary)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.mobileLabel,
            ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: buckets.actionableCount > 0,
              label: Text('${buckets.actionableCount}'),
              child: const Icon(Icons.more_horiz_rounded),
            ),
            selectedIcon: const Icon(Icons.more_horiz_rounded),
            label: isMore ? 'More' : 'More',
          ),
        ],
      ),
    );
  }

  void _showMoreSheet(BuildContext context, WidgetRef ref) {
    final secondary =
        appDestinations.where((d) => !d.primary).toList();
    final buckets = ref.read(followUpBucketsProvider);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.75,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: Insets.lg),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Insets.xl, 0, Insets.xl, Insets.md),
                child: Text(
                  'All sections',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final d in secondary)
                ListTile(
                  leading: Icon(d.icon, size: 20),
                  title: Text(d.label),
                  trailing: d.route == '/followups' &&
                          buckets.actionableCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius:
                                BorderRadius.circular(Corners.pill),
                          ),
                          child: Text(
                            '${buckets.actionableCount}',
                            style: AppTheme.mono(
                              size: 10,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right_rounded, size: 18),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(d.route);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard page scaffold used inside the shell.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.padding,
    this.scrollable = true,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = isMobile(context);
    final pad = padding ??
        EdgeInsets.fromLTRB(
          mobile ? Insets.lg : Insets.xl,
          Insets.sm,
          mobile ? Insets.lg : Insets.xl,
          mobile ? 96 : Insets.xxl,
        );

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        titleSpacing: mobile ? Insets.lg : Insets.xl,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.headlineMedium),
            if (subtitle != null)
              Text(subtitle!, style: theme.textTheme.bodySmall),
          ],
        ),
        toolbarHeight: subtitle != null ? 68 : 56,
        actions: [
          ...actions,
          SizedBox(width: mobile ? Insets.sm : Insets.lg),
        ],
        bottom: bottom,
      ),
      body: scrollable
          ? SingleChildScrollView(padding: pad, child: child)
          : Padding(padding: pad, child: child),
    );
  }
}
