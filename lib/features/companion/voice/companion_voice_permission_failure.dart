/// Map mic permission outcomes to honest OR voice failures.
library;

import 'companion_voice_failure.dart';
import 'companion_voice_permission.dart';

CompanionVoiceFailure companionVoicePermissionFailure(
  CompanionVoicePermission permission,
) {
  return switch (permission) {
    CompanionVoicePermission.denied =>
      CompanionVoiceFailure.permissionDenied(),
    CompanionVoicePermission.permanentlyDenied =>
      CompanionVoiceFailure.permissionPermanentlyDenied(),
    CompanionVoicePermission.unavailable =>
      CompanionVoiceFailure.microphoneUnavailable(),
    CompanionVoicePermission.granted =>
      CompanionVoiceFailure.speechUnavailable(),
  };
}
