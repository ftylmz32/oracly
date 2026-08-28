/// One voice-conversation turn — never a continuous listen loop.
library;

enum OrVoiceTurnPhase {
  /// Mic off; waiting for an intentional tap.
  ready,
  listening,
  /// Soft beat after speech ends — not walkie-talkie cutover.
  settling,
  thinking,
  speaking,
}

extension OrVoiceTurnPhaseX on OrVoiceTurnPhase {
  bool get blocksComposerSend =>
      this == OrVoiceTurnPhase.listening ||
      this == OrVoiceTurnPhase.settling ||
      this == OrVoiceTurnPhase.thinking;
}
