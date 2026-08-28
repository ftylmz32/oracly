/// Procedural SFX cue bytes — volumes tuned for real device audibility.
library;

import 'dart:typed_data';

import 'oracly_sound_chamber.dart';
import 'oracly_wav_synth.dart';

abstract final class OraclySfxCues {
  OraclySfxCues._();

  static Uint8List bytesFor(OraclySoundCue cue, double detune) {
    return switch (cue) {
      OraclySoundCue.softTap || OraclySoundCue.buttonTap =>
        OraclyWavSynth.softTap(detune: detune),
      OraclySoundCue.selection => OraclyWavSynth.selectionTick(detune: detune),
      OraclySoundCue.cardSlide => OraclyWavSynth.paperRustle(detune: detune),
      OraclySoundCue.orbHum => OraclyWavSynth.tone(
          frequencyHz: 176 * detune,
          durationMs: 680,
          volume: 0.14,
          releaseMs: 420,
        ),
      OraclySoundCue.cardFlip => OraclyWavSynth.sweep(
          fromHz: 260 * detune,
          toHz: 128 * detune,
          durationMs: 260,
          volume: 0.16,
        ),
      OraclySoundCue.revealTone => OraclyWavSynth.tone(
          frequencyHz: 392 * detune,
          durationMs: 320,
          volume: 0.09,
          attackMs: 40,
          releaseMs: 220,
        ),
      OraclySoundCue.magicalReveal => OraclyWavSynth.chime(
          frequencies: [392 * detune, 523.2 * detune, 659.2 * detune],
          durationMs: 920,
          volume: 0.15,
        ),
      OraclySoundCue.journeyComplete => OraclyWavSynth.chime(
          frequencies: [329.6 * detune, 440 * detune, 554.4 * detune],
          durationMs: 1400,
          volume: 0.14,
        ),
      OraclySoundCue.premiumPurchase => OraclyWavSynth.chime(
          frequencies: [
            440 * detune,
            554.4 * detune,
            659.2 * detune,
            783.9 * detune,
          ],
          durationMs: 1600,
          volume: 0.15,
        ),
    };
  }
}
