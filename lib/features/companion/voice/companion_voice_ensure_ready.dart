/// Probe speech + mic before a one-shot OR capture.
library;

import '../services/companion_voice_input_port.dart';
import 'companion_voice_failure.dart';
import 'companion_voice_permission.dart';
import 'companion_voice_permission_failure.dart';

Future<CompanionVoiceFailure?> companionVoiceEnsureReady(
  CompanionVoiceInputPort port,
) async {
  if (!await port.isSpeechAvailable()) {
    return CompanionVoiceFailure.speechUnavailable();
  }
  final permission = await port.requestPermission();
  if (permission != CompanionVoicePermission.granted) {
    return companionVoicePermissionFailure(permission);
  }
  return null;
}
