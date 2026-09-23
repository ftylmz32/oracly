/// Phase 5A — launch catalog entry: Timeline.
library;

import '../narrative/evidence/narrative_question_grounding.dart';
import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_enums.dart';
import 'signature_spread_position.dart';

final kSignatureTimeline = SignatureSpreadDefinition(
  spreadId: 'classical.threeCard',
  version: 1,
  runtimeEnumName: 'threeCard',
  purposeKey: 'tarot.spread.threeCard.purpose',
  supportedQuestionKinds: const {
    QuestionKind.open,
    QuestionKind.guidance,
    QuestionKind.relationship,
    QuestionKind.decision,
  },
  primaryQuestionKind: QuestionKind.open,
  displayTitleKey: 'tarot.spread.threeCard',
  displayBlurbKey: 'tarot.spread.threeCard.blurb',
  bannerKey: 'tarot.spread.threeCard.banner',
  cardCount: 3,
  positions: const [
    SignatureSpreadPosition(
      positionKey: 'past',
      index: 0,
      role: PositionRole.root,
      guidingQuestionKey: 'tarot.spread.threeCard.guide.past',
      displayLabelKey: 'tarot.pos.past',
    ),
    SignatureSpreadPosition(
      positionKey: 'present',
      index: 1,
      role: PositionRole.state,
      guidingQuestionKey: 'tarot.spread.threeCard.guide.present',
      displayLabelKey: 'tarot.pos.present',
    ),
    SignatureSpreadPosition(
      positionKey: 'future',
      index: 2,
      role: PositionRole.direction,
      guidingQuestionKey: 'tarot.spread.threeCard.guide.future',
      displayLabelKey: 'tarot.pos.future',
    ),
  ],
  interpretationOrder: const [0, 1, 2],
  dominantArcKey: 'timeline',
  synthesisStrategyKey: 'timeline',
  uncertaintyPolicyKey: 'uncertainty.reflective_next_step',
  projectionSpreadId: 'classical.threeCard',
  edgeTableId: 'threeCard',
  signatureGeometryHook: SignatureGeometryHook.threeLinear,
  lengthBand: SignatureLengthBand.medium,
  offeredInLivePicker: true,
  premiumOnly: false,
  allowHistoricalContextOverlap: true,
  forbidSameSpreadAloneAuth: true,
  memoryInclusionPosture: SignatureMemoryInclusionPosture.normal,
);
