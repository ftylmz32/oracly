/// OR-1100 — Reading history service.
library;

import '../domain/models/reading.dart';
import '../domain/repositories/history_repository.dart';

class HistoryService {
  HistoryService(this._repository);

  final HistoryRepository _repository;

  Future<List<ReadingModel>> getAll() => _repository.getReadings();

  Future<void> remove(String id) => _repository.deleteReading(id);

  Future<void> clear() => _repository.clearAll();
}
