/// SPRINT-002 — Zodiac sign identifiers.
library;

import '../../../core/l10n/l10n.dart';

enum ZodiacSignId {
  aries('Koç', '♈'),
  taurus('Boğa', '♉'),
  gemini('İkizler', '♊'),
  cancer('Yengeç', '♋'),
  leo('Aslan', '♌'),
  virgo('Başak', '♍'),
  libra('Terazi', '♎'),
  scorpio('Akrep', '♏'),
  sagittarius('Yay', '♐'),
  capricorn('Oğlak', '♑'),
  aquarius('Kova', '♒'),
  pisces('Balık', '♓');

  const ZodiacSignId(this.labelTr, this.symbol);
  final String labelTr;
  final String symbol;

  String get id => name;

  String labeled(String languageCode) =>
      OraclyL10n.t('zodiac.$name', languageCode: languageCode);

  static ZodiacSignId fromIndex(int index) {
    return values[index % values.length];
  }

  static ZodiacSignId fromDate(DateTime date) {
    final month = date.month;
    final day = date.day;

    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) {
      return aries;
    }
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) {
      return taurus;
    }
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) {
      return gemini;
    }
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) {
      return cancer;
    }
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) {
      return leo;
    }
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) {
      return virgo;
    }
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) {
      return libra;
    }
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) {
      return scorpio;
    }
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
      return sagittarius;
    }
    if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
      return capricorn;
    }
    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
      return aquarius;
    }
    return pisces;
  }

  int get signIndex => ZodiacSignId.values.indexOf(this);
}

enum ChartElement { fire, earth, air, water }

enum ChartModality { cardinal, fixed, mutable }

enum PlanetId {
  sun('Güneş'),
  moon('Ay'),
  ascendant('Yükselen'),
  mercury('Merkür'),
  venus('Venüs'),
  mars('Mars'),
  jupiter('Jüpiter'),
  saturn('Satürn'),
  uranus('Uranüs'),
  neptune('Neptün'),
  pluto('Plüton');

  const PlanetId(this.labelTr);
  final String labelTr;

  String labeled(String languageCode) =>
      OraclyL10n.t('planet.$name', languageCode: languageCode);
}

enum AspectType {
  conjunction('Kavuşum', 0, 8),
  sextile('Sekstil', 60, 6),
  square('Kare', 90, 8),
  trine('Üçgen', 120, 8),
  opposition('Karşıt', 180, 8);

  const AspectType(this.labelTr, this.angle, this.defaultOrb);
  final String labelTr;
  final int angle;
  final int defaultOrb;

  String labeled(String languageCode) =>
      OraclyL10n.t('aspect.$name', languageCode: languageCode);
}
