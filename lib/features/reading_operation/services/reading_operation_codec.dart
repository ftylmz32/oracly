/// Parses public operation payloads. Rejects client-authored authority.
library;

import '../models/reading_operation_snapshot.dart';
import '../models/reading_operation_status.dart';

class ReadingOperationCodec {
  const ReadingOperationCodec();

  ReadingOperationSnapshot? parse(Map<String, dynamic> json) {
    final operationId = json['operationId'];
    final status = readingOperationStatusFromWire(json['status'] as String?);
    final readingType = readingTypeFromWire(json['readingType'] as String?);
    final createdAt = _utc(json['createdAt']);
    final readyAt = _utc(json['readyAt']);
    final serverNow = _utc(json['serverNow']);
    final remainingMs = json['remainingMs'];
    final waitFinished = json['waitFinished'];
    final resultReady = json['resultReady'];
    if (operationId is! String || operationId.length != 32) return null;
    if (status == null || readingType == null) return null;
    if (createdAt == null || readyAt == null || serverNow == null) return null;
    if (remainingMs is! int || remainingMs < 0) return null;
    if (waitFinished is! bool || resultReady is! bool) return null;
    if (json.containsKey('ownerUserId') || json.containsKey('failureCode')) {
      return null;
    }
    final resultId = json['resultId'];
    if (resultId != null && resultId is! String) return null;
    if (resultReady && (resultId == null || resultId.isEmpty)) return null;
    if (!resultReady && resultId != null) return null;
    if (status == ReadingOperationStatus.ready && !resultReady) return null;
    return ReadingOperationSnapshot(
      operationId: operationId,
      readingType: readingType,
      status: status,
      createdAt: createdAt,
      readyAt: readyAt,
      serverNow: serverNow,
      waitFinished: waitFinished,
      remainingMs: remainingMs,
      resultReady: resultReady,
      resultId: resultId,
      durable: json['durable'] == true,
    );
  }

  Map<String, Object> createBody({
    required ReadingType readingType,
    required String sourceRequestId,
    String language = 'tr',
    String? executionMode,
  }) {
    return {
      'readingType': readingTypeWire(readingType),
      'sourceRequestId': sourceRequestId,
      'language': language,
      if (executionMode != null) 'executionMode': executionMode,
    };
  }

  DateTime? _utc(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return null;
    return parsed.toUtc();
  }
}
