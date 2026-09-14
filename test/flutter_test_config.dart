import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Runs before every test in this directory.
///
/// google_fonts otherwise tries to fetch font files over HTTP, which stalls
/// widget tests; the bundled fallback is fine for layout assertions.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
