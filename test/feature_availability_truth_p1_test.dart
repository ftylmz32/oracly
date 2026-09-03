/// Feature availability truth — registry is the single source for Home/Explore.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/preview_capability_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_module.dart';
import 'package:oracly_new/core/modules/oracly_feature_navigation.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/features/explore/presentation/explore_module_card.dart';
import 'package:oracly_new/features/explore/presentation/explore_reference_screen.dart';
import 'package:oracly_new/features/home/reference/home_reference_module_grid.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:oracly_new/features/home/reference/home_reference_scope.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const audited = <OraclyFeatureId>[
    OraclyFeatureId.dream,
    OraclyFeatureId.astrology,
    OraclyFeatureId.starMap,
  ];

  test('Dream Astrology StarMap are LIVE and reachable', () {
    for (final id in audited) {
      final module = OraclyFeatureRegistry.byId(id)!;
      expect(module.isLive, isTrue, reason: '$id');
      expect(module.isPreview, isFalse, reason: '$id');
      expect(module.isNavigable, isTrue, reason: '$id');
      expect(module.routeName, isNotNull, reason: '$id');
      expect(OraclyFeatureNavigation.canOpen(id), isTrue, reason: '$id');
    }
  });

  test('registry subtitles do not claim Preview for LIVE modules', () {
    for (final id in audited) {
      final sub = OraclyFeatureRegistry.byId(id)!.subtitle ?? '';
      expect(sub.toLowerCase(), isNot(contains('önizleme')), reason: '$id');
      expect(sub.toLowerCase(), isNot(contains('preview')), reason: '$id');
    }
  });

  test('Home tiles have no independent availability override', () {
    for (final spec in [
      ...HomeReferenceModules.list(),
      HomeReferenceModules.dreamExtension,
    ]) {
      final module = OraclyFeatureRegistry.byId(spec.id);
      expect(module, isNotNull, reason: '${spec.id}');
      expect(
        module!.isPreview,
        OraclyFeatureRegistry.byId(spec.id)!.isPreview,
      );
    }
  });

  testWidgets('Home presentation matches registry for audited modules', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final layout = HomeReferenceTokens.layoutFor(500);
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          home: Scaffold(
            body: HomeReferenceScope(
              layout: layout,
              child: const HomeReferenceModuleGrid(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(OraclyFeatureRegistry.byId(OraclyFeatureId.dream)!.isLive, isTrue);
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.astrology)!.isLive,
      isTrue,
    );
    expect(OraclyFeatureRegistry.byId(OraclyFeatureId.starMap)!.isLive, isTrue);
    expect(find.text(PreviewCapabilityCopy.badge), findsNothing);
    expect(find.text('Yeni'), findsOneWidget);
  });

  testWidgets('Explore presentation matches registry for audited modules', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: const MaterialApp(home: ExploreReferenceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final cards = tester
        .widgetList<ExploreModuleCard>(find.byType(ExploreModuleCard))
        .toList();
    for (final id in audited) {
      expect(cards.any((c) => c.featureId == id), isTrue, reason: '$id');
    }
    expect(
      find.descendant(
        of: find.byType(ExploreModuleCard),
        matching: find.text(PreviewCapabilityCopy.badge),
      ),
      findsNothing,
    );
  });

  test('no hard-coded preview status contradicts registry for audited set', () {
    for (final OraclyFeatureModule module in OraclyFeatureRegistry.all) {
      if (!audited.contains(module.id)) continue;
      expect(module.isPreview, isFalse);
      expect(module.isLive, isTrue);
    }
  });
}