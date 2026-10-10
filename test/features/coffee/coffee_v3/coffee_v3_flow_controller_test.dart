/// Coffee V3 flow controller: EXACT-operation observation (never the
/// feature-wide recovery), m2_public_v1 result restore via Slice 3, result
/// handoff/acknowledgement, terminal failure, restart, server-owned
/// acceleration economy, and rollout-flag semantics (flags gate NEW
/// creation only).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_intention.dart';
import 'package:oracly_new/features/coffee/coffee_v3/controllers/coffee_v3_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_flow_stage.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:oracly_new/features/reading_operation/copy/reading_live_copy.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/coffee_v3_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

// SYNTHETIC (never product copy): short, padded, scrub-sensitive.
const _overall = '  Fincanda bir konu ön plana çıkabilir;  kesin olacak gibi değil.\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late FakeReadingOperationBackend backend;
  late CoffeeV3TestTransport transport;
  late CoffeeReadingStore readings;
  late NoProviderAi ai;
  late List<int> balances;
  var allowed = true;
  var sizeSeed = 9000;
  var sourceCounter = 0;
  final controllers = <CoffeeV3FlowController>[];

  setUp(() async {
    OraclyL10n.bind('tr');
    temp = await Directory.systemTemp.createTemp('coffee_v3_flow_');
    installCoffeeV3SupportRoot(temp.path);
    storage = LocalStorage.ephemeral();
    backend = FakeReadingOperationBackend(immediatelyEligible: false)
      ..authoritativeBalance = 95;
    transport = CoffeeV3TestTransport(backend);
    readings = CoffeeReadingStore(storage);
    ai = NoProviderAi();
    balances = [];
    allowed = true;
    sourceCounter = 0;
  });

  tearDown(() async {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  CoffeeV3FlowController build() {
    final flow = ReadingLiveFlow(
      operations: ReadingOperationGateway(send: transport.send),
      acceleration: ReadingAccelerationClient(send: transport.send),
      send: transport.send,
    );
    final controller = CoffeeV3FlowController(
      submission: CoffeeV3SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(transport.send),
        store: CoffeeV3SubmissionStore(
          storage,
          ownerId: 'owner-flow',
          requireOwner: true,
        ),
        normalizer: ownedCoffeeV3Normalizer(temp.path),
        messages: coffeeV3TestMessages,
        creationAllowed: () => allowed,
        newSourceRequestId: () => 'coffee-v3-src-${++sourceCounter}',
      ),
      flow: flow,
      experience: CoffeeExperienceService(
        store: readings,
        analysis: OpenAiCoffeeAnalysis(ai: ai),
      ),
      onAuthoritativeBalance: (b) async => balances.add(b),
    );
    controllers.add(controller);
    return controller;
  }

  Future<void> waitFor(bool Function() condition, {int seconds = 6}) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('condition not reached in ${seconds}s');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  /// Temp-file release runs right after the durable record commit.
  Future<void> expectDeleted(List<String> paths) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (true) {
      var remaining = 0;
      for (final p in paths) {
        if (await File(p).exists()) remaining++;
      }
      if (remaining == 0) return;
      if (DateTime.now().isAfter(deadline)) fail('$remaining temp files left');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Future<void> captureFour(CoffeeV3FlowController c) async {
    c.dismissIntro();
    for (final slot in coffeeV3CanonicalSlotOrder) {
      expect(c.stage, CoffeeV3FlowStage.step);
      expect(c.currentStepSlot, slot);
      final file = File('${temp.path}/${slot.wireValue}.jpg');
      await file.writeAsBytes(plainJpegBytes(totalSize: sizeSeed += 41));
      c.setPreviewCandidate(slot, CoffeeImagePick(path: file.path));
      expect(c.stage, CoffeeV3FlowStage.preview);
      expect(await c.confirmCandidate(), CoffeeV3ConfirmOutcome.committedAdvance);
    }
    expect(c.stage, CoffeeV3FlowStage.finalReview);
    await c.selectIntention(CoffeeV2IntentionChoice.love);
  }

  Future<String> submitFour(CoffeeV3FlowController c) async {
    await c.boot();
    await captureFour(c);
    expect(c.canSubmit, isTrue);
    await c.beginSubmission();
    expect(c.stage, CoffeeV3FlowStage.activeObserving);
    return c.operationId!;
  }

  test('AV-AX/BA-BE exact-op polling → m2_public_v1 restored → CoffeeReading exact',
      () async {
    final c = build();
    final opId = await submitFour(c);
    final hero = c.heroPath;
    expect(hero, isNotNull);
    final tempPaths = [
      for (final s in coffeeV3CanonicalSlotOrder) c.record.slots[s]!.asset!.path,
    ];
    await waitFor(() => c.liveState != null);

    // Another Coffee operation becomes the feature-wide "active" one — the V3
    // session must never attach to it.
    await backend.send('POST', '/v1/reading-operations', {
      'readingType': 'coffee',
      'sourceRequestId': 'coffee-v2-other-1',
    });
    backend.completeServerSide(
      opId,
      resultId: 'coffee-m2-r1',
      result: m2PublicV1Result(_overall),
    );
    await waitFor(() => c.reading != null);

    final reading = c.reading!;
    expect(reading.id, 'coffee-m2-r1');
    expect(reading.isM2PublicV1, isTrue);
    expect(reading.overall, _overall);
    expect(reading.visualObservation, '');
    expect(reading.symbols, isEmpty);
    expect(reading.love + reading.career + reading.nearFuture + reading.takeaway,
        isEmpty);
    expect(readings.byId('coffee-m2-r1')?.overall, _overall);

    expect(transport.featureWideRecoveries, isEmpty);
    expect(transport.exactFetches, isNotEmpty);
    expect(
      transport.exactFetches.every((f) => f.path == '/v1/reading-operations/$opId'),
      isTrue,
    );
    expect(
      transport.calls.where((c) => c.path.endsWith('/result')).map((c) => c.path).toSet(),
      {'/v1/reading-operations/$opId/result'},
    );
    // BE temp photos released; BF handoff metadata kept until acknowledgement.
    await waitFor(() => c.record.resultPendingAcknowledgement);
    await expectDeleted(tempPaths);
    expect(c.heroPath, isNull);
    expect(c.record.operationId, opId);
    expect(c.record.resultId, 'coffee-m2-r1');
    expect(ai.calls, 0);
  });

  test('BF/BG result survives restart until New Cup; New Cup = fresh identity',
      () async {
    final c = build();
    final opId = await submitFour(c);
    backend.completeServerSide(opId,
        resultId: 'coffee-m2-r2', result: m2PublicV1Result(_overall));
    await waitFor(() => c.record.resultPendingAcknowledgement);
    c.dispose();
    controllers.remove(c);

    final restarted = build();
    final fetchesBefore = backend.resultFetchCalls;
    await restarted.boot();
    expect(restarted.reading?.id, 'coffee-m2-r2');
    expect(restarted.reading?.overall, _overall);
    expect(restarted.stage, CoffeeV3FlowStage.activeObserving);
    expect(backend.resultFetchCalls, fetchesBefore); // served locally

    restarted.resetToFreshDraft();
    await waitFor(() => restarted.reading == null);
    final store = CoffeeV3SubmissionStore(storage, ownerId: 'owner-flow');
    expect(store.load(), isNull);
    expect(store.loadAcknowledgedOperationId(), opId);
    expect(restarted.stage, CoffeeV3FlowStage.intro);

    await captureFour(restarted);
    await restarted.beginSubmission();
    expect(transport.creates.last.body?['sourceRequestId'], 'coffee-v3-src-2');
    expect(restarted.operationId, isNot(opId));
  });

  test('AY failed exact op → existing error copy, temp released, terminal',
      () async {
    final c = build();
    final opId = await submitFour(c);
    final paths = [
      for (final s in coffeeV3CanonicalSlotOrder) c.record.slots[s]!.asset!.path,
    ];
    await transport.failServerSide(opId);
    await waitFor(() => c.observeError != null);
    await waitFor(() => c.heroPath == null); // upload files released
    expect(c.observeError, ReadingLiveCopy.failed);
    expect(c.stage, CoffeeV3FlowStage.activeObserving);
    await expectDeleted(paths);
    expect(c.record.operationId, opId);
    // No in-place retake: photos cannot be replaced on this operation.
    c.setPreviewCandidate(CoffeeV3PhotoSlot.cupTurnA, const CoffeeImagePick(path: 'x'));
    expect(c.previewCandidate, isNull);
    c.resetToFreshDraft();
    await waitFor(() => c.observeError == null);
    expect(c.record.isDraft, isTrue);
    expect(c.record.sourceRequestId, isNull);
  });

  test('AZ restart while waiting observes the SAME operation id', () async {
    final c = build();
    final opId = await submitFour(c);
    c.dispose();
    controllers.remove(c);
    final before = transport.exactFetches.length;

    final restarted = build();
    await restarted.boot();
    await waitFor(() => transport.exactFetches.length > before);
    expect(restarted.operationId, opId);
    expect(transport.creates, hasLength(1));
    expect(
      transport.exactFetches.skip(before).every(
            (f) => f.path == '/v1/reading-operations/$opId',
          ),
      isTrue,
    );
    expect(transport.featureWideRecoveries, isEmpty);
  });

  test('exact op gone (404) ends terminal, never attaches elsewhere', () async {
    final c = build();
    await submitFour(c);
    // Simulate an operation the server no longer knows.
    final store = CoffeeV3SubmissionStore(storage, ownerId: 'owner-flow');
    await store.saveDurable(store.load()!.copyWith(operationId: 'f' * 32));
    c.dispose();
    controllers.remove(c);
    final restarted = build();
    await restarted.boot();
    await waitFor(() => restarted.observeError != null);
    expect(restarted.observeError, ReadingLiveCopy.failed);
    expect(transport.featureWideRecoveries, isEmpty);
  });

  group('acceleration (server-owned economy)', () {
    test('BH/BK/BM quote from server; accelerates the bound op; balance forwarded',
        () async {
      final c = build();
      final opId = await submitFour(c);
      await waitFor(() => c.canAccelerate);
      expect(c.accelerationCost, 10);
      await c.accelerateWaiting();
      expect(backend.accelerationDebitCount, 1);
      expect(backend.authoritativeBalance, 85);
      expect(balances, contains(85));
      final post = transport.calls.lastWhere(
        (c) => c.method == 'POST' && c.path.endsWith('/accelerate'),
      );
      expect(post.path, '/v1/reading-operations/$opId/accelerate');
      expect(transport.featureWideRecoveries, isEmpty);
    });

    test('BI priceChanged: no auto retry, no debit', () async {
      final c = build();
      await submitFour(c);
      await waitFor(() => c.canAccelerate);
      backend.coffeeAccelerationCost = 12;
      await c.accelerateWaiting();
      expect(c.accelerationError, ReadingLiveCopy.priceChanged);
      expect(c.accelerationCost, 12);
      expect(backend.accelerationCalls, 1);
      expect(backend.accelerationDebitCount, 0);
    });

    test('BJ insufficient gems: explicit error, no fake success', () async {
      final c = build();
      await submitFour(c);
      await waitFor(() => c.canAccelerate);
      backend.accelerationInsufficient = true;
      await c.accelerateWaiting();
      expect(c.accelerationError, ReadingLiveCopy.insufficient);
      expect(backend.accelerationDebitCount, 0);
      expect(c.reading, isNull);
    });

    test('BL active V3 stays acceleratable with the rollout flag OFF', () async {
      final c = build();
      await submitFour(c);
      allowed = false;
      c.dispose();
      controllers.remove(c);
      final restarted = build();
      await restarted.boot();
      expect(restarted.stage, CoffeeV3FlowStage.activeObserving);
      await waitFor(() => restarted.canAccelerate);
      await restarted.accelerateWaiting();
      expect(backend.accelerationDebitCount, 1);
    });
  });

  group('rollout semantics', () {
    test('E flag-off ACTIVE V3 keeps recovering to its m2 result', () async {
      final c = build();
      final opId = await submitFour(c);
      c.dispose();
      controllers.remove(c);
      allowed = false;
      backend.completeServerSide(opId,
          resultId: 'coffee-m2-flagoff', result: m2PublicV1Result(_overall));
      final restarted = build();
      await restarted.boot();
      await waitFor(() => restarted.reading != null);
      expect(restarted.reading?.overall, _overall);
      expect(restarted.reading?.isM2PublicV1, isTrue);
    });

    test('F flag-off DRAFT preserved: reviewable/replaceable, create blocked',
        () async {
      final c = build();
      await c.boot();
      await captureFour(c);
      allowed = false;
      expect(c.stage, CoffeeV3FlowStage.finalReview);
      expect(c.canSubmit, isFalse);
      expect(c.createBlock, CoffeeV3CreateBlock.creationDisabled);
      await c.beginSubmission();
      expect(transport.creates, isEmpty);
      // Replacement still allowed in a draft.
      c.beginReplacing(CoffeeV3PhotoSlot.saucer);
      final file = File('${temp.path}/replacement.jpg');
      await file.writeAsBytes(plainJpegBytes(totalSize: 31337));
      c.setPreviewCandidate(CoffeeV3PhotoSlot.saucer, CoffeeImagePick(path: file.path));
      expect(await c.confirmCandidate(),
          CoffeeV3ConfirmOutcome.committedReturnToReview);
      final replaced = c.record.slots[CoffeeV3PhotoSlot.saucer]!.asset!;
      expect(await file.exists(), isTrue); // source original untouched
      // Reopen: draft still there, never auto-cleared.
      c.dispose();
      controllers.remove(c);
      final reopened = build();
      await reopened.boot();
      expect(reopened.stage, CoffeeV3FlowStage.finalReview);
      expect(reopened.record.slots[CoffeeV3PhotoSlot.saucer]?.asset, replaced);
      // Cancel is allowed and returns the visit to the default route.
      await reopened.cancelDraft();
      expect(reopened.stage, CoffeeV3FlowStage.exitToDefault);
    });

    test('AC server V3 flag off: 400 keeps the draft, shows unavailable', () async {
      transport.rejectV3Create = true;
      final c = build();
      await c.boot();
      await captureFour(c);
      await c.beginSubmission();
      expect(c.stage, CoffeeV3FlowStage.finalReview);
      expect(c.createBlock, CoffeeV3CreateBlock.serverUnavailable);
      expect(c.operationId, isNull);
      expect(transport.stageCalls, isEmpty);
      expect(transport.gemCalls, isEmpty);
      expect(c.record.sourceRequestId, 'coffee-v3-src-1');
    });

    test('empty V3 with creation disallowed hands back to the default route',
        () async {
      allowed = false;
      final c = build();
      await c.boot();
      expect(c.stage, CoffeeV3FlowStage.exitToDefault);
    });
  });
}
