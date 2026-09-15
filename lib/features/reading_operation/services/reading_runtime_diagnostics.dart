import 'package:flutter/foundation.dart';

class ReadingRuntimeDiagnostic {
  const ReadingRuntimeDiagnostic({required this.feature, required this.operationId, required this.stage, required this.exceptionType, required this.safeMessage, this.httpStatus, this.backendCode});
  final String feature;
  final String? operationId;
  final String stage;
  final String exceptionType;
  final String safeMessage;
  final int? httpStatus;
  final String? backendCode;
}

abstract interface class ReadingRuntimeDiagnostics {
  void record(ReadingRuntimeDiagnostic event);
}

class DebugReadingRuntimeDiagnostics implements ReadingRuntimeDiagnostics {
  const DebugReadingRuntimeDiagnostics();
  @override void record(ReadingRuntimeDiagnostic event) {
    debugPrint('[ReadingRuntime] feature=${event.feature} operation=${event.operationId ?? 'none'} stage=${event.stage} exception=${event.exceptionType} message=${_safe(event.safeMessage)} status=${event.httpStatus ?? 'none'} code=${event.backendCode ?? 'none'}');
  }
  static String _safe(String value) {
    final cleaned = value.replaceAllMapped(
      RegExp(r'(bearer|token|key|signature)\s*[:=]\s*\S+', caseSensitive: false),
      (match) => '${match.group(1)}=[redacted]',
    ).replaceAll(RegExp(r'[\r\n]+'), ' ');
    return cleaned.length <= 240 ? cleaned : cleaned.substring(0, 240);
  }
}

class ReadingRuntimeException implements Exception {
  const ReadingRuntimeException(this.stage, {this.status, this.backendCode, this.message = 'request_failed'});
  final String stage;
  final int? status;
  final String? backendCode;
  final String message;
  @override String toString() => message;
}
