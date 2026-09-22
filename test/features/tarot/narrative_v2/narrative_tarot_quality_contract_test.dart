import 'package:flutter_test/flutter_test.dart';

import '../../../support/narrative_tarot_v2/narrative_tarot_v2_corpus_loader.dart';
import '../../../support/narrative_tarot_v2/narrative_tarot_v2_evaluator.dart';

/// Soft quality flags + pass/fail outcomes for Narrative Tarot V2 corpus.
void main() {
  final corpus = Ntv2CorpusLoader.load();

  test('expected soft flags match evaluator', () {
    for (final s in corpus.scenarios) {
      final eval = Ntv2ContractEvaluator.evaluate(s);
      for (final entry in s.expected.flags.entries) {
        expect(
          eval.flags[entry.key],
          entry.value,
          reason: '${s.id} flag ${entry.key}',
        );
      }
    }
  });

  test('expected pass equals empty hard + release-critical soft', () {
    for (final s in corpus.scenarios) {
      final eval = Ntv2ContractEvaluator.evaluate(s);
      final softFail =
          eval.flags['allCardsAccountedFor'] == false ||
          eval.flags['legacySectionDependence'] == true ||
          eval.flags['genericityDetected'] == true ||
          eval.flags['sycophancyDetected'] == true ||
          eval.flags['repetitiveCardEssayDetected'] == true ||
          eval.flags['questionGrounded'] == false ||
          eval.flags['referentialIntegrityOk'] == false;
      final pass = eval.hardFailures.isEmpty && !softFail;
      expect(pass, s.expected.pass, reason: s.id);
    }
  });

  test('harness contains soft-quality intentional fails', () {
    bool hasFlag(String key, bool value) => corpus.scenarios.any(
      (s) => !s.expected.pass && s.expected.flags[key] == value,
    );
    expect(hasFlag('genericityDetected', true), isTrue);
    expect(hasFlag('sycophancyDetected', true), isTrue);
    expect(hasFlag('repetitiveCardEssayDetected', true), isTrue);
    expect(hasFlag('legacySectionDependence', true), isTrue);
    expect(hasFlag('allCardsAccountedFor', false), isTrue);
  });

  test('warmth without sycophancy can still pass', () {
    expect(
      corpus.scenarios.any(
        (s) =>
            s.expected.pass && s.expected.flags['sycophancyDetected'] == false,
      ),
      isTrue,
    );
  });
}
