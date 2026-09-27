/// Dream Phase 2 — typed section provenance, `fromAi` meaning, legacy decode.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
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

  test('B — some sections replaced locally: fromAi, mixed', () async {
    final dream = await _analyze(const LiveDreamAiStub());
    expect(dream.fromAi, isTrue);
    expect(DreamReadingProvenance.of(dream), DreamProvenance.mixed);
  });

  test('C — every provider section rejected: not fromAi, local only', () async {
    final dream = await _analyze(ScriptedDreamAi(phase2AllRejected));
    expect(dream.fromAi, isFalse);
    expect(
      dream.insights.map((i) => i.source).toSet(),
      {DreamInsightSource.local},
    );
    expect(
      dream.insights.map((i) => i.kind),
      isNot(contains(DreamInsightKind.mainInterpretation)),
    );
    expect(DreamReadingProvenance.of(dream), DreamProvenance.localOnly);
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
    final dream = await _analyze(const LiveDreamAiStub(), repo);
    final sources = dream.insights.map((i) => i.source).toList();
    final decoded = Dream.fromJson(_roundTrip(dream.toJson()));
    expect(decoded.insights.map((i) => i.source), sources);
    final reopened = DreamRecordMapper.fromRecord((await repo.getAll()).single);
    expect(reopened.insights.map((i) => i.source), sources);
    expect(DreamReadingProvenance.of(reopened), DreamProvenance.mixed);
  });

  test('source survives version payload append and selection', () async {
    final older = await _analyze(const LiveDreamAiStub());
    final newer = await _analyze(ScriptedDreamAi(phase2AllRejected));
    final payloads = [
      _roundTrip(ReadingVersionPayload.dream(older, 'a')),
      _roundTrip(ReadingVersionPayload.dream(newer, 'b')),
    ];
    final selectedOld = ReadingVersionPayload.applyDream(newer, payloads[0])!;
    final selectedNew = ReadingVersionPayload.applyDream(older, payloads[1])!;
    expect(DreamReadingProvenance.of(selectedOld), DreamProvenance.mixed);
    expect(DreamReadingProvenance.of(selectedNew), DreamProvenance.localOnly);
    expect(
      selectedOld.insights.map((i) => i.source),
      older.insights.map((i) => i.source),
    );
  });

  test('legacy version payload decodes neutrally', () {
    final legacy = ReadingVersionPayload.applyDream(null, {
      'analysis': 'Eski',
      'payload': {
        'id': 'dream_old_version',
        'narrative': phase2Narrative,
        'recordedAt': DateTime(2025, 6, 1).toIso8601String(),
        'fromAi': true,
        'insights': [
          {'kind': 'summary', 'body': 'Eski özet metni.'},
        ],
      },
    })!;
    expect(DreamReadingProvenance.of(legacy), DreamProvenance.legacyUnknown);
    expect(DreamReadingProvenance.hasAcceptedAi(legacy.insights), isFalse);
  });

  test('unknown source values decode as legacy, never AI', () {
    expect(DreamInsightSource.fromJson('AI'), DreamInsightSource.legacyUnknown);
    expect(DreamInsightSource.fromJson(null), DreamInsightSource.legacyUnknown);
    expect(DreamInsightSource.fromJson(1), DreamInsightSource.legacyUnknown);
    expect(DreamInsightSource.fromJson('ai'), DreamInsightSource.ai);
  });
}
