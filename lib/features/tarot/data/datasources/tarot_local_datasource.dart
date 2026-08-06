/// OR-1170 — Persistent tarot session storage.
library;

import 'dart:convert';

import '../../../../core/data/datasources/local_storage.dart';
import '../../domain/models/reading_session.dart';

class TarotLocalDataSource {
  TarotLocalDataSource(this._storage);

  final LocalStorage _storage;

  static const _historyKey = 'or_tarot_reading_sessions';
  static const _activeKey = 'or_tarot_active_session';

  Future<List<ReadingSession>> fetchCompleted() async {
    final raw = _storage.getStringList(_historyKey) ?? [];
    return raw
        .map((e) => ReadingSession.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .where((s) => s.status == ReadingSessionStatus.completed)
        .toList()
      ..sort((a, b) => (b.completedAt ?? b.startedAt)
          .compareTo(a.completedAt ?? a.startedAt));
  }

  Future<List<ReadingSession>> fetchAll() async {
    final raw = _storage.getStringList(_historyKey) ?? [];
    return raw
        .map((e) => ReadingSession.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  Future<ReadingSession?> fetchById(String id) async {
    final all = await fetchAll();
    for (final session in all) {
      if (session.id == id) return session;
    }
    return null;
  }

  Future<ReadingSession?> fetchActive() async {
    final raw = _storage.getString(_activeKey);
    if (raw == null || raw.isEmpty) return null;
    return ReadingSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveActive(ReadingSession session) async {
    await _storage.setString(_activeKey, jsonEncode(session.toJson()));
  }

  Future<void> clearActive() async {
    await _storage.setString(_activeKey, '');
  }

  Future<void> upsert(ReadingSession session) async {
    final all = await fetchAll();
    final encoded = jsonEncode(session.toJson());
    final updated = [
      encoded,
      ...all
          .where((s) => s.id != session.id)
          .map((s) => jsonEncode(s.toJson())),
    ];
    await _storage.setStringList(_historyKey, updated);

    if (session.status == ReadingSessionStatus.inProgress) {
      await saveActive(session);
    } else {
      final active = await fetchActive();
      if (active?.id == session.id) {
        await clearActive();
      }
    }
  }

  Future<void> remove(String id) async {
    final all = await fetchAll();
    await _storage.setStringList(
      _historyKey,
      all.where((s) => s.id != id).map((s) => jsonEncode(s.toJson())).toList(),
    );
    final active = await fetchActive();
    if (active?.id == id) await clearActive();
  }
}
