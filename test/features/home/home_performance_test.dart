/// HOME 16 — Home performance floors (decode, atmosphere, quiet motion).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/brand/oracly_brand_mark.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/design_system/oracly_cosmic_background.dart';
import 'package:oracly_new/core/theme/oracly_quiet_motion.dart';
import 'package:oracly_new/features/home/master/home_master_body.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/reference/home_discovery_module_arts.dart';
import 'package:oracly_new/features/home/reference/home_module_visual.dart';
import 'package:oracly_new/shared/widgets/oracly_asset_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(
    WidgetTester tester, {
    Size size = const Size(360, 640),
    double dpr = 2.0,
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
              devicePixelRatio: dpr,
              padding: const EdgeInsets.only(top: 24, bottom: 34),
            ),
            child: const HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('Home mounts a single cosmic atmosphere (no duplicate stacks)',
      (tester) async {
    await pumpHome(tester);
    expect(find.byType(OraclyCosmicBackground), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('master Home keeps modest decoded asset count', (tester) async {
    await pumpHome(tester);
    final images = tester.widgetList<OraclyAssetImage>(
      find.byType(OraclyAssetImage),
    );
    // Brand mark + daily ritual plate (no 6-tile cinematic decode on live grid).
    expect(images.length, lessThanOrEqualTo(12));
    for (final image in images) {
      expect(image.cacheCapPx, lessThanOrEqualTo(1600));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('header brand mark decodes near display size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(360, 640), devicePixelRatio: 2),
          child: Scaffold(
            body: Center(child: OraclyBrandMark(size: 24)),
          ),
        ),
      ),
    );
    await tester.pump();
    final image = tester.widget<OraclyAssetImage>(find.byType(OraclyAssetImage));
    // 24 * 2 * 1.25 = 60 — far below legacy fixed 384/512 header decode.
    expect(image.cacheCapPx, lessThanOrEqualTo(96));
    expect(image.filterQuality, FilterQuality.high);
  });

  testWidgets('master Home keeps RepaintBoundary on art plates', (tester) async {
    await pumpHome(tester);
    final body = find.descendant(
      of: find.byType(HomeMasterBody),
      matching: find.byType(RepaintBoundary),
    );
    expect(body, findsAtLeastNWidgets(2));
  });

  testWidgets('discovery tile library keeps modest decode caps', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 110,
            height: 110,
            child: HomeDiscoveryModuleArt(visual: HomeModuleVisual.coffee),
          ),
        ),
      ),
    );
    await tester.pump();
    final images = tester.widgetList<OraclyAssetImage>(
      find.byType(OraclyAssetImage),
    );
    expect(images, isNotEmpty);
    for (final image in images) {
      expect(image.cacheCapPx, lessThanOrEqualTo(640));
      expect(image.filterQuality, isNot(FilterQuality.high));
    }
  });

  testWidgets('KN8-class Home is treated as constrained quiet motion',
      (tester) async {
    await pumpHome(tester, dpr: 2.0);
    final ctx = tester.element(find.byType(HomeMasterPage));
    expect(OraclyQuietMotion.constrained(ctx), isTrue);
    expect(OraclyQuietMotion.still(ctx), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home pump stays exception-free on fixed viewport',
      (tester) async {
    await pumpHome(tester);
    expect(find.byType(ListView), findsNothing);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
