/// Local list store for Yıldızname artifacts (`yildizname_artifacts_v1`).
library;

import 'package:flutter/foundation.dart';

import '../../../core/data/datasources/local_storage.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_exceptions.dart';
import 'yildizname_artifact_repository.dart';
import 'yildizname_artifact_store_codec.dart';

class LocalYildiznameArtifactRepository
    implements YildiznameArtifactRepository {
  LocalYildiznameArtifactRepository(
    this._storage, {
    required this.ownerId,
  });

  static const storageKey = 'yildizname_artifacts_v1';

  final LocalStorage _storage;
  final String? ownerId;

  bool get _ownerReady =>
      ownerId != null && ownerId!.trim().isNotEmpty;

  void _requireOwner() {
    if (!_ownerReady) {
      throw const YildiznameArtifactOwnerUnavailableException();
    }
  }

  String get _owner => ownerId!.trim();

  @override
  Future<List<YildiznameArtifact>> getAll() async {
    _requireOwner();
    final all = YildiznameArtifactStoreCodec.decodeStringList(
      _storage.getStringList(storageKey) ?? const <String>[],
    );
    final owned = <YildiznameArtifact>[];
    final seen = <String, String>{};
    for (final a in all) {
      if (a.ownerId.trim() != _owner) continue;
      final prior = seen[a.id];
      if (prior != null && prior != a.contentHash) {
        debugPrint(
          '[YildiznameArtifact] duplicate id ${a.id} different hash',
        );
        continue;
      }
      if (prior != null) continue;
      seen[a.id] = a.contentHash;
      owned.add(a);
    }
    owned.sort((a, b) {
      final c = b.createdAtUtc.compareTo(a.createdAtUtc);
      if (c != 0) return c;
      return a.id.compareTo(b.id);
    });
    return owned;
  }

  @override
  Future<YildiznameArtifact?> getById(String id) async {
    _requireOwner();
    for (final a in await getAll()) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  Future<YildiznameArtifact> saveNew(YildiznameArtifact artifact) async {
    _requireOwner();
    if (artifact.ownerId.trim() != _owner) {
      throw const YildiznameArtifactOwnerUnavailableException(
        'owner mismatch',
      );
    }
    final raw = _storage.getStringList(storageKey) ?? const <String>[];
    for (final existing in YildiznameArtifactStoreCodec.decodeStringList(raw)) {
      if (existing.id != artifact.id) continue;
      if (existing.contentHash == artifact.contentHash) return existing;
      throw const YildiznameArtifactDuplicateConflictException();
    }
    await _storage.setStringList(storageKey, [
      YildiznameArtifactStoreCodec.encode(artifact),
      ...raw,
    ]);
    return artifact;
  }

  @override
  Future<void> delete(String id) async {
    _requireOwner();
    await _filterOwner((a) => a.id != id);
  }

  @override
  Future<void> clearAllForOwner() async {
    _requireOwner();
    await _filterOwner((_) => false);
  }

  Future<void> _filterOwner(bool Function(YildiznameArtifact a) keep) async {
    final raw = _storage.getStringList(storageKey) ?? const <String>[];
    final next = <String>[];
    for (final entry in raw) {
      final a = YildiznameArtifactStoreCodec.tryDecode(entry);
      if (a == null) {
        next.add(entry);
        continue;
      }
      if (a.ownerId.trim() == _owner && !keep(a)) continue;
      next.add(entry);
    }
    await _storage.setStringList(storageKey, next);
  }
}
