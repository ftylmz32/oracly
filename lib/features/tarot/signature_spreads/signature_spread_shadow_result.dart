/// Phase 5E — immutable Signature shadow evaluation result.
library;

import '../narrative/evidence/narrative_question_grounding.dart';
import '../narrative/evidence/narrative_request.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_semantic_projection.dart';
import 'signature_spread_shadow_normalized.dart';
import 'signature_spread_shadow_status.dart';

class SignatureSpreadShadowResult {
  SignatureSpreadShadowResult._({
    required this.ok,
    required this.phase3EvidenceStatus,
    required this.phase4HistoryStatus,
    required this.structuralEdgeGraphAvailable,
    required this.phase3EdgeAwareScoringAvailable,
    this.failureCode,
    this.definition,
    this.projection,
    this.cards,
    this.questionKind,
    this.languageCode,
    this.structuralFingerprint,
    this.classicalRequest,
    this.enrichedRequest,
  });

  factory SignatureSpreadShadowResult.failure({
    required SignatureShadowFailureCode code,
    required SignaturePhase3EvidenceStatus phase3,
    required SignaturePhase4HistoryStatus phase4,
  }) {
    return SignatureSpreadShadowResult._(
      ok: false,
      failureCode: code,
      phase3EvidenceStatus: phase3,
      phase4HistoryStatus: phase4,
      structuralEdgeGraphAvailable: false,
      phase3EdgeAwareScoringAvailable: false,
    );
  }

  factory SignatureSpreadShadowResult.success({
    required SignatureSpreadDefinition definition,
    required SignatureSpreadSemanticProjection projection,
    required List<SignatureSpreadShadowNormalizedCard> cards,
    required QuestionKind questionKind,
    required String languageCode,
    required String structuralFingerprint,
    required SignaturePhase3EvidenceStatus phase3EvidenceStatus,
    required SignaturePhase4HistoryStatus phase4HistoryStatus,
    required bool structuralEdgeGraphAvailable,
    required bool phase3EdgeAwareScoringAvailable,
    TarotNarrativeRequest? classicalRequest,
    TarotNarrativeRequest? enrichedRequest,
  }) {
    return SignatureSpreadShadowResult._(
      ok: true,
      definition: definition,
      projection: projection,
      cards: List.unmodifiable(cards),
      questionKind: questionKind,
      languageCode: languageCode,
      structuralFingerprint: structuralFingerprint,
      phase3EvidenceStatus: phase3EvidenceStatus,
      phase4HistoryStatus: phase4HistoryStatus,
      classicalRequest: classicalRequest,
      enrichedRequest: enrichedRequest,
      structuralEdgeGraphAvailable: structuralEdgeGraphAvailable,
      phase3EdgeAwareScoringAvailable: phase3EdgeAwareScoringAvailable,
    );
  }

  final bool ok;
  final SignatureShadowFailureCode? failureCode;
  final SignatureSpreadDefinition? definition;
  final SignatureSpreadSemanticProjection? projection;
  final List<SignatureSpreadShadowNormalizedCard>? cards;
  final QuestionKind? questionKind;
  final String? languageCode;
  final String? structuralFingerprint;
  final SignaturePhase3EvidenceStatus phase3EvidenceStatus;
  final SignaturePhase4HistoryStatus phase4HistoryStatus;
  final TarotNarrativeRequest? classicalRequest;
  final TarotNarrativeRequest? enrichedRequest;

  /// Phase 5 structural edges available (Crossroads = yes).
  final bool structuralEdgeGraphAvailable;

  /// Phase 3 scorer consumes edges (Crossroads = true after Phase 6G).
  final bool phase3EdgeAwareScoringAvailable;
}
