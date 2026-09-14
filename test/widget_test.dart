import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:european_dream/core/providers/app_providers.dart';
import 'package:european_dream/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('app boots to Mission Control with the target lists seeded',
      (tester) async {
    // a phone-sized surface exercises the mobile shell
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final bootstrap = await AppBootstrap.load();

    await tester.pumpWidget(
      ProviderScope(
        overrides: bootstrap.overrides,
        child: const EuropeanDreamApp(),
      ),
    );
    await tester.pumpAndSettle();

    // the hero renders
    expect(find.text('EUROPEAN DREAM'), findsWidgets);
    expect(find.text('Mission Control'), findsWidgets);

    // seeding populated the target database on first launch
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    expect(container.read(companiesProvider).length, greaterThan(1000));
    expect(container.read(agenciesProvider).length, greaterThan(200));
    expect(container.read(resumesProvider).length, 4);

    // the daily plan generated itself
    expect(container.read(todayTasksProvider), isNotEmpty);
  });

  testWidgets('quick add opens the capture sheet', (tester) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final bootstrap = await AppBootstrap.load();
    await tester.pumpWidget(
      ProviderScope(
        overrides: bootstrap.overrides,
        child: const EuropeanDreamApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Quick add'), findsOneWidget);
    expect(find.text('Application'), findsWidgets);
    expect(find.text('Opportunity'), findsWidgets);
  });
}
