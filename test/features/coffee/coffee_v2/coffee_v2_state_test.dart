/// Coffee V2 client foundation — Phase 2C1 §27 "REQUIRED TESTS — STATE"
/// (A-J). No camera UI here — this exercises the state/controller
/// foundation directly.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
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

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_v2_state_test_');
    PathProviderPlatform.instance = FakePathProvider(temp.path);
    backend = FakeReadingOperationBackend();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  CoffeeV2SubmissionController buildController() {
    final operations = ReadingOperationGateway(send: backend.send);
    return CoffeeV2SubmissionController(
      flow: ReadingLiveFlow(
        operations: operations,
        acceleration: ReadingAccelerationClient(send: backend.send),
        send: backend.send,
      ),
      stagedImages: ReadingStagedImageGateway(backend.send),
      store: CoffeeV2SubmissionStore(LocalStorage.ephemeral()),
      messages: coffeeV2TestMessages,
    );
  }

  Future<String> writeJpeg(String name, {int totalSize = 9 * 1024}) async {
    final path = '${temp.path}/$name';
    await File(path).writeAsBytes(plainJpegBytes(totalSize: totalSize));
    return path;
  }

  test('A — exactly three canonical slots exist, in locked order', () {
    expect(coffeeV2CanonicalSlotOrder, [
      CoffeeV2PhotoSlot.cupPrimary,
      CoffeeV2PhotoSlot.cupSecondary,
      CoffeeV2PhotoSlot.saucer,
    ]);
    expect(coffeeV2CanonicalSlotOrder.length, 3);
  });

  test('B — asset model stores path/metadata, not bytes', () async {
    final controller = buildController();
    final path = await writeJpeg('primary.jpg');
    final result = await controller.setSlot(
      CoffeeV2PhotoSlot.cupPrimary,
      CoffeeImagePick(path: path),
    );
    expect(result.isSuccess, isTrue);
    final asset = result.asset!;
    expect(
      asset.toJson().keys.toSet(),
      {'slot', 'path', 'mimeType', 'sha256', 'sizeBytes'},
    );
  });

  test(
    'C — three file paths may coexist without three in-memory byte buffers',
    () async {
      final controller = buildController();
      final primary = await writeJpeg('primary.jpg', totalSize: 9001);
      final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
      final saucer = await writeJpeg('saucer.jpg', totalSize: 9201);

      await controller.setSlot(
        CoffeeV2PhotoSlot.cupPrimary,
        CoffeeImagePick(path: primary),
      );
      await controller.setSlot(
        CoffeeV2PhotoSlot.cupSecondary,
        CoffeeImagePick(path: secondary),
      );
      await controller.setSlot(
        CoffeeV2PhotoSlot.saucer,
        CoffeeImagePick(path: saucer),
      );

      for (final slot in coffeeV2CanonicalSlotOrder) {
        expect(controller.assetFor(slot), isNotNull);
        expect(controller.assetFor(slot)!.path, isNotEmpty);
      }
    },
  );

  test('D — photo selection does not automatically create an operation', () async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
    final saucer = await writeJpeg('saucer.jpg', totalSize: 9201);

    await controller.setSlot(CoffeeV2PhotoSlot.cupPrimary, CoffeeImagePick(path: primary));
    await controller.setSlot(CoffeeV2PhotoSlot.cupSecondary, CoffeeImagePick(path: secondary));
    await controller.setSlot(CoffeeV2PhotoSlot.saucer, CoffeeImagePick(path: saucer));

    expect(backend.operationCount, 0);
  });

  test('E — 1 confirmed slot cannot submit', () async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    await controller.setSlot(CoffeeV2PhotoSlot.cupPrimary, CoffeeImagePick(path: primary));
    await controller.confirmSlot(CoffeeV2PhotoSlot.cupPrimary);

    final outcome = await controller.beginSubmission('src-e');
    expect(outcome, CoffeeV2SubmissionOutcome.blockedByValidation);
    expect(backend.operationCount, 0);
  });

  test('F — 2 confirmed slots cannot submit', () async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
    await controller.setSlot(CoffeeV2PhotoSlot.cupPrimary, CoffeeImagePick(path: primary));
    await controller.confirmSlot(CoffeeV2PhotoSlot.cupPrimary);
    await controller.setSlot(CoffeeV2PhotoSlot.cupSecondary, CoffeeImagePick(path: secondary));
    await controller.confirmSlot(CoffeeV2PhotoSlot.cupSecondary);

    final outcome = await controller.beginSubmission('src-f');
    expect(outcome, CoffeeV2SubmissionOutcome.blockedByValidation);
    expect(backend.operationCount, 0);
  });

  test('G — 3 confirmed valid distinct slots makes submission eligible', () async {
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

    expect(controller.allThreeReady, isTrue);
    final outcome = await controller.beginSubmission('src-g');
    expect(outcome, CoffeeV2SubmissionOutcome.completedStaging);
    expect(backend.operationCount, 1);
  });

  test('H — replacing one DRAFT slot changes only that slot', () async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
    final saucer = await writeJpeg('saucer.jpg', totalSize: 9201);
    await controller.setSlot(CoffeeV2PhotoSlot.cupPrimary, CoffeeImagePick(path: primary));
    await controller.setSlot(CoffeeV2PhotoSlot.cupSecondary, CoffeeImagePick(path: secondary));
    await controller.setSlot(CoffeeV2PhotoSlot.saucer, CoffeeImagePick(path: saucer));
    final primaryBefore = controller.assetFor(CoffeeV2PhotoSlot.cupPrimary);
    final secondaryBefore = controller.assetFor(CoffeeV2PhotoSlot.cupSecondary);
    final saucerBefore = controller.assetFor(CoffeeV2PhotoSlot.saucer);

    final replacementPath = await writeJpeg('primary_retake.jpg', totalSize: 9301);
    await controller.replaceSlot(
      CoffeeV2PhotoSlot.cupPrimary,
      CoffeeImagePick(path: replacementPath),
    );

    expect(controller.assetFor(CoffeeV2PhotoSlot.cupPrimary)!.sha256, isNot(primaryBefore!.sha256));
    expect(controller.assetFor(CoffeeV2PhotoSlot.cupSecondary), secondaryBefore);
    expect(controller.assetFor(CoffeeV2PhotoSlot.saucer), saucerBefore);
  });

  test('I — clearing one DRAFT slot changes only that slot', () async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
    final saucer = await writeJpeg('saucer.jpg', totalSize: 9201);
    await controller.setSlot(CoffeeV2PhotoSlot.cupPrimary, CoffeeImagePick(path: primary));
    await controller.setSlot(CoffeeV2PhotoSlot.cupSecondary, CoffeeImagePick(path: secondary));
    await controller.setSlot(CoffeeV2PhotoSlot.saucer, CoffeeImagePick(path: saucer));

    await controller.clearSlot(CoffeeV2PhotoSlot.cupSecondary);

    expect(controller.assetFor(CoffeeV2PhotoSlot.cupPrimary), isNotNull);
    expect(controller.assetFor(CoffeeV2PhotoSlot.cupSecondary), isNull);
    expect(controller.assetFor(CoffeeV2PhotoSlot.saucer), isNotNull);
  });

  test('J — active-submission assets cannot silently mutate', () async {
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
    await controller.beginSubmission('src-j');
    expect(controller.record.isActive, isTrue);

    final anotherPath = await writeJpeg('another.jpg', totalSize: 9401);
    await expectLater(
      controller.setSlot(CoffeeV2PhotoSlot.cupPrimary, CoffeeImagePick(path: anotherPath)),
      throwsStateError,
    );
    await expectLater(
      controller.clearSlot(CoffeeV2PhotoSlot.saucer),
      throwsStateError,
    );
  });
}
