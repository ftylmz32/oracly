/// OR presence — one identity, four quiet states. Error looks like idle.
library;

import '../../models/companion_state.dart';

enum CompanionOrPresence { idle, thinking, speaking, error }

abstract final class CompanionOrPresenceResolve {
  CompanionOrPresenceResolve._();

  /// Speaking glow only in voice mode. Text mode stays visually present, idle.
  static CompanionOrPresence from({
    required CompanionPhase phase,
    required bool busy,
    required bool speaking,
    bool voiceMode = false,
  }) {
    if (voiceMode && speaking) return CompanionOrPresence.speaking;
    if (busy || phase == CompanionPhase.thinking) {
      return CompanionOrPresence.thinking;
    }
    return CompanionOrPresence.idle;
  }
}
