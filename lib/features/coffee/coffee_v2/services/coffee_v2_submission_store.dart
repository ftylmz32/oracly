/// Persists the Coffee V2 draft/submission record — metadata only, never
/// bytes — under a single fixed key. There is only ever one Coffee V2
/// draft/submission in flight at a time, unlike the per-`ReadingType`
/// `ReadingPendingOperationStore`.
library;

import 'dart:convert';

import '../../../../core/data/datasources/local_storage.dart';
import '../models/coffee_v2_submission_record.dart';

class CoffeeV2SubmissionStore {
  CoffeeV2SubmissionStore(
    this._storage, {
    String? ownerId,
    this.requireOwner = false,
  }) : ownerId = ownerId?.trim();

  final LocalStorage _storage;
  final String? ownerId;
  final bool requireOwner;

  static const _key = 'coffee_v2_submission';
  static const _acknowledgedOperationKey = 'coffee_v2_acknowledged_operation';

  CoffeeV2SubmissionRecord? load() {
    if (requireOwner && (ownerId == null || ownerId!.isEmpty)) return null;
    final raw = _storage.getString(_key);
    if (raw == null) return null;
    try {
      final record = CoffeeV2SubmissionRecord.fromJson(jsonDecode(raw));
      final currentOwner = ownerId;
      if (currentOwner != null &&
          currentOwner.isNotEmpty &&
          record.ownerId != null &&
          record.ownerId != currentOwner) {
        return null;
      }
      return record;
    } catch (_) {
      return null;
    }
  }

  Future<void> save(CoffeeV2SubmissionRecord record) {
    final currentOwner = ownerId;
    if (requireOwner && (currentOwner == null || currentOwner.isEmpty)) {
      return Future.value();
    }
    final owned = currentOwner == null || currentOwner.isEmpty
        ? record
        : record.copyWith(ownerId: currentOwner);
    return _storage.setString(_key, jsonEncode(owned.toJson()));
  }

  Future<void> clear() => _storage.remove(_key);

  String? loadAcknowledgedOperationId() {
    if (requireOwner && (ownerId == null || ownerId!.isEmpty)) return null;
    final raw = _storage.getString(_acknowledgedOperationKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final storedOwner = json['ownerId'];
      final operationId = json['operationId'];
      if (ownerId != null && storedOwner != ownerId) return null;
      return operationId is String && operationId.isNotEmpty
          ? operationId
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> acknowledge(String operationId) {
    if (requireOwner && (ownerId == null || ownerId!.isEmpty)) {
      return Future.value();
    }
    return _storage.setString(
      _acknowledgedOperationKey,
      jsonEncode({
        if (ownerId != null && ownerId!.isNotEmpty) 'ownerId': ownerId,
        'operationId': operationId,
      }),
    );
  }
}
