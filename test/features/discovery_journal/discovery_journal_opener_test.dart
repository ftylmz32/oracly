/// Journal reopen — a dream entry that no longer resolves must not silently
/// surface whatever dream the (app-lifetime) analysis controller last held.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_reference_screen.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_opener.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/providers/dream_providers.dart';
import 'package:oracly_new/features/favorite_moments/copy/favorite_moments_copy.dart';
import 'package:oracly_new/features/palm/presentation/palm_reference_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  testWidgets(
    'opening a dream journal entry with no matching record shows honest '
    'unavailable copy instead of the previously-analyzed dream',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      late WidgetRef capturedRef;
      late BuildContext capturedContext;

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                capturedContext = context;
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Simulate a dream already analyzed earlier in this app session —
      // the controller is a long-lived singleton, not scoped to a screen.
      final staleDream = Dream(
        id: 'dream_stale',
        narrative: 'Eski bir rüya',
        recordedAt: DateTime(2024, 1, 1),
      );
      capturedRef.read(dreamAnalysisControllerProvider).openSaved(staleDream);

      // Tap a journal entry whose id no longer resolves (deleted / drifted).
      await DiscoveryJournalOpener.open(
        capturedContext,
        capturedRef,
        DiscoveryJournalEntry(
          id: 'dream_missing',
          kind: DiscoveryJournalKind.dream,
          date: DateTime(2024, 2, 1),
          title: 'Missing dream',
        ),
      );
      await tester.pump();

      // The controller must still hold the stale dream unchanged — the
      // opener must not have pushed the Dream screen showing it as if it
      // were the tapped entry.
      final controller = capturedRef.read(dreamAnalysisControllerProvider);
      expect(controller.dream?.id, 'dream_stale');
      expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsOneWidget);
    },
  );

  testWidgets(
    'opening a coffee journal entry with no matching record does not push '
    'a screen that could show a stale reading',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      late WidgetRef capturedRef;
      late BuildContext capturedContext;

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                capturedContext = context;
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Store is empty — the tapped id cannot resolve.
      await DiscoveryJournalOpener.open(
        capturedContext,
        capturedRef,
        DiscoveryJournalEntry(
          id: 'coffee_missing',
          kind: DiscoveryJournalKind.coffee,
          date: DateTime(2024, 2, 1),
          title: 'Missing coffee reading',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CoffeeReferenceScreen), findsNothing);
      expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsOneWidget);
    },
  );

  testWidgets(
    'opening a palm journal entry with no matching record does not push '
    'a screen that could show a stale reading',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      late WidgetRef capturedRef;
      late BuildContext capturedContext;

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                capturedContext = context;
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await DiscoveryJournalOpener.open(
        capturedContext,
        capturedRef,
        DiscoveryJournalEntry(
          id: 'palm_missing',
          kind: DiscoveryJournalKind.palm,
          date: DateTime(2024, 2, 1),
          title: 'Missing palm reading',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PalmReferenceScreen), findsNothing);
      expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsOneWidget);
    },
  );

  testWidgets(
    'opening a tarot journal entry with no matching record surfaces honest '
    'unavailable copy instead of silently doing nothing',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      late WidgetRef capturedRef;
      late BuildContext capturedContext;

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                capturedContext = context;
                return const Scaffold(body: SizedBox.shrink());
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // History is empty — the tapped id/sessionId cannot resolve. Before
      // the fix, DiscoveryJournalOpener._openTarot returned silently here
      // with no feedback at all, unlike Dream/Coffee/Palm above.
      await DiscoveryJournalOpener.open(
        capturedContext,
        capturedRef,
        DiscoveryJournalEntry(
          id: 'tarot_missing',
          kind: DiscoveryJournalKind.tarot,
          date: DateTime(2024, 2, 1),
          title: 'Missing tarot reading',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(FavoriteMomentsCopy.sourceUnavailable), findsOneWidget);
    },
  );
}
