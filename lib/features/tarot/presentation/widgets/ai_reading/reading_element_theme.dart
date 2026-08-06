/// OR-301+ — Element-based ambient lighting for the drawn card.
library;

import 'package:flutter/material.dart';

import '../../../models/tarot_card.dart';
import '../../../../../core/theme/oracly_brand_signature.dart';

enum ReadingElement { fire, water, air, earth, universal }

@immutable
class ReadingElementTheme {
  const ReadingElementTheme({
    required this.element,
    required this.glowColor,
    required this.glowSecondary,
  });

  final ReadingElement element;
  final Color glowColor;
  final Color glowSecondary;

  static ReadingElementTheme fromCard(TarotCard? card) {
    final el = _resolveElement(card);
    return switch (el) {
      ReadingElement.fire => const ReadingElementTheme(
          element: ReadingElement.fire,
          glowColor: Color(0xFFFF8C42),
          glowSecondary: Color(0xFFFFB366),
        ),
      ReadingElement.water => const ReadingElementTheme(
          element: ReadingElement.water,
          glowColor: Color(0xFF4A9EFF),
          glowSecondary: Color(0xFF6BB5FF),
        ),
      ReadingElement.air => const ReadingElementTheme(
          element: ReadingElement.air,
          glowColor: Color(0xFFE8ECF4),
          glowSecondary: Color(0xFFC8D0E0),
        ),
      ReadingElement.earth => const ReadingElementTheme(
          element: ReadingElement.earth,
          glowColor: Color(0xFF8FB84A),
          glowSecondary: Color(0xFFD4AF37),
        ),
      ReadingElement.universal => ReadingElementTheme(
          element: ReadingElement.universal,
          glowColor: OraclySignaturePalette.purpleEnergy,
          glowSecondary: OraclySignaturePalette.champagneDeep,
        ),
    };
  }

  static ReadingElement _resolveElement(TarotCard? card) {
    if (card == null) return ReadingElement.universal;
    final raw = card.element?.toLowerCase();
    if (raw != null && raw.isNotEmpty) {
      return switch (raw) {
        'fire' || 'ateş' => ReadingElement.fire,
        'water' || 'su' => ReadingElement.water,
        'air' || 'hava' => ReadingElement.air,
        'earth' || 'toprak' => ReadingElement.earth,
        _ => ReadingElement.universal,
      };
    }
    return switch (card.suit) {
      TarotSuit.wands => ReadingElement.fire,
      TarotSuit.cups => ReadingElement.water,
      TarotSuit.swords => ReadingElement.air,
      TarotSuit.pentacles => ReadingElement.earth,
      _ => ReadingElement.universal,
    };
  }
}
