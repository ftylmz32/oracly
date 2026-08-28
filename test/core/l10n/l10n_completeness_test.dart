/// Production key completeness and no mixed-language fallback.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/app_string_tables.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';

void main() {
  test('every production key exists in TR, EN, and RU with no empty values', () {
    final triples = AppStringTables.all;
    expect(triples, isNotEmpty);
    for (final e in triples.entries) {
      expect(e.value.tr.trim(), isNotEmpty, reason: 'TR empty: ${e.key}');
      expect(e.value.en.trim(), isNotEmpty, reason: 'EN empty: ${e.key}');
      expect(e.value.ru.trim(), isNotEmpty, reason: 'RU empty: ${e.key}');
    }
  });

  test('selected language never falls back to another language', () {
    OraclyL10n.bind('en');
    expect(OraclyL10n.t(L10nKeys.settingsTitle), 'SETTINGS');
    expect(OraclyL10n.t('missing.en.only.key'), 'missing.en.only.key');
    expect(OraclyL10n.t('missing.en.only.key'), isNot('AYARLAR'));

    OraclyL10n.bind('ru');
    expect(OraclyL10n.t(L10nKeys.settingsTitle), 'НАСТРОЙКИ');
    expect(OraclyL10n.t('missing.ru.only.key'), 'missing.ru.only.key');
    expect(OraclyL10n.t('missing.ru.only.key'), isNot('AYARLAR'));
    expect(OraclyL10n.t('missing.ru.only.key'), isNot('SETTINGS'));

    OraclyL10n.bind('tr');
    expect(OraclyL10n.t(L10nKeys.settingsTitle), 'AYARLAR');
  });

  test('AppLocale normalizes Russian labels', () {
    expect(AppLocale.normalize('Русский'), AppLocale.ru);
    expect(AppLocale.normalize('ru'), AppLocale.ru);
    expect(AppLocale.normalize('russian'), AppLocale.ru);
    expect(AppLocale.displayName('ru'), 'Русский');
  });

  test('coffee palm premium soulmate headings follow bound locale', () {
    OraclyL10n.bind('en');
    expect(CoffeeCopy.loveTitle, 'LOVE');
    expect(CoffeeCopy.nearFutureTitle, 'NEWS');
    expect(PalmCopy.leftHand, 'LEFT HAND');
    expect(PalmCopy.rightHand, 'RIGHT HAND');
    expect(PremiumCopy.ctaUnavailable, contains('not open'));
    expect(SoulMateCopy.drawCta, 'CREATE PORTRAIT');
    expect(ResilienceCopy.retryAction, 'TRY AGAIN');

    OraclyL10n.bind('ru');
    expect(CoffeeCopy.loveTitle, 'ЛЮБОВЬ');
    expect(CoffeeCopy.nearFutureTitle, 'ВЕСТЬ');
    expect(PalmCopy.leftHand, 'ЛЕВАЯ РУКА');
    expect(PalmCopy.rightHand, 'ПРАВАЯ РУКА');
    expect(SoulMateCopy.screenTitle, 'РОДСТВЕННАЯ ДУША');

    OraclyL10n.bind('tr');
    expect(CoffeeCopy.loveTitle, 'AŞK');
    expect(PalmCopy.leftHand, 'SOL EL');
  });
}
