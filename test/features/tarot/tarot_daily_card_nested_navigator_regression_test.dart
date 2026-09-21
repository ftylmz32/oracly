/// Daily-card must open deck-ready on the INNER Tarot navigator (under TarotScope).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/navigation/oracly_route_generator.dart';
import 'package:oracly_new/core/navigation/oracly_routes.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_intent.dart';
import 'package:oracly_new/features/tarot/navigation/tarot_module_navigator.dart';
import 'package:oracly_new/features/tarot/presentation/screens/shuffle_screen.dart';
import 'package:oracly_new/features/tarot/ritual/screens/tarot_ritual_deck_ready_screen.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:oracly_new/shared/widgets/oracly_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('tr');
    if (DailyRitualIntent.hasPendingDraw) {
      DailyRitualIntent.consumePendingDraw();
    }
  });

  tearDown(() {
    if (DailyRitualIntent.hasPendingDraw) {
      DailyRitualIntent.consumePendingDraw();
    }
  });

  testWidgets(
    'daily-card deck-ready stays under TarotScope and Continue starts session',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorage.open();

      // Pending intent before Tarot module mounts — same as Home CTA path.
      DailyRitualIntent.requestDailyCardDraw();

      await tester.pumpWidget(
        buildProviderScopeHarness(
          storage: storage,
          child: MaterialApp(
            onGenerateRoute: OraclyRouteGenerator.onGenerateRoute,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(OraclyRoutes.tarot);
                },
                child: const Text('open-tarot-module'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('open-tarot-module'));
      await tester.pump();
      // Bridge post-frame + restoreReady.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TarotModuleNavigator), findsOneWidget);
      expect(find.byType(TarotRitualDeckReadyScreen), findsOneWidget);

      // THE BUG: deck-ready pushed on the OUTER navigator has no TarotScope.
      final deckElement = tester.element(
        find.byType(TarotRitualDeckReadyScreen),
      );
      expect(
        TarotScope.maybeOf(deckElement),
        isNotNull,
        reason: 'DeckReady must sit under TarotScope (inner Tarot navigator)',
      );

      await tester.tap(find.byType(OraclyButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(ResilienceCopy.sessionInitFailed), findsNothing);
      expect(find.byType(ShuffleScreen), findsOneWidget);

      final shuffleElement = tester.element(find.byType(ShuffleScreen));
      expect(TarotScope.maybeOf(shuffleElement), isNotNull);
      expect(
        TarotScope.maybeOf(shuffleElement)!.reading.session,
        isNotNull,
      );
    },
  );
}
