import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_app_bar.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_hero_card.dart';
import 'package:oracly_new/features/premium/presentation/reference/premium_reference_screen.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
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

  testWidgets('live premium fits 360x640 without fake prices', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: PremiumReferenceScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(tester.takeException(), isNull);
    expect(find.text(PremiumCopy.heroTitle), findsOneWidget);
    expect(find.text(PremiumCopy.heroSubtitle), findsOneWidget);
    expect(
      find.text(PremiumCopy.benefitOrTitle, skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.text(PremiumCopy.benefitJourneyTitle, skipOffstage: false),
      findsWidgets,
    );
    expect(
      find.text(PremiumCopy.benefitCoffeeTitle, skipOffstage: false),
      findsNothing,
    );
    expect(
      find.text(PremiumCopy.ctaUnavailable, skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.text(PremiumCopy.ctaHint, skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text(PremiumCopy.ctaExplore), findsOneWidget);
    expect(find.byType(OraclyGoldButton), findsNothing);
    expect(find.text('Planı Seç'), findsNothing);
    expect(find.textContaining('₺'), findsNothing);
  });

  group('Premium reference — no overflow', () {
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
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: const EdgeInsets.only(bottom: 24),
                ),
                child: const PremiumReferenceScreen(),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 80));

        expect(tester.takeException(), isNull);
        expect(find.text(PremiumReferenceAppBar.title), findsOneWidget);
        expect(find.text('PREMİUM'), findsOneWidget);
        expect(find.byType(PremiumReferenceHeroCard), findsOneWidget);
        expect(find.text(PremiumCopy.heroTitle), findsWidgets);
        expect(
          find.text(PremiumCopy.ctaUnavailable, skipOffstage: false),
          findsOneWidget,
        );
        expect(find.byType(OraclyGoldButton), findsNothing);
        expect(find.text('Planı Seç'), findsNothing);
        expect(find.textContaining('₺'), findsNothing);
      });
    }
  });
}
