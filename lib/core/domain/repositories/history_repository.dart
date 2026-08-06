/// OR-1100 — Reading history repository interface.
library;

import '../models/reading.dart';

abstract class HistoryRepository {
  Future<List<ReadingModel>> getReadings();
  Future<void> saveReading(ReadingModel reading);
  Future<void> deleteReading(String id);
  Future<void> clearAll();
}
