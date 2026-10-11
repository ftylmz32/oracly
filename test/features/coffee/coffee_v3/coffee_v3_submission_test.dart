/// Coffee V3 submission controller: validation gates, backend V3-create
/// rejection (draft + sourceRequestId preserved, no staging, no gems, no V2
/// fallback), sequential resume-safe three-slot staging (two cup + saucer),
/// post-create photo
/// immutability, draft/active restart recovery and draft cancel.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_stage_state.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_pending_operation_store.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/coffee_v3_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

const _intention = 'Aşk ve ilişkilerim hakkında';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late FakeReadingOperationBackend backend;
  late CoffeeV3TestTransport transport;
  late List<String> chronology;
  var allowed = true;
  var sizeSeed = 9000;
  var sourceCounter = 0;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_v3_sub_');
    installCoffeeV3SupportRoot(temp.path);
    storage = LocalStorage.ephemeral();
    backend = FakeReadingOperationBackend(immediatelyEligible: false);
    chronology = [];
    transport = CoffeeV3TestTransport(backend, chronology: chronology);
    allowed = true;
    sourceCounter = 0;
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  CoffeeV3SubmissionStore storeFor([String owner = 'owner-v3']) =>
      CoffeeV3SubmissionStore(storage, ownerId: owner, requireOwner: true);

  CoffeeV3SubmissionController build({CoffeeV3SubmissionStore? store}) {
    final flow = ReadingLiveFlow(
      operations: ReadingOperationGateway(send: transport.send),
      acceleration: ReadingAccelerationClient(send: transport.send),
      send: transport.send,
    );
    return CoffeeV3SubmissionController(
      flow: flow,
      stagedImages: ReadingStagedImageGateway(transport.send),
      store: store ?? storeFor(),
      byteLoader: RecordingByteLoader(chronology),
      normalizer: ownedCoffeeV3Normalizer(temp.path),
      messages: coffeeV3TestMessages,
      creationAllowed: () => allowed,
      newSourceRequestId: () => 'coffee-v3-src-${++sourceCounter}',
    );
  }

  Future<CoffeeImagePick> photo(String name, {int? size}) async {
    final file = File('${temp.path}/$name.jpg');
    await file.writeAsBytes(plainJpegBytes(totalSize: size ?? (sizeSeed += 37)));
    return CoffeeImagePick(path: file.path, mimeType: 'image/jpeg');
  }

  Future<void> fillAll(CoffeeV3SubmissionController c) async {
    for (final slot in coffeeV3CanonicalSlotOrder) {
      final r = await c.selectSlot(slot, await photo(slot.wireValue));
      expect(r.isSuccess, isTrue, reason: slot.name);
    }
    await c.setIntention(_intention);
  }

  group('validation gates', () {
    test('R/U/V/W/X: no operation before every condition holds', () async {
      final c = build();
      for (final slot in coffeeV3CanonicalSlotOrder.take(2)) {
        await c.selectSlot(slot, await photo(slot.wireValue));
      }
      await c.setIntention(_intention);
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.blockedByValidation);
      await c.selectSlot(CoffeeV3PhotoSlot.saucer, await photo('saucer'));
      await c.setIntention(null);
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.blockedByValidation);
      expect(await c.setIntention('<script>'), isFalse);
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.blockedByValidation);
      await c.setIntention(_intention);
      allowed = false; // rollout off OR non-tr
      expect(c.readyToCreate, isFalse);
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.creationDisabled);
      expect(transport.creates, isEmpty);
      expect(c.record.sourceRequestId, isNull);
      allowed = true;
      expect(c.readyToCreate, isTrue);
    });

    test('T duplicate photo in ANY later slot is rejected, old asset kept',
        () async {
      final c = build();
      final first = await photo('first', size: 12000);
      await c.selectSlot(CoffeeV3PhotoSlot.cupViewA, first);
      for (final slot in coffeeV3CanonicalSlotOrder.skip(1)) {
        final same = await photo('dup_${slot.name}', size: 12000);
        final r = await c.selectSlot(slot, same);
        expect(r.failure, CoffeeV3SlotSelectionFailure.duplicate);
        expect(r.duplicateOf, CoffeeV3PhotoSlot.cupViewA);
        expect(c.assetFor(slot), isNull);
      }
      // Replacing the saucer with a duplicate of the second cup view keeps
      // the saucer's old photo (a cup photo never stands in for the saucer).
      await c.selectSlot(CoffeeV3PhotoSlot.cupViewB, await photo('a', size: 13000));
      await c.selectSlot(CoffeeV3PhotoSlot.saucer, await photo('b', size: 14000));
      final oldSaucer = c.assetFor(CoffeeV3PhotoSlot.saucer);
      final r = await c.selectSlot(
        CoffeeV3PhotoSlot.saucer,
        await photo('b_dup', size: 13000),
      );
      expect(r.failure, CoffeeV3SlotSelectionFailure.duplicate);
      expect(r.duplicateOf, CoffeeV3PhotoSlot.cupViewB);
      expect(c.assetFor(CoffeeV3PhotoSlot.saucer), oldSaucer);
      expect(await File(oldSaucer!.path).exists(), isTrue);
    });

    test('invalid replacement leaves the previous confirmed asset intact',
        () async {
      final c = CoffeeV3SubmissionController(
        flow: ReadingLiveFlow(
          operations: ReadingOperationGateway(send: transport.send),
          acceleration: ReadingAccelerationClient(send: transport.send),
          send: transport.send,
        ),
        stagedImages: ReadingStagedImageGateway(transport.send),
        store: storeFor(),
        normalizer: ownedCoffeeV3Normalizer(temp.path, failWhen: 'broken'),
        messages: coffeeV3TestMessages,
        creationAllowed: () => true,
      );
      final ok = await c.selectSlot(CoffeeV3PhotoSlot.saucer, await photo('ok'));
      expect(ok.isSuccess, isTrue);
      final r = await c.selectSlot(CoffeeV3PhotoSlot.saucer, await photo('broken'));
      expect(r.isSuccess, isFalse);
      expect(c.assetFor(CoffeeV3PhotoSlot.saucer), ok.asset);
    });
  });

  group('backend V3 flag off (400 invalid_request)', () {
    test('AC-AI draft kept, same sourceRequestId, no staging, no gems, no V2',
        () async {
      transport.rejectV3Create = true;
      final c = build();
      await fillAll(c);
      final assetsBefore = {
        for (final s in coffeeV3CanonicalSlotOrder) s: c.assetFor(s),
      };
      expect(await c.beginSubmission(), CoffeeV3SubmissionOutcome.createRejected);
      expect(c.record.operationId, isNull);
      expect(c.record.isDraft, isTrue);
      final source = c.record.sourceRequestId;
      expect(source, 'coffee-v3-src-1');
      expect(storeFor().load()?.sourceRequestId, source);
      for (final s in coffeeV3CanonicalSlotOrder) {
        expect(c.assetFor(s), assetsBefore[s]);
        expect(c.record.slots[s]?.confirmed, isTrue);
        expect(await File(c.assetFor(s)!.path).exists(), isTrue);
      }
      expect(transport.stageCalls, isEmpty);
      expect(transport.gemCalls, isEmpty);
      expect(backend.operationCount, 0);
      // No V2 fallback / remap.
      expect(storage.getString('coffee_v2_submission'), isNull);
      expect(CoffeeV2SubmissionStore(storage, ownerId: 'owner-v3').load(), isNull);
      expect(
        transport.creates.every(
          (c) => c.body?['coffeeCaptureContract'] == 'three_view_v3',
        ),
        isTrue,
      );

      // AH retry (server flag now on) reuses the SAME sourceRequestId.
      transport.rejectV3Create = false;
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.completedStaging);
      expect(transport.creates, hasLength(2));
      expect(transport.creates.map((c) => c.body?['sourceRequestId']).toSet(),
          {'coffee-v3-src-1'});
      expect(backend.operationCount, 1);
    });

    test('transport drop before bind: retryable, same id reused on retry',
        () async {
      transport.dropNextCreate = true;
      final c = build();
      await fillAll(c);
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.retryableFailure);
      expect(c.record.operationId, isNull);
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.completedStaging);
      expect(transport.creates.map((c) => c.body?['sourceRequestId']).toSet(),
          {'coffee-v3-src-1'});
    });
  });

  group('creation + staging', () {
    test('Y/AJ-AM one create, exact body, three ordered namespaced one-at-a-time stages',
        () async {
      final c = build();
      await fillAll(c);
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.completedStaging);
      expect(transport.creates.single.body, {
        'readingType': 'coffee',
        'sourceRequestId': 'coffee-v3-src-1',
        'language': 'tr',
        'intention': _intention,
        'coffeeInputContract': 'trusted_intention_v1',
        'coffeeCaptureContract': 'three_view_v3',
      });
      expect(backend.operationCount, 1);
      expect(transport.stagedSlots, [
        'v3_cup_view_a',
        'v3_cup_view_b',
        'v3_saucer_view',
      ]);
      final opId = c.record.operationId!;
      expect(
        transport.stageCalls.every(
          (s) => s.path == '/v1/reading-operations/$opId/staged-image',
        ),
        isTrue,
      );
      // Strict load → stage → next load: never two byte arrays at once.
      final events = chronology.where((e) => e.startsWith('load:') ||
          e.startsWith('stage:')).toList();
      expect(events, hasLength(6));
      for (var i = 0; i < 6; i += 2) {
        expect(events[i], startsWith('load:'));
        expect(events[i + 1], 'stage:${coffeeV3CanonicalSlotOrder[i ~/ 2].wireValue}');
      }
      expect(transport.staged.maxConcurrentObserved, 1);
      expect(
        coffeeV3CanonicalSlotOrder.every(
          (s) => c.record.slots[s]?.stageState == CoffeeV3StageState.staged,
        ),
        isTrue,
      );
    });

    test('AN-AP failure at slot 2: slot 1 stays staged; retry resumes 2/3 on same op',
        () async {
      transport.staged.failSlotsOnce.add('v3_cup_view_b');
      final c = build();
      await fillAll(c);
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.retryableFailure);
      final opId = c.record.operationId;
      expect(opId, isNotNull);
      expect(c.record.slots[CoffeeV3PhotoSlot.cupViewA]?.stageState,
          CoffeeV3StageState.staged);
      expect(c.record.slots[CoffeeV3PhotoSlot.cupViewB]?.stageState,
          CoffeeV3StageState.notStaged);
      expect(c.record.slots[CoffeeV3PhotoSlot.saucer]?.stageState,
          CoffeeV3StageState.notStaged);
      expect(c.assetFor(CoffeeV3PhotoSlot.saucer), isNotNull);

      expect(await c.retrySubmission(),
          CoffeeV3SubmissionOutcome.completedStaging);
      expect(c.record.operationId, opId);
      expect(c.record.sourceRequestId, 'coffee-v3-src-1');
      expect(transport.creates, hasLength(1));
      expect(backend.operationCount, 1);
      expect(transport.stagedSlots, [
        'v3_cup_view_a',
        'v3_cup_view_b', // failed attempt
        'v3_cup_view_b',
        'v3_saucer_view',
      ]);
    });

    test('AQ app restart midway resumes the SAME operation, no new create',
        () async {
      transport.staged.failSlotsOnce.add('v3_cup_view_b');
      final first = build();
      await fillAll(first);
      await first.beginSubmission();
      final opId = first.record.operationId!;

      final restarted = build(); // fresh process, same durable store
      await restarted.recoverDraftOrSubmission();
      expect(restarted.record.operationId, opId);
      expect(restarted.record.sourceRequestId, 'coffee-v3-src-1');
      expect(await restarted.retrySubmission(),
          CoffeeV3SubmissionOutcome.completedStaging);
      expect(transport.creates, hasLength(1));
      expect(sourceCounter, 1);
      expect(transport.stagedSlots.where((s) => s == 'v3_cup_view_a'),
          hasLength(1));
    });

    test('kill between create and bind: same sourceRequestId → same operation',
        () async {
      final c = build();
      await fillAll(c);
      // Server already created the operation for this id (bind never landed).
      await c.beginSubmission();
      final opId = c.record.operationId!;
      final record = c.record.copyWith(operationId: null, slots: {
        for (final s in coffeeV3CanonicalSlotOrder)
          s: c.record.slots[s]!.copyWith(stageState: CoffeeV3StageState.notStaged),
      });
      await storeFor().saveDurable(record);
      final restarted = build();
      await restarted.recoverDraftOrSubmission();
      expect(restarted.record.sourceRequestId, 'coffee-v3-src-1');
      expect(await restarted.beginSubmission(),
          CoffeeV3SubmissionOutcome.completedStaging);
      expect(restarted.record.operationId, opId);
      expect(backend.operationCount, 1);
    });
  });

  group('post-create immutability', () {
    test('AR-AU replace / clear / new photo / intention rejected once active',
        () async {
      final c = build();
      await fillAll(c);
      await c.beginSubmission();
      final before = c.record.slots[CoffeeV3PhotoSlot.cupViewB]?.asset;
      await expectLater(
        c.selectSlot(CoffeeV3PhotoSlot.cupViewB, await photo('retake')),
        throwsStateError,
      );
      await expectLater(c.clearSlot(CoffeeV3PhotoSlot.cupViewB), throwsStateError);
      await expectLater(c.setIntention('Para'), throwsStateError);
      await expectLater(c.cancelDraft(), throwsStateError);
      expect(await c.beginSubmission(),
          CoffeeV3SubmissionOutcome.activeSubmissionInProgress);
      expect(c.record.slots[CoffeeV3PhotoSlot.cupViewB]?.asset, before);
      expect(transport.creates, hasLength(1));
    });
  });

  group('restart / cancel', () {
    test('draft restart restores valid slots, clears only the invalid one',
        () async {
      final c = build();
      await fillAll(c);
      final viewB = c.assetFor(CoffeeV3PhotoSlot.cupViewB)!;
      await File(viewB.path).writeAsBytes(plainJpegBytes(totalSize: 4242));
      final restarted = build();
      await restarted.recoverDraftOrSubmission();
      expect(restarted.record.isDraft, isTrue);
      expect(restarted.assetFor(CoffeeV3PhotoSlot.cupViewB), isNull);
      for (final s in [
        CoffeeV3PhotoSlot.cupViewA,
        CoffeeV3PhotoSlot.saucer,
      ]) {
        expect(restarted.assetFor(s), c.assetFor(s));
        expect(restarted.record.slots[s]?.confirmed, isTrue);
      }
      expect(transport.creates, isEmpty); // never auto-submits
    });

    test('cancel deletes only V3 draft data (V2 / legacy untouched)', () async {
      await storage.setString('coffee_v2_submission', '{"slots":{}}');
      final pending = ReadingPendingOperationStore(storage);
      final c = build();
      await fillAll(c);
      final paths = [for (final s in coffeeV3CanonicalSlotOrder) c.assetFor(s)!.path];
      await c.cancelDraft();
      expect(storage.getString(CoffeeV3SubmissionStore.key), isNull);
      for (final p in paths) {
        expect(await File(p).exists(), isFalse);
      }
      expect(storage.getString('coffee_v2_submission'), '{"slots":{}}');
      expect(pending.load(ReadingType.coffee), isNull);
      expect(transport.calls, isEmpty);
    });

    test('owner switch never exposes or stages owner A\'s files', () async {
      final a = build(store: storeFor('owner-a'));
      await fillAll(a);
      final b = build(store: storeFor('owner-b'));
      await b.recoverDraftOrSubmission();
      expect(b.record.isDraft, isTrue);
      expect(coffeeV3CanonicalSlotOrder.every((s) => b.assetFor(s) == null), isTrue);
      expect(await b.beginSubmission(),
          CoffeeV3SubmissionOutcome.blockedByValidation);
      expect(transport.calls, isEmpty);
      expect(storeFor('owner-a').load()?.slots[CoffeeV3PhotoSlot.saucer]?.asset,
          isNotNull);
    });
  });
}
