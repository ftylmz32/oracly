/// Phase 5 — immutable SignatureSpreadDefinition domain model.
library;

import '../narrative/evidence/narrative_question_grounding.dart';
import 'signature_spread_enums.dart';
import 'signature_spread_position.dart';

class SignatureSpreadDefinition {
  SignatureSpreadDefinition({
    required this.spreadId,
    required this.version,
    required this.runtimeEnumName,
    required this.purposeKey,
    required Set<QuestionKind> supportedQuestionKinds,
    required this.primaryQuestionKind,
    required this.displayTitleKey,
    required this.displayBlurbKey,
    required this.cardCount,
    required List<SignatureSpreadPosition> positions,
    required List<int> interpretationOrder,
    required this.dominantArcKey,
    required this.synthesisStrategyKey,
    required this.uncertaintyPolicyKey,
    required this.projectionSpreadId,
    required this.edgeTableId,
    required this.signatureGeometryHook,
    required this.lengthBand,
    required this.offeredInLivePicker,
    required this.premiumOnly,
    required this.allowHistoricalContextOverlap,
    required this.forbidSameSpreadAloneAuth,
    required this.memoryInclusionPosture,
    this.bannerKey,
    this.outcomeSlotKey,
    this.adviceSlotKey,
  }) : supportedQuestionKinds = Set<QuestionKind>.unmodifiable(
         supportedQuestionKinds,
       ),
       positions = List<SignatureSpreadPosition>.unmodifiable(positions),
       interpretationOrder = List<int>.unmodifiable(interpretationOrder);

  final String spreadId;
  final int version;
  final String runtimeEnumName;
  final String purposeKey;
  final Set<QuestionKind> supportedQuestionKinds;
  final QuestionKind primaryQuestionKind;
  final String displayTitleKey;
  final String displayBlurbKey;
  final String? bannerKey;
  final int cardCount;
  final List<SignatureSpreadPosition> positions;
  final List<int> interpretationOrder;
  final String dominantArcKey;
  final String synthesisStrategyKey;
  final String? outcomeSlotKey;
  final String? adviceSlotKey;
  final String uncertaintyPolicyKey;
  final String projectionSpreadId;
  final String edgeTableId;
  final SignatureGeometryHook signatureGeometryHook;
  final SignatureLengthBand lengthBand;
  final bool offeredInLivePicker;
  final bool premiumOnly;
  final bool allowHistoricalContextOverlap;
  final bool forbidSameSpreadAloneAuth;
  final SignatureMemoryInclusionPosture memoryInclusionPosture;
}
