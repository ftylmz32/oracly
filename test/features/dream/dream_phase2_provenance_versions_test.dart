/// Dream Phase 2 — section provenance through reading-version payloads.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/models/dream_provenance.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_reading_provenance.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase2_support.dart';

Future<Dream> _analyze(OraclyAiService ai) async {
  final result = await DreamExperienceService(
    repository: MemDreamRepository(),
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

Map<String, dynamic> _roundTrip(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  test('source survives version payload append and selection', () async {
    final older = await _analyze(ScriptedDreamAi(_symbolsLocal));
    final newer = await _analyze(
      const UnconfiguredOraclyAiService(allowsLocalFallback: true),
    );
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
