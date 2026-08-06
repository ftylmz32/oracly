/// OR-1130 — HTTP client abstraction with interceptors.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../logging/logger.dart';
import 'api_interceptor.dart';
import 'api_result.dart';
import 'network_exception.dart';
import 'retry_interceptor.dart';

typedef HttpClientFactory = http.Client Function();

class ApiClient {
  ApiClient({
    http.Client? client,
    List<ApiInterceptor>? interceptors,
    RetryInterceptor? retryInterceptor,
    this.timeout = const Duration(seconds: 30),
    Logger? logger,
  })  : _client = client ?? http.Client(),
        _interceptors = interceptors ?? const [],
        _retryInterceptor = retryInterceptor ?? RetryInterceptor(),
        _logger = logger ?? Logger('ApiClient');

  final http.Client _client;
  final List<ApiInterceptor> _interceptors;
  final RetryInterceptor _retryInterceptor;
  final Duration timeout;
  final Logger _logger;

  Future<ApiResult<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    T Function(dynamic json)? parser,
  }) {
    return _send(
      method: 'GET',
      url: url,
      headers: headers,
      parser: parser,
    );
  }

  Future<ApiResult<T>> post<T>(
    String url, {
    Map<String, String>? headers,
    Object? body,
    T Function(dynamic json)? parser,
  }) {
    return _send(
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
      parser: parser,
    );
  }

  Future<ApiResult<T>> put<T>(
    String url, {
    Map<String, String>? headers,
    Object? body,
    T Function(dynamic json)? parser,
  }) {
    return _send(
      method: 'PUT',
      url: url,
      headers: headers,
      body: body,
      parser: parser,
    );
  }

  Future<ApiResult<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    T Function(dynamic json)? parser,
  }) {
    return _send(
      method: 'DELETE',
      url: url,
      headers: headers,
      parser: parser,
    );
  }

  Future<ApiResult<T>> _send<T>({
    required String method,
    required String url,
    Map<String, String>? headers,
    Object? body,
    T Function(dynamic json)? parser,
  }) async {
    var attempt = 0;

    while (true) {
      try {
        var requestHeaders = <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (AppConfig.isInitialized)
            'X-App-Environment': AppConfig.instance.environment.name,
          ...?headers,
        };

        for (final interceptor in _interceptors) {
          requestHeaders = await interceptor.onRequest(requestHeaders);
        }

        _logger.debug('$method $url (attempt ${attempt + 1})');

        final uri = Uri.parse(url);
        final encodedBody = body == null
            ? null
            : body is String
                ? body
                : jsonEncode(body);

        final response = await _dispatch(
          method,
          uri,
          requestHeaders,
          encodedBody,
        ).timeout(timeout);

        for (final interceptor in _interceptors) {
          await interceptor.onResponse(
            response.statusCode,
            response.headers,
          );
        }

        if (response.statusCode >= 200 && response.statusCode < 300) {
          _retryInterceptor.reset();
          final parsed = _parseBody<T>(response.body, parser);
          if (parser != null &&
              parsed == null &&
              response.body.isNotEmpty) {
            return ApiFailure(
              NetworkException(
                message: 'Yanıt ayrıştırılamadı.',
                kind: NetworkErrorKind.parse,
              ),
            );
          }
          return ApiSuccess(parsed as T);
        }

        final error = NetworkException.fromStatusCode(
          response.statusCode,
          response.body.isNotEmpty ? response.body : null,
        );

        if (_retryInterceptor.shouldRetry(error) &&
            attempt < _retryInterceptor.maxAttempts - 1) {
          attempt++;
          _retryInterceptor.incrementAttempt();
          await Future<void>.delayed(_retryInterceptor.delayForAttempt(attempt));
          continue;
        }

        return ApiFailure(error);
      } on TimeoutException {
        final error = NetworkException.timeout();
        if (_retryInterceptor.shouldRetry(error) &&
            attempt < _retryInterceptor.maxAttempts - 1) {
          attempt++;
          await Future<void>.delayed(_retryInterceptor.delayForAttempt(attempt));
          continue;
        }
        return ApiFailure(error);
      } on NetworkException catch (e) {
        for (final interceptor in _interceptors) {
          await interceptor.onError(e);
        }
        return ApiFailure(e);
      } catch (e) {
        for (final interceptor in _interceptors) {
          await interceptor.onError(e);
        }
        return ApiFailure(
          NetworkException(message: e.toString(), cause: e),
        );
      }
    }
  }

  Future<http.Response> _dispatch(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    return switch (method) {
      'GET' => _client.get(uri, headers: headers),
      'POST' => _client.post(uri, headers: headers, body: body),
      'PUT' => _client.put(uri, headers: headers, body: body),
      'DELETE' => _client.delete(uri, headers: headers),
      _ => throw NetworkException(message: 'Unsupported method: $method'),
    };
  }

  T? _parseBody<T>(String body, T Function(dynamic json)? parser) {
    if (body.isEmpty) return null;
    if (parser != null) {
      final decoded = jsonDecode(body);
      return parser(decoded);
    }
    if (T == String) return body as T;
    return jsonDecode(body) as T;
  }

  void dispose() => _client.close();
}
