/// Typed voice failures — Turkish copy, never a fake transcript.
library;

import '../../../core/copy/resilience_copy.dart';
import '../copy/dream_copy.dart';

enum DreamVoiceFailureKind {
  permissionDenied,
  permissionPermanentlyDenied,
  microphoneUnavailable,
  speechUnavailable,
  speechError,
  emptyTranscription,
  network,
  timeout,
}

class DreamVoiceFailure implements Exception {
  const DreamVoiceFailure(this.kind, this.userMessage);

  final DreamVoiceFailureKind kind;
  final String userMessage;

  factory DreamVoiceFailure.permissionDenied() => DreamVoiceFailure(
        DreamVoiceFailureKind.permissionDenied,
        DreamCopy.voicePermissionDenied,
      );

  factory DreamVoiceFailure.permissionPermanentlyDenied() =>
      DreamVoiceFailure(
        DreamVoiceFailureKind.permissionPermanentlyDenied,
        DreamCopy.voicePermissionPermanent,
      );

  factory DreamVoiceFailure.microphoneUnavailable() => DreamVoiceFailure(
        DreamVoiceFailureKind.microphoneUnavailable,
        DreamCopy.voiceMicUnavailable,
      );

  factory DreamVoiceFailure.speechUnavailable() => DreamVoiceFailure(
        DreamVoiceFailureKind.speechUnavailable,
        DreamCopy.voiceSpeechUnavailable,
      );

  factory DreamVoiceFailure.speechError() => DreamVoiceFailure(
        DreamVoiceFailureKind.speechError,
        DreamCopy.voiceSpeechError,
      );

  factory DreamVoiceFailure.emptyTranscription() => DreamVoiceFailure(
        DreamVoiceFailureKind.emptyTranscription,
        DreamCopy.voiceEmpty,
      );

  factory DreamVoiceFailure.network() => DreamVoiceFailure(
        DreamVoiceFailureKind.network,
        ResilienceCopy.offline,
      );

  factory DreamVoiceFailure.timeout() => DreamVoiceFailure(
        DreamVoiceFailureKind.timeout,
        ResilienceCopy.slowResponse,
      );

  @override
  String toString() => 'DreamVoiceFailure($kind)';
}
