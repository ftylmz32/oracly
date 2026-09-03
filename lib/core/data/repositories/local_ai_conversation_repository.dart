/// OR-1130 — Local AI conversation repository.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../data/datasources/local_storage.dart';
import '../../domain/models/conversation_record.dart';
import '../../domain/repositories/ai_conversation_repository.dart';

class LocalAiConversationRepository implements AiConversationRepository {
  LocalAiConversationRepository(this._storage);

  static const _key = 'ai_conversations';

  final LocalStorage _storage;

  /// Quarantined corrupt row count for the last [getAll] (tests / diagnostics).
  int lastQuarantinedRows = 0;

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
    final updated = [
      for (final r in all)
        if (r.id != record.id) r,
      record,
    ];
    await _storage.setStringList(
      _key,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  @override
  Future<void> delete(String id) async {
    final all = await getAll();
    await _storage.setStringList(
      _key,
      all.where((e) => e.id != id).map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  @override
  Future<void> sync() async {}
}
