/// Device TTS via flutter_tts — Android/iOS system engines only.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../features/premium/models/personalization_models.dart';
import 'oracly_device_ssml.dart';
import 'oracly_device_tts_voices.dart';
import 'or_speech_speed.dart';
import 'oracly_tts_personality.dart';
import 'oracly_tts_port.dart';
import 'oracly_voice_id.dart';

class OraclyDeviceTts implements OraclyTtsPort {
  OraclyDeviceTts({FlutterTts? tts}) : _injected = tts;

  final FlutterTts? _injected;
  FlutterTts? _created;

  FlutterTts get _tts => _injected ?? (_created ??= FlutterTts());
  bool _ready = false;
  bool _engineOk = false;
  bool _speaking = false;
  bool _lastFailed = false;

  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  @override
  bool get isSpeaking => _speaking;

  @override
  bool get lastSpeakFailed => _lastFailed;

  void _setSpeaking(bool value) {
    _speaking = value;
    onSpeakingChanged?.call(value);
  }

  Future<void> initialize() async {
    if (_ready) return;
    try {
      _tts.setCompletionHandler(() => _setSpeaking(false));
      _tts.setCancelHandler(() => _setSpeaking(false));
      _tts.setErrorHandler((_) => _setSpeaking(false));
      await _tts.awaitSpeakCompletion(false);
      try {
        await _tts.setQueueMode(0);
      } catch (_) {}
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
      }
      await OraclyDeviceTtsVoices.prefer(_tts, 'tr');
      _engineOk = true;
      _ready = true;
    } catch (_) {
      _engineOk = false;
      _ready = true;
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (!_ready) await initialize();
    return _engineOk;
  }

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {
    final body = text.trim();
    if (body.isEmpty) return;
    _lastFailed = false;
    if (!await isAvailable()) {
      _lastFailed = true;
      return;
    }
    await stop();
    try {
      await OraclyDeviceTtsVoices.prefer(_tts, languageCode, voice);
      await _applyLocale(languageCode);
      final base =
          OraclyTtsPersonality.rate(personality) * voice.rateMul;
      await _tts.setSpeechRate(speed.applyDevice(base));
      await _tts.setPitch(
        (OraclyTtsPersonality.pitch(personality) * voice.pitchMul).clamp(
          0.5,
          2.0,
        ),
      );
      await _tts.setVolume(OraclyTtsPersonality.volume(personality));
      _setSpeaking(true);
      final spoken = OraclyDeviceSsml.maybeWrap(
        body,
        googleAndroid: OraclyDeviceTtsVoices.googleBound,
      );
      final result = await _tts.speak(spoken);
      if (result != 1) {
        _lastFailed = true;
        _setSpeaking(false);
      }
    } catch (_) {
      _lastFailed = true;
      _setSpeaking(false);
    }
  }

  @override
  Future<void> stop() async {
    _setSpeaking(false);
    if (!_ready) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> pausePlayback() async {
    if (!_ready || !_speaking) return;
    try {
      await _tts.pause();
    } catch (_) {}
  }

  /// Device engines rarely resume cleanly; HQ playback resumes via the player.
  Future<void> resumePlayback() async {}

  Future<void> _applyLocale(String languageCode) async {
    final preferred = OraclyDeviceTtsVoices.localeOf(languageCode);
    final short = preferred.split('-').first;
    for (final locale in [preferred, short]) {
      if (await _supports(locale)) {
        await _tts.setLanguage(locale);
        return;
      }
    }
    throw StateError('locale');
  }

  Future<bool> _supports(String locale) async {
    try {
      final value = await _tts.isLanguageAvailable(locale);
      return value is bool ? value : value is num && value == 1;
    } catch (_) {
      return false;
    }
  }
}
