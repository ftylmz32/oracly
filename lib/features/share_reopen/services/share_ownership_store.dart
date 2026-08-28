/// Device-only owner map. Authorization never comes from the link.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/share_ownership.dart';

class ShareOwnershipStore {
  ShareOwnershipStore(this._storage);

  static const key = 'or_share_ownership_v1';
  static const maxRows = 40;

  final LocalStorage _storage;

  ShareOwnership? byId(String id) {
    for (final row in all()) {
      if (row.id == id) return row;
    }
    return null;
  }

  List<ShareOwnership> all() {
    final raw = _storage.getStringList(key) ?? const [];
    return [for (final row in raw) ..._decode(row)];
  }

  Future<void> put(ShareOwnership ownership) async {
    if (ownership.id.isEmpty || ownership.ownerUserId.isEmpty) return;
    final next = [
      ownership,
      ...all().where((row) => row.id != ownership.id),
    ].take(maxRows).toList();
    await _storage.setStringList(
      key,
      [for (final row in next) jsonEncode(row.toJson())],
    );
  }

  static Iterable<ShareOwnership> _decode(String row) {
    try {
      final decoded = jsonDecode(row);
      if (decoded is! Map) return const [];
      final json = Map<String, dynamic>.from(decoded);
      if (json['id'] == null || json['ownerUserId'] == null) return const [];
      return [ShareOwnership.fromJson(json)];
    } catch (_) {
      return const [];
    }
  }
}
