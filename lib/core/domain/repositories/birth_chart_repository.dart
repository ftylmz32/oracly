/// SPRINT-002 — Birth chart repository contract.
library;

import '../models/birth_chart_record.dart';

abstract class BirthChartRepository {
  Future<BirthChartRecord?> getLatest();
  Future<void> save(BirthChartRecord record);
  Future<void> delete(String id);
}
