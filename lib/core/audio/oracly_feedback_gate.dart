import 'oracly_sound_chamber.dart';
import 'oracly_sound_service.dart';

/// Updated by the app shell when personalization settings change.
abstract final class OraclyFeedbackGate {
  OraclyFeedbackGate._();

  static OraclySoundService? sound;
  static bool hapticEnabled = true;
  static bool soundEnabled = true;

  static void bind({
    required OraclySoundService service,
    required bool haptics,
    required bool sounds,
  }) {
    sound = service;
    hapticEnabled = haptics;
    soundEnabled = sounds;
    service.syncSfxEnabled(sounds);
    if (!sounds) {
      // ignore: unawaited_futures
      service.stopSfx();
    }
  }

  static void playCue(OraclySoundCue cue) {
    if (!soundEnabled) return;
    final resolved = cue == OraclySoundCue.buttonTap
        ? OraclySoundCue.softTap
        : cue;
    final service = sound;
    if (service == null) return;
    // ignore: unawaited_futures
    service.play(resolved);
  }

  static void softTap() => playCue(OraclySoundCue.softTap);

  static void selection() => playCue(OraclySoundCue.selection);

  /// Soft paper movement — shuffle, cut, draw.
  static void cardMove() => playCue(OraclySoundCue.cardSlide);

  /// Card turn during reveal ritual.
  static void cardReveal() => playCue(OraclySoundCue.cardFlip);

  /// Quiet bloom after the card has turned.
  static void revealBloom() => playCue(OraclySoundCue.revealTone);

  /// Successful reading / analysis complete.
  static void successfulAnalysis() => playCue(OraclySoundCue.journeyComplete);

  /// Ceremonial special reveal peak.
  static void specialReveal() => playCue(OraclySoundCue.magicalReveal);

  static void acknowledgeTap() => softTap();
}
