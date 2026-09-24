/// Phase 6E — 24 launch + 22 non-launch Classical dual-run corpus gates.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_cache_identity.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_canonical.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_classical_shadow.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_status.dart';

import 'narrative_shadow_test_support.dart';

ReadingSession _asCrossroads(ReadingSession base) {
  return ReadingSession(
    id: base.id,
    deckId: base.deckId,
    spread: TarotSpreadType.crossroads,
    intention: base.intention,
    shuffleSeed: base.shuffleSeed,
    startedAt: base.startedAt,
    drawnCards: base.drawnCards,
  );
}

void main() {
  final frozen = jsonDecode(
    File('test/fixtures/tarot_narrative_classical_shadow_v1.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final frozenRows = (frozen['scenarios'] as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  test('launch corpus 24/24 PASS + frozen fixture lock', () {
    expect(frozen['scenarioCount'], 24);
    expect(frozenRows, hasLength(24));
    final launch = launchScenarios();
    expect(launch, hasLength(24));
    var single = 0, three = 0, five = 0;
    for (final scenario in launch) {
      final a = evaluateScenario(scenario);
      final b = evaluateScenario(scenario);
      expect(a.isPass, isTrue, reason: '${scenario['id']}');
      expect(a.status, NarrativeTarotShadowStatus.pass);
      expect(b.structuralFingerprint, a.structuralFingerprint);
      expect(b.narrativeCacheKey, a.narrativeCacheKey);
      expect(
        NarrativeTarotPromptCanonical.toMap(b.promptInput!),
        NarrativeTarotPromptCanonical.toMap(a.promptInput!),
      );
      expect(b.wirePayload, a.wirePayload);
      expect(a.parity!.overallPass, isTrue);
      expect(
        a.narrativeCacheKey!.startsWith(NarrativeTarotCacheIdentity.keyPrefix),
        isTrue,
      );
      expect(
        a.wirePayload!.keys.toSet(),
        {'mode', 'contractVersion', 'language', 'narrative'},
      );
      final actual = freezeShadowRecord(scenario: scenario, result: a);
      final expected = frozenRows.firstWhere(
        (r) => r['scenarioId'] == scenario['id'],
      );
      expect(actual, expected, reason: 'fixture drift ${scenario['id']}');
      final spread = (scenario['input'] as Map)['spreadType'] as String;
      if (spread == 'single') single++;
      if (spread == 'threeCard') three++;
      if (spread == 'fiveCard') five++;
    }
    expect(single, 5);
    expect(three, 9);
    expect(five, 10);
  });

  test('non-launch seven/celtic 22/22 notLiveLaunchCandidate', () {
    final non = nonLaunchScenarios();
    expect(non, hasLength(22));
    var seven = 0, celtic = 0;
    for (final scenario in non) {
      final result = evaluateScenario(scenario);
      expect(
        result.status,
        NarrativeTarotShadowStatus.notLiveLaunchCandidate,
        reason: '${scenario['id']}',
      );
      expect(result.finalNarrativeRequest, isNull);
      expect(result.wirePayload, isNull);
      final spread = (scenario['input'] as Map)['spreadType'] as String;
      if (spread == 'sevenCard') seven++;
      if (spread == 'celticCross') celtic++;
    }
    expect(seven, 9);
    expect(celtic, 13);
  });

  test('crossroads is notLiveLaunchCandidate', () {
    final five = launchScenarios().firstWhere(
      (s) => (s['input'] as Map)['spreadType'] == 'fiveCard',
    );
    final result = NarrativeTarotClassicalShadow.evaluate(
      session: _asCrossroads(sessionFromEvidence(five)),
      readingId: 'read_cr_firewall',
      languageCode: 'en',
    );
    expect(result.status, NarrativeTarotShadowStatus.notLiveLaunchCandidate);
    expect(result.finalNarrativeRequest, isNull);
  });
}
