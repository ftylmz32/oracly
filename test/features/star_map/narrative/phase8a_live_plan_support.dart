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
  String? engineId,
  String? engineVersion,
  String? zodiacSystem,
  String? coordinateConvention,
  String? timezoneDatabase,
  bool clearTimezoneDatabase = false,
  String? houseSystem,
  String? birthInstantKind,
  String? utcInstantIso,
  bool clearUtcInstantIso = false,
  ChartCalculationFidelity? chartFidelity,
  ChartCalculationFidelity? evidenceFidelity,
}) {
  final json = Map<String, dynamic>.from(chart.toJson());
  if (chartFidelity != null) json['fidelity'] = chartFidelity.name;
  final evRaw = json['natalEvidence'];
  if (evRaw is Map) {
    final ev = Map<String, dynamic>.from(evRaw);
    if (evidenceFidelity != null) ev['fidelity'] = evidenceFidelity.name;
    if (houseSystem != null) ev['houseSystem'] = houseSystem;
    final meta = Map<String, dynamic>.from(ev['metadata'] as Map);
    if (evidenceFingerprint != null) {
      meta['evidenceFingerprint'] = evidenceFingerprint;
    }
    if (calculationVersion != null) {
      meta['calculationVersion'] = calculationVersion;
    }
    if (engineId != null) meta['engineId'] = engineId;
    if (engineVersion != null) meta['engineVersion'] = engineVersion;
    if (zodiacSystem != null) meta['zodiacSystem'] = zodiacSystem;
    if (coordinateConvention != null) {
      meta['coordinateConvention'] = coordinateConvention;
    }
    if (clearTimezoneDatabase) {
      meta.remove('timezoneDatabase');
    } else if (timezoneDatabase != null) {
      meta['timezoneDatabase'] = timezoneDatabase;
    }
    if (houseSystem != null) meta['houseSystem'] = houseSystem;
    if (birthInstantKind != null) {
      meta['birthInstantKind'] = birthInstantKind;
    }
    if (clearUtcInstantIso) {
      meta.remove('utcInstantIso');
    } else if (utcInstantIso != null) {
      meta['utcInstantIso'] = utcInstantIso;
    }
    ev['metadata'] = meta;
    json['natalEvidence'] = ev;
  }
  return BirthChart.fromJson(json);
}

/// Mutate one fact provenance field; keep top-level metadata unchanged.
BirthChart phase8aMutateFactProvenance(
  BirthChart chart, {
  required String target, // placement | ascendant | midheaven | house | aspect
  required String field,
  required String value,
  int index = 0,
}) {
  final json = Map<String, dynamic>.from(chart.toJson());
  final ev = Map<String, dynamic>.from(json['natalEvidence'] as Map);
  Map<String, dynamic> fact;
  if (target == 'placement') {
    final list = List<Map<String, dynamic>>.from(
      (ev['placements'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    fact = list[index];
    final prov = Map<String, dynamic>.from(fact['provenance'] as Map);
    prov[field] = value;
    fact['provenance'] = prov;
    list[index] = fact;
    ev['placements'] = list;
  } else if (target == 'ascendant' || target == 'midheaven') {
    fact = Map<String, dynamic>.from(ev[target] as Map);
    final prov = Map<String, dynamic>.from(fact['provenance'] as Map);
    prov[field] = value;
    fact['provenance'] = prov;
    ev[target] = fact;
  } else if (target == 'house') {
    final list = List<Map<String, dynamic>>.from(
      (ev['houses'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    fact = list[index];
    final prov = Map<String, dynamic>.from(fact['provenance'] as Map);
    prov[field] = value;
    fact['provenance'] = prov;
    list[index] = fact;
    ev['houses'] = list;
  } else if (target == 'aspect') {
    final list = List<Map<String, dynamic>>.from(
      (ev['aspects'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
    fact = list[index];
    final prov = Map<String, dynamic>.from(fact['provenance'] as Map);
    prov[field] = value;
    fact['provenance'] = prov;
    list[index] = fact;
    ev['aspects'] = list;
  } else {
    throw ArgumentError('unknown target: $target');
  }
  json['natalEvidence'] = ev;
  return BirthChart.fromJson(json);
}

/// Inject exact fields into the first intervalStable reduced placement.
BirthChart phase8aInjectReducedExactField(
  BirthChart chart, {
  double? longitude,
  double? degreeWithinSign,
  bool? retrograde,
  int? house,
}) {
  final json = Map<String, dynamic>.from(chart.toJson());
  final ev = Map<String, dynamic>.from(json['natalEvidence'] as Map);
  final list = List<Map<String, dynamic>>.from(
    (ev['placements'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
  );
  final i = list.indexWhere((p) => p['certainty'] == 'intervalStable');
  if (i < 0) throw StateError('no intervalStable placement');
  final p = list[i];
  if (longitude != null) p['longitude'] = longitude;
  if (degreeWithinSign != null) p['degreeWithinSign'] = degreeWithinSign;
  if (retrograde != null) p['retrograde'] = retrograde;
  if (house != null) p['house'] = house;
  list[i] = p;
  ev['placements'] = list;
  json['natalEvidence'] = ev;
  return BirthChart.fromJson(json);
}

/// Ambiguous placement with a contradictory selected sign.
BirthChart phase8aInjectAmbiguousSign(BirthChart chart) {
  final json = Map<String, dynamic>.from(chart.toJson());
  final ev = Map<String, dynamic>.from(json['natalEvidence'] as Map);
  final list = List<Map<String, dynamic>>.from(
    (ev['placements'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
  );
  final i = list.indexWhere((p) => p['certainty'] == 'ambiguous');
  final target = i >= 0 ? i : 0;
  final p = list[target];
  p['certainty'] = 'ambiguous';
  p['sign'] = 'aries';
  p.remove('longitude');
  p.remove('degreeWithinSign');
  p.remove('retrograde');
  p.remove('house');
  list[target] = p;
  ev['placements'] = list;
  json['natalEvidence'] = ev;
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
