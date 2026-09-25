/// Phase 7D — actor ownership, duplication, reduced-motion, failed draw.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_actor.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_face.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_math.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_phase.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_actor_ownership.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_phase.dart';
import 'package:oracly_new/features/tarot/ritual/tarot_ritual_stage.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_card_shell.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_spread_slots.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';

RevealCardData _sample(int id) {
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

/// START HEAD showFlight — kept for regression proof only.
bool _legacyShowFlight(TarotTablePhase phase, TarotRitualStage stage) {
  return phase == TarotTablePhase.draw ||
      phase == TarotTablePhase.reading ||
      stage == TarotRitualStage.draw ||
      stage == TarotRitualStage.reveal ||
      stage == TarotRitualStage.place;
}

void main() {
  group('7D actor ownership', () {
    test('multi reading releases actor once all slots settled', () {
      expect(
        TarotTableActorOwnership.ownsActiveCard(
          phase: TarotTablePhase.reading,
          ritualStage: TarotRitualStage.place,
          cardCount: 3,
          placedCount: 3,
        ),
        isFalse,
      );
      // START HEAD would still show flight — defect proof.
      expect(
        _legacyShowFlight(TarotTablePhase.reading, TarotRitualStage.place),
        isTrue,
      );
    });

    test('single reading keeps actor as sole physical face', () {
      expect(
        TarotTableActorOwnership.ownsActiveCard(
          phase: TarotTablePhase.reading,
          ritualStage: TarotRitualStage.place,
          cardCount: 1,
          placedCount: 1,
        ),
        isTrue,
      );
    });

    test('draw phase owns card before settle', () {
      expect(
        TarotTableActorOwnership.ownsActiveCard(
          phase: TarotTablePhase.draw,
          ritualStage: TarotRitualStage.reveal,
          cardCount: 3,
          placedCount: 2,
        ),
        isTrue,
      );
    });
  });

  group('7D reduced motion parity', () {
    test('singleSettledOffset matches completed flight math', () {
      final end = CardFlightMath.flightOffset(
        drag: const Offset(0, -96),
        phase: CardFlightPhase.placing,
        t: 1,
        placeTarget: null,
      );
      expect(end, CardFlightMath.singleSettledOffset);
      expect(CardFlightMath.settledOffset(null), end);
    });

    test('actions source has no Offset(0,-120) reduced-motion fallback', () {
      final src = File(
        'lib/features/tarot/ritual/table/card_flight_actor_actions.dart',
      ).readAsStringSync();
      expect(src.contains('Offset(0, -120)'), isFalse);
      expect(src, contains('CardFlightMath.settledOffset'));
      expect(src, contains('flight.value = 1'));
    });

    testWidgets('reduced motion lands at singleSettledOffset with face',
        (tester) async {
      final key = GlobalKey<CardFlightActorState>();
      var completes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CardFlightActor(
                key: key,
                enabled: true,
                reducedMotion: true,
                placeTarget: null,
                onInteracted: () {},
                onRequestDraw: () async => _sample(1),
                onFlightComplete: (_) => completes++,
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(CardFlightActor));
      final g = await tester.startGesture(center);
      await g.moveBy(const Offset(0, -110));
      await g.up();
      await tester.pumpAndSettle();
      expect(key.currentState!.phase, CardFlightPhase.placed);
      expect(key.currentState!.drag, CardFlightMath.singleSettledOffset);
      expect(key.currentState!.drag, isNot(const Offset(0, -120)));
      expect(completes, 1);
      expect(find.byType(RitualCardFace), findsOneWidget);
    });
  });

  group('7D multi-card face ownership', () {
    testWidgets('threeCard final: 3 faces, no actor face', (tester) async {
      final placed = [_sample(1), _sample(2), _sample(3)];
      final showFlight = TarotTableActorOwnership.ownsActiveCard(
        phase: TarotTablePhase.reading,
        ritualStage: TarotRitualStage.place,
        cardCount: 3,
        placedCount: placed.length,
      );
      expect(showFlight, isFalse);
      expect(
        _legacyShowFlight(TarotTablePhase.reading, TarotRitualStage.place),
        isTrue,
        reason: 'START HEAD would keep actor mounted (duplication)',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RitualSpreadSlots(
                  placed: placed,
                  spread: TarotSpreadType.threeCard,
                ),
                if (showFlight)
                  CardFlightActor(
                    enabled: false,
                    reducedMotion: true,
                    onInteracted: () {},
                    onRequestDraw: () async => _sample(99),
                    onFlightComplete: (_) {},
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(RitualCardFace), findsNWidgets(3));
      expect(find.byType(CardFlightActor), findsNothing);
      expect(find.byType(CardFlightFace), findsNothing);
    });

    testWidgets('fiveCard final: 5 faces, no actor face', (tester) async {
      final placed = List.generate(5, _sample);
      final showFlight = TarotTableActorOwnership.ownsActiveCard(
        phase: TarotTablePhase.reading,
        ritualStage: TarotRitualStage.place,
        cardCount: 5,
        placedCount: 5,
      );
      expect(showFlight, isFalse);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RitualSpreadSlots(
                  placed: placed,
                  spread: TarotSpreadType.fiveCard,
                ),
                if (showFlight)
                  CardFlightActor(
                    enabled: false,
                    onInteracted: () {},
                    onRequestDraw: () async => _sample(99),
                    onFlightComplete: (_) {},
                  ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(RitualCardFace), findsNWidgets(5));
      expect(find.byType(CardFlightActor), findsNothing);
    });
  });

  group('7D draw domain', () {
    testWidgets('failed draw does not complete or keep face', (tester) async {
      final key = GlobalKey<CardFlightActorState>();
      var draws = 0;
      var completes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CardFlightActor(
                key: key,
                enabled: true,
                reducedMotion: true,
                onInteracted: () {},
                onRequestDraw: () async {
                  draws++;
                  return null;
                },
                onFlightComplete: (_) => completes++,
              ),
            ),
          ),
        ),
      );
      final center = tester.getCenter(find.byType(CardFlightActor));
      final g = await tester.startGesture(center);
      await g.moveBy(const Offset(0, -110));
      await g.up();
      await tester.pumpAndSettle();
      expect(draws, 1);
      expect(completes, 0);
      expect(key.currentState!.face, isNull);
      expect(key.currentState!.phase, CardFlightPhase.onDeck);
      expect(key.currentState!.drawFired, isFalse);

      // Retry succeeds.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CardFlightActor(
                key: key,
                enabled: true,
                reducedMotion: true,
                onInteracted: () {},
                onRequestDraw: () async {
                  draws++;
                  return _sample(7);
                },
                onFlightComplete: (_) => completes++,
              ),
            ),
          ),
        ),
      );
      final g2 = await tester.startGesture(
        tester.getCenter(find.byType(CardFlightActor)),
      );
      await g2.moveBy(const Offset(0, -110));
      await g2.up();
      await tester.pumpAndSettle();
      expect(draws, 2);
      expect(completes, 1);
      expect(key.currentState!.face, isNotNull);
    });

    testWidgets('threeCard reduced: 3 commits → 3 draws → 3 completes',
        (tester) async {
      final key = GlobalKey<CardFlightActorState>();
      var draws = 0;
      var completes = 0;
      final placed = <RevealCardData>[];

      Future<void> pumpActor() async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: CardFlightActor(
                  key: key,
                  enabled: true,
                  reducedMotion: true,
                  placeTarget: const Offset(40, -80),
                  onInteracted: () {},
                  onRequestDraw: () async {
                    draws++;
                    return _sample(draws);
                  },
                  onFlightComplete: (data) {
                    completes++;
                    placed.add(data);
                    key.currentState?.resetForNextDraw();
                  },
                ),
              ),
            ),
          ),
        );
      }

      await pumpActor();
      final before = key.currentState!;
      final id = before.identityToken;

      for (var i = 0; i < 3; i++) {
        final g = await tester.startGesture(
          tester.getCenter(find.byType(CardFlightActor)),
        );
        await g.moveBy(const Offset(0, -110));
        await g.up();
        await tester.pumpAndSettle();
        expect(identical(key.currentState, before), isTrue);
        expect(key.currentState!.identityToken, same(id));
      }

      expect(draws, 3);
      expect(completes, 3);
      expect(placed.map((e) => e.card.id).toSet().length, 3);
      expect(key.currentState!.face, isNull);
      expect(key.currentState!.phase, CardFlightPhase.onDeck);
    });

    testWidgets('fiveCard reduced: 5 commits → 5 draws', (tester) async {
      final key = GlobalKey<CardFlightActorState>();
      var draws = 0;
      var completes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CardFlightActor(
                key: key,
                enabled: true,
                reducedMotion: true,
                placeTarget: const Offset(20, -60),
                onInteracted: () {},
                onRequestDraw: () async {
                  draws++;
                  return _sample(draws);
                },
                onFlightComplete: (_) {
                  completes++;
                  key.currentState?.resetForNextDraw();
                },
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 5; i++) {
        final g = await tester.startGesture(
          tester.getCenter(find.byType(CardFlightActor)),
        );
        await g.moveBy(const Offset(0, -110));
        await g.up();
        await tester.pumpAndSettle();
      }
      expect(draws, 5);
      expect(completes, 5);
    });
  });
}
