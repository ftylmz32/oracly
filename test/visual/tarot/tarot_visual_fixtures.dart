/// Phase 7A/7G — AiReadingContent fixtures for visual baselines (test-only).
library;

import 'package:flutter/material.dart';
import 'package:oracly_new/features/tarot/art/major_arcana_art.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';

/// Deterministic major-arcana faces using shipped `.webp` assets.
List<String> tarotVisualFaceAssets(int count) {
  return [
    for (var i = 0; i < count; i++)
      MajorArcanaArt.assetFor(
        CardRevealSpread.forIndex(i % CardRevealSpread.cards.length).card.id,
      ),
  ];
}

TarotCard _faceCard(int catalogueIndex) {
  final base =
      CardRevealSpread.forIndex(catalogueIndex % CardRevealSpread.cards.length);
  final id = base.card.id.clamp(0, 21);
  return TarotCard(
    id: id,
    name: base.card.name,
    image: MajorArcanaArt.assetFor(id),
    arcana: base.card.arcana,
    suit: base.card.suit,
    number: base.card.number,
    summary: base.card.summary,
    meaning: base.card.meaning,
    reversedMeaning: base.card.reversedMeaning,
    keywords: base.card.keywords,
    element: base.card.element,
  );
}

/// Deterministic major-arcana faces from the real catalogue (not `star.png`).
List<TarotDrawnCard> tarotVisualDrawn(int count) {
  return [
    for (var i = 0; i < count; i++)
      TarotDrawnCard(
        card: _faceCard(i),
        positionIndex: i,
        isReversed: i.isOdd,
        positionLabel: 'P$i',
        positionKey: 'p$i',
      ),
  ];
}

RevealCardData tarotVisualReveal(int index, {bool reversed = false}) {
  final base = CardRevealSpread.forIndex(index % CardRevealSpread.cards.length);
  final card = _faceCard(index);
  return RevealCardData(
    card: card,
    displayName: base.displayName,
    subtitle: reversed ? 'Reversed' : 'Upright',
    rarityLabel: base.rarityLabel,
    rarityColor: base.rarityColor,
    imageAsset: card.image,
    positionLabel: 'P$index',
    isReversed: reversed,
  );
}

AiReadingContent tarotVisualNarrativeContent({
  required String spreadLabel,
  required int cardCount,
  String? question,
  String summary =
      'A short opening lead about patience and honest attention.',
  String narrative =
      'The longer primary synthesis holds the main story body with several '
      'calm reflective sentences about the threshold you are standing on now.',
  String closing =
      'One honest step today is more valuable than a dramatic vow.',
  String love = 'Affection asks for presence more than proof.',
  String career = 'Work favors steady craft over rushed display.',
  String direction = 'Keep one quiet promise to yourself today.',
}) {
  final drawn = tarotVisualDrawn(cardCount);
  final primary = drawn.isEmpty ? _faceCard(0) : drawn.first.card;
  return AiReadingContent(
    cardName: spreadLabel,
    tagline: 'Reflection',
    generalMeaning: summary,
    love: love,
    career: career,
    money: '',
    spiritualGuidance: '',
    luckyEnergy: narrative,
    dailyAdvice: direction,
    imageAsset: primary.image,
    rarityColor: const Color(0xFF9B6DFF),
    drawnCards: drawn,
    spreadLabel: spreadLabel,
    closingMessage: closing,
    cardReadings: narrative,
    userQuestion: question,
    readingTheme: 'open',
    interpretationSource: InterpretationSource.ai,
    sourceAttributionKnown: true,
  );
}

AiReadingContent tarotVisualSafetyContent() {
  const reason = 'This topic needs care beyond a reading.';
  return AiReadingContent(
    cardName: 'Safety',
    tagline: '',
    generalMeaning: reason,
    love: '',
    career: '',
    money: '',
    spiritualGuidance: '',
    luckyEnergy: '',
    dailyAdvice: '',
    imageAsset: '',
    rarityColor: const Color(0x00000000),
    drawnCards: const [],
    fullInterpretation: reason,
    deliveryKind: TarotReadingDeliveryKind.safety,
  );
}

AiReadingContent tarotVisualRecoveryContent() {
  final face = _faceCard(0);
  return AiReadingContent(
    cardName: CardRevealSpread.forIndex(0).displayName,
    tagline: '',
    generalMeaning: 'A calm recovery message for a failed interpretation.',
    love: '',
    career: '',
    money: '',
    spiritualGuidance: '',
    luckyEnergy: '',
    dailyAdvice: 'You can try again when ready.',
    imageAsset: face.image,
    rarityColor: const Color(0xFF9B6DFF),
    drawnCards: tarotVisualDrawn(1),
    deliveryKind: TarotReadingDeliveryKind.recovery,
    interpretationSource: InterpretationSource.local,
    sourceAttributionKnown: true,
  );
}
