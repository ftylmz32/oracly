/// Phase 8A — shared live-plan chart helpers (real EvidenceAware calculator).
library;

import 'package:oracly_new/features/birth_chart/astronomy/evidence_aware_natal_calculator.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_fidelity.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact.dart';
import 'package:oracly_new/features/star_map/artifacts/yildizname_artifact_factory.dart';
import 'package:oracly_new/features/star_map/narrative/request/yildizname_theme_fact.dart';

import '../artifacts/phase6_test_support.dart';

final phase8aCalc = EvidenceAwareNatalChartCalculator();

BirthProfile phase8aE1Profile() => BirthProfile(
      birthDate: DateTime(1990, 6, 15),
      birthPlace: '',
      birthTimeKnown: false,
      birthPlaceUnknownConfirmed: true,
    );

BirthProfile phase8aE2Profile() => BirthProfile(
      birthDate: DateTime(1990, 6, 15),
      birthPlace: 'İstanbul',
      birthPlaceId: 'tr_34',
      birthTimeKnown: false,
      latitude: 41.0082,
      longitude: 28.9784,
      timezoneId: 'Europe/Istanbul',
      timezoneResolutionStatus: BirthTimezoneStatus.resolved,
    );

BirthProfile phase8aE3Profile() => BirthProfile(
      birthDate: DateTime(1990, 6, 15),
      birthPlace: '',
      birthTime: DateTime(1990, 6, 15, 14, 30),
      birthTimeKnown: true,
      birthPlaceUnknownConfirmed: true,
    );

BirthProfile phase8aE4Profile() => BirthProfile(
      birthDate: DateTime(2000, 1, 1),
      birthPlace: 'İstanbul',
      birthPlaceId: 'tr_34',
      birthTime: DateTime(2000, 1, 1, 12, 0),
      birthTimeKnown: true,
      latitude: 41.0082,
      longitude: 28.9784,
      timezoneId: 'Europe/Istanbul',
      timezoneResolutionStatus: BirthTimezoneStatus.resolved,
    );

BirthChart phase8aChart(BirthProfile profile) => phase8aCalc.calculate(profile);

BirthChart phase8aMutateEvidence(
  BirthChart chart, {
  String? evidenceFingerprint,
  String? calculationVersion,
  ChartCalculationFidelity? chartFidelity,
  ChartCalculationFidelity? evidenceFidelity,
}) {
  final json = Map<String, dynamic>.from(chart.toJson());
  if (chartFidelity != null) json['fidelity'] = chartFidelity.name;
  final evRaw = json['natalEvidence'];
  if (evRaw is Map) {
    final ev = Map<String, dynamic>.from(evRaw);
    if (evidenceFidelity != null) ev['fidelity'] = evidenceFidelity.name;
    final meta = Map<String, dynamic>.from(ev['metadata'] as Map);
    if (evidenceFingerprint != null) {
      meta['evidenceFingerprint'] = evidenceFingerprint;
    }
    if (calculationVersion != null) {
      meta['calculationVersion'] = calculationVersion;
    }
    ev['metadata'] = meta;
    json['natalEvidence'] = ev;
  }
  return BirthChart.fromJson(json);
}

YildiznameArtifact phase8aNarrativeArtifact({
  required String ownerId,
  required String id,
  required String label,
  required DateTime at,
  String semantic = 'sem',
}) {
  return YildiznameArtifactFactory.createNarrative(
    ownerId: ownerId,
    id: id,
    request: sampleRequest(
      themes: [YildiznameThemeFact(themeRef: 'theme.0', label: label)],
    ),
    result: sampleResult(themeRefs: const ['theme.0']),
    semanticFingerprint: semantic,
    createdAtUtc: at,
  );
}
