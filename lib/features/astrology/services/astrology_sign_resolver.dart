/// Resolves zodiac: saved choice first, else sun sign from birth date.
library;

import '../../../core/domain/repositories/birth_chart_repository.dart';
import '../../birth_chart/data/birth_chart_record_mapper.dart';
import '../../content/astrology/data/astrology_content_catalogue.dart';
import '../data/astrology_preferences_store.dart';

class AstrologySignResolver {
  AstrologySignResolver({
    required this._preferences,
    this._birthCharts,
  });

  final AstrologyPreferencesStore _preferences;
  final BirthChartRepository? _birthCharts;

  static const fallbackId = 'aries';

  String? get savedSignId {
    final id = _preferences.selectedSignId;
    if (id == null) return null;
    return AstrologyContentCatalogue.signById(id)?.id;
  }

  Future<String> resolve() async {
    final saved = savedSignId;
    if (saved != null) return saved;

    final fromBirth = await _sunSignFromBirthChart();
    if (fromBirth != null) return fromBirth;
    return fallbackId;
  }

  Future<void> select(String id) async {
    final sign = AstrologyContentCatalogue.signById(id);
    if (sign == null) return;
    await _preferences.setSelectedSignId(sign.id);
  }

  Future<String?> _sunSignFromBirthChart() async {
    final repo = _birthCharts;
    if (repo == null) return null;
    try {
      final record = await repo.getLatest();
      if (record == null) return null;
      final chart = BirthChartRecordMapper.fromRecord(record);
      return chart.sun.sign.id;
    } catch (_) {
      return null;
    }
  }
}
