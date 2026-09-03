/// Canonical app language codes — persist `tr` / `en` / `ru` only.
library;

import 'package:flutter/material.dart';

abstract final class AppLocale {
  AppLocale._();

  static const tr = 'tr';
  static const en = 'en';
  static const ru = 'ru';

  static const productionCodes = <String>[tr, en, ru];

  static const supportedLocales = <Locale>[Locale(tr), Locale(en), Locale(ru)];

  static const displayOptions = <(String, String)>[
    (tr, 'Türkçe'),
    (en, 'English'),
    (ru, 'Русский'),
  ];

  /// Production picker — only languages with complete visible catalogues.
  static const pickerOptions = displayOptions;

  /// Accepts legacy display labels and modern codes. Never Spanish.
  static String normalize(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == en || v == 'english' || v == 'ingilizce' || v.startsWith('en')) {
      return en;
    }
    if (v == ru ||
        v == 'russian' ||
        v == 'русский' ||
        v == 'русская' ||
        v.startsWith('ru')) {
      return ru;
    }
    return tr;
  }

  /// Maps a device [Locale] to a supported product code.
  /// Unsupported → safe fallback [tr]. Does not invent languages.
  static String fromDeviceLocale(Locale? device) {
    final code = device?.languageCode.trim().toLowerCase() ?? '';
    if (code == en) return en;
    if (code == ru) return ru;
    if (code == tr) return tr;
    return tr;
  }

  /// Explicit stored language always wins. Missing/blank → device, else [tr].
  static String resolvePreferred({String? stored, Locale? device}) {
    final raw = stored?.trim() ?? '';
    if (raw.isNotEmpty) return normalize(raw);
    return fromDeviceLocale(device ?? readDeviceLocale());
  }

  /// Test override for first-launch device locale resolution.
  static Locale Function()? debugDeviceLocale;

  static Locale readDeviceLocale() {
    if (debugDeviceLocale != null) return debugDeviceLocale!();
    try {
      return WidgetsBinding.instance.platformDispatcher.locale;
    } catch (_) {
      return const Locale(tr);
    }
  }

  /// Material/Cupertino chrome locale. Flutter has no `tr` Material strings.
  static Locale materialLocale(String? raw) {
    final code = normalize(raw);
    if (code == ru) return const Locale(ru);
    return const Locale(en);
  }

  static Locale toLocale(String? raw) => Locale(normalize(raw));

  static String displayName(String? raw) => switch (normalize(raw)) {
    en => 'English',
    ru => 'Русский',
    _ => 'Türkçe',
  };

  static bool isEnglish(String? raw) => normalize(raw) == en;
}
