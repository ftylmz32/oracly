/// G1 — Palm acceleration: its own server quote only, never Coffee's, and
/// no offer or charge before that quote exists.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/economy/palm_economy.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';

import '../../support/fake_reading_operation_backend.dart';
import 'g1_support.dart';

void main() {
  test('the base Palm reading has no local price', () {
    expect(PalmEconomy.analysisCost, isNull);
    expect(PalmEconomy.hasCost, isFalse);
  });

  testWidgets('no quote means no offer and no charge; the quote is Palm\'s '
      'own server price', (tester) async {
    final backend = FakeReadingOperationBackend(immediatelyEligible: false)
      ..coffeeAccelerationCost = 10
      ..palmAccelerationCost = 15;
    final transport = G1FlakyTransport(backend)..dropQuotes = true;
    await transport.flow().begin(
          readingType: ReadingType.palm,
          sourceRequestId: 'g1-palm-accel',
        );
    final controller = PalmReadingController(
      experience: PalmExperienceService(
        store: PalmReadingStore(LocalStorage.ephemeral()),
        analysis: G1CompletedPalm(),
      ),
      images: const G1NoImages(),
      live: transport.runner(serverOwnedCompletion: true),
    );
    await controller.recoverActive();
    await tester.pump();

    expect(controller.liveState?.kind, ReadingLiveKind.waiting);
    expect(controller.accelerationCost, isNull);
    expect(controller.canAccelerate, isFalse);
    await controller.accelerateWaiting();
    expect(backend.accelerationCalls, 0);

    transport.dropQuotes = false;
    await controller.recoverActive();
    await tester.pump();
    expect(controller.accelerationCost, 15);
    expect(controller.canAccelerate, isTrue);
    controller.dispose();
  });
}
