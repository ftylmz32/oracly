/// Load / generate result types for birth chart experience.
library;

import '../models/birth_chart.dart';
import '../models/birth_profile.dart';

class BirthChartExperienceResult {
  const BirthChartExperienceResult({required this.chart});

  final BirthChart chart;
}

enum BirthChartLoadStatus { none, loaded, clearedCorrupt, ownerUnavailable }

class BirthChartLoadResult {
  const BirthChartLoadResult._({
    required this.status,
    this.chart,
    this.profileHint,
  });

  const BirthChartLoadResult.none() : this._(status: BirthChartLoadStatus.none);

  const BirthChartLoadResult.loaded(BirthChart chart)
    : this._(status: BirthChartLoadStatus.loaded, chart: chart);

  const BirthChartLoadResult.clearedCorrupt({BirthProfile? profileHint})
    : this._(
        status: BirthChartLoadStatus.clearedCorrupt,
        profileHint: profileHint,
      );

  const BirthChartLoadResult.ownerUnavailable()
    : this._(status: BirthChartLoadStatus.ownerUnavailable);

  final BirthChartLoadStatus status;
  final BirthChart? chart;
  final BirthProfile? profileHint;
}
