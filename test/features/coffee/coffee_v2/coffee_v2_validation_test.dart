/// Coffee V2 client foundation — Phase 2C1 §28 "REQUIRED TESTS —
/// VALIDATION" (K-R).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_image_limits.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_normalizer.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_validation.dart';
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
    temp = await Directory.systemTemp.createTemp('coffee_v2_validation_test_');
    PathProviderPlatform.instance = FakePathProvider(temp.path);
    backend = FakeReadingOperationBackend();
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  CoffeeV2SubmissionController buildController({CoffeeV2Normalizer? normalizer}) {
    final operations = ReadingOperationGateway(send: backend.send);
    return CoffeeV2SubmissionController(
      flow: ReadingLiveFlow(
        operations: operations,
        acceleration: ReadingAccelerationClient(send: backend.send),
        send: backend.send,
      ),
      stagedImages: ReadingStagedImageGateway(backend.send),
      store: CoffeeV2SubmissionStore(LocalStorage.ephemeral()),
      normalizer: normalizer,
      messages: coffeeV2TestMessages,
    );
  }

  Future<String> writeJpeg(String name, {int totalSize = 9 * 1024}) async {
    final path = '${temp.path}/$name';
    await File(path).writeAsBytes(plainJpegBytes(totalSize: totalSize));
    return path;
  }

  test('K — each Coffee V2 asset must be <= 8 MiB', () async {
    final controller = buildController();
    final path = await writeJpeg('primary.jpg', totalSize: 9001);
    final result = await controller.setSlot(
      CoffeeV2PhotoSlot.cupPrimary,
      CoffeeImagePick(path: path),
    );
    expect(result.isSuccess, isTrue);
    expect(result.asset!.sizeBytes, lessThanOrEqualTo(CoffeeV2ImageLimits.maxBytes));
  });

  test('L — an oversized final normalized asset prevents operation creation', () async {
    // Scripted normalizer bypasses the real ImageNormalizer/platform
    // channel to deterministically simulate "the normalizer produced a
    // file over the 8 MiB ceiling" without needing a multi-megabyte real
    // JPEG or flutter_image_compress.
    final oversizedPath = await writeJpeg(
      'oversized.jpg',
      totalSize: CoffeeV2ImageLimits.maxBytes + 1024,
    );
    final controller = buildController(
      normalizer: ScriptedCoffeeV2Normalizer(
        (source) async => CoffeeImagePick(path: oversizedPath, mimeType: 'image/jpeg'),
      ),
    );

    final result = await controller.setSlot(
      CoffeeV2PhotoSlot.cupPrimary,
      CoffeeImagePick(path: oversizedPath),
    );

    expect(result.isSuccess, isFalse);
    expect(result.failure, CoffeeV2SlotSelectionFailure.tooLarge);
    expect(controller.assetFor(CoffeeV2PhotoSlot.cupPrimary), isNull);
    expect(backend.operationCount, 0);
  });

  test('M — invalid MIME prevents operation creation', () async {
    final path = '${temp.path}/not_an_image.bin';
    await File(path).writeAsBytes([1, 2, 3, 4, 5, 6, 7, 8]);
    final controller = buildController();

    final result = await controller.setSlot(
      CoffeeV2PhotoSlot.cupPrimary,
      CoffeeImagePick(path: path),
    );

    expect(result.isSuccess, isFalse);
    expect(result.failure, CoffeeV2SlotSelectionFailure.unsupportedFormat);
    expect(backend.operationCount, 0);
  });

  test('N — missing local file invalidates only that draft slot', () async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    await controller.setSlot(CoffeeV2PhotoSlot.cupPrimary, CoffeeImagePick(path: primary));

    final result = await controller.setSlot(
      CoffeeV2PhotoSlot.cupSecondary,
      CoffeeImagePick(path: '${temp.path}/does_not_exist.jpg'),
    );

    expect(result.isSuccess, isFalse);
    expect(result.failure, CoffeeV2SlotSelectionFailure.missingFile);
    // Only the failed slot is affected — cup_primary's earlier selection
    // is untouched.
    expect(controller.assetFor(CoffeeV2PhotoSlot.cupPrimary), isNotNull);
    expect(controller.assetFor(CoffeeV2PhotoSlot.cupSecondary), isNull);
  });

  Future<void> expectDuplicateRejected({
    required CoffeeV2PhotoSlot slotA,
    required CoffeeV2PhotoSlot slotB,
    required CoffeeV2ValidationIssue expectedIssue,
  }) async {
    final controller = buildController();
    final sharedBytes = plainJpegBytes(totalSize: 9001);
    final pathA = '${temp.path}/${slotA.wireValue}.jpg';
    final pathB = '${temp.path}/${slotB.wireValue}.jpg';
    await File(pathA).writeAsBytes(sharedBytes);
    await File(pathB).writeAsBytes(sharedBytes);
    final thirdSlot = coffeeV2CanonicalSlotOrder
        .firstWhere((s) => s != slotA && s != slotB);
    final thirdPath = await writeJpeg('${thirdSlot.wireValue}.jpg', totalSize: 9301);

    await controller.setSlot(slotA, CoffeeImagePick(path: pathA));
    await controller.setSlot(slotB, CoffeeImagePick(path: pathB));
    await controller.setSlot(thirdSlot, CoffeeImagePick(path: thirdPath));
    for (final slot in coffeeV2CanonicalSlotOrder) {
      await controller.confirmSlot(slot);
    }

    expect(controller.hasDuplicate, isTrue);
    expect(controller.validationIssue, expectedIssue);
    final outcome = await controller.beginSubmission('src-dup');
    expect(outcome, CoffeeV2SubmissionOutcome.blockedByValidation);
    expect(backend.operationCount, 0);
  }

  test('O — exact duplicate primary/secondary is rejected', () async {
    await expectDuplicateRejected(
      slotA: CoffeeV2PhotoSlot.cupPrimary,
      slotB: CoffeeV2PhotoSlot.cupSecondary,
      expectedIssue: CoffeeV2ValidationIssue.duplicatePrimarySecondary,
    );
  });

  test('P — exact duplicate primary/saucer is rejected', () async {
    await expectDuplicateRejected(
      slotA: CoffeeV2PhotoSlot.cupPrimary,
      slotB: CoffeeV2PhotoSlot.saucer,
      expectedIssue: CoffeeV2ValidationIssue.duplicatePrimarySaucer,
    );
  });

  test('Q — exact duplicate secondary/saucer is rejected', () async {
    await expectDuplicateRejected(
      slotA: CoffeeV2PhotoSlot.cupSecondary,
      slotB: CoffeeV2PhotoSlot.saucer,
      expectedIssue: CoffeeV2ValidationIssue.duplicateSecondarySaucer,
    );
  });

  test('R — three different checksums pass', () async {
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

    expect(controller.hasDuplicate, isFalse);
    expect(controller.validationIssue, isNull);
    final outcome = await controller.beginSubmission('src-r');
    expect(outcome, CoffeeV2SubmissionOutcome.completedStaging);
    expect(backend.operationCount, 1);
  });
}
