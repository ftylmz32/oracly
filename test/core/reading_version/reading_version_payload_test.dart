/// Reading version payload application — corrupted stored versions must not
/// crash the reader when switching between saved revisions.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/features/dream/models/dream.dart';

void main() {
  final base = Dream(
    id: 'dream_1',
    narrative: 'Uçtuğumu gördüm',
    recordedAt: DateTime(2024, 1, 1),
  );

  test('applyDream returns the parsed dream for a well-formed payload', () {
    final result = ReadingVersionPayload.applyDream(base, {
      'payload': base.toJson(),
    });

    expect(result, isNotNull);
    expect(result!.id, base.id);
  });

  test('applyDream falls back to base instead of crashing on a corrupted payload', () {
    // Missing required fields ('narrative', 'recordedAt') that Dream.fromJson
    // hard-casts — this simulates a schema-drifted / partially written entry.
    final result = ReadingVersionPayload.applyDream(base, {
      'payload': <String, dynamic>{'id': 'dream_1'},
    });

    expect(result, base);
  });

  test('applyDream falls back to base when payload has the wrong type', () {
    final result = ReadingVersionPayload.applyDream(base, {
      'payload': 'not-a-map',
    });

    expect(result, base);
  });

  test('applyDream returns null when there is no base and payload is unusable', () {
    final result = ReadingVersionPayload.applyDream(null, {
      'payload': <String, dynamic>{'id': 'dream_1'},
    });

    expect(result, isNull);
  });
}
