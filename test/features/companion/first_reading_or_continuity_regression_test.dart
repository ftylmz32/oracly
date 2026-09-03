/// Regression: Tarot → OR handoff survives provider settling (dedicated /chat).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/companion/providers/companion_providers.dart';
import 'package:oracly_new/features/companion/services/first_reading_or_deepen.dart';
import 'package:oracly_new/features/companion/services/or_chat_handoff.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  setUp(() {
    OraclyL10n.bind('tr');
    OrChatHandoffBuffer.clear();
  });

  tearDown(OrChatHandoffBuffer.clear);

  testWidgets(
    'inside-shell Ask OR keeps readingContext after provider settle',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();
      await FirstReadingOrDeepen.markEligible(storage, 'session_first');

      const reading = OracleReadingContext(
        sessionId: 'session_first',
        spreadLabel: 'Tek Kart',
        deckId: 'classic',
        deckName: 'Classic',
        readingTitle: 'The Star',
        cardsSummary: 'The Star',
        interpretationSummary: 'Umut.',
        kind: OracleReadingKind.tarot,
        sourceLabel: 'Tarot',
      );

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: const _InsideShellAskOrHarness(),
        ),
      );
      await tester.pumpAndSettle();

      openOracleConversation(
        tester.element(find.text('tarot-inside-shell')),
        readingContext: reading,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CompanionReferenceScreen), findsOneWidget);

      final controller = ProviderScope.containerOf(
        tester.element(find.byType(CompanionReferenceScreen)),
      ).read(companionControllerProvider);

      expect(controller.readingContext?.sessionId, 'session_first');
      expect(
        FirstReadingOrDeepen.allows(storage, controller.readingContext),
        isTrue,
      );
    },
  );
}

class _InsideShellAskOrHarness extends StatefulWidget {
  const _InsideShellAskOrHarness();

  @override
  State<_InsideShellAskOrHarness> createState() =>
      _InsideShellAskOrHarnessState();
}

class _InsideShellAskOrHarnessState extends State<_InsideShellAskOrHarness> {
  int _tab = OraclyTab.home.index;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (_) => OraclyNavigationScope(
              currentIndex: _tab,
              switchToTab: (i) => setState(() => _tab = i),
              child: Scaffold(
                body: _tab == OraclyTab.home.index
                    ? const Text('tarot-inside-shell')
                    : const Text('or-tab'),
              ),
            ),
        OraclyRoutes.chat: (_) => const CompanionReferenceScreen(),
      },
    );
  }
}
