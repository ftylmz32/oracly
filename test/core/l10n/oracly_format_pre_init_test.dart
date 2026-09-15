/// Regression: OraclyFormat.time() must not crash before ensureInitialized.
///
/// main.dart calls runApp() before awaiting OraclyFormat.ensureInitialized()
/// (see the "deferred startup" comment there) — the first frame can render
/// before ICU locale data is loaded. date()/dayMonth()/dateCompact() already
/// degrade gracefully via a sync fallback; time() used to call
/// DateFormat.jm/Hm directly and threw a LocaleDataException in that
/// window. This file intentionally never calls ensureInitialized() so it
/// exercises exactly that pre-init state (each test file runs in its own
/// isolate, so this does not depend on ordering with other l10n tests).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';

void main() {
  final evening = DateTime(2026, 8, 13, 21, 5);
  final morning = DateTime(2026, 8, 13, 9, 5);

  test('time() before ensureInitialized falls back instead of throwing (TR)', () {
    OraclyL10n.bind('tr');
    expect(() => OraclyFormat.time(evening), returnsNormally);
    expect(OraclyFormat.time(evening), '21:05');
  });

  test('time() before ensureInitialized falls back instead of throwing (EN)', () {
    OraclyL10n.bind('en');
    expect(() => OraclyFormat.time(morning), returnsNormally);
    expect(OraclyFormat.time(morning), '9:05 AM');
    expect(OraclyFormat.time(evening), '9:05 PM');
  });

  test('relativeDayTime (used by dream result/history rows) does not throw '
      'before ensureInitialized', () {
    OraclyL10n.bind('tr');
    expect(
      () => OraclyFormat.relativeDayTime(evening, now: evening),
      returnsNormally,
    );
  });
}
