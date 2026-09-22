import 'package:flutter_test/flutter_test.dart';

import '../../../support/narrative_tarot_v2/narrative_tarot_v2_corpus_loader.dart';
import '../../../support/narrative_tarot_v2/narrative_tarot_v2_evaluator.dart';
import '../../../support/narrative_tarot_v2/narrative_tarot_v2_hard_failures.dart';

/// Deterministic hard-failure contract — harness must catch intentional fails.
void main() {
  final corpus = Ntv2CorpusLoader.load();

  test('hard-failure taxonomy is stable', () {
    expect(Ntv2HardFailure.all.length, 15);
    expect(Ntv2HardFailure.all, contains(Ntv2HardFailure.fabricatedRecurrence));
    expect(Ntv2HardFailure.all, contains(Ntv2HardFailure.safetyViolation));
  });

  test('every scenario hardFailures match evaluator', () {
    for (final s in corpus.scenarios) {
      final eval = Ntv2ContractEvaluator.evaluate(s);
      expect(
        eval.hardFailures,
        equals(s.expected.hardFailures.toSet()),
        reason: s.id,
      );
    }
  });

  test('corpus contains intentional hard-fail examples', () {
    final seen = <String>{};
    for (final s in corpus.scenarios) {
      seen.addAll(s.expected.hardFailures);
    }
    for (final tag in const [
      Ntv2HardFailure.unknownCardRef,
      Ntv2HardFailure.undrawnCardRef,
      Ntv2HardFailure.unknownPositionRef,
      Ntv2HardFailure.unknownRelationshipEvidence,
      Ntv2HardFailure.unknownMemoryEvidence,
      Ntv2HardFailure.unknownRecurrenceEvidence,
      Ntv2HardFailure.recurrenceCountMismatch,
      Ntv2HardFailure.fabricatedRecurrence,
      Ntv2HardFailure.orientationMismatch,
      Ntv2HardFailure.unsupportedCertainty,
      Ntv2HardFailure.safetyViolation,
      Ntv2HardFailure.languageMismatch,
      Ntv2HardFailure.foreignAccountEvidence,
      Ntv2HardFailure.deletedEvidenceUsed,
    ]) {
      expect(seen, contains(tag), reason: 'missing intentional fail: $tag');
    }
  });

  test('positive scenarios have empty hardFailures', () {
    final positives = corpus.scenarios.where((s) => s.expected.pass).toList();
    expect(positives, isNotEmpty);
    for (final s in positives) {
      expect(s.expected.hardFailures, isEmpty, reason: s.id);
      final eval = Ntv2ContractEvaluator.evaluate(s);
      expect(eval.hardFailures, isEmpty, reason: s.id);
    }
  });
}
