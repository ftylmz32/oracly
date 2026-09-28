// Dream Phase 4C.2 — every live body the backend accepted in the model
// comparison, replayed offline through the production client exactly as
// the backend returned it (sanitized symbols; no provider call). The
// committed 4C.2 replay is frozen; the 4C.2a replay lives in its own file.
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

  // The 4C.2 replay is frozen evidence: it is only read, never rewritten.
  // The one 4C.2a client change is the provider-AI guard no longer applying
  // the local template-style check, so the only permitted drift is a field
  // the frozen replay refused at `HumanReader.looksGeneric` now delivered.
  test('4C.2 client replay matches the frozen artifact up to 4C.2a drift', () {
    final frozen = jsonDecode(File(_replay).readAsStringSync()) as Map;
    expect(frozen['schema'], 'oracly.dream.phase4c2.client-replay/v1');
    final before = (frozen['replays'] as List).cast<Map>();
    final now = replays();
    expect([for (final r in now) r['runId']],
        [for (final r in before) r['runId']]);
    final drifted = <String>[];
    for (final (i, old) in before.indexed) {
      final next = now[i];
      if (jsonEncode(old) == jsonEncode(next)) continue;
      drifted.add(old['runId'] as String);
      final oldFields = old['fields'] as Map;
      final nextFields = next['fields'] as Map;
      for (final field in oldFields.keys) {
        if (jsonEncode(oldFields[field]) == jsonEncode(nextFields[field])) {
          continue;
        }
        expect((oldFields[field] as Map)['layer'], 'HumanReader.looksGeneric',
            reason: '${old['runId']}.$field');
        expect((nextFields[field] as Map)['source'], 'ai');
      }
    }
    expect(drifted, ['tr-history::gpt-6-astra']);
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
