/// JSON codec helpers for [ReadingModel] — keeps model file under line budget.
library;

import 'reading.dart';
import 'ritual_journal_metadata.dart';

Map<String, dynamic> readingModelToJson(ReadingModel m) => {
      'id': m.id,
      'cardId': m.cardId,
      'cardIndex': m.cardIndex,
      'cardName': m.cardName,
      'cardImageAsset': m.cardImageAsset,
      'spreadType': m.spreadType,
      'aiSummary': m.aiSummary,
      'createdAt': m.createdAt.toIso8601String(),
      'deckId': m.deckId,
      'cards': m.cards.map((c) => c.toJson()).toList(),
      'intention': m.intention,
      'readingType': m.readingType,
      'shuffleSeed': m.shuffleSeed,
      'durationMs': m.durationMs,
      'sessionId': m.sessionId,
      'userId': m.userId,
      'journal': m.journal.toJson(),
      if (m.resultMode != null) 'resultMode': m.resultMode,
      if (m.interpretationSource != null)
        'interpretationSource': m.interpretationSource,
      if (m.deliveryKind != null) 'deliveryKind': m.deliveryKind,
    };

ReadingModel readingModelFromJson(Map<String, dynamic> json) {
  return ReadingModel(
    id: json['id'] as String,
    cardId: json['cardId'] as int? ?? 0,
    cardIndex: json['cardIndex'] as int? ?? 0,
    cardName: json['cardName'] as String? ?? '',
    cardImageAsset: json['cardImageAsset'] as String? ?? '',
    spreadType: json['spreadType'] as String? ?? 'Tek Kart',
    aiSummary: json['aiSummary'] as String? ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.now(),
    deckId: json['deckId'] as String? ?? 'rider-waite',
    cards: (json['cards'] as List<dynamic>? ?? [])
        .map((e) => ReadingCardSnapshot.fromJson(e as Map<String, dynamic>))
        .toList(),
    intention: json['intention'] as String?,
    readingType: json['readingType'] as String? ?? json['intention'] as String?,
    shuffleSeed: json['shuffleSeed'] as int?,
    durationMs: json['durationMs'] as int?,
    sessionId: json['sessionId'] as String?,
    userId: json['userId'] as String?,
    journal: RitualJournalMetadata.fromJson(
      json['journal'] as Map<String, dynamic>?,
    ),
    resultMode: json['resultMode'] as String?,
    interpretationSource: json['interpretationSource'] as String?,
    deliveryKind: json['deliveryKind'] as String?,
  );
}
