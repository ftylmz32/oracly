import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_error.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_contrasts.dart';

void main() {
  group('NarrativeKeywordContrasts', () {
    test('counts 11 hard + 4 contextual = 15', () {
      expect(NarrativeKeywordContrasts.hardPairCount, 11);
      expect(NarrativeKeywordContrasts.contextualPairCount, 4);
      expect(NarrativeKeywordContrasts.totalPairCount, 15);
    });

    test('hard pairs exact + symmetric', () {
      const hard = [
        (NarrativeKeywordIds.balance, NarrativeKeywordIds.imbalance),
        (NarrativeKeywordIds.stability, NarrativeKeywordIds.instability),
        (NarrativeKeywordIds.belonging, NarrativeKeywordIds.isolation),
        (NarrativeKeywordIds.abundance, NarrativeKeywordIds.scarcity),
        (NarrativeKeywordIds.clarity, NarrativeKeywordIds.confusion),
        (NarrativeKeywordIds.truth, NarrativeKeywordIds.denial),
        (NarrativeKeywordIds.union, NarrativeKeywordIds.isolation),
        (NarrativeKeywordIds.opening, NarrativeKeywordIds.closing),
        (NarrativeKeywordIds.joy, NarrativeKeywordIds.despair),
        (NarrativeKeywordIds.hope, NarrativeKeywordIds.despair),
        (NarrativeKeywordIds.listening, NarrativeKeywordIds.notListening),
      ];
      for (final (a, b) in hard) {
        expect(
          NarrativeKeywordContrasts.between(a, b),
          NarrativeKeywordContrastClass.hard,
        );
        expect(
          NarrativeKeywordContrasts.between(b, a),
          NarrativeKeywordContrastClass.hard,
        );
      }
    });

    test('contextual pairs exact + symmetric', () {
      const contextual = [
        (NarrativeKeywordIds.momentum, NarrativeKeywordIds.haste),
        (NarrativeKeywordIds.nurture, NarrativeKeywordIds.rescue),
        (NarrativeKeywordIds.pause, NarrativeKeywordIds.delay),
        (NarrativeKeywordIds.boundary, NarrativeKeywordIds.coldness),
      ];
      for (final (a, b) in contextual) {
        expect(
          NarrativeKeywordContrasts.between(a, b),
          NarrativeKeywordContrastClass.contextual,
        );
        expect(
          NarrativeKeywordContrasts.between(b, a),
          NarrativeKeywordContrastClass.contextual,
        );
      }
    });

    test('explicit non-contrasts', () {
      expect(
        NarrativeKeywordContrasts.between(
          NarrativeKeywordIds.momentum,
          NarrativeKeywordIds.direction,
        ),
        isNull,
      );
      expect(
        NarrativeKeywordContrasts.between(
          NarrativeKeywordIds.haste,
          NarrativeKeywordIds.scatter,
        ),
        isNull,
      );
      expect(
        NarrativeKeywordContrasts.between(
          NarrativeKeywordIds.control,
          NarrativeKeywordIds.rigidity,
        ),
        isNull,
      );
    });

    test('unknown id throws', () {
      expect(
        () => NarrativeKeywordContrasts.between(
          'notARealKeyword',
          NarrativeKeywordIds.hope,
        ),
        throwsA(
          isA<NarrativeEvidenceException>().having(
            (e) => e.code,
            'code',
            NarrativeEvidenceErrorCode.invalidOntologyId,
          ),
        ),
      );
    });

    test('self-pair is null', () {
      expect(
        NarrativeKeywordContrasts.between(
          NarrativeKeywordIds.balance,
          NarrativeKeywordIds.balance,
        ),
        isNull,
      );
    });
  });
}
