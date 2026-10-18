import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
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
    Size(320, 568),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

  Future<void> pumpGems(
    WidgetTester tester, {
    Size size = const Size(360, 800),
  }) async {
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
    expect(find.text('—'), findsAtLeastNWidgets(2));
    expect(find.text(GemDisplay.format(0)), findsNothing);
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
      testWidgets('full page at ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
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

  testWidgets('gems list clears the floating shell bar', (tester) async {
    const size = Size(390, 844);
    const safeBottom = 34.0;
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: size,
              padding: EdgeInsets.only(top: 47, bottom: safeBottom),
              viewPadding: EdgeInsets.only(top: 47, bottom: safeBottom),
            ),
            child: Scaffold(
              extendBody: true,
              body: const GemsReferenceScreen(),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  AppLayout.navBarMarginBottom + safeBottom,
                ),
                child: const SizedBox(height: AppLayout.navBarHeight),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final list = tester.widget<ListView>(find.byType(ListView));
    final pad = list.padding! as EdgeInsets;
    expect(
      pad.bottom,
      greaterThanOrEqualTo(
        AppLayout.navBarHeight +
            AppLayout.navBarMarginBottom +
            safeBottom +
            AppLayout.contentBottomBreath,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
