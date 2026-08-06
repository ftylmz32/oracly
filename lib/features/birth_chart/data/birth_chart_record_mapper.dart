/// SPRINT-002 — Maps between [BirthChart] and [BirthChartRecord].
library;

import '../../../core/domain/models/birth_chart_record.dart';
import '../models/birth_chart.dart';

abstract final class BirthChartRecordMapper {
  BirthChartRecordMapper._();

  static BirthChartRecord toRecord(BirthChart chart) {
    return BirthChartRecord(
      id: chart.id,
      createdAt: chart.generatedAt,
      updatedAt: DateTime.now(),
      payload: chart.toJson(),
    );
  }

  static BirthChart fromRecord(BirthChartRecord record) {
    return BirthChart.fromJson(record.payload);
  }
}
