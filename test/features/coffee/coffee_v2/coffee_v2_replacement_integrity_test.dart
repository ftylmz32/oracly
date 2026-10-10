/// Slice 4A — Coffee V2 replacement integrity. Replacing an already
/// confirmed photo with a candidate that is a duplicate of ANOTHER slot (or
/// that fails normalization) must never touch the previously confirmed
/// photo: the candidate is validated BEFORE anything is committed.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/ai/production/transport/image_normalizer.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_flow_stage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_intention.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_validation.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late FakeReadingOperationBackend backend;
  var size = 9000;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_v2_replace_');
    storage = LocalStorage.ephemeral();
    backend = FakeReadingOperationBackend(immediatelyEligible: false);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  CoffeeV2SubmissionStore store() =>
      CoffeeV2SubmissionStore(storage, ownerId: 'owner-v2', requireOwner: true);

  CoffeeV2FlowController build() {
    final flow = ReadingLiveFlow(
      operations: ReadingOperationGateway(send: backend.send),
      acceleration: ReadingAccelerationClient(send: backend.send),
      send: backend.send,
    );
    return CoffeeV2FlowController(
      submission: CoffeeV2SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(backend.send),
        store: store(),
        normalizer: ScriptedCoffeeV2Normalizer((s) async {
          if (s.path.contains('broken')) {
            throw const ImageNormalizeException(
              'normalize_failed',
              kind: ImageNormalizeKind.failed,
            );
          }
          return s;
        }),
        messages: coffeeV2TestMessages,
      ),
      flow: flow,
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(storage),
        analysis: const UnavailableCoffeeAnalysis(),
      ),
    );
  }

  Future<String> photo(String name, {int? bytes}) async {
    final path = '${temp.path}/$name.jpg';
    await File(path).writeAsBytes(plainJpegBytes(totalSize: bytes ?? (size += 53)));
    return path;
  }

  /// Three confirmed, distinct photos; returns their byte sizes per slot.
  Future<Map<CoffeeV2PhotoSlot, int>> confirmThree(
    CoffeeV2FlowController c,
  ) async {
    await c.boot();
    c.dismissIntro();
    final sizes = <CoffeeV2PhotoSlot, int>{};
    for (final slot in coffeeV2CanonicalSlotOrder) {
      sizes[slot] = size += 211;
      c.setPreviewCandidate(
        slot,
        CoffeeImagePick(path: await photo('orig_${slot.wireValue}', bytes: sizes[slot])),
      );
      expect(await c.confirmCandidate(), CoffeeV2ConfirmOutcome.committedAdvance);
    }
    expect(c.stage, CoffeeV2FlowStage.finalReview);
    return sizes;
  }

  Future<CoffeeV2ConfirmOutcome> replace(
    CoffeeV2FlowController c,
    CoffeeV2PhotoSlot slot,
    String path,
  ) async {
    c.beginReplacing(slot);
    c.setPreviewCandidate(slot, CoffeeImagePick(path: path));
    return c.confirmCandidate();
  }

  test('duplicate replacement preserves the previously confirmed photo',
      () async {
    final c = build();
    final sizes = await confirmThree(c);
    final before = c.record.slots[CoffeeV2PhotoSlot.saucer]!.asset!;

    // Same bytes as cup_primary → a duplicate of ANOTHER slot.
    final dup = await photo('dup', bytes: sizes[CoffeeV2PhotoSlot.cupPrimary]);
    expect(await replace(c, CoffeeV2PhotoSlot.saucer, dup),
        CoffeeV2ConfirmOutcome.duplicate);

    final after = c.record.slots[CoffeeV2PhotoSlot.saucer]!;
    expect(after.asset, before);
    expect(after.confirmed, isTrue);
    expect(store().load()!.slots[CoffeeV2PhotoSlot.saucer]!.asset, before);
    expect(store().load()!.slots[CoffeeV2PhotoSlot.saucer]!.confirmed, isTrue);
    expect(await File(before.path).exists(), isTrue);
    expect(await File(dup).exists(), isTrue); // source original never deleted
    expect(c.lastDuplicateIssue, CoffeeV2ValidationIssue.duplicatePrimarySaucer);
    expect(c.submission!.validationIssue, isNull);
    expect(backend.operationCount, 0);
  });

  test('every V2 slot-pair duplicate scenario preserves the replaced slot',
      () async {
    for (final target in coffeeV2CanonicalSlotOrder) {
      for (final source in coffeeV2CanonicalSlotOrder) {
        if (source == target) continue;
        storage = LocalStorage.ephemeral();
        final c = build();
        final sizes = await confirmThree(c);
        final snapshot = {
          for (final s in coffeeV2CanonicalSlotOrder) s: c.record.slots[s]!.asset,
        };
        final dup = await photo('dup_${target.name}_${source.name}',
            bytes: sizes[source]);
        expect(await replace(c, target, dup), CoffeeV2ConfirmOutcome.duplicate,
            reason: '$target <- $source');
        for (final s in coffeeV2CanonicalSlotOrder) {
          expect(c.record.slots[s]!.asset, snapshot[s], reason: '$target/$s');
          expect(c.record.slots[s]!.confirmed, isTrue, reason: '$target/$s');
        }
        expect(c.submission!.validationIssue, isNull);
        c.dispose();
      }
    }
    expect(backend.operationCount, 0);
  });

  test('normalization failure on replacement preserves the old photo', () async {
    final c = build();
    await confirmThree(c);
    final before = c.record.slots[CoffeeV2PhotoSlot.cupSecondary]!.asset;
    expect(await replace(c, CoffeeV2PhotoSlot.cupSecondary, await photo('broken')),
        CoffeeV2ConfirmOutcome.invalidPhoto);
    expect(c.record.slots[CoffeeV2PhotoSlot.cupSecondary]!.asset, before);
    expect(c.record.slots[CoffeeV2PhotoSlot.cupSecondary]!.confirmed, isTrue);
    expect(store().load()!.slots[CoffeeV2PhotoSlot.cupSecondary]!.asset, before);
  });

  test('successful replacement changes only that slot and survives restart',
      () async {
    final c = build();
    await confirmThree(c);
    final primary = c.record.slots[CoffeeV2PhotoSlot.cupPrimary]!.asset;
    final saucer = c.record.slots[CoffeeV2PhotoSlot.saucer]!.asset;
    final fresh = await photo('fresh_secondary');
    expect(await replace(c, CoffeeV2PhotoSlot.cupSecondary, fresh),
        CoffeeV2ConfirmOutcome.committedReturnToReview);
    expect(c.record.slots[CoffeeV2PhotoSlot.cupSecondary]!.asset!.path, fresh);
    expect(c.record.slots[CoffeeV2PhotoSlot.cupPrimary]!.asset, primary);
    expect(c.record.slots[CoffeeV2PhotoSlot.saucer]!.asset, saucer);

    final restarted = build();
    await restarted.boot();
    expect(restarted.stage, CoffeeV2FlowStage.finalReview);
    expect(restarted.record.slots[CoffeeV2PhotoSlot.cupSecondary]!.asset!.path,
        fresh);
    expect(restarted.record.slots[CoffeeV2PhotoSlot.cupSecondary]!.confirmed,
        isTrue);
    expect(restarted.record.slots[CoffeeV2PhotoSlot.cupPrimary]!.asset, primary);
    expect(backend.operationCount, 0);
  });

  test('an ACTIVE V2 submission stays immutable', () async {
    final c = build();
    await confirmThree(c);
    await c.selectIntention(CoffeeV2IntentionChoice.general);
    await c.beginSubmission();
    expect(c.record.isActive, isTrue);
    final snapshot = {
      for (final s in coffeeV2CanonicalSlotOrder) s: c.record.slots[s]!.asset,
    };
    c.setPreviewCandidate(
      CoffeeV2PhotoSlot.saucer,
      CoffeeImagePick(path: await photo('late')),
    );
    await expectLater(c.confirmCandidate(), throwsStateError);
    for (final s in coffeeV2CanonicalSlotOrder) {
      expect(c.record.slots[s]!.asset, snapshot[s]);
    }
    expect(backend.operationCount, 1);
  });
}
