/// Fincan Haritası ↔ Coffee V3 handoff through the REAL flow controller and
/// submission controller (fake backend, zero provider calls): the map holds
/// exactly the three photos that were staged for the operation whose result
/// was restored, byte for byte; V3 still releases its working copies; and a
/// failing keeper never stops the reading from completing.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_intention.dart';
import 'package:oracly_new/features/coffee/coffee_v3/controllers/coffee_v3_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_flow_stage.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_consent.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_keeper.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../../support/coffee_cup_map_test_support.dart';
import '../../../support/coffee_v3_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

// SYNTHETIC narrative (never product copy).
const _overall = 'Fincanda bir konu ön plana çıkabilir; kesin olacak gibi değil.';
const _owner = 'owner-map';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late FakeReadingOperationBackend backend;
  late CoffeeV3TestTransport transport;
  late CoffeeReadingStore readings;
  late NoProviderAi ai;
  final controllers = <CoffeeV3FlowController>[];

  setUp(() async {
    OraclyL10n.bind('tr');
    temp = await Directory.systemTemp.createTemp('cup_map_v3_');
    await installCupMapPaths(temp);
    storage = await ownedStorage(_owner);
    backend = FakeReadingOperationBackend(immediatelyEligible: false)
      ..authoritativeBalance = 50;
    transport = CoffeeV3TestTransport(backend);
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

  CoffeeV3FlowController build({CoffeeV3ResultPhotoKeeper? keeper}) {
    final flow = ReadingLiveFlow(
      operations: ReadingOperationGateway(send: transport.send),
      acceleration: ReadingAccelerationClient(send: transport.send),
      send: transport.send,
    );
    final controller = CoffeeV3FlowController(
      submission: CoffeeV3SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(transport.send),
        store: CoffeeV3SubmissionStore(
          storage,
          ownerId: _owner,
          requireOwner: true,
        ),
        normalizer: ownedCoffeeV3Normalizer(temp.path),
        messages: coffeeV3TestMessages,
        creationAllowed: () => true,
        newSourceRequestId: () => 'coffee-v3-src-map',
        resultPhotoKeeper: keeper,
      ),
      flow: flow,
      experience: CoffeeExperienceService(
        store: readings,
        analysis: OpenAiCoffeeAnalysis(ai: ai),
      ),
      onAuthoritativeBalance: (_) async {},
    );
    controllers.add(controller);
    return controller;
  }

  Future<void> waitFor(bool Function() condition, {int seconds = 6}) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) fail('condition not reached');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  /// Three distinct real cup photos (the repo fixture plus a slot marker
  /// after EOI, so their checksums differ the way three shots would).
  Future<Map<CoffeeV3PhotoSlot, Uint8List>> submitThree(
    CoffeeV3FlowController c,
  ) async {
    final base = await File(cupMapFixturePhoto).readAsBytes();
    final staged = <CoffeeV3PhotoSlot, Uint8List>{};
    await c.boot();
    c.dismissIntro();
    for (final slot in coffeeV3CanonicalSlotOrder) {
      final bytes = Uint8List.fromList([...base, slot.index + 1]);
      final file = File('${temp.path}/source_${slot.wireValue}.jpg');
      await file.writeAsBytes(bytes);
      c.setPreviewCandidate(slot, CoffeeImagePick(path: file.path));
      expect(
        await c.confirmCandidate(),
        CoffeeV3ConfirmOutcome.committedAdvance,
      );
      staged[slot] = bytes;
    }
    await c.selectIntention(CoffeeV2IntentionChoice.love);
    await c.beginSubmission();
    expect(c.stage, CoffeeV3FlowStage.activeObserving);
    return staged;
  }

  test('not opted in (the default): today\'s V3 flow, nothing kept',
      () async {
    final c = build(keeper: CoffeeCupMapKeeper(storage).keep);
    await submitThree(c);
    final workPaths = [
      for (final s in coffeeV3CanonicalSlotOrder) c.record.slots[s]!.asset!.path,
    ];
    await waitFor(() => c.liveState != null);
    backend.completeServerSide(
      c.operationId!,
      resultId: 'coffee-v3-map-r0',
      result: v3NarrativeV1Result(_overall),
    );
    await waitFor(() => c.record.resultPendingAcknowledgement);
    expect(readings.byId('coffee-v3-map-r0')?.overall, _overall);
    expect(cupMapFileText(), isNull);
    expect(
      installedCupMapLocation.audit().isEmpty,
      isTrue,
    );
    for (final path in workPaths) {
      expect(await File(path).exists(), isFalse);
    }
    // Same staged slots as before the feature existed: 2 cups + 1 saucer.
    expect(transport.stagedSlots, [
      for (final s in coffeeV3CanonicalSlotOrder) s.wireValue,
    ]);
  });

  test('opted in: the restored reading gets a map of exactly its three '
      'staged photos', () async {
    await CoffeeCupMapConsent(storage).setKeepPhotos(true);
    final c = build(keeper: CoffeeCupMapKeeper(storage).keep);
    final staged = await submitThree(c);
    final workPaths = [
      for (final s in coffeeV3CanonicalSlotOrder) c.record.slots[s]!.asset!.path,
    ];
    final opId = c.operationId!;
    await waitFor(() => c.liveState != null);
    backend.completeServerSide(
      opId,
      resultId: 'coffee-v3-map-r1',
      result: v3NarrativeV1Result(_overall),
    );
    await waitFor(() => c.record.resultPendingAcknowledgement);

    expect(readings.byId('coffee-v3-map-r1')?.overall, _overall);
    final map = (await CoffeeCupMapStore(storage).load('coffee-v3-map-r1'))!;
    expect(map.ownerId, _owner);
    expect(map.photos.map((p) => p.slot), coffeeV3CanonicalSlotOrder);
    for (final photo in map.photos) {
      expect(await File(photo.path).readAsBytes(), staged[photo.slot]);
    }
    // V3 still released every working copy; only the archive keeps them.
    for (final path in workPaths) {
      expect(await File(path).exists(), isFalse);
    }
    expect(ai.calls, 0);
  });

  test('a failing keeper never blocks the reading or the release', () async {
    final c = build(
      keeper: ({
        required resultId,
        required submissionOwnerId,
        required assets,
      }) async =>
          throw StateError('disk full'),
    );
    await submitThree(c);
    final workPaths = [
      for (final s in coffeeV3CanonicalSlotOrder) c.record.slots[s]!.asset!.path,
    ];
    await waitFor(() => c.liveState != null);
    backend.completeServerSide(
      c.operationId!,
      resultId: 'coffee-v3-map-r2',
      result: v3NarrativeV1Result(_overall),
    );
    await waitFor(() => c.record.resultPendingAcknowledgement);
    expect(c.reading?.id, 'coffee-v3-map-r2');
    expect((await CoffeeCupMapStore(storage).load('coffee-v3-map-r2')), isNull);
    for (final path in workPaths) {
      expect(await File(path).exists(), isFalse);
    }
  });

  test('a keeper that never returns cannot hold the handoff', () async {
    final c = build(
      keeper: ({
        required resultId,
        required submissionOwnerId,
        required assets,
      }) =>
          Completer<void>().future,
    );
    await submitThree(c);
    await waitFor(() => c.liveState != null);
    backend.completeServerSide(
      c.operationId!,
      resultId: 'coffee-v3-map-r4',
      result: v3NarrativeV1Result(_overall),
    );
    await waitFor(() => c.record.resultPendingAcknowledgement, seconds: 20);
    expect(readings.byId('coffee-v3-map-r4')?.overall, _overall);
  });

  test('without a keeper (other builds) nothing is kept', () async {
    final c = build();
    await submitThree(c);
    await waitFor(() => c.liveState != null);
    backend.completeServerSide(
      c.operationId!,
      resultId: 'coffee-v3-map-r3',
      result: v3NarrativeV1Result(_overall),
    );
    await waitFor(() => c.record.resultPendingAcknowledgement);
    expect((await CoffeeCupMapStore(storage).load('coffee-v3-map-r3')), isNull);
    expect(cupMapFileText(), isNull);
  });
}
