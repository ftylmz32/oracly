/// Phase 8A.2 — typed mutations for NaN/infinity (JSON cannot round-trip).
library;

import 'package:oracly_new/features/birth_chart/astronomy/natal_chart_evidence.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_house.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_placement.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';

BirthChart phase8aReplaceEvidence(BirthChart chart, NatalChartEvidence evidence) {
  return BirthChart(
    id: chart.id,
    profile: chart.profile,
    sun: chart.sun,
    moon: chart.moon,
    rising: chart.rising,
    midheaven: chart.midheaven,
    planets: chart.planets,
    houses: chart.houses,
    aspects: chart.aspects,
    elementBalance: chart.elementBalance,
    dominantEnergy: chart.dominantEnergy,
    lifeThemes: chart.lifeThemes,
    insights: chart.insights,
    generatedAt: chart.generatedAt,
    precision: chart.precision,
    fidelity: chart.fidelity,
    natalEvidence: evidence,
  );
}

NatalChartEvidence _cloneEv(
  NatalChartEvidence ev, {
  List<NatalPlacement>? placements,
  List<NatalHouse>? houses,
}) {
  return NatalChartEvidence(
    fidelity: ev.fidelity,
    metadata: ev.metadata,
    placements: placements ?? ev.placements,
    houses: houses ?? ev.houses,
    aspects: ev.aspects,
    elementBalance: ev.elementBalance,
    modalityBalance: ev.modalityBalance,
    ascendant: ev.ascendant,
    midheaven: ev.midheaven,
    houseSystem: ev.houseSystem,
  );
}

BirthChart phase8aTypedPlacementLongitude(BirthChart chart, double longitude) {
  final ev = chart.natalEvidence!;
  final p = ev.placements[0];
  final next = NatalPlacement(
    body: p.body,
    certainty: p.certainty,
    provenance: p.provenance,
    sign: p.sign,
    longitude: longitude,
    degreeWithinSign: p.degreeWithinSign,
    retrograde: p.retrograde,
    house: p.house,
  );
  return phase8aReplaceEvidence(
    chart,
    _cloneEv(ev, placements: [...ev.placements]..[0] = next),
  );
}

BirthChart phase8aTypedPlacementDegree(BirthChart chart, double degree) {
  final ev = chart.natalEvidence!;
  final p = ev.placements[0];
  final next = NatalPlacement(
    body: p.body,
    certainty: p.certainty,
    provenance: p.provenance,
    sign: p.sign,
    longitude: p.longitude,
    degreeWithinSign: degree,
    retrograde: p.retrograde,
    house: p.house,
  );
  return phase8aReplaceEvidence(
    chart,
    _cloneEv(ev, placements: [...ev.placements]..[0] = next),
  );
}

BirthChart phase8aTypedHouseCusp(BirthChart chart, double cusp) {
  final ev = chart.natalEvidence!;
  final h = ev.houses[0];
  final next = NatalHouse(
    number: h.number,
    sign: h.sign,
    cuspLongitude: cusp,
    system: h.system,
    certainty: h.certainty,
    provenance: h.provenance,
  );
  return phase8aReplaceEvidence(
    chart,
    _cloneEv(ev, houses: [...ev.houses]..[0] = next),
  );
}

BirthChart phase8aTypedPlacementHouse(BirthChart chart, int house) {
  final ev = chart.natalEvidence!;
  final p = ev.placements[0];
  final next = NatalPlacement(
    body: p.body,
    certainty: p.certainty,
    provenance: p.provenance,
    sign: p.sign,
    longitude: p.longitude,
    degreeWithinSign: p.degreeWithinSign,
    retrograde: p.retrograde,
    house: house,
  );
  return phase8aReplaceEvidence(
    chart,
    _cloneEv(ev, placements: [...ev.placements]..[0] = next),
  );
}
