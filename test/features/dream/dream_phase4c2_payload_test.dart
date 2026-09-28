// Dream Phase 4C.2 — the model comparison sends the production client's own
// requests for nine Phase 4C cases. Each payload is byte-identical to the
// frozen 4C fixture; the Russian connected memory now arrives through
// ordinary retrieval. `PHASE4C2_WRITE_PAYLOADS=1` writes the 4C.2 fixture;
// otherwise the committed one must match.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'dream_phase4c_support.dart';

const phase4c2PayloadsPath =
    'backend/tests/fixtures/dream-phase4c2-payloads.json';
const phase4c2Cases = [
  'tr-negated-fear',
  'en-negated-fear',
  'ru-negated-fear',
  'en-mixed-emotion',
  'tr-domain-work',
  'ru-domain-family',
  'ru-memory',
  'en-history',
  'tr-history',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('4C.2 payloads are the current client requests', () async {
    final cases = {for (final c in loadPhase4cCases()) c['id']: c};
    final frozen = {
      for (final r in (jsonDecode(File(phase4cPayloadsPath).readAsStringSync())
          as Map)['requests'] as List)
        (r as Map)['id']: r,
    };
    final built = [for (final id in phase4c2Cases) await clientRequest(cases[id]!)];

    for (final r in built) {
      expect(jsonEncode(r['payload']), jsonEncode(frozen[r['id']]!['payload']),
          reason: '${r['id']}');
      if (r['category'] == 'safe_connected_memory') {
        expect(r['memorySource'], 'retriever', reason: '${r['id']}');
        expect((r['payload'] as Map)['memorySummary'], isA<String>());
      }
    }
    final encoded = '${const JsonEncoder.withIndent('  ').convert({
          'schema': 'oracly.dream.phase4c2.payloads/v1',
          'source': 'test/features/dream/dream_phase4c2_payload_test.dart',
          'requests': built,
        })}\n';
    final out = File(phase4c2PayloadsPath);
    if (Platform.environment['PHASE4C2_WRITE_PAYLOADS'] == '1') {
      out.writeAsStringSync(encoded);
    }
    expect(out.readAsStringSync().replaceAll('\r\n', '\n'), encoded);
  });
}
