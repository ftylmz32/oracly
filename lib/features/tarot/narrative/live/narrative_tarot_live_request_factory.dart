/// Phase 6F — live Narrative request factory (no shadow imports).
library;

import '../../../../core/l10n/app_locale.dart';
import '../../domain/models/reading_session.dart';
import '../../signature_spreads/signature_spread_runtime_bridge.dart';
import '../../signature_spreads/signature_spread_shadow_classical.dart';
import '../../signature_spreads/signature_spread_shadow_validation.dart';
import '../evidence/narrative_request.dart';
import '../history/tarot_historical_snapshot_loader.dart';
import '../prompt/narrative_tarot_prompt_input.dart';
import '../prompt/narrative_tarot_prompt_serializer.dart';
import '../transport/narrative_tarot_wire_contract.dart';
import 'narrative_tarot_live_session.dart';
import 'narrative_tarot_live_spreads.dart';

class NarrativeTarotLiveBuiltRequest {
  const NarrativeTarotLiveBuiltRequest({
    required this.request,
    required this.promptInput,
    required this.wirePayload,
  });

  final TarotNarrativeRequest request;
  final NarrativeTarotPromptInput promptInput;
  final Map<String, Object?> wirePayload;
}

/// Builds enriched Narrative request + wire payload from a live session.
abstract final class NarrativeTarotLiveRequestFactory {
  NarrativeTarotLiveRequestFactory._();

  static NarrativeTarotLiveBuiltRequest build({
    required ReadingSession session,
    required String languageCode,
    required TarotHistoricalSnapshotLoadResult historyLoad,
    required DateTime now,
  }) {
    if (!NarrativeTarotLiveSpreads.isLiveLaunchCandidate(session.spread)) {
      throw StateError('spread not eligible for Narrative V2 live');
    }
    final fail = NarrativeTarotLiveSession.guard(session);
    if (fail != null) {
      throw StateError('malformed session: $fail');
    }
    final language = AppLocale.normalize(languageCode);
    final readingId = session.id;
    final definition =
        SignatureSpreadRuntimeBridge.definitionFor(session.spread);
    if (definition == null) {
      throw StateError('missing Classical spread definition');
    }
    final input = NarrativeTarotLiveSession.toLiveInput(
      session: session,
      readingId: readingId,
      languageCode: language,
    );
    final normalized = SignatureSpreadShadowValidation.normalizeCards(
      definition: definition,
      cards: input.cards,
    );
    if (!normalized.ok) {
      throw StateError('card normalize failed: ${normalized.failure}');
    }
    final base = SignatureSpreadShadowClassical.buildEvidence(
      input: input,
      languageCode: language,
      cards: normalized.cards!,
    );
    if (base == null) {
      throw StateError('Narrative evidence build failed');
    }
    final hist = SignatureSpreadShadowClassical.attachHistory(
      base: base,
      history: historyLoad.snapshot,
      currentOwnerId: session.userId,
      privacyBlocked: historyLoad.privacyBlocked,
      now: now,
    );
    final request = hist.enrichedRequest ?? hist.classicalRequest;
    if (request == null) {
      throw StateError('Narrative enrichment produced no request');
    }
    final promptInput = NarrativeTarotPromptSerializer.serialize(request);
    final wire = NarrativeTarotWireContract.payloadFor(promptInput);
    return NarrativeTarotLiveBuiltRequest(
      request: request,
      promptInput: promptInput,
      wirePayload: wire,
    );
  }
}
