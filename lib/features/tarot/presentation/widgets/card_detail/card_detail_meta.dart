/// Canonical element / planet / zodiac labels for card-detail chips.
library;

import '../../../../../core/l10n/l10n.dart';

abstract final class CardDetailMeta {
  CardDetailMeta._();

  static String element(String raw) {
    final key = switch (raw.trim()) {
      'Ateş' => 'birth.element.fire',
      'Toprak' => 'birth.element.earth',
      'Hava' => 'birth.element.air',
      'Su' => 'birth.element.water',
      _ => null,
    };
    return key == null ? raw : OraclyL10n.t(key);
  }

  static String planet(String raw) {
    final key = switch (raw.trim()) {
      'Güneş' => 'planet.sun',
      'Ay' => 'planet.moon',
      'Merkür' => 'planet.mercury',
      'Venüs' => 'planet.venus',
      'Mars' => 'planet.mars',
      'Jüpiter' => 'planet.jupiter',
      'Satürn' => 'planet.saturn',
      'Uranüs' => 'planet.uranus',
      'Neptün' => 'planet.neptune',
      'Plüton' => 'planet.pluto',
      _ => null,
    };
    return key == null ? raw : OraclyL10n.t(key);
  }

  static String zodiac(String raw) {
    final trimmed = raw.trim();
    // Catalogue quirk: Tower uses planetary Mars in the zodiac field.
    if (trimmed == 'Mars') return planet(trimmed);
    final key = switch (trimmed) {
      'Koç' => 'zodiac.aries',
      'Boğa' => 'zodiac.taurus',
      'İkizler' => 'zodiac.gemini',
      'Yengeç' => 'zodiac.cancer',
      'Aslan' => 'zodiac.leo',
      'Başak' => 'zodiac.virgo',
      'Terazi' => 'zodiac.libra',
      'Akrep' => 'zodiac.scorpio',
      'Yay' => 'zodiac.sagittarius',
      'Oğlak' => 'zodiac.capricorn',
      'Kova' => 'zodiac.aquarius',
      'Balık' => 'zodiac.pisces',
      _ => null,
    };
    return key == null ? raw : OraclyL10n.t(key);
  }
}
