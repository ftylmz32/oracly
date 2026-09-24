/// Phase 6E — offline structured Narrative result assessor (QA only).
library;

import '../../../../core/reading/ai_output_quality_tarot.dart';
import '../../../insights/services/reflective_intelligence.dart';
import '../../interpretation/models/interpretation_result.dart';
import '../evidence/narrative_request.dart';
import '../result/narrative_tarot_quality_validator.dart';
import '../result/narrative_tarot_result_bridge.dart';
import '../result/narrative_tarot_result_error.dart';
import '../result/narrative_tarot_result_parser.dart';
import '../result/narrative_tarot_structured_result.dart';
import 'narrative_tarot_shadow_status.dart';

class NarrativeTarotShadowAssessment {
  const NarrativeTarotShadowAssessment({
    required this.status,
    this.parsed,
    this.bridged,
    this.guarded,
    this.errorKind,
  });

  final NarrativeTarotShadowAssessStatus status;
  final NarrativeTarotStructuredResult? parsed;
  final InterpretationResult? bridged;
  final InterpretationResult? guarded;
  final NarrativeTarotResultErrorKind? errorKind;

  bool get isPass => status == NarrativeTarotShadowAssessStatus.pass;
}

/// Pure offline pipeline: parse → Narrative quality → bridge → guard → AiQuality.
abstract final class NarrativeTarotShadowResultAssessor {
  NarrativeTarotShadowResultAssessor._();

  static NarrativeTarotShadowAssessment assess({
    required TarotNarrativeRequest request,
    required Map<String, dynamic> rawResult,
    required String requestId,
    required String sessionId,
    required DateTime generatedAt,
  }) {
    late final NarrativeTarotStructuredResult parsed;
    try {
      parsed = NarrativeTarotResultParser.parse(rawResult);
    } on NarrativeTarotResultException catch (e) {
      return NarrativeTarotShadowAssessment(
        status: NarrativeTarotShadowAssessStatus.parseFailure,
        errorKind: e.kind,
      );
    }
    try {
      NarrativeTarotQualityValidator.validate(
        request: request,
        result: parsed,
      );
    } on NarrativeTarotResultException catch (e) {
      return NarrativeTarotShadowAssessment(
        status: NarrativeTarotShadowAssessStatus.narrativeEvidenceFailure,
        parsed: parsed,
        errorKind: e.kind,
      );
    }
    final bridged = NarrativeTarotResultBridge.toInterpretationResult(
      request: request,
      result: parsed,
      requestId: requestId,
      sessionId: sessionId,
      generatedAt: generatedAt,
    );
    final guarded = ReflectiveIntelligence.guard(bridged);
    if (!AiOutputQualityTarot.passes(guarded)) {
      return NarrativeTarotShadowAssessment(
        status: NarrativeTarotShadowAssessStatus.aiOutputQualityFailure,
        parsed: parsed,
        bridged: bridged,
        guarded: guarded,
      );
    }
    return NarrativeTarotShadowAssessment(
      status: NarrativeTarotShadowAssessStatus.pass,
      parsed: parsed,
      bridged: bridged,
      guarded: guarded,
    );
  }
}
