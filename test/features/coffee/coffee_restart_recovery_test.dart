/// Regression coverage for app-restart / controller-disposal recovery of
/// a `waiting` Coffee operation. The previous fix (automatic in-session
/// resume) depended entirely on an in-memory Timer plus a `runPipeline`
/// closure holding the original local image bytes — both are lost the
/// moment the controller instance is destroyed (app kill, not just a
/// widget rebuild).
///
/// This proves the SAME staged operation can be found and resumed by a
/// brand-new controller instance, sharing only durable state (local
/// storage's pending-operation record + the server), and that the
/// server-staged image — never local bytes — is what the resumed pipeline
/// call actually uses.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_pending_operation_store.dart';
// Transitive test-only deps already used the same way elsewhere in this
// suite (see coffee_cancel_analysis_test.dart) — not a direct pubspec dep.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

/// Implements BOTH the normal (local-bytes) and staged-only analysis
/// ports so a test can assert exactly which path a given call took.
class _TrackingAnalysis
    implements CoffeeAnalysisPort, CoffeeStagedAnalysisPort, CoffeeCompletedAnalysisPort {
  int localBytesCalls = 0;
  int stagedCalls = 0;
  String? lastStagedOperationId;

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    localBytesCalls++;
    return CoffeeReading(
      id: 'coffee_restart_local',
      createdAt: DateTime.utc(2026, 1, 1),
      overall: 'overall',
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: 'takeaway',
      imagePath: image.path,
    );
  }

  @override
  Future<CoffeeReading> analyzeStaged({
    required String operationId,
    required String mimeType,
  }) async {
    stagedCalls++;
    lastStagedOperationId = operationId;
    return CoffeeReading(
      id: 'coffee_restart_staged',
      createdAt: DateTime.utc(2026, 1, 1),
      overall: 'overall (from server-staged image)',
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: 'takeaway',
      imagePath: null,
    );
  }
  @override
  CoffeeReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  }) {
    return CoffeeReading(
      id: resultId,
      createdAt: persistedAt,
      overall: result['overall'] as String? ?? 'server result',
      love: result['love'] as String? ?? '',
      career: result['career'] as String? ?? '',
      money: result['money'] as String? ?? '',
      nearFuture: result['nearFuture'] as String? ?? '',
      takeaway: result['takeaway'] as String? ?? '',
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
  late CoffeeReadingStore sharedReadingStore;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_restart_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    fixturePath = '${temp.path}/cup.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
    SharedPreferences.setMockInitialValues({});
    // Shared across "controller A" (pre-restart) and "controller B"
    // (post-restart) — this is exactly what SharedPreferences durability
    // gives a real app across a real process kill+relaunch.
    sharedStorage = LocalStorage(await SharedPreferences.getInstance());
    sharedPendingStore = ReadingPendingOperationStore(sharedStorage);
    sharedReadingStore = CoffeeReadingStore(sharedStorage);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test(
    'THE BUG (pre-fix baseline, still true without a pending record): a '
    'fresh controller with no pending-operation record only reflects '
    'status passively — it does not (and safely cannot) resume',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final analysisA = _TrackingAnalysis();
      final controllerA = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: sharedReadingStore,
          analysis: analysisA,
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
        // No pendingStore — mirrors the pre-fix architecture exactly.
      );

      controllerA.startCapture();
      await controllerA.pickGallery();
      await controllerA.analyze();
      expect(controllerA.phase, CoffeePhase.analyzing);
      controllerA.dispose();

      backend.immediatelyEligible = true;

      final controllerB = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: sharedReadingStore,
          analysis: _TrackingAnalysis(),
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
      );
      addTearDown(controllerB.dispose);
      await controllerB.recoverActive();

      // Honest: without identity to resume by, it only reflects status.
      expect(controllerB.phase, CoffeePhase.analyzing);
      expect(controllerB.reading, isNull);
    },
  );

  test(
    'server-owned Coffee recovers from waiting without any pending pointer',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final controllerA = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: sharedReadingStore,
          analysis: _TrackingAnalysis(),
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(
          backend: backend,
          serverOwnedCompletion: true,
        ),
        // Deliberately NO pendingStore: production recovery must converge
        // from the server-owned active operation alone.
      );
      controllerA.startCapture();
      await controllerA.pickGallery();
      await controllerA.analyze();
      final operationId = controllerA.liveState?.snapshot?.operationId;
      expect(operationId, isNotNull);
      expect(controllerA.phase, CoffeePhase.analyzing);
      controllerA.dispose();

      final controllerB = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: sharedReadingStore,
          analysis: _TrackingAnalysis(),
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(
          backend: backend,
          serverOwnedCompletion: true,
        ),
        serverPollInterval: const Duration(milliseconds: 1),
      );
      addTearDown(controllerB.dispose);

      await controllerB.recoverActive();
      expect(controllerB.phase, CoffeePhase.analyzing);

      backend.completeServerSide(
        operationId!,
        resultId: 'coffee_server_ready',
        result: const {
          'overall': 'server owned result',
          'love': '',
          'career': '',
          'money': '',
          'nearFuture': '',
          'takeaway': 'done',
        },
      );

      final deadline = DateTime.now().add(const Duration(seconds: 1));
      while (controllerB.phase != CoffeePhase.result &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(controllerB.phase, CoffeePhase.result);
      expect(controllerB.reading?.id, 'coffee_server_ready');
      expect(controllerB.reading?.overall, 'server owned result');
      expect(backend.operationCount, 1);
    },
  );

  test(
    'THE FIX: a brand-new controller instance (simulated app restart) '
    'resumes the SAME staged operation using ONLY the server-held image '
    '— no local image bytes/path required, no duplicate operation',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final analysisA = _TrackingAnalysis();

      // "Controller A" — the pre-restart session that creates + stages.
      final controllerA = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: sharedReadingStore,
          analysis: analysisA,
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
        pendingStore: sharedPendingStore,
      );

      controllerA.startCapture();
      await controllerA.pickGallery();
      await controllerA.analyze();
      expect(controllerA.phase, CoffeePhase.analyzing);
      expect(controllerA.liveState?.kind, ReadingLiveKind.waiting);
      expect(analysisA.localBytesCalls, 0, reason: 'not eligible yet');
      final operationId = controllerA.liveState?.snapshot?.operationId;
      expect(operationId, isNotNull);

      // Simulated app kill: dispose without ever letting the in-memory
      // resume Timer fire, and drop every in-memory reference (image
      // bytes, the runPipeline closure, the experience/analysis
      // instance) that the OLD architecture depended on.
      controllerA.dispose();

      // The wait elapses in the real world while the app is closed.
      backend.immediatelyEligible = true;

      // "Controller B" — simulated relaunch. Deliberately built with a
      // FRESH analysis instance (no shared in-memory state with A) and
      // no CoffeeImageInputPort image ever picked — the only things it
      // shares with A are the durable pending-operation record (local
      // storage) and the server (the fake backend).
      final analysisB = _TrackingAnalysis();
      final controllerB = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: sharedReadingStore,
          analysis: analysisB,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
        pendingStore: sharedPendingStore,
      );
      addTearDown(controllerB.dispose);

      await controllerB.recoverActive();

      expect(controllerB.phase, CoffeePhase.result);
      expect(controllerB.reading?.id, 'coffee_restart_staged');
      expect(
        analysisB.stagedCalls,
        1,
        reason: 'must resume via the staged-only (server-image) path',
      );
      expect(
        analysisB.lastStagedOperationId,
        operationId,
        reason: 'must resume the SAME operation, not create a new one',
      );
      expect(
        analysisB.localBytesCalls,
        0,
        reason: 'recovery must never require local image bytes',
      );
      expect(
        analysisA.localBytesCalls,
        0,
        reason: 'the original (disposed) instance must never fire either',
      );
    },
  );

  test(
    'no duplicate operation is created across the restart — the resumed '
    'call reuses the exact same operationId end to end',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final controllerA = CoffeeReadingController(
        experience: CoffeeExperienceService(
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
      final operationIdBefore = controllerA.liveState?.snapshot?.operationId;
      controllerA.dispose();

      backend.immediatelyEligible = true;

      final controllerB = CoffeeReadingController(
        experience: CoffeeExperienceService(store: sharedReadingStore, analysis: _TrackingAnalysis()),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
        pendingStore: sharedPendingStore,
      );
      addTearDown(controllerB.dispose);
      await controllerB.recoverActive();

      expect(controllerB.liveState?.snapshot?.operationId, operationIdBefore);
      expect(backend.operationCount, 1, reason: 'never created a second operation');
    },
  );

  test(
    'completion deep link restores the exact Coffee operation even when another Coffee operation is active',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final runner = fakeImmediateReadingFeatureRunner(
        backend: backend,
        serverOwnedCompletion: true,
      );
      final target = await runner.flow.begin(
        readingType: ReadingType.coffee,
        sourceRequestId: 'push-target-coffee',
      );
      final targetId = target.snapshot!.operationId;
      backend.completeServerSide(
        targetId,
        resultId: 'coffee_push_target_result',
        result: const {
          'overall': 'exact push target',
          'love': '',
          'career': '',
          'money': '',
          'nearFuture': '',
          'takeaway': 'done',
        },
      );

      final other = await runner.flow.begin(
        readingType: ReadingType.coffee,
        sourceRequestId: 'other-active-coffee',
      );
      expect(other.snapshot!.operationId, isNot(targetId));

      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: sharedReadingStore,
          analysis: _TrackingAnalysis(),
        ),
        images: _FakeImages(fixturePath),
        live: runner,
        pendingStore: sharedPendingStore,
      );
      addTearDown(controller.dispose);

      await controller.recoverOperation(targetId);

      expect(controller.phase, CoffeePhase.result);
      expect(controller.liveState?.snapshot?.operationId, targetId);
      expect(controller.reading?.id, 'coffee_push_target_result');
      expect(controller.reading?.overall, 'exact push target');
    },
  );

  test(
    'Coffee exact recovery rejects a Palm operation id',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final runner = fakeImmediateReadingFeatureRunner(
        backend: backend,
        serverOwnedCompletion: true,
      );
      final palm = await runner.flow.begin(
        readingType: ReadingType.palm,
        sourceRequestId: 'wrong-feature-target',
      );
      backend.completeServerSide(
        palm.snapshot!.operationId,
        resultId: 'wrong_feature_result',
      );

      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: sharedReadingStore,
          analysis: _TrackingAnalysis(),
        ),
        images: _FakeImages(fixturePath),
        live: runner,
        pendingStore: sharedPendingStore,
      );
      addTearDown(controller.dispose);

      await controller.recoverOperation(palm.snapshot!.operationId);

      expect(controller.phase, CoffeePhase.entry);
      expect(controller.reading, isNull);
    },
  );

test(
    'the pending record is cleared once the operation reaches a terminal '
    'state, so a later recoverActive() call does not try to resume it '
    'again',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final controllerA = CoffeeReadingController(
        experience: CoffeeExperienceService(
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

      final controllerB = CoffeeReadingController(
        experience: CoffeeExperienceService(store: sharedReadingStore, analysis: _TrackingAnalysis()),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
        pendingStore: sharedPendingStore,
      );
      await controllerB.recoverActive();
      expect(controllerB.phase, CoffeePhase.result);
      controllerB.dispose();

      expect(sharedPendingStore.load(ReadingType.coffee), isNull);
    },
  );
}
