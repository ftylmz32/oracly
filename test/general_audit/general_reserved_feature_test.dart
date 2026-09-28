/// G0 — reserved features (Achievements, Numerology, Moon Calendar,
/// Manifestation) never surface as a working promise or open a screen.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/modules/oracly_feature_navigation.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_navigator_key.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/universe/oracly_universe_realm.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(AccountDeletionPendingState.markClear);

  final reserved = OraclyFeatureRegistry.reserved.map((m) => m.id).toSet();

  test('Home bands and Universe realms list live modules only', () {
    for (final band in ['explore', 'reflect', 'understand']) {
      for (final m in OraclyFeatureRegistry.forHomeBand(band)) {
        expect(reserved.contains(m.id), isFalse, reason: '$band ${m.id}');
      }
    }
    for (final realm in OraclyUniverseRealm.values) {
      for (final m in OraclyFeatureRegistry.forRealm(realm)) {
        expect(reserved.contains(m.id), isFalse, reason: '$realm ${m.id}');
      }
    }
  });

  testWidgets('opening a reserved module pushes nothing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: await LocalStorage.open(),
        child: MaterialApp(
          navigatorKey: oraclyNavigatorKey,
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: const SizedBox.shrink(),
        ),
      ),
    );
    final ctx = oraclyNavigatorKey.currentContext!;
    for (final id in reserved) {
      OraclyFeatureNavigation.open(ctx, id);
      await tester.pump(const Duration(milliseconds: 200));
      expect(oraclyNavigatorKey.currentState!.canPop(), isFalse,
          reason: id.name);
    }
  });

  test('legacy reserved surfaces stay unreachable from live code', () {
    const legacy = [
      'AchievementsScreen(',
      'ProfileMenuSection(',
      'ProfileReferenceAchievementsSection(',
    ];
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      for (final name in legacy) {
        final decl = 'const ${name.substring(0, name.length - 1)}({';
        if (src.contains(name) && !src.contains(decl)) hits.add(f.path);
      }
    }
    expect(hits, isEmpty);
  });
}
