/// Daily/first-card Continue must start a free single-card session successfully.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/daily_ritual/services/daily_ritual_intent.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_flow_controller.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';
import 'package:oracly_new/features/tarot/ritual/screens/tarot_ritual_deck_ready_screen.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:oracly_new/shared/widgets/oracly_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('en');
    if (DailyRitualIntent.hasPendingDraw) {
      DailyRitualIntent.consumePendingDraw();
    }
  });

  testWidgets(
    'daily single-card Continue starts despite stale 3-card selection',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final repo = TarotReadingRepositoryImpl.fromStorage(storage);
      final reading = TarotReadingController(repository: repo);
      addTearDown(reading.dispose);
      final flow = TarotFlowController();
      addTearDown(flow.dispose);
      flow.selectSpread(TarotSpreadType.threeCard);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            selectedSpreadProvider.overrideWith(
              (ref) => TarotSpreadType.threeCard.label,
            ),
            selectedDeckProvider.overrideWith((ref) => 'classic'),
          ],
          child: TarotScope(
            flow: flow,
            reading: reading,
            restoreReady: Future<void>.value(),
            child: MaterialApp(
              theme: AppTheme.dark,
              home: Consumer(
                builder: (context, ref, _) {
                  return Scaffold(
                    body: Column(
                      children: [
                        TextButton(
                          onPressed: () async {
                            await TarotFirstReading.applySpread(ref, context);
                          },
                          child: const Text('apply-single'),
                        ),
                        const Expanded(child: TarotRitualDeckReadyScreen()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('apply-single'));
      await tester.pump();
      expect(flow.spread, TarotFirstReading.spread);

      await tester.tap(find.byType(OraclyButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(ResilienceCopy.sessionInitFailed), findsNothing);
      expect(reading.session, isNotNull);
      expect(reading.session!.spread, TarotSpreadType.single);
      expect(
        reading.session!.flowStep,
        isNot(ReadingFlowStep.deckSelection),
      );
    },
  );

  testWidgets('beginSession abandons stale active before starting', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repo = TarotReadingRepositoryImpl.fromStorage(storage);
    final reading = TarotReadingController(repository: repo);
    addTearDown(reading.dispose);

    await reading.beginSession(
      spread: TarotSpreadType.threeCard,
      deckId: 'classic',
    );
    expect(reading.session!.spread, TarotSpreadType.threeCard);
    final staleId = reading.session!.id;

    await tester.pump(const Duration(milliseconds: 2));
    await reading.beginSession(
      spread: TarotSpreadType.single,
      deckId: 'classic',
    );
    expect(reading.session, isNotNull);
    expect(reading.session!.id, isNot(staleId));
    expect(reading.session!.spread, TarotSpreadType.single);
    expect(reading.deckController.drawPile, isNotEmpty);
  });
}
