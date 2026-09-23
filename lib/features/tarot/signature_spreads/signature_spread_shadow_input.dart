/// Phase 5E — pure shadow reading input (no storage / UI / network).
library;

import '../domain/models/tarot_spread.dart';

/// Caller-supplied drawn card facts. Canonical id is derived via bridge.
class SignatureSpreadShadowCard {
  const SignatureSpreadShadowCard({
    required this.ritualCardId,
    required this.isReversed,
    required this.positionIndex,
    this.positionKey,
  });

  final int ritualCardId;
  final bool isReversed;
  final int positionIndex;

  /// Optional stored key. Empty/absent → reconstruct. Non-empty mismatch → fail.
  final String? positionKey;
}

/// One candidate Signature reading for shadow evaluation.
class SignatureSpreadShadowInput {
  SignatureSpreadShadowInput({
    required this.sessionId,
    required this.readingId,
    required this.languageCode,
    required this.spreadType,
    required Iterable<SignatureSpreadShadowCard> cards,
    this.questionRaw,
    this.intentionTopic,
  }) : cards = List<SignatureSpreadShadowCard>.unmodifiable(
         List<SignatureSpreadShadowCard>.from(cards),
       );

  final String sessionId;
  final String readingId;
  final String languageCode;
  final TarotSpreadType spreadType;
  final String? questionRaw;
  final String? intentionTopic;
  final List<SignatureSpreadShadowCard> cards;
}
