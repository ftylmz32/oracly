// Dream Phase 4C.2a — every immutable 4C.2 live body the calibrated backend
// now accepts, replayed offline through the production client with the
// 4C.2a filtered symbols (no provider call). `PHASE4C2A_WRITE_CLIENT=1`
// writes the 4C.2a replay; otherwise the committed one must match. The
// frozen 4C.2 files are only read.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';

import 'dream_phase4c_replay.dart';
import 'dream_phase4c_support.dart';

const _frozen = 'docs/product/dream/evals/DREAM_PHASE4C2_MODEL_AB_20260928.json';
const _reclassified = 'docs/product/dream/evals/'
    'DREAM_PHASE4C2A_OFFLINE_RECLASSIFICATION_20260928.json';
const _replay =
    'docs/product/dream/evals/DREAM_PHASE4C2A_CLIENT_REPLAY_20260928.json';

Map<String, dynamic> _read(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Map<String, dynamic>> replays() {
    final cases = {for (final c in loadPhase4cCases()) c['id']: c};
    final attempts = {
      for (final a in (_read(_frozen)['attempts'] as List).cast<Map>())
        a['attemptId']: a,
    };
    return [
      for (final row in (_read(_reclassified)['attempts'] as List).cast<Map>())
        if (row['newBackendFinal'] == 'PASS')
          () {
            final a = attempts[row['attemptId']]!;
            final c = cases[a['caseId']]!;
            return {
              'candidateModel': a['candidateModel'],
              ...replayClient(
                runId: row['attemptId'] as String,
                narrative: c['narrative'] as String,
                appLanguage: a['language'] as String,
                data: {
                  ...Map<String, dynamic>.from(a['parsed'] as Map),
                  'symbols': row['newFilteredSymbols'],
                },
                selectedEmotions: [
                  for (final id in (c['selectedEmotions'] as List?) ?? const [])
                    DreamEmotion(
                        id: DreamEmotionId.values.byName(id as String)),
                ],
                memorySummary: a['memorySummarySent'] as String?,
              ),
            };
          }(),
    ];
  }

  test('4C.2a client replay of every new backend PASS matches the artifact',
      () {
    final encoded = '${const JsonEncoder.withIndent('  ').convert({
          'schema': 'oracly.dream.phase4c2a.client-replay/v1',
          'source': _reclassified,
          'bodies': 'immutable 4C.2 parsed body with the 4C.2a filtered symbols',
          'replays': replays(),
        })}\n';
    final out = File(_replay);
    if (Platform.environment['PHASE4C2A_WRITE_CLIENT'] == '1') {
      out.writeAsStringSync(encoded);
    }
    expect(out.readAsStringSync().replaceAll('\r\n', '\n'), encoded);
  });

  test('Astra tr-history delivers every section from provider AI', () {
    final astra =
        replays().singleWhere((r) => r['runId'] == 'tr-history::gpt-6-astra');
    expect(astra['clientResult'], 'PASS');
    expect(astra['requiredAiSections'], 5);
    expect(astra['fromAi'], isTrue);
  });
}
