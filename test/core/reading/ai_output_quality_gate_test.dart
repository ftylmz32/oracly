/// AI output quality gate — safety checks before user-facing render.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading/ai_output_quality_category.dart';
import 'package:oracly_new/core/reading/ai_output_quality_context.dart';
import 'package:oracly_new/core/reading/ai_output_quality_gate.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';

void main() {
  test('rejects deterministic future claims', () {
    final result = AiOutputQualityGate.validate(
      'Kesin 3 hafta içinde haber alacaksın.',
      kind: AiOutputQualityKind.tarot,
    );
    expect(result.isAcceptable, isFalse);
    expect(result.category, AiOutputQualityCategory.deterministicFuture);
  });

  test('rejects unsupported coffee certainty without visual evidence', () {
    final result = AiOutputQualityGate.validate(
      'Fincanda kesin kuş var.',
      kind: AiOutputQualityKind.coffee,
      context: const AiOutputQualityContext(hasVisualEvidence: false),
    );
    expect(result.isAcceptable, isFalse);
    expect(result.category, AiOutputQualityCategory.unsupportedClaim);
  });

  test('rejects fake memory without evidence', () {
    final result = AiOutputQualityGate.validate(
      'Geçen hafta annen hakkında konuşmuştuk.',
      kind: AiOutputQualityKind.companion,
      context: const AiOutputQualityContext(hasMemoryEvidence: false),
    );
    expect(result.isAcceptable, isFalse);
    expect(result.category, AiOutputQualityCategory.fakeMemory);
  });

  test('polish softens forbidden certainty', () {
    final out = AiOutputQualityGate.polish(
      'Kesinlikle olacak.',
      kind: AiOutputQualityKind.tarot,
    );
    expect(out.toLowerCase(), isNot(contains('kesinlikle olacak')));
  });
}
