/// Phase 6E.1 — Phase 5 by-reference parity + Quick Insight Q-kind gate.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_phase5.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_session.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_status.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_evaluator.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_status.dart';

import 'narrative_shadow_test_support.dart';

void main() {
  test('Phase5 top-level matches 6E Classical path for open/guidance', () {
    final applicable = launchScenarios().where((s) {
      final kind = (s['expected'] as Map)['question'] as Map;
      final k = kind['kind'] as String;
      final spread = (s['input'] as Map)['spreadType'] as String;
      if (spread != 'single') return true;
      return k == 'open' || k == 'guidance';
    }).toList();
    expect(applicable, isNotEmpty);
    for (final scenario in applicable) {
      final input = Map<String, dynamic>.from(scenario['input'] as Map);
      final session = sessionFromEvidence(scenario);
      final readingId = input['readingId'] as String;
      final lang = input['languageCode'] as String;
      final sixE = NarrativeTarotShadowPhase5.evaluate(
        session: session,
        readingId: readingId,
        languageCode: lang,
      );
      expect(sixE.failure, isNull, reason: '${scenario['id']}');
      final top = SignatureSpreadShadowEvaluator.evaluate(
        input: NarrativeTarotShadowSession.toShadowInput(
          session: session,
          readingId: readingId,
          languageCode: lang,
        ),
      );
      expect(top.ok, isTrue, reason: '${scenario['id']}');
      expect(top.structuralFingerprint, sixE.structuralFingerprint);
      final a = sixE.classicalRequest!;
      final b = top.classicalRequest!;
      expect(a.cards.map((c) => c.canonicalCardId).toList(),
          b.cards.map((c) => c.canonicalCardId).toList());
      expect(a.cards.map((c) => c.ritualCardId).toList(),
          b.cards.map((c) => c.ritualCardId).toList());
      expect(a.cards.map((c) => c.isReversed).toList(),
          b.cards.map((c) => c.isReversed).toList());
      expect(a.spread.spreadId, b.spread.spreadId);
      expect(a.question.kind, b.question.kind);
    }
  });

  test('Quick Insight marketing gate rejects single relationship/decision', () {
    final gated = launchScenarios().where((s) {
      final input = s['input'] as Map;
      if (input['spreadType'] != 'single') return false;
      final kind = ((s['expected'] as Map)['question'] as Map)['kind'];
      return kind == 'relationship' || kind == 'decision';
    }).toList();
    expect(gated, hasLength(2));
    for (final scenario in gated) {
      final input = Map<String, dynamic>.from(scenario['input'] as Map);
      final session = sessionFromEvidence(scenario);
      final top = SignatureSpreadShadowEvaluator.evaluate(
        input: NarrativeTarotShadowSession.toShadowInput(
          session: session,
          readingId: input['readingId'] as String,
          languageCode: input['languageCode'] as String,
        ),
      );
      expect(top.ok, isFalse, reason: '${scenario['id']}');
      expect(
        top.failureCode,
        SignatureShadowFailureCode.unsupportedQuestionKind,
      );
      final sixE = evaluateScenario(scenario);
      expect(sixE.status, NarrativeTarotShadowStatus.pass);
      expect(sixE.isPass, isTrue);
    }
  });
}
