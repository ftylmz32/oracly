/// OR-1170 — Tarot reading repository contract.
library;

import '../models/reading_session.dart';

abstract interface class TarotReadingRepository {
  Future<List<ReadingSession>> loadCompletedSessions();

  Future<List<ReadingSession>> loadAllSessions();

  Future<ReadingSession?> loadSession(String id);

  Future<ReadingSession?> loadActiveSession();

  Future<void> saveSession(ReadingSession session);

  Future<void> clearActiveSession();

  Future<void> deleteSession(String id);
}
