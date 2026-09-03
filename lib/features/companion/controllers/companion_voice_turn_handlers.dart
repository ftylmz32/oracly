/// Voice/session listener + commit wiring for [CompanionVoiceTurnController].
library;

import 'dart:async';

import '../voice/or_voice_turn_phase.dart';
import 'companion_controller.dart';
import 'companion_output_controller.dart';
import 'companion_voice_controller.dart';
import 'companion_voice_turn_commit.dart';

typedef VoiceTurnPhaseSetter = void Function(OrVoiceTurnPhase phase);
typedef VoiceTurnNotify = void Function();

void companionVoiceOnEnded({
  required bool disposed,
  required bool active,
  required OrVoiceTurnPhase phase,
  required CompanionVoiceController voice,
  required VoiceTurnPhaseSetter setPhase,
  required VoiceTurnNotify notify,
  required void Function(String text) commit,
}) {
  if (disposed || !active || phase != OrVoiceTurnPhase.listening) return;
  if (voice.isActive) return;
  if (voice.errorMessage != null || voice.transcript.trim().isEmpty) {
    setPhase(OrVoiceTurnPhase.ready);
    notify();
    return;
  }
  if (voice.needsReview) {
    setPhase(OrVoiceTurnPhase.ready);
    notify();
    return;
  }
  commit(voice.transcript.trim());
}

void companionVoiceOnSessionError({
  required bool disposed,
  required bool active,
  required OrVoiceTurnPhase phase,
  required CompanionController? session,
  required VoiceTurnPhaseSetter setPhase,
  required VoiceTurnNotify notify,
}) {
  if (disposed || !active) return;
  if (phase == OrVoiceTurnPhase.thinking &&
      session?.state.errorMessage != null) {
    setPhase(OrVoiceTurnPhase.ready);
    notify();
  }
}

Future<void> companionVoiceRunCommit({
  required String text,
  required int turnId,
  required int Function() currentTurn,
  required bool Function() alive,
  required CompanionVoiceController voice,
  required CompanionOutputController output,
  required Future<void> Function(String text)? send,
  required VoiceTurnPhaseSetter setPhase,
  required VoiceTurnNotify notify,
  required void Function(OrVoiceTurnPhase phase) applyPhase,
}) async {
  if (!alive()) return;
  final next = await commitVoiceTurn(
    text: text,
    turnId: turnId,
    currentTurn: currentTurn,
    isActive: alive,
    output: output,
    send: send,
    setPhase: (phase) {
      if (!alive()) return;
      setPhase(phase);
      notify();
    },
  );
  if (!alive() || turnId != currentTurn()) return;
  voice.consumeTranscript();
  applyPhase(next);
  notify();
}
