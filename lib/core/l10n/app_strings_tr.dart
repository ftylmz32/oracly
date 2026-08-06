/// OR-438 — Default Turkish strings (current app language).
library;

import 'l10n_keys.dart';

/// In-memory string table — replace with generated l10n when `flutter gen-l10n` ships.
abstract final class AppStringsTr {
  AppStringsTr._();

  static const _strings = <String, String>{
    L10nKeys.home: 'Ana Sayfa',
    L10nKeys.tarot: 'Tarot',
    L10nKeys.chat: 'Sohbet',
    L10nKeys.profile: 'Profil',
    L10nKeys.tarotReading: 'Tarot Falı',
    L10nKeys.aiChat: 'AI Sohbet',
    L10nKeys.dream: 'Rüya Analizi',
    L10nKeys.astrology: 'Astroloji',
    L10nKeys.numerology: 'Numeroloji',
    L10nKeys.moonCalendar: 'Ay Takvimi',
    L10nKeys.manifestation: 'Manifestasyon',
    L10nKeys.settingsTitle: 'Ayarlar',
    L10nKeys.language: 'Dil',
    L10nKeys.save: 'Kaydet',
    L10nKeys.cancel: 'İptal',
    L10nKeys.comingSoon: 'Yakında',
  };

  static String resolve(String key, {String? fallback}) =>
      _strings[key] ?? fallback ?? key;
}
