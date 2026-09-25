/// OR-1170 — Saved tarot reading model (supports multi-card sessions).
library;

import 'reading_card_snapshot.dart';
import 'reading_model_json.dart';
import 'ritual_journal_metadata.dart';

export 'reading_card_snapshot.dart';

class ReadingModel {
  const ReadingModel({
    required this.id,
    required this.cardId,
    required this.cardName,
    required this.cardImageAsset,
    required this.spreadType,
    required this.aiSummary,
    required this.createdAt,
    this.cardIndex = 0,
    this.deckId = 'rider-waite',
    this.cards = const [],
    this.intention,
    this.readingType,
    this.shuffleSeed,
    this.durationMs,
    this.sessionId,
    this.userId,
    this.journal = const RitualJournalMetadata(),
    this.resultMode,
    this.interpretationSource,
    this.deliveryKind,
  });

  final String id;
  final int cardId;
  final int cardIndex;
  final String cardName;
  final String cardImageAsset;
  final String spreadType;
  final String aiSummary;
  final DateTime createdAt;
  final String deckId;
  final List<ReadingCardSnapshot> cards;
  final String? intention;
  final String? readingType;
  final int? shuffleSeed;
  final int? durationMs;
  final String? sessionId;
  final String? userId;
  final RitualJournalMetadata journal;

  /// Presentation mode at save (`narrativeV2` / `legacy`). Null = unknown.
  final String? resultMode;

  /// Source at save (`ai` / `local` / `cache`). Null = unknown — do not invent.
  final String? interpretationSource;

  /// Delivery at save (`interpretation` / `recovery`). Null = unknown.
  final String? deliveryKind;

  /// Primary card orientation from the saved cards snapshot.
  /// Old readings without cards default upright (false).
  bool get primaryIsReversed {
    if (cards.isEmpty) return false;
    for (final card in cards) {
      if (card.cardId == cardId || card.cardImageAsset == cardImageAsset) {
        return card.isReversed;
      }
    }
    final ordered = [...cards]
      ..sort((a, b) => a.positionIndex.compareTo(b.positionIndex));
    return ordered.first.isReversed;
  }

  List<String> get emotionalKeywords => journal.emotionalKeywords;
  String? get personalNote => journal.personalNote;
  String? get summaryExcerpt => journal.summaryExcerpt;
  bool get isFavorite => journal.isFavorite;

  ReadingModel copyWith({
    String? aiSummary,
    RitualJournalMetadata? journal,
  }) {
    return ReadingModel(
      id: id,
      cardId: cardId,
      cardIndex: cardIndex,
      cardName: cardName,
      cardImageAsset: cardImageAsset,
      spreadType: spreadType,
      aiSummary: aiSummary ?? this.aiSummary,
      createdAt: createdAt,
      deckId: deckId,
      cards: cards,
      intention: intention,
      readingType: readingType,
      shuffleSeed: shuffleSeed,
      durationMs: durationMs,
      sessionId: sessionId,
      userId: userId,
      journal: journal ?? this.journal,
      resultMode: resultMode,
      interpretationSource: interpretationSource,
      deliveryKind: deliveryKind,
    );
  }

  Map<String, dynamic> toJson() => readingModelToJson(this);

  factory ReadingModel.fromJson(Map<String, dynamic> json) =>
      readingModelFromJson(json);
}
