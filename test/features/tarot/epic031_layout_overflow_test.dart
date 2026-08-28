import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/data/gem_display.dart';
import 'package:oracly_new/features/tarot/presentation/epic031/tarot_epic031_page.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/deck/physical_deck_stack.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  const viewports = <Size>[
    Size(360, 640),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

  group('Tarot entry — composition, no overflow', () {
    for (final size in viewports) {
      testWidgets('full page at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        SharedPreferences.setMockInitialValues({});
        final storage = await LocalStorage.open();
        await tester.pumpWidget(
          buildProviderScopeHarness(
            storage: storage,
            child: const MaterialApp(
              home: TarotEpic031Page(),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('TAROT'), findsOneWidget);
        expect(find.text(GemDisplay.format(0)), findsOneWidget);
        expect(
          find.text('Bugün evren sana ne fısıldıyor?'),
          findsOneWidget,
        );
        expect(
          find.text('Aklındaki soruyu yaz... (isteğe bağlı)'),
          findsOneWidget,
        );
        expect(find.text('TEK KART'), findsOneWidget);
        expect(find.text('ÜÇ KART'), findsOneWidget);
        expect(find.text('DERİN AÇILIM'), findsOneWidget);
        expect(find.text('YEDİ KART'), findsOneWidget);
        expect(find.text('RİTÜELE GİR'), findsOneWidget);
        expect(find.byType(PhysicalDeckStack), findsOneWidget);
        expect(find.text('78'), findsNothing);
        expect(find.text('Rüya'), findsNothing);
      });
    }
  });
}
