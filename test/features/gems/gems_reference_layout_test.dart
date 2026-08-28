import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/gems/copy/gems_copy.dart';
import 'package:oracly_new/features/gems/data/gem_display.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/presentation/reference/gems_reference_app_bar.dart';
import 'package:oracly_new/features/gems/presentation/reference/gems_reference_hero.dart';
import 'package:oracly_new/features/gems/presentation/reference/gems_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

  Future<void> pumpGems(WidgetTester tester, {Size size = const Size(360, 800)}) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(bottom: 24),
            ),
            child: const GemsReferenceScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
  }

  testWidgets('gems screen fits 360x640 without fake shop', (tester) async {
    await pumpGems(tester, size: const Size(360, 640));

    expect(tester.takeException(), isNull);
    expect(find.text(GemsReferenceAppBar.title), findsOneWidget);
    expect(find.text('MÜCEVHERLER'), findsOneWidget);
    expect(find.byType(GemsBalanceHero), findsOneWidget);
    expect(find.text(GemDisplay.format(0)), findsAtLeastNWidgets(2));
    expect(find.text('+${GemEconomy.starterGrant}'), findsOneWidget);
    expect(
      find.text('+${GemEconomy.dailyReward}${GemsCopy.dailyValueSuffix}'),
      findsOneWidget,
    );
    expect(find.text('-${GemEconomy.tarotReading}'), findsOneWidget);
    expect(find.text(GemsCopy.reasonStarter), findsOneWidget);
    expect(find.text(GemsCopy.reasonDailyReward), findsOneWidget);
    expect(find.text(GemsCopy.tarotLabel), findsOneWidget);
    expect(find.text(GemsCopy.whatTitle), findsOneWidget);
    expect(find.text(GemsCopy.spendTitle), findsOneWidget);
    expect(find.text(GemsCopy.dailyRewardLink), findsOneWidget);
    expect(find.text(GemsCopy.shopHonesty), findsOneWidget);
    expect(find.textContaining('₺'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('Mücevher Paketi Satın Al'), findsNothing);
    expect(find.text('Yakında'), findsNothing);
  });

  group('Gems reference — no overflow', () {
    for (final size in viewports) {
      testWidgets('full page at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await pumpGems(tester, size: size);

        expect(tester.takeException(), isNull);
        expect(find.text('MÜCEVHERLER'), findsOneWidget);
        expect(find.byType(GemsBalanceHero), findsOneWidget);
        expect(find.text('+${GemEconomy.starterGrant}'), findsOneWidget);
        expect(find.text('-${GemEconomy.tarotReading}'), findsOneWidget);
        expect(find.textContaining('₺'), findsNothing);
      });
    }
  });
}
