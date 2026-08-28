/// OR-1170 — Full tarot reading session aggregate.
library;

import 'package:flutter/foundation.dart';

import '../../../../core/l10n/l10n.dart';
import '../../copy/tarot_l10n.dart';
import '../../models/tarot_card.dart';
import 'tarot_spread.dart';

enum ReadingSessionStatus { inProgress, completed }

enum ReadingFlowStep {
  deckSelection,
  shuffle,
  cardSelection,
  reveal,
  reading,
  completed,
}

@immutable
class TarotDrawnCard {
  const TarotDrawnCard({
    required this.card,
    required this.positionIndex,
    required this.isReversed,
    this.positionLabel,
    this.positionKey,
  });

  final TarotCard card;
  final int positionIndex;
  final bool isReversed;
  final String? positionLabel;
  final String? positionKey;

  String get effectiveMeaning =>
      isReversed ? card.reversedMeaning : card.meaning;

  String get localizedName => TarotL10n.cardNameOf(card);

  String get localizedPosition {
    final key = positionKey;
    if (key != null && key.isNotEmpty) {
      final value = OraclyL10n.t('tarot.pos.$key');
      if (value != 'tarot.pos.$key') return value;
    }
    return positionLabel ?? OraclyL10n.t('tarot.card_field');
  }

  Map<String, dynamic> toJson() => {
        'card': _cardToJson(card),
        'positionIndex': positionIndex,
        'isReversed': isReversed,
        'positionLabel': positionLabel,
        'positionKey': positionKey,
      };

  factory TarotDrawnCard.fromJson(Map<String, dynamic> json) {
    return TarotDrawnCard(
      card: _cardFromJson(json['card'] as Map<String, dynamic>),
      positionIndex: json['positionIndex'] as int? ?? 0,
      isReversed: json['isReversed'] as bool? ?? false,
      positionLabel: json['positionLabel'] as String?,
      positionKey: json['positionKey'] as String?,
    );
  }
}

@immutable
class ReadingSession {
  const ReadingSession({
    required this.id,
    required this.deckId,
    required this.spread,
    required this.intention,
    required this.shuffleSeed,
    required this.startedAt,
    this.userId,
    this.drawnCards = const [],
    this.interpretation,
    this.completedAt,
    this.durationMs,
    this.status = ReadingSessionStatus.inProgress,
    this.flowStep = ReadingFlowStep.deckSelection,
    this.currentPositionIndex = 0,
  });

  final String id;
  final String deckId;
  final String? userId;
  final TarotSpreadType spread;
  final TarotIntention intention;
  final int shuffleSeed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationMs;
  final List<TarotDrawnCard> drawnCards;
  final String? interpretation;
  final ReadingSessionStatus status;
  final ReadingFlowStep flowStep;
  final int currentPositionIndex;

  int get requiredCardCount => spread.cardCount;
  bool get allCardsDrawn => drawnCards.length >= requiredCardCount;
  bool get isComplete =>
      status == ReadingSessionStatus.completed && interpretation != null;

  TarotDrawnCard? get currentCard {
    if (drawnCards.isEmpty) return null;
    if (currentPositionIndex >= drawnCards.length) {
      return drawnCards.last;
    }
    return drawnCards[currentPositionIndex];
  }

  ReadingSession copyWith({
    String? deckId,
    String? userId,
    List<TarotDrawnCard>? drawnCards,
    String? interpretation,
    DateTime? completedAt,
    int? durationMs,
    ReadingSessionStatus? status,
    ReadingFlowStep? flowStep,
    int? currentPositionIndex,
    int? shuffleSeed,
  }) {
    return ReadingSession(
      id: id,
      deckId: deckId ?? this.deckId,
      userId: userId ?? this.userId,
      spread: spread,
      intention: intention,
      shuffleSeed: shuffleSeed ?? this.shuffleSeed,
      startedAt: startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMs: durationMs ?? this.durationMs,
      drawnCards: drawnCards ?? this.drawnCards,
      interpretation: interpretation ?? this.interpretation,
      status: status ?? this.status,
      flowStep: flowStep ?? this.flowStep,
      currentPositionIndex: currentPositionIndex ?? this.currentPositionIndex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'deckId': deckId,
        'userId': userId,
        'spread': spread.name,
        'intention': intention.text,
        'intentionTopic': intention.topic,
        'shuffleSeed': shuffleSeed,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'durationMs': durationMs,
        'drawnCards': drawnCards.map((c) => c.toJson()).toList(),
        'interpretation': interpretation,
        'status': status.name,
        'flowStep': flowStep.name,
        'currentPositionIndex': currentPositionIndex,
      };

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      id: json['id'] as String,
      deckId: json['deckId'] as String? ?? 'rider-waite',
      userId: json['userId'] as String?,
      spread: TarotSpreadType.values.byName(json['spread'] as String),
      intention: TarotIntention(
        text: json['intention'] as String? ?? '',
        topic: json['intentionTopic'] as String?,
      ),
      shuffleSeed: json['shuffleSeed'] as int? ?? 0,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      durationMs: json['durationMs'] as int?,
      drawnCards: (json['drawnCards'] as List<dynamic>? ?? [])
          .map((e) => TarotDrawnCard.fromJson(e as Map<String, dynamic>))
          .toList(),
      interpretation: json['interpretation'] as String?,
      status: ReadingSessionStatus.values.byName(
        json['status'] as String? ?? 'inProgress',
      ),
      flowStep: ReadingFlowStep.values.byName(
        json['flowStep'] as String? ?? 'deckSelection',
      ),
      currentPositionIndex: json['currentPositionIndex'] as int? ?? 0,
    );
  }
}

Map<String, dynamic> _cardToJson(TarotCard card) => {
      'id': card.id,
      'name': card.name,
      'image': card.image,
      'arcana': card.arcana.name,
      'suit': card.suit.name,
      'rank': card.rank.name,
      'number': card.number,
      'summary': card.summary,
      'meaning': card.meaning,
      'reversedMeaning': card.reversedMeaning,
      'keywords': card.keywords,
      'element': card.element,
      'planet': card.planet,
      'zodiac': card.zodiac,
    };

TarotCard _cardFromJson(Map<String, dynamic> json) {
  return TarotCard(
    id: json['id'] as int,
    name: json['name'] as String,
    image: json['image'] as String,
    arcana: TarotArcana.values.byName(json['arcana'] as String),
    suit: TarotSuit.values.byName(json['suit'] as String),
    rank: TarotRank.values.byName(json['rank'] as String? ?? 'none'),
    number: json['number'] as int,
    summary: json['summary'] as String? ?? '',
    meaning: json['meaning'] as String? ?? '',
    reversedMeaning: json['reversedMeaning'] as String? ?? '',
    keywords: (json['keywords'] as List<dynamic>? ?? []).cast<String>(),
    element: json['element'] as String?,
    planet: json['planet'] as String?,
    zodiac: json['zodiac'] as String?,
  );
}
