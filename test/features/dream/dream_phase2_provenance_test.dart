/// Dream Phase 2 — typed section provenance, `fromAi` meaning, legacy decode.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/data/dream_record_mapper.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/models/dream_provenance.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_reading_provenance.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';

Future<Dream> _analyze(OraclyAiService ai, [MemDreamRepository? repo]) async {
  final result = await DreamExperienceService(
    repository: repo ?? MemDreamRepository(),
    owner: testDreamOwner(),
    ai: ai,
  ).analyze(narrative: phase2Narrative);
  return result.dream;
}

/// Every required section accepted; no provider symbols (composed locally).
final _symbolsLocal = DreamAiAnalysis(
  summary: phase2AllAccepted.summary,
  symbols: const [],
  emotionalTheme: phase2AllAccepted.emotionalTheme,
  interpretation: phase2AllAccepted.interpretation,
  dailyLifeReflection: phase2AllAccepted.dailyLifeReflection,
  conclusion: phase2AllAccepted.conclusion,
);

/// Everything accepted except an unrelated daily reflection.
final _reflectionRejected = DreamAiAnalysis(
  summary: phase2AllAccepted.summary,
  symbols: phase2AllAccepted.symbols,
  emotionalTheme: phase2AllAccepted.emotionalTheme,
  interpretation: phase2AllAccepted.interpretation,
  dailyLifeReflection: 'Bugün uzak bir limanda gemileri izlemek iyi gelebilir.',
  conclusion: phase2AllAccepted.conclusion,
);

Map<String, dynamic> _roundTrip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  test('A — every displayed section accepted: fromAi, AI only', () async {
    final dream = await _analyze(ScriptedDreamAi(phase2AllAccepted));
    expect(dream.fromAi, isTrue);
    expect(DreamReadingProvenance.of(dream), DreamProvenance.aiOnly);
    expect(
      DreamCopy.readingFootnote(DreamReadingProvenance.of(dream)),
      startsWith(DreamCopy.sourceAi),
    );
    final themes = dream.insights
        .where((i) => i.kind == DreamInsightKind.themes)
        .map((i) => i.source);
    expect(themes, everyElement(DreamInsightSource.local));
  });

  test('B — optional symbols composed locally: fromAi, mixed', () async {
    final dream = await _analyze(ScriptedDreamAi(_symbolsLocal));
    expect(dream.fromAi, isTrue);
    expect(DreamReadingProvenance.of(dream), DreamProvenance.mixed);
    final symbols =
        dream.insights.singleWhere((i) => i.kind == DreamInsightKind.symbols);
    expect(symbols.source, DreamInsightSource.local);
  });

  // Phase 4B: a required section replaced locally used to ship as "mixed";
  // it is now an invalid response and nothing is stored.
  for (final (name, reply) in [
    ('B2 — one required section rejected', _reflectionRejected),
    ('C — every provider section rejected', phase2AllRejected),
  ]) {
    test('$name: invalid response, nothing stored', () async {
      final repo = MemDreamRepository();
      final ai = ScriptedDreamAi(reply);
      await expectLater(_analyze(ai, repo), throwsInvalidDreamResponse);
      expect(ai.contexts, hasLength(1));
      expect(await repo.getAll(), isEmpty);
    });
  }

  test('local-only footnote never claims AI', () {
    expect(
      DreamCopy.readingFootnote(DreamProvenance.localOnly),
      isNot(contains('yapay zek')),
    );
  });

  test('D — dev local fallback: not fromAi, local only', () async {
    final dream = await _analyze(
      const UnconfiguredOraclyAiService(allowsLocalFallback: true),
    );
    expect(dream.fromAi, isFalse);
    expect(DreamReadingProvenance.of(dream), DreamProvenance.localOnly);
  });

  test('E — legacy record flagged fromAi stays legacy, never AI', () {
    final legacy = Dream.fromJson({
      'id': 'dream_legacy',
      'narrative': phase2Narrative,
      'recordedAt': DateTime(2026, 1, 2).toIso8601String(),
      'fromAi': true,
      'insights': [
        {'kind': 'mainInterpretation', 'body': 'Eski bir yorum metni.'},
        {'kind': 'closingTakeaway', 'body': 'Eski bir soru?'},
      ],
    });
    expect(
      legacy.insights.map((i) => i.source).toSet(),
      {DreamInsightSource.legacyUnknown},
    );
    expect(DreamReadingProvenance.of(legacy), DreamProvenance.legacyUnknown);
    final footnote = DreamCopy.readingFootnote(
      DreamReadingProvenance.of(legacy),
    );
    expect(footnote, startsWith(DreamCopy.sourceSaved));
    expect(footnote.toLowerCase(), isNot(contains('yapay zek')));
    expect(footnote, isNot(contains(DreamCopy.sourceLocal)));
    // Decoding is read-only: nothing is upgraded or rewritten.
    expect(legacy.toJson()['insights'], everyElement(containsPair(
      'source',
      DreamInsightSource.legacyUnknown.name,
    )));
  });

  test('source survives JSON, record persistence and reopen', () async {
    final repo = MemDreamRepository();
    final dream = await _analyze(ScriptedDreamAi(_symbolsLocal), repo);
    final sources = dream.insights.map((i) => i.source).toList();
    final decoded = Dream.fromJson(_roundTrip(dream.toJson()));
    expect(decoded.insights.map((i) => i.source), sources);
    final reopened = DreamRecordMapper.fromRecord((await repo.getAll()).single);
    expect(reopened.insights.map((i) => i.source), sources);
    expect(DreamReadingProvenance.of(reopened), DreamProvenance.mixed);
  });
}
