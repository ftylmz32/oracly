/// G1 — Coffee V2 restart seams: a terminal handoff survives a restart, a
/// ready-but-unfetched result is never discarded, and a result the user
/// deleted is never fetched back.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_flow_stage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_stage_state.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_submission_record.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../support/coffee_v2_test_support.dart';
import '../../support/fake_reading_operation_backend.dart';
import 'g1_support.dart';

void main() {
  late LocalStorage storage;
  late CoffeeV2SubmissionStore sessionStore;
  late FakeReadingOperationBackend backend;
  late G1FlakyTransport transport;

  setUp(() {
    storage = LocalStorage.ephemeral();
    sessionStore = CoffeeV2SubmissionStore(storage, ownerId: 'owner-g1');
    backend = FakeReadingOperationBackend();
    transport = G1FlakyTransport(backend);
  });

  CoffeeV2FlowController build() {
    final flow = transport.flow();
    final controller = CoffeeV2FlowController(
      submission: CoffeeV2SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(transport.send),
        store: sessionStore,
        normalizer: ScriptedCoffeeV2Normalizer((source) async => source),
        messages: coffeeV2TestMessages,
      ),
      flow: flow,
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(storage),
        analysis: G1CompletedCoffee(),
      ),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<String> coffeeOperation(String source) async {
    final begun = await transport.flow().begin(
          readingType: ReadingType.coffee,
          sourceRequestId: source,
        );
    return begun.snapshot!.operationId;
  }

  CoffeeV2SubmissionRecord staged(String operationId) =>
      CoffeeV2SubmissionRecord(
        operationId: operationId,
        slots: {
          for (final slot in coffeeV2CanonicalSlotOrder)
            slot: const CoffeeV2SlotRecord(
              confirmed: true,
              stageState: CoffeeV2StageState.staged,
            ),
        },
      );

  testWidgets('a failed reading whose photos were released reopens as that '
      'failure, not an endless preparing spinner', (tester) async {
    final id = await coffeeOperation('g1-v2-failed');
    await transport.flow().failFinal(id);
    await sessionStore.save(
      CoffeeV2SubmissionRecord.empty().copyWith(operationId: id),
    );
    final controller = build();
    await controller.boot();
    await tester.pump();

    expect(controller.stage, CoffeeV2FlowStage.activeObserving);
    expect(controller.observeError, isNotNull);

    controller.resetToFreshDraft();
    await tester.pump();
    expect(sessionStore.load(), isNull);
    expect(controller.stage, CoffeeV2FlowStage.intro);
  });

  testWidgets('a ready result the server cannot hand over yet stays '
      'recoverable through Retry', (tester) async {
    final id = await coffeeOperation('g1-v2-unfetched');
    backend.completeServerSide(id, resultId: 'g1-v2-result');
    await sessionStore.save(staged(id));
    transport.dropResult = 10;
    final controller = build();
    await controller.boot();
    for (var i = 0; i < 12 && controller.observeError == null; i++) {
      await tester.pump(const Duration(seconds: 3));
    }
    expect(controller.observeError, isNotNull);
    expect(sessionStore.load()?.operationId, id);

    controller.resetToFreshDraft();
    for (var i = 0; i < 3 && controller.reading == null; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(controller.reading?.id, 'g1-v2-result');
    expect(controller.observeError, isNull);
  });

  testWidgets('a restored result the user deleted is not fetched back',
      (tester) async {
    final id = await coffeeOperation('g1-v2-deleted');
    backend.completeServerSide(id, resultId: 'g1-v2-deleted-result');
    await sessionStore.save(
      CoffeeV2SubmissionRecord.empty().copyWith(
        operationId: id,
        resultId: 'g1-v2-deleted-result',
        resultPendingAcknowledgement: true,
      ),
    );
    final controller = build();
    await controller.boot();
    await tester.pump(const Duration(seconds: 4));

    expect(controller.reading, isNull);
    expect(backend.resultFetchCalls, 0);
    expect(sessionStore.load(), isNull);
    expect(controller.stage, CoffeeV2FlowStage.intro);
  });
}
