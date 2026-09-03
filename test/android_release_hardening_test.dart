/// Android release hardening — R8 minify + shrink + signing safety.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  final gradle = File('$root/android/app/build.gradle.kts');
  final proguard = File('$root/android/app/proguard-rules.pro');
  final example = File('$root/android/key.properties.example');

  test('release enables R8 minify and resource shrinking', () {
    final body = gradle.readAsStringSync();
    expect(body, contains('isMinifyEnabled = true'));
    expect(body, contains('isShrinkResources = true'));
    expect(
      body,
      contains('proguard-android-optimize.txt'),
    );
    expect(body, contains('"proguard-rules.pro"'));
    // Debug must not enable minify in this file.
    expect(
      RegExp(r'debug\s*\{[^}]*isMinifyEnabled\s*=\s*true', dotAll: true)
          .hasMatch(body),
      isFalse,
    );
  });

  test('release signing never falls back to debug', () {
    final body = gradle.readAsStringSync();
    expect(body, contains('signingConfigs.getByName("release")'));
    expect(body, isNot(contains('getByName("debug")')));
    expect(body, contains('Silent debug signing fallback is disabled'));
    expect(body, contains('key.properties'));
    expect(example.existsSync(), isTrue);
  });

  test('proguard rules stay minimal — no global keep-all', () {
    expect(proguard.existsSync(), isTrue);
    final rules = proguard.readAsStringSync();
    expect(rules, isNot(contains('-keep class ** { *; }')));
    expect(rules, contains('io.flutter.embedding'));
    expect(rules, contains('-dontwarn com.google.android.play.core'));
  });
}