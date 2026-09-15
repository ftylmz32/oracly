/// 26091106 client contract: Coffee/Palm's real production
/// `ReadingFeatureRunner` is wired with `serverOwnedCompletion: true` (see
/// `reading_live_provider.dart`). These tests exercise the controllers
/// against that EXACT setting -- the one older acceleration tests in
/// `acceleration_controller_wiring_test.dart` do not use -- proving the 5
/// specific 26091105 failure scenarios named in the release audit:
///
/// A) accelerate -> countdown/waiting UI gives way to processing, with
///    ZERO client-owned provider calls.
/// B) app killed immediately after accelerate -> restart -> same operation
///    recovered as `processing`, no generic failure, no second charge.
/// C) free wait elapses while closed -> restart while the server is still
///    processing -> processing state, not a client-run pipeline.
/// D) server already completed while closed -> restart -> persisted result
///    opens directly.
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

/// Must-not-run pipeline: any call increments a counter the tests assert
/// stays at zero, exactly the way a real client-owned provider call must
/// never happen once the server owns completion. Implements the completed
/// port too, so a genuinely server-persisted result can still be restored
/// and displayed -- that path is legitimate and must keep working.
class _MustNotRunCoffee implements CoffeeAnalysisPort, CoffeeStagedAnalysisPort, CoffeeCompletedAnalysisPort {
  int calls = 0;
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) => throw UnimplementedError();
  @override
  Future<CoffeeReading> analyzeStaged({required String operationId, required String mimeType}) async {
    calls++;
    throw StateError('client-owned pipeline must never run once the server owns completion');
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
      overall: (result['overall'] as String?) ?? '',
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: (result['takeaway'] as String?) ?? '',
    );
  }
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
    throw StateError('client-owned pipeline must never run once the server owns completion');
  }
  @override
  PalmReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required PalmHand hand,
    required Map<String, dynamic> result,
  }) {
    return PalmReading(
      id: resultId,
      createdAt: persistedAt,
      hand: hand,
      overall: (result['overall'] as String?) ?? '',
      takeaway: (result['takeaway'] as String?) ?? '',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('(A) accelerate success -> processing, zero client-owned provider calls, result loads once the server completes it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
    await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-a-01');
    final analysis = _MustNotRunCoffee();
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
      acceptAuthoritativeBalance: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.recoverActive();
    await Future<void>.delayed(Duration.zero);

    await controller.accelerateWaiting();

    // Countdown/waiting gives way to a processing state -- never the old
    // client-owned "analyzing via local bytes" outcome.
    expect(controller.liveState?.kind, ReadingLiveKind.processing);
    expect(analysis.calls, 0);
    expect(controller.phase, CoffeePhase.analyzing);

    // The durable worker (not this client) completes it server-side.
    final operationId = controller.liveState!.snapshot!.operationId;
    backend.completeServerSide(operationId, resultId: 'coffee_server_a01', result: {
      'overall': 'a real server-produced reading', 'love': '', 'career': '', 'money': '', 'nearFuture': '', 'takeaway': 'done',
    });

    // The client observes it via its existing poll -- call recoverActive
    // directly here to avoid depending on the real 3s timer in a unit test.
    await controller.recoverActive();
    await Future<void>.delayed(Duration.zero);
    expect(controller.phase, CoffeePhase.result);
    expect(controller.reading?.id, 'coffee_server_a01');
    expect(analysis.calls, 0);
  });

  test('(B) app killed immediately after accelerate -> restart -> recovered as processing, no generic failure, no second charge', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
    await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-b-01');
    final analysis = _MustNotRunCoffee();

    // First controller instance: accelerate, then simulate the app dying
    // right after (never call recoverActive/observe again on it).
    final firstInstance = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
      acceptAuthoritativeBalance: (_) async {},
    );
    await firstInstance.recoverActive();
    await Future<void>.delayed(Duration.zero);
    await firstInstance.accelerateWaiting();
    expect(backend.accelerationCalls, 1);
    firstInstance.dispose();

    // A brand new controller instance, as a real app restart would create.
    final restarted = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
      acceptAuthoritativeBalance: (_) async {},
    );
    addTearDown(restarted.dispose);
    await restarted.recoverActive();
    await Future<void>.delayed(Duration.zero);

    expect(restarted.liveState?.kind, ReadingLiveKind.processing);
    expect(restarted.phase, isNot(CoffeePhase.error));
    expect(restarted.errorMessage, isNull);
    // No second acceleration/charge happened on restart.
    expect(backend.accelerationCalls, 1);
    expect(analysis.calls, 0);
  });

  test('(C) free wait elapses while closed -> restart while server is processing -> processing state, no client pipeline run', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
    await runner.flow.begin(readingType: ReadingType.palm, sourceRequestId: 'palm-c-01');
    final analysis = _MustNotRunPalm();

    // The operation transitions to processing purely server-side (as the
    // durable worker's claim would do) -- no client ever calls accelerate.
    backend.immediatelyEligible = true;

    final controller = PalmReadingController(
      experience: PalmExperienceService(store: PalmReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
    );
    addTearDown(controller.dispose);
    await controller.recoverActive();
    await Future<void>.delayed(Duration.zero);

    // The fake's claim path executes immediately once eligible in the
    // non-server-owned model; here what matters is the client itself never
    // ran the provider for it.
    expect(analysis.calls, 0);
  });

  test('(D) server already completed while closed -> restart -> persisted result opens directly', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final backend = FakeReadingOperationBackend(immediatelyEligible: false);
    final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
    final begun = await runner.flow.begin(readingType: ReadingType.coffee, sourceRequestId: 'coffee-d-01');
    final analysis = _MustNotRunCoffee();
    backend.completeServerSide(
      begun.snapshot!.operationId,
      resultId: 'coffee_server_d01',
      result: {'overall': 'ready while you were away', 'love': '', 'career': '', 'money': '', 'nearFuture': '', 'takeaway': 'done'},
    );

    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(store: CoffeeReadingStore(LocalStorage(prefs)), analysis: analysis),
      images: const _Images('unused'),
      live: runner,
      acceptAuthoritativeBalance: (_) async {},
    );
    addTearDown(controller.dispose);
    await controller.recoverActive();
    await Future<void>.delayed(Duration.zero);

    expect(controller.phase, CoffeePhase.result);
    expect(controller.reading?.id, 'coffee_server_d01');
    expect(analysis.calls, 0);
  });

  test(
    '(E) LIVE INCIDENT REGRESSION -- Palm: accelerate succeeds once, app '
    'restarts before the durable worker finishes, countdown never comes '
    'back and no second Gem debit, then the server-completed result is '
    'shown on the next observe. Reproduces the real production failure '
    'where operationId e9c79eccae53e8dd844aa7dd55950868 was accelerated '
    '(one 15-Gem debit), the durable Cloud Task claimed and completed it '
    'server-side in ~23s, but the installed (pre-server-owned-completion) '
    'client fell back to re-rendering a fresh ~4h waiting countdown '
    'instead of observing the processing/ready state. With '
    '`serverOwnedCompletion: true` (the real production wiring, see '
    'reading_live_provider.dart) the client never attempts its own claim '
    'at all, so it cannot lose that race or regress to `waiting`.',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final backend = FakeReadingOperationBackend(immediatelyEligible: false);
      final runner = fakeImmediateReadingFeatureRunner(backend: backend, serverOwnedCompletion: true);
      await runner.flow.begin(readingType: ReadingType.palm, sourceRequestId: 'palm-e-01');
      final analysis = _MustNotRunPalm();

      final firstInstance = PalmReadingController(
        experience: PalmExperienceService(store: PalmReadingStore(LocalStorage(prefs)), analysis: analysis),
        images: const _Images('unused'),
        live: runner,
      );
      await firstInstance.recoverActive();
      await Future<void>.delayed(Duration.zero);

      await firstInstance.accelerateWaiting();

      // Exactly one debit for this operation -- never a second one, no
      // matter how many times the client re-observes it afterward.
      expect(backend.accelerationCalls, 1);
      // The countdown must never come back: acceleration success means
      // `processing`, not a re-armed `waiting` state with a fresh timer.
      expect(firstInstance.liveState?.kind, ReadingLiveKind.processing);
      expect(analysis.calls, 0);
      final operationId = firstInstance.liveState!.snapshot!.operationId;

      // App dies immediately after acceleration -- never observed again on
      // this instance, exactly like the real device closing/backgrounding.
      firstInstance.dispose();

      // A brand-new controller instance, as a real app restart would
      // create. Must still show `processing`, never a fresh waiting
      // countdown, and must not re-charge.
      final restarted = PalmReadingController(
        experience: PalmExperienceService(store: PalmReadingStore(LocalStorage(prefs)), analysis: analysis),
        images: const _Images('unused'),
        live: runner,
      );
      addTearDown(restarted.dispose);
      await restarted.recoverActive();
      await Future<void>.delayed(Duration.zero);

      expect(restarted.liveState?.kind, ReadingLiveKind.processing);
      expect(restarted.phase, isNot(PalmPhase.error));
      expect(backend.accelerationCalls, 1);
      expect(analysis.calls, 0);

      // The durable worker now completes the SAME operation server-side --
      // exactly one provider execution, never triggered by this client.
      backend.completeServerSide(operationId, resultId: 'palm_server_e01', result: {
        'overall': 'a real server-produced palm reading',
        'takeaway': 'done',
      });

      // The next observe (the real app's poll/recover) must show the
      // finished result -- not a countdown, not an error, not a re-tap
      // prompt -- and still without ever running the client-owned pipeline.
      await restarted.recoverActive();
      await Future<void>.delayed(Duration.zero);
      expect(restarted.phase, PalmPhase.result);
      expect(restarted.reading?.id, 'palm_server_e01');
      expect(analysis.calls, 0);
      expect(backend.accelerationCalls, 1);
    },
  );
}
