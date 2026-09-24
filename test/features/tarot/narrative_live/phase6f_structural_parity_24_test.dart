/// Phase 6F — live request factory preserves the frozen 24 Classical
/// launch scenarios structurally. Structure only — never prose.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_request_factory.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_session.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_spreads.dart';

import '../narrative_shadow/narrative_shadow_test_support.dart';
import 'phase6f_live_support.dart';

final _now = DateTime.utc(2026, 9, 24, 19);

NarrativeTarotLiveBuiltRequest _build(Map<String, dynamic> scenario) {
  final input = Map<String, dynamic>.from(scenario['input'] as Map);
  return NarrativeTarotLiveRequestFactory.build(
    session: sessionFromEvidence(scenario),
    languageCode: input['languageCode'] as String,
    historyLoad: emptyHistoryLoad(),
    now: _now,
  );
}

void main() {
  final scenarios = launchScenarios();

  test('frozen launch corpus is exactly 24 Classical scenarios', () {
    expect(scenarios, hasLength(24));
    for (final s in scenarios) {
      final input = Map<String, dynamic>.from(s['input'] as Map);
      final type = spreadTypeNamed(input['spreadType'] as String);
      expect(NarrativeTarotLiveSpreads.isLiveLaunchCandidate(type), isTrue);
    }
  });

  group('structural parity 24/24', () {
    for (final scenario in scenarios) {
      final id = scenario['id'] as String;
      final input = Map<String, dynamic>.from(scenario['input'] as Map);
      final expected = Map<String, dynamic>.from(scenario['expected'] as Map);

      test('$id — identity, cards, question and locale preserved', () {
        final session = sessionFromEvidence(scenario);
        expect(NarrativeTarotLiveSession.guard(session), isNull);

        final TarotNarrativeRequest request = _build(scenario).request;

        expect(request.narrativeTarotVersion, expected['narrativeTarotVersion']);
        expect(request.languageCode, expected['languageCode']);
        expect(request.languageCode, input['languageCode']);
        expect(request.spread.spreadId, expected['spreadId']);
        expect(
          request.spread.spreadId,
          NarrativeTarotLiveSpreads.narrativeSpreadId(session.spread),
        );
        expect(request.spread.cardCount, expected['cardCount']);
        expect(request.cards, hasLength(expected['cardCount']));

        final cards = (expected['cards'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        expect(
          [for (final c in request.cards) c.canonicalCardId],
          expected['cardOrder'],
        );
        expect(
          [for (final c in request.cards) c.ritualCardId],
          [for (final c in cards) c['ritualCardId']],
        );
        expect(
          [for (final c in request.cards) c.isReversed],
          [for (final c in cards) c['isReversed']],
        );
        expect(
          [for (final c in request.cards) c.positionKey],
          [for (final c in cards) c['positionKey']],
        );
        expect(
          [for (final c in request.cards) c.positionIndex],
          [for (final c in cards) c['positionIndex']],
        );

        final question = Map<String, dynamic>.from(
          expected['question'] as Map,
        );
        expect(request.question.rawText, question['rawText']);
        expect(request.question.topic, question['topic']);
        expect(request.question.kind.name, question['kind']);
        expect(request.question.hasRealQuestion, question['hasRealQuestion']);

        expect(request.relationships, hasLength(expected['relationshipCount']));
        expect(request.sessionId, session.id);
        expect(request.readingId, session.id);
      });
    }
  });

  test('wire payload mirrors the built request structure', () {
    for (final scenario in scenarios) {
      final built = _build(scenario);
      final expected = Map<String, dynamic>.from(scenario['expected'] as Map);
      final wire = built.wirePayload;
      expect(wire['mode'], 'narrative_v2');
      expect(wire['language'], expected['languageCode']);
      final narrative = Map<String, Object?>.from(
        wire['narrative']! as Map,
      );
      final spread = Map<String, Object?>.from(narrative['spread']! as Map);
      expect(spread['spreadId'], expected['spreadId']);
      expect(spread['cardCount'], expected['cardCount']);
      expect(
        [
          for (final c in narrative['cards']! as List)
            (c as Map)['canonicalCardId'],
        ],
        expected['cardOrder'],
      );
    }
  });
}
