/// Keeps the visible Dream draft aligned with voice capture.
library;

import 'package:flutter/widgets.dart';

import '../controllers/dream_voice_controller.dart';
import 'dream_voice_phase.dart';

/// One narrative field. Voice may replace it only after a new capture starts,
/// and a cancelled review must not leave that transcript behind.
abstract final class DreamVoiceDraft {
  DreamVoiceDraft._();

  static void onPhase({
    required TextEditingController narrative,
    required DreamVoicePhase? from,
    required DreamVoiceController next,
  }) {
    if (from == DreamVoicePhase.transcribed &&
        next.phase == DreamVoicePhase.recording) {
      narrative.clear();
    }
    if (next.phase == DreamVoicePhase.transcribed &&
        narrative.text != next.transcript) {
      narrative.text = next.transcript;
    }
  }

  /// Back from the review screen abandons that voice draft.
  /// Recording cancel and a failed first capture leave typed text alone.
  static void abandon({
    required TextEditingController narrative,
    required DreamVoiceController voice,
  }) {
    final dropReview = voice.phase == DreamVoicePhase.transcribed;
    voice.reset();
    if (dropReview) narrative.clear();
  }

  /// Permission failure returns before any new recording, so the review text
  /// stays. A later recording phase is what clears it.
  static Future<void> listenAgain({
    required Future<bool?> Function() askMicrophone,
    required DreamVoiceController voice,
  }) async {
    final allowed = await askMicrophone();
    if (allowed != true) return;
    await voice.listenAgain();
  }
}
