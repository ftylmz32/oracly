/// Phase 6E — offline structured result assessor corpus + mutation stages.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_result_assessor.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_status.dart';

import '../narrative_result/phase6d_test_support.dart';
import 'narrative_shadow_test_support.dart';

void main() {
  final at = DateTime.utc(2026, 9, 24, 15);

  test('offline structured result corpus 24/24 plumbing PASS', () {
    for (final scenario in launchScenarios()) {
      final shadow = evaluateScenario(scenario);
      expect(shadow.isPass, isTrue, reason: '${scenario['id']}');
      final req = shadow.finalNarrativeRequest!;
      final assessment = NarrativeTarotShadowResultAssessor.assess(
        request: req,
        rawResult: validResultMap(req),
        requestId: 'req_${scenario['id']}',
        sessionId: req.sessionId,
        generatedAt: at,
      );
      expect(assessment.isPass, isTrue, reason: '${scenario['id']}');
      expect(assessment.status, NarrativeTarotShadowAssessStatus.pass);
    }
  });

  test('assessor fails at correct stages for mutations', () {
    final scenario = launchScenarios().firstWhere(
      (s) => s['id'] == 'three_contrast_exemplar_en',
    );
    final req = evaluateScenario(scenario).finalNarrativeRequest!;
    final good = validResultMap(req);

    expect(
      NarrativeTarotShadowResultAssessor.assess(
        request: req,
        rawResult: Map<String, dynamic>.from(good)..remove('summary'),
        requestId: 'r',
        sessionId: 's',
        generatedAt: at,
      ).status,
      NarrativeTarotShadowAssessStatus.parseFailure,
    );

    void expectEvidenceFail(Map<String, dynamic> raw) {
      expect(
        NarrativeTarotShadowResultAssessor.assess(
          request: req,
          rawResult: raw,
          requestId: 'r',
          sessionId: 's',
          generatedAt: at,
        ).status,
        NarrativeTarotShadowAssessStatus.narrativeEvidenceFailure,
      );
    }

    final wrongCard = Map<String, dynamic>.from(good);
    wrongCard['cardReadings'] = [
      {
        'cardId': 'major_21',
        'positionKey': req.cards.first.positionKey,
        'text': longProse(60),
      },
      ...((good['cardReadings'] as List).skip(1)),
    ];
    expectEvidenceFail(wrongCard);

    final fakeRel = Map<String, dynamic>.from(good);
    fakeRel['relationshipInsights'] = [
      {
        'leftCardId': req.cards.first.canonicalCardId,
        'rightCardId': req.cards.last.canonicalCardId,
        'kind': 'conflict',
        'text': longProse(50),
      },
    ];
    expectEvidenceFail(fakeRel);

    final fakeRec = Map<String, dynamic>.from(good);
    fakeRec['recurringCardInsights'] = [
      {'cardId': 'major_21', 'text': longProse(50)},
    ];
    expectEvidenceFail(fakeRec);

    final fakeMem = Map<String, dynamic>.from(good);
    fakeMem['memoryInsights'] = [
      {'memoryIndex': 0, 'text': longProse(50)},
    ];
    expectEvidenceFail(fakeMem);

    final leak = Map<String, dynamic>.from(good);
    leak['summary'] = '${longProse(80)} ${req.sessionId} rel_99';
    expectEvidenceFail(leak);
  });
}
