/// HOME 03 — scrollable Home foundation: all sections, nav clearance.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/features/home/master/home_master_body.dart';
import 'package:oracly_new/features/home/master/home_master_budget.dart';
import 'package:oracly_new/features/home/master/home_master_grid.dart';
import 'package:oracly_new/features/home/master/home_master_header.dart';
import 'package:oracly_new/features/home/master/home_master_hero.dart';
import 'package:oracly_new/features/home/master/home_master_or.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/master/home_master_premium.dart';
import 'package:oracly_new/features/home/master/home_master_today.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(360, 640),
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
  ];

  Future<void> pumpHome(WidgetTester tester, Size size) async {
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
              padding: const EdgeInsets.only(top: 24, bottom: 34),
            ),
            child: const HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  test('budget allocates exactly to content height on KN8-class', () {
    const nav = 60.0 + 8.0 + 34.0 + 16.0;
    final budget = HomeMasterBudget.resolve(
      maxHeight: 640 - 24 - 4,
      navClearance: nav,
    );
    expect(budget.allocated, closeTo(budget.contentHeight, 0.01));
    expect(budget.header, greaterThan(0));
    expect(budget.hero, greaterThan(0));
    expect(budget.orSection, greaterThan(0));
    expect(budget.today, greaterThan(0));
    expect(budget.grid, greaterThan(0));
    expect(budget.premium, greaterThan(0));
    expect(budget.navClearance, nav);
  });

  for (final size in viewports) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('scrollable Home shows all sections on $label', (tester) async {
      await pumpHome(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeMasterPage), findsOneWidget);
      expect(find.byType(HomeMasterBody), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(HomeMasterHeader), findsOneWidget);
      expect(find.byType(HomeMasterHero), findsOneWidget);
      expect(find.byType(HomeMasterOr), findsOneWidget);
      expect(find.byType(HomeMasterToday), findsOneWidget);
      expect(find.byType(HomeMasterGrid), findsOneWidget);
      expect(find.byType(HomeMasterPremium), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(NestedScrollView), findsNothing);
      expect(find.byType(PageView), findsNothing);

      await tester.scrollUntilVisible(
        find.byType(HomeMasterPremium),
        80,
        scrollable: find
            .descendant(
              of: find.byType(HomeMasterBody),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump();

      final premium = tester.getRect(find.byType(HomeMasterPremium));
      final page = tester.getRect(find.byType(HomeMasterPage));
      expect(
        page.bottom - premium.bottom,
        greaterThanOrEqualTo(AppLayout.navBarHeight),
      );
    });
  }
}
