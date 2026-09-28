// Dream Phase 4C — every backend-PASS live body replayed offline through the
// production client pipeline (no provider call). The committed replay is the
// frozen 4C evidence; the 4C.1 replay lives in its own artifact.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';

import 'dream_phase4b_support.dart';
import 'dream_phase4c_replay.dart';
import 'dream_phase4c_rewrite.dart';
import 'dream_phase4c_support.dart';

const _artifact = 'docs/product/dream/evals/DREAM_PHASE4C_LIVE_RUN_20260928.json';
const _replay =
    'docs/product/dream/evals/DREAM_PHASE4C_CLIENT_REPLAY_20260928.json';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('replay proof: backend premium goldens replay as full AI readings', () {
    for (final g in loadDreamGoldens()) {
      final r = replayClient(
        runId: g.id,
        narrative: g.narrative,
        appLanguage: g.language,
        data: g.data,
      );
      expect(r['clientResult'], 'PASS', reason: g.id);
      expect(r['requiredAiSections'], 5, reason: g.id);
      expect(r['clientLanguage'], g.language, reason: g.id);
    }
  });

  test('replay proof: a refused field names its layer', () {
    final g = dreamGolden('en-rich-negated-fear');
    final r = replayClient(
      runId: 'probe',
      narrative: g.narrative,
      appLanguage: 'en',
      data: {...g.data, 'conclusion': 'Why the lamp? Why the waves?'},
    );
    expect(r['clientResult'], 'FAIL_DELIVERY');
    expect(r['clientGap'], 'closingTakeaway');
    final closing = (r['fields'] as Map)['conclusion'] as Map;
    expect(closing['layer'], 'DreamAnalysisGuard.questionCount');
    expect(rewriteClass('A b c.', 'A b c'), 'format_only');
    expect(rewriteClass('one two three four five', 'one two three four six'),
        'lexically_changed');
  });

  test('committed client replay matches the live artifact', () {
    final file = File(_artifact);
    if (!file.existsSync()) {
      markTestSkipped('no live artifact yet');
      return;
    }
    final cases = {for (final c in loadPhase4cCases()) c['id']: c};
    final runs = (jsonDecode(file.readAsStringSync()) as Map)['runs'] as List;
    List<Map<String, dynamic>> replay(bool Function(Map run) include) => [
      for (final run in runs.cast<Map>())
        if (include(run) && run['stages'] != null)
          replayClient(
            runId: run['runId'] as String,
            narrative: cases[run['caseId']]!['narrative'] as String,
            appLanguage: run['language'] as String,
            data: Map<String, dynamic>.from(
                (run['stages'] as Map)['parsed'] as Map),
            selectedEmotions: [
              for (final id
                  in (cases[run['caseId']]!['selectedEmotions'] as List?) ??
                      const [])
                DreamEmotion(id: DreamEmotionId.values.byName(id as String)),
            ],
            memorySummary: run['memorySummary'] as String?,
          ),
    ];
    // The 4C replay is frozen evidence: it is only read, never rewritten.
    final frozen = jsonDecode(File(_replay).readAsStringSync()) as Map;
    expect(frozen['schema'], 'oracly.dream.phase4c.client-replay/v1');
    expect(jsonEncode(frozen['replays']),
        jsonEncode(replay((run) => run['backendFinal'] == 'PASS')));
    // Diagnostic only: bodies the backend refused never reach a client. The
    // one 4C.1 client change is emotionalTheme role grounding, so the only
    // permitted drift is an emotionalTheme field moving local → ai.
    final now = {
      for (final r in replay((run) => run['backendFinal'] == 'REJECT'))
        r['runId']: r,
    };
    final before = (frozen['diagnosticRejectedReplays'] as List).cast<Map>();
    expect(before.map((r) => r['runId']).toList(), now.keys.toList());
    for (final old in before) {
      final next = now[old['runId']]!;
      final oldFields = old['fields'] as Map;
      final nextFields = next['fields'] as Map;
      for (final field in oldFields.keys) {
        if (jsonEncode(oldFields[field]) == jsonEncode(nextFields[field])) {
          continue;
        }
        expect(field, 'emotionalTheme', reason: '${old['runId']}');
        expect((oldFields[field] as Map)['source'], 'local');
        expect((nextFields[field] as Map)['source'], 'ai');
      }
    }
  });
}
