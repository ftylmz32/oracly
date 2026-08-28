/// Coffee V1 polish — vision honesty, result spine, OR, gems, copy.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/personality/or_living_voice.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_followup_copy.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_parser.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/economy/coffee_economy.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('result titles match the V1 coffee spine', () {
    expect(CoffeeCopy.overallTitle, 'FİNCANIN SANA ANLATTIĞI');
    expect(CoffeeCopy.overallSubtitle, 'Küçük detaylar, büyük hikâyeler...');
    expect(CoffeeCopy.symbolsTitle, 'ÖNE ÇIKAN SEMBOLLER');
    expect(CoffeeCopy.loveTitle, 'AŞK');
    expect(CoffeeCopy.careerTitle, 'İŞ');
    expect(CoffeeCopy.moneyTitle, 'Maddi Konular');
    expect(CoffeeCopy.newsTitle, 'HABER');
    expect(CoffeeCopy.pathTitle, 'YOL');
    expect(CoffeeCopy.nearFutureTitle, 'HABER');
    expect(CoffeeCopy.cautionTitle, 'DİKKAT');
    expect(CoffeeCopy.attentionTitle, 'DİKKAT');
    expect(CoffeeCopy.takeawayTitle, 'DİKKAT');
    expect(
      CoffeeCopy.analyzing,
      isIn(OrLivingVoice.thinkingPool(OrLivingSurface.coffee)),
    );
    expect(CoffeeCopy.analyzingSubtitle, contains('fotoğraf'));
    expect(
      CoffeeCopy.analysisFailed,
      'Fincanı şu an okuyamadım. Bir daha deneyelim.',
    );
    expect(CoffeeCopy.retry, 'TEKRAR DENE');
    expect(CoffeeCopy.disclaimer, 'Bu, sembolik bir yorumdur.');
  });

  test('parser accepts yakinDonem without inventing symbols', () {
    final reading = CoffeeReadingParser.parse(
      '''
{
  "genelYorum": "Fincanda sakin bir açıklık var.",
  "ask": "Yakınlık için net bir cümle iyi gelir.",
  "kariyer": "Tek bir işi bitirmek kazandırır.",
  "maddiDurum": "Küçük bir birikim adımı yeter.",
  "yakinDonem": "Acele kararları bir gece beklet.",
  "semboller": [],
  "sonuc": "Bugün sakin ve net dur."
}
''',
      id: 'c-polish',
      createdAt: DateTime(2026, 8, 9),
    );
    expect(reading, isNotNull);
    expect(reading!.nearFuture, contains('Acele'));
    expect(reading.symbols, isEmpty);
  });

  test('history reopen keeps category interpretations', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CoffeeReadingStore(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    final reading = CoffeeReading(
      id: 'c-hist',
      createdAt: DateTime(2026, 8, 9, 11),
      imagePath: '/tmp/cup.jpg',
      overall: 'Genel sakinlik.',
      love: 'Aşkta netlik.',
      career: 'İşde sabır.',
      money: 'Küçük adım.',
      nearFuture: 'Acele etme.',
      takeaway: 'Nefes al.',
    );
    await store.save(reading);
    final loaded = store.byId('c-hist');
    expect(loaded?.imagePath, '/tmp/cup.jpg');
    expect(loaded?.overall, 'Genel sakinlik.');
    expect(loaded?.takeaway, 'Nefes al.');
  });

  test('OR answers coffee follow-up from the reading', () {
    final reading = CoffeeReading(
      id: 'c-or',
      createdAt: DateTime(2026, 8, 9),
      overall: 'Fincanda duruluk var.',
      love: 'Yakınlık için sakin bir cümle.',
      career: 'Tek işe odaklan.',
      money: 'Küçük birikim.',
      nearFuture: 'Acele kararları beklet.',
      takeaway: 'Sakin kal.',
    );
    final ctx = OracleReadingContextSources.coffee(reading);
    expect(ctx.fullInterpretation, contains('Fincanda duruluk'));
    expect(ctx.fullInterpretation, contains('Sakin kal'));
    final answer = OracleFollowupCopy.respond(
      context: ctx,
      question: 'Kariyer kısmı bana ne söylüyor?',
    );
    expect(answer.toLowerCase(), contains('kariyer'));
    expect(answer.toLowerCase(), anyOf(contains('duruluk'), contains('odaklan')));
  });

  test('unavailable vision and free gem hook stay honest', () {
    expect(const UnavailableCoffeeAnalysis().isAvailable, isFalse);
    expect(
      CoffeeCopy.analysisUnavailable,
      'Kahve falı şu an hazırlanamadı. Biraz sonra tekrar deneyebilirsin.',
    );
    expect(CoffeeEconomy.hasCost, isFalse);
    expect(GemsCopy.insufficient, 'Yeterli mücevherin yok.');
  });
}
