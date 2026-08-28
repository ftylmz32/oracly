/// OR Rehberi voice input — real STT only, never a fabricated transcript.
library;

import 'package:flutter/foundation.dart';

import '../models/insight_request.dart';
import '../voice/companion_speech_result.dart';
import '../voice/companion_voice_failure.dart';
import '../voice/companion_voice_permission.dart';

abstract class CompanionVoiceInputPort {
  const CompanionVoiceInputPort();

  /// Implementation exists. Device support is probed in [isSpeechAvailable].
  bool get isAvailable;

  Future<bool> isSpeechAvailable();

  Future<CompanionVoicePermission> requestPermission();

  Future<void> startListening({
    required void Function(CompanionSpeechResult result) onResult,
    required void Function(CompanionVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  });

  Future<void> stopListening();

  Future<void> cancelListening();
}

class UnavailableCompanionVoiceInput extends CompanionVoiceInputPort {
  const UnavailableCompanionVoiceInput();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> isSpeechAvailable() async => false;

  @override
  Future<CompanionVoicePermission> requestPermission() async =>
      CompanionVoicePermission.unavailable;

  @override
  Future<void> startListening({
    required void Function(CompanionSpeechResult result) onResult,
    required void Function(CompanionVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    onError(CompanionVoiceFailure.speechUnavailable());
  }

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> cancelListening() async {}
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
