/// KN8 responsive + accessibility floors for master Home.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/accessibility/oracly_a11y.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/features/home/master/home_master_hero.dart';
import 'package:oracly_new/features/home/master/home_master_or.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/master/home_master_premium.dart';
import 'package:oracly_new/features/home/master/home_master_today.dart';
import 'package:oracly_new/features/home/reference/home_reference_or_flagship.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester, {
    Size size = const Size(360, 640),
    double textScale = 1.0,
    bool disableAnimations = false,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              padding: const EdgeInsets.only(top: 24, bottom: 34),
              textScaler: TextScaler.linear(textScale),
              disableAnimations: disableAnimations,
            ),
            child: const HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('KN8 portrait - no overflow on core Home surfaces',
      (tester) async {
    await pumpHome(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeMasterHero), findsOneWidget);
    expect(find.byType(HomeMasterOr), findsOneWidget);
    expect(find.text(HomeMasterToday.label), findsOneWidget);
    expect(find.textContaining('Kahve'), findsWidgets);
    expect(find.byType(HomeMasterPremium), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text scale 1.3 on KN8 - no overflow, CTAs remain',
      (tester) async {
    await pumpHome(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeMasterOr), findsOneWidget);
    final orSize = tester.getSize(find.byType(HomeMasterOr));
    expect(orSize.height, greaterThanOrEqualTo(OraclyA11y.minTouchTarget));
    expect(orSize.width, greaterThanOrEqualTo(OraclyA11y.minTouchTarget));
  });

  testWidgets('large phone - Home stack stays calm', (tester) async {
    await pumpHome(tester, size: const Size(430, 932));
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeMasterHero), findsOneWidget);
  });

  testWidgets('reduced motion keeps Home interactive', (tester) async {
    await pumpHome(tester, disableAnimations: true);
    expect(tester.takeException(), isNull);
    expect(find.byType(HomeMasterOr), findsOneWidget);
    expect(find.text(HomeReferenceOrFlagship.cta), findsOneWidget);
  });

  testWidgets('long Turkish discovery titles remain present at text scale 1.3',
      (tester) async {
    await pumpHome(tester, textScale: 1.3);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Kahve'), findsWidgets);
    expect(find.textContaining('Astroloji'), findsWidgets);
    expect(find.textContaining('Tarot'), findsWidgets);
    expect(find.byType(HomeMasterPremium), findsOneWidget);
  });
}
