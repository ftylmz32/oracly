/// OR-1140 — In-memory reading store for architecture phase.
library;

import '../core/oracle_engine_type.dart';
import '../core/oracle_result.dart';
import '../domain/oracle_reading_repository.dart';

class InMemoryOracleReadingRepository implements OracleReadingRepository {
  final Map<String, Map<String, dynamic>> _store = {};

  @override
  Future<void> save<T>(OracleResult<T> result) async {
    _store[result.readingId] = {
      'engine': result.engine.name,
      'readingId': result.readingId,
      'generatedAt': result.generatedAt.toIso8601String(),
      'ruleSetId': result.ruleSetId,
      'sectionCount': result.sections.length,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> listByEngine(OracleEngineType engine) async {
    return _store.values
        .where((e) => e['engine'] == engine.name)
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getById(String readingId) async =>
      _store[readingId];
}
