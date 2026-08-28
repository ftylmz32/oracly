/// HQ proxy first. Device TTS is an honest fallback, never a studio claim.
library;

import '../../features/premium/models/personalization_models.dart';
import '../feature_flags/feature_flag_rollback.dart';
import '../feature_flags/feature_flag_surface.dart';
import 'or_speech_prosody.dart';
import 'or_speech_speed.dart';
import 'oracly_device_tts.dart';
import 'oracly_proxy_speech.dart';
import 'oracly_speech_player.dart';
import 'oracly_tts_port.dart';
import 'oracly_voice_id.dart';
import 'oracly_voice_trace.dart';

part 'oracly_reply_tts_play.dart';

class OraclyReplyTts implements OraclyTtsPort {
  OraclyReplyTts({
    required this.proxy,
    required this.device,
    OraclySpeechSink? playback,
  }) : player = playback ?? OraclySpeechPlayer() {
    player.onComplete = _onPlaybackComplete;
    player.onInterrupted = _onPlaybackInterrupted;
  }

  final OraclyProxySpeech proxy;
  final OraclyTtsPort device;
  final OraclySpeechSink player;
  int _generation = 0;
  int _playGeneration = 0;
  bool _speaking = false;
  bool _lastFailed = false;

  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  @override
  bool get isSpeaking => _speaking;

  @override
  bool get lastSpeakFailed => _lastFailed;

  @override
  Future<bool> isAvailable() async =>
      proxy.isConfigured || await device.isAvailable();

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {
    final body = OrSpeechProsody.prepare(text);
    if (body.isEmpty) return;
    await stop();
    final id = ++_generation;
    _lastFailed = false;
    _setSpeaking(true);
    try {
      if (FeatureFlagRollback.useExperimental(FeatureFlagSurface.orVoice) &&
          proxy.isConfigured &&
          await _speakProxy(
            this,
            body,
            personality,
            languageCode,
            voice,
            speed,
            id,
          )) {
        return;
      }
      if (id != _generation) return;
      await _speakDevice(
        this,
        body,
        personality,
        languageCode,
        voice,
        speed,
        id,
      );
    } catch (_) {
      if (id == _generation) {
        _lastFailed = true;
        _setSpeaking(false);
      }
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    _lastFailed = false;
    _setSpeaking(false);
    await player.stop();
    await device.stop();
  }

  Future<void> pause() async {
    await player.pause();
    final engine = device;
    if (engine is OraclyDeviceTts) await engine.pausePlayback();
  }

  Future<void> resume() async {
    await player.resume();
    final engine = device;
    if (engine is OraclyDeviceTts) await engine.resumePlayback();
  }

  void _onPlaybackComplete() {
    if (_playGeneration != _generation) return;
    _setSpeaking(false);
  }

  void _onPlaybackInterrupted() {
    if (_playGeneration != _generation && !_speaking) return;
    _generation++;
    _setSpeaking(false);
  }

  void _setSpeaking(bool value) {
    if (_speaking == value) return;
    _speaking = value;
    onSpeakingChanged?.call(value);
  }

  Future<void> dispose() async {
    await stop();
    final sink = player;
    if (sink is OraclySpeechPlayer) await sink.dispose();
  }
}
