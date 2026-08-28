/// Phase 5 — El Falı navigation, pick, preview. On Home 3×2 discovery grid.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/modules/oracly_feature_id.dart';
import 'package:oracly_new/core/modules/oracly_feature_registry.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/home/reference/home_reference_modules.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_view.dart';
import 'package:oracly_new/features/palm/providers/palm_providers.dart';
import 'package:oracly_new/features/palm/services/unavailable_palm_analysis.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('palm_flow_');
    PathProviderPlatform.instance = _FlowPathProvider(temp.path);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('feature is live on the Home 3x2 discovery grid', () {
    final module = OraclyFeatureRegistry.byId(OraclyFeatureId.palm);
    expect(module?.isLive, isTrue);
    expect(module?.routeName, OraclyRoutes.palm);
    expect(
      HomeReferenceModules.list().map((m) => m.id),
      contains(OraclyFeatureId.palm),
    );
  });

  testWidgets('landing offers camera, gallery, and hand choice', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(_app(storage));
    await tester.pump();

    expect(find.text(PalmCopy.screenTitle), findsOneWidget);
    expect(find.text(PalmCopy.landingLine), findsOneWidget);
    expect(find.text(PalmCopy.landingCameraLabel), findsOneWidget);
    expect(find.text(PalmCopy.galleryLabel), findsOneWidget);
    expect(find.text(PalmCopy.rightHand), findsOneWidget);
    expect(find.text(PalmCopy.leftHand), findsOneWidget);
    expect(find.text('KAHVE FALI'), findsNothing);
  });

  testWidgets('gallery pick opens preview and enables analyze CTA',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(_app(storage));
    await tester.pump();

    final controller = ProviderScope.containerOf(
      tester.element(find.byType(PalmReferenceScreen)),
    ).read(palmReadingControllerProvider);
    controller.startCapture();
    await tester.pump();
    expect(find.text(PalmCopy.addPhotoTitle), findsOneWidget);

    // Avoid Image.file decode (hangs under Windows widget tests).
    controller.debugSetImageForTest(
      const CoffeeImagePick(path: 'no_such_palm.jpg', mimeType: 'image/jpeg'),
    );
    expect(controller.image, isNotNull);
    await tester.pump(const Duration(milliseconds: 16));

    expect(find.text(PalmCopy.previewLabel), findsOneWidget);
    expect(find.text(PalmCopy.usePhotoLabel), findsOneWidget);
    final cta = tester.widget<OraclyGoldButton>(
      find.byType(OraclyGoldButton),
    );
    expect(cta.onPressed, isNotNull);
  });

  testWidgets('analyze stays disabled without photo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(_app(storage, images: const _SilentPalmImages()));
    await tester.pump();
    ProviderScope.containerOf(tester.element(find.byType(PalmReferenceScreen)))
        .read(palmReadingControllerProvider)
        .startCapture();
    await tester.pump();

    expect(find.text(PalmCopy.analyzeCta), findsNothing);
    expect(find.text(PalmCopy.captureGuide), findsOneWidget);
  });

  testWidgets('result shows the hand story and only observed line asides',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PalmResultView(
              reading: PalmReading(
                id: 'palm-1',
                createdAt: DateTime(2026, 8, 15),
                hand: PalmHand.right,
                overall: 'Avuç açık ve sakin duruyor.',
                heartLine: 'Kalp çizgisi yakınlık temasını taşıyor.',
                headLine: 'Zihin çizgisi net bir ritim okutuyor.',
                lifeLine: 'Yaşam çizgisi dengeli görünüyor.',
                fateLine: 'Yön teması bir sapmayı ima ediyor.',
                symbols: const ['yıldız'],
              ),
              onNewPalm: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(PalmCopy.overallTitle), findsOneWidget);
    expect(find.text(PalmCopy.heartTitle), findsOneWidget);
    expect(find.text(PalmCopy.headTitle), findsOneWidget);
    expect(find.text(PalmCopy.lifeTitle), findsOneWidget);
    expect(find.text(PalmCopy.fateTitle), findsOneWidget);
    expect(find.text(PalmCopy.symbolsTitle), findsOneWidget);
    expect(find.textContaining('Avuç açık ve sakin duruyor.'), findsOneWidget);
    expect(find.textContaining('Kalp çizgisi yakınlık temasını taşıyor.'), findsOneWidget);
    expect(
      find.text(PalmCopy.disclaimer, skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('empty palm asides stay out of the reading', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PalmResultView(
              reading: PalmReading(
                id: 'palm-2',
                createdAt: DateTime(2026, 8, 15),
                hand: PalmHand.left,
                overall: 'Sadece genel yapı geldi.',
              ),
              onNewPalm: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(PalmCopy.overallTitle), findsOneWidget);
    expect(find.text(PalmCopy.heartTitle), findsNothing);
    expect(find.text(PalmCopy.headTitle), findsNothing);
    expect(find.text(PalmCopy.lifeTitle), findsNothing);
    expect(find.text(PalmCopy.fateTitle), findsNothing);
    expect(find.text(PalmCopy.symbolsTitle), findsNothing);
    expect(find.textContaining('Sadece genel yapı geldi.'), findsOneWidget);
    expect(
      find.text(PalmCopy.disclaimer, skipOffstage: false),
      findsOneWidget,
    );
  });

  const viewports = <Size>[
    Size(360, 800),
    Size(375, 812),
    Size(390, 844),
    Size(411, 901),
    Size(430, 932),
    Size(600, 960),
  ];

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
      expect(find.text(PalmCopy.screenTitle), findsOneWidget);
      expect(find.text(PalmCopy.galleryLabel), findsOneWidget);
      expect(
        tester.getRect(find.text(PalmCopy.galleryLabel)).bottom,
        lessThanOrEqualTo(size.height),
      );
    });
  }

  test('unavailable analysis never invents a palm reading', () async {
    const port = UnavailablePalmAnalysis();
    expect(port.isAvailable, isFalse);
    expect(
      () => port.analyze(
        const CoffeeImagePick(path: 'palm.jpg'),
        hand: PalmHand.right,
      ),
      throwsA(isA<Exception>()),
    );
  });
}

Widget _app(LocalStorage storage, {CoffeeImageInputPort? images}) {
  return ProviderScope(
    overrides: [
      localStorageProvider.overrideWithValue(storage),
      palmAnalysisProvider.overrideWithValue(const UnavailablePalmAnalysis()),
      if (images != null) coffeeImageInputProvider.overrideWithValue(images),
    ],
    child: const MaterialApp(home: PalmReferenceScreen()),
  );
}

class _FakePalmImages implements CoffeeImageInputPort {
  _FakePalmImages({required this.path});
  final String path;

  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async =>
      CoffeeImagePick(path: path, mimeType: 'image/jpeg');
  @override
  Future<CoffeeImagePick?> pickFromGallery() async =>
      CoffeeImagePick(path: path, mimeType: 'image/jpeg');
}

class _SilentPalmImages implements CoffeeImageInputPort {
  const _SilentPalmImages();
  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}

class _FlowPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FlowPathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
}
