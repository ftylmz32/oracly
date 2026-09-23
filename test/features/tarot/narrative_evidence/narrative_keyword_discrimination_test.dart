import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/data/narrative_tarot_profile_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/domain/narrative_keyword_ids.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_error.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_keyword_discrimination.dart';

void main() {
  group('NarrativeKeywordDiscrimination', () {
    test('ontology revision / N / map size', () {
      expect(NarrativeKeywordDiscrimination.ontologyRevision, 1);
      expect(NarrativeKeywordDiscrimination.orientationCount, 156);
      expect(NarrativeKeywordDiscrimination.documentFrequency, hasLength(128));
      expect(
        NarrativeKeywordDiscrimination.documentFrequency.keys.toSet(),
        NarrativeKeywordIds.all,
      );
    });

    test('frozen df exact catalog match', () {
      final recomputed = _recomputeDf();
      expect(recomputed.length, 156);
      expect(
        NarrativeKeywordDiscrimination.documentFrequency,
        equals(recomputed.df),
      );
    });

    test('scatter=14 haste=13 sentinels', () {
      expect(
        NarrativeKeywordDiscrimination.df(NarrativeKeywordIds.scatter),
        14,
      );
      expect(NarrativeKeywordDiscrimination.df(NarrativeKeywordIds.haste), 13);
      expect(
        NarrativeKeywordDiscrimination.isHighFrequency(
          NarrativeKeywordIds.scatter,
        ),
        isTrue,
      );
      expect(
        NarrativeKeywordDiscrimination.isHighFrequency(
          NarrativeKeywordIds.haste,
        ),
        isTrue,
      );
    });

    test('HF threshold 8', () {
      expect(NarrativeKeywordDiscrimination.highFrequencyDfThreshold, 8);
      // belonging df=5 < 8
      expect(
        NarrativeKeywordDiscrimination.df(NarrativeKeywordIds.belonging),
        5,
      );
      expect(
        NarrativeKeywordDiscrimination.isHighFrequency(
          NarrativeKeywordIds.belonging,
        ),
        isFalse,
      );
      // display df=8
      expect(NarrativeKeywordDiscrimination.df(NarrativeKeywordIds.display), 8);
      expect(
        NarrativeKeywordDiscrimination.isHighFrequency(
          NarrativeKeywordIds.display,
        ),
        isTrue,
      );
    });

    test('weight formula + monotonicity + clamp', () {
      final weights = <int, double>{};
      for (final e
          in NarrativeKeywordDiscrimination.documentFrequency.entries) {
        final w = NarrativeKeywordDiscrimination.weight(e.key);
        expect(w, greaterThanOrEqualTo(1.0));
        expect(w, lessThanOrEqualTo(6.0));
        final expected = _rawWeight(e.value);
        final clamped = expected < 1.0
            ? 1.0
            : expected > 6.0
            ? 6.0
            : expected;
        expect(w, closeTo(clamped, 1e-12));
        weights.putIfAbsent(e.value, () => w);
        expect(weights[e.value], closeTo(w, 1e-12));
      }

      final dfs = weights.keys.toList()..sort();
      for (var i = 1; i < dfs.length; i++) {
        expect(weights[dfs[i]]!, lessThanOrEqualTo(weights[dfs[i - 1]]!));
      }

      final zeroWeight = NarrativeKeywordDiscrimination.weight(
        NarrativeKeywordIds.listening, // df=0
      );
      final maxDfWeight = NarrativeKeywordDiscrimination.weight(
        NarrativeKeywordIds.scatter, // df=14
      );
      expect(zeroWeight, greaterThan(maxDfWeight));
    });

    test('unknown id throws', () {
      expect(
        () => NarrativeKeywordDiscrimination.weight('notARealKeyword'),
        throwsA(
          isA<NarrativeEvidenceException>().having(
            (e) => e.code,
            'code',
            NarrativeEvidenceErrorCode.invalidOntologyId,
          ),
        ),
      );
    });
  });
}

double _rawWeight(int df) => math.log((156 + 1) / (df + 1)) + 1.0;

({int length, Map<String, int> df}) _recomputeDf() {
  final df = {for (final id in NarrativeKeywordIds.all) id: 0};
  var n = 0;
  for (final p in NarrativeTarotProfileCatalog.all) {
    for (final ori in [p.upright, p.reversed]) {
      n++;
      for (final id in ori.keywordIds.toSet()) {
        df[id] = df[id]! + 1;
      }
    }
  }
  return (length: n, df: df);
}
