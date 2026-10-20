/// Owner-aware local birth chart storage (Phase 3).
library;

import 'dart:convert';

import '../../auth/user_local_data_isolation.dart';
import '../../data/datasources/local_storage.dart';
import '../../domain/models/birth_chart_record.dart';
import '../../domain/repositories/birth_chart_repository.dart';

/// Thrown when canonical local owner is missing — never wipe for this.
class BirthChartOwnerUnavailableException implements Exception {
  const BirthChartOwnerUnavailableException();

  @override
  String toString() => 'BirthChartOwnerUnavailableException';
}

class LocalBirthChartRepository implements BirthChartRepository {
  LocalBirthChartRepository(
    this._storage, {
    String? ownerId,
    String? Function()? ownerIdResolver,
  })  : _fixedOwnerId = ownerId,
        _ownerIdResolver = ownerIdResolver;

  /// Reads the canonical owner on every call. The first owner of an install
  /// is committed without an account-switch epoch bump, so a repository built
  /// before anonymous auth finished must still see that owner afterwards.
  factory LocalBirthChartRepository.live(LocalStorage storage) =>
      LocalBirthChartRepository(
        storage,
        ownerIdResolver: () => readCanonicalOwner(storage),
      );

  static const storageKey = 'birth_chart_latest';
  static const _key = storageKey;

  final LocalStorage _storage;

  final String? _fixedOwnerId;
  final String? Function()? _ownerIdResolver;

  /// Canonical local-data owner. Null/empty → fail closed (no wipe).
  String? get ownerId => _ownerIdResolver?.call() ?? _fixedOwnerId;

  /// Trimmed owner for one operation, or null when unresolved.
  String? _ownerNow() {
    final id = ownerId?.trim();
    return id == null || id.isEmpty ? null : id;
  }

  String _requireOwner() =>
      _ownerNow() ?? (throw const BirthChartOwnerUnavailableException());

  @override
  Future<BirthChartRecord?> getLatest() async {
    final owner = _requireOwner();
    final raw = _storage.getString(_key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final record =
          BirthChartRecord.fromJson(Map<String, dynamic>.from(decoded));
      return _adoptOrFilter(record, owner);
    } catch (e) {
      if (e is BirthChartOwnerUnavailableException) rethrow;
      return null;
    }
  }

  Future<BirthChartRecord?> _adoptOrFilter(
    BirthChartRecord record,
    String current,
  ) async {
    final existing = record.ownerId?.trim();
    if (existing == null || existing.isEmpty) {
      final adopted = record.copyWith(ownerId: current);
      await _storage.setString(_key, jsonEncode(adopted.toJson()));
      return adopted;
    }
    if (existing != current) return null;
    return record;
  }

  @override
  Future<void> save(BirthChartRecord record) async {
    final current = _requireOwner();
    final existingRaw = _storage.getString(_key);
    if (existingRaw != null && existingRaw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(existingRaw);
        if (decoded is Map) {
          final existing = BirthChartRecord.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          final eid = existing.ownerId?.trim();
          if (eid != null && eid.isNotEmpty && eid != current) {
            return; // fail closed — do not overwrite A with B
          }
        }
      } catch (_) {}
    }
    final stamped = record.copyWith(ownerId: current);
    await _storage.setString(_key, jsonEncode(stamped.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    _requireOwner();
    final current = await getLatest();
    if (current?.id == id) {
      await clearLatest();
    }
  }

  @override
  Future<void> clearLatest() async {
    final owner = _ownerNow();
    if (owner == null) return; // fail closed — do not wipe when owner unresolved
    final raw = _storage.getString(_key);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final existing = BirthChartRecord.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          final eid = existing.ownerId?.trim();
          if (eid != null && eid.isNotEmpty && eid != owner) {
            return; // fail closed — B cannot clear A's record
          }
        }
      } catch (_) {}
    }
    await _storage.remove(_key);
  }

  /// Read owner key from storage without constructing a repository.
  static String? readCanonicalOwner(LocalStorage storage) =>
      storage.getString(UserLocalDataIsolation.ownerKey);
}
