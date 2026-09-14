import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'core/config/app_config.dart';
import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_screen.dart' show themeModeProvider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load every collection up front so no screen needs a loading state.
  final bootstrap = await AppBootstrap.load(config: AppConfig.fromEnvironment);

  runApp(
    ProviderScope(
      overrides: bootstrap.overrides,
      child: const EuropeanDreamApp(),
    ),
  );
}

class EuropeanDreamApp extends ConsumerStatefulWidget {
  const EuropeanDreamApp({super.key});

  @override
  ConsumerState<EuropeanDreamApp> createState() => _EuropeanDreamAppState();
}

class _EuropeanDreamAppState extends ConsumerState<EuropeanDreamApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // restore the saved theme preference
      final saved = ref.read(settingsProvider).themeMode;
      ref.read(themeModeProvider.notifier).state = switch (saved) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      };
      // make sure today's plan exists on launch
      ref.read(tasksProvider.notifier).ensurePlanFor(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'European Dream',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: appRouter,
    );
  }
}
