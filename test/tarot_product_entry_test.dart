/// Tarot product entry — live module, not on Home 3×2, ritual host mounted.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_navigation_service.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:oracly_new/features/tarot/navigation/tarot_module_navigator.dart';
import 'package:oracly_new/features/tarot/presentation/screens/tarot_home_screen.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  test('tarot is live on the Home discovery doors', () {
    final module = OraclyFeatureRegistry.byId(OraclyFeatureId.tarot);
    expect(module?.isLive, isTrue);
    expect(module?.routeName, OraclyRoutes.tarot);
    final doors = HomeReferenceModules.list();
    expect(doors.map((m) => m.id), contains(OraclyFeatureId.tarot));
    expect(doors, hasLength(7));
    expect(doors.last.id, OraclyFeatureId.dream);
    expect(
      HomeDiscoveryCopy.title(OraclyFeatureId.tarot),
      'Tarot',
    );
  });

  test('named /tarot route mounts the completed ritual host', () {
    final route = OraclyRouteGenerator.onGenerateRoute(
      const RouteSettings(name: OraclyRoutes.tarot),
    );
    expect(route, isNotNull);
    expect(
      OraclyRouteGenerator.onGenerateRoute(
        const RouteSettings(name: OraclyRoutes.palm),
      ),
      isNotNull,
    );
  });

  testWidgets('opening tarot from outside Home wraps ritual scope',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => OraclyNavigationService.startTarotFlow(context),
              child: const Text('open-tarot'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-tarot'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TarotModuleNavigator), findsOneWidget);
    expect(find.byType(TarotHomeScreen), findsOneWidget);
    final scoped = tester.element(find.byType(TarotHomeScreen));
    expect(TarotScope.maybeOf(scoped), isNotNull);
  });
}
