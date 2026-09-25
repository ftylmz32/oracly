/// Phase 7A — AiReadingContent fixtures for visual baselines (test-only).
library;

import 'package:flutter/material.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';

List<TarotDrawnCard> tarotVisualDrawn(int count) {
  return [
    for (var i = 0; i < count; i++)
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(i % 78).card,
        positionIndex: i,
        isReversed: i.isOdd,
        positionLabel: 'P$i',
      ),
  ];
}

AiReadingContent tarotVisualNarrativeContent({
  required String spreadLabel,
  required int cardCount,
  String? question,
  String narrative =
      'A quiet threshold opens. The spread holds one coherent story, '
      'not three separate essays. Calm attention is enough.',
  String closing =
      'One honest step today is more valuable than a dramatic vow.',
}) {
  final drawn = tarotVisualDrawn(cardCount);
  return AiReadingContent(
    cardName: spreadLabel,
    tagline: 'Reflection',
    generalMeaning: narrative,
    love: '',
    career: '',
    money: '',
    spiritualGuidance: '',
    luckyEnergy: narrative,
    dailyAdvice: closing,
    imageAsset: 'star.png',
    rarityColor: const Color(0xFF9B6DFF),
    drawnCards: drawn,
    spreadLabel: spreadLabel,
    closingMessage: closing,
    cardReadings: narrative,
    userQuestion: question,
    readingTheme: 'open',
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
  return AiReadingContent(
    cardName: 'Recovery',
    tagline: '',
    generalMeaning: 'A calm recovery message for a failed interpretation.',
    love: '',
    career: '',
    money: '',
    spiritualGuidance: '',
    luckyEnergy: '',
    dailyAdvice: 'You can try again when ready.',
    imageAsset: 'star.png',
    rarityColor: const Color(0xFF9B6DFF),
    drawnCards: tarotVisualDrawn(1),
    deliveryKind: TarotReadingDeliveryKind.recovery,
  );
}
