/// P0-05 — live Dream / Astrology / Yıldızname show preview capability.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/preview_capability_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/universe/oracly_tab_labels.dart';
import 'package:oracly_new/core/navigation/universe/universe_navigation_copy.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_kind_note.dart';
import 'package:oracly_new/features/birth_chart/copy/birth_chart_copy.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/presentation/reference/dream_reference_intro.dart';
import 'package:oracly_new/features/home/reference/home_reference_module_grid.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:oracly_new/features/home/reference/home_reference_scope.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('preview modules are labeled Önizleme, not complete engines', () {
    expect(PreviewCapabilityCopy.badge, 'Önizleme');
    expect(DreamCopy.previewNote, contains('Önizleme'));
    expect(DreamCopy.previewNote.toLowerCase(), contains('katalog'));
    expect(DreamCopy.previewNoteLive.toLowerCase(), isNot(contains('önizleme')));
    expect(DreamCopy.previewNoteLive.toLowerCase(), contains('or'));
    expect(DreamCopy.previewNoteLive.toLowerCase(), isNot(contains('katalog')));
    expect(DreamCopy.previewNoteNeedsOr, contains('Önizleme'));
    expect(
      DreamCopy.previewNoteNeedsOr.toLowerCase(),
      isNot(contains('katalog')),
    );
    expect(DreamCopy.entryDescription, contains('Önizleme'));
    expect(DreamReferenceIntro.copy, contains('Önizleme'));
    expect(AstrologyReferenceKindNote.label, 'Önizleme');
    expect(AstrologyReferenceKindNote.detail, contains('yansıma'));
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), isNot(contains('katalog')));
    expect(StarMapPolishCopy.whatItIs, startsWith('Güneş burcuna göre'));
    expect(StarMapPolishCopy.capabilityNote, contains('Güneş burcuna göre'));
    expect(StarMapPolishCopy.capabilityNote.toLowerCase(), isNot(contains('hesaplanmaz')));
    expect(BirthChartCopy.previewBadge, 'Önizleme');
    expect(BirthChartCopy.capabilityNote, contains('Güneş burcuna göre'));
    expect(BirthChartCopy.onboardingDescription, startsWith('Önizleme'));
    expect(BirthChartCopy.ephemerisNote, startsWith('Önizleme'));
    expect(OraclyTab.astrology.universeHint, contains('Önizleme'));
    expect(OraclyTab.starMap.universeHint.toLowerCase(), contains('yerel'));
    expect(OraclyTab.starMap.universeHint.toLowerCase(), isNot(contains('önizleme')));
    expect(
      UniverseNavigationCopy.bandUnderstandHint.toLowerCase(),
      contains('önizleme'),
    );
    expect(
      UniverseNavigationCopy.realmUnderstandHint.toLowerCase(),
      contains('önizleme'),
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.dream)?.subtitle,
      contains('Önizleme'),
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.astrology)?.subtitle,
      contains('Önizleme'),
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.starMap)!.subtitle!.toLowerCase(),
      contains('yerel'),
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.starMap)!.subtitle!.toLowerCase(),
      isNot(contains('önizleme')),
    );
  });

  test('home grid includes Kahve; preview honesty stays on feature screens', () {
    expect(
      HomeReferenceModules.list()
          .map((m) => HomeDiscoveryCopy.title(m.id)),
      contains('Kahve Falı'),
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.dream)?.subtitle,
      contains('Önizleme'),
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.astrology)?.subtitle,
      contains('Önizleme'),
    );
    expect(
      OraclyFeatureRegistry.byId(OraclyFeatureId.starMap)!.subtitle!.toLowerCase(),
      contains('yerel'),
    );
  });

  testWidgets('Home grid shows Önizleme on catalogue tiles', (tester) async {
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

    // Visual master Home: no Önizleme chrome on cinematic cards.
    expect(find.text(PreviewCapabilityCopy.badge), findsNothing);
    expect(find.text('Kahve Falı'), findsOneWidget);
    expect(find.textContaining('El'), findsWidgets);
    expect(find.text('Tarot'), findsOneWidget);
    expect(find.textContaining('Ruh'), findsWidgets);
  });
}
