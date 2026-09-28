/// G1 — Palm ↔ Discovery Journal: a server-completed result refreshes the
/// Journal once it is on screen, and reinterpret is only offered where it
/// can complete.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/discovery_journal/providers/discovery_journal_providers.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:oracly_new/features/palm/providers/palm_providers.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';

import '../../support/fake_reading_operation_backend.dart';
import 'g1_support.dart';

void main() {
  testWidgets('a Palm result shown on screen refreshes the Journal',
      (tester) async {
    var journalBuilds = 0;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        localStorageProvider.overrideWithValue(LocalStorage.ephemeral()),
        discoveryJournalEntriesProvider.overrideWith((ref) async {
          journalBuilds++;
          return const <DiscoveryJournalEntry>[];
        }),
      ],
      child: const MaterialApp(home: PalmReferenceScreen()),
    ));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PalmReferenceScreen)),
    );
    await container.read(discoveryJournalEntriesProvider.future);
    final before = journalBuilds;

    container.read(palmReadingControllerProvider).openSaved(
          PalmReading(
            id: 'g1-journal-palm',
            createdAt: DateTime.utc(2026),
            hand: PalmHand.left,
            overall: 'server palm',
            takeaway: 'done',
          ),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await container.read(discoveryJournalEntriesProvider.future);

    expect(journalBuilds, greaterThan(before));
  });

  test('reinterpret is not offered when completion is server-owned',
      () async {
    final dir = await Directory.systemTemp.createTemp('g1_palm_reinterpret_');
    addTearDown(() => dir.delete(recursive: true));
    final photo = File('${dir.path}/hand.jpg')..writeAsBytesSync([1, 2, 3]);
    final reading = PalmReading(
      id: 'g1-palm-reinterpret',
      createdAt: DateTime.utc(2026),
      hand: PalmHand.right,
      overall: 'server palm',
      takeaway: 'done',
      imagePath: photo.path,
    );
    PalmReadingController build({required bool serverOwned}) {
      final controller = PalmReadingController(
        experience: PalmExperienceService(
          store: PalmReadingStore(LocalStorage.ephemeral()),
          analysis: G1CompletedPalm(),
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
