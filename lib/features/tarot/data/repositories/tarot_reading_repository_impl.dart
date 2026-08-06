/// OR-1170 — Tarot reading repository implementation.
library;

import '../../../../core/data/datasources/local_storage.dart';
import '../../domain/models/reading_session.dart';
import '../../domain/repositories/tarot_reading_repository.dart';
import '../datasources/tarot_local_datasource.dart';

class TarotReadingRepositoryImpl implements TarotReadingRepository {
  TarotReadingRepositoryImpl({required TarotLocalDataSource local})
      : _local = local;

  TarotReadingRepositoryImpl.fromStorage(LocalStorage storage)
      : _local = TarotLocalDataSource(storage);

  final TarotLocalDataSource _local;

  @override
  Future<void> clearActiveSession() => _local.clearActive();

  @override
  Future<void> deleteSession(String id) => _local.remove(id);

  @override
  Future<ReadingSession?> loadSession(String id) => _local.fetchById(id);

  @override
  Future<ReadingSession?> loadActiveSession() => _local.fetchActive();

  @override
  Future<List<ReadingSession>> loadCompletedSessions() =>
      _local.fetchCompleted();

  @override
  Future<List<ReadingSession>> loadAllSessions() => _local.fetchAll();

  @override
  Future<void> saveSession(ReadingSession session) => _local.upsert(session);
}
