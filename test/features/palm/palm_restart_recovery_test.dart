/// Regression coverage for app-restart / controller-disposal recovery of
/// a `waiting` Palm operation — the Palm-side mirror of
/// coffee_restart_recovery_test.dart. See that file for the full
/// rationale: the in-session-only resume fix depended entirely on an
/// in-memory Timer plus local image bytes, both lost when the controller
/// instance is destroyed (app kill, not just a widget rebuild).
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
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_pending_operation_store.dart';
// Transitive test-only deps already used the same way elsewhere in this
// suite (see coffee_cancel_analysis_test.dart) — not a direct pubspec dep.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

class _TrackingAnalysis implements PalmAnalysisPort, PalmStagedAnalysisPort {
  int localBytesCalls = 0;
  int stagedCalls = 0;
  String? lastStagedOperationId;
  PalmHand? lastStagedHand;

  @override
  bool get isAvailable => true;

  @override
  Future<PalmReading> analyze(CoffeeImagePick image, {required PalmHand hand}) async {
    localBytesCalls++;
    return PalmReading(
      id: 'palm_restart_local',
      createdAt: DateTime.utc(2026, 1, 1),
      hand: hand,
      overall: 'overall',
      takeaway: 'takeaway',
      imagePath: image.path,
    );
  }

  @override
  Future<PalmReading> analyzeStaged({
    required String operationId,
    required String mimeType,
    required PalmHand hand,
  }) async {
    stagedCalls++;
    lastStagedOperationId = operationId;
    lastStagedHand = hand;
    return PalmReading(
      id: 'palm_restart_staged',
      createdAt: DateTime.utc(2026, 1, 1),
      hand: hand,
      overall: 'overall (from server-staged image)',
      takeaway: 'takeaway',
      imagePath: null,
    );
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
  late LocalStorage sharedStorage;
  late ReadingPendingOperationStore sharedPendingStore;
  late PalmReadingStore sharedReadingStore;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('palm_restart_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    fixturePath = '${temp.path}/palm.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
    SharedPreferences.setMockInitialValues({});
    sharedStorage = LocalStorage(await SharedPreferences.getInstance());
    sharedPendingStore = ReadingPendingOperationStore(sharedStorage);
    sharedReadingStore = PalmReadingStore(sharedStorage);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test(
    'THE FIX: a brand-new controller instance (simulated app restart) '
    'resumes the SAME staged operation using ONLY the server-held image '
    '— no local image bytes/path required, no duplicate operation, '
    'correct hand preserved',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final analysisA = _TrackingAnalysis();

      final controllerA = PalmReadingController(
        experience: PalmExperienceService(
          store: sharedReadingStore,
          analysis: analysisA,
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
        pendingStore: sharedPendingStore,
      );
      controllerA.startCapture();
      controllerA.selectHand(PalmHand.left);
      await controllerA.pickGallery();
      await controllerA.analyze();
      expect(controllerA.phase, PalmPhase.analyzing);
      expect(analysisA.localBytesCalls, 0, reason: 'not eligible yet');
      final operationId = controllerA.liveState?.snapshot?.operationId;
      expect(operationId, isNotNull);

      controllerA.dispose();
      backend.immediatelyEligible = true;

      final analysisB = _TrackingAnalysis();
      final controllerB = PalmReadingController(
        experience: PalmExperienceService(store: sharedReadingStore, analysis: analysisB),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
        pendingStore: sharedPendingStore,
      );
      addTearDown(controllerB.dispose);

      await controllerB.recoverActive();

      expect(controllerB.phase, PalmPhase.result);
      expect(controllerB.reading?.id, 'palm_restart_staged');
      expect(analysisB.stagedCalls, 1);
      expect(analysisB.lastStagedOperationId, operationId);
      expect(
        analysisB.lastStagedHand,
        PalmHand.left,
        reason: 'the persisted pending record must carry the original hand',
      );
      expect(analysisB.localBytesCalls, 0);
      expect(analysisA.localBytesCalls, 0);
      expect(backend.operationCount, 1, reason: 'never created a second operation');
    },
  );

  test(
    'the pending record is cleared once the operation reaches a terminal '
    'state',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final controllerA = PalmReadingController(
        experience: PalmExperienceService(
          store: sharedReadingStore,
          analysis: _TrackingAnalysis(),
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
        pendingStore: sharedPendingStore,
      );
      controllerA.startCapture();
      await controllerA.pickGallery();
      await controllerA.analyze();
      controllerA.dispose();
      backend.immediatelyEligible = true;

      final controllerB = PalmReadingController(
        experience: PalmExperienceService(store: sharedReadingStore, analysis: _TrackingAnalysis()),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
        pendingStore: sharedPendingStore,
      );
      await controllerB.recoverActive();
      expect(controllerB.phase, PalmPhase.result);
      controllerB.dispose();

      expect(sharedPendingStore.load(ReadingType.palm), isNull);
    },
  );
}
