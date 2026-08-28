/// Coffee Retry reuses current valid image; missing image returns to capture.
library;

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
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<CoffeeReadingController> failedController() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(storage),
        analysis: _FailAnalysis(),
      ),
      images: const _FakeImages('cup.jpg'),
    );
    controller.startCapture();
    await controller.pickGallery();
    await controller.analyze();
    expect(controller.phase, CoffeePhase.error);
    expect(controller.image, isNotNull);
    return controller;
  }

  testWidgets('retry with valid image calls onAnalyze not preview', (tester) async {
    final controller = await failedController();
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
    final controller = await failedController();
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
