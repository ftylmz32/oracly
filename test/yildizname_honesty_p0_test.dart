/// P0 — Yıldızname is sun-sign + catalogue, not a natal engine.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_kind_note.dart';
import 'package:oracly_new/features/birth_chart/copy/birth_chart_copy.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:oracly_new/features/daily_ritual/widgets/daily_ritual_card.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';

void main() {
  test('tropical sun sign stays date-only and not full natal', () {
    const calculator = NatalChartCalculator();
    final chart = calculator.calculate(
      BirthProfile(
        birthDate: DateTime(1995, 8, 15),
        birthPlace: 'İstanbul',
        birthTime: DateTime(1995, 8, 15, 14, 30),
        birthTimeKnown: true,
        latitude: 41.01,
        longitude: 28.98,
      ),
    );

    expect(chart.sun.sign, ZodiacSignId.leo);
    expect(chart.fidelity, ChartCalculationFidelity.tropicalSunSign);
    expect(chart.hasFullNatal, isFalse);
    expect(chart.moon, isNull);
    expect(chart.rising, isNull);
    expect(chart.planets, isEmpty);
    expect(chart.houses, isEmpty);
    expect(chart.aspects, isEmpty);
  });

  test('product and result copy do not claim a natal engine', () {
    expect(BirthChartCopy.screenTitle, 'Yıldızname');
    expect(BirthChartCopy.sectionYourChart, 'Güneş burcun');
    expect(BirthChartCopy.summaryTitle, 'Yorumun özeti');
    expect(BirthChartCopy.personalizeEmpty, contains('Güneş burcuna göre'));
    expect(BirthChartCopy.onboardingDescription, contains('yalnızca doğum tarihinden'));
    expect(BirthChartCopy.timeImportance, contains('hesaba katılmaz'));
    expect(BirthChartCopy.placeImportance, contains('hesaba katılmaz'));
    expect(BirthChartCopy.storedNotUsedNote, contains('hesaba katılmaz'));
    expect(BirthChartCopy.ephemerisNote, contains('sembolik'));
    expect(BirthChartCopy.ephemerisNote, contains('Güneş burcun'));
    expect(StarMapPolishCopy.birthChartTitle, 'Kişisel yıldızname yolu');
    expect(StarMapPolishCopy.birthChartHint.toLowerCase(), contains('sembolik'));
    expect(StarMapPolishCopy.whatItIs, contains('sembolik'));
    expect(StarMapPolishCopy.planetsCatalogueNote.toLowerCase(), contains('sembolik'));
    expect(StarMapPolishCopy.karmicTitle, 'Hikâyenin iplikleri');
    expect(StarMapPolishCopy.karmicResultTitle, 'İÇİNDEKİ TEMA');
    expect(StarMapPolishCopy.karmicResultTitle, isNot('KARMİK ANALİZ'));
    expect(StarMapPolishCopy.todayReflectionTitle, 'BUGÜNÜN İZİ');
    expect(StarMapPolishCopy.journeyTitle, 'SON DÖNEMİN HİKÂYESİ');
    expect(StarMapPolishCopy.karmicAsk, 'ÖNÜNDEKİ EŞİK');
    expect(StarMapPolishCopy.leftQuestionTitle, 'SANA BIRAKTIĞI SORU');
    expect(
      StarMapPolishCopy.karmicResultTitle.toLowerCase(),
      isNot(contains('karmik')),
    );
    expect(StarMapPolishCopy.karmicHint.toLowerCase(), isNot(contains('katalog')));
    expect(StarMapPolishCopy.karmicHint.toLowerCase(), isNot(contains('hesap')));

    for (final text in [
      BirthChartCopy.screenTitle,
      BirthChartCopy.onboardingDescription,
      BirthChartCopy.generateChart,
      BirthChartCopy.sectionYourChart,
      BirthChartCopy.summaryTitle,
      BirthChartCopy.closingNote,
      StarMapPolishCopy.birthChartTitle,
      StarMapPolishCopy.chartReady,
    ]) {
      expect(text.toLowerCase(), isNot(contains('tam doğum haritası')));
      expect(text.toLowerCase(), isNot(contains('natal')));
      expect(text.toLowerCase(), isNot(contains('ephemeris')));
    }
  });

  test('catalogue yıldızname is not labeled AI', () {
    expect(BirthChartCopy.ephemerisNote.toLowerCase(), isNot(contains('ai')));
    expect(
      BirthChartCopy.ephemerisNote.toLowerCase(),
      isNot(contains('yapay zek')),
    );
    expect(StarMapPolishCopy.whatItIs.toLowerCase(), isNot(contains('ai')));
    expect(AstrologyReferenceKindNote.label, 'Önizleme');
    expect(AstrologyReferenceKindNote.detail, contains('yansıma'));
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), isNot(contains('hesaplanmaz')));
    expect(
      AstrologyReferenceKindNote.detail.toLowerCase(),
      isNot(contains('ai')),
    );
  });

  test('home daily ritual, tarot first session, premium and gems stay same', () {
    expect(DailyRitualCard.title, 'Bugünkü Ayin');
    expect(TarotFirstReading.spread, TarotSpreadType.single);
    expect(TarotFirstReading.spread.label, 'Tek Kart');
    expect(TarotEconomy.readingCost, 20);
    expect(GemEconomy.starterGrant, 20);
    expect(PremiumCopy.purchaseUnavailable, contains('henüz'));
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.starMap)?.title,
      'Yıldızname',
    );
  });
}
