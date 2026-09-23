/// Phase 5A — launch catalog entry: Deep Field.
library;

import '../narrative/evidence/narrative_question_grounding.dart';
import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_enums.dart';
import 'signature_spread_position.dart';

final kSignatureDeepField = SignatureSpreadDefinition(
  spreadId: 'classical.fiveCard',
  version: 1,
  runtimeEnumName: 'fiveCard',
  purposeKey: 'tarot.spread.fiveCard.purpose',
  supportedQuestionKinds: const {
    QuestionKind.open,
    QuestionKind.guidance,
    QuestionKind.relationship,
    QuestionKind.decision,
  },
  primaryQuestionKind: QuestionKind.open,
  displayTitleKey: 'tarot.spread.fiveCard',
  displayBlurbKey: 'tarot.spread.fiveCard.blurb',
  bannerKey: 'tarot.spread.fiveCard.banner',
  cardCount: 5,
  positions: const [
    SignatureSpreadPosition(
      positionKey: 'situation',
      index: 0,
      role: PositionRole.context,
      guidingQuestionKey: 'tarot.spread.fiveCard.guide.situation',
      displayLabelKey: 'tarot.pos.situation',
    ),
    SignatureSpreadPosition(
      positionKey: 'hidden_influence',
      index: 1,
      role: PositionRole.hiddenInfluence,
      guidingQuestionKey: 'tarot.spread.fiveCard.guide.hidden_influence',
      displayLabelKey: 'tarot.pos.hidden_influence',
    ),
    SignatureSpreadPosition(
      positionKey: 'challenge',
      index: 2,
      role: PositionRole.challenge,
      guidingQuestionKey: 'tarot.spread.fiveCard.guide.challenge',
      displayLabelKey: 'tarot.pos.challenge',
    ),
    SignatureSpreadPosition(
      positionKey: 'strength',
      index: 3,
      role: PositionRole.support,
      guidingQuestionKey: 'tarot.spread.fiveCard.guide.strength',
      displayLabelKey: 'tarot.pos.strength',
    ),
    SignatureSpreadPosition(
      positionKey: 'direction',
      index: 4,
      role: PositionRole.direction,
      guidingQuestionKey: 'tarot.spread.fiveCard.guide.direction',
      displayLabelKey: 'tarot.pos.direction',
    ),
  ],
  interpretationOrder: const [0, 1, 2, 3, 4],
  dominantArcKey: 'field',
  synthesisStrategyKey: 'field',
  outcomeSlotKey: 'direction',
  adviceSlotKey: 'strength',
  uncertaintyPolicyKey: 'uncertainty.reflective_next_step',
  projectionSpreadId: 'classical.fiveCard',
  edgeTableId: 'fiveCard',
  signatureGeometryHook: SignatureGeometryHook.fiveLinear,
  lengthBand: SignatureLengthBand.deep,
  offeredInLivePicker: true,
  premiumOnly: false,
  allowHistoricalContextOverlap: true,
  forbidSameSpreadAloneAuth: true,
  memoryInclusionPosture: SignatureMemoryInclusionPosture.normal,
);
