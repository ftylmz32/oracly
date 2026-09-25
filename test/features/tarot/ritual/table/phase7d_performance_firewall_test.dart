/// Phase 7D — live table GPU / filter firewall (source).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TarotTableBackground remains static — no filters/controllers', () {
    final bg = File(
      'lib/features/tarot/ritual/table/tarot_table_background.dart',
    ).readAsStringSync();
    final layers = File(
      'lib/features/tarot/ritual/table/tarot_table_background_layers.dart',
    ).readAsStringSync();
    for (final src in [bg, layers]) {
      expect(src.contains('AnimationController'), isFalse);
      expect(src.contains('ImageFiltered'), isFalse);
      expect(src.contains('ImageFilter'), isFalse);
      expect(src.contains('BackdropFilter'), isFalse);
    }
    expect(layers, contains('shouldRepaint'));
    expect(layers, contains('false'));
  });

  test('TarotDeckTableAtmosphere has zero ImageFiltered layers', () {
    final src = File(
      'lib/features/tarot/presentation/widgets/deck/tarot_deck_table_atmosphere.dart',
    ).readAsStringSync();
    expect(src.contains('ImageFiltered('), isFalse);
    expect(src.contains('ImageFilter.blur('), isFalse);
    expect(src.contains('BackdropFilter('), isFalse);
    expect(src.contains('AnimationController'), isFalse);
    expect(src, contains('RadialGradient'));
    expect(src, contains('BoxShadow'));
  });

  test('CardFlightActor keeps only spring + flight controllers', () {
    final src = File(
      'lib/features/tarot/ritual/table/card_flight_actor.dart',
    ).readAsStringSync();
    final controllers = RegExp(r'AnimationController').allMatches(src).length;
    expect(controllers, lessThanOrEqualTo(6));
    expect(src.contains('AnimationController'), isTrue);
    expect(src.contains(r'ambient'), isFalse);
  });

  test('live home still resolves to TarotTableScene only', () {
    final home = File(
      'lib/features/tarot/presentation/screens/tarot_home_screen.dart',
    ).readAsStringSync();
    expect(home, contains('TarotTableScene'));
    expect(home.contains('CardRevealScreen'), isFalse);
  });

  test('scene uses TarotTableActorOwnership — not broad reading showFlight', () {
    final src = File(
      'lib/features/tarot/ritual/table/tarot_table_scene.dart',
    ).readAsStringSync();
    expect(src, contains('TarotTableActorOwnership.ownsActiveCard'));
    expect(
      src.contains('phase == TarotTablePhase.draw ||\n'
          '        phase == TarotTablePhase.reading'),
      isFalse,
      reason: 'START HEAD broad showFlight must not return',
    );
  });
}
