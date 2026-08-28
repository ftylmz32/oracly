/// Global gate for OR reply TTS — Settings identity + personality delivery.
library;

import 'package:flutter/foundation.dart';

import '../../features/premium/models/personalization_models.dart';
import 'oracly_reply_tts.dart';
import 'oracly_tts_port.dart';
import 'or_speech_speed.dart';
import 'oracly_voice_id.dart';

abstract final class OraclyTtsGate {
  OraclyTtsGate._();

  static OraclyTtsPort? engine;
  static bool voiceRepliesEnabled = false;
  static AiPersonality personality = AiPersonality.mystical;
  static OraclyVoiceId voice = OraclyVoiceId.warm;
  static OrSpeechSpeed speechSpeed = OrSpeechSpeed.normal;
  static String languageCode = 'tr';
  static final ValueNotifier<bool> speaking = ValueNotifier(false);
  static final ValueNotifier<bool> paused = ValueNotifier(false);
  static final ValueNotifier<bool> unavailable = ValueNotifier(false);
  static int _interruptGen = 0;

  static int get interruptGeneration => _interruptGen;

  static void bind({
    required OraclyTtsPort service,
    required bool enabled,
    required AiPersonality style,
    required String language,
    OraclyVoiceId? identity,
    OrSpeechSpeed? speed,
  }) {
    engine = service;
    voiceRepliesEnabled = enabled;
    personality = style;
    languageCode = language;
    if (identity != null) voice = identity;
    if (speed != null) speechSpeed = speed;
    service.onSpeakingChanged = (value) {
      if (speaking.value != value) speaking.value = value;
      if (!value) paused.value = false;
    };
    if (!enabled) {
      speaking.value = false;
      paused.value = false;
    }
  }

  static Future<void> speakReply(String? text) async {
    if (!voiceRepliesEnabled) return;
    await _speakNow(text);
  }

  /// Chat TTS — only when SESLİ / voice replies are enabled.
  static Future<void> speakChat(String? text) async {
    if (!voiceRepliesEnabled) return;
    await _speakNow(text);
  }

  /// Real generated preview. Independent from SESLİ / YAZILI.
  static Future<void> preview(String? text, {required OraclyVoiceId identity}) =>
      _speakNow(text, identity: identity);

  static Future<void> _speakNow(String? text, {OraclyVoiceId? identity}) async {
    final body = text?.trim() ?? '';
    if (body.isEmpty) return;
    final gen = _interruptGen;
    unavailable.value = false;
    paused.value = false;
    final tts = engine;
    if (tts == null) {
      unavailable.value = true;
      return;
    }
    await tts.stop();
    if (gen != _interruptGen) return;
    if (!await tts.isAvailable()) {
      unavailable.value = true;
      speaking.value = false;
      return;
    }
    try {
      await tts.speak(
        body,
        personality: personality,
        languageCode: languageCode,
        voice: identity ?? voice,
        speed: speechSpeed,
      );
      if (gen != _interruptGen) {
        await tts.stop();
        speaking.value = false;
        paused.value = false;
        return;
      }
      speaking.value = tts.isSpeaking;
      if (tts.lastSpeakFailed) unavailable.value = true;
    } catch (_) {
      unavailable.value = true;
      speaking.value = false;
    }
  }

  static Future<void> stop() async {
    await engine?.stop();
    speaking.value = false;
    paused.value = false;
  }

  /// Hard cut — phone call, focus loss, barge-in, background. Never resumes.
  static Future<void> interrupt() async {
    _interruptGen++;
    await stop();
  }

  static Future<void> pause() async {
    if (!speaking.value || paused.value) return;
    final tts = engine;
    if (tts is OraclyReplyTts) await tts.pause();
    paused.value = true;
  }

  static Future<void> resume() async {
    if (!paused.value) return;
    final tts = engine;
    if (tts is OraclyReplyTts) await tts.resume();
    paused.value = false;
  }
}
