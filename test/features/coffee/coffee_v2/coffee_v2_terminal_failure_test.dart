/// Slice 4C — client side of the V2 insufficient-result terminal contract.
/// The backend now settles an insufficient V2 outcome as a typed terminal
/// FAILURE (never a ready reading). The existing V2 client must show the
/// existing failure experience — no success screen, no raw diagnostics, no
/// endless spinner, no history entry — keep that state across a restart,
/// and offer the existing next action (New Cup → clean draft).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_flow_stage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_intention.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late FakeReadingOperationBackend backend;
  late CoffeeReadingStore readings;
  late NoProviderAi ai;
  final controllers = <CoffeeV2FlowController>[];
  var size = 9000;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_v2_4c_');
    storage = LocalStorage.ephemeral();
    backend = FakeReadingOperationBackend(immediatelyEligible: false);
    readings = CoffeeReadingStore(storage);
    ai = NoProviderAi();
  });

  tearDown(() async {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  CoffeeV2FlowController build() {
    final flow = ReadingLiveFlow(
      operations: ReadingOperationGateway(send: backend.send),
      acceleration: ReadingAccelerationClient(send: backend.send),
      send: backend.send,
    );
    final c = CoffeeV2FlowController(
      submission: CoffeeV2SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(backend.send),
        store: CoffeeV2SubmissionStore(storage, ownerId: 'owner-4c', requireOwner: true),
        normalizer: ScriptedCoffeeV2Normalizer((s) async => s),
        messages: coffeeV2TestMessages,
      ),
      flow: flow,
      experience: CoffeeExperienceService(
        store: readings,
        analysis: OpenAiCoffeeAnalysis(ai: ai),
      ),
    );
    controllers.add(c);
    return c;
  }

  Future<void> waitFor(bool Function() condition, {int seconds = 6}) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) fail('condition not reached');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test('server terminal failure → existing error state, survives restart, New Cup resets',
      () async {
    final c = build();
    await c.boot();
    c.dismissIntro();
    for (final slot in coffeeV2CanonicalSlotOrder) {
      final f = File('${temp.path}/${slot.wireValue}.jpg');
      await f.writeAsBytes(plainJpegBytes(totalSize: size += 97));
      c.setPreviewCandidate(slot, CoffeeImagePick(path: f.path));
      await c.confirmCandidate();
    }
    await c.selectIntention(CoffeeV2IntentionChoice.general);
    await c.beginSubmission();
    final opId = c.record.operationId!;
    final source = c.record.sourceRequestId;

    // The backend settles the insufficient outcome as a terminal failure.
    await backend.send('POST', '/v1/reading-operations/$opId/fail', const {});
    await waitFor(() => c.observeError != null);

    expect(c.observeError, ReadingLiveCopy.failed);
    expect(c.reading, isNull); // never the success result
    expect(c.stage, CoffeeV2FlowStage.activeObserving);
    expect(readings.all(), isEmpty); // no history entry
    expect(backend.resultFetchCalls, 0);
    for (final raw in ['insufficient_semantic_signal', 'no_safe_semantic_facets']) {
      expect(c.observeError!.contains(raw), isFalse); // no raw diagnostics
    }
    expect(ai.calls, 0);
    await waitFor(() => coffeeV2CanonicalSlotOrder
        .every((s) => c.record.slots[s]?.asset == null)); // upload data released
    expect(c.record.operationId, opId); // operation identity kept until ack

    // Restart: still the failure, never a spinner or a success.
    c.dispose();
    controllers.remove(c);
    final restarted = build();
    await restarted.boot();
    await waitFor(() => restarted.observeError != null);
    expect(restarted.observeError, ReadingLiveCopy.failed);
    expect(restarted.reading, isNull);
    expect(restarted.record.operationId, opId);
    expect(backend.operationCount, 1); // no automatic new operation

    // Existing next action: New Cup → acknowledged, clean draft.
    restarted.resetToFreshDraft();
    await waitFor(() => restarted.observeError == null);
    expect(restarted.record.isDraft, isTrue);
    expect(restarted.record.sourceRequestId, isNull);
    expect(restarted.record.sourceRequestId, isNot(source));
    expect(restarted.stage, CoffeeV2FlowStage.intro);
    expect(backend.operationCount, 1);
  });
}
