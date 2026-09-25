/// Phase 5E — pure Signature shadow evaluator (no side effects).
library;

import '../../../core/l10n/app_locale.dart';
import '../narrative/evidence/narrative_question_grounding.dart';
import '../narrative/history/tarot_historical_models.dart';
import 'signature_spread_projector.dart';
import 'signature_spread_runtime_bridge.dart';
import 'signature_spread_shadow_classical.dart';
import 'signature_spread_shadow_fingerprint.dart';
import 'signature_spread_shadow_input.dart';
import 'signature_spread_shadow_result.dart';
import 'signature_spread_shadow_status.dart';
import 'signature_spread_shadow_validation.dart';

abstract final class SignatureSpreadShadowEvaluator {
  SignatureSpreadShadowEvaluator._();

  /// Pure shadow evaluation. Never persists, networks, or reads the clock.
  static SignatureSpreadShadowResult evaluate({
    required SignatureSpreadShadowInput input,
    TarotHistoricalSnapshot? history,
    String? currentOwnerId,
    bool privacyBlocked = false,
    DateTime? now,
  }) {
    if (input.sessionId.trim().isEmpty) {
      return _fail(SignatureShadowFailureCode.emptySessionId);
    }
    if (input.readingId.trim().isEmpty) {
      return _fail(SignatureShadowFailureCode.emptyReadingId);
    }

    final definition = SignatureSpreadRuntimeBridge.definitionFor(
      input.spreadType,
    );
    if (definition == null) {
      return _fail(SignatureShadowFailureCode.unsupportedRuntimeSpread);
    }

    final language = AppLocale.normalize(input.languageCode);
    final normalized = SignatureSpreadShadowValidation.normalizeCards(
      definition: definition,
      cards: input.cards,
    );
    if (!normalized.ok) {
      return _fail(normalized.failure!);
    }
    final cards = normalized.cards!;

    final grounded = NarrativeQuestionGrounding.from(
      rawQuestion: input.questionRaw,
      topic: input.intentionTopic,
    );
    if (!definition.supportedQuestionKinds.contains(grounded.kind)) {
      return _fail(SignatureShadowFailureCode.unsupportedQuestionKind);
    }

    final projection = SignatureSpreadProjector.project(definition);
    final fingerprint = SignatureSpreadShadowFingerprint.compute(
      definition: definition,
      projection: projection,
      cards: cards,
      questionKind: grounded.kind,
    );

    if (history != null && now == null) {
      return _fail(SignatureShadowFailureCode.missingNowForHistory);
    }

    // Phase 6G: Crossroads uses Signature strategy; Classical uses Classical.
    final request = SignatureSpreadShadowClassical.buildEvidence(
      input: input,
      languageCode: language,
      cards: cards,
    );
    if (request == null) {
      return SignatureSpreadShadowResult.failure(
        code: SignatureShadowFailureCode.evidenceBuildFailed,
        phase3: SignaturePhase3EvidenceStatus.invalidInput,
        phase4: SignaturePhase4HistoryStatus.notRequested,
      );
    }

    final hist = SignatureSpreadShadowClassical.attachHistory(
      base: request,
      history: history,
      currentOwnerId: currentOwnerId,
      privacyBlocked: privacyBlocked,
      now: now,
    );
    return SignatureSpreadShadowResult.success(
      definition: definition,
      projection: projection,
      cards: cards,
      questionKind: grounded.kind,
      languageCode: language,
      structuralFingerprint: fingerprint,
      phase3EvidenceStatus: hist.phase3Status,
      phase4HistoryStatus: hist.phase4Status,
      classicalRequest: hist.classicalRequest,
      enrichedRequest: hist.enrichedRequest,
      structuralEdgeGraphAvailable: projection.edges.isNotEmpty,
      phase3EdgeAwareScoringAvailable: true,
    );
  }

  static SignatureSpreadShadowResult _fail(SignatureShadowFailureCode code) {
    return SignatureSpreadShadowResult.failure(
      code: code,
      phase3: SignaturePhase3EvidenceStatus.invalidInput,
      phase4: SignaturePhase4HistoryStatus.notRequested,
    );
  }
}
