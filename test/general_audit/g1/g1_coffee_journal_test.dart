/// G1 — Coffee ↔ Discovery Journal: a result that appears on screen (legacy
/// or V2) refreshes the Journal, and reinterpret is only offered where it
/// can actually complete.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_submission_record.dart';
import 'package:oracly_new/features/coffee/coffee_v2/presentation/coffee_v2_flow_screen.dart';
import 'package:oracly_new/features/coffee/coffee_v2/providers/coffee_v2_providers.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/coffee/providers/coffee_providers.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/discovery_journal/providers/discovery_journal_providers.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';

import '../../support/coffee_v2_test_support.dart';
import '../../support/fake_reading_operation_backend.dart';
import 'g1_support.dart';

void main() {
  var journalBuilds = 0;
  setUp(() => journalBuilds = 0);

  Override countingJournal() =>
      discoveryJournalEntriesProvider.overrideWith((ref) async {
        journalBuilds++;
        return const <DiscoveryJournalEntry>[];
      });

  Future<void> readJournal(WidgetTester tester, Type screen) async {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(screen)),
    );
    await container.read(discoveryJournalEntriesProvider.future);
  }

  testWidgets('a Coffee result shown on the legacy screen refreshes the '
      'Journal', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(LocalStorage.ephemeral()),
        coffeeAnalysisProvider
            .overrideWithValue(const UnavailableCoffeeAnalysis()),
        countingJournal(),
      ],
      child: const MaterialApp(home: CoffeeReferenceScreen()),
    ));
    await tester.pump();
    await readJournal(tester, CoffeeReferenceScreen);
    final before = journalBuilds;
    ProviderScope.containerOf(tester.element(find.byType(CoffeeReferenceScreen)))
        .read(coffeeReadingControllerProvider)
        .openSaved(g1Coffee('g1-journal-coffee'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await readJournal(tester, CoffeeReferenceScreen);

    expect(journalBuilds, greaterThan(before));
  });

  testWidgets('a Coffee V2 result refreshes the Journal', (tester) async {
    final storage = LocalStorage.ephemeral();
    final backend = FakeReadingOperationBackend();
    final transport = G1FlakyTransport(backend);
    final begun = await transport.flow().begin(
          readingType: ReadingType.coffee,
          sourceRequestId: 'g1-journal-v2',
        );
    final id = begun.snapshot!.operationId;
    backend.completeServerSide(id, resultId: 'g1-journal-v2-result');
    final sessionStore = CoffeeV2SubmissionStore(storage, ownerId: 'owner-g1');
    await sessionStore.save(
      CoffeeV2SubmissionRecord.empty().copyWith(operationId: id),
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
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        coffeeV2FlowControllerProvider.overrideWith((ref) => controller),
        countingJournal(),
      ],
      child: const MaterialApp(home: CoffeeV2FlowScreen()),
    ));
    await readJournal(tester, CoffeeV2FlowScreen);
    final before = journalBuilds;
    await controller.boot();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(controller.reading?.id, 'g1-journal-v2-result');
    await readJournal(tester, CoffeeV2FlowScreen);

    expect(journalBuilds, greaterThan(before));
  });

  test('reinterpret is not offered when completion is server-owned',
      () async {
    final dir = await Directory.systemTemp.createTemp('g1_reinterpret_');
    addTearDown(() => dir.delete(recursive: true));
    final photo = File('${dir.path}/cup.jpg')..writeAsBytesSync([1, 2, 3]);
    final reading = CoffeeReading(
      id: 'g1-reinterpret',
      createdAt: DateTime.utc(2026),
      overall: 'server coffee',
      love: '',
      career: '',
      money: '',
      nearFuture: '',
      takeaway: 'done',
      imagePath: photo.path,
    );
    CoffeeReadingController build({required bool serverOwned}) {
      final controller = CoffeeReadingController(
        experience: CoffeeExperienceService(
          store: CoffeeReadingStore(LocalStorage.ephemeral()),
          analysis: G1CompletedCoffee(),
        ),
        images: const G1NoImages(),
        live: fakeImmediateReadingFeatureRunner(
          serverOwnedCompletion: serverOwned,
        ),
      );
      addTearDown(controller.dispose);
      return controller..openSaved(reading);
    }

    expect(build(serverOwned: true).canReinterpret, isFalse);
    expect(build(serverOwned: false).canReinterpret, isTrue);
  });
}
