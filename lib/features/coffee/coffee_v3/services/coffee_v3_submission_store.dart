/// Persists the Coffee V3 draft/submission record — metadata only, never
/// bytes — under its OWN keys (never `coffee_v2_submission`). Owner
/// discipline mirrors `CoffeeV2SubmissionStore`: a record stamped with
/// another owner is never exposed and never overwritten; integrity-critical
/// writes around operation creation require an available owner.
library;

import 'dart:convert';

import '../../../../core/data/datasources/local_storage.dart';
import '../models/coffee_v3_submission_record.dart';

/// What the entry gate may know about the stored V3 record.
enum CoffeeV3StoredState {
  /// Nothing stored.
  none,

  /// A current-contract DRAFT (no operation yet).
  draft,

  /// A current-contract ACTIVE submission (operation bound).
  active,

  /// Something is stored that this client must not interpret or overwrite
  /// (another owner's record, an unknown / missing capture contract, corrupt
  /// JSON, or no owner while one is required). Fail closed: V3 is not
  /// entered and the existing route is used.
  blocked,
}

class CoffeeV3SubmissionStore {
  CoffeeV3SubmissionStore(
    this._storage, {
    String? ownerId,
    this.ownerResolver,
    this.requireOwner = false,
  }) : _fixedOwnerId = ownerId?.trim();

  final LocalStorage _storage;
  final String? _fixedOwnerId;
  final String? Function()? ownerResolver;
  final bool requireOwner;

  static const key = 'coffee_v3_submission';
  static const acknowledgedOperationKey = 'coffee_v3_acknowledged_operation';

  String? get ownerId {
    final resolved = ownerResolver?.call()?.trim();
    if (resolved != null && resolved.isNotEmpty) return resolved;
    return _fixedOwnerId;
  }

  bool get ownerReady =>
      !requireOwner || (ownerId != null && ownerId!.isNotEmpty);

  CoffeeV3StoredState inspect() {
    final raw = _storage.getString(key);
    if (raw == null) return CoffeeV3StoredState.none;
    if (!ownerReady) return CoffeeV3StoredState.blocked;
    final CoffeeV3SubmissionRecord record;
    try {
      record = CoffeeV3SubmissionRecord.fromJson(jsonDecode(raw));
    } catch (_) {
      return CoffeeV3StoredState.blocked;
    }
    if (!_ownerMatches(record)) return CoffeeV3StoredState.blocked;
    return record.isActive
        ? CoffeeV3StoredState.active
        : CoffeeV3StoredState.draft;
  }

  CoffeeV3SubmissionRecord? load() {
    if (!ownerReady) return null;
    final raw = _storage.getString(key);
    if (raw == null) return null;
    try {
      final record = CoffeeV3SubmissionRecord.fromJson(jsonDecode(raw));
      return _ownerMatches(record) ? record : null;
    } catch (_) {
      return null;
    }
  }

  bool _ownerMatches(CoffeeV3SubmissionRecord record) {
    final currentOwner = ownerId;
    return currentOwner == null ||
        currentOwner.isEmpty ||
        record.ownerId == null ||
        record.ownerId == currentOwner;
  }

  Future<void> save(CoffeeV3SubmissionRecord record) async {
    if (!ownerReady) return;
    await _saveOwned(record);
  }

  /// Integrity-critical write (operation about to be / already created): an
  /// ownerless no-op is not acceptable — losing the local binding could
  /// create a second operation after restart.
  Future<void> saveDurable(CoffeeV3SubmissionRecord record) async {
    if (!ownerReady) throw StateError('coffee v3 owner unavailable');
    await _saveOwned(record);
  }

  Future<void> _saveOwned(CoffeeV3SubmissionRecord record) async {
    final currentOwner = ownerId;
    _assertStoredCompatible(currentOwner);
    final owned = currentOwner == null || currentOwner.isEmpty
        ? record
        : record.copyWith(ownerId: currentOwner);
    final ok = await _storage.setString(key, jsonEncode(owned.toJson()));
    if (!ok) throw StateError('coffee v3 submission not persisted');
  }

  Future<void> clear() async {
    if (!ownerReady) return;
    await _remove();
  }

  Future<void> clearDurable() async {
    if (!ownerReady) throw StateError('coffee v3 owner unavailable');
    await _remove();
  }

  Future<void> _remove() async {
    _assertStoredCompatible(ownerId);
    final ok = await _storage.remove(key);
    if (!ok) throw StateError('coffee v3 submission not cleared');
  }

  String? loadAcknowledgedOperationId() {
    if (!ownerReady) return null;
    final raw = _storage.getString(acknowledgedOperationKey);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      if (ownerId != null && json['ownerId'] != ownerId) return null;
      final operationId = json['operationId'];
      return operationId is String && operationId.isNotEmpty
          ? operationId
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> acknowledgeDurable(String operationId) async {
    if (!ownerReady) throw StateError('coffee v3 owner unavailable');
    final currentOwner = ownerId;
    final ok = await _storage.setString(
      acknowledgedOperationKey,
      jsonEncode({
        if (currentOwner != null && currentOwner.isNotEmpty)
          'ownerId': currentOwner,
        'operationId': operationId,
      }),
    );
    if (!ok) throw StateError('coffee v3 acknowledgement not persisted');
  }

  /// Never overwrite / remove a record this client may not interpret:
  /// another owner's record, or an unknown / corrupt one.
  void _assertStoredCompatible(String? currentOwner) {
    final raw = _storage.getString(key);
    if (raw == null) return;
    final CoffeeV3SubmissionRecord stored;
    try {
      stored = CoffeeV3SubmissionRecord.fromJson(jsonDecode(raw));
    } catch (_) {
      throw StateError('coffee v3 submission metadata unsupported');
    }
    if (currentOwner == null || currentOwner.isEmpty) return;
    final storedOwner = stored.ownerId;
    if (storedOwner != null && storedOwner != currentOwner) {
      throw StateError('coffee v3 owner mismatch');
    }
  }
}
