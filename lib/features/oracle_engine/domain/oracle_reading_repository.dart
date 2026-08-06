/// OR-1140 — Reading persistence contract.
library;

import '../core/oracle_engine_type.dart';
import '../core/oracle_result.dart';

abstract class OracleReadingRepository {
  Future<void> save<T>(OracleResult<T> result);
  Future<List<Map<String, dynamic>>> listByEngine(OracleEngineType engine);
  Future<Map<String, dynamic>?> getById(String readingId);
}
