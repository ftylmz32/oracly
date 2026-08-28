/// Profile journal preview — real records or honest empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/discovery_journal/copy/discovery_journal_copy.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/discovery_journal/providers/discovery_journal_providers.dart';
import 'package:oracly_new/screens/profile/copy/profile_copy.dart';
import 'package:oracly_new/screens/profile/reference/profile_journal_preview.dart';

void main() {
  testWidgets('empty journal stays honest', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryJournalEntriesProvider.overrideWith(
            (ref) async => const <DiscoveryJournalEntry>[],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileJournalPreview())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(ProfileCopy.journalTitle), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.emptyTitle), findsOneWidget);
    expect(find.textContaining('streak'), findsNothing);
  });

  testWidgets('shows a real persisted record', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryJournalEntriesProvider.overrideWith(
            (ref) async => [
              DiscoveryJournalEntry(
                id: 'r1',
                kind: DiscoveryJournalKind.tarot,
                date: DateTime(2026, 8, 12),
                title: 'The Moon',
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileJournalPreview())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tarot · The Moon'), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.emptyTitle), findsNothing);
  });
}
