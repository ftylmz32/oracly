/// Local persistence for gem balance + simple ledger.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/gem_transaction.dart';

class GemWalletStore {
  GemWalletStore(this._storage);

  static const balanceKey = 'gem_balance';
  static const txKey = 'gem_transactions';
  /// Keep enough ledger rows that charge idempotency survives weeks of use.
  static const maxHistory = 80;

  final LocalStorage _storage;

  int balance() {
    final raw = _storage.getInt(balanceKey) ?? 0;
    return raw < 0 ? 0 : raw;
  }

  List<GemTransaction> history() {
    final raw = _storage.getStringList(txKey) ?? const <String>[];
    final items = <GemTransaction>[];
    for (final row in raw) {
      try {
        final decoded = jsonDecode(row);
        if (decoded is! Map) continue;
        final tx = GemTransaction.fromJson(
          Map<String, dynamic>.from(decoded),
        );
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
}
