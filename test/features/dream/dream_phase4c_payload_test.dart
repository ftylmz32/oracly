// Dream Phase 4C — the live corpus payloads are the production client's own
// requests. `PHASE4C_WRITE_PAYLOADS=1` regenerates the committed fixture;
// otherwise the committed fixture must match what the client builds today.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'dream_phase4c_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('committed Phase 4C payloads are the client requests', () async {
    final cases = loadPhase4cCases();
    final built = [for (final c in cases) await clientRequest(c)];

    expect(cases, hasLength(24));
    for (final r in built) {
      final payload = r['payload'] as Map<String, dynamic>;
      expect(payload['language'], r['language'], reason: '${r['id']}');
      if (r['category'] == 'safe_connected_memory') {
        expect(payload['memorySummary'], isA<String>(), reason: '${r['id']}');
        expect(
          r['memorySource'],
          r['language'] == 'ru' ? 'retriever_recall_fallback' : 'retriever',
          reason: '${r['id']}',
        );
      }
      if (r['category'] == 'prior_dream_history') {
        expect(payload['history'], isNotEmpty, reason: '${r['id']}');
      }
    }

    final encoded =
        '${const JsonEncoder.withIndent('  ').convert({'requests': built})}\n';
    final file = File(phase4cPayloadsPath);
    if (Platform.environment['PHASE4C_WRITE_PAYLOADS'] == '1') {
      file.writeAsStringSync(encoded);
    }
    expect(file.readAsStringSync().replaceAll('\r\n', '\n'), encoded);
  });
}
