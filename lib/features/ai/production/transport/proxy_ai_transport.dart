/// Production transport — Flutter → ORACLY proxy. Never sends OpenAI keys.
library;

// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/auth/auth_service.dart';
import '../../../../core/auth/firebase/firebase_auth_gateway.dart';
import '../ai_failure.dart';
import '../ai_outcome.dart';
import '../ai_proxy_readiness.dart';
import '../ai_runtime_config.dart';
import 'ai_error_mapper.dart';
import 'ai_operation.dart';
import 'ai_proxy_request.dart';
import 'ai_proxy_response_parser.dart';
import 'ai_transport.dart';
import 'ai_token_reader.dart';
import 'proxy_ai_headers.dart';
import 'proxy_ai_transport_log.dart';

class ProxyAiTransport implements AiTransport {
  ProxyAiTransport({
    required AiRuntimeConfig config,
    AuthService? auth,
    AiTokenReader? accessToken,
    AiTokenReader? appCheckToken,
    FirebaseAuthGateway? liveGateway,
    http.Client? client,
  })  : _config = config,
        _auth = auth,
        _client = client ?? http.Client(),
        _accessToken = accessToken,
        _appCheckToken = appCheckToken,
        _liveGateway = liveGateway;

  final AiRuntimeConfig _config;
  final AuthService? _auth;
  final http.Client _client;
  final AiTokenReader? _accessToken;
  final AiTokenReader? _appCheckToken;
  final FirebaseAuthGateway? _liveGateway;

  @override
  Future<AiOutcome<Map<String, dynamic>>> execute(
    AiProxyRequest request,
  ) async {
    final proxy = _config.resolvedProxyUrl;
    if (proxy == null || proxy.isEmpty) {
      return AiOutcome.failure(AiFailure.noConfiguration());
    }
    final blocked = await AiProxyReadiness.ensure(
      config: _config,
      auth: _auth,
      accessToken: _accessToken,
      appCheckToken: _appCheckToken,
      liveGateway: _liveGateway,
    );
    if (blocked != null) {
      ProxyAiTransportLog.preflight(request.operation, blocked.kind.name);
      return AiOutcome.failure(blocked);
    }
    final headers = await ProxyAiHeaders.build(
      config: _config,
      request: request,
      accessToken: _accessToken,
      appCheckToken: _appCheckToken,
      liveGateway: _liveGateway,
    );
    if (headers == null) {
      ProxyAiTransportLog.preflight(request.operation, 'appCheck');
      return AiOutcome.failure(AiFailure.appCheck());
    }
    final started = DateTime.now();
    try {
      ProxyAiTransportLog.send(
        operation: request.operation,
        headers: headers,
        endpoint: proxy,
      );
      final response = await _client
          .post(
            Uri.parse(proxy),
            headers: headers,
            body: jsonEncode(request.toJson()),
          )
          .timeout(
            request.operation == AiOperation.soulmateDraw
                ? _config.imageTimeout
                : _config.timeout,
          );
      final image = request.payload['imageBase64'];
      if (response.statusCode != 200) {
        final failure = _failureFromHttpResponse(response);
        ProxyAiTransportLog.httpStatus(
          operation: request.operation,
          status: response.statusCode,
          started: started,
          imagePresent: image is String && image.isNotEmpty,
          errorCode: _errorCodeFromBody(response.body),
          responseBody: response.body,
        );
        ProxyAiTransportLog.resultError(
          operation: request.operation,
          kind: failure.kind.name,
          errorCode: _errorCodeFromBody(response.body),
        );
        return AiOutcome.failure(failure);
      }
      ProxyAiTransportLog.httpStatus(
        operation: request.operation,
        status: response.statusCode,
        started: started,
        imagePresent: image is String && image.isNotEmpty,
      );
      final parsed = AiProxyResponseParser.parse(response.body);
      parsed.when(
        success: (_) {},
        error: (failure) {
          ProxyAiTransportLog.resultError(
            operation: request.operation,
            kind: failure.kind.name,
            errorCode: _errorCodeFromBody(response.body),
          );
          ProxyAiTransportLog.parseError(
            operation: request.operation,
            reason: 'envelope_error kind=${failure.kind.name}',
            responseBody: response.body,
          );
        },
      );
      return parsed;
    } on TimeoutException {
      return _caught(request, 'timeout', AiFailure.timeout());
    } on SocketException {
      return _caught(request, 'network', AiFailure.network());
    } on http.ClientException {
      return _caught(request, 'network', AiFailure.network());
    } on FormatException catch (error, stackTrace) {
      ProxyAiTransportLog.parseError(
        operation: request.operation,
        reason: 'invalid_json exception=${error.runtimeType}',
      );
      ProxyAiTransportLog.caught(
        request.operation,
        'invalid_json',
        error: error,
        stackTrace: stackTrace,
      );
      return AiOutcome.failure(AiFailure.invalidResponse());
    } catch (error, stackTrace) {
      return _caught(
        request,
        'providerError',
        AiFailure.providerError(),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static AiFailure _failureFromHttpResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      final envelope = AiProxyResponseParser.asStringMap(decoded);
      if (envelope != null && envelope['success'] == false) {
        final error = AiProxyResponseParser.asStringMap(envelope['error']);
        return AiErrorMapper.fromCode(error?['code'] as String?);
      }
    } catch (_) {}
    return AiErrorMapper.fromStatus(response.statusCode);
  }

  static String? _errorCodeFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      final envelope = AiProxyResponseParser.asStringMap(decoded);
      if (envelope == null || envelope['success'] != false) return null;
      final error = AiProxyResponseParser.asStringMap(envelope['error']);
      final code = error?['code'];
      return code is String && code.isNotEmpty ? code : null;
    } catch (_) {
      return null;
    }
  }

  AiOutcome<Map<String, dynamic>> _caught(
    AiProxyRequest request,
    String tag,
    AiFailure failure, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    ProxyAiTransportLog.caught(
      request.operation,
      tag,
      error: error,
      stackTrace: stackTrace,
    );
    return AiOutcome.failure(failure);
  }
}
