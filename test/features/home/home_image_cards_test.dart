/// Home image-first cards — six discovery doors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/reference/home_discovery_module_arts.dart';
import 'package:oracly_new/features/home/reference/home_reference_module_grid.dart';
import 'package:oracly_new/features/home/reference/home_reference_module_tile.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:oracly_new/features/home/reference/home_reference_scope.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('grid shows six discovery doors with cinematic art', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
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

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeReferenceModuleTile), findsNWidgets(7));
    expect(find.text('Önizleme'), findsNothing);
    expect(find.text('Kahve Falı'), findsOneWidget);
    expect(find.text('El Falı'), findsOneWidget);
    expect(find.text('Astroloji'), findsOneWidget);
    expect(find.text('Yıldızname'), findsOneWidget);
    expect(find.text('Ruh Eşi'), findsOneWidget);
    expect(find.text('Tarot'), findsOneWidget);
    expect(find.text('Rüya Analizi'), findsOneWidget);
    expect(find.text('PREMIUM'), findsNothing);
    expect(find.byType(HomeDiscoveryModuleArt), findsNWidgets(7));
    expect(
      find.text(HomeDiscoveryCopy.caption(HomeReferenceModules.list().first.id)),
      findsNothing,
    );
  });
}
