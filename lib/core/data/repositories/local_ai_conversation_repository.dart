/// OR-1130 — Local AI conversation repository.
library;

import 'dart:convert';

import '../../data/datasources/local_storage.dart';
import '../../domain/models/conversation_record.dart';
import '../../domain/repositories/ai_conversation_repository.dart';

class LocalAiConversationRepository implements AiConversationRepository {
  LocalAiConversationRepository(this._storage);

  static const _key = 'ai_conversations';

  final LocalStorage _storage;

  @override
  Future<List<ConversationRecord>> getAll() async {
    final raw = _storage.getStringList(_key);
    if (raw == null) return [];
    return raw
        .map((e) =>
            ConversationRecord.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
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
      all
          .where((e) => e.id != id)
          .map((e) => jsonEncode(e.toJson()))
          .toList(),
    );
  }

  @override
  Future<void> sync() async {}
}
