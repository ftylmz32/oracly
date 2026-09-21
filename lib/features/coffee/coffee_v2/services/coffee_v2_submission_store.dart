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
    this.ownerResolver,
    this.requireOwner = false,
  }) : _fixedOwnerId = ownerId?.trim();

  final LocalStorage _storage;
  final String? _fixedOwnerId;
  final String? Function()? ownerResolver;
  final bool requireOwner;

  String? get ownerId {
    final resolved = ownerResolver?.call()?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;
    return _fixedOwnerId;
  }

  static const _key = 'coffee_v2_submission';
  static const _acknowledgedOperationKey = 'coffee_v2_acknowledged_operation';

  bool get ownerReady =>
      !requireOwner || (ownerId != null && ownerId!.isNotEmpty);

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

  Future<void> save(CoffeeV2SubmissionRecord record) async {
    final currentOwner = ownerId;
    if (requireOwner && (currentOwner == null || currentOwner.isEmpty)) {
      return;
    }
    await _saveOwned(record, currentOwner);
  }

  /// Integrity-critical write used once the flow is about to create or has
  /// already created a server operation. At that point an ownerless no-op is
  /// not acceptable: losing the local binding can create a second operation
  /// after restart even though the server already owns the first one.
  Future<void> saveDurable(CoffeeV2SubmissionRecord record) async {
    final currentOwner = ownerId;
    if (requireOwner && (currentOwner == null || currentOwner.isEmpty)) {
      throw StateError('coffee v2 owner unavailable');
    }
    await _saveOwned(record, currentOwner);
  }

  Future<void> _saveOwned(
    CoffeeV2SubmissionRecord record,
    String? currentOwner,
  ) async {
    _assertStoredOwnerCompatible(currentOwner);
    final owned = currentOwner == null || currentOwner.isEmpty
        ? record
        : record.copyWith(ownerId: currentOwner);
    final ok = await _storage.setString(_key, jsonEncode(owned.toJson()));
    if (!ok) throw StateError('coffee v2 submission not persisted');
  }

  Future<void> clear() async {
    final currentOwner = ownerId;
    if (requireOwner && (currentOwner == null || currentOwner.isEmpty)) {
      return;
    }
    _assertStoredOwnerCompatible(currentOwner);
    final ok = await _storage.remove(_key);
    if (!ok) throw StateError('coffee v2 submission not cleared');
  }

  Future<void> clearDurable() async {
    final currentOwner = ownerId;
    if (requireOwner && (currentOwner == null || currentOwner.isEmpty)) {
      throw StateError('coffee v2 owner unavailable');
    }
    _assertStoredOwnerCompatible(currentOwner);
    final ok = await _storage.remove(_key);
    if (!ok) throw StateError('coffee v2 submission not cleared');
  }

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

  Future<void> acknowledge(String operationId) async {
    if (requireOwner && (ownerId == null || ownerId!.isEmpty)) return;
    await _acknowledgeOwned(operationId, requireOwnerNow: false);
  }

  Future<void> acknowledgeDurable(String operationId) =>
      _acknowledgeOwned(operationId, requireOwnerNow: true);

  Future<void> _acknowledgeOwned(
    String operationId, {
    required bool requireOwnerNow,
  }) async {
    final currentOwner = ownerId;
    if (requireOwner && (currentOwner == null || currentOwner.isEmpty)) {
      if (requireOwnerNow) {
        throw StateError('coffee v2 owner unavailable');
      }
      return;
    }
    final ok = await _storage.setString(
      _acknowledgedOperationKey,
      jsonEncode({
        if (currentOwner != null && currentOwner.isNotEmpty)
          'ownerId': currentOwner,
        'operationId': operationId,
      }),
    );
    if (!ok) throw StateError('coffee v2 acknowledgement not persisted');
  }

  void _assertStoredOwnerCompatible(String? currentOwner) {
    if (currentOwner == null || currentOwner.isEmpty) return;
    final raw = _storage.getString(_key);
    if (raw == null) return;
    try {
      final record = CoffeeV2SubmissionRecord.fromJson(jsonDecode(raw));
      final storedOwner = record.ownerId;
      if (storedOwner != null && storedOwner != currentOwner) {
        throw StateError('coffee v2 owner mismatch');
      }
    } on StateError {
      rethrow;
    } catch (_) {
      throw StateError('coffee v2 submission metadata corrupt');
    }
  }
}
