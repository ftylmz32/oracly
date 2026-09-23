/// Deterministic NarrativeEvidenceBuilder — closed TarotNarrativeRequest (3D.1D).
library;

import '../../../../core/l10n/app_locale.dart';
import 'narrative_card_evidence.dart';
import 'narrative_evidence_error.dart';
import 'narrative_evidence_input.dart';
import 'narrative_evidence_validation.dart';
import 'narrative_memory_evidence.dart';
import 'narrative_profile_slice.dart';
import 'narrative_question_grounding.dart';
import 'narrative_recurrence_evidence.dart';
import 'narrative_relationship_context.dart';
import 'narrative_relationship_evidence.dart';
import 'narrative_relationship_selector.dart';
import 'narrative_request.dart';
import 'narrative_semantic_channel.dart';
import 'narrative_spread_semantics.dart';

abstract final class NarrativeEvidenceBuilder {
  NarrativeEvidenceBuilder._();

  static TarotNarrativeRequest build(NarrativeEvidenceInput input) {
    final languageCode = AppLocale.normalize(input.languageCode);
    final spread = NarrativeEvidenceValidation.resolveSpread(input.spreadType);
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
    );

    _assertClosedUniverse(
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

  static void _assertClosedUniverse({
    required List<TarotNarrativeCardEvidence> cards,
    required List<TarotNarrativeRelationshipEvidence> relationships,
    required SpreadSemanticDefinition spread,
  }) {
    final cardIds = cards.map((c) => c.canonicalCardId).toSet();
    final positionKeys = spread.positions.map((p) => p.positionKey).toSet();
    final evidenceIds = <String>{};

    if (relationships.length > RequestBounds.defaults.maxRelationships) {
      throw NarrativeEvidenceException(
        NarrativeEvidenceErrorCode.spreadMismatch,
        message: 'relationship count ${relationships.length}',
      );
    }

    for (final rel in relationships) {
      if (rel.evidenceId.isEmpty || !evidenceIds.add(rel.evidenceId)) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.duplicateEvidenceId,
          message: rel.evidenceId,
        );
      }
      if (!cardIds.contains(rel.leftCardId) ||
          !cardIds.contains(rel.rightCardId) ||
          !positionKeys.contains(rel.leftPositionKey) ||
          !positionKeys.contains(rel.rightPositionKey)) {
        throw const NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.spreadMismatch,
          message: 'relationship outside closed universe',
        );
      }
    }
  }
}
