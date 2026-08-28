/// DEV-only direct OpenAI HTTP — never used when proxy mode is active.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../ai_failure.dart';
import '../ai_outcome.dart';
import '../ai_runtime_config.dart';
import 'openai_status_mapper.dart';
import 'openai_speech_http.dart';

class OpenAiTransport {
  OpenAiTransport({required this._config, http.Client? client})
    : _client = client ?? http.Client();

  final AiRuntimeConfig _config;
  final http.Client _client;

  Future<AiOutcome<String>> complete({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.6,
  }) async {
    if (!_config.usesClientKey) {
      return AiOutcome.failure(AiFailure.noConfiguration());
    }
    final started = DateTime.now();
    try {
      final response = await _client
          .post(
            Uri.parse(AiRuntimeConfig.openAiChatUrl),
            headers: _headers(),
            body: jsonEncode({
              'model': _config.model,
              'temperature': temperature,
              'messages': messages,
            }),
          )
          .timeout(_config.timeout);
      _logStatus(response.statusCode, started);
      if (response.statusCode != 200) {
        return AiOutcome.failure(
          OpenAiStatusMapper.fromStatus(response.statusCode),
        );
      }
      final text = _parseContent(response.body);
      if (text.trim().isEmpty) {
        return AiOutcome.failure(AiFailure.invalidResponse());
      }
      return AiOutcome.success(text.trim());
    } on TimeoutException {
      return AiOutcome.failure(AiFailure.timeout());
    } on SocketException {
      return AiOutcome.failure(AiFailure.network());
    } on http.ClientException {
      return AiOutcome.failure(AiFailure.network());
    } on FormatException {
      return AiOutcome.failure(AiFailure.invalidResponse());
    } catch (_) {
      return AiOutcome.failure(AiFailure.providerError());
    }
  }

  Future<AiOutcome<Map<String, dynamic>>> speech({
    required String text,
    required String personality,
    String language = 'tr',
    String? voiceId,
    String? speechSpeed,
  }) {
    return OpenAiSpeechHttp.post(
      config: _config,
      client: _client,
      text: text,
      personality: personality,
      language: language,
      voiceId: voiceId,
      speechSpeed: speechSpeed,
    );
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_config.usesClientKey) {
      headers['Authorization'] = 'Bearer ${_config.openAiKey!.trim()}';
    }
    return headers;
  }

  void _logStatus(int status, DateTime started) {
    if (!kDebugMode) return;
    assert(() {
      final ms = DateTime.now().difference(started).inMilliseconds;
      debugPrint(
        '[DirectOpenAi] status=$status model=${_config.model} latencyMs=$ms',
      );
      return true;
    }());
  }

  static String _parseContent(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return '';
    final data = Map<String, dynamic>.from(decoded);
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) return '';
    final choice = choices.first;
    if (choice is! Map) return '';
    final message = Map<String, dynamic>.from(choice)['message'];
    if (message is! Map) return '';
    return Map<String, dynamic>.from(message)['content'] as String? ?? '';
  }
}
