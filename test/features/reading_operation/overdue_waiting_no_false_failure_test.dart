/// Regression coverage for a real release-risk: Coffee/Palm's client-side
/// resume/observe loop must NEVER infer a terminal failure merely from
/// "readyAt passed and N seconds/observations elapsed". Cloud Tasks queue
/// concurrency (currently 1), Cloud Run cold starts, and retry/backoff can
/// legitimately keep a healthy operation `waiting` for far longer than any
/// small client-side count -- only explicit server-reported terminal state
/// (`ReadingLiveKind.failed`) may ever show recovery/error UI.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

class _Images implements CoffeeImageInputPort {
  const _Images(this.path);
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

class _MustNotRunCoffee implements CoffeeAnalysisPort, CoffeeStagedAnalysisPort, CoffeeCompletedAnalysisPort {
  int calls = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) => throw UnimplementedError();
  @override
  Future<CoffeeReading> analyzeStaged({required String operationId, required String mimeType}) async {
    calls++;
    throw StateError('must never run while merely waiting');
  }
  @override
  CoffeeReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  }) => CoffeeReading(
    id: resultId, createdAt: persistedAt,
    overall: (result['overall'] as String?) ?? '', love: '', career: '', money: '', nearFuture: '',
    takeaway: (result['takeaway'] as String?) ?? '',
  );
}

class _MustNotRunPalm implements PalmAnalysisPort, PalmStagedAnalysisPort, PalmCompletedAnalysisPort {
  int calls = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<PalmReading> analyze(CoffeeImagePick image, {required PalmHand hand}) => throw UnimplementedError();
  @override
  Future<PalmReading> analyzeStaged({required String operationId, required String mimeType, required PalmHand hand}) async {
    calls++;
    throw StateError('must never run while merely waiting');
  }
  @override
  PalmReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required PalmHand hand,
    required Map<String, dynamic> result,
  }) => PalmReading(
    id: resultId, createdAt: persistedAt, hand: hand,
    overall: (result['overall'] as String?) ?? '', takeaway: (result['takeaway'] as String?) ?? '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('(A/B/C) Coffee: many repeated observations of an overdue-but-healthy waiting operation never produce a failure', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
    final analysis = _MustNotRunCoffee();
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
    );
    addTearDown(controller.dispose);
    await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-overdue-01');
    await controller.recoverActive();

    // Simulate 50 separate observations of the SAME still-waiting operation
    // -- ten times the old (removed) 5-retry threshold. None may ever tip
    // into a false terminal failure; the operation is genuinely healthy,
    // just not yet claimed.
    for (var i = 0; i < 50; i++) {
      await controller.recoverActive();
      expect(controller.phase, isNot(CoffeePhase.error));
      expect(controller.errorMessage, isNull);
      expect(controller.liveState?.kind, ReadingLiveKind.waiting);
    }
    expect(analysis.calls, 0);
  });

  test('(A/B/C) Palm: many repeated observations of an overdue-but-healthy waiting operation never produce a failure', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
    final analysis = _MustNotRunPalm();
    final controller = PalmReadingController(
      experience: PalmExperienceService(store: PalmReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
    );
    addTearDown(controller.dispose);
    await runner.flow.begin(readingType: ReadingType.palm, sourceRequestId: 'palm-overdue-01');
    await controller.recoverActive();

    for (var i = 0; i < 50; i++) {
      await controller.recoverActive();
      expect(controller.phase, isNot(PalmPhase.error));
      expect(controller.errorMessage, isNull);
      expect(controller.liveState?.kind, ReadingLiveKind.waiting);
    }
    expect(analysis.calls, 0);
  });

  test('(D) waiting -> processing after a delayed server claim shows processing UI normally', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
    final analysis = _MustNotRunCoffee();
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
      acceptAuthoritativeBalance: (_) async {},
    );
    addTearDown(controller.dispose);
    await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-delayed-claim-01');
    await controller.recoverActive();
    // Many overdue observations first -- simulating real queue delay.
    for (var i = 0; i < 10; i++) {
      await controller.recoverActive();
    }
    expect(controller.liveState?.kind, ReadingLiveKind.waiting);
    // The durable worker finally claims it (server-side, no client action).
    backend.immediatelyEligible = true;
    await runner.flow.claimIfEligible(controller.liveState!.snapshot!.operationId);
    await controller.recoverActive();
    expect(controller.liveState?.kind, ReadingLiveKind.processing);
    expect(controller.phase, isNot(CoffeePhase.error));
    expect(analysis.calls, 0);
  });

  test('(E) waiting -> ready after delayed server completion opens the result normally', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
    final analysis = _MustNotRunCoffee();
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
      acceptAuthoritativeBalance: (_) async {},
    );
    addTearDown(controller.dispose);
    final begun = await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-delayed-ready-01');
    await controller.recoverActive();
    for (var i = 0; i < 10; i++) {
      await controller.recoverActive();
    }
    backend.completeServerSide(
      begun.snapshot!.operationId,
      resultId: 'coffee_delayed_ready_01',
      result: {'overall': 'finally ready', 'love': '', 'career': '', 'money': '', 'nearFuture': '', 'takeaway': 'done'},
    );
    await controller.recoverActive();
    expect(controller.phase, CoffeePhase.result);
    expect(controller.reading?.id, 'coffee_delayed_ready_01');
    expect(analysis.calls, 0);
  });

  test('(F) explicit server-reported terminal failure still shows recovery UI (unchanged, genuine failures still surface)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend();
    final runner = fakeImmediateReadingFeatureRunner(backend: backend);
    final analysis = _MustNotRunCoffee();
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
    );
    addTearDown(controller.dispose);
    final begun = await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-explicit-fail-01');
    await runner.flow.claimIfEligible(begun.snapshot!.operationId);
    await runner.flow.failFinal(begun.snapshot!.operationId);
    await controller.recoverActive();
    expect(controller.phase, CoffeePhase.error);
    expect(controller.errorMessage, isNotNull);
  });

  test('(H) app restart while an overdue-but-valid operation is still waiting continues observing the SAME operation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
    final analysis = _MustNotRunCoffee();

    final firstInstance = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
    );
    final begun = await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-restart-overdue-01');
    await firstInstance.recoverActive();
    for (var i = 0; i < 10; i++) {
      await firstInstance.recoverActive();
    }
    firstInstance.dispose();

    // A brand new controller instance, as a real app restart would create.
    final restarted = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
    );
    addTearDown(restarted.dispose);
    await restarted.recoverActive();

    expect(restarted.liveState?.kind, ReadingLiveKind.waiting);
    expect(restarted.liveState?.snapshot?.operationId, begun.snapshot?.operationId);
    expect(restarted.phase, isNot(CoffeePhase.error));
    expect(analysis.calls, 0);
    expect(backend.operationCount, 1);
  });
}
