/// OR reply speech port — HQ proxy first, device only as honest fallback.
library;

import '../../features/premium/models/personalization_models.dart';
import 'or_speech_speed.dart';
import 'oracly_voice_id.dart';

abstract class OraclyTtsPort {
  void Function(bool isSpeaking)? onSpeakingChanged;

  Future<bool> isAvailable();

  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  });

  Future<void> stop();

  bool get isSpeaking;

  bool get lastSpeakFailed;
}
