/// Phase 5A — signature spread validator negative contracts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_position.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_validation.dart';

import 'signature_spread_test_support.dart';

void main() {
  SignatureSpreadViolation firstOf(SignatureSpreadValidationResult r) =>
      r.violations.first;

  group('SignatureSpreadValidation definition negatives', () {
    test('empty spreadId / version 0 / empty runtime / cardCount 0', () {
      expect(
        firstOf(SignatureSpreadValidation.validateDefinition(
          sampleDefinition(spreadId: ' '),
        )),
        SignatureSpreadViolation.emptySpreadId,
      );
      expect(
        firstOf(SignatureSpreadValidation.validateDefinition(
          sampleDefinition(version: 0),
        )),
        SignatureSpreadViolation.invalidVersion,
      );
      expect(
        firstOf(SignatureSpreadValidation.validateDefinition(
          sampleDefinition(runtimeEnumName: ''),
        )),
        SignatureSpreadViolation.emptyRuntimeEnumName,
      );
      expect(
        firstOf(SignatureSpreadValidation.validateDefinition(
          sampleDefinition(cardCount: 0, positions: const [], interpretationOrder: const []),
        )),
        SignatureSpreadViolation.invalidCardCount,
      );
    });

    test('position count / index / key failures', () {
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(cardCount: 2),
        ).violations,
        contains(SignatureSpreadViolation.positionCountMismatch),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(
            cardCount: 2,
            positions: const [
              SignatureSpreadPosition(
                positionKey: 'a',
                index: 0,
                role: PositionRole.signal,
                guidingQuestionKey: 'g',
                displayLabelKey: 'l',
              ),
              SignatureSpreadPosition(
                positionKey: 'b',
                index: 0,
                role: PositionRole.signal,
                guidingQuestionKey: 'g',
                displayLabelKey: 'l',
              ),
            ],
            interpretationOrder: const [0, 0],
          ),
        ).violations,
        contains(SignatureSpreadViolation.duplicatePositionIndex),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(
            cardCount: 2,
            positions: const [
              SignatureSpreadPosition(
                positionKey: 'a',
                index: 0,
                role: PositionRole.signal,
                guidingQuestionKey: 'g',
                displayLabelKey: 'l',
              ),
              SignatureSpreadPosition(
                positionKey: 'b',
                index: 2,
                role: PositionRole.signal,
                guidingQuestionKey: 'g',
                displayLabelKey: 'l',
              ),
            ],
            interpretationOrder: const [0, 2],
          ),
        ).violations,
        contains(SignatureSpreadViolation.nonContiguousPositionIndex),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(
            positions: const [
              SignatureSpreadPosition(
                positionKey: ' ',
                index: 0,
                role: PositionRole.signal,
                guidingQuestionKey: 'g',
                displayLabelKey: 'l',
              ),
            ],
          ),
        ).violations,
        contains(SignatureSpreadViolation.emptyPositionKey),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(
            cardCount: 2,
            positions: const [
              SignatureSpreadPosition(
                positionKey: 'same',
                index: 0,
                role: PositionRole.signal,
                guidingQuestionKey: 'g',
                displayLabelKey: 'l',
              ),
              SignatureSpreadPosition(
                positionKey: 'same',
                index: 1,
                role: PositionRole.signal,
                guidingQuestionKey: 'g',
                displayLabelKey: 'l',
              ),
            ],
            interpretationOrder: const [0, 1],
          ),
        ).violations,
        contains(SignatureSpreadViolation.duplicatePositionKey),
      );
    });

    test('interpretation order / question kinds / slots / recurrence', () {
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(interpretationOrder: const []),
        ).violations,
        contains(SignatureSpreadViolation.badInterpretationOrder),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(
            cardCount: 2,
            positions: const [
              SignatureSpreadPosition(
                positionKey: 'a',
                index: 0,
                role: PositionRole.signal,
                guidingQuestionKey: 'g',
                displayLabelKey: 'l',
              ),
              SignatureSpreadPosition(
                positionKey: 'b',
                index: 1,
                role: PositionRole.signal,
                guidingQuestionKey: 'g',
                displayLabelKey: 'l',
              ),
            ],
            interpretationOrder: const [0, 0],
          ),
        ).violations,
        contains(SignatureSpreadViolation.badInterpretationOrder),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(
            cardCount: 1,
            interpretationOrder: const [3],
          ),
        ).violations,
        contains(SignatureSpreadViolation.badInterpretationOrder),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(supported: {}),
        ).violations,
        contains(SignatureSpreadViolation.emptySupportedQuestionKinds),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(
            supported: const {QuestionKind.open},
            primary: QuestionKind.decision,
          ),
        ).violations,
        contains(SignatureSpreadViolation.primaryKindUnsupported),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(outcomeSlotKey: 'missing'),
        ).violations,
        contains(SignatureSpreadViolation.invalidOutcomeSlot),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(adviceSlotKey: 'missing'),
        ).violations,
        contains(SignatureSpreadViolation.invalidAdviceSlot),
      );
      expect(
        SignatureSpreadValidation.validateDefinition(
          sampleDefinition(forbidSameSpreadAloneAuth: false),
        ).violations,
        contains(SignatureSpreadViolation.sameSpreadRecurrenceAuthViolation),
      );
    });
  });

  group('SignatureSpreadValidation catalog negatives', () {
    test('duplicate id / runtime / wrong order', () {
      final base = SignatureSpreadCatalog.launch;
      expect(
        SignatureSpreadValidation.validateCatalog(
          [base[0], base[0]],
          expectedSpreadIdsInOrder: [base[0].spreadId, base[0].spreadId],
        ).violations,
        contains(SignatureSpreadViolation.duplicateCatalogSpreadId),
      );
      expect(
        SignatureSpreadValidation.validateCatalog(
          [
            sampleDefinition(spreadId: 'a', runtimeEnumName: 'x'),
            sampleDefinition(spreadId: 'b', runtimeEnumName: 'x'),
          ],
          expectedSpreadIdsInOrder: const ['a', 'b'],
        ).violations,
        contains(SignatureSpreadViolation.duplicateCatalogRuntimeName),
      );
      expect(
        SignatureSpreadValidation.validateCatalog(
          [base[1], base[0], base[2], base[3]],
          expectedSpreadIdsInOrder: kSignatureLaunchSpreadIds,
        ).violations,
        contains(SignatureSpreadViolation.invalidCatalogOrder),
      );
    });
  });
}
