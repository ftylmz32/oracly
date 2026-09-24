/// Phase 6E — Classical candidate via Phase 5 Classical path (no Signature Q-gate).
library;

import '../../../../core/l10n/app_locale.dart';
import '../../domain/models/reading_session.dart';
import '../../signature_spreads/signature_spread_projector.dart';
import '../../signature_spreads/signature_spread_runtime_bridge.dart';
import '../../signature_spreads/signature_spread_shadow_classical.dart';
import '../../signature_spreads/signature_spread_shadow_fingerprint.dart';
import '../../signature_spreads/signature_spread_shadow_status.dart';
import '../../signature_spreads/signature_spread_shadow_validation.dart';
import '../evidence/narrative_question_grounding.dart';
import '../evidence/narrative_request.dart';
import '../history/tarot_historical_models.dart';
import 'narrative_tarot_shadow_session.dart';
import 'narrative_tarot_shadow_status.dart';

/// Outcome of Classical Phase 5 Classical path (question-kind gate omitted).
class NarrativeTarotShadowPhase5Outcome {
  const NarrativeTarotShadowPhase5Outcome.ok({
    required this.classicalRequest,
    required this.enrichedRequest,
    required this.structuralFingerprint,
    required this.phase4Status,
  }) : failure = null;

  const NarrativeTarotShadowPhase5Outcome.fail(this.failure)
      : classicalRequest = null,
        enrichedRequest = null,
        structuralFingerprint = null,
        phase4Status = SignaturePhase4HistoryStatus.notRequested;

  final NarrativeTarotShadowStatus? failure;
  final TarotNarrativeRequest? classicalRequest;
  final TarotNarrativeRequest? enrichedRequest;
  final String? structuralFingerprint;
  final SignaturePhase4HistoryStatus phase4Status;
}

/// Reuses Phase 5 Classical shadow pieces without Signature product Q-kind gate.
///
/// Live Classical single accepts relationship/decision; Signature Quick Insight
/// catalog only lists open/guidance. 6E compares live Classical facts, so the
/// marketing gate must not reject valid Phase 3 corpus readings.
abstract final class NarrativeTarotShadowPhase5 {
  NarrativeTarotShadowPhase5._();

  static NarrativeTarotShadowPhase5Outcome evaluate({
    required ReadingSession session,
    required String readingId,
    required String languageCode,
    TarotHistoricalSnapshot? history,
    String? currentOwnerId,
    bool privacyBlocked = false,
    DateTime? now,
  }) {
    final definition = SignatureSpreadRuntimeBridge.definitionFor(
      session.spread,
    );
    if (definition == null) {
      return const NarrativeTarotShadowPhase5Outcome.fail(
        NarrativeTarotShadowStatus.phase5ShadowFailed,
      );
    }
    final language = AppLocale.normalize(languageCode);
    final input = NarrativeTarotShadowSession.toShadowInput(
      session: session,
      readingId: readingId,
      languageCode: language,
    );
    final normalized = SignatureSpreadShadowValidation.normalizeCards(
      definition: definition,
      cards: input.cards,
    );
    if (!normalized.ok) {
      return const NarrativeTarotShadowPhase5Outcome.fail(
        NarrativeTarotShadowStatus.phase5ShadowFailed,
      );
    }
    final grounded = NarrativeQuestionGrounding.from(
      rawQuestion: input.questionRaw,
      topic: input.intentionTopic,
    );
    final projection = SignatureSpreadProjector.project(definition);
    final fingerprint = SignatureSpreadShadowFingerprint.compute(
      definition: definition,
      projection: projection,
      cards: normalized.cards!,
      questionKind: grounded.kind,
    );
    if (history != null && now == null) {
      return const NarrativeTarotShadowPhase5Outcome.fail(
        NarrativeTarotShadowStatus.historyUnavailable,
      );
    }
    final request = SignatureSpreadShadowClassical.buildEvidence(
      input: input,
      languageCode: language,
      cards: normalized.cards!,
    );
    if (request == null) {
      return const NarrativeTarotShadowPhase5Outcome.fail(
        NarrativeTarotShadowStatus.phase3Unavailable,
      );
    }
    final hist = SignatureSpreadShadowClassical.attachHistory(
      base: request,
      history: history,
      currentOwnerId: currentOwnerId,
      privacyBlocked: privacyBlocked,
      now: now,
    );
    return NarrativeTarotShadowPhase5Outcome.ok(
      classicalRequest: hist.classicalRequest!,
      enrichedRequest: hist.enrichedRequest,
      structuralFingerprint: fingerprint,
      phase4Status: hist.phase4Status,
    );
  }
}
