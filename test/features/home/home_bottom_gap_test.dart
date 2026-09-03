/// HOME bottom gap - shell nav must not be double-counted into scroll inset.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/features/home/master/home_master_body.dart';
import 'package:oracly_new/features/home/master/home_master_bottom_inset.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/master/home_master_premium.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const phones = <Size>[
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
    Size(360, 640),
  ];

  const safeBottom = 34.0;
  const expectedClearance = AppLayout.navBarHeight +
      AppLayout.navBarMarginBottom +
      safeBottom +
      AppLayout.contentBottomBreath;

  Widget shellHome(Size size) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: const EdgeInsets.only(top: 47, bottom: safeBottom),
        viewPadding: const EdgeInsets.only(top: 47, bottom: safeBottom),
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBody: true,
        body: const HomeMasterPage(),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.navBarMarginH,
            0,
            AppLayout.navBarMarginH,
            AppLayout.navBarMarginBottom + safeBottom,
          ),
          child: const SizedBox(
            height: AppLayout.navBarHeight,
            child: ColoredBox(color: Color(0x33FF0000)),
          ),
        ),
      ),
    );
  }

  Future<void> pumpShellHome(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(home: shellHome(size)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
  }

  testWidgets('inset under shell matches single nav clearance', (tester) async {
    late double inset;
    late double legacyInset;
    late double inflatedPadding;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 47, bottom: safeBottom),
            viewPadding: EdgeInsets.only(top: 47, bottom: safeBottom),
          ),
          child: Scaffold(
            extendBody: true,
            body: Builder(
              builder: (context) {
                inflatedPadding = MediaQuery.paddingOf(context).bottom;
                inset = HomeMasterBottomInset.resolve(context);
                legacyInset = AppLayout.scrollBottomInset(context);
                return const SizedBox.expand();
              },
            ),
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
    );
    await tester.pump();

    expect(inflatedPadding, greaterThan(safeBottom));
    expect(inset, closeTo(expectedClearance, 0.5));
    expect(
      legacyInset,
      closeTo(inset, 0.5),
      reason: 'AppLayout must match Home — no shell double-count',
    );
  });

  testWidgets('isolated Home still reserves full nav chrome', (tester) async {
    late double inset;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            padding: EdgeInsets.only(top: 47, bottom: safeBottom),
          ),
          child: Builder(
            builder: (context) {
              inset = HomeMasterBottomInset.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    expect(inset, closeTo(expectedClearance, 0.5));
  });

  for (final size in phones) {
    final label = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('shell $label Premium clears nav without excess gap',
        (tester) async {
      await pumpShellHome(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.byType(HomeMasterBody), findsOneWidget);

      final scrollable = find.descendant(
        of: find.byType(HomeMasterBody),
        matching: find.byType(Scrollable),
      );
      if (scrollable.evaluate().isNotEmpty) {
        final position =
            tester.state<ScrollableState>(scrollable.first).position;
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
      }

      final premium = tester.getRect(find.byType(HomeMasterPremium));
      final page = tester.getRect(find.byType(HomeMasterPage));
      final gap = page.bottom - premium.bottom;

      expect(gap, greaterThanOrEqualTo(AppLayout.navBarHeight));
      expect(
        gap,
        lessThanOrEqualTo(expectedClearance + 8),
        reason: 'gap must clear nav without the old double-count',
      );

      final bodyContext = tester.element(find.byType(HomeMasterBody));
      expect(
        HomeMasterBottomInset.resolve(bodyContext),
        lessThanOrEqualTo(expectedClearance + 1),
      );
    });
  }
}