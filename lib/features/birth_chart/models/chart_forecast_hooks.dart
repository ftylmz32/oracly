/// Future transit / lunar hooks (not Phase 4).
library;

import 'aspect.dart';
import 'birth_chart.dart';

class ChartForecastContext {
  const ChartForecastContext({required this.chart, required this.asOf});
  final BirthChart chart;
  final DateTime asOf;
}

abstract class TransitCalculationPort {
  Future<List<Aspect>> dailyTransits({
    required BirthChart chart,
    required DateTime date,
  });
}

abstract class LunarPhasePort {
  String phaseLabel({required DateTime date});
}
