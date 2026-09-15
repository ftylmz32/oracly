/// Regression coverage for a real-device-confirmed bug: Coffee's own
/// commercial wait (a real, non-zero, non-commercial-value-changed
/// duration — see `backend/src/reading/wait-policy.ts`) meant `submit`'s
/// single claim attempt at creation time almost always lost, and nothing
/// in the whole client ever came back to try again once the operation
/// genuinely became eligible. Confirmed live: create -> 200, staged-image
/// -> 200, then the app just spun until the generic "slow response"
/// failsafe fired — the operation was never claimed, executed, or
/// completed, no matter how long the user waited.
///
/// `CoffeeReadingController` now schedules exactly one automatic resume
/// attempt for when the operation's own countdown reaches zero, reusing
/// the already-staged operation (no re-staging, no second operation).
/// These tests never touch the wait DURATION itself — they only prove
/// that once a wait genuinely elapses, the reading actually completes.
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
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
// Transitive test-only deps already used the same way elsewhere in this
// suite (see coffee_cancel_analysis_test.dart) — not a direct pubspec dep.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

class _OkAnalysis implements CoffeeAnalysisPort {
  int calls = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    calls++;
    return CoffeeReading(
      id: 'coffee_wait_resume_1',
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
  late CoffeeReadingStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_wait_resume_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    fixturePath = '${temp.path}/cup.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
    SharedPreferences.setMockInitialValues({});
    store = CoffeeReadingStore(LocalStorage(await SharedPreferences.getInstance()));
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test(
    'THE BUG: an operation staged before its wait elapses stays waiting '
    'and the pipeline never runs — matches the live-device symptom '
    '("slow response" forever) exactly',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final analysis = _OkAnalysis();
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: store,
          analysis: analysis,
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
      );
      addTearDown(controller.dispose);

      controller.startCapture();
      await controller.pickGallery();
      await controller.analyze();

      expect(controller.phase, CoffeePhase.analyzing);
      expect(controller.liveState?.kind, ReadingLiveKind.waiting);
      expect(analysis.calls, 0);
    },
  );

  test(
    'THE FIX: once the wait elapses server-side, the controller resumes on '
    'its own and completes the reading — no second analyze() call, no '
    're-staging, no user action required',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final analysis = _OkAnalysis();
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: store,
          analysis: analysis,
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
      );
      addTearDown(controller.dispose);

      controller.startCapture();
      await controller.pickGallery();
      await controller.analyze();
      expect(controller.phase, CoffeePhase.analyzing);
      expect(analysis.calls, 0);

      // The commercial wait elapses on the server — the client neither
      // shortens nor invents this; it only needs to notice it.
      backend.immediatelyEligible = true;

      // No further call from the test — this proves the resume is
      // automatic, driven by the controller's own scheduled timer.
      await Future<void>.delayed(const Duration(milliseconds: 1300));

      expect(controller.phase, CoffeePhase.result);
      expect(controller.reading?.id, 'coffee_wait_resume_1');
      expect(analysis.calls, 1);
      expect(controller.liveState?.kind, ReadingLiveKind.ready);
    },
  );

  test(
    'a resumed reading is saved to history exactly like an immediate one',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final analysis = _OkAnalysis();
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: store,
          analysis: analysis,
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
      );
      addTearDown(controller.dispose);

      controller.startCapture();
      await controller.pickGallery();
      await controller.analyze();
      backend.immediatelyEligible = true;
      await Future<void>.delayed(const Duration(milliseconds: 1300));

      expect(controller.phase, CoffeePhase.result);
      expect(controller.history.map((r) => r.id), contains('coffee_wait_resume_1'));
    },
  );

  test(
    'leaving the screen (dispose) before the wait elapses cancels the '
    'pending resume — no work happens on a disposed controller',
    () async {
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final analysis = _OkAnalysis();
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: store,
          analysis: analysis,
          persistImage: ({required readingId, required sourcePath}) async => sourcePath,
        ),
        images: _FakeImages(fixturePath),
        live: fakeImmediateReadingFeatureRunner(backend: backend),
      );

      controller.startCapture();
      await controller.pickGallery();
      await controller.analyze();
      expect(controller.phase, CoffeePhase.analyzing);

      controller.dispose();
      backend.immediatelyEligible = true;
      await Future<void>.delayed(const Duration(milliseconds: 1300));

      // No exception, no crash, and (most importantly) no attempt to
      // notify a disposed ChangeNotifier — analysis.calls proves the
      // cancelled timer never fired the pipeline either.
      expect(analysis.calls, 0);
    },
  );
}
