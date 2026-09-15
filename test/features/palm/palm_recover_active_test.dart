/// BATCH 5F — Palm's active-operation recovery (app kill / relaunch
/// simulated by constructing a fresh controller instance against the same
/// backend state) must reopen a ready result or a failed state without any
/// second AI call, and must not touch anything when there is nothing active.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
// Transitive test-only deps already used the same way elsewhere in this
// suite (see coffee_cancel_analysis_test.dart) — not a direct pubspec dep.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

class _OkAnalysis implements PalmAnalysisPort {
  int calls = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<PalmReading> analyze(CoffeeImagePick image, {required PalmHand hand}) async {
    calls++;
    return PalmReading(
      id: 'palm_recover_1',
      createdAt: DateTime.utc(2026, 1, 1),
      hand: hand,
      overall: 'overall',
      takeaway: 'takeaway',
      imagePath: image.path,
    );
  }
}

class _FailAnalysis implements PalmAnalysisPort {
  @override
  bool get isAvailable => true;
  @override
  Future<PalmReading> analyze(CoffeeImagePick image, {required PalmHand hand}) async {
    throw Exception('fail');
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late String fixturePath;
  late PalmReadingStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('palm_recover_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    fixturePath = '${temp.path}/palm.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
    SharedPreferences.setMockInitialValues({});
    store = PalmReadingStore(LocalStorage(await SharedPreferences.getInstance()));
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test(
    'H/I: a fresh controller (simulated app relaunch) recovers a ready '
    'operation and reopens the persisted result with zero extra AI calls',
    () async {
      final backend = FakeReadingOperationBackend();
      final analysis = _OkAnalysis();
      final controllerA = PalmReadingController(
        experience: PalmExperienceService(
          store: store,
          analysis: analysis,
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
      );
      controllerA.startCapture();
      await controllerA.pickGallery();
      await controllerA.analyze();
      expect(controllerA.phase, PalmPhase.result);
      expect(analysis.calls, 1);

      final controllerB = PalmReadingController(
        experience: PalmExperienceService(store: store, analysis: analysis),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
      );
      await controllerB.recoverActive();

      expect(controllerB.phase, PalmPhase.result);
      expect(controllerB.reading?.id, 'palm_recover_1');
      expect(analysis.calls, 1, reason: 'recovery must never re-run AI');
    },
  );

  test('recoverActive recovers a failed operation into the error state', () async {
    final backend = FakeReadingOperationBackend();
    final controllerA = PalmReadingController(
      experience: PalmExperienceService(store: store, analysis: _FailAnalysis()),
      images: _FakeImages(fixturePath),
      live: fakeImmediateReadingFeatureRunner(backend: backend),
    );
    controllerA.startCapture();
    await controllerA.pickGallery();
    await controllerA.analyze();
    expect(controllerA.phase, PalmPhase.error);

    final controllerB = PalmReadingController(
      experience: PalmExperienceService(store: store, analysis: _FailAnalysis()),
      images: _FakeImages(fixturePath),
      live: fakeImmediateReadingFeatureRunner(backend: backend),
    );
    await controllerB.recoverActive();
    expect(controllerB.phase, PalmPhase.error);
    expect(controllerB.errorMessage, isNotNull);
  });

  test('recoverActive does nothing when there is no active operation', () async {
    final backend = FakeReadingOperationBackend();
    final controller = PalmReadingController(
      experience: PalmExperienceService(store: store, analysis: _OkAnalysis()),
      images: _FakeImages(fixturePath),
      live: fakeImmediateReadingFeatureRunner(backend: backend),
    );
    await controller.recoverActive();
    expect(controller.phase, PalmPhase.entry);
    expect(controller.reading, isNull);
  });

  test('recoverActive is a no-op (never throws) with no live runner configured', () async {
    final controller = PalmReadingController(
      experience: PalmExperienceService(store: store, analysis: _OkAnalysis()),
      images: _FakeImages(fixturePath),
    );
    await controller.recoverActive();
    expect(controller.phase, PalmPhase.entry);
  });
}
