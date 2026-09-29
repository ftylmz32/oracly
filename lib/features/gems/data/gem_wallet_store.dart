/// Last-known server snapshot plus non-authoritative legacy display history.
library;

import 'dart:convert';

import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../../core/data/datasources/storage_result.dart';
import '../models/gem_transaction.dart';

class GemWalletStore {
  GemWalletStore(this._storage);

  static const balanceKey = 'gem_balance';
  static const txKey = 'gem_transactions';
  static const serverBalanceCacheKey = 'gem_server_balance_cache_v1';
  static const serverBalanceOwnerKey = 'gem_server_balance_owner_v1';

  /// Keep enough ledger rows that charge idempotency survives weeks of use.
  static const maxHistory = 80;

  final LocalStorage _storage;

  int balance() {
    final raw = _storage.getInt(serverBalanceCacheKey) ?? 0;
    return raw < 0 ? 0 : raw;
  }

  /// Returns a displayable server snapshot only for its authenticated owner.
  /// Legacy unowned cache values intentionally fail closed.
  int? balanceForOwner(String? ownerId) {
    if (ownerId == null || ownerId.isEmpty) return null;
    if (_storage.getString(serverBalanceOwnerKey) != ownerId) return null;
    final raw = _storage.getInt(serverBalanceCacheKey);
    if (raw == null) return null;
    return raw < 0 ? 0 : raw;
  }

  List<GemTransaction> history() {
    final raw = _storage.getStringList(txKey) ?? const <String>[];
    final items = <GemTransaction>[];
    for (final row in raw) {
      try {
        final decoded = jsonDecode(row);
        if (decoded is! Map) continue;
        final tx = GemTransaction.fromJson(Map<String, dynamic>.from(decoded));
        if (tx.id.isEmpty) continue;
        items.add(tx);
      } catch (_) {}
    }
    return items;
  }

  Future<void> write({
    required int balance,
    required GemTransaction transaction,
  }) async {
    // Legacy/test compatibility only. `gem_balance` is retired and never read
    // as authority or uploaded to the server.
    final nextBalance = balance < 0 ? 0 : balance;
    final nextHistory = [transaction, ...history()].take(maxHistory).toList();
    // History first — crash mid-write prefers an auditable ledger over a
    // silent balance bump without a matching transaction.
    await _storage.setStringList(
      txKey,
      nextHistory.map((e) => jsonEncode(e.toJson())).toList(),
    );
    await _storage.setInt(balanceKey, nextBalance);
  }

  Future<void> cacheServerBalance(
    int balance, {
    String? ownerId,
    bool Function()? stillOwner,
  }) {
    return UserLocalDataIsolation.runOwnerScopedMutation(() async {
      if (stillOwner != null && !stillOwner()) return;
      final owner = ownerId?.trim();
      final normalized = balance < 0 ? 0 : balance;
      if (owner == null || owner.isEmpty) {
        await _storage
            .setInt(serverBalanceCacheKey, normalized)
            .requireDurable(serverBalanceCacheKey);
        return;
      }
      if (stillOwner != null && !stillOwner()) return;
      await _storage
          .remove(serverBalanceCacheKey)
          .requireDurable(serverBalanceCacheKey);
      if (stillOwner != null && !stillOwner()) return;
      await _storage
          .setString(serverBalanceOwnerKey, owner)
          .requireDurable(serverBalanceOwnerKey);
      if (stillOwner != null && !stillOwner()) {
        await _storage.remove(serverBalanceOwnerKey);
        return;
      }
      await _storage
          .setInt(serverBalanceCacheKey, normalized)
          .requireDurable(serverBalanceCacheKey);
    });
  }
}
