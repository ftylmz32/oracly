/// Deterministic NarrativeEvidenceBuilder — closed TarotNarrativeRequest (3D.1D).
library;

import '../../../../core/l10n/app_locale.dart';
import 'narrative_card_evidence.dart';
import 'narrative_evidence_closed_universe.dart';
import 'narrative_evidence_input.dart';
import 'narrative_evidence_validation.dart';
import 'narrative_memory_evidence.dart';
import 'narrative_position_edge_provider.dart';
import 'narrative_profile_slice.dart';
import 'narrative_question_grounding.dart';
import 'narrative_recurrence_evidence.dart';
import 'narrative_relationship_context.dart';
import 'narrative_relationship_evidence.dart';
import 'narrative_relationship_selector.dart';
import 'narrative_request.dart';
import 'narrative_semantic_channel.dart';
import 'narrative_spread_semantic_resolver.dart';

abstract final class NarrativeEvidenceBuilder {
  NarrativeEvidenceBuilder._();

  /// Builds a closed [TarotNarrativeRequest].
  ///
  /// Defaults remain Classical. Pass Signature resolver + edge provider for
  /// Crossroads (Phase 6G) — never coerces Crossroads through Classical.
  static TarotNarrativeRequest build(
    NarrativeEvidenceInput input, {
    NarrativeSpreadSemanticResolver resolver =
        const ClassicalSpreadSemanticResolver(),
    NarrativePositionEdgeProvider edgeProvider =
        const ClassicalPositionEdgeProvider(),
  }) {
    final languageCode = AppLocale.normalize(input.languageCode);
    final spread = NarrativeEvidenceValidation.resolveSpread(
      input.spreadType,
      resolver: resolver,
    );
    NarrativeEvidenceValidation.requireCardCount(input, spread);
    final validated = NarrativeEvidenceValidation.validateCards(
      input: input,
      spread: spread,
    );

    final question = NarrativeQuestionGrounding.from(
      rawQuestion: input.questionRaw,
      topic: input.intentionTopic,
    );

    final byPositionKey = {for (final v in validated) v.input.positionKey: v};
    final ordered = <NarrativeEvidenceValidatedCard>[];
    for (final index in spread.interpretationOrder) {
      final position = spread.positions.firstWhere((p) => p.index == index);
      ordered.add(byPositionKey[position.positionKey]!);
    }

    final cards = <TarotNarrativeCardEvidence>[];
    final contexts = <NarrativeRelationshipCardContext>[];
    for (final v in ordered) {
      final slice = TarotNarrativeProfileSlice.fromProfile(
        v.profile,
        isReversed: v.input.isReversed,
        questionKind: question.kind,
      );
      final channel = NarrativeSemanticChannel.from(
        keywordIds: slice.keywordIds,
        symbolTags: slice.symbolTags,
      );
      cards.add(
        TarotNarrativeCardEvidence(
          canonicalCardId: v.input.canonicalCardId,
          ritualCardId: v.input.ritualCardId,
          isReversed: v.input.isReversed,
          positionKey: v.input.positionKey,
          positionIndex: v.input.positionIndex,
          displayName: v.deckCard.name.of(languageCode),
          profileSlice: slice,
          imageAsset: v.deckCard.visualAsset,
        ),
      );
      contexts.add(
        NarrativeRelationshipCardContext(
          canonicalCardId: v.deckCard.id,
          positionKey: v.input.positionKey,
          positionIndex: v.input.positionIndex,
          isReversed: v.input.isReversed,
          suit: v.deckCard.suit,
          number: v.deckCard.number,
          keywordIds: slice.keywordIds,
          semanticChannel: channel,
          transforms: slice.transforms,
          relatedIds: v.deckCard.relationshipWithOtherCards.relatedIds,
        ),
      );
    }

    final relationships = NarrativeRelationshipSelector.select(
      cards: contexts,
      spread: spread,
      questionKind: question.kind,
      maxRelationships: RequestBounds.defaults.maxRelationships,
      edgeProvider: edgeProvider,
    );

    NarrativeEvidenceClosedUniverse.assertRelationships(
      cards: cards,
      relationships: relationships,
      spread: spread,
    );

    return TarotNarrativeRequest(
      narrativeTarotVersion: TarotNarrativeRequest.currentNarrativeVersion,
      languageCode: languageCode,
      sessionId: input.sessionId,
      readingId: input.readingId,
      question: question,
      spread: spread,
      cards: List<TarotNarrativeCardEvidence>.unmodifiable(cards),
      relationships: List<TarotNarrativeRelationshipEvidence>.unmodifiable(
        relationships,
      ),
      memory: TarotNarrativeMemoryEvidence.empty,
      recurringCards: List<TarotRecurringCardEvidence>.unmodifiable(
        const <TarotRecurringCardEvidence>[],
      ),
      recurringThemes: List<TarotRecurringThemeEvidence>.unmodifiable(
        const <TarotRecurringThemeEvidence>[],
      ),
      bounds: RequestBounds.defaults,
    );
  }
}
