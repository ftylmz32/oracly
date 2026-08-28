/// Deck physicality — shuffle, cut, draw, flip, gated SFX.
library;

import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/audio/oracly_feedback_gate.dart';
import 'package:oracly_new/core/audio/oracly_sound_chamber.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/audio/oracly_wav_synth.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/deck/physical_deck_stack.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/reveal_timeline.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/shuffle/shuffle_cut_motion.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/shuffle/shuffle_cut_offer.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/shuffle/shuffle_timeline.dart';

class _CountingSoundService extends OraclySoundService {
  final plays = <OraclySoundCue>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> play(OraclySoundCue cue) async {
    plays.add(cue);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  tearDown(() {
    OraclyFeedbackGate.sound = null;
    OraclyFeedbackGate.soundEnabled = true;
    OraclyFeedbackGate.hapticEnabled = true;
  });

  test('shuffle ritual is short and not a casino riffle', () {
    expect(
      ShuffleTimeline.totalDuration,
      lessThanOrEqualTo(const Duration(milliseconds: 2800)),
    );
    expect(ShuffleTimeline.separation(0.5), lessThan(0.35));
    expect(ShuffleTimeline.shuffleEnvelope(0.42), greaterThan(0.4));
    expect(ShuffleTimeline.shuffleEnvelope(0.0), 0);
    expect(ShuffleTimeline.shuffleEnvelope(1.0), closeTo(0, 1e-10));
  });

  test('cut splits the deck then reforms', () {
    final leftPeak = ShuffleCutMotion.packetOffset(
      index: 0,
      total: 8,
      t: 0.40,
    );
    final rightPeak = ShuffleCutMotion.packetOffset(
      index: 7,
      total: 8,
      t: 0.40,
    );
    expect(leftPeak.dx, lessThan(-10));
    expect(rightPeak.dx, greaterThan(10));

    final leftRest = ShuffleCutMotion.packetOffset(
      index: 0,
      total: 8,
      t: 1,
    );
    final rightRest = ShuffleCutMotion.packetOffset(
      index: 7,
      total: 8,
      t: 1,
    );
    expect(leftRest.distance, lessThan(1));
    expect(rightRest.distance, lessThan(1));
  });

  test('draw rises from the resting pile then flips slowly', () {
    expect(RevealTimeline.floatUp(0), closeTo(RevealTimeline.deckRestY, 0.5));
    expect(RevealTimeline.floatUp(0.42), lessThan(RevealTimeline.floatUp(0)));
    expect(RevealTimeline.originDeckOpacity(0), 1);
    expect(RevealTimeline.originDeckOpacity(1), 0);

    expect(RevealTimeline.flipRotation(0), 0);
    expect(RevealTimeline.flipRotation(RevealTimeline.flipStart), 0);
    expect(RevealTimeline.flipRotation(1), closeTo(pi, 0.01));
    final window = RevealTimeline.flipEnd - RevealTimeline.flipStart;
    expect(window, greaterThan(0.30));
  });

  test('paper rustle is a real WAV, not an empty click', () {
    expect(OraclyWavSynth.paperRustle().length, greaterThan(44));
  });

  test('cardMove is silent when SFX are disabled', () {
    final service = _CountingSoundService();
    OraclyFeedbackGate.bind(
      service: service,
      haptics: false,
      sounds: false,
    );
    OraclyFeedbackGate.cardMove();
    OraclyFeedbackGate.cardReveal();
    expect(service.plays, isEmpty);
  });

  testWidgets('physical deck stack paints without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: PhysicalDeckStack()),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(PhysicalDeckStack), findsOneWidget);
  });

  testWidgets('cut offer shows Desteyi kes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShuffleCutOffer(onCut: () {}, onSkip: () {}),
        ),
      ),
    );
    expect(find.text('Desteyi kes'), findsOneWidget);
    expect(TarotPolishCopy.cutDeck, 'Desteyi kes');
  });
}
