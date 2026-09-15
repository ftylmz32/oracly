/// UI hardening — palm result rendering with realistic long AI text.
///
/// Complements the existing E3H live-envelope render check (which only
/// covers 320x568/390x844 with no text-scale variation) with the remaining
/// required device widths and an accessibility text-scale pass.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _longOverall = '''
Avucundaki genel çizgi dağılımı, hayatının bu döneminde pratiklik ile '''
    'sezgi arasında bir denge kurmaya çalıştığını gösteriyor. Baş çizgisinin '
    'derinliği, karar verirken duygularını bastırmadan mantığını da devreye '
    'soktuğuna işaret ediyor; bu nadir bir denge ve seni güçlü kılan '
    'yönlerinden biri.\n\n'
    'Avuç içindeki genel doku ise son dönemde yaşadığın bir yorgunluğun '
    'izlerini taşıyor. Bu yorgunluk fiziksel değil, daha çok karar '
    'yorgunluğu; art arda küçük seçimler yapmak zorunda kalman seni '
    'tüketmiş olabilir.';

const _longHeart = '''
Kalp çizgisinin kesintisiz ve derin oluşu, duygusal bağlarında '''
    'kalıcılığı önemsediğini gösteriyor. Ancak çizginin sonunda görülen '
    'küçük çatallanma, yakın zamanda bir ilişkinde iki yol arasında '
    'kalabileceğine işaret ediyor. Bu çatallanma bir son değil, sadece '
    'bir seçim anı.';

const _longHead = '''
Baş çizgisi boyunca gözlemlenen düzenli aralıklar, analitik düşünme '''
    'biçiminin son dönemde daha disiplinli hale geldiğini gösteriyor. '
    'Bu, kariyerinde karşına çıkacak karmaşık bir problemi çözerken sana '
    'avantaj sağlayacak.';

const _longLife = '''
Yaşam çizgisinin geniş kavisi, enerjini geniş bir çevreye yaymayı '''
    'sevdiğini, ama bazen kendine yeterince zaman ayırmadığını gösteriyor. '
    'Önümüzdeki dönemde bu dengesizliği fark edip küçük bir düzeltme '
    'yapman, genel iyi oluşuna doğrudan katkı sağlayacak.';

const _longFate = '''
Kader çizgisinin orta noktada belirginleşmesi, hayatının bu evresinde '''
    'kendi seçimlerinin kaderini önceki dönemlerden daha güçlü şekilde '
    'şekillendirdiğini gösteriyor. Bu, sorumluluk hissini artırabilir ama '
    'aynı zamanda özgürleştirici bir işaret.';

const _longTakeaway = '''
Bugün senden istenen tek şey: bir kararı ertelemeyi bırakıp, avucunun '''
    'sana zaten gösterdiği yöne doğru küçük bir adım atmak.';

PalmReading _longReading() {
  return PalmReading(
    id: 'p-long-1',
    createdAt: DateTime(2026, 8, 30),
    hand: PalmHand.right,
    overall: _longOverall,
    heartLine: _longHeart,
    headLine: _longHead,
    lifeLine: _longLife,
    fateLine: _longFate,
    takeaway: _longTakeaway,
    symbols: const ['Yıldız işareti', 'Kesişen çizgiler'],
    themes: const ['Denge', 'Karar'],
  );
}

Future<LocalStorage> _storage() async {
  SharedPreferences.setMockInitialValues({});
  return LocalStorage.open();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  const viewports = <Size>[
    Size(320, 568),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(412, 915),
  ];

  for (final size in viewports) {
    testWidgets(
      'palm result renders long AI text without overflow at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        final storage = await _storage();
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          ProviderScope(
            overrides: [localStorageProvider.overrideWithValue(storage)],
            child: MaterialApp(
              home: Scaffold(
                body: PalmResultView(
                  reading: _longReading(),
                  onNewPalm: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);

        expect(
          find.textContaining('avucunun sana zaten gösterdiği'),
          findsWidgets,
        );

        await tester.dragUntilVisible(
          find.textContaining('avucunun sana zaten gösterdiği'),
          find.byType(Scrollable).first,
          const Offset(0, -400),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'palm result stays usable at 1.3x text scale',
    (tester) async {
      final storage = await _storage();
      const size = Size(360, 800);
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageProvider.overrideWithValue(storage)],
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: size,
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: Scaffold(
                  body: PalmResultView(
                    reading: _longReading(),
                    onNewPalm: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
    },
  );
}
