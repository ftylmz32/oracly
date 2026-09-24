/// Phase 6E — candidate build + serialize after safety clear (pure).
library;

import 'package:flutter/foundation.dart';

import '../../domain/models/reading_session.dart';
import '../../domain/models/tarot_spread.dart';
import '../../interpretation/models/reading_context.dart';
import '../../signature_spreads/signature_spread_shadow_status.dart';
import '../evidence/narrative_request.dart';
import '../history/tarot_historical_models.dart';
import '../prompt/narrative_tarot_cache_identity.dart';
import '../prompt/narrative_tarot_prompt_serializer.dart';
import '../transport/narrative_tarot_wire_contract.dart';
import 'narrative_tarot_shadow_parity.dart';
import 'narrative_tarot_shadow_phase5.dart';
import 'narrative_tarot_shadow_result.dart';
import 'narrative_tarot_shadow_status.dart';

abstract final class NarrativeTarotShadowPipeline {
  NarrativeTarotShadowPipeline._();

  /// Maps only known frozen-contract ArgumentError → serializationFailed.
  /// Unexpected errors must propagate (fail loud).
  @visibleForTesting
  static NarrativeTarotShadowResult mapCaughtError(
    Object error,
    ReadingContext legacy,
  ) {
    if (error is ArgumentError) {
      return NarrativeTarotShadowResult.terminal(
        status: NarrativeTarotShadowStatus.serializationFailed,
        legacyContext: legacy,
      );
    }
    throw error;
  }

  static NarrativeTarotShadowResult build({
    required ReadingSession session,
    required String readingId,
    required String languageCode,
    required TarotHistoricalSnapshot? history,
    required String? currentOwnerId,
    required bool privacyBlocked,
    required DateTime? now,
  }) {
    final legacy = ReadingContext.fromSession(session, language: languageCode);
    final phase5 = NarrativeTarotShadowPhase5.evaluate(
      session: session,
      readingId: readingId,
      languageCode: languageCode,
      history: history,
      currentOwnerId: currentOwnerId,
      privacyBlocked: privacyBlocked,
      now: now,
    );
    if (phase5.failure != null) {
      return NarrativeTarotShadowResult.terminal(
        status: phase5.failure!,
        legacyContext: legacy,
      );
    }
    final base = phase5.classicalRequest!;
    final finalReq = selectFinal(
      base: base,
      enriched: phase5.enrichedRequest,
      historyRequested: history != null,
      phase4: phase5.phase4Status,
    );
    if (finalReq == null) {
      return NarrativeTarotShadowResult.terminal(
        status: NarrativeTarotShadowStatus.historyUnavailable,
        legacyContext: legacy,
      );
    }
    return finish(
      legacy: legacy,
      base: base,
      finalReq: finalReq,
      readingId: readingId,
      sessionSpread: session.spread,
      fingerprint: phase5.structuralFingerprint!,
    );
  }

  static TarotNarrativeRequest? selectFinal({
    required TarotNarrativeRequest base,
    required TarotNarrativeRequest? enriched,
    required bool historyRequested,
    required SignaturePhase4HistoryStatus phase4,
  }) {
    if (!historyRequested) return base;
    if (enriched == null) return null;
    if (phase4 == SignaturePhase4HistoryStatus.notRequested) return null;
    return enriched;
  }

  static NarrativeTarotShadowResult finish({
    required ReadingContext legacy,
    required TarotNarrativeRequest base,
    required TarotNarrativeRequest finalReq,
    required String readingId,
    required TarotSpreadType sessionSpread,
    required String fingerprint,
  }) {
    final parity = NarrativeTarotShadowParity.compare(
      legacy: legacy,
      narrative: finalReq,
      readingId: readingId,
      sessionSpread: sessionSpread,
    );
    if (!parity.overallPass) {
      return NarrativeTarotShadowResult.terminal(
        status: NarrativeTarotShadowStatus.parityMismatch,
        legacyContext: legacy,
      );
    }
    try {
      final prompt = NarrativeTarotPromptSerializer.serialize(finalReq);
      return NarrativeTarotShadowResult.ok(
        legacyContext: legacy,
        baseNarrativeRequest: base,
        finalNarrativeRequest: finalReq,
        promptInput: prompt,
        wirePayload: NarrativeTarotWireContract.payloadFor(prompt),
        legacyCacheKey: legacy.cacheKey,
        narrativeCacheKey: NarrativeTarotCacheIdentity.keyFor(finalReq),
        parity: parity,
        structuralFingerprint: fingerprint,
      );
    } on ArgumentError catch (e) {
      return mapCaughtError(e, legacy);
    }
  }
}
