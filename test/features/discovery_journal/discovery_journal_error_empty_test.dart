/// Journal loading failure must not look empty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/discovery_journal/copy/discovery_journal_copy.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_entry.dart';
import 'package:oracly_new/features/discovery_journal/presentation/screens/discovery_journal_screen.dart';
import 'package:oracly_new/features/discovery_journal/providers/discovery_journal_providers.dart';
import 'package:oracly_new/shared/widgets/oracly_error_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loading failure renders error not empty', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    var retries = 0;
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          discoveryJournalEntriesProvider.overrideWith((ref) async {
            retries++;
            if (retries == 1) {
              throw StateError('journal read failed');
            }
            return <DiscoveryJournalEntry>[];
          }),
        ],
        child: const MaterialApp(home: DiscoveryJournalScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(OraclyErrorState), findsOneWidget);
    expect(find.text(ResilienceCopy.historyLoadFailedTitle), findsOneWidget);
    expect(find.text(DiscoveryJournalCopy.emptyTitle), findsNothing);
    await tester.tap(find.text(ResilienceCopy.retryAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(DiscoveryJournalCopy.emptyTitle), findsOneWidget);
  });

  testWidgets('zero records render empty state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        overrides: [
          discoveryJournalEntriesProvider.overrideWith(
            (ref) async => <DiscoveryJournalEntry>[],
          ),
        ],
        child: const MaterialApp(home: DiscoveryJournalScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(OraclyErrorState), findsNothing);
    expect(find.text(DiscoveryJournalCopy.emptyTitle), findsOneWidget);
  });
}
