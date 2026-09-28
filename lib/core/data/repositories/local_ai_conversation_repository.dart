/// OR-1130 — Local AI conversation repository.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/datasources/local_storage.dart';
import '../../data/datasources/storage_result.dart';
import '../../domain/models/conversation_record.dart';
import '../../domain/repositories/ai_conversation_repository.dart';

class LocalAiConversationRepository implements AiConversationRepository {
  LocalAiConversationRepository(this._storage);

  static const _key = 'ai_conversations';

  final LocalStorage _storage;

  /// Quarantined corrupt row count for the last [getAll] (tests / diagnostics).
  int lastQuarantinedRows = 0;

  /// Test-only: awaited once after [getAll] resolves inside [saveGuarded],
  /// before the final [canWrite] check and the write it guards. Lets a test
  /// interleave a real account switch inside that exact gap. Always `null`
  /// in production.
  @visibleForTesting
  Future<void> Function()? debugPauseAfterRead;

  @override
  Future<List<ConversationRecord>> getAll() async {
    final raw = _storage.getStringList(_key);
    if (raw == null) {
      lastQuarantinedRows = 0;
      return [];
    }
    final items = <ConversationRecord>[];
    var quarantined = 0;
    for (final row in raw) {
      final record = _tryParse(row);
      if (record != null) {
        items.add(record);
      } else {
        quarantined++;
        assert(() {
          // Metadata only — never row contents (private conversation).
          debugPrint('[OR] historyQuarantine reason=row_parse');
          return true;
        }());
      }
    }
    lastQuarantinedRows = quarantined;
    return items;
  }

  static ConversationRecord? _tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return ConversationRecord.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<ConversationRecord?> getById(String id) async {
    final all = await getAll();
    for (final record in all) {
      if (record.id == id) return record;
    }
    return null;
  }

  @override
  Future<void> save(ConversationRecord record) async {
    final all = await getAll();
    await _writeAll([
      for (final r in all)
        if (r.id != record.id) r,
      record,
    ]);
  }

  /// Same write as [save], except the write only proceeds if [canWrite]
  /// still holds once the current list has finished loading — checked
  /// immediately before the write starts, with nothing else awaited in
  /// between. [save] has the same `getAll`-then-write gap but no way to
  /// re-validate ownership inside it; production OR sends call this instead
  /// so a reply that arrives after the owner changed mid-gap is never
  /// written for the wrong owner.
  Future<void> saveGuarded(
    ConversationRecord record, {
    required bool Function() canWrite,
  }) async {
    final all = await getAll();
    final pause = debugPauseAfterRead;
    if (pause != null) await pause();
    if (!canWrite()) {
      throw StateError(
        'Owner changed before the conversation write; not saved.',
      );
    }
    await _writeAll([
      for (final r in all)
        if (r.id != record.id) r,
      record,
    ]);
  }

  @override
  Future<void> delete(String id) async {
    final all = await getAll();
    await _writeAll(all.where((e) => e.id != id).toList());
  }

  Future<void> _writeAll(List<ConversationRecord> records) => _storage
      .setStringList(_key, records.map((e) => jsonEncode(e.toJson())).toList())
      .requireDurable(_key);

  @override
  Future<void> sync() async {}
}
