/// Typed voice failures — Turkish copy, never a fake transcript.
library;

import '../../../core/copy/resilience_copy.dart';
import '../copy/companion_copy.dart';

enum CompanionVoiceFailureKind {
  permissionDenied,
  permissionPermanentlyDenied,
  microphoneUnavailable,
  speechUnavailable,
  speechError,
  emptyTranscription,
  network,
  timeout,
}

class CompanionVoiceFailure implements Exception {
  CompanionVoiceFailure(this.kind, this.userMessage);

  final CompanionVoiceFailureKind kind;
  final String userMessage;

  factory CompanionVoiceFailure.permissionDenied() =>
      CompanionVoiceFailure(
        CompanionVoiceFailureKind.permissionDenied,
        CompanionCopy.voicePermissionDenied,
      );

  factory CompanionVoiceFailure.permissionPermanentlyDenied() =>
      CompanionVoiceFailure(
        CompanionVoiceFailureKind.permissionPermanentlyDenied,
        CompanionCopy.voicePermissionPermanent,
      );

  factory CompanionVoiceFailure.microphoneUnavailable() =>
      CompanionVoiceFailure(
        CompanionVoiceFailureKind.microphoneUnavailable,
        CompanionCopy.voiceMicUnavailable,
      );

  factory CompanionVoiceFailure.speechUnavailable() =>
      CompanionVoiceFailure(
        CompanionVoiceFailureKind.speechUnavailable,
        CompanionCopy.voiceSpeechUnavailable,
      );

  factory CompanionVoiceFailure.speechError() => CompanionVoiceFailure(
        CompanionVoiceFailureKind.speechError,
        CompanionCopy.voiceSpeechError,
      );

  factory CompanionVoiceFailure.emptyTranscription() =>
      CompanionVoiceFailure(
        CompanionVoiceFailureKind.emptyTranscription,
        CompanionCopy.voiceEmpty,
      );

  factory CompanionVoiceFailure.network() => CompanionVoiceFailure(
        CompanionVoiceFailureKind.network,
        ResilienceCopy.offline,
      );

  factory CompanionVoiceFailure.timeout() => CompanionVoiceFailure(
        CompanionVoiceFailureKind.timeout,
        ResilienceCopy.slowResponse,
      );

  @override
  String toString() => 'CompanionVoiceFailure($kind)';
}
