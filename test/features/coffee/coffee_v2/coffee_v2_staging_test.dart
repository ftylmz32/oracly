/// Coffee V2 client foundation — Phase 2C1 §29 "REQUIRED TESTS — STAGING"
/// (S-AB), plus the legacy/Palm no-slot serialization proofs (W/X).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_feature_runner.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late FakeReadingOperationBackend backend;
  late RecordingStagedTransport transport;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_v2_staging_test_');
    PathProviderPlatform.instance = FakePathProvider(temp.path);
    backend = FakeReadingOperationBackend();
    transport = RecordingStagedTransport(backend);
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
      store: CoffeeV2SubmissionStore(LocalStorage.ephemeral()),
      messages: coffeeV2TestMessages,
    );
  }

  Future<String> writeJpeg(String name, {int totalSize = 9 * 1024}) async {
    final path = '${temp.path}/$name';
    await File(path).writeAsBytes(plainJpegBytes(totalSize: totalSize));
    return path;
  }

  Future<CoffeeV2SubmissionController> readyToSubmit() async {
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
    return controller;
  }

  test('S — one and only one ReadingOperation is created', () async {
    final controller = await readyToSubmit();
    await controller.beginSubmission('src-s');
    expect(backend.operationCount, 1);
  });

  test('T — stage calls occur exactly cup_primary, cup_secondary, saucer', () async {
    final controller = await readyToSubmit();
    await controller.beginSubmission('src-t');
    expect(transport.slotCallOrder, ['cup_primary', 'cup_secondary', 'saucer']);
  });

  test('U — stage calls are sequential, never concurrent', () async {
    final controller = await readyToSubmit();
    await controller.beginSubmission('src-u');
    expect(transport.maxConcurrentObserved, 1);
  });

  test('V — each request sends its correct slot', () async {
    final controller = await readyToSubmit();
    await controller.beginSubmission('src-v');
    expect(transport.stageCallCountBySlot['cup_primary'], 1);
    expect(transport.stageCallCountBySlot['cup_secondary'], 1);
    expect(transport.stageCallCountBySlot['saucer'], 1);
  });

  test(
    'W — legacy staged-image gateway call with no slot serializes exactly as before',
    () async {
      Map<String, Object>? capturedBody;
      final gateway = ReadingStagedImageGateway((method, path, body) async {
        capturedBody = body;
        return const ReadingOperationWire(
          statusCode: 200,
          json: {'data': {'staged': true}},
        );
      });

      await gateway.stage(
        operationId: 'op-legacy',
        bytes: const [1, 2, 3],
        mimeType: 'image/jpeg',
      );

      expect(capturedBody, isNotNull);
      expect(capturedBody!.containsKey('slot'), isFalse);
      expect(capturedBody!.containsKey('handSide'), isFalse);
      expect(capturedBody!['mimeType'], 'image/jpeg');
    },
  );

  test('X — Palm continues sending no slot', () async {
    Map<String, Object>? capturedBody;
    final palmBackend = FakeReadingOperationBackend();
    Future<ReadingOperationWire?> wrappedSend(
      String method,
      String path,
      Map<String, Object>? body,
    ) {
      if (path.endsWith('/staged-image')) capturedBody = body;
      return palmBackend.send(method, path, body);
    }

    final runner = fakeImmediateReadingFeatureRunner(
      backend: palmBackend,
      serverOwnedCompletion: true,
    );
    // Re-point the runner's staged-image gateway through the capturing
    // wrapper while reusing the SAME backend, mirroring exactly what
    // `submit()` sends for a real Palm reading.
    final capturingRunner = ReadingFeatureRunner(
      flow: runner.flow,
      stagedImages: ReadingStagedImageGateway(wrappedSend),
      serverOwnedCompletion: true,
    );

    await capturingRunner.submit(
      readingType: ReadingType.palm,
      sourceRequestId: 'src-x',
      runPipeline: () async => 'unused',
      imageBytes: const [9, 9, 9],
      mimeType: 'image/jpeg',
      handSide: 'right',
    );

    expect(capturedBody, isNotNull);
    expect(capturedBody!.containsKey('slot'), isFalse);
    expect(capturedBody!['handSide'], 'right');
  });

  test('Y — slot #2 failure prevents #3 attempt', () async {
    final controller = await readyToSubmit();
    transport.failSlotsOnce.add('cup_secondary');

    final outcome = await controller.beginSubmission('src-y');

    expect(outcome, CoffeeV2SubmissionOutcome.retryableFailure);
    expect(transport.slotCallOrder, ['cup_primary', 'cup_secondary']);
    expect(controller.record.operationId, isNotNull);
  });

  test('Z — retry resumes from #2 using SAME operationId', () async {
    final controller = await readyToSubmit();
    transport.failSlotsOnce.add('cup_secondary');
    await controller.beginSubmission('src-z');
    final operationIdAfterFailure = controller.record.operationId;

    final retryOutcome = await controller.retrySubmission();

    expect(retryOutcome, CoffeeV2SubmissionOutcome.completedStaging);
    expect(controller.record.operationId, operationIdAfterFailure);
    expect(backend.operationCount, 1);
    expect(transport.slotCallOrder, [
      'cup_primary',
      'cup_secondary', // failed attempt
      'cup_secondary', // retry
      'saucer',
    ]);
  });

  test('AA — #3 failure preserves #1/#2 state', () async {
    final controller = await readyToSubmit();
    transport.failSlotsOnce.add('saucer');

    final outcome = await controller.beginSubmission('src-aa');

    expect(outcome, CoffeeV2SubmissionOutcome.retryableFailure);
    expect(transport.stageCallCountBySlot['cup_primary'], 1);
    expect(transport.stageCallCountBySlot['cup_secondary'], 1);
    expect(transport.stageCallCountBySlot['saucer'], 1);
    expect(backend.operationCount, 1);
  });

  test('AB — retry resumes #3 using SAME operationId', () async {
    final controller = await readyToSubmit();
    transport.failSlotsOnce.add('saucer');
    await controller.beginSubmission('src-ab');
    final operationIdAfterFailure = controller.record.operationId;

    final retryOutcome = await controller.retrySubmission();

    expect(retryOutcome, CoffeeV2SubmissionOutcome.completedStaging);
    expect(controller.record.operationId, operationIdAfterFailure);
    expect(backend.operationCount, 1);
    // cup_primary/cup_secondary are never re-sent on retry — only saucer.
    expect(transport.stageCallCountBySlot['cup_primary'], 1);
    expect(transport.stageCallCountBySlot['cup_secondary'], 1);
    expect(transport.stageCallCountBySlot['saucer'], 2);
  });
}
