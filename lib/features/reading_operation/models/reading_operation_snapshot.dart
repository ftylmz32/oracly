/// Server-authored operation view. The client never mutates these fields.
library;

import 'reading_failure_code.dart';
import 'reading_operation_status.dart';

class ReadingOperationSnapshot {
  const ReadingOperationSnapshot({
    required this.operationId,
    required this.readingType,
    required this.status,
    required this.createdAt,
    required this.readyAt,
    required this.serverNow,
    required this.waitFinished,
    required this.remainingMs,
    required this.resultReady,
    required this.resultId,
    this.durable = false,
    this.failureCode = ReadingFailureCode.unknown,
  });

  final String operationId;
  final ReadingType readingType;
  final ReadingOperationStatus status;
  final DateTime createdAt;
  final DateTime readyAt;
  final DateTime serverNow;
  final bool waitFinished;
  final int remainingMs;
  final bool resultReady;
  final String? resultId;
  /// SMD1 — true only for a server-authoritative durable operation (never
  /// true for a legacy client-driven Soulmate/Coffee/Palm record). Purely
  /// observational: the client never derives execution authority from this
  /// flag, only presentation (e.g. legacy-stale-operation detection).
  final bool durable;

  /// R3.1 — allow-listed public failure class when [status] is failed.
  /// Historical payloads without a code decode as [ReadingFailureCode.unknown].
  final ReadingFailureCode failureCode;

  bool get operationFailed => status == ReadingOperationStatus.failed;
}

/// Transport failure is not an operation failure.
class ReadingOperationChannelResult {
  const ReadingOperationChannelResult.snapshot(this.snapshot)
      : failure = null,
        httpStatus = null,
        backendCode = null;

  const ReadingOperationChannelResult.transport(this.failure, {this.httpStatus, this.backendCode}) : snapshot = null;

  final ReadingOperationSnapshot? snapshot;
  final String? failure;
  final int? httpStatus;
  final String? backendCode;

  bool get isTransportFailure => failure != null;
}
