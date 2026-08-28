part of 'oracly_reply_tts.dart';

Future<bool> _speakProxy(
  OraclyReplyTts tts,
  String body,
  AiPersonality personality,
  String languageCode,
  OraclyVoiceId voice,
  OrSpeechSpeed speed,
  int id,
) async {
  final started = DateTime.now();
  final clip = await tts.proxy.synthesize(
    text: body.length <= 1200 ? body : body.substring(0, 1200),
    personality: personality,
    languageCode: languageCode,
    voice: voice,
    speed: speed,
  );
  final ttsMs = DateTime.now().difference(started).inMilliseconds;
  if (id != tts._generation) return true;
  if (clip == null) return false;
  tts._playGeneration = id;
  try {
    final playAt = DateTime.now();
    await tts.player.play(clip.bytes, mimeType: clip.mimeType);
    logOrVoice(
      path: 'proxy',
      bytes: clip.bytes.length,
      ttsMs: ttsMs,
      firstAudioMs: DateTime.now().difference(playAt).inMilliseconds,
      failed: false,
    );
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> _speakDevice(
  OraclyReplyTts tts,
  String body,
  AiPersonality personality,
  String languageCode,
  OraclyVoiceId voice,
  OrSpeechSpeed speed,
  int id,
) async {
  if (!await tts.device.isAvailable()) {
    tts._lastFailed = true;
    tts._setSpeaking(false);
    return;
  }
  tts._lastFailed = tts.proxy.isConfigured;
  await tts.device.speak(
    body,
    personality: personality,
    languageCode: languageCode,
    voice: voice,
    speed: speed,
  );
  if (id != tts._generation) return;
  logOrVoice(
    path: 'device',
    bytes: 0,
    ttsMs: 0,
    firstAudioMs: 0,
    failed: tts._lastFailed,
  );
  if (tts.device.lastSpeakFailed) tts._lastFailed = true;
  tts._setSpeaking(tts.device.isSpeaking);
}
