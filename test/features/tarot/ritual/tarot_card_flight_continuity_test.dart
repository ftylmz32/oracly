/// Proves CardFlightActor identity survives drag → commit → flip → place.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/ritual/gestures/ritual_draw_gesture.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_actor.dart';
import 'package:oracly_new/features/tarot/ritual/table/card_flight_phase.dart';

void main() {
  RevealCardData sample() {
    const card = TarotCard(
      id: 17,
      name: 'The Star',
      image: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
      arcana: TarotArcana.major,
      suit: TarotSuit.none,
      number: 17,
      summary: 'Umut',
      meaning: 'Rehberlik',
      reversedMeaning: 'Gecikme',
      keywords: ['umut'],
      element: 'Su',
    );
    return RevealCardData(
      card: card,
      displayName: 'The Star',
      subtitle: 'Upright',
      rarityLabel: 'Major',
      rarityColor: const Color(0xFF9B6DFF),
      imageAsset: card.image,
    );
  }

  testWidgets('same State identity from drag through flip', (tester) async {
    final key = GlobalKey<CardFlightActorState>();
    var draws = 0;
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
                return sample();
              },
              onFlightComplete: (_) {},
            ),
          ),
        ),
      ),
    );

    final before = key.currentState!;
    final token = before.identityToken;
    final center = tester.getCenter(find.byType(CardFlightActor));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, -110));
    await tester.pump();
    expect(identical(key.currentState, before), isTrue);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(identical(key.currentState, before), isTrue);
    expect(key.currentState!.identityToken, same(token));
    expect(key.currentState!.phase, CardFlightPhase.placed);
    expect(draws, 1);
  });

  testWidgets('below threshold does not draw and keeps actor', (tester) async {
    final key = GlobalKey<CardFlightActorState>();
    var draws = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CardFlightActor(
              key: key,
              enabled: true,
              onInteracted: () {},
              onRequestDraw: () async {
                draws++;
                return sample();
              },
              onFlightComplete: (_) {},
            ),
          ),
        ),
      ),
    );
    final before = key.currentState!;
    final center = tester.getCenter(find.byType(CardFlightActor));
    final gesture = await tester.startGesture(center);
    await gesture.moveBy(const Offset(0, -40));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(draws, 0);
    expect(identical(key.currentState, before), isTrue);
    expect(key.currentState!.phase, CardFlightPhase.onDeck);
  });

  test('commit threshold unchanged', () {
    expect(RitualDrawThreshold.commitPx, 96);
  });

  test('reveal path does not pushReplacement ReadingScreen', () {
    final text = File(
      'lib/features/tarot/ritual/table/tarot_table_scene_state.dart',
    ).readAsStringSync();
    expect(text, contains('Navigator.of(context).push('));
    expect(text.contains('.pushReplacement('), isFalse);
    expect(text, contains('reading stays on table'));
    expect(text, contains('TarotTablePhase.reading'));
  });

  testWidgets('resetForNextDraw preserves State for 3-card continuity',
      (tester) async {
    final key = GlobalKey<CardFlightActorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CardFlightActor(
              key: key,
              enabled: true,
              reducedMotion: true,
              placeTarget: const Offset(-80, -200),
              onInteracted: () {},
              onRequestDraw: () async => sample(),
              onFlightComplete: (_) {},
            ),
          ),
        ),
      ),
    );
    final state = key.currentState!;
    final token = state.identityToken;
    final center = tester.getCenter(find.byType(CardFlightActor));
    final g = await tester.startGesture(center);
    await g.moveBy(const Offset(0, -110));
    await g.up();
    await tester.pumpAndSettle();
    expect(state.phase, CardFlightPhase.placed);
    state.resetForNextDraw();
    await tester.pump();
    expect(identical(key.currentState, state), isTrue);
    expect(key.currentState!.identityToken, same(token));
    expect(key.currentState!.phase, CardFlightPhase.onDeck);
  });
}
