/// G1 — Palm wait/recovery seams: outages keep polling, an unfetched result
/// is retried, leaving the wait is respected, the server-side hand survives
/// recovery, and a Coffee operation is never opened as Palm.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';

import '../../support/fake_reading_operation_backend.dart';
import 'g1_support.dart';

void main() {
  late FakeReadingOperationBackend backend;
  late G1FlakyTransport transport;

  setUp(() {
    backend = FakeReadingOperationBackend();
    transport = G1FlakyTransport(backend);
  });

  PalmReadingController build() => PalmReadingController(
        experience: PalmExperienceService(
          store: PalmReadingStore(LocalStorage.ephemeral()),
          analysis: G1CompletedPalm(),
        ),
        images: const G1NoImages(),
        live: transport.runner(serverOwnedCompletion: true),
      );

  Future<String> processingPalm(String source) async {
    final flow = transport.flow();
    final begun = await flow.begin(
      readingType: ReadingType.palm,
      sourceRequestId: source,
    );
    final id = begun.snapshot!.operationId;
    await flow.claimIfEligible(id);
    return id;
  }

  void completeLeftHand(String id, String resultId) =>
      backend.completeServerSide(
        id,
        resultId: resultId,
        result: const {'overall': 'server palm', '_handSide': 'left'},
      );

  Future<void> pollTicks(WidgetTester tester, int ticks) async {
    for (var i = 0; i < ticks; i++) {
      await tester.pump(const Duration(seconds: 3));
    }
  }

  testWidgets('an outage while analyzing keeps polling; the left hand '
      'survives recovery', (tester) async {
    final id = await processingPalm('g1-palm-outage');
    final controller = build();
    await controller.recoverActive();
    expect(controller.phase, PalmPhase.analyzing);

    transport.dropActive = 2;
    await pollTicks(tester, 2);
    completeLeftHand(id, 'g1-palm-after-outage');
    await pollTicks(tester, 2);

    expect(controller.phase, PalmPhase.result);
    expect(controller.reading?.id, 'g1-palm-after-outage');
    expect(controller.reading?.hand, PalmHand.left);
    controller.dispose();
  });

  testWidgets('a ready result that cannot be fetched yet is retried',
      (tester) async {
    final id = await processingPalm('g1-palm-unfetched');
    final controller = build();
    await controller.recoverActive();
    transport.dropResult = 2;
    completeLeftHand(id, 'g1-palm-late');
    await pollTicks(tester, 4);

    expect(controller.phase, PalmPhase.result);
    expect(controller.reading?.id, 'g1-palm-late');
    controller.dispose();
  });

  testWidgets('leaving the wait is respected by a poll already scheduled',
      (tester) async {
    final id = await processingPalm('g1-palm-left');
    final controller = build();
    await controller.recoverActive();
    controller.backToEntry();
    completeLeftHand(id, 'g1-palm-late-arrival');
    await pollTicks(tester, 2);

    expect(controller.phase, PalmPhase.entry);
    expect(controller.reading, isNull);
    controller.dispose();
  });

  testWidgets('exact recovery of a Coffee operation is rejected by Palm',
      (tester) async {
    final coffee = await transport.flow().begin(
          readingType: ReadingType.coffee,
          sourceRequestId: 'g1-coffee-not-palm',
        );
    backend.completeServerSide(
      coffee.snapshot!.operationId,
      resultId: 'g1-coffee-result',
    );
    final controller = build();
    await tester.pump();
    controller.openSaved(
      G1CompletedPalm().restoreCompleted(
        resultId: 'g1-unrelated-palm',
        persistedAt: DateTime.utc(2026),
        hand: PalmHand.right,
        result: const {},
      ),
    );
    expect(controller.phase, PalmPhase.result);

    await controller.recoverOperation(coffee.snapshot!.operationId);
    await tester.pump();

    expect(controller.phase, PalmPhase.entry);
    expect(controller.reading, isNull);
    controller.dispose();
  });
}
