/// Phase 5E — classical Phase 3 builder + Phase 4 enricher wiring.
library;

import '../domain/models/tarot_spread.dart';
import '../narrative/evidence/narrative_evidence_builder.dart';
import '../narrative/evidence/narrative_evidence_input.dart';
import '../narrative/evidence/narrative_request.dart';
import '../narrative/history/tarot_historical_models.dart';
import '../narrative/history/tarot_narrative_request_enricher.dart';
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

  static TarotNarrativeRequest? buildEvidence({
    required SignatureSpreadShadowInput input,
    required String languageCode,
    required List<SignatureSpreadShadowNormalizedCard> cards,
  }) {
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
      );
    } catch (_) {
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
    if (history == null) {
      return SignatureSpreadShadowClassicalOutcome(
        phase3Status: SignaturePhase3EvidenceStatus.builtClassical,
        phase4Status: SignaturePhase4HistoryStatus.notRequested,
        classicalRequest: base,
      );
    }
    if (now == null) {
      return const SignatureSpreadShadowClassicalOutcome(
        phase3Status: SignaturePhase3EvidenceStatus.builtClassical,
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
    return SignatureSpreadShadowClassicalOutcome(
      phase3Status: SignaturePhase3EvidenceStatus.builtClassical,
      phase4Status: privacyBlocked
          ? SignaturePhase4HistoryStatus.privacyBlocked
          : SignaturePhase4HistoryStatus.enrichedClassical,
      classicalRequest: base,
      enrichedRequest: enriched,
    );
  }
}
