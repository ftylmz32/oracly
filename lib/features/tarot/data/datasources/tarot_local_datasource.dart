/// OR-1170 — Persistent tarot session storage.
library;

import 'dart:convert';

import '../../../../core/data/datasources/local_storage.dart';
import '../../domain/models/reading_session.dart';
import '../../domain/models/tarot_session_recovery.dart';

class TarotLocalDataSource {
  TarotLocalDataSource(this._storage);

  static const historyKey = 'or_tarot_reading_sessions';
  static const activeKey = 'or_tarot_active_session';

  final LocalStorage _storage;

  static const _historyKey = historyKey;
  static const _activeKey = activeKey;

  Future<List<ReadingSession>> fetchCompleted() async {
    final all = await fetchAll();
    return all.where((s) => s.status == ReadingSessionStatus.completed).toList()
      ..sort((a, b) => (b.completedAt ?? b.startedAt)
          .compareTo(a.completedAt ?? a.startedAt));
  }

  Future<List<ReadingSession>> fetchAll() async {
    final raw = _storage.getStringList(_historyKey) ?? [];
    final sessions = <ReadingSession>[];
    for (final row in raw) {
      final session = TarotSessionRecovery.decode(row);
      if (session != null) sessions.add(session);
    }
    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sessions;
  }

  Future<ReadingSession?> fetchById(String id) async {
    final all = await fetchAll();
    for (final session in all) {
      if (session.id == id) return session;
    }
    return null;
  }

  Future<ReadingSession?> fetchActive() async {
    final recovered = TarotSessionRecovery.decode(
      _storage.getString(_activeKey),
      activeOnly: true,
    );
    if (recovered == null) {
      final raw = _storage.getString(_activeKey);
      if (raw != null && raw.isNotEmpty) await clearActive();
      return null;
    }
    return recovered;
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
