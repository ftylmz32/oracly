/// DEV-only OpenAI voice map. Production mapping lives on the proxy.
library;

import '../../../../core/voice/or_speech_speed.dart';
import '../../../../core/voice/oracly_voice_id.dart';

class OpenAiTtsVoice {
  const OpenAiTtsVoice({
    required this.voice,
    required this.speed,
    required this.instructions,
    required this.hdVoice,
    required this.hdSpeed,
  });

  final String voice;
  final double speed;
  final String instructions;
  final String hdVoice;
  final double hdSpeed;
}

abstract final class OpenAiTtsVoices {
  OpenAiTtsVoices._();

  static const _or =
      'You are Or — one presence. Voice options change expression only, '
      'never character. Thinking aloud to a friend — not reading a document. '
      'Connect words. Turkish linking (ulama) is required. Never isolate '
      'syllables or give each word equal time. Function words are quick; '
      'a word that carries feeling gets a little weight, never a shout. '
      'A comma is a slight breath, not a stop. An ellipsis is one short '
      'think — never three stops — then you continue on the same thought. '
      'A greeting plus a question stays one phrase and rises at the end. '
      'Questions rise; nasılsın, ne yapardın, -mi / -mı / değil mi must '
      'not sound like statements. A period closes a thought, then you '
      'continue. Vary how sentences end: some land softly, some stay open. '
      'Never theatre. Never a metronome. Never the same falling cadence '
      'twice in a row. Never name punctuation. '
      'Do not sound like phone TTS, GPS, or IVR.';

  static OpenAiTtsVoice resolve({
    required String personality,
    required String language,
    String? voiceId,
    String? speechSpeed,
  }) {
    final id = OraclyVoiceId.parse(voiceId);
    final speed = OrSpeechSpeed.parse(speechSpeed);
    final timbre = _timbre(id);
    final lang = language.toLowerCase().startsWith('en')
        ? 'English'
        : language.toLowerCase().startsWith('ru')
            ? 'Russian'
            : 'Turkish';
    final line =
        'The text is $lang. Native conversation. Vowels stay $lang.';
    final delivery = _delivery(personality, id);
    final tempo = speed.applyProxy(delivery.$1);
    return OpenAiTtsVoice(
      voice: timbre.$1,
      hdVoice: timbre.$2,
      speed: tempo,
      hdSpeed: tempo,
      instructions: '$_or $line ${timbre.$3} ${delivery.$2}',
    );
  }

  static (String, String, String) _timbre(OraclyVoiceId id) {
    const original =
        'Original voice created for OR. Never imitate a celebrity, actor, '
        'or any real public person. Same OR — expression color only. ';
    return switch (id) {
      OraclyVoiceId.bright => (
          'marin',
          'sage',
          '${original}Brighter mid register, close and kind across a '
              'small table. Clear, never a child, never a whisper, '
              'never breathy theatre.',
        ),
      OraclyVoiceId.warm => (
          'coral',
          'coral',
          '${original}Warm mid presence in everyday conversation. '
              'Confident, clear, unforced. Not a presenter, not a '
              'call-center prompt.',
        ),
      OraclyVoiceId.deep => (
          'cedar',
          'echo',
          '${original}Deeper chest color, a friend in the room. '
              'Clear, unforced. Not a radio host, not theatrical bass.',
        ),
      OraclyVoiceId.calm => (
          'ash',
          'ash',
          '${original}Quieter pace, intimate and measured. Slightly '
              'lower. Never a meditation app, never broadcast news.',
        ),
    };
  }

  static (double, String) _delivery(String personality, OraclyVoiceId id) {
    final soft = id == OraclyVoiceId.calm || id == OraclyVoiceId.bright;
    return switch (personality.trim().toLowerCase()) {
      'gentle' || 'calm' => (
          soft ? 0.98 : 0.99,
          'Softer, unhurried, still conversational. One thought at a time.',
        ),
      'poetic' || 'warm' => (
          1.0,
          'Warmer chat rhythm, like thinking with a friend.',
        ),
      'direct' => (
          1.02,
          'Shorter thoughts, decisive. Still a person, not a prompt.',
        ),
      _ => (
          soft ? 0.99 : 1.0,
          'Quiet curiosity in the room. Never a mystic performance.',
        ),
    };
  }
}
