/// Home Tarot tile — visible sixth discovery, real ritual entry.

library;



import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:oracly_new/core/data/datasources/local_storage.dart';

import 'package:oracly_new/core/l10n/l10n.dart';

import 'package:oracly_new/core/modules/oracly_feature_id.dart';

import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';

import 'package:oracly_new/features/home/reference/home_discovery_module_arts.dart';
import 'package:oracly_new/features/home/reference/home_reference_module_grid.dart';

import 'package:oracly_new/features/home/reference/home_reference_modules.dart';

import 'package:oracly_new/features/home/reference/home_reference_scope.dart';

import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';

import 'package:oracly_new/features/tarot/navigation/tarot_module_navigator.dart';

import 'package:oracly_new/features/tarot/presentation/screens/tarot_home_screen.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';

import 'package:shared_preferences/shared_preferences.dart';



import '../../test_helpers/provider_scope_harness.dart';



void main() {

  TestWidgetsFlutterBinding.ensureInitialized();



  setUp(() => OraclyL10n.bind('tr'));



  test('tarot tile copy is localized', () {

    expect(HomeDiscoveryCopy.title(OraclyFeatureId.tarot), 'Tarot');

    expect(

      HomeDiscoveryCopy.caption(OraclyFeatureId.tarot),

      'Bir kart, bir an',

    );

    OraclyL10n.bind('en');

    expect(HomeDiscoveryCopy.title(OraclyFeatureId.tarot), 'Tarot');

    OraclyL10n.bind('ru');

    expect(HomeDiscoveryCopy.title(OraclyFeatureId.tarot), 'Таро');

    OraclyL10n.bind('tr');

  });



  test('tarot is the sixth Home discovery door', () {
    final modules = HomeReferenceModules.list();
    expect(modules, hasLength(6));
    expect(modules[5].id, OraclyFeatureId.tarot);
    expect(HomeReferenceModules.dreamExtension.id, OraclyFeatureId.dream);
    expect(HomeDiscoveryCopy.title(OraclyFeatureId.tarot), 'Tarot');
    expect(HomeDiscoveryCopy.title(OraclyFeatureId.dream), 'Rüya Analizi');
  });



  testWidgets('Home opens with the Tarot tile', (tester) async {

    await tester.binding.setSurfaceSize(const Size(390, 844));

    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});

    final storage = await LocalStorage.open();

    final layout = HomeReferenceTokens.layoutFor(640);

    await tester.pumpWidget(

      buildProviderScopeHarness(

        storage: storage,

        child: MaterialApp(

          home: Scaffold(

            body: SizedBox(

              height: layout.gridSlotHeight,

              child: HomeReferenceScope(

                layout: layout,

                child: const HomeReferenceModuleGrid(),

              ),

            ),

          ),

        ),

      ),

    );

    await tester.pump();

    expect(find.text('Kahve Falı'), findsOneWidget);

    expect(find.text('Tarot'), findsOneWidget);

    expect(find.text(HomeDiscoveryCopy.caption(OraclyFeatureId.tarot)), findsNothing);

    expect(find.byType(HomeDiscoveryModuleArt), findsNWidgets(7));

    expect(tester.takeException(), isNull);

  });



  testWidgets('tap Tarot opens the real tarot screen', (tester) async {

    await tester.binding.setSurfaceSize(const Size(390, 844));

    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});

    final storage = await LocalStorage.open();

    final layout = HomeReferenceTokens.layoutFor(640);

    await tester.pumpWidget(

      buildProviderScopeHarness(

        storage: storage,

        child: MaterialApp(

          home: Scaffold(

            body: SizedBox(

              height: layout.gridSlotHeight,

              child: HomeReferenceScope(

                layout: layout,

                child: const HomeReferenceModuleGrid(),

              ),

            ),

          ),

        ),

      ),

    );

    await tester.pump();

    await tester.tap(find.text('Tarot'));

    await tester.pump();

    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TarotModuleNavigator), findsOneWidget);

    expect(find.byType(TarotHomeScreen), findsOneWidget);

    final scoped = tester.element(find.byType(TarotHomeScreen));

    expect(TarotScope.maybeOf(scoped), isNotNull);

  });

}


