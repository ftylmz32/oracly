/// Phase 10 — Home discovery → named route matrix + Tarot route smoke.
/// REAL PROVIDER CALLS = 0. Production unmodified.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Home 3×2 doors map to distinct live destinations', () {
    final expected = <OraclyFeatureId, String>{
      OraclyFeatureId.coffee: OraclyRoutes.coffee,
      OraclyFeatureId.palm: OraclyRoutes.palm,
      OraclyFeatureId.astrology: OraclyRoutes.astrology,
      OraclyFeatureId.starMap: OraclyRoutes.starMap,
      OraclyFeatureId.tarot: OraclyRoutes.tarot,
    };
    final doors = HomeReferenceModules.list();
    expect(doors.map((d) => d.id), containsAll(expected.keys));
    for (final entry in expected.entries) {
      final module = OraclyFeatureRegistry.byId(entry.key)!;
      expect(module.isLive, isTrue);
      expect(module.routeName, entry.value);
      // No door routes into another feature's path.
      for (final other in expected.entries) {
        if (other.key == entry.key) continue;
        expect(module.routeName, isNot(other.value));
      }
    }
    final soul = OraclyFeatureRegistry.byId(OraclyFeatureId.soulMate)!;
    expect(soul.requiresPremium, isTrue);
    expect(doors.map((d) => d.id), contains(OraclyFeatureId.soulMate));
    expect(
      HomeReferenceModules.dreamExtension.id,
      OraclyFeatureId.dream,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.dream)?.routeName,
      OraclyRoutes.dream,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.aiChat)?.routeName,
      OraclyRoutes.chat,
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.premium)?.routeName,
      OraclyRoutes.premium,
    );
  });

  testWidgets('Tarot named route builds without FlutterError', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final errors = <Object>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.exception);
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(OraclyRoutes.tarot),
              child: const Text('go-tarot'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go-tarot'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(errors, isEmpty, reason: 'tarot route threw $errors');
  });
}
