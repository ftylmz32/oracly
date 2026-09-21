/// Persists just enough identity about an in-flight `waiting`/`processing`
/// Coffee/Palm reading operation — NEVER image bytes — so recovery after
/// an app restart or controller disposal can find and resume the SAME
/// staged operation. Once an operation is staged, the server-held image
/// is the durable source; this store only remembers which operation to
/// ask the server about, not the input itself.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/reading_operation_status.dart';

class ReadingPendingOperation {
  const ReadingPendingOperation({
    required this.operationId,
    required this.sourceRequestId,
    required this.mimeType,
    this.handSide,
  });

  final String operationId;
  final String sourceRequestId;
  final String mimeType;
  final String? handSide;

  Map<String, dynamic> toJson() => {
        'operationId': operationId,
        'sourceRequestId': sourceRequestId,
        'mimeType': mimeType,
        if (handSide != null) 'handSide': handSide,
      };

  static ReadingPendingOperation? fromJson(Object? json) {
    if (json is! Map) return null;
    final operationId = json['operationId'];
    final sourceRequestId = json['sourceRequestId'];
    final mimeType = json['mimeType'];
    if (operationId is! String || operationId.isEmpty) return null;
    if (sourceRequestId is! String || sourceRequestId.isEmpty) return null;
    if (mimeType is! String || mimeType.isEmpty) return null;
    final handSide = json['handSide'];
    return ReadingPendingOperation(
      operationId: operationId,
      sourceRequestId: sourceRequestId,
      mimeType: mimeType,
      handSide: handSide is String ? handSide : null,
    );
  }
}

class ReadingPendingOperationStore {
  ReadingPendingOperationStore(this._storage);

  final LocalStorage _storage;

  static String _key(ReadingType type) => 'reading_pending_operation_${type.name}';

  ReadingPendingOperation? load(ReadingType type) {
    final raw = _storage.getString(_key(type));
    if (raw == null) return null;
    try {
      return ReadingPendingOperation.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ReadingType type, ReadingPendingOperation operation) {
    return _storage.setString(_key(type), jsonEncode(operation.toJson()));
  }

  Future<void> clear(ReadingType type) {
    return _storage.remove(_key(type));
  }

  /// R5 — account-boundary wipe for every durable pending pointer.
  /// Clears known [ReadingType] keys plus any stray `reading_pending_operation_*`.
  /// A `false` (non-throwing) removal is exactly as much a failure as a
  /// thrown one — every key is still attempted, but this throws if any
  /// removal did not durably succeed, so [UserLocalDataWipe] catches it.
  static Future<void> clearAll(LocalStorage storage) async {
    final failed = <String>[];
    Future<void> removeKey(String key) async {
      try {
        if (!await storage.remove(key)) failed.add(key);
      } catch (_) {
        failed.add(key);
      }
    }

    for (final type in ReadingType.values) {
      await removeKey(_key(type));
    }
    for (final key in storage.keys
        .where((k) => k.startsWith('reading_pending_operation_'))
        .toList()) {
      await removeKey(key);
    }
    if (failed.isNotEmpty) {
      throw StateError('reading pending operation keys not removed: $failed');
    }
  }
}
