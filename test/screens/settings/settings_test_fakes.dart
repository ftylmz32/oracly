/// Silent audio fakes so Settings widget tests stay quiet.
library;

import 'package:oracly_new/core/audio/oracly_sound_service.dart';
import 'package:oracly_new/core/voice/oracly_tts_port.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/birth_chart/models/zodiac_sign_id.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

class SilentSound extends OraclySoundService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> ensureSfxReady() async {}

  @override
  Future<void> syncAmbientEnabled(bool enabled) async {}

  @override
  Future<void> setAtmosphere(ZodiacSignId sign) async {}
}

class SilentTts implements OraclyTtsPort {
  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  @override
  bool get isSpeaking => false;

  @override
  bool get lastSpeakFailed => false;

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {}

  @override
  Future<void> stop() async {}
}

class RecordingTts implements OraclyTtsPort {
  final spoken = <String>[];
  final voices = <OraclyVoiceId>[];
  final styles = <AiPersonality>[];

  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  @override
  bool get isSpeaking => false;

  @override
  bool get lastSpeakFailed => false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {
    spoken.add(text);
    voices.add(voice);
    styles.add(personality);
  }

  @override
  Future<void> stop() async {}
}
