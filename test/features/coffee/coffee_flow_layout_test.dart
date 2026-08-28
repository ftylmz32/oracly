/// Kahve Falı flow — pick, preview gate, loading, unavailable, layout.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_loading_view.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const viewports = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

  testWidgets('analyze stays disabled without photo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      _app(
        storage,
        analysis: const _LiveCoffeeAnalysis(),
        images: const _SilentCoffeeImages(),
      ),
    );
    await tester.pump();

    ProviderScope.containerOf(tester.element(find.byType(CoffeeReferenceScreen)))
        .read(coffeeReadingControllerProvider)
        .startCapture();
    await tester.pump();

    // CTA only appears after a photo is selected.
    expect(find.text(CoffeeCopy.usePhotoLabel), findsNothing);
  });

  testWidgets('gallery preview enables CTA even when vision unavailable',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();

    await tester.pumpWidget(
      _app(storage, images: const _FakeCoffeeImages(path: 'missing_cup.jpg')),
    );
    await tester.pump();
    await tester.tap(find.text(CoffeeCopy.galleryLabel));
    await tester.pump();

    expect(find.text(CoffeeCopy.usePhotoLabel), findsOneWidget);

    final cta = tester.widget<OraclyGoldButton>(
      find.byType(OraclyGoldButton),
    );
    expect(cta.onPressed, isNotNull);
  });

  test('analyze enters loading then honest unavailable', () async {
    SharedPreferences.setMockInitialValues({});
    final gate = Completer<void>();
    final controller = CoffeeReadingController(
      experience: _GatedExperience(
        store: CoffeeReadingStore(
          LocalStorage(await SharedPreferences.getInstance()),
        ),
        gate: gate,
      ),
      images: const _FakeCoffeeImages(path: 'cup.jpg'),
    );
    controller.startCapture();
    await controller.pickGallery();
    final pending = controller.analyze();
    expect(controller.phase, CoffeePhase.analyzing);
    await controller.analyze();
    expect(controller.phase, CoffeePhase.analyzing);
    gate.complete();
    await pending;
    expect(controller.phase, CoffeePhase.error);
    expect(controller.errorMessage, CoffeeCopy.analysisUnavailable);
  });

  testWidgets('loading copy appears while analyzing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoffeeLoadingView(message: CoffeeCopy.analyzing),
        ),
      ),
    );
    expect(find.text(CoffeeCopy.analyzing), findsOneWidget);
  });

  testWidgets('back from capture returns to landing', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      _app(storage, images: const _SilentCoffeeImages()),
    );
    await tester.pump();
    ProviderScope.containerOf(tester.element(find.byType(CoffeeReferenceScreen)))
        .read(coffeeReadingControllerProvider)
        .startCapture();
    await tester.pump();
    expect(find.text(CoffeeCopy.hubLead), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    expect(find.text(CoffeeCopy.hubLead), findsOneWidget);
  });

  for (final size in viewports) {
    testWidgets(
        'landing fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: _app(storage),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(CoffeeCopy.photoCta), findsOneWidget);
      expect(find.text(CoffeeCopy.hubLead), findsOneWidget);
      expect(find.text(CoffeeCopy.galleryLabel), findsOneWidget);
      expect(find.text(CoffeeCopy.ritualTease), findsNothing);
    });

    testWidgets(
        'capture fits ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: _app(storage, images: const _SilentCoffeeImages()),
        ),
      );
      await tester.pump();
      ProviderScope.containerOf(
        tester.element(find.byType(CoffeeReferenceScreen)),
      ).read(coffeeReadingControllerProvider).startCapture();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(CoffeeCopy.photoCta), findsOneWidget);
      expect(find.text(CoffeeCopy.hubLead), findsNothing);
      expect(find.text(CoffeeCopy.usePhotoLabel), findsNothing);
    });

    testWidgets(
        'photo CTA visible ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: _app(
            storage,
            analysis: const _LiveCoffeeAnalysis(),
            images: const _FakeCoffeeImages(path: 'cup.jpg'),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(CoffeeCopy.galleryLabel));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(CoffeeCopy.usePhotoLabel), findsOneWidget);
      expect(
        tester.getRect(find.text(CoffeeCopy.usePhotoLabel)).bottom,
        lessThanOrEqualTo(size.height),
      );
    });
  }
}

Widget _app(
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

class _GatedExperience extends CoffeeExperienceService {
  _GatedExperience({
    required CoffeeReadingStore store,
    required this.gate,
  }) : super(store: store, analysis: const _LiveCoffeeAnalysis());

  final Completer<void> gate;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    await gate.future;
    throw CoffeeAnalysisException(CoffeeCopy.analysisUnavailable);
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

class _SilentCoffeeImages implements CoffeeImageInputPort {
  const _SilentCoffeeImages();
  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}

class _LiveCoffeeAnalysis implements CoffeeAnalysisPort {
  const _LiveCoffeeAnalysis();
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    throw StateError('not used');
  }
}
