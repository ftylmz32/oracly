/// HOME asset reality — live Home must mount real artwork, not placeholders.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/constants/app_assets.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/home/master/home_master_page.dart';
import 'package:oracly_new/features/home/reference/home_discovery_module_arts.dart';
import 'package:oracly_new/features/home/reference/home_reference_hero_plate.dart';
import 'package:oracly_new/features/home/reference/home_reference_or_flagship.dart';
import 'package:oracly_new/features/home/reference/home_reference_premium_card.dart';
import 'package:oracly_new/shared/widgets/oracly_asset_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(360, 640),
              padding: EdgeInsets.only(top: 24, bottom: 34),
            ),
            child: HomeMasterPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('live Home mounts hero / OR / discovery / premium art assets',
      (tester) async {
    await pumpHome(tester);
    expect(tester.takeException(), isNull);

    expect(find.byType(HomeReferenceHeroPlate), findsOneWidget);
    expect(find.byType(HomeReferenceOrFlagship), findsOneWidget);
    expect(find.byType(HomeDiscoveryModuleArt), findsNWidgets(7));
    expect(find.byType(HomeReferencePremiumCard), findsOneWidget);

    final images = tester
        .widgetList<OraclyAssetImage>(find.byType(OraclyAssetImage))
        .toList();
    final paths = images.map((i) => i.assetPath).toSet();

    expect(paths, contains(AppAssets.homeHeroMoon));
    expect(paths, contains(AppAssets.homeOrGuide));
    expect(paths, contains(AppAssets.homeCoffee));
    expect(paths, contains(AppAssets.homePalm));
    expect(paths, contains(AppAssets.homeAstrology));
    expect(paths, contains(AppAssets.homeYildizname));
    expect(paths, contains(AppAssets.homeSoulMate));
    expect(paths, contains(AppAssets.homeTarot));
    expect(paths, contains(AppAssets.homeDream));
    expect(paths, contains(AppAssets.homePremium));

    expect(find.byType(ListView), findsNothing);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
