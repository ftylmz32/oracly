/// Phase 6D — immutable Narrative structured result DTOs.
library;

final class NarrativeTarotCardReading {
  const NarrativeTarotCardReading({
    required this.cardId,
    required this.positionKey,
    required this.text,
  });

  final String cardId;
  final String positionKey;
  final String text;
}

final class NarrativeTarotRelationshipInsight {
  const NarrativeTarotRelationshipInsight({
    required this.leftCardId,
    required this.rightCardId,
    required this.kind,
    required this.text,
  });

  final String leftCardId;
  final String rightCardId;
  final String kind;
  final String text;
}

final class NarrativeTarotRecurringCardInsight {
  const NarrativeTarotRecurringCardInsight({
    required this.cardId,
    required this.text,
  });

  final String cardId;
  final String text;
}

final class NarrativeTarotRecurringThemeInsight {
  const NarrativeTarotRecurringThemeInsight({
    required this.themeIdOrLabel,
    required this.text,
  });

  final String themeIdOrLabel;
  final String text;
}

final class NarrativeTarotMemoryInsight {
  NarrativeTarotMemoryInsight({
    required List<int> memoryIndices,
    required this.text,
  }) : memoryIndices = List<int>.unmodifiable(memoryIndices);

  final List<int> memoryIndices;
  final String text;
}

final class NarrativeTarotLifeArea {
  const NarrativeTarotLifeArea({required this.kind, required this.text});

  final String kind;
  final String text;
}

final class NarrativeTarotStructuredResult {
  NarrativeTarotStructuredResult({
    required this.contractVersion,
    required this.languageCode,
    required this.summary,
    required List<NarrativeTarotCardReading> cardReadings,
    required this.synthesis,
    required List<NarrativeTarotRelationshipInsight> relationshipInsights,
    required List<NarrativeTarotRecurringCardInsight> recurringCardInsights,
    required List<NarrativeTarotRecurringThemeInsight> recurringThemeInsights,
    required List<NarrativeTarotMemoryInsight> memoryInsights,
    required List<NarrativeTarotLifeArea> lifeAreas,
    required this.advice,
    required this.reflectionPrompt,
    required this.dailyFocus,
    required this.closingMessage,
  })  : cardReadings =
            List<NarrativeTarotCardReading>.unmodifiable(cardReadings),
        relationshipInsights =
            List<NarrativeTarotRelationshipInsight>.unmodifiable(
              relationshipInsights,
            ),
        recurringCardInsights =
            List<NarrativeTarotRecurringCardInsight>.unmodifiable(
              recurringCardInsights,
            ),
        recurringThemeInsights =
            List<NarrativeTarotRecurringThemeInsight>.unmodifiable(
              recurringThemeInsights,
            ),
        memoryInsights =
            List<NarrativeTarotMemoryInsight>.unmodifiable(memoryInsights),
        lifeAreas = List<NarrativeTarotLifeArea>.unmodifiable(lifeAreas);

  final int contractVersion;
  final String languageCode;
  final String summary;
  final List<NarrativeTarotCardReading> cardReadings;
  final String synthesis;
  final List<NarrativeTarotRelationshipInsight> relationshipInsights;
  final List<NarrativeTarotRecurringCardInsight> recurringCardInsights;
  final List<NarrativeTarotRecurringThemeInsight> recurringThemeInsights;
  final List<NarrativeTarotMemoryInsight> memoryInsights;
  final List<NarrativeTarotLifeArea> lifeAreas;
  final String advice;
  final String? reflectionPrompt;
  final String? dailyFocus;
  final String closingMessage;
}
