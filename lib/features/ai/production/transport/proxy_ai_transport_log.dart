/// Debug-only proxy transport logs. Never prints tokens or payloads.
library;

import 'package:flutter/foundation.dart';

import 'ai_operation.dart';
import 'proxy_ai_headers.dart';
import 'proxy_ai_response_sanitize.dart';

abstract final class ProxyAiTransportLog {
  ProxyAiTransportLog._();

  static void config({
    required bool configured,
    required bool usesProxy,
    required String? endpoint,
    required bool visionAvailable,
  }) {
    if (!kDebugMode) return;
    assert(() {
      debugPrint(
        '[ProxyAiTransport] configured=$configured usesProxy=$usesProxy '
        'vision=$visionAvailable endpoint=${endpoint ?? 'none'}',
      );
      return true;
    }());
  }

  static void preflight(AiOperation operation, String reason) {
    if (!kDebugMode) return;
    assert(() {
      debugPrint(
        '[ProxyAiTransport] feature=${operation.wireName} '
        'stage=preflight reason=$reason requestSent=no',
      );
      return true;
    }());
  }

  static void send({
    required AiOperation operation,
    required Map<String, String> headers,
    required String endpoint,
  }) {
    if (!kDebugMode) return;
    assert(() {
      final authUser = headers.containsKey('Authorization') ? 'yes' : 'no';
      final appCheck = headers.containsKey(ProxyAiHeaders.appCheckHeader)
          ? 'yes'
          : 'no';
      debugPrint(
        '[ProxyAiTransport] feature=${operation.wireName} stage=send '
        'endpoint=$endpoint authUser=$authUser appCheck=$appCheck requestSent=yes',
      );
      return true;
    }());
  }

  static void httpStatus({
    required AiOperation operation,
    required int status,
    required DateTime started,
    required bool imagePresent,
    String? errorCode,
    String? responseBody,
  }) {
    if (!kDebugMode) return;
    assert(() {
      final ms = DateTime.now().difference(started).inMilliseconds;
      final code = errorCode == null ? '' : ' errorCode=$errorCode';
      final body = responseBody == null
          ? ''
          : ' body=${ProxyAiResponseSanitize.snippet(responseBody)}';
      debugPrint(
        '[ProxyAiTransport] feature=${operation.wireName} stage=http '
        'httpStatus=$status latencyMs=$ms imagePresent=$imagePresent$code$body',
      );
      return true;
    }());
  }

  static void parseError({
    required AiOperation operation,
    required String reason,
    String? responseBody,
  }) {
    if (!kDebugMode) return;
    assert(() {
      final body = responseBody == null
          ? ''
          : ' body=${ProxyAiResponseSanitize.snippet(responseBody)}';
      debugPrint(
        '[ProxyAiTransport] feature=${operation.wireName} stage=parse '
        'reason=$reason$body',
      );
      return true;
    }());
  }

  static void caught(
    AiOperation operation,
    String tag, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    assert(() {
      final detail = error == null ? '' : ' exception=${error.runtimeType}';
      debugPrint(
        '[ProxyAiTransport] feature=${operation.wireName} stage=network '
        'error=$tag requestSent=yes$detail',
      );
      if (stackTrace != null) {
        debugPrintStack(
          stackTrace: stackTrace,
          label: '[ProxyAiTransport] ${operation.wireName}',
        );
      }
      return true;
    }());
  }

  static void resultError({
    required AiOperation operation,
    required String kind,
    String? errorCode,
  }) {
    if (!kDebugMode) return;
    assert(() {
      final code = errorCode == null ? '' : ' errorCode=$errorCode';
      debugPrint(
        '[ProxyAiTransport] feature=${operation.wireName} stage=result '
        'kind=$kind$code',
      );
      return true;
    }());
  }
}
