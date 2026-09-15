/// UI hardening — coffee result rendering with realistic long AI text.
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
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _longOverall = '''
Fincanın ağzına yakın bölgede uzun, kesintisiz bir çizgi göze çarpıyor; '''
    'bu çizgi, önümüzdeki haftalarda hayatına giren bir fırsatın ilk '
    'bakışta göründüğünden daha kalıcı olacağına işaret ediyor. Tabanda '
    'toplanan yoğun telve kümesi ise geçmişten taşıdığın bir yükün henüz '
    'tam olarak bırakılmadığını gösteriyor. Bu iki işaret bir arada '
    'okunduğunda, önündeki fırsatı kabul etmeden önce eski bir hesaplaşmayı '
    'tamamlaman gerektiği ortaya çıkıyor.\n\n'
    'Kenarlardaki dağınık noktalar, çevrende olup biten küçük dedikoduların '
    'ya da yanlış anlaşılmaların şu anda sandığından daha az önemli '
    'olduğunu hatırlatıyor. Enerjini bunlara harcamak yerine, ortadaki net '
    'çizgiye odaklanman daha doğru olur.';

const _longLove = '''
Kalp meselesinde fincan, sende beklenti ile gerçeklik arasında bir '''
    'boşluk olduğunu gösteriyor. Karşındaki kişiden beklediğin adımı '
    'kendin atmadığın sürece bu boşluk kapanmayacak. Cesaretle bir adım '
    'atman, ilişkinin gidişatını olumlu yönde değiştirecek.';

const _longCareer = '''
Kariyer alanında görülen yükselen çizgi, emeğinin karşılığını almaya '''
    'başladığını gösteriyor. Ancak bu yükseliş düz bir çizgi değil; '
    'zikzaklı bir yol izliyor, yani ilerlerken küçük gerilemeler de '
    'yaşayabilirsin. Bu gerilemeler seni yolundan caydırmasın.';

const _longNear = '''
Yakın gelecekte, uzun süredir beklediğin bir haberin geleceğine dair '''
    'güçlü bir işaret var. Bu haber, planladığın bir şeyi hızlandırabilir '
    'ya da yön değiştirmene neden olabilir; her iki durumda da sonuç '
    'lehine olacak.';

const _longTakeaway = '''
Bugünden itibaren dikkat etmen gereken tek şey: küçük işaretleri '''
    'görmezden gelme alışkanlığın. Bu fincanda gördüğün her ayrıntı, '
    'aslında zaten fark ettiğin ama kabul etmek istemediğin bir gerçeğin '
    'yansıması.';

CoffeeReading _longReading() {
  return CoffeeReading(
    id: 'c-long-1',
    createdAt: DateTime(2026, 8, 30),
    overall: _longOverall,
    love: _longLove,
    career: _longCareer,
    money: '',
    nearFuture: _longNear,
    takeaway: _longTakeaway,
    visualObservation: '',
    symbols: const [
      CoffeeSymbol(
        name: 'Kuş',
        meaning: 'İyi haber',
        interpretation:
            'Kanatlarını açmış bir kuş şekli, beklenmedik ama sevindirici '
            'bir haberin yolda olduğunu gösteriyor.',
        trust: CoffeeMarkTrust.high,
      ),
      CoffeeSymbol(
        name: 'Yol',
        meaning: 'Yeni bir yön',
        interpretation:
            'Uzun ve dolambaçlı bir yol şekli, önündeki kararın tek bir '
            'adımda değil, aşama aşama netleşeceğini işaret ediyor.',
        trust: CoffeeMarkTrust.mid,
      ),
    ],
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
      'coffee result renders long AI text without overflow at '
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
                body: CoffeeResultView(
                  reading: _longReading(),
                  onNewCup: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));
        expect(tester.takeException(), isNull);

        expect(
          find.textContaining('küçük işaretleri görmezden gelme'),
          findsWidgets,
        );

        await tester.dragUntilVisible(
          find.textContaining('küçük işaretleri görmezden gelme'),
          find.byType(Scrollable).first,
          const Offset(0, -400),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'coffee result stays usable at 1.3x text scale',
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
                  body: CoffeeResultView(
                    reading: _longReading(),
                    onNewCup: () {},
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
