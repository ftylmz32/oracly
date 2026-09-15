/// Shared wait / claim / recover boundary. Feature AI stays outside.
library;

// ignore_for_file: prefer_initializing_formals, prefer_function_declarations_over_variables

import '../models/reading_acceleration.dart';
import '../models/reading_operation_snapshot.dart';
import '../models/reading_operation_status.dart';
import 'reading_acceleration_client.dart';
import 'reading_operation_clock.dart';
import 'reading_operation_gateway.dart';
import 'reading_runtime_diagnostics.dart';
import '../../../core/l10n/l10n.dart';

enum ReadingLiveKind { waiting, processing, ready, failed, idle }

class ReadingCompletedResult {
  const ReadingCompletedResult({
    required this.resultId,
    required this.persistedAt,
    required this.result,
  });
  final String resultId;
  final DateTime persistedAt;
  final Map<String, dynamic> result;
}

class ReadingSoulmatePortrait {
  const ReadingSoulmatePortrait({required this.mimeType, required this.imageBase64});
  final String mimeType;
  final String imageBase64;
}

class ReadingLiveState {
  const ReadingLiveState({
    required this.kind,
    required this.snapshot,
    this.execute = false,
    this.refunded = false,
    this.insufficient = false,
    this.failureStage,
    this.httpStatus,
    this.backendCode,
  });

  final ReadingLiveKind kind;
  final ReadingOperationSnapshot? snapshot;
  final bool execute;
  final bool refunded;
  final bool insufficient;
  final String? failureStage;
  final int? httpStatus;
  final String? backendCode;

  Duration displayRemaining(Duration elapsedSinceSync) {
    final snap = snapshot;
    if (snap == null) return Duration.zero;
    return const ReadingOperationClock().displayRemaining(
      readyAt: snap.readyAt,
      serverNowAtSync: snap.serverNow,
      elapsedSinceSync: elapsedSinceSync,
    );
  }
}

class ReadingLiveFlow {
  ReadingLiveFlow({
    required ReadingOperationGateway operations,
    required ReadingAccelerationClient acceleration,
    required Future<ReadingOperationWire?> Function(
      String method,
      String path,
      Map<String, Object>? body,
    )
    send,
  }) : _operations = operations,
       _acceleration = acceleration,
       _send = send;

  final ReadingOperationGateway _operations;
  final ReadingAccelerationClient _acceleration;
  final ReadingOperationSender _send;
  String? _claimed;

  Future<ReadingLiveState> begin({
    required ReadingType readingType,
    required String sourceRequestId,
    String? executionMode,
  }) async {
    final created = await _operations.create(
      readingType: readingType,
      sourceRequestId: sourceRequestId,
      language: OraclyL10n.code,
      executionMode: executionMode,
    );
    if (created.snapshot == null) {
      return ReadingLiveState(
        kind: ReadingLiveKind.failed,
        snapshot: null,
        failureStage: 'begin',
        httpStatus: created.httpStatus,
        backendCode: created.backendCode,
      );
    }
    return _fromSnapshot(created.snapshot!);
  }

  Future<ReadingLiveState> recover(ReadingType readingType) async {
    final wire = await _send(
      'GET',
      '/v1/reading-flow/active?readingType=${readingType.name}',
      null,
    );
    final data = wire?.json?['data'];
    final operation = data is Map ? data['operation'] : null;
    if (wire == null || operation is! Map) {
      return const ReadingLiveState(kind: ReadingLiveKind.idle, snapshot: null);
    }
    final parsed = _operations.parsePublic(
      Map<String, dynamic>.from(operation),
    );
    if (parsed == null) {
      return const ReadingLiveState(kind: ReadingLiveKind.idle, snapshot: null);
    }
    return _fromSnapshot(parsed);
  }

  Future<ReadingLiveState> claimIfEligible(String operationId) async {
    if (_claimed == operationId) {
      return ReadingLiveState(
        kind: ReadingLiveKind.processing,
        snapshot: null,
        execute: false,
      );
    }
    final wire = await _send(
      'POST',
      '/v1/reading-operations/$operationId/claim',
      const {},
    );
    final data = wire?.json?['data'];
    if (data is! Map || data['execute'] != true) {
      return const ReadingLiveState(
        kind: ReadingLiveKind.processing,
        snapshot: null,
        execute: false,
      );
    }
    _claimed = operationId;
    return ReadingLiveState(
      kind: ReadingLiveKind.processing,
      snapshot: _operations.parsePublic(
        Map<String, dynamic>.from(data['operation'] as Map),
      ),
      execute: true,
    );
  }

  Future<ReadingAccelerationView> accelerate({
    required String operationId,
    required String idempotencyKey,
    String? expectedPriceToken,
  }) {
    return _acceleration.accelerate(
      operationId: operationId,
      idempotencyKey: idempotencyKey,
      expectedPriceToken: expectedPriceToken,
    );
  }

  Future<ReadingAccelerationQuote?> quoteAcceleration(String operationId) {
    return _acceleration.quoteAcceleration(operationId: operationId);
  }

  Future<ReadingCompletedResult?> fetchCompletedResult(
    String operationId,
  ) async {
    final wire = await _send(
      'GET',
      '/v1/reading-operations/$operationId/result',
      null,
    );
    final data = wire?.json?['data'];
    if (wire == null || wire.statusCode != 200 || data is! Map) return null;
    final resultId = data['resultId'];
    final persistedAt = DateTime.tryParse(
      data['persistedAt']?.toString() ?? '',
    );
    final result = data['result'];
    if (resultId is! String || persistedAt == null || result is! Map)
      return null;
    return ReadingCompletedResult(
      resultId: resultId,
      persistedAt: persistedAt,
      result: Map<String, dynamic>.from(result),
    );
  }

  /// SMD1 — the durable Soulmate portrait is private, authenticated storage
  /// (never a public URL); this is the only way a client may fetch it, and
  /// only for the operation's own owner (server-enforced).
  Future<ReadingSoulmatePortrait?> fetchSoulmatePortrait(
    String operationId,
  ) async {
    final wire = await _send(
      'GET',
      '/v1/reading-operations/$operationId/soulmate-portrait',
      null,
    );
    final data = wire?.json?['data'];
    if (wire == null || wire.statusCode != 200 || data is! Map) return null;
    final mimeType = data['mimeType'];
    final imageBase64 = data['imageBase64'];
    if (mimeType is! String || imageBase64 is! String) return null;
    return ReadingSoulmatePortrait(mimeType: mimeType, imageBase64: imageBase64);
  }

  Future<void> complete({
    required String operationId,
    required String resultId,
  }) async {
    final wire = await _send(
      'POST',
      '/v1/reading-operations/$operationId/complete',
      {'resultId': resultId},
    );
    if (wire == null || wire.statusCode < 200 || wire.statusCode >= 300) {
      final code = wire?.json?['error'] is Map
          ? (wire!.json!['error'] as Map)['code']?.toString()
          : null;
      throw ReadingRuntimeException(
        'complete',
        status: wire?.statusCode,
        backendCode: code,
        message: wire == null ? 'transport_unavailable' : 'backend_rejected',
      );
    }
  }

  Future<bool> failFinal(String operationId) async {
    final wire = await _send(
      'POST',
      '/v1/reading-operations/$operationId/fail',
      const {},
    );
    final data = wire?.json?['data'];
    return data is Map && data['refunded'] == true;
  }

  ReadingLiveState _fromSnapshot(ReadingOperationSnapshot snap) {
    return switch (snap.status) {
      ReadingOperationStatus.ready => ReadingLiveState(
        kind: ReadingLiveKind.ready,
        snapshot: snap,
      ),
      ReadingOperationStatus.failed => ReadingLiveState(
        kind: ReadingLiveKind.failed,
        snapshot: snap,
      ),
      ReadingOperationStatus.processing => ReadingLiveState(
        kind: ReadingLiveKind.processing,
        snapshot: snap,
      ),
      ReadingOperationStatus.waiting => ReadingLiveState(
        kind: ReadingLiveKind.waiting,
        snapshot: snap,
      ),
    };
  }
}
