import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:european_dream/core/data/seed_loader.dart';
import 'package:european_dream/core/domain/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed asset loads and covers every source', () async {
    final raw = await rootBundle.loadString(SeedLoader.assetPath);
    final data = jsonDecode(raw) as Map<String, Object?>;
    final records = (data['records'] as List).cast<Map<String, Object?>>();

    expect(records.length, greaterThan(1200));

    // every record must have a usable name
    for (final r in records) {
      expect((r['name'] as String).trim(), isNotEmpty);
    }

    // the primary markets must dominate
    final byCountry =
        (data['companiesByCountry'] as Map).cast<String, dynamic>();
    final counts = (data['counts'] as Map).cast<String, dynamic>();
    expect(counts['total'], records.length);
    expect(byCountry['Germany'], greaterThan(700));
    expect(byCountry['Netherlands'], greaterThan(100));

    // named companies from each distinct source must all be present
    final names = records
        .map((r) => (r['name'] as String).toLowerCase())
        .toSet();
    for (final expected in [
      'asml',                    // netherlands xlsx + txt
      'booking.com',             // netherlands
      'adyen',                   // netherlands
      'nxp semiconductors',      // netherlands
      'zooplus se',              // german master sheet (last row)
      '3m deutschland gmbh',     // german master sheet (first row)
      'darwin recruitment',      // recruiter column
      'huxley',                  // NL recruiter
      'bolt',                    // visa-sponsor sheet w/ offer note
      'make it in germany',      // government portal infographic
      'stepstone',               // local job board infographic
      'apollo',                  // recruiter database infographic
      'manpowergroup',           // screenshot staffing groups
      'randstad luxembourg',     // luxembourg.txt
      'undutchables',            // country wise companies.txt
      'blue lynx recruitment',   // country wise companies.txt
    ]) {
      expect(names, contains(expected), reason: 'missing "$expected"');
    }
  });

  test('enum ids round-trip', () {
    for (final s in ApplicationStage.values) {
      expect(ApplicationStage.fromId(s.id), s);
    }
    for (final s in AgencyStatus.values) {
      expect(AgencyStatus.fromId(s.id), s);
    }
    for (final s in ContactStatus.values) {
      expect(ContactStatus.fromId(s.id), s);
    }
    // unknown ids fall back rather than throwing
    expect(ApplicationStage.fromId('nope'), ApplicationStage.saved);
    expect(ApplicationStage.fromId(null), ApplicationStage.saved);
  });
}
