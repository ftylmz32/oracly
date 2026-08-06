/// OR-1170 — Spread position definitions.
library;

import 'package:flutter/foundation.dart';

import 'tarot_spread.dart';

@immutable
class TarotPosition {
  const TarotPosition({
    required this.index,
    required this.key,
    required this.labelTr,
    this.description,
  });

  final int index;
  final String key;
  final String labelTr;
  final String? description;
}

abstract final class SpreadService {
  SpreadService._();

  static List<TarotPosition> positionsFor(TarotSpreadType spread) {
    return switch (spread) {
      TarotSpreadType.single => const [
          TarotPosition(
            index: 0,
            key: 'focus',
            labelTr: 'Odak',
            description: 'Bugünün ana mesajı.',
          ),
        ],
      TarotSpreadType.threeCard => const [
          TarotPosition(
            index: 0,
            key: 'past',
            labelTr: 'Geçmiş',
            description: 'Kökler ve geçmiş etkiler.',
          ),
          TarotPosition(
            index: 1,
            key: 'present',
            labelTr: 'Şimdi',
            description: 'Mevcut enerji ve durum.',
          ),
          TarotPosition(
            index: 2,
            key: 'future',
            labelTr: 'Gelecek',
            description: 'Yakın geleceğin olası yönü.',
          ),
        ],
      TarotSpreadType.fiveCard => const [
          TarotPosition(
            index: 0,
            key: 'situation',
            labelTr: 'Durum',
            description: 'Mevcut durumun özü.',
          ),
          TarotPosition(
            index: 1,
            key: 'challenge',
            labelTr: 'Engel',
            description: 'Aşılması gereken zorluk.',
          ),
          TarotPosition(
            index: 2,
            key: 'past',
            labelTr: 'Geçmiş',
            description: 'Geçmişten gelen etki.',
          ),
          TarotPosition(
            index: 3,
            key: 'advice',
            labelTr: 'Tavsiye',
            description: 'Evrenin rehberliği.',
          ),
          TarotPosition(
            index: 4,
            key: 'outcome',
            labelTr: 'Sonuç',
            description: 'Olası sonuç ve potansiyel.',
          ),
        ],
      TarotSpreadType.celticCross => const [
          TarotPosition(index: 0, key: 'present', labelTr: 'Şimdi'),
          TarotPosition(index: 1, key: 'challenge', labelTr: 'Engel'),
          TarotPosition(index: 2, key: 'distant_past', labelTr: 'Uzak Geçmiş'),
          TarotPosition(index: 3, key: 'recent_past', labelTr: 'Yakın Geçmiş'),
          TarotPosition(index: 4, key: 'crown', labelTr: 'Taç / Hedef'),
          TarotPosition(index: 5, key: 'near_future', labelTr: 'Yakın Gelecek'),
          TarotPosition(index: 6, key: 'self', labelTr: 'Benlik'),
          TarotPosition(index: 7, key: 'environment', labelTr: 'Çevre'),
          TarotPosition(index: 8, key: 'hopes', labelTr: 'Umut & Korku'),
          TarotPosition(index: 9, key: 'outcome', labelTr: 'Sonuç'),
        ],
    };
  }

  static TarotPosition? positionAt(TarotSpreadType spread, int index) {
    final list = positionsFor(spread);
    if (index < 0 || index >= list.length) return null;
    return list[index];
  }
}
