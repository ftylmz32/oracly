/// Production dart-define file contract — public config only, no secrets.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production dart-define example is public-only and HTTPS-shaped', () {
    final example = File('tool/dart_defines.production.example.json');
    expect(example.existsSync(), isTrue);
    final map = jsonDecode(example.readAsStringSync()) as Map<String, dynamic>;
    expect(map['APP_ENV'], 'production');
    final proxy = map['ORACLY_AI_PROXY_URL'] as String;
    expect(proxy.startsWith('https://'), isTrue);
    expect(proxy.contains('/v1/ai/complete'), isTrue);
    expect(proxy.toLowerCase(), isNot(contains('127.0.0.1')));
    expect(proxy.toLowerCase(), isNot(contains('localhost')));
    for (final key in map.keys) {
      expect(key.toUpperCase(), isNot(contains('OPENAI')));
      expect(key.toUpperCase(), isNot(contains('SECRET')));
      expect(key.toUpperCase(), isNot(contains('API_KEY')));
    }
    expect(map.containsKey('OPENAI_API_KEY'), isFalse);
  });

  test('real production dart-define file is gitignored', () {
    final ignore = File('.gitignore').readAsStringSync();
    expect(ignore, contains('tool/dart_defines.production.json'));
    expect(ignore, contains('dart_defines.production.json'));
  });
}
