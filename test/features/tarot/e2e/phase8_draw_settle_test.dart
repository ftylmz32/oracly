/// Phase 8.2 — rapid draw / draw failure / settle failure (real ritual).
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_flow_controller.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/ritual/ritual_settle_outcome.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_controller.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_settle.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_stage.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'phase8_failing_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Phase8FailingRepo repo;
  late TarotReadingController reading;
  late TarotRitualController ritual;
  late TarotFlowController flow;

  Future<void> boot(TarotSpreadType spread) async {
    SharedPreferences.setMockInitialValues({});
    OraclyL10n.bind('en');
    final storage = LocalStorage(await SharedPreferences.getInstance());
    repo = Phase8FailingRepo(TarotReadingRepositoryImpl.fromStorage(storage));
    reading = TarotReadingController(repository: repo);
    flow = TarotFlowController();
    ritual = TarotRitualController();
    flow.selectSpread(spread);
    await reading.beginSession(spread: spread, deckId: 'classic');
    await reading.advanceToShuffle();
    await reading.performShuffle();
    await reading.finishShuffle();
    flow.selectDrawMode(TarotDrawMode.manual);
    ritual.domainShuffleDone = true;
    ritual.setVisual(ritual.visual.copyWith(stage: TarotRitualStage.draw));
  }

  tearDown(() {
    reading.dispose();
    ritual.dispose();
    flow.dispose();
  });

  testWidgets('rapid draw — two requests, one domain draw', (tester) async {
    await boot(TarotSpreadType.threeCard);
    await tester.pumpWidget(
      TarotScope(
        flow: flow,
        reading: reading,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    final a = ritual.commitDraw(context);
                    final b = ritual.commitDraw(context);
                    final okA = await a;
                    final okB = await b;
                    // Exactly one domain commit; second is rejected/busy.
                    expect(okA || okB, isTrue);
                    expect(okA && okB, isFalse);
                    expect(reading.session!.drawnCards, hasLength(1));
                  },
                  child: const Text('rapid'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('rapid'));
    await tester.pumpAndSettle();
  });

  testWidgets('draw persist failure — no visible commit; retry one card',
      (tester) async {
    await boot(TarotSpreadType.single);
    final sid = reading.session!.id;
    await tester.pumpWidget(
      TarotScope(
        flow: flow,
        reading: reading,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    repo.failNextSaves = 1;
                    final failed = await ritual.commitDraw(context);
                    expect(failed, isFalse);
                    expect(reading.session!.id, sid);
                    expect(reading.session!.drawnCards, isEmpty);
                    expect(ritual.active, isNull);
                    final ok = await ritual.commitDraw(context);
                    expect(ok, isTrue);
                    expect(reading.session!.drawnCards, hasLength(1));
                  },
                  child: const Text('drawfail'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('drawfail'));
    await tester.pumpAndSettle();
  });

  testWidgets('settle failure — no redraw; retry same card', (tester) async {
    await boot(TarotSpreadType.single);
    await tester.pumpWidget(
      TarotScope(
        flow: flow,
        reading: reading,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () async {
                    expect(await ritual.commitDraw(context), isTrue);
                    final id = ritual.active!.card.id;
                    expect(reading.session!.drawnCards, hasLength(1));
                    repo.failNextSaves = 1;
                    expect(
                      await ritual.settleAfterReveal(context),
                      RitualSettleOutcome.failed,
                    );
                    expect(ritual.active!.card.id, id);
                    expect(ritual.placed, isEmpty);
                    expect(reading.session!.drawnCards, hasLength(1));
                    expect(
                      await ritual.settleAfterReveal(context),
                      RitualSettleOutcome.readingReady,
                    );
                    expect(ritual.placed, hasLength(1));
                    expect(reading.session!.drawnCards, hasLength(1));
                    expect(reading.session!.drawnCards.first.card.id, id);
                  },
                  child: const Text('settlefail'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('settlefail'));
    await tester.pumpAndSettle();
  });
}
