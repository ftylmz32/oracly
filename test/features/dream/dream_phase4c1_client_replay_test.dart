// Dream Phase 4C.1 — every frozen live body the 4C.1 backend now accepts,
// replayed offline through the production client with the sanitized symbol
// array (no provider call). `PHASE4C1_WRITE_CLIENT=1` writes the 4C.1 replay;
// otherwise the committed one must match. The frozen 4C files are only read.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';

import 'dream_phase4c_replay.dart';
import 'dream_phase4c_support.dart';

const _frozen = 'docs/product/dream/evals/DREAM_PHASE4C_LIVE_RUN_20260928.json';
const _reclassified = 'docs/product/dream/evals/'
    'DREAM_PHASE4C1_OFFLINE_RECLASSIFICATION_20260928.json';
const _replay =
    'docs/product/dream/evals/DREAM_PHASE4C1_CLIENT_REPLAY_20260928.json';

Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Map<String, dynamic>> replays() {
    final cases = {for (final c in loadPhase4cCases()) c['id']: c};
    final runs = {
      for (final r in (_read(_frozen)['runs'] as List).cast<Map>())
        r['runId']: r,
    };
    return [
      for (final row in (_read(_reclassified)['runs'] as List).cast<Map>())
        if (row['newBackendFinal'] == 'PASS')
          () {
            final run = runs[row['runId']]!;
            final c = cases[run['caseId']]!;
            return replayClient(
              runId: row['runId'] as String,
              narrative: c['narrative'] as String,
              appLanguage: run['language'] as String,
              data: {
                ...Map<String, dynamic>.from(
                    (run['stages'] as Map)['parsed'] as Map),
                'symbols': row['filteredSymbols'],
              },
              selectedEmotions: [
                for (final id in (c['selectedEmotions'] as List?) ?? const [])
                  DreamEmotion(
                      id: DreamEmotionId.values.byName(id as String)),
              ],
              memorySummary: run['memorySummary'] as String?,
            );
          }(),
    ];
  }

  test('4C.1 client replay of every new backend PASS matches the artifact',
      () {
    final encoded = '${const JsonEncoder.withIndent('  ').convert({
          'schema': 'oracly.dream.phase4c1.client-replay/v1',
          'source': _reclassified,
          'bodies': 'frozen 4C parsed body with the 4C.1 filtered symbols',
          'replays': replays(),
        })}\n';
    final out = File(_replay);
    if (Platform.environment['PHASE4C1_WRITE_CLIENT'] == '1') {
      out.writeAsStringSync(encoded);
    }
    expect(out.readAsStringSync().replaceAll('\r\n', '\n'), encoded);
  });

  test('backend-accepted live bodies deliver all five AI sections', () {
    final all = replays();
    expect(all, isNotEmpty);
    for (final r in all) {
      expect(r['clientResult'], 'PASS', reason: '${r['runId']}');
      expect(r['requiredAiSections'], 5, reason: '${r['runId']}');
      expect(r['fromAi'], isTrue, reason: '${r['runId']}');
    }
  });
}
