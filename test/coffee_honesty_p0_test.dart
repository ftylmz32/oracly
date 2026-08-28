/// P0/P1 — Coffee vision honesty: no fake interpretation without proxy.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/preview_capability_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/features/home/reference/home_reference_module_grid.dart';
import 'package:oracly_new/features/home/copy/home_discovery_copy.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:oracly_new/features/home/reference/home_reference_scope.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Home Kahve tile is live entry; vision honesty stays in Coffee copy', () {
    expect(
      HomeReferenceModules.list().map((m) => HomeDiscoveryCopy.title(m.id)),
      contains('Kahve Falı'),
    );
    expect(CoffeeCopy.previewBadge, PreviewCapabilityCopy.badge);
    expect(CoffeeCopy.capabilityNote.toLowerCase(), contains('or'));
    expect(CoffeeCopy.capabilityNote.toLowerCase(), isNot(contains('önizleme')));
    expect(CoffeeCopy.landingLine, 'Masa hazır. Fincan hâlâ sıcak.');
    expect(CoffeeCopy.analyzeCta, 'FALIMI YORUMLA');
  });

  test('unavailable vision never invents a coffee reading', () async {
    expect(const UnavailableCoffeeAnalysis().isAvailable, isFalse);
    expect(
      () => const UnavailableCoffeeAnalysis().analyze(
        const CoffeeImagePick(path: 'cup.jpg'),
      ),
      throwsA(isA<CoffeeAnalysisException>()),
    );
    expect(
      CoffeeCopy.analysisUnavailable.toLowerCase(),
      contains('hazırlanamadı'),
    );
  });

  testWidgets('Home grid hosts KAHVE tile', (tester) async {
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
    expect(find.text('Kahve Falı'), findsOneWidget);
    expect(find.text('Tarot'), findsOneWidget);
    expect(find.text('PREMIUM'), findsNothing);
  });

  testWidgets('gallery opens capture; CTA enabled without permanent lock',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      _coffeeApp(storage, images: const _FakeCoffeeImages(path: 'cup.jpg')),
    );
    await tester.pump();

    await tester.tap(find.text(CoffeeCopy.galleryLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(CoffeeCopy.usePhotoLabel), findsOneWidget);
    expect(find.text(CoffeeCopy.analysisUnavailable), findsNothing);
  });

  testWidgets('available vision can enter capture via gallery', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      _coffeeApp(
        storage,
        analysis: const _LiveCoffeeAnalysis(),
        images: const _FakeCoffeeImages(path: 'cup.jpg'),
      ),
    );
    await tester.pump();

    await tester.tap(find.text(CoffeeCopy.galleryLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text(CoffeeCopy.usePhotoLabel), findsOneWidget);
  });
}

Widget _coffeeApp(
  LocalStorage storage, {
  CoffeeAnalysisPort? analysis,
  CoffeeImageInputPort? images,
}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      coffeeAnalysisProvider.overrideWithValue(
        analysis ?? const UnavailableCoffeeAnalysis(),
      ),
      if (images != null) coffeeImageInputProvider.overrideWithValue(images),
    ],
    child: const MaterialApp(home: CoffeeReferenceScreen()),
  );
}

class _LiveCoffeeAnalysis implements CoffeeAnalysisPort {
  const _LiveCoffeeAnalysis();

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    throw StateError('capture-only test');
  }
}

class _FakeCoffeeImages implements CoffeeImageInputPort {
  const _FakeCoffeeImages({required this.path});
  final String path;

  @override
  bool get cameraAvailable => true;

  @override
  bool get galleryAvailable => true;

  @override
  Future<CoffeeImagePick?> pickFromCamera() async => CoffeeImagePick(path: path);

  @override
  Future<CoffeeImagePick?> pickFromGallery() async =>
      CoffeeImagePick(path: path);
}
