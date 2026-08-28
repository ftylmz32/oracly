/// Wait for one OR reply utterance to finish — never starts the mic.
library;

import 'dart:async';

import '../../../core/voice/oracly_tts_gate.dart';
import 'companion_output_controller.dart';

Future<void> awaitOrVoiceReplyEnd({
  required CompanionOutputController output,
  required int turnId,
  required int Function() currentTurn,
}) async {
  final started = DateTime.now();
  while (turnId == currentTurn() && !output.isSpeaking) {
    if (DateTime.now().difference(started) > const Duration(milliseconds: 900)) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 40));
  }
  if (turnId != currentTurn() || !output.isSpeaking) return;
  var sawSpeech = true;
  final gate = Completer<void>();
  void tick() {
    if (turnId != currentTurn()) return;
    if (output.isSpeaking) sawSpeech = true;
    if (sawSpeech && !output.isSpeaking && !output.isPaused) {
      if (!gate.isCompleted) gate.complete();
    }
  }
  OraclyTtsGate.speaking.addListener(tick);
  OraclyTtsGate.paused.addListener(tick);
  try {
    await gate.future.timeout(const Duration(minutes: 3), onTimeout: () {});
  } finally {
    OraclyTtsGate.speaking.removeListener(tick);
    OraclyTtsGate.paused.removeListener(tick);
  }
}
