/// Spread position catalogs — static layout data.
library;

import 'package:flutter/foundation.dart';

import '../../../../core/l10n/l10n.dart';

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

  String get label => OraclyL10n.t('tarot.pos.$key');
}

const kSinglePositions = [
  TarotPosition(
    index: 0,
    key: 'sign',
    labelTr: 'Bugünün ana işareti',
    description: 'Bugünün duruşuna dair tek işaret.',
  ),
];

const kThreeCardPositions = [
  TarotPosition(
    index: 0,
    key: 'past',
    labelTr: 'Geçmiş',
    description: 'Kökler ve geride kalan etki.',
  ),
  TarotPosition(
    index: 1,
    key: 'present',
    labelTr: 'Şimdi',
    description: 'Şu anki enerji.',
  ),
  TarotPosition(
    index: 2,
    key: 'future',
    labelTr: 'Gelecek',
    description: 'Öne açılan sembolik yön — kesin bir kehanet değil.',
  ),
];

const kFiveCardPositions = [
  TarotPosition(
    index: 0,
    key: 'situation',
    labelTr: 'Durum',
    description: 'Görünen sahne.',
  ),
  TarotPosition(
    index: 1,
    key: 'hidden_influence',
    labelTr: 'Gizli etki',
    description: 'Altta duran etki.',
  ),
  TarotPosition(
    index: 2,
    key: 'challenge',
    labelTr: 'Zorluk',
    description: 'Sürtünme noktası.',
  ),
  TarotPosition(
    index: 3,
    key: 'strength',
    labelTr: 'Güç',
    description: 'Eldeki destek.',
  ),
  TarotPosition(
    index: 4,
    key: 'direction',
    labelTr: 'Yön',
    description: 'Sembolik yön — kehanet değil.',
  ),
];

const kSevenCardPositions = [
  TarotPosition(
    index: 0,
    key: 'question',
    labelTr: 'Soru',
    description: 'Meselenin kalbi.',
  ),
  TarotPosition(
    index: 1,
    key: 'current_energy',
    labelTr: 'Şimdiki enerji',
    description: 'Şu anki iklim.',
  ),
  TarotPosition(
    index: 2,
    key: 'obstacle',
    labelTr: 'Engel',
    description: 'Karşıdaki zorluk.',
  ),
  TarotPosition(
    index: 3,
    key: 'hidden_factor',
    labelTr: 'Gizli etken',
    description: 'Henüz net görünmeyen.',
  ),
  TarotPosition(
    index: 4,
    key: 'what_helps',
    labelTr: 'Yardımcı olan',
    description: 'Destekleyen eğilim.',
  ),
  TarotPosition(
    index: 5,
    key: 'what_to_avoid',
    labelTr: 'Kaçınılacak',
    description: 'Uzak durmanın yardımcı olabileceği yer.',
  ),
  TarotPosition(
    index: 6,
    key: 'direction',
    labelTr: 'Yön',
    description: 'Sembolik yön — kehanet değil.',
  ),
];

const kCelticCrossPositions = [
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
];
