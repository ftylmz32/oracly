/// OR-1130 — Network layer exceptions.
library;

import '../copy/resilience_copy.dart';

enum NetworkErrorKind {
  timeout,
  noConnection,
  unauthorized,
  forbidden,
  notFound,
  server,
  parse,
  cancelled,
  unknown,
}

class NetworkException implements Exception {
  const NetworkException({
    required this.message,
    this.kind = NetworkErrorKind.unknown,
    this.statusCode,
    this.cause,
  });

  final String message;
  final NetworkErrorKind kind;
  final int? statusCode;
  final Object? cause;

  factory NetworkException.timeout([String? message]) => NetworkException(
        message: message ?? ResilienceCopy.slowResponse,
        kind: NetworkErrorKind.timeout,
      );

  factory NetworkException.noConnection([String? message]) => NetworkException(
        message: message ?? ResilienceCopy.offline,
        kind: NetworkErrorKind.noConnection,
      );

  factory NetworkException.unauthorized([String? message]) => NetworkException(
        message: message ?? ResilienceCopy.aiConfigMissing,
        kind: NetworkErrorKind.unauthorized,
        statusCode: 401,
      );

  factory NetworkException.fromStatusCode(int code, [String? message]) {
    final kind = switch (code) {
      401 => NetworkErrorKind.unauthorized,
      403 => NetworkErrorKind.forbidden,
      404 => NetworkErrorKind.notFound,
      >= 500 => NetworkErrorKind.server,
      _ => NetworkErrorKind.unknown,
    };
    final fallback = switch (kind) {
      NetworkErrorKind.unauthorized ||
      NetworkErrorKind.forbidden =>
        ResilienceCopy.aiConfigMissing,
      NetworkErrorKind.server => ResilienceCopy.aiUnavailable,
      NetworkErrorKind.notFound => ResilienceCopy.genericLoadFailed,
      _ => ResilienceCopy.temporaryFailure,
    };
    return NetworkException(
      message: message ?? fallback,
      kind: kind,
      statusCode: code,
    );
  }

  @override
  String toString() => 'NetworkException($kind, $statusCode): $message';
}
