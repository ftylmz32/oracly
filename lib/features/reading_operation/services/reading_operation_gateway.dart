/// Minimum client foundation. Screens are not wired in this batch.
library;

import '../models/reading_operation_snapshot.dart';
import '../models/reading_operation_status.dart';
import 'reading_operation_codec.dart';

typedef ReadingOperationSender =
    Future<ReadingOperationWire?> Function(
      String method,
      String path,
      Map<String, Object>? body,
    );

class ReadingOperationWire {
  const ReadingOperationWire({required this.statusCode, required this.json});

  final int statusCode;
  final Map<String, dynamic>? json;
}

class ReadingOperationGateway {
  ReadingOperationGateway({required this._send, ReadingOperationCodec? codec})
    : _codec = codec ?? const ReadingOperationCodec();

  final ReadingOperationSender _send;
  final ReadingOperationCodec _codec;

  ReadingOperationSnapshot? parsePublic(Map<String, dynamic> json) {
    return _codec.parse(json);
  }

  Future<ReadingOperationChannelResult> create({
    required ReadingType readingType,
    required String sourceRequestId,
    String language = 'tr',
    String? executionMode,
  }) {
    return _exchange(
      'POST',
      '/v1/reading-operations',
      _codec.createBody(
        readingType: readingType,
        sourceRequestId: sourceRequestId,
        language: language,
        executionMode: executionMode,
      ),
    );
  }

  Future<ReadingOperationChannelResult> fetch(String operationId) {
    return _exchange('GET', '/v1/reading-operations/$operationId', null);
  }

  Future<ReadingOperationChannelResult> _exchange(
    String method,
    String path,
    Map<String, Object>? body,
  ) async {
    try {
      final wire = await _send(method, path, body);
      if (wire == null || wire.statusCode < 200 || wire.statusCode >= 300) {
        final error = wire?.json?['error'];
        return ReadingOperationChannelResult.transport(
          wire == null ? 'transport_unavailable' : 'backend_rejected',
          httpStatus: wire?.statusCode,
          backendCode: error is Map ? error['code']?.toString() : null,
        );
      }
      final data = wire.json?['data'];
      if (data is! Map<String, dynamic>) {
        return const ReadingOperationChannelResult.transport('invalid');
      }
      final snapshot = _codec.parse(data);
      if (snapshot == null) {
        return const ReadingOperationChannelResult.transport('invalid');
      }
      return ReadingOperationChannelResult.snapshot(snapshot);
    } catch (_) {
      return const ReadingOperationChannelResult.transport('unavailable');
    }
  }
}
