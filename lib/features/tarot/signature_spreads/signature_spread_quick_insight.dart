/// Phase 5A — launch catalog entry: Quick Insight.
library;

import '../narrative/evidence/narrative_question_grounding.dart';
import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_enums.dart';
import 'signature_spread_position.dart';

final kSignatureQuickInsight = SignatureSpreadDefinition(
  spreadId: 'classical.single',
  version: 1,
  runtimeEnumName: 'single',
  purposeKey: 'tarot.spread.single.purpose',
  supportedQuestionKinds: const {QuestionKind.open, QuestionKind.guidance},
  primaryQuestionKind: QuestionKind.open,
  displayTitleKey: 'tarot.spread.single',
  displayBlurbKey: 'tarot.spread.single.blurb',
  bannerKey: 'tarot.spread.single.banner',
  cardCount: 1,
  positions: const [
    SignatureSpreadPosition(
      positionKey: 'sign',
      index: 0,
      role: PositionRole.signal,
      guidingQuestionKey: 'tarot.spread.single.guide.sign',
      displayLabelKey: 'tarot.pos.sign',
    ),
  ],
  interpretationOrder: const [0],
  dominantArcKey: 'single_signal',
  synthesisStrategyKey: 'single_signal',
  uncertaintyPolicyKey: 'uncertainty.reflective_next_step',
  projectionSpreadId: 'classical.single',
  edgeTableId: 'single',
  signatureGeometryHook: SignatureGeometryHook.single,
  lengthBand: SignatureLengthBand.short,
  offeredInLivePicker: true,
  premiumOnly: false,
  allowHistoricalContextOverlap: true,
  forbidSameSpreadAloneAuth: true,
  memoryInclusionPosture: SignatureMemoryInclusionPosture.normal,
);
