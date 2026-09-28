library;

import 'dart:async';

import '../../ai/domain/models/ai_message.dart';
import '../../gems/services/paid_ai_operation_binder.dart';

abstract final class OrOperationId {
  OrOperationId._();

  static const metadataKey = 'orOperationId';
  static const stateKey = 'orOperationState';
  static const pending = 'pending';
  static const completed = 'completed';
  static const abandoned = 'abandoned';
  static const _zoneKey = #orOperationId;

  static String? get current => Zone.current[_zoneKey] as String?;

  /// Turn-scoped zone + Idempotency-Key binder for one user send intent.
  static Future<T> run<T>(String id, Future<T> Function() body) {
    return runZoned(
      () => PaidAiOperationBinder.runWithKey(id, body),
      zoneValues: {_zoneKey: id},
    );
  }

  /// Runs a quality re-generation under its own key. Reusing the turn key
  /// would make the server replay the very response the gate just rejected.
  static Future<T> runQualityAttempt<T>(
    int attempt,
    Future<T> Function() body,
  ) {
    final turn = current;
    if (attempt <= 1 || turn == null) return body();
    final nonce = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return run('$turn.q$attempt.$nonce', body);
  }

  static String? pendingId(AIMessage? message) {
    if (message == null || !message.isUser) return null;
    if (message.metadata[stateKey] != pending) return null;
    final id = message.metadata[metadataKey]?.trim() ?? '';
    return id.isEmpty ? null : id;
  }

  static AIMessage withState(AIMessage message, String state) =>
      message.copyWith(metadata: {...message.metadata, stateKey: state});
}
