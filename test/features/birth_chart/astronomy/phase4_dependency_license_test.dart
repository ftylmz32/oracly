/// Phase 4 — dependency license firewall (no Swiss Ephemeris).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec.lock pins astronomia 1.1.1 and timezone 0.11.1', () {
    final lock = File('pubspec.lock').readAsStringSync();
    final astro = RegExp(
      r'astronomia:.*?version: "([^"]+)"',
      dotAll: true,
    ).firstMatch(lock);
    final tz = RegExp(
      r'(?:^|\n)  timezone:.*?version: "([^"]+)"',
      dotAll: true,
    ).firstMatch(lock);
    expect(astro?.group(1), '1.1.1');
    expect(tz?.group(1), '0.11.1');
  });

  test('no Swiss Ephemeris bindings in lock names', () {
    final lock = File('pubspec.lock').readAsStringSync().toLowerCase();
    for (final banned in ['swisseph', 'sweph', 'jyotish']) {
      expect(lock.contains(banned), isFalse, reason: banned);
    }
  });

  test('astronomia 1.1.1 LICENSE is MIT; no native code', () {
    final cache = Platform.environment['PUB_CACHE'] ?? '';
    final root = Directory('$cache/hosted/pub.dev/astronomia-1.1.1');
    expect(root.existsSync(), isTrue);
    final license = File('${root.path}/LICENSE').readAsStringSync();
    expect(license.toUpperCase(), contains('MIT'));
    expect(license.toLowerCase(), isNot(contains('swiss ephemeris')));
    final natives = root
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) => RegExp(r'\.(c|cpp|h|so|dll|dylib)$')
              .hasMatch(f.path.toLowerCase()),
        );
    expect(natives, isEmpty);
  });
}
