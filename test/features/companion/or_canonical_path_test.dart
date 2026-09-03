/// Canonical OR path — one screen for Home and feature handoffs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/navigation/oracly_navigation_service.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/navigation/oracle_conversation_route.dart';
import 'package:oracly_new/features/ai/presentation/screens/oracle_conversation_screen.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_screen.dart';
import 'package:oracly_new/features/companion/presentation/screens/companion_screen.dart';
import 'package:oracly_new/features/companion/services/or_chat_handoff.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(OrChatHandoffBuffer.clear);

  test('chat route is the single canonical OR path', () {
    expect(OraclyRoutes.chat, '/chat');
  });

  test('handoff compact stays short and omits card ids', () {
    final compact = OrChatHandoff.compact(
      const OracleReadingContext(
        sessionId: 's1',
        spreadLabel: 'Tek Kart',
        deckId: 'classic',
        deckName: 'Classic',
        readingTitle: 'Degnek Altilisi',
        cardsSummary: 'Bugun Â· id:42 Â· Degnek Altilisi Â· Duz',
        interpretationSummary: 'Kisa ozet.',
        userQuestion: 'Ne goruyorum?',
        cardNames: ['Degnek Altilisi'],
        kind: OracleReadingKind.tarot,
        sourceLabel: 'Tarot',
      ),
    );
    expect(compact.contains('Tarot'), isTrue);
    expect(compact.contains('Ne goruyorum?'), isTrue);
    expect(compact.contains('Degnek Altilisi'), isTrue);
    expect(compact.contains('id:42'), isFalse);
    expect(compact.length, lessThan(400));
  });

  testWidgets('Home openChat mounts CompanionReferenceScreen only',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => OraclyNavigationService.openChat(context),
              child: const Text('go-or'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go-or'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);
    expect(find.byType(OracleConversationScreen), findsNothing);
    expect(find.byType(CompanionScreen), findsNothing);
  });

  testWidgets('feature handoff opens the same canonical OR screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    const reading = OracleReadingContext(
      sessionId: 'coffee-1',
      spreadLabel: '',
      deckId: '',
      deckName: '',
      readingTitle: 'Kahve',
      cardsSummary: '',
      interpretationSummary: 'Fincanda belirsiz iz.',
      kind: OracleReadingKind.coffee,
      sourceLabel: 'Kahve',
    );
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => openOracleConversation(
                context,
                readingContext: reading,
              ),
              child: const Text('ask-or'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ask-or'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);
    expect(find.byType(OracleConversationScreen), findsNothing);
  });

  testWidgets('duplicate openChat does not stack a second OR screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => OraclyNavigationService.openChat(context),
              child: const Text('go-or'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go-or'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);

    // Second entry while OR is current route — must not push another.
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    OraclyNavigationService.openChat(nav.context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);
  });

  testWidgets('back from OR returns to prior route', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    await tester.pumpWidget(
      buildProviderScopeHarness(
        storage: storage,
        child: MaterialApp(
          onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => OraclyNavigationService.openChat(context),
              child: const Text('go-or'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go-or'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CompanionReferenceScreen), findsOneWidget);

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CompanionReferenceScreen), findsNothing);
    expect(find.text('go-or'), findsOneWidget);
  });
}
