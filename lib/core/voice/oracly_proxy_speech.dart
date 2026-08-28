/// Fetch OR speech audio via the existing AI transport (proxy in production).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../features/ai/production/ai_request_abuse_policy.dart';
import '../../features/ai/production/ai_request_fingerprint.dart';
import '../../features/ai/production/ai_request_guard.dart';
import '../../features/ai/production/openai/openai_tts_request.dart';
import '../../features/ai/production/transport/ai_transport.dart';
import '../../features/premium/models/personalization_models.dart';
import '../personality/or_personality.dart';
import 'or_speech_prosody.dart';
import 'or_speech_speed.dart';
import 'oracly_speech_cache.dart';
import 'oracly_voice_id.dart';

final _cache = OraclySpeechCache();

class OraclySpeechClip {
  const OraclySpeechClip({required this.bytes, required this.mimeType});

  final List<int> bytes;
  final String mimeType;
}

class OraclyProxySpeech {
  OraclyProxySpeech(this._transport, {AiRequestGuard? guard})
      : _guard = guard ?? AiRequestGuard.shared;

  final AiTransport? _transport;
  final AiRequestGuard _guard;

  bool get isConfigured => _transport != null;

  @visibleForTesting
  static void resetCache() => _cache.clear();

  /// Drop in-memory TTS clips when leaving OR.
  static void releaseCaches() => _cache.clear();

  Future<OraclySpeechClip?> synthesize({
    required String text,
    required AiPersonality personality,
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
    String languageCode = 'tr',
  }) async {
    final transport = _transport;
    if (transport == null) return null;
    final body = OrSpeechProsody.prepare(text);
    if (body.isEmpty) return null;
    final key =
        '${voice.wire}|${personality.name}|${speed.wire}|$languageCode|$body';
    final hit = _cache.take(key);
    if (hit != null) return hit;
    final fp = AiRequestFingerprint.text('tts', key);
    return _guard.run(
      'tts',
      kind: AiRequestKind.tts,
      fingerprint: fp,
      limited: () => null,
      succeeded: (clip) => clip != null,
      () async {
        final outcome = await transport.execute(
          OpenAiTtsRequest.create(
            text: body,
            personality: OrPersonality.chatKey(personality),
            language: languageCode,
            voiceId: voice.wire,
            speechSpeed: speed.wire,
          ),
        );
        final clip = outcome.when(success: _clip, error: (_) => null);
        if (clip != null) _cache.put(key, clip);
        return clip;
      },
    );
  }

  static OraclySpeechClip? _clip(Map<String, dynamic> data) {
    final raw = data['audioBase64']?.toString() ?? '';
    if (raw.length < 32) return null;
    try {
      final bytes = base64Decode(raw);
      if (bytes.length < 32) return null;
      final mime = data['mimeType']?.toString().trim();
      return OraclySpeechClip(
        bytes: bytes,
        mimeType: (mime == null || mime.isEmpty) ? 'audio/mpeg' : mime,
      );
    } catch (_) {
      return null;
    }
  }
}
