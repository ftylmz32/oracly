/// OR-1170 — Card reveal data from session draws.
library;

import 'package:flutter/material.dart';

import '../../../copy/tarot_l10n.dart';
import '../../../copy/tarot_polish_copy.dart';
import '../../../domain/models/reading_session.dart';
import '../../../models/tarot_card.dart';
import '../../../../../core/l10n/l10n.dart';

/// Rich card metadata for the selection → reveal pipeline.
class RevealCardData {
  const RevealCardData({
    required this.card,
    required this.displayName,
    required this.subtitle,
    required this.rarityLabel,
    required this.rarityColor,
    required this.imageAsset,
    this.positionLabel,
    this.isReversed = false,
  });

  final TarotCard card;
  final String displayName;
  final String subtitle;
  final String rarityLabel;
  final Color rarityColor;
  final String imageAsset;
  final String? positionLabel;
  final bool isReversed;

  static RevealCardData fromDrawnCard(TarotDrawnCard drawn) {
    final card = drawn.card;
    final orientation =
        drawn.isReversed ? TarotPolishCopy.reversed : TarotPolishCopy.upright;
    // Reveal hierarchy: name → position → orientation. Reading comes later.
    return RevealCardData(
      card: card,
      displayName: TarotL10n.cardNameOf(card),
      subtitle: [
        if ((drawn.localizedPosition).isNotEmpty) drawn.localizedPosition,
        '${TarotPolishCopy.orientationLabel}: $orientation',
      ].join('\n'),
      rarityLabel: card.isMajor
          ? OraclyL10n.t('tarot.arcana.major')
          : OraclyL10n.t('tarot.arcana.minor'),
      rarityColor: card.isMajor
          ? const Color(0xFF9B6DFF)
          : const Color(0xFF7EC8E3),
      imageAsset: card.image,
      positionLabel: drawn.localizedPosition,
      isReversed: drawn.isReversed,
    );
  }
}

abstract final class CardRevealSpread {
  CardRevealSpread._();

  static const _root = 'lib/assets/images/tarot/major_arcana';

  static const List<RevealCardData> cards = [
    RevealCardData(
      card: TarotCard(
        id: 17,
        name: 'The Star',
        image: '$_root/17_yildiz.png',
        arcana: TarotArcana.major,
        suit: TarotSuit.none,
        number: 17,
        summary: 'Umut, ilham ve ruhsal rehberlik.',
        meaning: 'Yıldız kartı yenilenme ve iç huzur getirir.',
        reversedMeaning: 'Geçici umutsuzluk veya bağlantı kaybı.',
        keywords: ['Umut', 'Rehberlik', 'Sezgi'],
        element: 'Su',
      ),
      displayName: 'The Star',
      subtitle: 'Umut ve ilahi rehberlik seninle.',
      rarityLabel: 'Major Arcana',
      rarityColor: Color(0xFF9B6DFF),
      imageAsset: '$_root/17_yildiz.png',
    ),
    RevealCardData(
      card: TarotCard(
        id: 18,
        name: 'The Moon',
        image: '$_root/18_ay.png',
        arcana: TarotArcana.major,
        suit: TarotSuit.none,
        number: 18,
        summary: 'Sezgi, rüya alemi ve gizem.',
        meaning: 'Ay kartı bilinçaltının mesajlarını taşır.',
        reversedMeaning: 'Kafa karışıklığı veya korkular.',
        keywords: ['Sezgi', 'Rüya', 'Gizem'],
        element: 'Su',
      ),
      displayName: 'The Moon',
      subtitle: 'Gecenin bilgeliği sana fısıldıyor.',
      rarityLabel: 'Major Arcana',
      rarityColor: Color(0xFFB794FF),
      imageAsset: '$_root/18_ay.png',
    ),
    RevealCardData(
      card: TarotCard(
        id: 19,
        name: 'The Sun',
        image: '$_root/19_gunes.png',
        arcana: TarotArcana.major,
        suit: TarotSuit.none,
        number: 19,
        summary: 'Aydınlanma, neşe ve canlılık.',
        meaning: 'Güneş kartı başarı ve iç ışığı simgeler.',
        reversedMeaning: 'Geçici hayal kırıklığı.',
        keywords: ['Neşe', 'Başarı', 'Işık'],
        element: 'Ateş',
      ),
      displayName: 'The Sun',
      subtitle: 'Işığın en parlak haliyle parlıyor.',
      rarityLabel: 'Major Arcana',
      rarityColor: Color(0xFFF0D77A),
      imageAsset: '$_root/19_gunes.png',
    ),
    RevealCardData(
      card: TarotCard(
        id: 6,
        name: 'The Lovers',
        image: '$_root/06_asiklar.png',
        arcana: TarotArcana.major,
        suit: TarotSuit.none,
        number: 6,
        summary: 'Bağ, uyum ve bilinçli seçim.',
        meaning: 'Aşıklar kartı kalp ve uyumu temsil eder.',
        reversedMeaning: 'Uyumsuzluk veya kararsızlık.',
        keywords: ['Aşk', 'Seçim', 'Uyum'],
        element: 'Hava',
      ),
      displayName: 'The Lovers',
      subtitle: 'Kalbinin seçimi netleşiyor.',
      rarityLabel: 'Major Arcana',
      rarityColor: Color(0xFFFF6B9D),
      imageAsset: '$_root/06_asiklar.png',
    ),
    RevealCardData(
      card: TarotCard(
        id: 9,
        name: 'The Hermit',
        image: '$_root/09_ermis.png',
        arcana: TarotArcana.major,
        suit: TarotSuit.none,
        number: 9,
        summary: 'İçsel bilgelik ve yalnız arayış.',
        meaning: 'Ermiş kartı sessiz rehberlik sunar.',
        reversedMeaning: 'İzolasyon veya kaçış.',
        keywords: ['Bilgelik', 'Sessizlik', 'Rehber'],
        element: 'Toprak',
      ),
      displayName: 'The Hermit',
      subtitle: 'İçindeki bilge sesi dinle.',
      rarityLabel: 'Major Arcana',
      rarityColor: Color(0xFFD4AF37),
      imageAsset: '$_root/09_ermis.png',
    ),
    RevealCardData(
      card: TarotCard(
        id: 13,
        name: 'Death',
        image: '$_root/13_olum.png',
        arcana: TarotArcana.major,
        suit: TarotSuit.none,
        number: 13,
        summary: 'Dönüşüm ve yeni başlangıç.',
        meaning: 'Ölüm kartı köklü değişimi müjdeler.',
        reversedMeaning: 'Değişime direnç.',
        keywords: ['Dönüşüm', 'Yenilenme', 'Son'],
        element: 'Su',
      ),
      displayName: 'Death',
      subtitle: 'Eski sona eriyor, yeni doğuyor.',
      rarityLabel: 'Major Arcana',
      rarityColor: Color(0xFF6B4BC4),
      imageAsset: '$_root/13_olum.png',
    ),
    RevealCardData(
      card: TarotCard(
        id: 1,
        name: 'The Magician',
        image: '$_root/01_buyucu.png',
        arcana: TarotArcana.major,
        suit: TarotSuit.none,
        number: 1,
        summary: 'Yaratıcı güç ve niyet.',
        meaning: 'Büyücü kartı potansiyeli somutlaştırır.',
        reversedMeaning: 'Manipülasyon veya dağınıklık.',
        keywords: ['Güç', 'Niyet', 'Yaratım'],
        element: 'Hava',
      ),
      displayName: 'The Magician',
      subtitle: 'Evren senin niyetini duyuyor.',
      rarityLabel: 'Major Arcana',
      rarityColor: Color(0xFF7EC8E3),
      imageAsset: '$_root/01_buyucu.png',
    ),
  ];

  static RevealCardData forIndex(int index) {
    return cards[index.clamp(0, cards.length - 1)];
  }
}
