/// HOME composition — cinematic preferred sizes; scroll when content exceeds.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/master/home_master_body.dart';
import 'package:oracly_new/features/home/master/home_master_budget.dart';
import 'package:oracly_new/features/home/master/home_master_composition.dart';
import 'package:oracly_new/features/home/master/home_master_grid.dart';
import 'package:oracly_new/features/home/master/home_master_header.dart';
import 'package:oracly_new/features/home/master/home_master_hero.dart';
import 'package:oracly_new/features/home/master/home_master_or.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/master/home_master_premium.dart';
import 'package:oracly_new/features/home/master/home_master_today.dart';
import 'package:oracly_new/features/home/reference/home_reference_module_tile.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const modernPhones = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(430, 932),
  ];

  const shortPhones = <Size>[
    Size(320, 568),
    Size(360, 640),
  ];

  const mediaPadding = EdgeInsets.only(top: 24, bottom: 34);

  Future<void> pumpHome(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
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
              padding: mediaPadding,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
  }

  Finder scrollableInBody() => find.descendant(
        of: find.byType(HomeMasterBody),
        matching: find.byType(Scrollable),
      );

  void expectHierarchy() {
    expect(find.byType(HomeMasterHeader), findsOneWidget);
    expect(find.byType(HomeMasterHero), findsOneWidget);
    expect(find.byType(HomeMasterOr), findsOneWidget);
    expect(find.byType(HomeMasterToday), findsOneWidget);
    expect(find.byType(HomeMasterGrid), findsOneWidget);
    expect(find.byType(HomeMasterPremium), findsOneWidget);
  }

  test('preferred layout keeps cinematic floors', () {
    final layout = HomeReferenceTokens.layoutFor(844);
    expect(layout.heroSlotHeight, greaterThanOrEqualTo(168));
    expect(layout.orGuideHeight, greaterThanOrEqualTo(118));
    expect(layout.moduleTileHeight, greaterThanOrEqualTo(104));
    expect(layout.dreamExtensionHeight, greaterThanOrEqualTo(72));
    expect(layout.greetingTitleSize, greaterThanOrEqualTo(18));
  });

  test('budget no longer force-fits by crushing floors', () {
    const nav = 60.0 + 8.0 + 34.0 + 16.0;
    final budget = HomeMasterBudget.resolve(
      maxHeight: 800,
      navClearance: nav,
    );
    expect(budget.hero, greaterThanOrEqualTo(160));
    expect(budget.orSection, greaterThanOrEqualTo(118));
    expect(budget.grid, greaterThan(200));
  });

  test('composition prefers scroll over crushing on normal phones', () {
    final composition = HomeMasterComposition.resolve(
      bodyHeight: 700,
      navClearance: 118,
      screenHeightHint: 800,
    );
    expect(composition.layout.moduleTileHeight, greaterThanOrEqualTo(104));
    expect(composition.requiresScroll, isTrue);
  });

  for (final size in modernPhones) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('modern $label keeps hierarchy without overflow',
        (tester) async {
      await pumpHome(tester, size);
      expect(tester.takeException(), isNull);
      expectHierarchy();
      expect(find.byType(HomeReferenceModuleTile), findsNWidgets(7));
      expect(
        find.text(HomeDiscoveryCopy.title(OraclyFeatureId.dream)),
        findsOneWidget,
      );

      final hero = tester.getSize(find.byType(HomeMasterHero));
      expect(hero.height, greaterThanOrEqualTo(160));

      final tiles = tester.getSize(find.byType(HomeMasterGrid));
      expect(tiles.height, greaterThanOrEqualTo(260));
    });
  }

  for (final size in shortPhones) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('short $label scrolls safely to Premium', (tester) async {
      await pumpHome(tester, size);
      expect(tester.takeException(), isNull);
      expectHierarchy();
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byType(HomeMasterPremium),
        80,
        scrollable: scrollableInBody().first,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final premium = tester.getRect(find.byType(HomeMasterPremium));
      final page = tester.getRect(find.byType(HomeMasterPage));
      expect(
        page.bottom - premium.bottom,
        greaterThanOrEqualTo(AppLayout.navBarHeight),
      );
    });
  }

  testWidgets('text scale 1.3 remains usable via scroll', (tester) async {
    await pumpHome(tester, const Size(390, 844), textScale: 1.3);
    expect(tester.takeException(), isNull);
    expectHierarchy();
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(HomeMasterPremium),
      80,
      scrollable: scrollableInBody().first,
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
