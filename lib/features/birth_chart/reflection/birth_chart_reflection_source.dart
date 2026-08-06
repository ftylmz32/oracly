/// SPRINT-002 — Birth chart source for Reflection Engine.
library;

import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../../core/intelligence/domain/models/reflection_entry.dart';
import '../../../core/reflection/domain/sources/reflection_source.dart';
import '../models/chart_insight.dart';
import '../data/birth_chart_record_mapper.dart';

class BirthChartReflectionSource implements ReflectionSource {
  BirthChartReflectionSource(this._repository);

  final BirthChartRepository _repository;

  @override
  ReflectionSourceKind get kind => ReflectionSourceKind.astrology;

  @override
  Future<ReflectionInputPartial?> collect({required DateTime asOf}) async {
    final record = await _repository.getLatest();
    if (record == null) return null;

    final chart = BirthChartRecordMapper.fromRecord(record);
    final coreInsight = chart.insights
        .where((i) => i.kind == ChartInsightKind.corePersonality)
        .map((i) => i.body)
        .firstOrNull;

    final text = coreInsight ?? chart.dominantEnergy.summary;
    if (text.trim().isEmpty) return null;

    return ReflectionInputPartial(
      reflections: [
        ReflectionEntry(
          id: 'chart_ref_${record.id}',
          source: JourneyReflectionSource.astrology,
          recordedAt: record.createdAt,
          text: text,
        ),
      ],
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
