/// G1 — Coffee acceleration price authority: no speed-up offer and no charge
/// without a server quote for this exact operation (legacy and V2).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_stage_state.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_submission_record.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/economy/coffee_economy.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../support/coffee_v2_test_support.dart';
import '../../support/fake_reading_operation_backend.dart';
import 'g1_support.dart';

void main() {
  late FakeReadingOperationBackend backend;
  late G1FlakyTransport transport;
  late String operationId;

  setUp(() async {
    backend = FakeReadingOperationBackend(immediatelyEligible: false);
    transport = G1FlakyTransport(backend)..dropQuotes = true;
    final begun = await transport.flow().begin(
          readingType: ReadingType.coffee,
          sourceRequestId: 'g1-coffee-accel',
        );
    operationId = begun.snapshot!.operationId;
  });

  test('the base Coffee reading has no local price', () {
    expect(CoffeeEconomy.analysisCost, isNull);
  });

  test('legacy Coffee: no quote means no offer and no charge', () async {
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(LocalStorage.ephemeral()),
        analysis: G1CompletedCoffee(),
      ),
      images: const G1NoImages(),
      live: transport.runner(serverOwnedCompletion: true),
      serverPollInterval: const Duration(hours: 1),
    );
    addTearDown(controller.dispose);
    await controller.recoverActive();
    await Future<void>.delayed(Duration.zero);

    expect(controller.liveState?.kind, ReadingLiveKind.waiting);
    expect(controller.accelerationCost, isNull);
    expect(controller.canAccelerate, isFalse);
    await controller.accelerateWaiting();
    expect(backend.accelerationCalls, 0);

    transport.dropQuotes = false;
    await controller.recoverActive();
    await Future<void>.delayed(Duration.zero);
    expect(controller.accelerationCost, 10);
    expect(controller.canAccelerate, isTrue);
  });

  testWidgets('Coffee V2: no quote means no offer and no charge',
      (tester) async {
    final storage = LocalStorage.ephemeral();
    final sessionStore = CoffeeV2SubmissionStore(storage, ownerId: 'owner-g1');
    await sessionStore.save(
      CoffeeV2SubmissionRecord(
        operationId: operationId,
        slots: {
          for (final slot in coffeeV2CanonicalSlotOrder)
            slot: const CoffeeV2SlotRecord(
              confirmed: true,
              stageState: CoffeeV2StageState.staged,
            ),
        },
      ),
    );
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
    await controller.boot();
    await tester.pump();

    expect(controller.liveState?.kind, ReadingLiveKind.waiting);
    expect(controller.canAccelerate, isFalse);
    await controller.accelerateWaiting();
    expect(backend.accelerationCalls, 0);
    controller.dispose();
  });
}
