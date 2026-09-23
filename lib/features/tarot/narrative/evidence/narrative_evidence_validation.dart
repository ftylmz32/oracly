/// Fact validation helpers for NarrativeEvidenceBuilder (3D.1D).
library;

import '../../deck/oracly_tarot_bridge.dart';
import '../../deck/oracly_tarot_card.dart';
import '../../deck/oracly_tarot_deck.dart';
import '../../domain/models/tarot_spread.dart';
import '../data/narrative_tarot_profile_catalog.dart';
import '../domain/narrative_card_profile.dart';
import 'narrative_classical_spread_catalog.dart';
import 'narrative_evidence_error.dart';
import 'narrative_evidence_input.dart';
import 'narrative_spread_semantics.dart';

class NarrativeEvidenceValidatedCard {
  const NarrativeEvidenceValidatedCard({
    required this.input,
    required this.deckCard,
    required this.profile,
    required this.position,
  });

  final NarrativeEvidenceCardInput input;
  final OraclyTarotCard deckCard;
  final NarrativeCardProfile profile;
  final SpreadPositionSemantic position;
}

abstract final class NarrativeEvidenceValidation {
  NarrativeEvidenceValidation._();

  static SpreadSemanticDefinition resolveSpread(TarotSpreadType type) {
    return ClassicalSpreadSemantics.byLegacyTypeName(type.name);
  }

  static void requireCardCount(
    NarrativeEvidenceInput input,
    SpreadSemanticDefinition spread,
  ) {
    if (input.cards.length != spread.cardCount ||
        input.cards.length != input.spreadType.cardCount) {
      throw NarrativeEvidenceException(
        NarrativeEvidenceErrorCode.cardCountMismatch,
        message:
            'cards=${input.cards.length} spread=${spread.cardCount} '
            'type=${input.spreadType.cardCount}',
      );
    }
  }

  static List<NarrativeEvidenceValidatedCard> validateCards({
    required NarrativeEvidenceInput input,
    required SpreadSemanticDefinition spread,
  }) {
    final seenCanonical = <String>{};
    final seenPositions = <String>{};
    final byKey = {for (final p in spread.positions) p.positionKey: p};
    final validated = <NarrativeEvidenceValidatedCard>[];

    for (final card in input.cards) {
      if (!seenCanonical.add(card.canonicalCardId)) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.duplicateCardId,
          message: 'duplicate canonical ${card.canonicalCardId}',
        );
      }

      final bridged = OraclyTarotBridge.byRitualId(card.ritualCardId);
      if (bridged == null || bridged.id != card.canonicalCardId) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.ritualCardMismatch,
          message:
              'ritual=${card.ritualCardId} canonical=${card.canonicalCardId}',
        );
      }

      final deckCard = OraclyTarotDeck.byId(card.canonicalCardId);
      if (deckCard == null) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.unknownCanonicalCardId,
          message: card.canonicalCardId,
        );
      }

      final profile = NarrativeTarotProfileCatalog.lookup(card.canonicalCardId);
      if (profile == null) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.profileMissing,
          message: card.canonicalCardId,
        );
      }

      if (!seenPositions.add(card.positionKey)) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.duplicatePositionKey,
          message: card.positionKey,
        );
      }

      final position = byKey[card.positionKey];
      if (position == null) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.unknownPositionKey,
          message: card.positionKey,
        );
      }

      if (card.positionIndex != position.index) {
        throw NarrativeEvidenceException(
          NarrativeEvidenceErrorCode.spreadMismatch,
          message:
              '${card.positionKey} index=${card.positionIndex} '
              'expected=${position.index}',
        );
      }

      validated.add(
        NarrativeEvidenceValidatedCard(
          input: card,
          deckCard: deckCard,
          profile: profile,
          position: position,
        ),
      );
    }

    final expectedKeys = spread.positions.map((p) => p.positionKey).toSet();
    if (seenPositions.length != expectedKeys.length ||
        !seenPositions.containsAll(expectedKeys)) {
      throw const NarrativeEvidenceException(
        NarrativeEvidenceErrorCode.spreadMismatch,
        message: 'position coverage incomplete',
      );
    }

    return validated;
  }
}
