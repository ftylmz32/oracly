/// Phase 6C — question / spread / card prompt DTO parts.
library;

final class NarrativePromptQuestion {
  const NarrativePromptQuestion({
    required this.text,
    required this.topic,
    required this.kind,
    required this.hasRealQuestion,
  });

  final String? text;
  final String? topic;
  final String kind;
  final bool hasRealQuestion;
}

final class NarrativePromptPosition {
  const NarrativePromptPosition({
    required this.positionKey,
    required this.index,
    required this.role,
    required this.temporal,
  });

  final String positionKey;
  final int index;
  final String role;
  final String temporal;
}

final class NarrativePromptSpread {
  NarrativePromptSpread({
    required this.spreadId,
    required this.cardCount,
    required this.geometryHook,
    required this.lengthBand,
    required List<int> interpretationOrder,
    required List<NarrativePromptPosition> positions,
  }) : interpretationOrder = List<int>.unmodifiable(interpretationOrder),
       positions = List<NarrativePromptPosition>.unmodifiable(positions);

  final String spreadId;
  final int cardCount;
  final String geometryHook;
  final String lengthBand;
  final List<int> interpretationOrder;
  final List<NarrativePromptPosition> positions;
}

final class NarrativePromptCard {
  NarrativePromptCard({
    required this.canonicalCardId,
    required this.displayName,
    required this.isReversed,
    required this.positionKey,
    required this.positionIndex,
    required this.coreMeaning,
    required this.orientationExpression,
    required List<String> keywordIds,
    required List<String> symbolTags,
    required List<String> transforms,
    this.light,
    this.shadow,
    this.tension,
    this.desire,
    this.fear,
    this.relationshipDynamic,
    this.decisionDynamic,
    this.actionDirection,
  }) : keywordIds = List<String>.unmodifiable(keywordIds),
       symbolTags = List<String>.unmodifiable(symbolTags),
       transforms = List<String>.unmodifiable(transforms);

  final String canonicalCardId;
  final String displayName;
  final bool isReversed;
  final String positionKey;
  final int positionIndex;
  final String coreMeaning;
  final String orientationExpression;
  final List<String> keywordIds;
  final List<String> symbolTags;
  final List<String> transforms;
  final String? light;
  final String? shadow;
  final String? tension;
  final String? desire;
  final String? fear;
  final String? relationshipDynamic;
  final String? decisionDynamic;
  final String? actionDirection;
}
