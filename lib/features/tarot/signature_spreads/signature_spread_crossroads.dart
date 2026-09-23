/// Phase 5A — launch catalog entry: Crossroads (picker-unreachable).
library;

import '../narrative/evidence/narrative_question_grounding.dart';
import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_enums.dart';
import 'signature_spread_position.dart';

/// Crossroads `runtimeEnumName` is inert metadata until Phase 5D.
final kSignatureCrossroads = SignatureSpreadDefinition(
  spreadId: 'signature.crossroads',
  version: 1,
  runtimeEnumName: 'crossroads',
  purposeKey: 'tarot.spread.crossroads.purpose',
  supportedQuestionKinds: const {
    QuestionKind.decision,
    QuestionKind.open,
    QuestionKind.guidance,
  },
  primaryQuestionKind: QuestionKind.decision,
  displayTitleKey: 'tarot.spread.crossroads',
  displayBlurbKey: 'tarot.spread.crossroads.blurb',
  bannerKey: 'tarot.spread.crossroads.banner',
  cardCount: 5,
  positions: const [
    SignatureSpreadPosition(
      positionKey: 'option_a',
      index: 0,
      role: PositionRole.direction,
      guidingQuestionKey: 'tarot.spread.crossroads.guide.option_a',
      displayLabelKey: 'tarot.pos.option_a',
    ),
    SignatureSpreadPosition(
      positionKey: 'option_b',
      index: 1,
      role: PositionRole.direction,
      guidingQuestionKey: 'tarot.spread.crossroads.guide.option_b',
      displayLabelKey: 'tarot.pos.option_b',
    ),
    SignatureSpreadPosition(
      positionKey: 'tension',
      index: 2,
      role: PositionRole.challenge,
      guidingQuestionKey: 'tarot.spread.crossroads.guide.tension',
      displayLabelKey: 'tarot.pos.tension',
    ),
    SignatureSpreadPosition(
      positionKey: 'counsel',
      index: 3,
      role: PositionRole.support,
      guidingQuestionKey: 'tarot.spread.crossroads.guide.counsel',
      displayLabelKey: 'tarot.pos.counsel',
    ),
    SignatureSpreadPosition(
      positionKey: 'direction',
      index: 4,
      role: PositionRole.direction,
      guidingQuestionKey: 'tarot.spread.crossroads.guide.direction',
      displayLabelKey: 'tarot.pos.direction',
    ),
  ],
  interpretationOrder: const [0, 1, 2, 3, 4],
  dominantArcKey: 'crossroads',
  synthesisStrategyKey: 'crossroads',
  outcomeSlotKey: 'direction',
  adviceSlotKey: 'counsel',
  uncertaintyPolicyKey: 'uncertainty.reflective_next_step',
  projectionSpreadId: 'signature.crossroads',
  edgeTableId: 'crossroads',
  signatureGeometryHook: SignatureGeometryHook.fiveDecision,
  lengthBand: SignatureLengthBand.deep,
  offeredInLivePicker: false,
  premiumOnly: false,
  allowHistoricalContextOverlap: true,
  forbidSameSpreadAloneAuth: true,
  memoryInclusionPosture: SignatureMemoryInclusionPosture.normal,
);
