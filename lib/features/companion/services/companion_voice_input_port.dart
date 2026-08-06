/// SPRINT-003 — Future-ready voice input port.
library;

import '../models/insight_request.dart';

abstract class CompanionVoiceInputPort {
  const CompanionVoiceInputPort();

  bool get isAvailable;

  Stream<String> listenAndTranscribe();

  Future<void> stop();
}

class UnavailableCompanionVoiceInput extends CompanionVoiceInputPort {
  const UnavailableCompanionVoiceInput();

  @override
  bool get isAvailable => false;

  @override
  Stream<String> listenAndTranscribe() async* {}

  @override
  Future<void> stop() async {}
}

/// Input channel independent from conversation logic.
abstract class CompanionInputChannel {
  Future<InsightRequestPayload> capture();
}

class TextCompanionInputChannel implements CompanionInputChannel {
  TextCompanionInputChannel(this.text);

  final String text;

  @override
  Future<InsightRequestPayload> capture() async {
    return InsightRequestPayload(text: text, fromVoice: false);
  }
}

class InsightRequestPayload {
  const InsightRequestPayload({
    required this.text,
    required this.fromVoice,
  });

  final String text;
  final bool fromVoice;

  InsightRequest toRequest() => InsightRequest(
        text: text,
        voiceTranscript: fromVoice,
      );
}
