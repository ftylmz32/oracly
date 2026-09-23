/// Phase 5E — position / bridge / card-count validation for shadow input.
library;

import '../deck/oracly_tarot_bridge.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_shadow_input.dart';
import 'signature_spread_shadow_normalized.dart';
import 'signature_spread_shadow_status.dart';

class SignatureSpreadShadowNormalizeOutcome {
  const SignatureSpreadShadowNormalizeOutcome.ok(
    this.cards,
  ) : failure = null;

  const SignatureSpreadShadowNormalizeOutcome.fail(this.failure) : cards = null;

  final List<SignatureSpreadShadowNormalizedCard>? cards;
  final SignatureShadowFailureCode? failure;

  bool get ok => failure == null && cards != null;
}

abstract final class SignatureSpreadShadowValidation {
  SignatureSpreadShadowValidation._();

  static SignatureSpreadShadowNormalizeOutcome normalizeCards({
    required SignatureSpreadDefinition definition,
    required List<SignatureSpreadShadowCard> cards,
  }) {
    if (cards.length != definition.cardCount) {
      return const SignatureSpreadShadowNormalizeOutcome.fail(
        SignatureShadowFailureCode.cardCountMismatch,
      );
    }

    final byIndex = <int, SignatureSpreadShadowCard>{};
    for (final card in cards) {
      if (card.positionIndex < 0) {
        return const SignatureSpreadShadowNormalizeOutcome.fail(
          SignatureShadowFailureCode.negativePositionIndex,
        );
      }
      if (card.positionIndex >= definition.cardCount) {
        return const SignatureSpreadShadowNormalizeOutcome.fail(
          SignatureShadowFailureCode.outOfRangePositionIndex,
        );
      }
      if (byIndex.containsKey(card.positionIndex)) {
        return const SignatureSpreadShadowNormalizeOutcome.fail(
          SignatureShadowFailureCode.duplicatePositionIndex,
        );
      }
      byIndex[card.positionIndex] = card;
    }

    for (var i = 0; i < definition.cardCount; i++) {
      if (!byIndex.containsKey(i)) {
        return const SignatureSpreadShadowNormalizeOutcome.fail(
          SignatureShadowFailureCode.missingPositionIndex,
        );
      }
    }

    final positionByIndex = {
      for (final p in definition.positions) p.index: p,
    };
    final normalized = <SignatureSpreadShadowNormalizedCard>[];
    for (final index in definition.interpretationOrder) {
      final raw = byIndex[index]!;
      final slot = positionByIndex[index]!;
      final stored = raw.positionKey?.trim() ?? '';
      final key = stored.isEmpty ? slot.positionKey : stored;
      if (stored.isNotEmpty && stored != slot.positionKey) {
        return const SignatureSpreadShadowNormalizeOutcome.fail(
          SignatureShadowFailureCode.positionKeyMismatch,
        );
      }
      final bridged = OraclyTarotBridge.byRitualId(raw.ritualCardId);
      if (bridged == null) {
        return const SignatureSpreadShadowNormalizeOutcome.fail(
          SignatureShadowFailureCode.invalidRitualCardId,
        );
      }
      normalized.add(
        SignatureSpreadShadowNormalizedCard(
          ritualCardId: raw.ritualCardId,
          canonicalCardId: bridged.id,
          isReversed: raw.isReversed,
          positionIndex: index,
          positionKey: key,
          role: slot.role,
        ),
      );
    }
    return SignatureSpreadShadowNormalizeOutcome.ok(normalized);
  }
}
