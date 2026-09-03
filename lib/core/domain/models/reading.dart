/// OR-1170 — Saved tarot reading model (supports multi-card sessions).
library;

import 'ritual_journal_metadata.dart';

class ReadingCardSnapshot {
  const ReadingCardSnapshot({
    required this.cardId,
    required this.cardName,
    required this.cardImageAsset,
    required this.positionIndex,
    this.positionLabel,
    this.isReversed = false,
  });

  final int cardId;
  final String cardName;
  final String cardImageAsset;
  final int positionIndex;
  final String? positionLabel;
  final bool isReversed;

  Map<String, dynamic> toJson() => {
        'cardId': cardId,
        'cardName': cardName,
        'cardImageAsset': cardImageAsset,
        'positionIndex': positionIndex,
        'positionLabel': positionLabel,
        'isReversed': isReversed,
      };

  factory ReadingCardSnapshot.fromJson(Map<String, dynamic> json) {
    return ReadingCardSnapshot(
      cardId: json['cardId'] as int? ?? 0,
      cardName: json['cardName'] as String? ?? '',
      cardImageAsset: json['cardImageAsset'] as String? ?? '',
      positionIndex: json['positionIndex'] as int? ?? 0,
      positionLabel: json['positionLabel'] as String?,
      isReversed: json['isReversed'] as bool? ?? false,
    );
  }
}

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
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardId': cardId,
        'cardIndex': cardIndex,
        'cardName': cardName,
        'cardImageAsset': cardImageAsset,
        'spreadType': spreadType,
        'aiSummary': aiSummary,
        'createdAt': createdAt.toIso8601String(),
        'deckId': deckId,
        'cards': cards.map((c) => c.toJson()).toList(),
        'intention': intention,
        'readingType': readingType,
        'shuffleSeed': shuffleSeed,
        'durationMs': durationMs,
        'sessionId': sessionId,
        'userId': userId,
        'journal': journal.toJson(),
      };

  factory ReadingModel.fromJson(Map<String, dynamic> json) {
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
    );
  }
}
