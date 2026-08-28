/// Production transport — Flutter → ORACLY proxy. Never sends OpenAI keys.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../ai_failure.dart';
import '../ai_outcome.dart';
import '../ai_runtime_config.dart';
import 'ai_error_mapper.dart';
import 'ai_operation.dart';
import 'ai_proxy_request.dart';
import 'ai_proxy_response_parser.dart';
import 'ai_transport.dart';
import 'proxy_ai_headers.dart';

class ProxyAiTransport implements AiTransport {
  ProxyAiTransport({
    required AiRuntimeConfig config,
    http.Client? client,
    Future<String?> Function()? accessToken,
    Future<String?> Function()? appCheckToken,
  })  : _config = config,
        _client = client ?? http.Client(),
        _accessToken = accessToken,
        _appCheckToken = appCheckToken;

  final AiRuntimeConfig _config;
  final http.Client _client;
  final Future<String?> Function()? _accessToken;
  final Future<String?> Function()? _appCheckToken;

  @override
  Future<AiOutcome<Map<String, dynamic>>> execute(
    AiProxyRequest request,
  ) async {
    final proxy = _config.resolvedProxyUrl;
    if (proxy == null || proxy.isEmpty) {
      return AiOutcome.failure(AiFailure.noConfiguration());
    }
    final headers = await ProxyAiHeaders.build(
      config: _config,
      request: request,
      accessToken: _accessToken,
      appCheckToken: _appCheckToken,
    );
    if (headers == null) {
      return AiOutcome.failure(AiFailure.unauthorized());
    }
    final started = DateTime.now();
    try {
      final response = await _client
          .post(
            Uri.parse(proxy),
            headers: headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(_config.timeout);
      _log(request.operation, response.statusCode, started, request);
      if (response.statusCode != 200) {
        return AiOutcome.failure(AiErrorMapper.fromStatus(response.statusCode));
      }
      final parsed = AiProxyResponseParser.parse(response.body);
      _logResult(request.operation, parsed);
      return parsed;
    } on TimeoutException {
      return _caught(request, 'timeout', AiFailure.timeout());
    } on SocketException {
      return _caught(request, 'network', AiFailure.network());
    } on http.ClientException {
      return _caught(request, 'network', AiFailure.network());
    } catch (_) {
      return _caught(request, 'providerError', AiFailure.providerError());
    }
  }

  AiOutcome<Map<String, dynamic>> _caught(
    AiProxyRequest request,
    String tag,
    AiFailure failure,
  ) {
    assert(() {
      debugPrint(
        '[ProxyAiTransport] op=${request.operation.wireName} '
        'resultReceived=no error=$tag',
      );
      return true;
    }());
    return AiOutcome.failure(failure);
  }

  void _log(
    AiOperation operation,
    int status,
    DateTime started,
    AiProxyRequest request,
  ) {
    if (!kDebugMode) return;
    assert(() {
      final ms = DateTime.now().difference(started).inMilliseconds;
      final image = request.payload['imageBase64'];
      final imagePresent = image is String && image.isNotEmpty;
      debugPrint(
        '[ProxyAiTransport] op=${operation.wireName} '
        'status=$status latencyMs=$ms imagePresent=$imagePresent',
      );
      return true;
    }());
  }

  void _logResult(
    AiOperation operation,
    AiOutcome<Map<String, dynamic>> outcome,
  ) {
    if (!kDebugMode) return;
    assert(() {
      outcome.when(
        success: (_) {},
        error: (failure) {
          debugPrint(
            '[ProxyAiTransport] op=${operation.wireName} '
            'resultReceived=no error=${failure.kind.name}',
          );
        },
      );
      return true;
    }());
  }
}
