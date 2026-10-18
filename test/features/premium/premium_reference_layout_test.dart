import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/design_system/app_spacing.dart';
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
    Size(320, 568),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(412, 915),
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
    expect(find.text(PremiumCopy.ctaExplore), findsNothing);
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
                  textScaler: size.width <= 412
                      ? const TextScaler.linear(1.3)
                      : TextScaler.noScaling,
                  padding: const EdgeInsets.only(bottom: 24),
                  disableAnimations: true,
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

  testWidgets('premium page fits 320 and 412 at 1.3x text', (tester) async {
    for (final size in const [Size(320, 568), Size(412, 915)]) {
      await tester.binding.setSurfaceSize(size);
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.3),
                disableAnimations: true,
              ),
              child: const PremiumReferenceScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.takeException(), isNull);
      final list = tester.widget<ListView>(find.byType(ListView));
      final pad = list.padding! as EdgeInsets;
      expect(
        pad.bottom,
        greaterThanOrEqualTo(
          AppLayout.navBarHeight +
              AppLayout.navBarMarginBottom +
              AppLayout.contentBottomBreath +
              AppSpacing.s16,
        ),
      );
      final link = find.text(PremiumCopy.reviewAccess);
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump();
      expect(tester.takeException(), isNull);
      final box = tester.getRect(link);
      expect(box.top, greaterThanOrEqualTo(0));
      expect(box.bottom, lessThanOrEqualTo(size.height - AppLayout.navBarHeight));
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
