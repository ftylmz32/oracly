/// Coffee V2 client foundation — Phase 2C1 §31 "REQUIRED TESTS — RESTART /
/// RECOVERY" (AH-AO). Each "restart" is simulated by discarding the old
/// controller and building a fresh one against the SAME store/backend,
/// then calling `recoverDraftOrSubmission()`.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_stage_state.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';
import '../../../support/false_return_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late FakeReadingOperationBackend backend;
  late RecordingStagedTransport transport;
  late LocalStorage sharedStorage;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_v2_restart_test_');
    PathProviderPlatform.instance = FakePathProvider(temp.path);
    backend = FakeReadingOperationBackend();
    transport = RecordingStagedTransport(backend);
    // Survives across "restarts" in these tests exactly like
    // SharedPreferences survives an app restart on a real device.
    sharedStorage = LocalStorage.ephemeral();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  CoffeeV2SubmissionController buildController() {
    final operations = ReadingOperationGateway(send: transport.send);
    return CoffeeV2SubmissionController(
      flow: ReadingLiveFlow(
        operations: operations,
        acceleration: ReadingAccelerationClient(send: transport.send),
        send: transport.send,
      ),
      stagedImages: ReadingStagedImageGateway(transport.send),
      store: CoffeeV2SubmissionStore(sharedStorage),
      messages: coffeeV2TestMessages,
    );
  }

  Future<String> writeJpeg(String name, {int totalSize = 9 * 1024}) async {
    final path = '${temp.path}/$name';
    await File(path).writeAsBytes(plainJpegBytes(totalSize: totalSize));
    return path;
  }

  test('AH — DRAFT restart restores valid selected slots', () async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
    await controller.setSlot(
      CoffeeV2PhotoSlot.cupPrimary,
      CoffeeImagePick(path: primary),
    );
    await controller.setSlot(
      CoffeeV2PhotoSlot.cupSecondary,
      CoffeeImagePick(path: secondary),
    );
    final primaryChecksum = controller
        .assetFor(CoffeeV2PhotoSlot.cupPrimary)!
        .sha256;
    final secondaryChecksum = controller
        .assetFor(CoffeeV2PhotoSlot.cupSecondary)!
        .sha256;

    // Simulate restart: fresh controller instance, same persisted store.
    final restarted = buildController();
    await restarted.recoverDraftOrSubmission();

    expect(restarted.record.isDraft, isTrue);
    expect(
      restarted.assetFor(CoffeeV2PhotoSlot.cupPrimary)?.sha256,
      primaryChecksum,
    );
    expect(
      restarted.assetFor(CoffeeV2PhotoSlot.cupSecondary)?.sha256,
      secondaryChecksum,
    );
    expect(restarted.assetFor(CoffeeV2PhotoSlot.saucer), isNull);
  });

  test('AI — missing one draft file clears only that slot', () async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
    await controller.setSlot(
      CoffeeV2PhotoSlot.cupPrimary,
      CoffeeImagePick(path: primary),
    );
    await controller.setSlot(
      CoffeeV2PhotoSlot.cupSecondary,
      CoffeeImagePick(path: secondary),
    );
    final primaryChecksum = controller
        .assetFor(CoffeeV2PhotoSlot.cupPrimary)!
        .sha256;

    // The secondary's normalized working file disappears (device cleanup,
    // corruption, etc.) before restart.
    await File(
      controller.assetFor(CoffeeV2PhotoSlot.cupSecondary)!.path,
    ).delete();

    final restarted = buildController();
    await restarted.recoverDraftOrSubmission();

    expect(
      restarted.assetFor(CoffeeV2PhotoSlot.cupPrimary)?.sha256,
      primaryChecksum,
    );
    expect(restarted.assetFor(CoffeeV2PhotoSlot.cupSecondary), isNull);
  });

  Future<CoffeeV2SubmissionController> activeSubmissionWithFailure(
    String failSlot,
  ) async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
    final saucer = await writeJpeg('saucer.jpg', totalSize: 9201);
    for (final entry in {
      CoffeeV2PhotoSlot.cupPrimary: primary,
      CoffeeV2PhotoSlot.cupSecondary: secondary,
      CoffeeV2PhotoSlot.saucer: saucer,
    }.entries) {
      await controller.setSlot(entry.key, CoffeeImagePick(path: entry.value));
      await controller.confirmSlot(entry.key);
    }
    transport.failSlotsOnce.add(failSlot);
    await controller.beginSubmission('src-restart');
    return controller;
  }

  test('AJ — ACTIVE restart preserves operationId', () async {
    final controller = await activeSubmissionWithFailure('cup_secondary');
    final operationId = controller.record.operationId;
    expect(operationId, isNotNull);

    final restarted = buildController();
    await restarted.recoverDraftOrSubmission();

    expect(restarted.record.operationId, operationId);
  });

  test('AK — ACTIVE restart does not create a second operation', () async {
    final controller = await activeSubmissionWithFailure('cup_secondary');
    expect(controller.record.operationId, isNotNull);
    expect(backend.operationCount, 1);

    final restarted = buildController();
    await restarted.recoverDraftOrSubmission();
    await restarted.retrySubmission();

    expect(backend.operationCount, 1);
  });

  test('AL — process death after backend stage success but before local '
      'stage-state save can safely re-stage the same slot', () async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
    final saucer = await writeJpeg('saucer.jpg', totalSize: 9201);
    for (final entry in {
      CoffeeV2PhotoSlot.cupPrimary: primary,
      CoffeeV2PhotoSlot.cupSecondary: secondary,
      CoffeeV2PhotoSlot.saucer: saucer,
    }.entries) {
      await controller.setSlot(entry.key, CoffeeImagePick(path: entry.value));
      await controller.confirmSlot(entry.key);
    }

    // Drive the exact pre-crash sequence by hand: create the operation
    // and stage cup_primary against the REAL fake backend (so the
    // server genuinely has it), but persist a record whose cup_primary
    // stageState is still `notStaged` — precisely what a crash between
    // the HTTP 200 and the local disk write would leave behind.
    final begun = await controller.flow.begin(
      readingType: ReadingType.coffee,
      sourceRequestId: 'src-al',
    );
    final operationId = begun.snapshot!.operationId;
    final primaryAsset = controller.assetFor(CoffeeV2PhotoSlot.cupPrimary)!;
    final staged = await controller.stagedImages.stage(
      operationId: operationId,
      bytes: await File(primaryAsset.path).readAsBytes(),
      mimeType: primaryAsset.mimeType,
      slot: CoffeeV2PhotoSlot.cupPrimary.wireValue,
    );
    expect(staged, isTrue);
    final crashedRecord = controller.record.copyWith(
      operationId: operationId,
      sourceRequestId: 'src-al',
    );
    await CoffeeV2SubmissionStore(sharedStorage).save(crashedRecord);

    final restarted = buildController();
    await restarted.recoverDraftOrSubmission();
    expect(restarted.record.operationId, operationId);
    expect(
      restarted.record.slots[CoffeeV2PhotoSlot.cupPrimary]!.stageState,
      CoffeeV2StageState.notStaged,
    );

    final outcome = await restarted.retrySubmission();

    expect(outcome, CoffeeV2SubmissionOutcome.completedStaging);
    expect(backend.operationCount, 1);
    // cup_primary was staged twice: once "before the crash", once on
    // the post-restart retry — safe because backend staging is
    // idempotent per slot/operation.
    expect(transport.stageCallCountBySlot['cup_primary'], 2);
    expect(transport.stageCallCountBySlot['cup_secondary'], 1);
    expect(transport.stageCallCountBySlot['saucer'], 1);
  });

  test('AM — slot #2 retry after restart uses same operationId', () async {
    final controller = await activeSubmissionWithFailure('cup_secondary');
    final operationId = controller.record.operationId;

    final restarted = buildController();
    await restarted.recoverDraftOrSubmission();
    final outcome = await restarted.retrySubmission();

    expect(outcome, CoffeeV2SubmissionOutcome.completedStaging);
    expect(restarted.record.operationId, operationId);
    expect(backend.operationCount, 1);
  });

  test(
    'AN — successful operation completion clears V2 submission metadata',
    () async {
      final controller = buildController();
      final primary = await writeJpeg('primary.jpg', totalSize: 9001);
      final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
      final saucer = await writeJpeg('saucer.jpg', totalSize: 9201);
      for (final entry in {
        CoffeeV2PhotoSlot.cupPrimary: primary,
        CoffeeV2PhotoSlot.cupSecondary: secondary,
        CoffeeV2PhotoSlot.saucer: saucer,
      }.entries) {
        await controller.setSlot(entry.key, CoffeeImagePick(path: entry.value));
        await controller.confirmSlot(entry.key);
      }
      await controller.beginSubmission('src-an');
      final tempFiles = coffeeV2CanonicalSlotOrder
          .map((slot) => controller.assetFor(slot)!.path)
          .toList();

      final operationId = controller.record.operationId;
      await controller.onResultRestored('result-an');

      expect(controller.record.operationId, operationId);
      expect(controller.record.resultId, 'result-an');
      expect(controller.record.resultPendingAcknowledgement, isTrue);
      for (final path in tempFiles) {
        expect(await File(path).exists(), isFalse);
      }
      final store = CoffeeV2SubmissionStore(sharedStorage);
      expect(store.load()?.operationId, operationId);

      await controller.acknowledgeTerminalHandoff();
      expect(store.load(), isNull);
      expect(store.loadAcknowledgedOperationId(), operationId);
    },
  );

  test(
    'AP — false-returning draft persistence never advances in-memory slot state',
    () async {
      SharedPreferences.setMockInitialValues({});
      final failing = FalseReturnLocalStorage(
        await SharedPreferences.getInstance(),
      )..falseReturnKeys.add('coffee_v2_submission');
      sharedStorage = failing;
      final controller = buildController();
      final primary = await writeJpeg('ap-primary.jpg', totalSize: 9001);

      await expectLater(
        controller.setSlot(
          CoffeeV2PhotoSlot.cupPrimary,
          CoffeeImagePick(path: primary),
        ),
        throwsStateError,
      );

      expect(controller.assetFor(CoffeeV2PhotoSlot.cupPrimary), isNull);
      expect(CoffeeV2SubmissionStore(sharedStorage).load(), isNull);
    },
  );

  test(
    'AQ — operationId bind write loss restarts with the same durable sourceRequestId',
    () async {
      SharedPreferences.setMockInitialValues({});
      final durable = _FailNthStringStorage(
        await SharedPreferences.getInstance(),
      );
      sharedStorage = durable;
      final controller = buildController();
      final primary = await writeJpeg('aq-primary.jpg', totalSize: 9001);
      final secondary = await writeJpeg('aq-secondary.jpg', totalSize: 9101);
      final saucer = await writeJpeg('aq-saucer.jpg', totalSize: 9201);
      for (final entry in {
        CoffeeV2PhotoSlot.cupPrimary: primary,
        CoffeeV2PhotoSlot.cupSecondary: secondary,
        CoffeeV2PhotoSlot.saucer: saucer,
      }.entries) {
        await controller.setSlot(entry.key, CoffeeImagePick(path: entry.value));
        await controller.confirmSlot(entry.key);
      }

      // beginSubmission performs two critical writes: sourceRequestId BEFORE
      // create, then operationId AFTER create. Fail only the second one.
      durable.failAt = durable.setStringAttempts + 2;
      await expectLater(
        controller.beginSubmission('src-aq-stable'),
        throwsStateError,
      );
      expect(backend.operationCount, 1);
      expect(controller.record.isDraft, isTrue);
      expect(controller.record.sourceRequestId, 'src-aq-stable');

      durable.failAt = null;
      final restarted = buildController();
      await restarted.recoverDraftOrSubmission();
      expect(restarted.record.sourceRequestId, 'src-aq-stable');
      final outcome = await restarted.beginSubmission('src-aq-must-not-replace');

      expect(outcome, CoffeeV2SubmissionOutcome.completedStaging);
      expect(backend.operationCount, 1);
      expect(restarted.record.operationId, isNotNull);
      expect(restarted.record.sourceRequestId, 'src-aq-stable');
    },
  );

  test(
    'AR — terminal clear false keeps durable + in-memory operation for retry',
    () async {
      SharedPreferences.setMockInitialValues({});
      final failing = FalseReturnLocalStorage(
        await SharedPreferences.getInstance(),
      );
      sharedStorage = failing;
      final store = CoffeeV2SubmissionStore(sharedStorage);
      final active = CoffeeV2SubmissionRecord.empty().copyWith(
        operationId: 'a' * 32,
        sourceRequestId: 'src-ar',
        resultId: 'result-ar',
        resultPendingAcknowledgement: true,
      );
      await store.save(active);
      final controller = buildController();
      await controller.recoverDraftOrSubmission();
      failing.falseReturnRemoveKeys.add('coffee_v2_submission');

      await expectLater(
        controller.acknowledgeTerminalHandoff(),
        throwsStateError,
      );

      expect(controller.record.operationId, 'a' * 32);
      expect(store.load()?.operationId, 'a' * 32);
      expect(store.loadAcknowledgedOperationId(), 'a' * 32);
    },
  );

  test('AO — retryable failure keeps V2 metadata/local files', () async {
    final controller = await activeSubmissionWithFailure('saucer');
    final tempFiles = coffeeV2CanonicalSlotOrder
        .map((slot) => controller.assetFor(slot)!.path)
        .toList();

    for (final path in tempFiles) {
      expect(await File(path).exists(), isTrue);
    }
    final store = CoffeeV2SubmissionStore(sharedStorage);
    expect(store.load()?.operationId, controller.record.operationId);
  });
}

class _FailNthStringStorage extends LocalStorage {
  _FailNthStringStorage(super.prefs);

  int setStringAttempts = 0;
  int? failAt;

  @override
  Future<bool> setString(String key, String value) async {
    setStringAttempts++;
    if (failAt == setStringAttempts) return false;
    return super.setString(key, value);
  }
}
