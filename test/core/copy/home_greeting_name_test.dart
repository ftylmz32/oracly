/// Safe first-name extraction for the Home greeting — never truncates a
/// real name, never surfaces a placeholder/email as if it were a name.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/home_greeting_name.dart';

void main() {
  group('HomeGreetingName.firstNameOrNull', () {
    test('single first name passes through untouched', () {
      expect(HomeGreetingName.firstNameOrNull('Fatih'), 'Fatih');
    });

    test('a normal first name is never cut to 1-2 characters', () {
      final result = HomeGreetingName.firstNameOrNull('Fatih');
      expect(result, isNot('Fa'));
      expect(result, isNot('F'));
      expect(result, hasLength(5));
    });

    test('full name uses only the first token', () {
      expect(HomeGreetingName.firstNameOrNull('Fatih Taha Yılmaz'), 'Fatih');
    });

    test('preserves Turkish characters correctly', () {
      expect(HomeGreetingName.firstNameOrNull('Yılmaz'), 'Yılmaz');
      expect(HomeGreetingName.firstNameOrNull('Şükrü Öztürk'), 'Şükrü');
      expect(HomeGreetingName.firstNameOrNull('Çağla İnci'), 'Çağla');
    });

    test('trims leading, trailing, and repeated/mixed whitespace', () {
      expect(HomeGreetingName.firstNameOrNull('  Fatih  '), 'Fatih');
      expect(HomeGreetingName.firstNameOrNull('Fatih   Taha'), 'Fatih');
      expect(HomeGreetingName.firstNameOrNull('\tFatih\n'), 'Fatih');
      expect(HomeGreetingName.firstNameOrNull('   '), isNull);
    });

    test('null and empty input return null', () {
      expect(HomeGreetingName.firstNameOrNull(null), isNull);
      expect(HomeGreetingName.firstNameOrNull(''), isNull);
    });

    test('rejects null-like / placeholder values case-insensitively', () {
      for (final placeholder in [
        'null',
        'Null',
        'NULL',
        'user',
        'User',
        'guest',
        'Guest',
        '-',
        '—',
        'undefined',
        'n/a',
        'na',
      ]) {
        expect(
          HomeGreetingName.firstNameOrNull(placeholder),
          isNull,
          reason: '"$placeholder" must not be shown as a name',
        );
      }
    });

    test('never exposes an email or email-looking value as a name', () {
      expect(HomeGreetingName.firstNameOrNull('ftylmz32@gmail.com'), isNull);
      expect(HomeGreetingName.firstNameOrNull('fatih@'), isNull);
    });

    test('a real short name that happens to be 2 characters is preserved', () {
      // Distinguishes "never truncate a real name" from "never allow a
      // short name" — a genuine short name must still pass through.
      expect(HomeGreetingName.firstNameOrNull('Al'), 'Al');
    });
  });
}
