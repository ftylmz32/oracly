/// Couples Tarot journal + session + connected memory on single delete.
library;

import '../../../core/memory/oracly_memory_store.dart';
import '../../../core/services/history_service.dart';
import '../domain/models/reading_session.dart';
import '../domain/repositories/tarot_reading_repository.dart';

class TarotHistoryDeletionService {
  TarotHistoryDeletionService({
    required this.history,
    required this.tarotRepository,
    required this.memory,
  });

  final HistoryService history;
  final TarotReadingRepository tarotRepository;
  final OraclyMemoryStore memory;

  Future<void> deleteReading(String requestedId) async {
    final id = requestedId.trim();
    if (id.isEmpty) {
      throw StateError('tarot history deletion incomplete');
    }

    final readings = await history.getAll();
    final sessions = await tarotRepository.loadAllSessions();

    final matchingReadings = [
      for (final r in readings)
        if (r.id == id || r.sessionId == id) r,
    ];

    final sourceIds = <String>{id};
    final sessionIds = <String>{id};

    for (final r in matchingReadings) {
      sourceIds.add(r.id);
      final sid = r.sessionId?.trim();
      if (sid != null && sid.isNotEmpty) {
        sourceIds.add(sid);
        sessionIds.add(sid);
      }
      if (sessions.any((s) => s.id == r.id)) {
        sessionIds.add(r.id);
      }
    }

    for (final s in sessions) {
      if (s.id == id || sourceIds.contains(s.id) || sessionIds.contains(s.id)) {
        sessionIds.add(s.id);
      }
    }

    final matchingSessions = <ReadingSession>[
      for (final s in sessions)
        if (sessionIds.contains(s.id)) s,
    ];

    for (final r in matchingReadings) {
      try {
        await history.remove(r.id);
      } catch (_) {}
    }
    for (final s in matchingSessions) {
      try {
        await tarotRepository.deleteSession(s.id);
      } catch (_) {}
    }
    for (final sourceId in sourceIds) {
      try {
        await memory.removeBySource(sourceId);
      } catch (_) {}
    }

    await _verifyGone(
      requestedId: id,
      sourceIds: sourceIds,
      sessionIds: sessionIds,
    );
  }

  Future<void> _verifyGone({
    required String requestedId,
    required Set<String> sourceIds,
    required Set<String> sessionIds,
  }) async {
    final readings = await history.getAll();
    final sessions = await tarotRepository.loadAllSessions();
    final memories = memory.all();

    for (final r in readings) {
      if (r.id == requestedId ||
          r.sessionId == requestedId ||
          sourceIds.contains(r.id) ||
          (r.sessionId != null && sourceIds.contains(r.sessionId!)) ||
          sessionIds.contains(r.id) ||
          (r.sessionId != null && sessionIds.contains(r.sessionId!))) {
        throw StateError('tarot history deletion incomplete');
      }
    }
    for (final s in sessions) {
      if (sessionIds.contains(s.id) || sourceIds.contains(s.id)) {
        throw StateError('tarot history deletion incomplete');
      }
    }
    for (final m in memories) {
      if (sourceIds.contains(m.source.id)) {
        throw StateError('tarot history deletion incomplete');
      }
    }
  }
}
