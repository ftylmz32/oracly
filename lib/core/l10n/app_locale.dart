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

  static Locale toLocale(String? raw) => Locale(normalize(raw));

  static String displayName(String? raw) => switch (normalize(raw)) {
    en => 'English',
    ru => 'Русский',
    _ => 'Türkçe',
  };

  static bool isEnglish(String? raw) => normalize(raw) == en;
}
