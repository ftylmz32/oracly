library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lockfile contains every declared dependency and restored record', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();
    final dependencyBlock = RegExp(
      r'^dependencies:\s*$([\s\S]*?)^flutter:\s*$',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!;
    final devBlock = RegExp(
      r'^dev_dependencies:\s*$([\s\S]*?)^(?:flutter:|dependency_overrides:)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1)!;
    final names = RegExp(
      r'^  ([a-zA-Z0-9_]+):',
      multiLine: true,
    ).allMatches('$dependencyBlock\n$devBlock').map((m) => m.group(1)!).toSet();
    for (final name in names) {
      expect(
        RegExp('^  ${RegExp.escape(name)}:', multiLine: true).hasMatch(lock),
        isTrue,
        reason: '$name is not locked',
      );
    }

    const restored = {
      'flutter_secure_storage': '9.2.4',
      'flutter_secure_storage_linux': '1.2.3',
      'flutter_secure_storage_macos': '3.1.3',
      'flutter_secure_storage_platform_interface': '1.1.2',
      'flutter_secure_storage_web': '1.2.1',
      'flutter_secure_storage_windows': '3.1.2',
      'js': '0.6.7',
    };
    for (final entry in restored.entries) {
      final record = RegExp(
        '^  ${RegExp.escape(entry.key)}:\\r?\\n([\\s\\S]*?)(?=^  [a-zA-Z0-9_]+:|^sdks:)',
        multiLine: true,
      ).firstMatch(lock)?.group(1);
      expect(record, isNotNull, reason: '${entry.key} is missing');
      expect(record, contains('version: "${entry.value}"'));
    }
  });
}
