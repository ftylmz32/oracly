/// Persists unpaid provider-ok ops so resume can settle without re-charge.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/paid_ai_operation.dart';

class PaidAiOperationStore {
  PaidAiOperationStore(this._storage);

  static const key = 'paid_ai_operations_v1';
  static const maxEntries = 40;

  final LocalStorage _storage;

  List<PaidAiOperation> all() {
    final raw = _storage.getStringList(key) ?? const <String>[];
    final out = <PaidAiOperation>[];
    for (final row in raw) {
      try {
        final decoded = jsonDecode(row);
        if (decoded is! Map<String, dynamic>) continue;
        final op = PaidAiOperation.fromJson(decoded);
        if (op.id.isNotEmpty) out.add(op);
      } catch (_) {
        // Skip corrupt rows so resume reconcile can still settle healthy ops.
      }
    }
    return out;
  }

  PaidAiOperation? byId(String id) {
    for (final op in all()) {
      if (op.id == id) return op;
    }
    return null;
  }

  List<PaidAiOperation> needingSettle() => [
        for (final op in all())
          if (op.status == PaidAiOperationStatus.providerOk && op.isBillable) op,
      ];

  Future<void> upsert(PaidAiOperation op) async {
    final next = [op, ...all().where((e) => e.id != op.id)]
        .take(maxEntries)
        .toList();
    await _write(next);
  }

  Future<void> remove(String id) async {
    await _write([for (final op in all()) if (op.id != id) op]);
  }

  Future<void> clear() => _storage.remove(key);

  Future<void> _write(List<PaidAiOperation> ops) async {
    await _storage.setStringList(
      key,
      ops.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }
}
