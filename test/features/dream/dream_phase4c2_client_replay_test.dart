// Dream Phase 4C.2 — every live body the backend accepted in the model
// comparison, replayed offline through the production client exactly as
// the backend returned it (sanitized symbols; no provider call).
// `PHASE4C2_WRITE_CLIENT=1` writes the 4C.2 replay; otherwise the committed
// one must match.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';

import 'dream_phase4c_replay.dart';
import 'dream_phase4c_support.dart';

const _artifact =
    'docs/product/dream/evals/DREAM_PHASE4C2_MODEL_AB_20260928.json';
const _replay =
    'docs/product/dream/evals/DREAM_PHASE4C2_CLIENT_REPLAY_20260928.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Map<String, dynamic>> replays() {
    final cases = {for (final c in loadPhase4cCases()) c['id']: c};
    final artifact =
        jsonDecode(File(_artifact).readAsStringSync()) as Map<String, dynamic>;
    return [
      for (final a in (artifact['attempts'] as List).cast<Map>())
        if (a['backendFinal'] == 'PASS')
          () {
            final c = cases[a['caseId']]!;
            return {
              'candidateModel': a['candidateModel'],
              ...replayClient(
                runId: a['attemptId'] as String,
                narrative: c['narrative'] as String,
                appLanguage: a['language'] as String,
                data: {
                  ...Map<String, dynamic>.from(a['parsed'] as Map),
                  'symbols': a['filteredSymbols'],
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

  test('4C.2 client replay of every backend PASS matches the artifact', () {
    final encoded = '${const JsonEncoder.withIndent('  ').convert({
          'schema': 'oracly.dream.phase4c2.client-replay/v1',
          'source': _artifact,
          'bodies': 'live 4C.2 parsed body with the backend-filtered symbols',
          'replays': replays(),
        })}\n';
    final out = File(_replay);
    if (Platform.environment['PHASE4C2_WRITE_CLIENT'] == '1') {
      out.writeAsStringSync(encoded);
    }
    expect(out.readAsStringSync().replaceAll('\r\n', '\n'), encoded);
  });

  test('every backend PASS was replayed through the client', () {
    final artifact =
        jsonDecode(File(_artifact).readAsStringSync()) as Map<String, dynamic>;
    final passes = [
      for (final a in (artifact['attempts'] as List).cast<Map>())
        if (a['backendFinal'] == 'PASS') a['attemptId'],
    ];
    expect(passes, isNotEmpty);
    expect([for (final r in replays()) r['runId']], passes);
  });
}
