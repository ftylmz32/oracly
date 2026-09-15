import 'dart:io';

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
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

class _CompletedAnalysis
    implements CoffeeAnalysisPort, CoffeeCompletedAnalysisPort {
  const _CompletedAnalysis();

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) =>
      throw StateError('server-owned');

  @override
  CoffeeReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  }) {
    return CoffeeReading(
      id: resultId,
      createdAt: persistedAt,
      overall: result['overall']?.toString() ?? '',
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: '',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late CoffeeV2SubmissionStore sessionStore;
  late CoffeeReadingStore readingStore;
  late FakeReadingOperationBackend backend;
  late RecordingStagedTransport transport;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_v2_cvc1_');
    storage = LocalStorage.ephemeral();
    sessionStore = CoffeeV2SubmissionStore(storage, ownerId: 'owner-cvc1');
    readingStore = CoffeeReadingStore(storage);
    backend = FakeReadingOperationBackend(immediatelyEligible: false)
      ..authoritativeBalance = 95;
    transport = RecordingStagedTransport(backend);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  ReadingLiveFlow buildFlow() {
    return ReadingLiveFlow(
      operations: ReadingOperationGateway(send: transport.send),
      acceleration: ReadingAccelerationClient(send: transport.send),
      send: transport.send,
    );
  }

  CoffeeV2FlowController buildController() {
    final flow = buildFlow();
    return CoffeeV2FlowController(
      submission: CoffeeV2SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(transport.send),
        store: sessionStore,
        normalizer: ScriptedCoffeeV2Normalizer((source) async => source),
        messages: coffeeV2TestMessages,
      ),
      flow: flow,
      experience: CoffeeExperienceService(
        store: readingStore,
        analysis: const _CompletedAnalysis(),
      ),
    );
  }

  Future<void> addThree(CoffeeV2FlowController controller) async {
    for (final entry in <CoffeeV2PhotoSlot, int>{
      CoffeeV2PhotoSlot.cupPrimary: 9001,
      CoffeeV2PhotoSlot.cupSecondary: 9101,
      CoffeeV2PhotoSlot.saucer: 9201,
    }.entries) {
      final file = File('${temp.path}/${entry.key.wireValue}.jpg');
      await file.writeAsBytes(plainJpegBytes(totalSize: entry.value));
      await controller.submission!.setSlot(
        entry.key,
        CoffeeImagePick(path: file.path, mimeType: 'image/jpeg'),
      );
      await controller.submission!.confirmSlot(entry.key);
    }
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 30));

  CoffeeV2SubmissionRecord stagedRecord(String operationId) {
    return CoffeeV2SubmissionRecord(
      operationId: operationId,
      slots: {
        for (final slot in coffeeV2CanonicalSlotOrder)
          slot: const CoffeeV2SlotRecord(
            confirmed: true,
            stageState: CoffeeV2StageState.staged,
          ),
      },
    );
  }

  test(
    'CVC1 full lifecycle: one operation, one debit, durable result until acknowledgement',
    () async {
      var controller = buildController();
      await controller.boot();
      controller.dismissIntro();
      await addThree(controller);
      expect(controller.stage, CoffeeV2FlowStage.finalReview);

      await controller.beginSubmission();
      await settle();
      final operationId = controller.record.operationId;
      expect(operationId, isNotNull);
      expect(sessionStore.load()?.operationId, operationId);
      expect(controller.stage, CoffeeV2FlowStage.activeObserving);

      await settle();
      expect(controller.accelerationCost, 10);
      await controller.accelerateWaiting();
      expect(backend.authoritativeBalance, 85);
      expect(backend.accelerationDebitCount, 1);

      controller.dispose();
      controller = buildController();
      await controller.boot();
      await settle();
      expect(controller.record.operationId, operationId);
      expect(controller.stage, CoffeeV2FlowStage.activeObserving);

      controller.dispose();
      controller = buildController();
      await controller.boot();
      expect(controller.record.operationId, operationId);
      backend.completeServerSide(
        operationId!,
        resultId: 'coffee-cvc1-result',
        result: const {'overall': 'authoritative result'},
      );

      controller.dispose();
      controller = buildController();
      await controller.boot();
      await settle();
      expect(controller.reading?.id, 'coffee-cvc1-result');
      expect(controller.stage, CoffeeV2FlowStage.activeObserving);
      expect(sessionStore.load()?.operationId, operationId);
      expect(sessionStore.load()?.resultPendingAcknowledgement, isTrue);
      expect(
        controller.record.slots.values.every((slot) => slot.asset == null),
        isTrue,
      );
      expect(readingStore.all(), hasLength(1));

      controller.dispose();
      controller = buildController();
      await controller.boot();
      expect(controller.reading?.id, 'coffee-cvc1-result');
      expect(controller.stage, CoffeeV2FlowStage.activeObserving);
      expect(readingStore.all(), hasLength(1));
      expect(backend.operationCount, 1);
      expect(backend.accelerationDebitCount, 1);

      controller.resetToFreshDraft();
      await settle();
      expect(sessionStore.load(), isNull);
      expect(sessionStore.loadAcknowledgedOperationId(), operationId);
      expect(controller.stage, CoffeeV2FlowStage.intro);
      controller.dismissIntro();
      expect(controller.stage, CoffeeV2FlowStage.step);
      expect(controller.currentStepSlot, CoffeeV2PhotoSlot.cupPrimary);
      controller.dispose();
    },
  );

  test('owner mismatch cannot recover another account session', () async {
    await sessionStore.save(
      CoffeeV2SubmissionRecord.empty().copyWith(operationId: 'a' * 32),
    );
    final other = CoffeeV2SubmissionStore(storage, ownerId: 'owner-other');
    expect(other.load(), isNull);
  });

  test('delayed auth cannot hydrate an owner-bound session early', () async {
    await sessionStore.save(
      CoffeeV2SubmissionRecord.empty().copyWith(operationId: 'b' * 32),
    );
    final beforeAuth = CoffeeV2SubmissionStore(storage, requireOwner: true);
    expect(beforeAuth.load(), isNull);
    final afterAuth = CoffeeV2SubmissionStore(
      storage,
      ownerId: 'owner-cvc1',
      requireOwner: true,
    );
    expect(afterAuth.load()?.operationId, 'b' * 32);
  });

  test('generic 409 preserves the operation and performs no debit', () async {
    final flow = buildFlow();
    final begun = await flow.begin(
      readingType: ReadingType.coffee,
      sourceRequestId: 'conflict-cvc1',
    );
    await sessionStore.save(stagedRecord(begun.snapshot!.operationId));
    final controller = buildController();
    await controller.boot();
    await settle();
    backend.accelerationGenericConflict = true;
    await controller.accelerateWaiting();
    expect(controller.record.operationId, begun.snapshot!.operationId);
    expect(controller.accelerationError, isNotNull);
    expect(backend.authoritativeBalance, 95);
    expect(backend.accelerationDebitCount, 0);
    controller.dispose();
  });

  test(
    'insufficient Gems preserves waiting and authoritative balance',
    () async {
      final flow = buildFlow();
      final begun = await flow.begin(
        readingType: ReadingType.coffee,
        sourceRequestId: 'insufficient-cvc1',
      );
      await sessionStore.save(stagedRecord(begun.snapshot!.operationId));
      final controller = buildController();
      await controller.boot();
      await settle();
      backend.accelerationInsufficient = true;
      await controller.accelerateWaiting();
      expect(controller.record.operationId, begun.snapshot!.operationId);
      expect(controller.accelerationError, isNotNull);
      expect(backend.authoritativeBalance, 95);
      expect(backend.accelerationDebitCount, 0);
      controller.dispose();
    },
  );
}
