/// P4B — journal continuation focus survives loading.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/continuation/models/session_continuation.dart';
import 'package:oracly_new/core/continuation/services/session_continuation_focus_store.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/discovery_journal/copy/discovery_journal_copy.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/discovery_journal/presentation/screens/discovery_journal_screen.dart';
import 'package:oracly_new/features/discovery_journal/presentation/widgets/discovery_journal_filter_tab.dart';
import 'package:oracly_new/features/discovery_journal/providers/discovery_journal_providers.dart';
import 'package:oracly_new/shared/widgets/oracly_cinematic_loading.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const focus = 'p4b-focus';

  DiscoveryJournalEntry entry({String theme = focus}) {
    return DiscoveryJournalEntry(
      id: 'row-1',
      kind: DiscoveryJournalKind.tarot,
      date: DateTime(2026, 9, 1),
      title: 'Keep this entry',
      themes: [theme],
    );
  }

  Future<LocalStorage> storage() async {
    SharedPreferences.setMockInitialValues({});
    return LocalStorage.open();
  }

  Future<void> writeFocus(
    LocalStorage store, {
    required SessionContinuationTarget target,
    String? theme,
  }) {
    return SessionContinuationFocusStore(
      store,
    ).write(SessionContinuation(target: target, line: 'next', theme: theme));
  }

  Future<void> pumpJournal(
    WidgetTester tester, {
    required LocalStorage store,
    required Future<List<DiscoveryJournalEntry>> future,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) {
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: buildProviderScopeHarness(
          storage: store,
          overrides: [
            discoveryJournalEntriesProvider.overrideWith((ref) => future),
          ],
          child: const MaterialApp(home: DiscoveryJournalScreen()),
        ),
      ),
    );
  }

  bool tabSelected(WidgetTester tester, String label) {
    return tester
        .widgetList<DiscoveryJournalFilterTab>(
          find.byType(DiscoveryJournalFilterTab),
        )
        .any((tab) => tab.selected && tab.label == label);
  }

  testWidgets('immediate data applies journal focus once', (tester) async {
    final store = await storage();
    await writeFocus(
      store,
      target: SessionContinuationTarget.discoveryJournal,
      theme: focus,
    );
    await pumpJournal(tester, store: store, future: Future.value([entry()]));
    await tester.pump();
    expect(tabSelected(tester, DiscoveryJournalCopy.heroTheme(focus)), isTrue);
    expect(SessionContinuationFocusStore(store).peek(), isNull);
    await tester.tap(find.text(DiscoveryJournalCopy.heroTheme(focus)));
    await tester.pump();
    expect(tabSelected(tester, DiscoveryJournalCopy.heroTheme(focus)), isFalse);
  });

  testWidgets('held loading keeps journal focus for the timeline', (
    tester,
  ) async {
    final store = await storage();
    await writeFocus(
      store,
      target: SessionContinuationTarget.discoveryJournal,
      theme: 'Denge',
    );
    final gate = Completer<List<DiscoveryJournalEntry>>();
    await pumpJournal(tester, store: store, future: gate.future);
    await tester.pump();
    expect(find.byType(OraclyCinematicLoading), findsOneWidget);
    expect(find.byType(DiscoveryJournalFilterTab), findsNothing);
    expect(SessionContinuationFocusStore(store).peek()?.theme, 'Denge');

    gate.complete([entry(theme: 'Denge')]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(OraclyCinematicLoading), findsNothing);
    final label = DiscoveryJournalCopy.heroTheme('Denge');
    expect(find.text(label), findsWidgets);
    expect(tabSelected(tester, label), isTrue);
    expect(SessionContinuationFocusStore(store).peek(), isNull);

    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: store,
        overrides: [
          discoveryJournalEntriesProvider.overrideWith(
            (ref) async => [entry(theme: 'Denge')],
          ),
        ],
        child: const MaterialApp(home: DiscoveryJournalScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(OraclyCinematicLoading), findsNothing);
    expect(
      tabSelected(tester, DiscoveryJournalCopy.heroTheme('Denge')),
      isFalse,
    );
  });

  testWidgets('a focus for another chamber is not consumed', (tester) async {
    final store = await storage();
    await writeFocus(
      store,
      target: SessionContinuationTarget.tarot,
      theme: focus,
    );
    await pumpJournal(tester, store: store, future: Future.value([entry()]));
    await tester.pump();
    expect(tabSelected(tester, DiscoveryJournalCopy.heroTheme(focus)), isFalse);
    expect(
      SessionContinuationFocusStore(store).peek()?.target,
      SessionContinuationTarget.tarot,
    );
  });

  testWidgets('a missing theme does not hide journal entries', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final store = await storage();
    await writeFocus(
      store,
      target: SessionContinuationTarget.discoveryJournal,
      theme: 'not-in-journal',
    );
    await pumpJournal(
      tester,
      store: store,
      future: Future.value([entry()]),
      size: const Size(320, 568),
      textScale: 1.4,
    );
    await tester.pump();
    expect(find.byType(OraclyCinematicLoading), findsNothing);
    expect(find.text(DiscoveryJournalCopy.filterEmpty), findsNothing);
    expect(tabSelected(tester, DiscoveryJournalCopy.heroTheme(focus)), isFalse);
    expect(tester.takeException(), isNull);
    expect(SessionContinuationFocusStore(store).peek(), isNull);

    await tester.binding.setSurfaceSize(const Size(360, 640));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });
}
