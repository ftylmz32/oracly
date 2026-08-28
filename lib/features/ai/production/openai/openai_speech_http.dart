/// DEV-only OpenAI /audio/speech — never used when proxy mode is active.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../ai_failure.dart';
import '../ai_outcome.dart';
import '../ai_runtime_config.dart';
import 'openai_status_mapper.dart';
import 'openai_tts_voices.dart';

abstract final class OpenAiSpeechHttp {
  OpenAiSpeechHttp._();

  static const url = 'https://api.openai.com/v1/audio/speech';

  static Future<AiOutcome<Map<String, dynamic>>> post({
    required AiRuntimeConfig config,
    required http.Client client,
    required String text,
    required String personality,
    String language = 'tr',
    String? voiceId,
    String? speechSpeed,
  }) async {
    if (!config.usesClientKey) {
      return AiOutcome.failure(AiFailure.noConfiguration());
    }
    final body = text.trim();
    if (body.isEmpty) {
      return AiOutcome.failure(AiFailure.invalidResponse());
    }
    final voice = OpenAiTtsVoices.resolve(
      personality: personality,
      language: language,
      voiceId: voiceId,
      speechSpeed: speechSpeed,
    );
    final primary = await _once(
      config: config,
      client: client,
      model: 'gpt-4o-mini-tts-2025-12-15',
      voice: voice.voice,
      speed: voice.speed,
      input: body,
      instructions: voice.instructions,
    );
    if (primary != null) return primary;
    final secondary = await _once(
      config: config,
      client: client,
      model: 'gpt-4o-mini-tts',
      voice: voice.voice,
      speed: voice.speed,
      input: body,
      instructions: voice.instructions,
    );
    if (secondary != null) return secondary;
    final fallback = await _once(
      config: config,
      client: client,
      model: 'tts-1-hd',
      voice: voice.hdVoice,
      speed: voice.hdSpeed,
      input: body,
    );
    return fallback ?? AiOutcome.failure(AiFailure.providerError());
  }

  static Future<AiOutcome<Map<String, dynamic>>?> _once({
    required AiRuntimeConfig config,
    required http.Client client,
    required String model,
    required String voice,
    required double speed,
    required String input,
    String? instructions,
  }) async {
    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${config.openAiKey!.trim()}',
            },
            body: jsonEncode({
              'model': model,
              'voice': voice,
              'input': input,
              'speed': speed,
              'response_format': 'mp3',
              'instructions': ?instructions,
            }),
          )
          .timeout(config.timeout);
      if (response.statusCode == 400) return null;
      if (response.statusCode != 200) {
        return AiOutcome.failure(
          OpenAiStatusMapper.fromStatus(response.statusCode),
        );
      }
      final bytes = response.bodyBytes;
      if (bytes.length < 32) {
        return AiOutcome.failure(AiFailure.invalidResponse());
      }
      return AiOutcome.success({
        'audioBase64': base64Encode(bytes),
        'mimeType': 'audio/mpeg',
        'operation': 'tts',
      });
    } on TimeoutException {
      return AiOutcome.failure(AiFailure.timeout());
    } on SocketException {
      return AiOutcome.failure(AiFailure.network());
    } on http.ClientException {
      return AiOutcome.failure(AiFailure.network());
    } catch (_) {
      return AiOutcome.failure(AiFailure.providerError());
    }
  }
}
