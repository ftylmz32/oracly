/// Tarot ritual — restrained motion, gated SFX, haptic, reduced motion.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/audio/oracly_feedback_gate.dart';
import 'package:oracly_new/core/audio/oracly_sound_chamber.dart';
import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/audio/oracly_wav_synth.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/reveal_sound_callbacks.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/reveal_timeline.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/shuffle/shuffle_ritual_experience.dart';
import 'package:oracly_new/shared/widgets/oracly_pressable.dart';

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

  test('reveal tone is a quiet single note, not a fantasy chime', () {
    final quiet = OraclyWavSynth.tone(
      frequencyHz: 392,
      durationMs: 320,
      volume: 0.09,
      attackMs: 40,
      releaseMs: 220,
    );
    final chime = OraclyWavSynth.chime(
      frequencies: const [392, 523.2, 659.2],
      durationMs: 920,
      volume: 0.15,
    );
    expect(quiet.length, greaterThan(44));
    expect(quiet.length, lessThan(chime.length));
  });

  test('bloom cue fires once after the flip, not as click spam', () {
    final service = _CountingSoundService();
    final tracker = RevealSoundCallbackTracker(service.revealCallbacks);

    tracker.tick(0.02);
    tracker.tick(RevealTimeline.flipStart);
    tracker.tick(RevealTimeline.flipEnd + 0.08);
    tracker.tick(1);

    expect(service.plays, [
      OraclySoundCue.cardSlide,
      OraclySoundCue.cardFlip,
      OraclySoundCue.revealTone,
    ]);
  });

  test('bloom cue is silent when SFX are disabled', () {
    final service = _CountingSoundService();
    OraclyFeedbackGate.bind(
      service: service,
      haptics: true,
      sounds: false,
    );
    OraclyFeedbackGate.cardMove();
    OraclyFeedbackGate.cardReveal();
    OraclyFeedbackGate.revealBloom();
    expect(service.plays, isEmpty);
  });

  test('reveal haptic does not throw when haptic is off', () {
    OraclyFeedbackGate.hapticEnabled = false;
    OraclyTouchFeedback.selection();
    OraclyTouchFeedback.reveal();
  });

  testWidgets('reduced motion skips the shuffle ritual', (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ShuffleRitualExperience(onComplete: () => completed++),
        ),
      ),
    );
    await tester.pump();
    expect(completed, 1);
    await tester.pump(const Duration(milliseconds: 2800));
    expect(completed, 1);
  });
}
