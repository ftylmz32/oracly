/// G1 — Coffee wait/recovery seams: a dead network is not a missing
/// operation, an unfetched result is retried, and an exact recovery target
/// that is gone, foreign or not Coffee never leaves another reading shown.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';

import '../../support/fake_reading_operation_backend.dart';
import 'g1_support.dart';

void main() {
  late FakeReadingOperationBackend backend;
  late G1FlakyTransport transport;
  late G1CompletedCoffee analysis;

  setUp(() {
    backend = FakeReadingOperationBackend();
    transport = G1FlakyTransport(backend);
    analysis = G1CompletedCoffee();
  });

  CoffeeReadingController build() {
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(LocalStorage.ephemeral()),
        analysis: analysis,
      ),
      images: const G1NoImages(),
      live: transport.runner(serverOwnedCompletion: true),
      serverPollInterval: const Duration(milliseconds: 1),
    );
    addTearDown(controller.dispose);
    return controller;
  }

  Future<String> processingCoffee(String source) async {
    final flow = transport.flow();
    final begun = await flow.begin(
      readingType: ReadingType.coffee,
      sourceRequestId: source,
    );
    final id = begun.snapshot!.operationId;
    await flow.claimIfEligible(id);
    return id;
  }

  test('a network outage while analyzing keeps polling until the result',
      () async {
    final id = await processingCoffee('g1-coffee-outage');
    final controller = build();
    await controller.recoverActive();
    expect(controller.phase, CoffeePhase.analyzing);

    transport.dropActive = 3;
    await g1Until(() => transport.dropActive == 0);
    backend.completeServerSide(id, resultId: 'g1-coffee-after-outage');
    await g1Until(() => controller.phase == CoffeePhase.result);

    expect(controller.phase, CoffeePhase.result);
    expect(controller.reading?.id, 'g1-coffee-after-outage');
  });

  test('an unfetchable or unreadable ready result is retried, not frozen',
      () async {
    final id = await processingCoffee('g1-coffee-unfetched');
    final controller = build();
    await controller.recoverActive();
    transport.dropResult = 2;
    analysis.throwNext = 1;
    backend.completeServerSide(id, resultId: 'g1-coffee-late-result');
    await g1Until(() => controller.phase == CoffeePhase.result);

    expect(controller.reading?.id, 'g1-coffee-late-result');
    expect(transport.dropResult, 0);
    expect(analysis.throwNext, 0);
  });

  test('exact recovery of a missing operation clears the reading on screen',
      () async {
    final controller = build();
    controller.openSaved(g1Coffee('g1-unrelated-saved'));
    expect(controller.phase, CoffeePhase.result);

    await controller.recoverOperation('f' * 32);

    expect(controller.phase, CoffeePhase.entry);
    expect(controller.reading, isNull);
  });

  test('exact recovery of a Palm operation is rejected by Coffee', () async {
    final flow = transport.flow();
    final palm = await flow.begin(
      readingType: ReadingType.palm,
      sourceRequestId: 'g1-palm-not-coffee',
    );
    backend.completeServerSide(
      palm.snapshot!.operationId,
      resultId: 'g1-palm-result',
    );
    final controller = build();
    controller.openSaved(g1Coffee('g1-unrelated-saved'));

    await controller.recoverOperation(palm.snapshot!.operationId);

    expect(controller.phase, CoffeePhase.entry);
    expect(controller.reading, isNull);
  });

  test('exact recovery survives an outage and opens the target result',
      () async {
    final id = await processingCoffee('g1-coffee-exact-outage');
    backend.completeServerSide(id, resultId: 'g1-coffee-exact-result');
    final controller = build();
    transport.dropExact = 2;

    await controller.recoverOperation(id);
    await g1Until(() => controller.phase == CoffeePhase.result);

    expect(controller.reading?.id, 'g1-coffee-exact-result');
  });
}
