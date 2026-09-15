/// Coffee Retry reuses current valid image; missing image returns to capture.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_body.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

class _FailAnalysis implements CoffeeAnalysisPort {
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    throw CoffeeAnalysisException(CoffeeCopy.analysisFailed);
  }
}

class _FakeImages implements CoffeeImageInputPort {
  const _FakeImages(this.path);
  final String path;
  @override
  bool get cameraAvailable => false;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => CoffeeImagePick(path: path);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `_analyzeLive` stages real image bytes (`File(image.path).readAsBytes()`)
  // before calling `live.submit`, and a real fixture file makes
  // CoffeeImageIntake take its real-normalization path (needs
  // path_provider) instead of short-circuiting on a missing file — so any
  // test that reaches analyze() needs both a real file on disk and a faked
  // PathProviderPlatform. Mirrors the fixture pattern already used by
  // coffee_cancel_analysis_test.dart et al.
  late Directory tempDir;
  late String fixturePath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('coffee_retry_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    final sample = File('test/features/palm/fixtures/palm_sample.jpg');
    fixturePath = '${tempDir.path}/cup.jpg';
    await sample.copy(fixturePath);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  // Real file IO (image read + normalization) doesn't resolve inside
  // `testWidgets`'s fake-async zone unless it runs via `tester.runAsync` —
  // without it, `await failedController()` hangs until the suite's outer
  // real-time timeout fires. Callers below must invoke this through
  // `tester.runAsync(failedController)`, not directly.
  Future<CoffeeReadingController> failedController() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(storage),
        analysis: _FailAnalysis(),
      ),
      images: _FakeImages(fixturePath),
      live: fakeImmediateReadingFeatureRunner(),
    );
    controller.startCapture();
    await controller.pickGallery();
    await controller.analyze();
    expect(controller.phase, CoffeePhase.error);
    expect(controller.image, isNotNull);
    return controller;
  }

  testWidgets('retry with valid image calls onAnalyze not preview', (tester) async {
    final controller = (await tester.runAsync(failedController))!;
    var analyzeTaps = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (_, __) => CoffeeReferenceBody(
                controller: controller,
                onAnalyze: () { analyzeTaps++; },
                onHistory: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(CoffeeCopy.usePhotoLabel), findsNothing);
    await tester.tap(find.text(CoffeeCopy.retry));
    await tester.pump();
    expect(analyzeTaps, 1);
    expect(controller.phase, isNot(CoffeePhase.capture));
    expect(controller.image, isNotNull);
  });

  testWidgets('missing image retry returns to capture safely', (tester) async {
    final controller = (await tester.runAsync(failedController))!;
    controller.clearImage();
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (_, __) => CoffeeReferenceBody(
                controller: controller,
                onAnalyze: () {},
                onHistory: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text(CoffeeCopy.retry));
    await tester.pump();
    expect(controller.phase, CoffeePhase.capture);
  });
}

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);
  final String root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
}
