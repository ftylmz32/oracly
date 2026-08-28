/// Explicit Sesli Anlat session phases — not a second analysis pipeline.
library;

enum DreamVoicePhase {
  idle,
  recording,
  processing,
  transcribed,
  error,
}
