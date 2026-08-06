/// OR-1130 — Dream repository interface.
library;

import '../models/dream_record.dart';

abstract class DreamRepository {
  Future<List<DreamRecord>> getAll();
  Future<DreamRecord?> getById(String id);
  Future<void> save(DreamRecord record);
  Future<void> delete(String id);
  Future<void> sync();
}
