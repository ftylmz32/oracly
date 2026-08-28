/// Dream voice input — real STT only, never a fabricated transcript.
library;

import 'package:flutter/foundation.dart';

import '../voice/dream_voice_failure.dart';
import '../voice/dream_voice_permission.dart';

abstract class DreamVoiceInputPort {
  const DreamVoiceInputPort();

  /// Implementation exists. Device support is probed in [isSpeechAvailable].
  bool get isAvailable;

  Future<bool> isSpeechAvailable();

  Future<DreamVoicePermission> requestPermission();

  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(DreamVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  });

  Future<void> stopListening();

  Future<void> cancelListening();
}

class UnavailableDreamVoiceInput extends DreamVoiceInputPort {
  const UnavailableDreamVoiceInput();

  @override
  bool get isAvailable => false;

  @override
  Future<bool> isSpeechAvailable() async => false;

  @override
  Future<DreamVoicePermission> requestPermission() async =>
      DreamVoicePermission.unavailable;

  @override
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function(DreamVoiceFailure failure) onError,
    VoidCallback? onListeningEnded,
  }) async {
    onError(DreamVoiceFailure.speechUnavailable());
  }

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> cancelListening() async {}
}
