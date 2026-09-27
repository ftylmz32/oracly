// Dream Phase 3 — the canonical synthetic corpus shared with the backend
// (`backend/tests/fixtures/dream_safety/`) proves client/backend parity.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/safety/dream_output_safety.dart';
import 'package:oracly_new/features/dream/safety/dream_safety_policy.dart';

List<Map<String, dynamic>> _rows(String name) {
  final file = File('backend/tests/fixtures/dream_safety/$name.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (json['rows'] as List).cast<Map<String, dynamic>>();
}

void main() {
  group('input corpus', () {
    final rows = _rows('input_corpus');

    test('covers every concern and false-positive controls in TR/EN/RU', () {
      for (final lang in ['tr', 'en', 'ru']) {
        final mine = rows.where((r) => r['language'] == lang);
        expect(mine.where((r) => r['expected'] == 'allow'), isNotEmpty);
        for (final concern in [
          'crisis',
          'acute_distress',
          'trauma',
          'delusion',
          'diagnosis',
        ]) {
          expect(
            mine.where((r) => r['concern'] == concern),
            isNotEmpty,
            reason: '$lang $concern',
          );
        }
      }
    });

    for (final row in rows) {
      test('${row['language']} ${row['expected']}: ${row['text']}', () {
        final concern = DreamSafetyPolicy.classify([row['text'] as String]);
        expect(concern?.code, row['concern']);
      });
    }
  });

  group('output corpus', () {
    for (final row in _rows('output_corpus')) {
      test('${row['language']} ${row['expected']}: ${row['text']}', () {
        expect(
          DreamOutputSafety.violation([row['text'] as String]),
          row['check'],
        );
      });
    }
  });
}
