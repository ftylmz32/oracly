/// Raw current-reading facts for NarrativeEvidenceBuilder (3D.1D).
library;

import '../../domain/models/tarot_spread.dart';

class NarrativeEvidenceCardInput {
  const NarrativeEvidenceCardInput({
    required this.canonicalCardId,
    required this.ritualCardId,
    required this.isReversed,
    required this.positionKey,
    required this.positionIndex,
  });

  final String canonicalCardId;
  final int ritualCardId;
  final bool isReversed;
  final String positionKey;
  final int positionIndex;
}

class NarrativeEvidenceInput {
  NarrativeEvidenceInput({
    required this.sessionId,
    required this.readingId,
    required this.languageCode,
    this.questionRaw,
    this.intentionTopic,
    required this.spreadType,
    required Iterable<NarrativeEvidenceCardInput> cards,
  }) : cards = List<NarrativeEvidenceCardInput>.unmodifiable(
         List<NarrativeEvidenceCardInput>.from(cards),
       );

  final String sessionId;
  final String readingId;
  final String languageCode;
  final String? questionRaw;
  final String? intentionTopic;
  final TarotSpreadType spreadType;
  final List<NarrativeEvidenceCardInput> cards;
}
