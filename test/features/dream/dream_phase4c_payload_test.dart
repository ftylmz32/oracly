// Dream Phase 4C — the live corpus payloads are the production client's own
// requests. The committed fixture is the frozen input of the 4C live run: the
// client must still build byte-identical payloads for it, and since 4C.1 the
// Russian connected memory arrives through ordinary retrieval (no recall
// fallback).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'dream_phase4c_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('committed Phase 4C payloads are the client requests', () async {
    final cases = loadPhase4cCases();
    final built = [for (final c in cases) await clientRequest(c)];
    final fixture = [
      for (final r in (jsonDecode(File(phase4cPayloadsPath).readAsStringSync())
          as Map)['requests'] as List)
        Map<String, dynamic>.from(r as Map),
    ];

    expect(cases, hasLength(24));
    expect(built, hasLength(fixture.length));
    for (final (i, r) in built.indexed) {
      final payload = r['payload'] as Map<String, dynamic>;
      expect(payload['language'], r['language'], reason: '${r['id']}');
      if (r['category'] == 'safe_connected_memory') {
        expect(payload['memorySummary'], isA<String>(), reason: '${r['id']}');
        expect(r['memorySource'], 'retriever', reason: '${r['id']}');
      }
      if (r['category'] == 'prior_dream_history') {
        expect(payload['history'], isNotEmpty, reason: '${r['id']}');
      }
      final frozen = fixture[i];
      expect(r['id'], frozen['id']);
      expect(r['model'], frozen['model'], reason: '${r['id']}');
      expect(jsonEncode(payload), jsonEncode(frozen['payload']),
          reason: '${r['id']}');
    }
  });
}
