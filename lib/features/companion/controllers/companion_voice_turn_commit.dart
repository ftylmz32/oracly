/// One SOHBET turn commit — invalidated by interrupt generation.
library;

import '../voice/or_voice_turn_phase.dart';
import 'companion_output_controller.dart';
import 'companion_voice_turn_speech.dart';

Future<OrVoiceTurnPhase> commitVoiceTurn({
  required String text,
  required int turnId,
  required int Function() currentTurn,
  required bool Function() isActive,
  required CompanionOutputController output,
  required Future<void> Function(String text)? send,
  required void Function(OrVoiceTurnPhase phase) setPhase,
}) async {
  setPhase(OrVoiceTurnPhase.settling);
  await Future<void>.delayed(const Duration(milliseconds: 420));
  if (turnId != currentTurn() || !isActive()) return OrVoiceTurnPhase.ready;
  setPhase(OrVoiceTurnPhase.thinking);
  try {
    if (send == null) return OrVoiceTurnPhase.ready;
    await send(text);
  } catch (_) {
    return OrVoiceTurnPhase.ready;
  }
  if (turnId != currentTurn() || !isActive()) return OrVoiceTurnPhase.ready;
  if (!output.isVoice || output.voiceUnavailable) {
    return OrVoiceTurnPhase.ready;
  }
  setPhase(OrVoiceTurnPhase.speaking);
  await awaitOrVoiceReplyEnd(
    output: output,
    turnId: turnId,
    currentTurn: currentTurn,
  );
  if (turnId != currentTurn() || !isActive()) return OrVoiceTurnPhase.ready;
  return OrVoiceTurnPhase.ready;
}
