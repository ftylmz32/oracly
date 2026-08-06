/// SPRINT-001 — Future-ready voice input port (not implemented).
library;

abstract class DreamVoiceInputPort {
  const DreamVoiceInputPort();

  bool get isAvailable;

  Future<String?> recordAndTranscribe();
}

class UnavailableDreamVoiceInput extends DreamVoiceInputPort {
  const UnavailableDreamVoiceInput();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> recordAndTranscribe() async => null;
}
