/// Phase 5E — Phase 3 builder + Phase 4 enricher wiring (Classical + Signature).
library;

import '../domain/models/tarot_spread.dart';
import '../narrative/evidence/narrative_evidence_builder.dart';
import '../narrative/evidence/narrative_evidence_error.dart';
import '../narrative/evidence/narrative_evidence_input.dart';
import '../narrative/evidence/narrative_request.dart';
import '../narrative/history/tarot_historical_models.dart';
import '../narrative/history/tarot_narrative_request_enricher.dart';
import 'narrative_evidence_strategy_dispatch.dart';
import 'signature_spread_shadow_input.dart';
import 'signature_spread_shadow_normalized.dart';
import 'signature_spread_shadow_status.dart';

class SignatureSpreadShadowClassicalOutcome {
  const SignatureSpreadShadowClassicalOutcome({
    required this.phase3Status,
    required this.phase4Status,
    this.classicalRequest,
    this.enrichedRequest,
  });

  final SignaturePhase3EvidenceStatus phase3Status;
  final SignaturePhase4HistoryStatus phase4Status;
  final TarotNarrativeRequest? classicalRequest;
  final TarotNarrativeRequest? enrichedRequest;
}

abstract final class SignatureSpreadShadowClassical {
  SignatureSpreadShadowClassical._();

  static bool isClassicalLaunch(TarotSpreadType type) =>
      type == TarotSpreadType.single ||
      type == TarotSpreadType.threeCard ||
      type == TarotSpreadType.fiveCard;

  static bool _isSignatureSpreadId(String spreadId) =>
      spreadId.startsWith('signature.');

  /// Builds Evidence via explicit Classical/Signature strategy dispatch.
  static TarotNarrativeRequest? buildEvidence({
    required SignatureSpreadShadowInput input,
    required String languageCode,
    required List<SignatureSpreadShadowNormalizedCard> cards,
  }) {
    final strategy =
        NarrativeEvidenceStrategyDispatch.forSpread(input.spreadType);
    try {
      return NarrativeEvidenceBuilder.build(
        NarrativeEvidenceInput(
          sessionId: input.sessionId,
          readingId: input.readingId,
          languageCode: languageCode,
          questionRaw: input.questionRaw,
          intentionTopic: input.intentionTopic,
          spreadType: input.spreadType,
          cards: [
            for (final c in cards)
              NarrativeEvidenceCardInput(
                canonicalCardId: c.canonicalCardId,
                ritualCardId: c.ritualCardId,
                isReversed: c.isReversed,
                positionKey: c.positionKey,
                positionIndex: c.positionIndex,
              ),
          ],
        ),
        resolver: strategy.resolver,
        edgeProvider: strategy.edgeProvider,
      );
    } on NarrativeEvidenceException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static SignatureSpreadShadowClassicalOutcome attachHistory({
    required TarotNarrativeRequest base,
    required TarotHistoricalSnapshot? history,
    required String? currentOwnerId,
    required bool privacyBlocked,
    required DateTime? now,
  }) {
    final signature = _isSignatureSpreadId(base.spread.spreadId);
    final phase3 = signature
        ? SignaturePhase3EvidenceStatus.builtSignature
        : SignaturePhase3EvidenceStatus.builtClassical;
    if (history == null) {
      return SignatureSpreadShadowClassicalOutcome(
        phase3Status: phase3,
        phase4Status: SignaturePhase4HistoryStatus.notRequested,
        classicalRequest: base,
      );
    }
    if (now == null) {
      return SignatureSpreadShadowClassicalOutcome(
        phase3Status: phase3,
        phase4Status: SignaturePhase4HistoryStatus.notRequested,
      );
    }
    final enriched = TarotNarrativeRequestEnricher.enrich(
      base: base,
      history: history,
      currentOwnerId: currentOwnerId,
      privacyBlocked: privacyBlocked,
      now: now,
    );
    final phase4 = privacyBlocked
        ? SignaturePhase4HistoryStatus.privacyBlocked
        : (signature
            ? SignaturePhase4HistoryStatus.enrichedSignature
            : SignaturePhase4HistoryStatus.enrichedClassical);
    return SignatureSpreadShadowClassicalOutcome(
      phase3Status: phase3,
      phase4Status: phase4,
      classicalRequest: base,
      enrichedRequest: enriched,
    );
  }
}
