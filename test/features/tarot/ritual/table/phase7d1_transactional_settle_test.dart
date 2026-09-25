/// Phase 7D.1 — transactional settle + awaitable completion + localized a11y.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_flow_controller.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/domain/repositories/tarot_reading_repository.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/ritual/ritual_settle_outcome.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_actor.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_controller.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_settle.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_stage.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('en'));

  group('7D.1 transactional settle', () {
    late _CountingRepo repo;
    late TarotReadingController reading;
    late TarotRitualController ritual;
    late TarotFlowController flow;

    Future<void> pumpScope(WidgetTester tester, Widget child) async {
      await tester.pumpWidget(
        TarotScope(
          flow: flow,
          reading: reading,
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      );
    }

    Future<void> boot({required TarotSpreadType spread}) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      repo = _CountingRepo(TarotReadingRepositoryImpl.fromStorage(storage));
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
      ritual.setVisual(
        ritual.visual.copyWith(stage: TarotRitualStage.draw),
      );
    }

    Future<void> drawOne(BuildContext context) async {
      final ok = await ritual.commitDraw(context);
      expect(ok, isTrue);
    }

    tearDown(() {
      reading.dispose();
      ritual.dispose();
      flow.dispose();
    });

    testWidgets('single: settle fail preserves card; retry no redraw',
        (tester) async {
      await boot(spread: TarotSpreadType.single);
      await pumpScope(
        tester,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                await drawOne(context);
                repo.failNextSaves = 1;
                expect(
                  await ritual.settleAfterReveal(context),
                  RitualSettleOutcome.failed,
                );
                expect(ritual.active, isNotNull);
                expect(ritual.placed, isEmpty);
                expect(reading.session!.drawnCards, hasLength(1));
                expect(reading.session!.flowStep, ReadingFlowStep.reveal);
                final id = ritual.active!.card.id;
                expect(
                  await ritual.settleAfterReveal(context),
                  RitualSettleOutcome.readingReady,
                );
                expect(reading.session!.drawnCards, hasLength(1));
                expect(ritual.placed.single.card.id, id);
                expect(ritual.active, isNull);
              },
              child: const Text('go'),
            );
          },
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    });

    testWidgets('threeCard non-final fail: no duplicate draw', (tester) async {
      await boot(spread: TarotSpreadType.threeCard);
      await pumpScope(
        tester,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                await drawOne(context);
                expect(reading.session!.drawnCards, hasLength(1));
                repo.failNextSaves = 1;
                expect(
                  await ritual.settleAfterReveal(context),
                  RitualSettleOutcome.failed,
                );
                expect(ritual.placed, isEmpty);
                expect(ritual.active, isNotNull);
                expect(reading.session!.drawnCards, hasLength(1));
                expect(
                  await ritual.settleAfterReveal(context),
                  RitualSettleOutcome.continueDraw,
                );
                expect(ritual.placed, hasLength(1));
                expect(reading.session!.drawnCards, hasLength(1));
              },
              child: const Text('go'),
            );
          },
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    });

    testWidgets('threeCard final fail: draw stays 3; retry places 3',
        (tester) async {
      await boot(spread: TarotSpreadType.threeCard);
      await pumpScope(
        tester,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                for (var i = 0; i < 2; i++) {
                  await drawOne(context);
                  expect(
                    await ritual.settleAfterReveal(context),
                    RitualSettleOutcome.continueDraw,
                  );
                }
                expect(ritual.placed, hasLength(2));
                await drawOne(context);
                expect(reading.session!.drawnCards, hasLength(3));
                final thirdId = ritual.active!.card.id;
                repo.failNextSaves = 1;
                expect(
                  await ritual.settleAfterReveal(context),
                  RitualSettleOutcome.failed,
                );
                expect(ritual.placed, hasLength(2));
                expect(ritual.active!.card.id, thirdId);
                expect(reading.session!.drawnCards, hasLength(3));
                expect(
                  await ritual.settleAfterReveal(context),
                  RitualSettleOutcome.readingReady,
                );
                expect(ritual.placed, hasLength(3));
                expect(ritual.active, isNull);
                expect(reading.session!.drawnCards, hasLength(3));
              },
              child: const Text('go'),
            );
          },
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    });

    testWidgets('fiveCard final fail: draw stays 5', (tester) async {
      await boot(spread: TarotSpreadType.fiveCard);
      await pumpScope(
        tester,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                for (var i = 0; i < 4; i++) {
                  await drawOne(context);
                  expect(
                    await ritual.settleAfterReveal(context),
                    RitualSettleOutcome.continueDraw,
                  );
                }
                await drawOne(context);
                expect(reading.session!.drawnCards, hasLength(5));
                repo.failNextSaves = 1;
                expect(
                  await ritual.settleAfterReveal(context),
                  RitualSettleOutcome.failed,
                );
                expect(reading.session!.drawnCards, hasLength(5));
                expect(ritual.placed, hasLength(4));
                expect(
                  await ritual.settleAfterReveal(context),
                  RitualSettleOutcome.readingReady,
                );
                expect(ritual.placed, hasLength(5));
                expect(reading.session!.drawnCards, hasLength(5));
              },
              child: const Text('go'),
            );
          },
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    });

    testWidgets('rapid settle returns busy; no double placed', (tester) async {
      await boot(spread: TarotSpreadType.single);
      await pumpScope(
        tester,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                await drawOne(context);
                repo.delaySaves = const Duration(milliseconds: 80);
                final first = ritual.settleAfterReveal(context);
                final second = await ritual.settleAfterReveal(context);
                expect(second, RitualSettleOutcome.busy);
                expect(await first, RitualSettleOutcome.readingReady);
                expect(ritual.placed, hasLength(1));
              },
              child: const Text('go'),
            );
          },
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    });
  });

  group('7D.1 awaitable completion', () {
    testWidgets('actor awaits onFlightComplete before returning',
        (tester) async {
      var settleStarted = false;
      var settleDone = false;
      final key = GlobalKey<CardFlightActorState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CardFlightActor(
                key: key,
                enabled: true,
                reducedMotion: true,
                onInteracted: () {},
                onRequestDraw: () async => _fakeReveal(1),
                onFlightComplete: (_) async {
                  settleStarted = true;
                  await Future<void>.delayed(const Duration(milliseconds: 40));
                  settleDone = true;
                },
              ),
            ),
          ),
        ),
      );
      final g = await tester.startGesture(
        tester.getCenter(find.byType(CardFlightActor)),
      );
      await g.moveBy(const Offset(0, -110));
      await g.up();
      await tester.pump();
      expect(settleStarted, isTrue);
      expect(settleDone, isFalse);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(settleDone, isTrue);
      expect(key.currentState!.face, isNotNull);
    });
  });

  group('7D.1 accessibility l10n', () {
    Future<void> pumpActor(WidgetTester tester, String locale) async {
      OraclyL10n.bind(locale);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CardFlightActor(
                enabled: true,
                reducedMotion: true,
                onInteracted: () {},
                onRequestDraw: () async => null,
                onFlightComplete: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('EN semantics localized', (tester) async {
      await pumpActor(tester, 'en');
      final node = tester.getSemantics(find.byType(CardFlightActor));
      expect(node.label, OraclyL10n.t('tarot.ritual.stage.draw'));
      expect(node.hint, OraclyL10n.t('tarot.ritual.draw_hint'));
      expect(node.label, isNot(equals('Draw card')));
    });

    testWidgets('TR semantics localized', (tester) async {
      await pumpActor(tester, 'tr');
      final node = tester.getSemantics(find.byType(CardFlightActor));
      expect(node.label, 'Üst kartı yukarı çek.');
      expect(node.hint, 'Kartı yukarı çek');
    });

    testWidgets('RU semantics localized', (tester) async {
      await pumpActor(tester, 'ru');
      final node = tester.getSemantics(find.byType(CardFlightActor));
      expect(node.label, 'Вытяни верхнюю карту вверх.');
      expect(node.hint, 'Потяни карту вверх');
    });

    test('source has no hardcoded English draw semantics', () {
      final src = File(
        'lib/features/tarot/ritual/table/card_flight_actor.dart',
      ).readAsStringSync();
      expect(src.contains("'Draw card'"), isFalse);
      expect(src.contains("'Drag upward to draw'"), isFalse);
      expect(src, contains("OraclyL10n.t('tarot.ritual.stage.draw')"));
      expect(src, contains("OraclyL10n.t('tarot.ritual.draw_hint')"));
    });
  });
}

RevealCardData _fakeReveal(int id) {
  final card = TarotCard(
    id: id,
    name: 'Card $id',
    image: 'lib/assets/images/tarot/major_arcana/00_aptal.png',
    arcana: TarotArcana.major,
    suit: TarotSuit.none,
    number: id,
    summary: 's',
    meaning: 'm',
    reversedMeaning: 'r',
    keywords: const ['k'],
    element: 'Air',
  );
  return RevealCardData(
    card: card,
    displayName: 'Card $id',
    subtitle: 'Upright',
    rarityLabel: 'Major',
    rarityColor: const Color(0xFF9B6DFF),
    imageAsset: card.image,
  );
}

class _CountingRepo implements TarotReadingRepository {
  _CountingRepo(this._inner);

  final TarotReadingRepository _inner;
  int failNextSaves = 0;
  Duration? delaySaves;

  @override
  Future<void> saveSession(ReadingSession session) async {
    if (delaySaves != null) await Future<void>.delayed(delaySaves!);
    if (failNextSaves > 0) {
      failNextSaves--;
      throw StateError('persist_failed');
    }
    await _inner.saveSession(session);
  }

  @override
  Future<void> clearActiveSession() => _inner.clearActiveSession();

  @override
  Future<void> deleteSession(String id) => _inner.deleteSession(id);

  @override
  Future<ReadingSession?> loadActiveSession() => _inner.loadActiveSession();

  @override
  Future<List<ReadingSession>> loadAllSessions() => _inner.loadAllSessions();

  @override
  Future<List<ReadingSession>> loadCompletedSessions() =>
      _inner.loadCompletedSessions();

  @override
  Future<ReadingSession?> loadSession(String id) => _inner.loadSession(id);
}
