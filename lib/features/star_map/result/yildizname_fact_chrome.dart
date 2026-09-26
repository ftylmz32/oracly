/// Explicit wire → typed → localized mappings for the natal fact layer.
///
/// Wire strings are parsed through closed, explicit tables — an unknown body,
/// sign, aspect or kind maps to `null` and the fact is dropped, so a raw
/// identifier can never become UI. Labels reuse the shared product tables
/// (`planet.*`, `zodiac.*`, `aspect.*`, `birth.element.*`) so there is exactly
/// one translation of each zodiac / planet / aspect name in the app.
library;

import '../../../core/l10n/l10n.dart';
import 'yildizname_fact_snapshot.dart';
import 'yildizname_result_chrome.dart';

abstract final class YildiznameFactChrome {
  YildiznameFactChrome._();

  // -- wire → typed (closed tables) ----------------------------------------

  static const Map<String, YildiznameFactSubject> _bodies = {
    'sun': YildiznameFactSubject.sun,
    'moon': YildiznameFactSubject.moon,
    'mercury': YildiznameFactSubject.mercury,
    'venus': YildiznameFactSubject.venus,
    'mars': YildiznameFactSubject.mars,
    'jupiter': YildiznameFactSubject.jupiter,
    'saturn': YildiznameFactSubject.saturn,
    'uranus': YildiznameFactSubject.uranus,
    'neptune': YildiznameFactSubject.neptune,
    'pluto': YildiznameFactSubject.pluto,
  };

  static const Map<String, YildiznameFactSubject> _angles = {
    'ascendant': YildiznameFactSubject.ascendant,
    'midheaven': YildiznameFactSubject.midheaven,
  };

  static const Map<String, String> _signKeys = {
    'aries': 'zodiac.aries',
    'taurus': 'zodiac.taurus',
    'gemini': 'zodiac.gemini',
    'cancer': 'zodiac.cancer',
    'leo': 'zodiac.leo',
    'virgo': 'zodiac.virgo',
    'libra': 'zodiac.libra',
    'scorpio': 'zodiac.scorpio',
    'sagittarius': 'zodiac.sagittarius',
    'capricorn': 'zodiac.capricorn',
    'aquarius': 'zodiac.aquarius',
    'pisces': 'zodiac.pisces',
  };

  static const Map<String, String> _aspectKeys = {
    'conjunction': 'aspect.conjunction',
    'sextile': 'aspect.sextile',
    'square': 'aspect.square',
    'trine': 'aspect.trine',
    'opposition': 'aspect.opposition',
  };

  static const Map<String, int> _aspectOrder = {
    'conjunction': 0,
    'sextile': 1,
    'square': 2,
    'trine': 3,
    'opposition': 4,
  };

  static const Map<String, String> _elementKeys = {
    'fire': 'birth.element.fire',
    'earth': 'birth.element.earth',
    'air': 'birth.element.air',
    'water': 'birth.element.water',
  };

  static const Map<String, String> _qualityKeys = {
    'cardinal': 'star.fact.quality.cardinal',
    'fixed': 'star.fact.quality.fixed',
    'mutable': 'star.fact.quality.mutable',
  };

  /// Planet body for a request `body` value; angles are NOT bodies.
  static YildiznameFactSubject? bodyOf(Object? wire) =>
      wire is String ? _bodies[wire] : null;

  /// Angle subject for a request angle `kind` / factRef suffix.
  static YildiznameFactSubject? angleOf(Object? wire) =>
      wire is String ? _angles[wire] : null;

  static bool isSign(Object? wire) => wire is String && _signKeys[wire] != null;

  static bool isAspect(Object? wire) =>
      wire is String && _aspectKeys[wire] != null;

  static int aspectOrder(String wire) => _aspectOrder[wire] ?? 99;

  static bool isElement(Object? wire) =>
      wire is String && _elementKeys[wire] != null;

  static bool isQuality(Object? wire) =>
      wire is String && _qualityKeys[wire] != null;

  // -- typed → group ---------------------------------------------------------

  static YildiznameFactGroup groupOf(YildiznameFactSubject s) => switch (s) {
    YildiznameFactSubject.sun ||
    YildiznameFactSubject.moon ||
    YildiznameFactSubject.ascendant ||
    YildiznameFactSubject.midheaven => YildiznameFactGroup.primary,
    YildiznameFactSubject.mercury ||
    YildiznameFactSubject.venus ||
    YildiznameFactSubject.mars => YildiznameFactGroup.secondary,
    YildiznameFactSubject.jupiter ||
    YildiznameFactSubject.saturn ||
    YildiznameFactSubject.uranus ||
    YildiznameFactSubject.neptune ||
    YildiznameFactSubject.pluto => YildiznameFactGroup.outer,
  };

  /// Deterministic priority order — never the request array order.
  static const List<YildiznameFactSubject> order = [
    YildiznameFactSubject.sun,
    YildiznameFactSubject.moon,
    YildiznameFactSubject.ascendant,
    YildiznameFactSubject.midheaven,
    YildiznameFactSubject.mercury,
    YildiznameFactSubject.venus,
    YildiznameFactSubject.mars,
    YildiznameFactSubject.jupiter,
    YildiznameFactSubject.saturn,
    YildiznameFactSubject.uranus,
    YildiznameFactSubject.neptune,
    YildiznameFactSubject.pluto,
  ];

  static int rankOf(YildiznameFactSubject s) => order.indexOf(s);

  /// Only the slower planets can honestly be flagged retrograde.
  static bool canBeRetrograde(YildiznameFactSubject s) => switch (s) {
    YildiznameFactSubject.mercury ||
    YildiznameFactSubject.venus ||
    YildiznameFactSubject.mars ||
    YildiznameFactSubject.jupiter ||
    YildiznameFactSubject.saturn ||
    YildiznameFactSubject.uranus ||
    YildiznameFactSubject.neptune ||
    YildiznameFactSubject.pluto => true,
    _ => false,
  };

  // -- typed → localized -----------------------------------------------------

  static String _t(String key, String lang) =>
      OraclyL10n.t(key, languageCode: lang);

  static String subjectLabel(YildiznameFactSubject s, String lang) {
    final key = switch (s) {
      YildiznameFactSubject.sun => 'planet.sun',
      YildiznameFactSubject.moon => 'planet.moon',
      YildiznameFactSubject.ascendant => 'planet.ascendant',
      YildiznameFactSubject.midheaven => 'star.fact.midheaven',
      YildiznameFactSubject.mercury => 'planet.mercury',
      YildiznameFactSubject.venus => 'planet.venus',
      YildiznameFactSubject.mars => 'planet.mars',
      YildiznameFactSubject.jupiter => 'planet.jupiter',
      YildiznameFactSubject.saturn => 'planet.saturn',
      YildiznameFactSubject.uranus => 'planet.uranus',
      YildiznameFactSubject.neptune => 'planet.neptune',
      YildiznameFactSubject.pluto => 'planet.pluto',
    };
    return _t(key, lang);
  }

  /// Localized sign name for a VALIDATED sign wire value.
  static String signLabel(String signWire, String lang) =>
      _t(_signKeys[signWire]!, lang);

  static String aspectLabel(String aspectWire, String lang) =>
      _t(_aspectKeys[aspectWire]!, lang);

  static String houseLabel(int number, String lang) =>
      _t('star.fact.house', lang).replaceAll('{n}', '$number');

  static String retrogradeLabel(String lang) =>
      _t('star.fact.retrograde', lang);

  static String elementLabel(String wire, String lang) =>
      _t(_elementKeys[wire]!, lang);

  static String qualityLabel(String wire, String lang) =>
      _t(_qualityKeys[wire]!, lang);

  static String balanceElementTitle(String lang) =>
      _t('star.fact.balance.element', lang);

  static String balanceQualityTitle(String lang) =>
      _t('star.fact.balance.quality', lang);

  static String title([String? lang]) =>
      _t('star.fact.title', YildiznameResultChrome.language(lang));

  static String moreLabel(String lang) => _t('star.fact.more', lang);

  static String outerLabel(String lang) => _t('star.fact.outer', lang);

  static String aspectsLabel(String lang) => _t('star.fact.aspects', lang);
}
