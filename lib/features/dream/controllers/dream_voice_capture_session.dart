/// Continuous dictation session state — segments, restarts, stop sealing.
library;

import '../voice/dream_voice_phase.dart';
import '../voice/dream_voice_transcript.dart';

class DreamVoiceCaptureSession {
  static const maxRestarts = 60;

  final DreamVoiceTranscript accumulator = DreamVoiceTranscript();
  var listenGeneration = 0;
  var restartAttempts = 0;
  var restarting = false;
  var stopping = false;

  void reset() {
    accumulator.reset();
    listenGeneration = 0;
    restartAttempts = 0;
    restarting = false;
    stopping = false;
  }

  bool canRestart(DreamVoicePhase phase) {
    return phase == DreamVoicePhase.recording &&
        !restarting &&
        !stopping &&
        restartAttempts < maxRestarts;
  }

  /// Commit unfinalized speech before a platform pause/restart boundary.
  void sealBeforeRecognitionRestart() {
    accumulator.beginNextGeneration();
  }

  String sealForReview() {
    accumulator.finalizeActiveSegment();
    return accumulator.text;
  }
}
