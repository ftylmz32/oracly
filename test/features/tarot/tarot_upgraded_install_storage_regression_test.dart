/// Upgraded-install Tarot start: legacy/wrong-type SharedPreferences.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/first_session/first_session_intent.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_flow_controller.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';
import 'package:oracly_new/features/tarot/ritual/screens/tarot_ritual_deck_ready_screen.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:oracly_new/shared/widgets/oracly_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  /// Legacy completed reading as a JSON *object* inside a String blob list.
  Map<String, dynamic> completedJson({required String id}) => {
        'id': id,
        'deckId': 'rider-waite',
        'spread': 'threeCard',
        'intention': 'eski okuma',
        'shuffleSeed': 42,
        'startedAt': '2026-01-10T10:00:00.000',
        'completedAt': '2026-01-10T10:05:00.000',
        'drawnCards': const [],
        'interpretation': 'eski yansıma',
        'status': 'completed',
        'flowStep': 'completed',
        'currentPositionIndex': 0,
      };

  Future<void> pumpFirstCardFlow(
    WidgetTester tester, {
    required Map<String, Object> seed,
    required TarotReadingController reading,
    required TarotFlowController flow,
    required LocalStorage storage,
  }) async {
    flow.selectSpread(TarotSpreadType.threeCard);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          selectedSpreadProvider.overrideWith(
            (ref) => TarotSpreadType.threeCard.label,
          ),
          selectedDeckProvider.overrideWith((ref) => 'rider-waite'),
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
                          await FirstSessionIntent.requestFirstReading(
                            storage,
                          );
                          await TarotFirstReading.applySpread(ref, context);
                        },
                        child: const Text('home-first-card'),
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
    await tester.tap(find.text('home-first-card'));
    await tester.pump();
    expect(flow.spread, TarotFirstReading.spread);
    await tester.tap(find.byType(OraclyButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets(
    'legacy String history + stale active starts first-card without error',
    (tester) async {
      final completed = completedJson(id: 'legacy_completed_1');
      final staleActive = {
        ...completedJson(id: 'stale_active'),
        'status': 'inProgress',
        'flowStep': 'reveal',
        'completedAt': null,
        'interpretation': null,
      };

      SharedPreferences.setMockInitialValues({
        // Wrong historical type: JSON array stored as a single String.
        TarotLocalDataSource.historyKey: jsonEncode([completed]),
        TarotLocalDataSource.activeKey: jsonEncode(staleActive),
        'or_selected_deck': 'rider-waite',
        'or_selected_spread': TarotSpreadType.threeCard.label,
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final reading = TarotReadingController(
        repository: TarotReadingRepositoryImpl.fromStorage(storage),
      );
      addTearDown(reading.dispose);
      final flow = TarotFlowController();
      addTearDown(flow.dispose);

      await pumpFirstCardFlow(
        tester,
        seed: const {},
        reading: reading,
        flow: flow,
        storage: storage,
      );

      expect(find.text(ResilienceCopy.sessionInitFailed), findsNothing);
      expect(reading.session, isNotNull);
      expect(reading.session!.spread, TarotSpreadType.single);
      expect(reading.deckController.drawPile, isNotEmpty);

      // Valid completed history preserved after migration + new session.
      final history = await TarotLocalDataSource(storage).fetchCompleted();
      expect(history.any((s) => s.id == 'legacy_completed_1'), isTrue);
      expect(
        storage.getStringList(TarotLocalDataSource.historyKey),
        isA<List<String>>(),
      );
    },
  );

  testWidgets(
    'malformed rows + wrong-type active still start single-card ritual',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        TarotLocalDataSource.historyKey: jsonEncode([
          'nope',
          completedJson(id: 'keep_me'),
          42,
        ]),
        // Wrong type for active (list instead of string).
        TarotLocalDataSource.activeKey: <String>['not-a-session'],
        'or_selected_deck': 'classic',
        'or_selected_spread': '3 Kart Açılımı',
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final reading = TarotReadingController(
        repository: TarotReadingRepositoryImpl.fromStorage(storage),
      );
      addTearDown(reading.dispose);
      final flow = TarotFlowController();
      addTearDown(flow.dispose);

      await pumpFirstCardFlow(
        tester,
        seed: const {},
        reading: reading,
        flow: flow,
        storage: storage,
      );

      expect(find.text(ResilienceCopy.sessionInitFailed), findsNothing);
      expect(reading.session!.spread, TarotSpreadType.single);
      final history = await TarotLocalDataSource(storage).fetchCompleted();
      expect(history.any((s) => s.id == 'keep_me'), isTrue);
    },
  );

  test('beginSession no longer throws on String-typed history key', () async {
    SharedPreferences.setMockInitialValues({
      TarotLocalDataSource.historyKey: '[]',
      TarotLocalDataSource.activeKey: '',
      'or_selected_deck': 'rider-waite',
      'or_selected_spread': '3 Kart',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final reading = TarotReadingController(
      repository: TarotReadingRepositoryImpl.fromStorage(storage),
    );
    addTearDown(reading.dispose);

    final session = await reading.beginSession(
      spread: TarotSpreadType.single,
      deckId: 'classic',
    );
    expect(session.spread, TarotSpreadType.single);
    expect(reading.deckController.drawPile, isNotEmpty);
  });
}
