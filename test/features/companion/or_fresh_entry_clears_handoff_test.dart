/// Fresh OR entry clears prior reading handoff context.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_navigation_service.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_kind.dart';
import 'package:oracly_new/features/companion/providers/companion_providers.dart';
import 'package:oracly_new/features/companion/services/or_chat_handoff.dart';
import 'package:shared_preferences/shared_preferences.dart';

OracleReadingContext _ctx({
  required OracleReadingKind kind,
  required String title,
}) {
  return OracleReadingContext(
    sessionId: 'sess-$title',
    spreadLabel: title,
    deckId: 'n/a',
    deckName: 'n/a',
    readingTitle: title,
    cardsSummary: title,
    interpretationSummary: title,
    kind: kind,
    sourceLabel: title,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('openChat without handoff clears sticky reading context', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: Builder(
          builder: (context) {
            container = ProviderScope.containerOf(context);
            return MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => TextButton(
                    onPressed: () => OraclyNavigationService.openChat(ctx),
                    child: const Text('open'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    final companion = container.read(companionControllerProvider);
    companion.applyReadingHandoff(
      _ctx(kind: OracleReadingKind.coffee, title: 'Prior coffee'),
    );
    OrChatHandoffBuffer.offer(
      _ctx(kind: OracleReadingKind.palm, title: 'Pending palm'),
    );
    expect(companion.readingContext, isNotNull);
    await tester.tap(find.text('open'));
    await tester.pump();
    expect(companion.readingContext, isNull);
    expect(OrChatHandoffBuffer.take(), isNull);
  });
}
