/// Shared builders for Phase 5A signature spread tests.
library;

import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_definition.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_enums.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_position.dart';

SignatureSpreadDefinition sampleDefinition({
  String spreadId = 'test.spread',
  int version = 1,
  String runtimeEnumName = 'test',
  Set<QuestionKind> supported = const {QuestionKind.open},
  QuestionKind primary = QuestionKind.open,
  int cardCount = 1,
  List<SignatureSpreadPosition>? positions,
  List<int>? interpretationOrder,
  String? outcomeSlotKey,
  String? adviceSlotKey,
  bool forbidSameSpreadAloneAuth = true,
}) {
  final slots =
      positions ??
      const [
        SignatureSpreadPosition(
          positionKey: 'sign',
          index: 0,
          role: PositionRole.signal,
          guidingQuestionKey: 'g',
          displayLabelKey: 'l',
        ),
      ];
  return SignatureSpreadDefinition(
    spreadId: spreadId,
    version: version,
    runtimeEnumName: runtimeEnumName,
    purposeKey: 'p',
    supportedQuestionKinds: supported,
    primaryQuestionKind: primary,
    displayTitleKey: 't',
    displayBlurbKey: 'b',
    cardCount: cardCount,
    positions: slots,
    interpretationOrder: interpretationOrder ?? [for (final p in slots) p.index],
    dominantArcKey: 'arc',
    synthesisStrategyKey: 'syn',
    uncertaintyPolicyKey: 'uncertainty.reflective_next_step',
    projectionSpreadId: spreadId,
    edgeTableId: runtimeEnumName,
    signatureGeometryHook: SignatureGeometryHook.single,
    lengthBand: SignatureLengthBand.short,
    offeredInLivePicker: false,
    premiumOnly: false,
    allowHistoricalContextOverlap: true,
    forbidSameSpreadAloneAuth: forbidSameSpreadAloneAuth,
    memoryInclusionPosture: SignatureMemoryInclusionPosture.normal,
    outcomeSlotKey: outcomeSlotKey,
    adviceSlotKey: adviceSlotKey,
  );
}
